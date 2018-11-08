//===--- LLVMMergeFunctions.cpp - Merge similar functions for swift -------===//
//
// This source file is part of the Swift.org open source project
// Licensed under Apache License v2.0 with Runtime Library Exception
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
//
// This pass looks for similar functions that are mergeable and folds them.
// The implementation is similar to LLVM's MergeFunctions pass. Instead of
// merging identical functions, it merges functions which only differ by a few
// constants in certain instructions.
// Currently this is very Swift specific in the sense that it's intended to
// merge specialized functions which only differ by loading different metadata
// pointers.
// TODO: It could make sense to generalize this pass.
//
// This pass should run after LLVM's MergeFunctions pass, because it works best
// if there are no _identical_ functions in the module.
// Note: it would also work for identical functions but could produce more
// code overhead than the LLVM pass.
//
// There is a big TODO: currently there is a large code overlap in this file
// and the LLVM pass, mainly the IR comparison functions. This should be
// factored out into a separate utility and used by both passes.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/FoldingSet.h"
#include "llvm/ADT/Hashing.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/CallSite.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/Utils/FunctionComparator.h"
#include <vector>

using namespace llvm;

#define DEBUG_TYPE "mergesimfunc"

STATISTIC(NumSimilarFunctionsMerged, "Number of functions merged");
STATISTIC(NumThunksWritten, "Number of thunks generated");

static cl::opt<unsigned> NumFunctionsForSanityCheck(
    "mergesimfunc-sanity",
    cl::desc("How many functions in module could be used for "
             "MergeSimilarFunctions pass sanity check. "
             "'0' disables this check. Works only with '-debug' key."),
    cl::init(0), cl::Hidden);

static cl::opt<unsigned> FunctionMergeThreshold(
    "mergesimfunc-threshold",
    cl::desc("Functions larger than the threshold are considered for merging."
             "'0' disables function merging at all."),
    cl::init(15), cl::Hidden);

namespace {

/// FunctionComparator - Compares two functions to determine whether or not
/// they will generate machine code with the same behavior. DataLayout is
/// used if available. The comparator always fails conservatively (erring on the
/// side of claiming that two functions are different).
class SwiftFunctionComparator : FunctionComparator {
public:
  SwiftFunctionComparator(const Function *F1, const Function *F2,
                          GlobalNumberState *GN)
      : FunctionComparator(F1, F2, GN) {}

  int cmpOperandsIgnoringConsts(const Instruction *L, const Instruction *R,
                                unsigned opIdx);

  int cmpBasicBlocksIgnoringConsts(const BasicBlock *BBL,
                                   const BasicBlock *BBR);

  int compareIgnoringConsts();
};

} // end anonymous namespace

static bool isEligibleForConstantSharing(const Instruction *I) {
  switch (I->getOpcode()) {
  case Instruction::Load:
  case Instruction::Store:
  case Instruction::Call:
    return true;
  default:
    return false;
  }
}

int SwiftFunctionComparator::cmpOperandsIgnoringConsts(const Instruction *L,
                                                       const Instruction *R,
                                                       unsigned opIdx) {
  Value *OpL = L->getOperand(opIdx);
  Value *OpR = R->getOperand(opIdx);

  int Res = cmpValues(OpL, OpR);
  if (Res == 0)
    return Res;

  if (!isa<Constant>(OpL) || !isa<Constant>(OpR))
    return Res;

  if (!isEligibleForConstantSharing(L))
    return Res;

  if (const auto *CL = dyn_cast<CallInst>(L)) {
    if (CL->isInlineAsm())
      return Res;
    if (Function *CalleeL = CL->getCalledFunction()) {
      if (CalleeL->isIntrinsic())
        return Res;
    }
    const CallInst *CR = cast<CallInst>(R);
    if (CR->isInlineAsm())
      return Res;
    if (Function *CalleeR = CR->getCalledFunction()) {
      if (CalleeR->isIntrinsic())
        return Res;
    }
  }

  if (cmpTypes(OpL->getType(), OpR->getType()))
    return Res;

  return 0;
}

// Test whether two basic blocks have equivalent behavior.
int SwiftFunctionComparator::cmpBasicBlocksIgnoringConsts(
    const BasicBlock *BBL, const BasicBlock *BBR) {
  BasicBlock::const_iterator InstL = BBL->begin(), InstLE = BBL->end();
  BasicBlock::const_iterator InstR = BBR->begin(), InstRE = BBR->end();

  do {
    bool needToCmpOperands = true;
    if (int Res = cmpOperations(&*InstL, &*InstR, needToCmpOperands))
      return Res;
    if (needToCmpOperands) {
      assert(InstL->getNumOperands() == InstR->getNumOperands());

      for (unsigned i = 0, e = InstL->getNumOperands(); i != e; ++i) {
        if (int Res = cmpOperandsIgnoringConsts(&*InstL, &*InstR, i))
          return Res;
        // cmpValues should ensure this is true.
        assert(cmpTypes(InstL->getOperand(i)->getType(),
                        InstR->getOperand(i)->getType()) == 0);
      }
    }
    ++InstL, ++InstR;
  } while (InstL != InstLE && InstR != InstRE);

  if (InstL != InstLE && InstR == InstRE)
    return 1;
  if (InstL == InstLE && InstR != InstRE)
    return -1;
  return 0;
}

