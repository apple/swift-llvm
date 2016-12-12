//===--- RecordLayout.h - Convenience wrappers for bitcode ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// \file Convenience wrappers for the LLVM bitcode format and bitstream APIs.
///
/// This allows you to use a sort of DSL to declare and use bitcode abbrevs
/// and records. Example:
///
/// \code
///     using Metadata = BCRecordLayout<
///       METADATA_ID, // ID
///       BCFixed<16>, // Module format major version
///       BCFixed<16>, // Module format minor version
///       BCBlob // misc. version information
///     >;
///     unsigned MetadataAbbrevCode = Metadata::emitAbbrev(Out);
///     Metadata::emitRecord(Out, ScratchRecord, MetadataAbbrevCode,
///                          VERSION_MAJOR, VERSION_MINOR, extraData);
/// \endcode
///
/// For details on the bitcode format, see
///   http://llvm.org/docs/BitCodeFormat.html
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_BITCODE_RECORDLAYOUT_H
#define LLVM_BITCODE_RECORDLAYOUT_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Bitcode/BitCodes.h"
#include "llvm/Bitcode/BitstreamWriter.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/MathExtras.h"

namespace llvm {

namespace impl {
  /// Convenience base for all kinds of bitcode abbreviation fields.
  ///
  /// This just defines common properties queried by the metaprogramming.
  template<bool COMPOUND = false>
  class BCField {
  public:
    static const bool IS_COMPOUND = COMPOUND;

    /// Asserts that the given data is a valid value for this field.
    template<typename T>
    static void assertValid(const T &data) {}

    /// Converts a raw numeric representation of this value to its preferred
    /// type.
    template<typename T>
    static T convert(T rawValue) {
      return rawValue;
    }
  };
} // end namespace impl


/// Represents a literal operand in a bitcode record.
///
/// The value of a literal operand is the same for all instances of the record,
/// so it is only emitted in the abbreviation definition.
///
/// Note that because this uses a compile-time template, you cannot have a
/// literal operand that is fixed at run-time without dropping down to the
/// raw LLVM APIs.
template<uint64_t Value>
class BCLiteral : public impl::BCField<> {
public:
  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(Value));
  }

  template<typename T>
  static void assertValid(const T &data) {
    assert(data == Value && "data value does not match declared literal value");
  }
};

/// Represents a fixed-width value in a bitcode record.
///
/// Note that the LLVM bitcode format only supports unsigned values.
template<unsigned Width>
class BCFixed : public impl::BCField<> {
public:
  static_assert(Width <= 64, "fixed-width field is too large");

  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(llvm::BitCodeAbbrevOp::Fixed, Width));
  }

  static void assertValid(const bool &data) {
    assert(llvm::isUInt<Width>(data) &&
           "data value does not fit in the given bit width");
  }

  template<typename T>
  static void assertValid(const T &data) {
    assert(data >= 0 && "cannot encode signed integers");
    assert(llvm::isUInt<Width>(data) &&
           "data value does not fit in the given bit width");
  }
};

/// Represents a variable-width value in a bitcode record.
///
/// The \p Width parameter should include the continuation bit.
///
/// Note that the LLVM bitcode format only supports unsigned values.
template<unsigned Width>
class BCVBR : public impl::BCField<> {
  static_assert(Width >= 2, "width does not have room for continuation bit");

public:
  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(llvm::BitCodeAbbrevOp::VBR, Width));
  }

  template<typename T>
  static void assertValid(const T &data) {
    assert(data >= 0 && "cannot encode signed integers");
  }
};

/// Represents a character encoded in LLVM's Char6 encoding.
///
/// This format is suitable for encoding decimal numbers (without signs or
/// exponents) and C identifiers (without dollar signs), but not much else.
///
/// \sa http://llvm.org/docs/BitCodeFormat.html#char6-encoded-value
class BCChar6 : public impl::BCField<> {
public:
  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(llvm::BitCodeAbbrevOp::Char6));
  }

  template<typename T>
  static void assertValid(const T &data) {
    assert(llvm::BitCodeAbbrevOp::isChar6(data) && "invalid Char6 data");
  }

  template<typename T>
  char convert(T rawValue) {
    return static_cast<char>(rawValue);
  }
};

