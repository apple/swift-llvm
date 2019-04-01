; RUN: opt -S -mtriple i686-windows -merge-similar-functions -mergesimfunc-threshold=4 %s | FileCheck %s

@g = external global i32

define dllexport i32 @f(i32 %x, i32 %y) {
  %sum = add i32 %x, %y
  %sum2 = add i32 %sum, %y
  %l = load i32, i32* @g, align 4
  %sum3 = add i32 %sum2, %y
  ret i32 %sum3
}

define dllexport i32 @h(i32 %x, i32 %y) {
  %sum = add i32 %x, %y
  %sum2 = add i32 %sum, %y
  %l = load i32, i32* @g, align 4
  %sum3 = add i32 %sum2, %y
  ret i32 %sum3
}

; CHECK-NOT: define internal dllexport i32 @fTm(i32, i32)
; CHECK-LABEL: define internal i32 @fTm(i32, i32)