// Test whether the two functions have equivalent behavior.
int SwiftFunctionComparator::compareIgnoringConsts() {
  beginCompare();

  if (int Res = compareSignature())
    return Res;

  Function::const_iterator LIter = FnL->begin(), LEnd = FnL->end();
  Function::const_iterator RIter = FnR->begin(), REnd = FnR->end();

  do {
    const BasicBlock *BBL = &*LIter;
    const BasicBlock *BBR = &*RIter;

    if (int Res = cmpValues(BBL, BBR))
      return Res;

    if (int Res = cmpBasicBlocksIgnoringConsts(BBL, BBR))
      return Res;

    ++LIter, ++RIter;
  } while (LIter != LEnd && RIter != REnd);

  return 0;
}

namespace {

/// MergeSimilarFunctions finds functions which only differ by constants in
/// certain instructions, e.g. resulting from specialized functions of layout
/// compatible types.
/// Such functions are merged by replacing the differing constants by a
/// parameter. The original functions are replaced by thunks which call the
/// merged function with the specific argument constants.
///
class MergeSimilarFunctions : public ModulePass {
public:
  static char ID;
  MergeSimilarFunctions()
      : ModulePass(ID), FnTree(FunctionNodeCmp(&GlobalNumbers)) {}

  bool runOnModule(Module &M) override;

private:
  enum {
    /// The maximum number of parameters added to a merged functions. This
    /// roughly corresponds to the number of differing constants.
    maxAddedParams = 4
  };

  struct FunctionEntry;

  /// Describes the set of functions which are considered as "equivalent" (i.e.
  /// only differing by some constants).
  struct EquivalenceClass {
    /// The single-linked list of all functions which are a member of this
    /// equivalence class.
    FunctionEntry *First;

    /// A very cheap hash, used to early exit if functions do not match.
    FunctionComparator::FunctionHash Hash;

  public:
    // Note the hash is recalculated potentially multiple times, but it is
    // cheap.
    EquivalenceClass(FunctionEntry *First)
        : First(First), Hash(FunctionComparator::functionHash(*First->F)) {
      assert(!First->Next);
    }
  };

  /// The function comparison operator is provided here so that FunctionNodes do
  /// not need to become larger with another pointer.
  class FunctionNodeCmp {
    GlobalNumberState *GlobalNumbers;

  public:
    FunctionNodeCmp(GlobalNumberState *GN) : GlobalNumbers(GN) {}
    bool operator()(const EquivalenceClass &LHS,
                    const EquivalenceClass &RHS) const {
      // Order first by hashes, then full function comparison.
      if (LHS.Hash != RHS.Hash)
        return LHS.Hash < RHS.Hash;
      SwiftFunctionComparator FCmp(LHS.First->F, RHS.First->F, GlobalNumbers);
      return FCmp.compareIgnoringConsts() == -1;
    }
  };
  using FnTreeType = std::set<EquivalenceClass, FunctionNodeCmp>;

  ///
  struct FunctionEntry {
    FunctionEntry(Function *F, FnTreeType::iterator I)
        : F(F), Next(nullptr), numUnhandledCallees(0), TreeIter(I),
          isMerged(false) {}

    /// Back-link to the function.
    AssertingVH<Function> F;

    /// The next function in its equivalence class.
    FunctionEntry *Next;

    /// The number of not-yet merged callees. Used to process the merging in
    /// bottom-up call order.
    /// This is only valid in the first entry of an equivalence class. The
    /// counts of all functions in an equivalence class are accumulated in the
    /// first entry.
    int numUnhandledCallees;

    /// The iterator of the function's equivalence class in the FnTree.
    /// It's FnTree.end() if the function is not in an equivalence class.
    FnTreeType::iterator TreeIter;

    /// True if this function is already a thunk, calling the merged function.
    bool isMerged;
  };

  /// Describes an operator of a specific instruction.
  struct OpLocation {
    Instruction *I;
    unsigned OpIndex;
  };

  /// Information for a function. Used during merging.
  struct FunctionInfo {

    FunctionInfo(Function *F)
        : F(F), CurrentInst(nullptr), NumParamsNeeded(0) {}

    void init() {
      CurrentInst = &*F->begin()->begin();
      NumParamsNeeded = 0;
    }

    /// Advances the current instruction to the next instruction.
    void nextInst() {
      assert(CurrentInst);
      if (CurrentInst->isTerminator()) {
        auto BlockIter = std::next(CurrentInst->getParent()->getIterator());
        if (BlockIter == F->end()) {
          CurrentInst = nullptr;
          return;
        }
        CurrentInst = &*BlockIter->begin();
        return;
      }
      CurrentInst = &*std::next(CurrentInst->getIterator());
    }

    Function *F;

    /// The current instruction while iterating over all instructions.
    Instruction *CurrentInst;

    /// Roughly the number of parameters needed if this function would be
    /// merged with the first function of the equivalence class.
    int NumParamsNeeded;
  };

