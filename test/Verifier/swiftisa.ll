; RUN: not llvm-as %s -o /dev/null 2>&1 | FileCheck %s

declare void @a(i32* swiftisa %a, i32* swiftisa %b)
; CHECK: Cannot have multiple 'swiftisa' parameters!
