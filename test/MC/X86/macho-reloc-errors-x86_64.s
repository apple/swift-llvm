// RUN: not llvm-mc -triple=x86_64-apple-darwin -filetype=obj -o /dev/null %s 2>&1 | FileCheck %s --check-prefix=CHECK-ERROR

        mov %rax, thing
        mov %rax, thing@GOT-thing2@GOT
        mov %rax, (thing-thing2)(%rip)
        mov %rax, thing-thing
        mov %rax, thing-thing2

// CHECK-ERROR: 3:9: error: 32-bit absolute addressing is not supported in 64-bit mode
// CHECK-ERROR: 4:9: error: unsupported relocation of modified symbol
// CHECK-ERROR: 5:9: error: unsupported pc-relative relocation of difference
// CHECK-ERROR: 6:9: error: unsupported relocation with identical base
// CHECK-ERROR: 7:9: error: unsupported relocation with subtraction expression, symbol 'thing' can not be undefined in a subtraction expression