  using FunctionInfos = SmallVector<FunctionInfo, 8>;

  /// Describes a parameter which we create to parameterize the merged function.
  struct ParamInfo {
    /// The value of the parameter for all the functions in the equivalence
    /// class.
    SmallVector<Constant *, 8> Values;

    /// All uses of the parameter in the merged function.
    SmallVector<OpLocation, 16> Uses;

    /// Checks if this parameter can be used to describe an operand in all
    /// functions of the equivalence class. Returns true if all values match
    /// the specific instruction operands in all functions.
    bool matches(const FunctionInfos &FInfos, unsigned OpIdx) const {
      unsigned NumFuncs = FInfos.size();
      assert(Values.size() == NumFuncs);
      for (unsigned Idx = 0; Idx < NumFuncs; ++Idx) {
        const FunctionInfo &FI = FInfos[Idx];
        Constant *C = cast<Constant>(FI.CurrentInst->getOperand(OpIdx));
        if (Values[Idx] != C)
          return false;
      }
      return true;
    }
  };

  using ParamInfos = SmallVector<ParamInfo, maxAddedParams>;

  GlobalNumberState GlobalNumbers;

  /// A work queue of functions that may have been modified and should be
  /// analyzed again.
  std::vector<WeakTrackingVH> Deferred;

  /// The set of all distinct functions. Use the insert() and remove() methods
  /// to modify it. The map allows efficient lookup and deferring of Functions.
  FnTreeType FnTree;

  ValueMap<Function *, FunctionEntry *> FuncEntries;

  FunctionEntry *getEntry(Function *F) const { return FuncEntries.lookup(F); }

  bool isInEquivalenceClass(FunctionEntry *FE) const {
    if (FE->TreeIter != FnTree.end()) {
      return true;
    }
    assert(!FE->Next);
    assert(FE->numUnhandledCallees == 0);
    return false;
  }

  /// Checks the rules of order relation introduced among functions set.
  /// Returns true, if sanity check has been passed, and false if failed.
  bool doSanityCheck(std::vector<WeakTrackingVH> &Worklist);

  /// Updates the numUnhandledCallees of all user functions of the equivalence
  /// class containing \p FE by \p Delta.
  void updateUnhandledCalleeCount(FunctionEntry *FE, int Delta);

  bool tryMergeEquivalenceClass(FunctionEntry *FirstInClass);

  FunctionInfo removeFuncWithMostParams(FunctionInfos &FInfos);

  bool deriveParams(ParamInfos &Params, FunctionInfos &FInfos);

  bool numOperandsDiffer(FunctionInfos &FInfos);

  bool constsDiffer(const FunctionInfos &FInfos, unsigned OpIdx);

  bool tryMapToParameter(FunctionInfos &FInfos, unsigned OpIdx,
                         ParamInfos &Params);

  void mergeWithParams(const FunctionInfos &FInfos, ParamInfos &Params);

  void removeEquivalenceClassFromTree(FunctionEntry *FE);

  void writeThunk(Function *ToFunc, Function *Thunk, const ParamInfos &Params,
                  unsigned FuncIdx);

  /// Replace all direct calls of Old with calls of New. Will bitcast New if
  /// necessary to make types match.
  bool replaceDirectCallers(Function *Old, Function *New,
                            const ParamInfos &Params, unsigned FuncIdx);
};

} // end anonymous namespace

char MergeSimilarFunctions::ID = 0;
INITIALIZE_PASS_BEGIN(MergeSimilarFunctions, "merge-similar-functions",
                      "Merge similar function pass", false, false)
INITIALIZE_PASS_END(MergeSimilarFunctions, "merge-similar-functions",
                    "Merge similar function pass", false, false)

llvm::ModulePass *llvm::createMergeSimilarFunctionsPass() {
  // LINUS_TODO: Is initialize necessary? The merge-identical pass does not call
  // it, and it's done in llvm::initializeIPO already.
  initializeMergeSimilarFunctionsPass(*llvm::PassRegistry::getPassRegistry());
  return new MergeSimilarFunctions();
}