/// Represents an untyped blob of bytes.
///
/// If present, this must be the last field in a record.
class BCBlob : public impl::BCField<true> {
public:
  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(llvm::BitCodeAbbrevOp::Blob));
  }
};

/// Represents an array of some other type.
///
/// If present, this must be the last field in a record.
template<typename Element>
class BCArray : public impl::BCField<true> {
  static_assert(!Element::IS_COMPOUND, "arrays can only contain scalar types");
public:
  static void emitOp(llvm::BitCodeAbbrev &abbrev) {
    abbrev.Add(llvm::BitCodeAbbrevOp(llvm::BitCodeAbbrevOp::Array));
    Element::emitOp(abbrev);
  }
};


namespace impl {
  /// Attaches the last field to an abbreviation.
  ///
  /// This is the base case for \c emitOps.
  ///
  /// \sa BCRecordLayout::emitAbbrev
  template<typename Last>
  static void emitOps(llvm::BitCodeAbbrev &abbrev) {
    Last::emitOp(abbrev);
  }

  /// Attaches fields to an abbreviation.
  ///
  /// This is the recursive case for \c emitOps.
  ///
  /// \sa BCRecordLayout::emitAbbrev
  template<typename First, typename Next, typename ...Rest>
  static void emitOps(llvm::BitCodeAbbrev &abbrev) {
    static_assert(!First::IS_COMPOUND,
                  "arrays and blobs may not appear in the middle of a record");
    First::emitOp(abbrev);
    emitOps<Next, Rest...>(abbrev);
  }


  /// Helper class for dealing with a scalar element in the middle of a record.
  ///
  /// \sa BCRecordLayout
  template<typename First, typename... Fields>
  class BCRecordCoding {
  public:
    template <typename BufferTy, typename FirstData, typename... Data>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, FirstData data, Data... rest) {
      static_assert(!First::IS_COMPOUND,
                    "arrays and blobs may not appear in the middle of a record");
      First::assertValid(data);
      buffer.push_back(data);
      BCRecordCoding<Fields...>::emit(out, buffer, abbrCode, rest...);
    }

    template <typename ElementTy, typename FirstData, typename... Data>
    static void read(ArrayRef<ElementTy> buffer,
                     FirstData &data, Data &&...rest) {
      assert(!buffer.empty() && "too few elements in buffer");
      data = First::convert(buffer.front());
      BCRecordCoding<Fields...>::read(buffer.slice(1),
                                      std::forward<Data>(rest)...);
    }

