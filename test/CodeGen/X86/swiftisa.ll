; RUN: llc -verify-machineinstrs -mtriple=x86_64-unknown-unknown -o - %s | FileCheck --check-prefix=CHECK --check-prefix=OPT %s
; RUN: llc -O0 -verify-machineinstrs -mtriple=x86_64-unknown-unknown -o - %s | FileCheck %s

; Parameter with swiftisa should be allocated to r14.
; CHECK-LABEL: swiftisa_param:
; CHECK: movq %r14, %rax
define i8 *@swiftisa_param(i8* swiftisa %addr0) {
    ret i8 *%addr0
}

; Check that r14 is used to pass a swiftisa argument.
; CHECK-LABEL: call_swiftisa:
; CHECK: movq %rdi, %r14
; CHECK: callq {{_?}}swiftisa_param
define i8 *@call_swiftisa(i8* %arg) {
  %res = call i8 *@swiftisa_param(i8* swiftisa %arg)
  ret i8 *%res
}

; r14 should be saved by the callee even if used for swiftisa
; CHECK-LABEL: swiftisa_clobber:
; CHECK: pushq %r14
; ...
; CHECK: popq %r14
define i8 *@swiftisa_clobber(i8* swiftisa %addr0) {
  call void asm sideeffect "nop", "~{r14}"()
  ret i8 *%addr0
}

; Demonstrate that we do not need any movs when calling multiple functions
; with swiftisa argument.
; CHECK-LABEL: swiftisa_passthrough:
; OPT-NOT: mov{{.*}}r14
; OPT: callq {{_?}}swiftisa_param
; OPT-NOT: mov{{.*}}r14
; OPT-NEXT: callq {{_?}}swiftisa_param
define void @swiftisa_passthrough(i8* swiftisa %addr0) {
  call i8 *@swiftisa_param(i8* swiftisa %addr0)
  call i8 *@swiftisa_param(i8* swiftisa %addr0)
  ret void
}