bool MergeSimilarFunctions::doSanityCheck(
    std::vector<WeakTrackingVH> &Worklist) {
  if (const unsigned Max = NumFunctionsForSanityCheck) {
    unsigned TripleNumber = 0;
    bool Valid = true;

    dbgs() << "MERGEFUNC-SANITY: Started for first " << Max << " functions.\n";

    unsigned i = 0;
    for (std::vector<WeakTrackingVH>::iterator I = Worklist.begin(),
                                               E = Worklist.end();
         I != E && i < Max; ++I, ++i) {
      unsigned j = i;
      for (std::vector<WeakTrackingVH>::iterator J = I; J != E && j < Max;
           ++J, ++j) {
        Function *F1 = cast<Function>(*I);
        Function *F2 = cast<Function>(*J);
        int Res1 = SwiftFunctionComparator(F1, F2, &GlobalNumbers)
                       .compareIgnoringConsts();
        int Res2 = SwiftFunctionComparator(F2, F1, &GlobalNumbers)
                       .compareIgnoringConsts();

        // If F1 <= F2, then F2 >= F1, otherwise report failure.
        if (Res1 != -Res2) {
          dbgs() << "MERGEFUNC-SANITY: Non-symmetric; triple: " << TripleNumber
                 << "\n";
          F1->dump();
          F2->dump();
          Valid = false;
        }

        if (Res1 == 0)
          continue;

        unsigned k = j;
        for (std::vector<WeakTrackingVH>::iterator K = J; K != E && k < Max;
             ++k, ++K, ++TripleNumber) {
          if (K == J)
            continue;

          Function *F3 = cast<Function>(*K);
          int Res3 = SwiftFunctionComparator(F1, F3, &GlobalNumbers)
                         .compareIgnoringConsts();
          int Res4 = SwiftFunctionComparator(F2, F3, &GlobalNumbers)
                         .compareIgnoringConsts();

          bool Transitive = true;

          if (Res1 != 0 && Res1 == Res4) {
            // F1 > F2, F2 > F3 => F1 > F3
            Transitive = Res3 == Res1;
          } else if (Res3 != 0 && Res3 == -Res4) {
            // F1 > F3, F3 > F2 => F1 > F2
            Transitive = Res3 == Res1;
          } else if (Res4 != 0 && -Res3 == Res4) {
            // F2 > F3, F3 > F1 => F2 > F1
            Transitive = Res4 == -Res1;
          }

          if (!Transitive) {
            dbgs() << "MERGEFUNC-SANITY: Non-transitive; triple: "
                   << TripleNumber << "\n";
            dbgs() << "Res1, Res3, Res4: " << Res1 << ", " << Res3 << ", "
                   << Res4 << "\n";
            F1->dump();
            F2->dump();
            F3->dump();
            Valid = false;
          }
        }
      }
    }

    dbgs() << "MERGEFUNC-SANITY: " << (Valid ? "Passed." : "Failed.") << "\n";
    return Valid;
  }
  return true;
}

/// Returns true if function \p F is eligible for merging.
static bool isEligibleFunction(Function *F) {
  if (F->isDeclaration())
    return false;

  if (F->hasAvailableExternallyLinkage())
    return false;

  if (F->getFunctionType()->isVarArg())
    return false;

  unsigned Benefit = 0;

  // We don't want to merge very small functions, because the overhead of
  // adding creating thunks and/or adding parameters to the call sites
  // outweighs the benefit.
  for (BasicBlock &BB : *F) {
    for (Instruction &I : BB) {
      if (CallSite CS = CallSite(&I)) {
        Function *Callee = CS.getCalledFunction();
        if (!Callee || !Callee->isIntrinsic()) {
          Benefit += 5;
          continue;
        }
      }
      Benefit += 1;
    }
  }
  if (Benefit < FunctionMergeThreshold)
    return false;

  return true;
}

bool MergeSimilarFunctions::runOnModule(Module &M) {

  if (FunctionMergeThreshold == 0)
    return false;

  bool Changed = false;

  // All functions in the module, ordered by hash. Functions with a unique
  // hash value are easily eliminated.
  std::vector<std::pair<FunctionComparator::FunctionHash, Function *>>
      HashedFuncs;

  for (Function &Func : M) {
    if (isEligibleFunction(&Func)) {
      HashedFuncs.push_back({FunctionComparator::functionHash(Func), &Func});
    }
  }

  std::stable_sort(
      HashedFuncs.begin(), HashedFuncs.end(),
      [](const std::pair<FunctionComparator::FunctionHash, Function *> &a,
         const std::pair<FunctionComparator::FunctionHash, Function *> &b) {
        return a.first < b.first;
      });

  std::vector<FunctionEntry> FuncEntryStorage;
  FuncEntryStorage.reserve(HashedFuncs.size());

  auto S = HashedFuncs.begin();
  for (auto I = HashedFuncs.begin(), IE = HashedFuncs.end(); I != IE; ++I) {

    Function *F = I->second;
    FuncEntryStorage.push_back(FunctionEntry(F, FnTree.end()));
    FunctionEntry &FE = FuncEntryStorage.back();
    FuncEntries[F] = &FE;

    // If the hash value matches the previous value or the next one, we must
    // consider merging it. Otherwise it is dropped and never considered again.
    if ((I != S && std::prev(I)->first == I->first) ||
        (std::next(I) != IE && std::next(I)->first == I->first)) {
      Deferred.push_back(WeakTrackingVH(F));
    }
  }

  do {
    std::vector<WeakTrackingVH> Worklist;
    Deferred.swap(Worklist);

    LLVM_DEBUG(dbgs() << "======\nbuild tree: worklist-size=" << Worklist.size()
                      << '\n');
    LLVM_DEBUG(doSanityCheck(Worklist));

    SmallVector<FunctionEntry *, 8> FuncsToMerge;

    // Insert all candidates into the Worklist.
    for (WeakTrackingVH &I : Worklist) {
      if (!I)
        continue;
      Function *F = cast<Function>(I);
      FunctionEntry *FE = getEntry(F);
      assert(!isInEquivalenceClass(FE));

      std::pair<FnTreeType::iterator, bool> Result = FnTree.insert(FE);

      FE->TreeIter = Result.first;
      const EquivalenceClass &Eq = *Result.first;

      if (Result.second) {
        assert(Eq.First == FE);
        LLVM_DEBUG(dbgs() << "  new in tree: " << F->getName() << '\n');
      } else {
        assert(Eq.First != FE);
        LLVM_DEBUG(dbgs() << "  add to existing: " << F->getName() << '\n');
        // Add the function to the existing equivalence class.
        FE->Next = Eq.First->Next;
        Eq.First->Next = FE;
        // Schedule for merging if the function's equivalence class reaches the
        // size of 2.
        if (!FE->Next)
          FuncsToMerge.push_back(Eq.First);
      }
    }
    LLVM_DEBUG(dbgs() << "merge functions: tree-size=" << FnTree.size()
                      << '\n');

    // Figure out the leaf functions. We want to do the merging in bottom-up
    // call order. This ensures that we don't parameterize on callee function
    // names if we don't have to (because the callee may be merged).
    // Note that "leaf functions" refer to the sub-call-graph of functions which
    // are in the FnTree.
    for (FunctionEntry *ToMerge : FuncsToMerge) {
      assert(isInEquivalenceClass(ToMerge));
      updateUnhandledCalleeCount(ToMerge, 1);
    }

    // Check if there are any leaf functions at all.
    bool LeafFound = false;
    for (FunctionEntry *ToMerge : FuncsToMerge) {
      if (ToMerge->numUnhandledCallees == 0)
        LeafFound = true;
    }
    for (FunctionEntry *ToMerge : FuncsToMerge) {
      if (isInEquivalenceClass(ToMerge)) {
        // Only merge leaf functions (or all functions if all functions are in
        // a call cycle).
        if (ToMerge->numUnhandledCallees == 0 || !LeafFound) {
          updateUnhandledCalleeCount(ToMerge, -1);
          Changed |= tryMergeEquivalenceClass(ToMerge);
        } else {
          // Non-leaf functions (i.e. functions in a call cycle) may become
          // leaf functions in the next iteration.
          removeEquivalenceClassFromTree(ToMerge);
        }
      }
    }
  } while (!Deferred.empty());

  FnTree.clear();
  GlobalNumbers.clear();
  FuncEntries.clear();

  return Changed;
}