    template <typename ElementTy, typename... Data>
    static void read(ArrayRef<ElementTy> buffer,
                     NoneType, Data &&...rest) {
      assert(!buffer.empty() && "too few elements in buffer");
      BCRecordCoding<Fields...>::read(buffer.slice(1),
                                      std::forward<Data>(rest)...);
    }
  };

  /// Helper class for dealing with a scalar element at the end of a record.
  ///
  /// This has a separate implementation because up until now we've only been
  /// \em building the record (into a data buffer), and now we need to hand it
  /// off to the BitstreamWriter to be emitted.
  ///
  /// \sa BCRecordLayout
  template<typename Last>
  class BCRecordCoding<Last> {
  public:
    template <typename BufferTy, typename LastData>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, LastData data) {
      static_assert(!Last::IS_COMPOUND,
                    "arrays and blobs need special handling");
      Last::assertValid(data);
      buffer.push_back(data);
      out.EmitRecordWithAbbrev(abbrCode, buffer);
    }

    template <typename ElementTy, typename LastData>
    static void read(ArrayRef<ElementTy> buffer, LastData &data) {
      assert(buffer.size() == 1 && "record data does not match layout");
      data = Last::convert(buffer.front());
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer, NoneType) {
      assert(buffer.size() == 1 && "record data does not match layout");
      (void)buffer;
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer) = delete;
  };

  /// Helper class for dealing with an array at the end of a record.
  ///
  /// \sa BCRecordLayout::emitRecord
  template<typename EleTy>
  class BCRecordCoding<BCArray<EleTy>> {
  public:
    template <typename BufferTy>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, StringRef arrayData) {
      // FIXME: validate array data.
      out.EmitRecordWithArray(abbrCode, buffer, arrayData);
    }

    template <typename BufferTy, typename ArrayTy>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, const ArrayTy &arrayData) {
#ifndef NDEBUG
      for (auto &item : arrayData)
        EleTy::assertValid(item);
#endif
      buffer.reserve(buffer.size() + arrayData.size());
      std::copy(arrayData.begin(), arrayData.end(),
                std::back_inserter(buffer));
      out.EmitRecordWithAbbrev(abbrCode, buffer);
    }

    template <typename BufferTy, typename FirstData, typename ...RestData>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, FirstData firstData,
                     RestData... restData) {
      std::array<FirstData, 1+sizeof...(restData)> arrayData{ {
        firstData,
        restData...
      } };
      emit(out, buffer, abbrCode, arrayData);
    }

    template <typename BufferTy>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, NoneType) {
      out.EmitRecordWithAbbrev(abbrCode, buffer);
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer, ArrayRef<ElementTy> &rawData) {
      rawData = buffer;
    }

    template <typename ElementTy, typename ArrayTy>
    static void read(ArrayRef<ElementTy> buffer, ArrayTy &array) {
      array.append(llvm::map_iterator(buffer.begin(), ElementTy::convert),
                   llvm::map_iterator(buffer.end(), ElementTy::convert));
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer, NoneType) {
      (void)buffer;
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer) = delete;
  };

  /// Helper class for dealing with a blob at the end of a record.
  ///
  /// \sa BCRecordLayout
  template<>
  class BCRecordCoding<BCBlob> {
  public:
    template <typename BufferTy>
    static void emit(llvm::BitstreamWriter &out, BufferTy &buffer,
                     unsigned abbrCode, StringRef blobData) {
      out.EmitRecordWithBlob(abbrCode, buffer, blobData);
    }

    template <typename ElementTy>
    static void read(ArrayRef<ElementTy> buffer) {
      (void)buffer;
    }

    /// Blob data is not stored in the buffer if you are using the correct
    /// accessor; this method should not be used.
    template <typename ElementTy, typename DataTy>
    static void read(ArrayRef<ElementTy> buffer, DataTy &data) = delete;
  };

  /// A type trait whose \c type field is the last of its template parameters.
  template<typename First, typename ...Rest>
  struct last_type {
    using type = typename last_type<Rest...>::type;
  };

  template<typename Last>
  struct last_type<Last> {
    using type = Last;
  };

  /// A type trait whose \c value field is \c true if the last type is BCBlob.
  template<typename ...Types>
  using has_blob = std::is_same<BCBlob, typename last_type<int, Types...>::type>;

  /// A type trait whose \c value field is \c true if the given type is a
  /// BCArray (of any element kind).
  template <typename T>
  struct is_array {
  private:
    template <typename E>
    static bool check(BCArray<E> *);
    static int check(...);

  public:
    typedef bool value_type;
    static constexpr bool value =
      !std::is_same<decltype(check((T*)nullptr)),
                    decltype(check(false))>::value;
  };

  /// A type trait whose \c value field is \c true if the last type is a
  /// BCArray (of any element kind).
  template<typename ...Types>
  using has_array = is_array<typename last_type<int, Types...>::type>;
} // end namespace impl

/// Represents a single bitcode record type.
///
/// This class template is meant to be instantiated and then given a name,
/// so that from then on that name can be used 
template<typename IDField, typename... Fields>
class BCGenericRecordLayout {
  llvm::BitstreamWriter &Out;

public:
  /// The abbreviation code used for this record in the current block.
  ///
  /// Note that this is not the same as the semantic record code, which is the
  /// first field of the record.
  const unsigned AbbrevCode;

  /// Create a layout and register it with the given bitstream writer.
  explicit BCGenericRecordLayout(llvm::BitstreamWriter &out)
    : Out(out), AbbrevCode(emitAbbrev(out)) {}

  /// Emit a record to the bitstream writer, using the given buffer for scratch
  /// space.
  ///
  /// Note that even fixed arguments must be specified here.
  template <typename BufferTy, typename... Data>
  void emit(BufferTy &buffer, unsigned recordID, Data... data) const {
    emitRecord(Out, buffer, AbbrevCode, recordID, data...);
  }