void MergeSimilarFunctions::updateUnhandledCalleeCount(FunctionEntry *FE,
                                                       int Delta) {
  // Iterate over all functions of FE's equivalence class.
  do {
    for (Use &U : FE->F->uses()) {
      if (auto *I = dyn_cast<Instruction>(U.getUser())) {
        FunctionEntry *CallerFE = getEntry(I->getFunction());
        if (CallerFE && CallerFE->TreeIter != FnTree.end()) {
          // Accumulate the count in the first entry of the equivalence class.
          FunctionEntry *Head = CallerFE->TreeIter->First;
          Head->numUnhandledCallees += Delta;
        }
      }
    }
    FE = FE->Next;
  } while (FE);
}

bool MergeSimilarFunctions::tryMergeEquivalenceClass(
    FunctionEntry *FirstInClass) {
  // Build the FInfos vector from all functions in the equivalence class.
  FunctionInfos FInfos;
  FunctionEntry *FE = FirstInClass;
  do {
    FInfos.push_back(FunctionInfo(FE->F));
    FE->isMerged = true;
    FE = FE->Next;
  } while (FE);
  assert(FInfos.size() >= 2);

  // Merged or not: in any case we remove the equivalence class from the FnTree.
  removeEquivalenceClassFromTree(FirstInClass);

  // Contains functions which differ too much from the first function (i.e.
  // would need too many parameters).
  FunctionInfos Removed;

  bool Changed = false;
  int Try = 0;

  // We need multiple tries if there are some functions in FInfos which differ
  // too much from the first function in FInfos. But we limit the number of
  // tries to a small number, because this is quadratic.
  while (FInfos.size() >= 2 && Try++ < 4) {
    ParamInfos Params;
    bool Merged = deriveParams(Params, FInfos);
    if (Merged) {
      mergeWithParams(FInfos, Params);
      Changed = true;
    } else {
      // We ran out of parameters. Remove the function from the set which
      // differs most from the first function.
      Removed.push_back(removeFuncWithMostParams(FInfos));
    }
    if (Merged || FInfos.size() < 2) {
      // Try again with the functions which were removed from the original set.
      FInfos.swap(Removed);
      Removed.clear();
    }
  }
  return Changed;
}

/// Remove the function from \p FInfos which needs the most parameters. Add the
/// removed function to
MergeSimilarFunctions::FunctionInfo
MergeSimilarFunctions::removeFuncWithMostParams(FunctionInfos &FInfos) {
  FunctionInfos::iterator MaxIter = FInfos.end();
  for (auto Iter = FInfos.begin(), End = FInfos.end(); Iter != End; ++Iter) {
    if (MaxIter == FInfos.end() ||
        Iter->NumParamsNeeded > MaxIter->NumParamsNeeded) {
      MaxIter = Iter;
    }
  }
  FunctionInfo Removed = *MaxIter;
  FInfos.erase(MaxIter);
  return Removed;
}