  /// Registers this record's layout with the bitstream reader.
  ///
  /// \returns The abbreviation code for the newly-registered record type.
  static unsigned emitAbbrev(llvm::BitstreamWriter &out) {
    auto *abbrev = new llvm::BitCodeAbbrev();
    impl::emitOps<IDField, Fields...>(*abbrev);
    return out.EmitAbbrev(abbrev);
  }

  /// Emit a record identified by \p abbrCode to bitstream reader \p out, using
  /// \p buffer for scratch space.
  ///
  /// Note that even fixed arguments must be specified here. Blobs are passed
  /// as StringRefs, while arrays can be passed inline, as aggregates, or as
  /// pre-encoded StringRef data. Skipped values and empty arrays should use
  /// the special Nothing value.
  template <typename BufferTy, typename... Data>
  static void emitRecord(llvm::BitstreamWriter &out, BufferTy &buffer,
                         unsigned abbrCode, unsigned recordID, Data... data) {
    static_assert(sizeof...(data) <= sizeof...(Fields) ||
                  impl::has_array<Fields...>::value,
                  "Too many record elements");
    static_assert(sizeof...(data) >= sizeof...(Fields),
                  "Too few record elements");
    buffer.clear();
    impl::BCRecordCoding<IDField, Fields...>::emit(out, buffer, abbrCode,
                                                   recordID, data...);
  }

  /// Extract record data from \p buffer into the given data fields.
  ///
  /// Note that even fixed arguments must be specified here. Pass \c Nothing
  /// if you don't care about a particular parameter. Blob data is not included
  /// in the buffer and should be handled separately by the caller.
  template <typename ElementTy, typename... Data>
  static void readRecord(ArrayRef<ElementTy> buffer, Data &&... data) {
    static_assert(sizeof...(data) <= sizeof...(Fields),
                  "Too many record elements");
    static_assert(sizeof...(Fields) <=
                  sizeof...(data) + impl::has_blob<Fields...>::value,
                  "Too few record elements");
    return impl::BCRecordCoding<Fields...>::read(buffer,
                                                 std::forward<Data>(data)...);
  }

  /// Extract record data from \p buffer into the given data fields.
  ///
  /// Note that even fixed arguments must be specified here. Pass \c Nothing
  /// if you don't care about a particular parameter. Blob data is not included
  /// in the buffer and should be handled separately by the caller.
  template <typename BufferTy, typename... Data>
  static void readRecord(BufferTy &buffer, Data &&... data) {
    return readRecord(llvm::makeArrayRef(buffer), std::forward<Data>(data)...);
  }
};

/// A record with a fixed record code.
template<unsigned RecordCode, typename... Fields>
class BCRecordLayout : public BCGenericRecordLayout<BCLiteral<RecordCode>,
                                                    Fields...> {
  using Base = BCGenericRecordLayout<BCLiteral<RecordCode>, Fields...>;
public:
  enum : unsigned {
    /// The record code associated with this layout.
    Code = RecordCode
  };

  /// Create a layout and register it with the given bitstream writer.
  explicit BCRecordLayout(llvm::BitstreamWriter &out) : Base(out) {}

  /// Emit a record to the bitstream writer, using the given buffer for scratch
  /// space.
  ///
  /// Note that even fixed arguments must be specified here.
  template <typename BufferTy, typename... Data>
  void emit(BufferTy &buffer, Data... data) const {
    Base::emit(buffer, RecordCode, data...);
  }

  /// Emit a record identified by \p abbrCode to bitstream reader \p out, using
  /// \p buffer for scratch space.
  ///
  /// Note that even fixed arguments must be specified here. Currently, arrays
  /// and blobs can only be passed as StringRefs.
  template <typename BufferTy, typename... Data>
  static void emitRecord(llvm::BitstreamWriter &out, BufferTy &buffer,
                         unsigned abbrCode, Data... data) {
    Base::emitRecord(out, buffer, abbrCode, RecordCode, data...);
  }
};

/// RAII object to pair entering and exiting a sub-block.
class BCBlockRAII {
  llvm::BitstreamWriter &Writer;
public:
  BCBlockRAII(llvm::BitstreamWriter &writer, unsigned blockID,
              unsigned abbrevLen)
    : Writer(writer) {
    writer.EnterSubblock(blockID, abbrevLen);
  }

  ~BCBlockRAII() {
    Writer.ExitBlock();
  }
};

} // end namespace llvm

#endif