/// Finds the set of parameters which are required to merge the functions in
/// \p FInfos.
/// Returns true on success, i.e. the functions in \p FInfos can be merged with
/// the parameters returned in \p Params.
bool MergeSimilarFunctions::deriveParams(ParamInfos &Params,
                                         FunctionInfos &FInfos) {
  for (FunctionInfo &FI : FInfos)
    FI.init();

  FunctionInfo &FirstFI = FInfos.front();

  // Iterate over all instructions synchronously in all functions.
  do {
    if (isEligibleForConstantSharing(FirstFI.CurrentInst)) {

      // Here we handle a rare corner case which needs to be explained:
      // Usually the number of operands match, because otherwise the functions
      // in FInfos would not be in the same equivalence class. There is only one
      // exception to that: If the current instruction is a call to a function,
      // which was merged in the previous iteration (in
      // tryMergeEquivalenceClass) then the call could be replaced and has more
      // arguments than the original call.
      if (numOperandsDiffer(FInfos)) {
        assert(isa<CallInst>(FirstFI.CurrentInst) &&
               "only calls are expected to differ in number of operands");
        return false;
      }

      for (unsigned OpIdx = 0, NumOps = FirstFI.CurrentInst->getNumOperands();
           OpIdx != NumOps; ++OpIdx) {

        if (constsDiffer(FInfos, OpIdx)) {
          // This instruction has operands which differ in at least some
          // functions. So we need to parameterize it.
          if (!tryMapToParameter(FInfos, OpIdx, Params)) {
            // We ran out of parameters.
            return false;
          }
        }
      }
    }
    // Go to the next instruction in all functions.
    for (FunctionInfo &FI : FInfos)
      FI.nextInst();
  } while (FirstFI.CurrentInst);

  return true;
}

/// Returns true if the number of operands of the current instruction differs.
bool MergeSimilarFunctions::numOperandsDiffer(FunctionInfos &FInfos) {
  unsigned numOps = FInfos[0].CurrentInst->getNumOperands();
  for (const FunctionInfo &FI : ArrayRef<FunctionInfo>(FInfos).drop_front(1)) {
    if (FI.CurrentInst->getNumOperands() != numOps)
      return true;
  }
  return false;
}

/// Returns true if the \p OpIdx's constant operand in the current instruction
/// does differ in any of the functions in \p FInfos.
bool MergeSimilarFunctions::constsDiffer(const FunctionInfos &FInfos,
                                         unsigned OpIdx) {
  Constant *CommonConst = nullptr;

  for (const FunctionInfo &FI : FInfos) {
    Value *Op = FI.CurrentInst->getOperand(OpIdx);
    if (auto *C = dyn_cast<Constant>(Op)) {
      if (!CommonConst) {
        CommonConst = C;
      } else if (C != CommonConst) {
        return true;
      }
    }
  }
  return false;
}

/// Create a new parameter for differing operands or try to reuse an existing
/// parameter.
/// Returns true if a parameter could be created or found without exceeding the
/// maximum number of parameters.
bool MergeSimilarFunctions::tryMapToParameter(FunctionInfos &FInfos,
                                              unsigned OpIdx,
                                              ParamInfos &Params) {
  ParamInfo *Matching = nullptr;
  // Try to find an existing parameter which exactly matches the differing
  // operands of the current instruction.
  for (ParamInfo &PI : Params) {
    if (PI.matches(FInfos, OpIdx)) {
      Matching = &PI;
      break;
    }
  }
  if (!Matching) {
    // We need a new parameter.
    // Check if we are within the limit.
    if (Params.size() >= maxAddedParams)
      return false;

    Params.resize(Params.size() + 1);
    Matching = &Params.back();
    // Store the constant values into the new parameter.
    Constant *FirstC = cast<Constant>(FInfos[0].CurrentInst->getOperand(OpIdx));
    for (FunctionInfo &FI : FInfos) {
      Constant *C = cast<Constant>(FI.CurrentInst->getOperand(OpIdx));
      Matching->Values.push_back(C);
      if (C != FirstC)
        FI.NumParamsNeeded += 1;
    }
  }
  /// Remember where the parameter is needed when we build our merged function.
  Matching->Uses.push_back({FInfos[0].CurrentInst, OpIdx});
  return true;
}

/// Merge all functions in \p FInfos by creating thunks which call the single
/// merged function with additional parameters.
void MergeSimilarFunctions::mergeWithParams(const FunctionInfos &FInfos,
                                            ParamInfos &Params) {
  // We reuse the body of the first function for the new merged function.
  Function *FirstF = FInfos.front().F;

  // Build the type for the merged function. This will be the type of the
  // original function (FirstF) but with the additional parameter which are
  // needed to parameterize the merged function.
  FunctionType *OrigTy = FirstF->getFunctionType();
  SmallVector<Type *, 8> ParamTypes(OrigTy->param_begin(), OrigTy->param_end());

  for (const ParamInfo &PI : Params) {
    ParamTypes.push_back(PI.Values[0]->getType());
  }

  FunctionType *funcType =
      FunctionType::get(OrigTy->getReturnType(), ParamTypes, false);

  // Create the new function.
  // TODO: Use a better name than just adding a suffix. Ideally it would be
  // a name which can be demangled in a meaningful way.
  Function *NewFunction = Function::Create(funcType, FirstF->getLinkage(),
                                           FirstF->getName() + "Tm");
  NewFunction->copyAttributesFrom(FirstF);
  // NOTE: this function is not externally available, do ensure that we reset
  // the DLL storage
  NewFunction->setDLLStorageClass(GlobalValue::DefaultStorageClass);
  NewFunction->setLinkage(GlobalValue::InternalLinkage);

  // Insert the new function after the last function in the equivalence class.
  FirstF->getParent()->getFunctionList().insert(
      std::next(FInfos[1].F->getIterator()), NewFunction);

  LLVM_DEBUG(dbgs() << "  Merge into " << NewFunction->getName() << '\n');

  // Move the body of FirstF into the NewFunction.
  NewFunction->getBasicBlockList().splice(NewFunction->begin(),
                                          FirstF->getBasicBlockList());

  auto NewArgIter = NewFunction->arg_begin();
  for (Argument &OrigArg : FirstF->args()) {
    Argument &NewArg = *NewArgIter++;
    OrigArg.replaceAllUsesWith(&NewArg);
  }

  SmallPtrSet<Function *, 8> SelfReferencingFunctions;

  // Replace all differing operands with a parameter.
  for (const ParamInfo &PI : Params) {
    Argument *NewArg = &*NewArgIter++;
    for (const OpLocation &OL : PI.Uses) {
      OL.I->setOperand(OL.OpIndex, NewArg);
    }
    ParamTypes.push_back(PI.Values[0]->getType());

    // Collect all functions which are referenced by any parameter.
    for (Value *V : PI.Values) {
      if (auto *F = dyn_cast<Function>(V))
        SelfReferencingFunctions.insert(F);
    }
  }

  for (unsigned FIdx = 0, NumFuncs = FInfos.size(); FIdx < NumFuncs; ++FIdx) {
    Function *OrigFunc = FInfos[FIdx].F;
    // Don't try to replace all callers of functions which are used as
    // parameters because we must not delete such functions.
    if (SelfReferencingFunctions.count(OrigFunc) == 0 &&
        replaceDirectCallers(OrigFunc, NewFunction, Params, FIdx)) {
      // We could replace all uses (and the function is not externally visible),
      // so we can delete the original function.
      auto Iter = FuncEntries.find(OrigFunc);
      assert(Iter != FuncEntries.end());
      assert(!isInEquivalenceClass(&*Iter->second));
      Iter->second->F = nullptr;
      FuncEntries.erase(Iter);
      LLVM_DEBUG(dbgs() << "    Erase " << OrigFunc->getName() << '\n');
      OrigFunc->eraseFromParent();
    } else {
      // Otherwise we need a thunk which calls the merged function.
      writeThunk(NewFunction, OrigFunc, Params, FIdx);
    }
    ++NumSimilarFunctionsMerged;
  }
}

/// Remove all functions of \p FE's equivalence class from FnTree. Add them to
/// Deferred so that we'll look at them in the next round.
void MergeSimilarFunctions::removeEquivalenceClassFromTree(FunctionEntry *FE) {
  if (!isInEquivalenceClass(FE))
    return;

  FnTreeType::iterator Iter = FE->TreeIter;
  FunctionEntry *Unlink = Iter->First;
  Unlink->numUnhandledCallees = 0;
  while (Unlink) {
    LLVM_DEBUG(dbgs() << "    remove from tree: " << Unlink->F->getName()
                      << '\n');
    if (!Unlink->isMerged)
      Deferred.emplace_back(Unlink->F);
    Unlink->TreeIter = FnTree.end();
    assert(Unlink->numUnhandledCallees == 0);
    FunctionEntry *NextEntry = Unlink->Next;
    Unlink->Next = nullptr;
    Unlink = NextEntry;
  }
  FnTree.erase(Iter);
}

// Helper for writeThunk,
// Selects proper bitcast operation,
// but a bit simpler then CastInst::getCastOpcode.
static Value *createCast(IRBuilder<> &Builder, Value *V, Type *DestTy) {
  Type *SrcTy = V->getType();
  if (SrcTy->isStructTy()) {
    assert(DestTy->isStructTy());
    assert(SrcTy->getStructNumElements() == DestTy->getStructNumElements());
    Value *Result = UndefValue::get(DestTy);
    for (unsigned int I = 0, E = SrcTy->getStructNumElements(); I < E; ++I) {
      Value *Element =
          createCast(Builder, Builder.CreateExtractValue(V, makeArrayRef(I)),
                     DestTy->getStructElementType(I));

      Result = Builder.CreateInsertValue(Result, Element, makeArrayRef(I));
    }
    return Result;
  }
  assert(!DestTy->isStructTy());
  if (SrcTy->isIntegerTy() && DestTy->isPointerTy())
    return Builder.CreateIntToPtr(V, DestTy);
  else if (SrcTy->isPointerTy() && DestTy->isIntegerTy())
    return Builder.CreatePtrToInt(V, DestTy);
  else
    return Builder.CreateBitCast(V, DestTy);
}

/// Replace \p Thunk with a simple tail call to \p ToFunc. Also add parameters
/// to the call to \p ToFunc, which are defined by the FuncIdx's value in
/// \p Params.
void MergeSimilarFunctions::writeThunk(Function *ToFunc, Function *Thunk,
                                       const ParamInfos &Params,
                                       unsigned FuncIdx) {
  // Delete the existing content of Thunk.
  Thunk->dropAllReferences();

  BasicBlock *BB = BasicBlock::Create(Thunk->getContext(), "", Thunk);
  IRBuilder<> Builder(BB);

  SmallVector<Value *, 16> Args;
  unsigned ParamIdx = 0;
  FunctionType *ToFuncTy = ToFunc->getFunctionType();

  // Add arguments which are passed through Thunk.
  for (Argument &AI : Thunk->args()) {
    Args.push_back(createCast(Builder, &AI, ToFuncTy->getParamType(ParamIdx)));
    ++ParamIdx;
  }
  // Add new arguments defined by Params.
  for (const ParamInfo &PI : Params) {
    assert(ParamIdx < ToFuncTy->getNumParams());
    Args.push_back(createCast(Builder, PI.Values[FuncIdx],
                              ToFuncTy->getParamType(ParamIdx)));
    ++ParamIdx;
  }

  CallInst *CI = Builder.CreateCall(ToFunc, Args);
  CI->setTailCall();
  CI->setCallingConv(ToFunc->getCallingConv());
  CI->setAttributes(ToFunc->getAttributes());
  if (Thunk->getReturnType()->isVoidTy()) {
    Builder.CreateRetVoid();
  } else {
    Builder.CreateRet(createCast(Builder, CI, Thunk->getReturnType()));
  }

  LLVM_DEBUG(dbgs() << "    writeThunk: " << Thunk->getName() << '\n');
  ++NumThunksWritten;
}

/// Replace direct callers of Old with New. Also add parameters to the call to
/// \p New, which are defined by the FuncIdx's value in \p Params.
bool MergeSimilarFunctions::replaceDirectCallers(Function *Old, Function *New,
                                                 const ParamInfos &Params,
                                                 unsigned FuncIdx) {
  bool AllReplaced = true;

  SmallVector<CallInst *, 8> Callers;

  for (Use &U : Old->uses()) {
    auto *I = dyn_cast<Instruction>(U.getUser());
    if (!I) {
      AllReplaced = false;
      continue;
    }
    FunctionEntry *FE = getEntry(I->getFunction());
    if (FE)
      removeEquivalenceClassFromTree(FE);

    auto *CI = dyn_cast<CallInst>(I);
    if (!CI || CI->getCalledValue() != Old) {
      AllReplaced = false;
      continue;
    }
    Callers.push_back(CI);
  }
  if (!AllReplaced)
    return false;

  for (CallInst *CI : Callers) {
    auto &Context = New->getContext();
    auto NewPAL = New->getAttributes();

    SmallVector<Type *, 8> OldParamTypes;
    SmallVector<Value *, 16> NewArgs;
    SmallVector<AttributeSet, 8> NewArgAttrs;
    IRBuilder<> Builder(CI);

    FunctionType *NewFuncTy = New->getFunctionType();
    (void)NewFuncTy;
    unsigned ParamIdx = 0;

    // Add the existing parameters.
    for (Value *OldArg : CI->arg_operands()) {
      NewArgAttrs.push_back(NewPAL.getParamAttributes(ParamIdx));
      NewArgs.push_back(OldArg);
      OldParamTypes.push_back(OldArg->getType());
      ++ParamIdx;
    }
    // Add the new parameters.
    for (const ParamInfo &PI : Params) {
      assert(ParamIdx < NewFuncTy->getNumParams());
      Constant *ArgValue = PI.Values[FuncIdx];
      assert(ArgValue != Old && "should not try to replace all callers of self "
                                "referencing functions");
      NewArgs.push_back(ArgValue);
      OldParamTypes.push_back(ArgValue->getType());
      ++ParamIdx;
    }

    auto *FType = FunctionType::get(Old->getFunctionType()->getReturnType(),
                                    OldParamTypes, false);
    auto *FPtrType = PointerType::get(
        FType, cast<PointerType>(New->getType())->getAddressSpace());

    Value *Callee = ConstantExpr::getBitCast(New, FPtrType);
    CallInst *NewCI = Builder.CreateCall(Callee, NewArgs);
    NewCI->setCallingConv(CI->getCallingConv());
    // Don't transfer attributes from the function to the callee. Function
    // attributes typically aren't relevant to the calling convention or ABI.
    NewCI->setAttributes(AttributeList::get(Context, /*FnAttrs=*/AttributeSet(),
                                            NewPAL.getRetAttributes(),
                                            NewArgAttrs));
    CI->replaceAllUsesWith(NewCI);
    CI->eraseFromParent();
  }
  assert(Old->use_empty() && "should have replaced all uses of old function");
  return Old->hasLocalLinkage();
}
