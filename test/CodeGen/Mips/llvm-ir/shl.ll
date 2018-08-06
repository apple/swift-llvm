; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips2 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS2
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS32
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r2 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS32R2
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r3 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS32R2
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r5 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS32R2
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r6 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS32R6
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips3 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS3
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips4 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS4
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips64 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS64
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips64r2 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS64R2
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips64r3 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS64R2
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips64r5 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS64R2
; RUN: llc < %s -mtriple=mips64-linux-gnu -mcpu=mips64r6 -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MIPS64R6
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r3 -mattr=+micromips -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MMR3
; RUN: llc < %s -mtriple=mips-linux-gnu -mcpu=mips32r6 -mattr=+micromips -relocation-model=pic | FileCheck %s \
; RUN:    -check-prefix=MMR6

define signext i1 @shl_i1(i1 signext %a, i1 signext %b) {
; MIPS2-LABEL: shl_i1:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    move $2, $4
;
; MIPS32-LABEL: shl_i1:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    move $2, $4
;
; MIPS32R2-LABEL: shl_i1:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    move $2, $4
;
; MIPS32R6-LABEL: shl_i1:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    move $2, $4
;
; MIPS3-LABEL: shl_i1:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    move $2, $4
;
; MIPS4-LABEL: shl_i1:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    move $2, $4
;
; MIPS64-LABEL: shl_i1:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    move $2, $4
;
; MIPS64R2-LABEL: shl_i1:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    move $2, $4
;
; MIPS64R6-LABEL: shl_i1:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    move $2, $4
;
; MMR3-LABEL: shl_i1:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    move $2, $4
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: shl_i1:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    move $2, $4
; MMR6-NEXT:    jrc $ra
entry:

  %r = shl i1 %a, %b
  ret i1 %r
}

define signext i8 @shl_i8(i8 signext %a, i8 signext %b) {
; MIPS2-LABEL: shl_i8:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    andi $1, $5, 255
; MIPS2-NEXT:    sllv $1, $4, $1
; MIPS2-NEXT:    sll $1, $1, 24
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    sra $2, $1, 24
;
; MIPS32-LABEL: shl_i8:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    andi $1, $5, 255
; MIPS32-NEXT:    sllv $1, $4, $1
; MIPS32-NEXT:    sll $1, $1, 24
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    sra $2, $1, 24
;
; MIPS32R2-LABEL: shl_i8:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    andi $1, $5, 255
; MIPS32R2-NEXT:    sllv $1, $4, $1
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    seb $2, $1
;
; MIPS32R6-LABEL: shl_i8:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    andi $1, $5, 255
; MIPS32R6-NEXT:    sllv $1, $4, $1
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    seb $2, $1
;
; MIPS3-LABEL: shl_i8:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    andi $1, $5, 255
; MIPS3-NEXT:    sllv $1, $4, $1
; MIPS3-NEXT:    sll $1, $1, 24
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    sra $2, $1, 24
;
; MIPS4-LABEL: shl_i8:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    andi $1, $5, 255
; MIPS4-NEXT:    sllv $1, $4, $1
; MIPS4-NEXT:    sll $1, $1, 24
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    sra $2, $1, 24
;
; MIPS64-LABEL: shl_i8:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    andi $1, $5, 255
; MIPS64-NEXT:    sllv $1, $4, $1
; MIPS64-NEXT:    sll $1, $1, 24
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    sra $2, $1, 24
;
; MIPS64R2-LABEL: shl_i8:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    andi $1, $5, 255
; MIPS64R2-NEXT:    sllv $1, $4, $1
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    seb $2, $1
;
; MIPS64R6-LABEL: shl_i8:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    andi $1, $5, 255
; MIPS64R6-NEXT:    sllv $1, $4, $1
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    seb $2, $1
;
; MMR3-LABEL: shl_i8:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    andi16 $2, $5, 255
; MMR3-NEXT:    sllv $1, $4, $2
; MMR3-NEXT:    jr $ra
; MMR3-NEXT:    seb $2, $1
;
; MMR6-LABEL: shl_i8:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    andi16 $2, $5, 255
; MMR6-NEXT:    sllv $1, $4, $2
; MMR6-NEXT:    seb $2, $1
; MMR6-NEXT:    jrc $ra
entry:

  %r = shl i8 %a, %b
  ret i8 %r
}

define signext i16 @shl_i16(i16 signext %a, i16 signext %b) {
; MIPS2-LABEL: shl_i16:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    andi $1, $5, 65535
; MIPS2-NEXT:    sllv $1, $4, $1
; MIPS2-NEXT:    sll $1, $1, 16
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    sra $2, $1, 16
;
; MIPS32-LABEL: shl_i16:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    andi $1, $5, 65535
; MIPS32-NEXT:    sllv $1, $4, $1
; MIPS32-NEXT:    sll $1, $1, 16
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    sra $2, $1, 16
;
; MIPS32R2-LABEL: shl_i16:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    andi $1, $5, 65535
; MIPS32R2-NEXT:    sllv $1, $4, $1
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    seh $2, $1
;
; MIPS32R6-LABEL: shl_i16:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    andi $1, $5, 65535
; MIPS32R6-NEXT:    sllv $1, $4, $1
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    seh $2, $1
;
; MIPS3-LABEL: shl_i16:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    andi $1, $5, 65535
; MIPS3-NEXT:    sllv $1, $4, $1
; MIPS3-NEXT:    sll $1, $1, 16
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    sra $2, $1, 16
;
; MIPS4-LABEL: shl_i16:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    andi $1, $5, 65535
; MIPS4-NEXT:    sllv $1, $4, $1
; MIPS4-NEXT:    sll $1, $1, 16
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    sra $2, $1, 16
;
; MIPS64-LABEL: shl_i16:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    andi $1, $5, 65535
; MIPS64-NEXT:    sllv $1, $4, $1
; MIPS64-NEXT:    sll $1, $1, 16
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    sra $2, $1, 16
;
; MIPS64R2-LABEL: shl_i16:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    andi $1, $5, 65535
; MIPS64R2-NEXT:    sllv $1, $4, $1
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    seh $2, $1
;
; MIPS64R6-LABEL: shl_i16:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    andi $1, $5, 65535
; MIPS64R6-NEXT:    sllv $1, $4, $1
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    seh $2, $1
;
; MMR3-LABEL: shl_i16:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    andi16 $2, $5, 65535
; MMR3-NEXT:    sllv $1, $4, $2
; MMR3-NEXT:    jr $ra
; MMR3-NEXT:    seh $2, $1
;
; MMR6-LABEL: shl_i16:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    andi16 $2, $5, 65535
; MMR6-NEXT:    sllv $1, $4, $2
; MMR6-NEXT:    seh $2, $1
; MMR6-NEXT:    jrc $ra
entry:

  %r = shl i16 %a, %b
  ret i16 %r
}

define signext i32 @shl_i32(i32 signext %a, i32 signext %b) {
; MIPS2-LABEL: shl_i32:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    sllv $2, $4, $5
;
; MIPS32-LABEL: shl_i32:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    sllv $2, $4, $5
;
; MIPS32R2-LABEL: shl_i32:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    sllv $2, $4, $5
;
; MIPS32R6-LABEL: shl_i32:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    sllv $2, $4, $5
;
; MIPS3-LABEL: shl_i32:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    sllv $2, $4, $5
;
; MIPS4-LABEL: shl_i32:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    sllv $2, $4, $5
;
; MIPS64-LABEL: shl_i32:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    sllv $2, $4, $5
;
; MIPS64R2-LABEL: shl_i32:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    sllv $2, $4, $5
;
; MIPS64R6-LABEL: shl_i32:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    sllv $2, $4, $5
;
; MMR3-LABEL: shl_i32:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    jr $ra
; MMR3-NEXT:    sllv $2, $4, $5
;
; MMR6-LABEL: shl_i32:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    sllv $2, $4, $5
; MMR6-NEXT:    jrc $ra
entry:

  %r = shl i32 %a, %b
  ret i32 %r
}

define signext i64 @shl_i64(i64 signext %a, i64 signext %b) {
; MIPS2-LABEL: shl_i64:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    sllv $6, $5, $7
; MIPS2-NEXT:    andi $8, $7, 32
; MIPS2-NEXT:    beqz $8, $BB4_3
; MIPS2-NEXT:    move $2, $6
; MIPS2-NEXT:  # %bb.1: # %entry
; MIPS2-NEXT:    beqz $8, $BB4_4
; MIPS2-NEXT:    addiu $3, $zero, 0
; MIPS2-NEXT:  $BB4_2: # %entry
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  $BB4_3: # %entry
; MIPS2-NEXT:    sllv $1, $4, $7
; MIPS2-NEXT:    not $2, $7
; MIPS2-NEXT:    srl $3, $5, 1
; MIPS2-NEXT:    srlv $2, $3, $2
; MIPS2-NEXT:    or $2, $1, $2
; MIPS2-NEXT:    bnez $8, $BB4_2
; MIPS2-NEXT:    addiu $3, $zero, 0
; MIPS2-NEXT:  $BB4_4: # %entry
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    move $3, $6
;
; MIPS32-LABEL: shl_i64:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    sllv $1, $4, $7
; MIPS32-NEXT:    not $2, $7
; MIPS32-NEXT:    srl $3, $5, 1
; MIPS32-NEXT:    srlv $2, $3, $2
; MIPS32-NEXT:    or $2, $1, $2
; MIPS32-NEXT:    sllv $3, $5, $7
; MIPS32-NEXT:    andi $1, $7, 32
; MIPS32-NEXT:    movn $2, $3, $1
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    movn $3, $zero, $1
;
; MIPS32R2-LABEL: shl_i64:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    sllv $1, $4, $7
; MIPS32R2-NEXT:    not $2, $7
; MIPS32R2-NEXT:    srl $3, $5, 1
; MIPS32R2-NEXT:    srlv $2, $3, $2
; MIPS32R2-NEXT:    or $2, $1, $2
; MIPS32R2-NEXT:    sllv $3, $5, $7
; MIPS32R2-NEXT:    andi $1, $7, 32
; MIPS32R2-NEXT:    movn $2, $3, $1
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    movn $3, $zero, $1
;
; MIPS32R6-LABEL: shl_i64:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    sllv $1, $4, $7
; MIPS32R6-NEXT:    not $2, $7
; MIPS32R6-NEXT:    srl $3, $5, 1
; MIPS32R6-NEXT:    srlv $2, $3, $2
; MIPS32R6-NEXT:    or $1, $1, $2
; MIPS32R6-NEXT:    andi $3, $7, 32
; MIPS32R6-NEXT:    seleqz $1, $1, $3
; MIPS32R6-NEXT:    sllv $4, $5, $7
; MIPS32R6-NEXT:    selnez $2, $4, $3
; MIPS32R6-NEXT:    or $2, $2, $1
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    seleqz $3, $4, $3
;
; MIPS3-LABEL: shl_i64:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    dsllv $2, $4, $5
;
; MIPS4-LABEL: shl_i64:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    dsllv $2, $4, $5
;
; MIPS64-LABEL: shl_i64:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    dsllv $2, $4, $5
;
; MIPS64R2-LABEL: shl_i64:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    dsllv $2, $4, $5
;
; MIPS64R6-LABEL: shl_i64:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    dsllv $2, $4, $5
;
; MMR3-LABEL: shl_i64:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    sllv $3, $4, $7
; MMR3-NEXT:    not16 $2, $7
; MMR3-NEXT:    srl16 $4, $5, 1
; MMR3-NEXT:    srlv $2, $4, $2
; MMR3-NEXT:    or16 $2, $3
; MMR3-NEXT:    sllv $3, $5, $7
; MMR3-NEXT:    andi16 $4, $7, 32
; MMR3-NEXT:    movn $2, $3, $4
; MMR3-NEXT:    li16 $5, 0
; MMR3-NEXT:    jr $ra
; MMR3-NEXT:    movn $3, $5, $4
;
; MMR6-LABEL: shl_i64:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    sllv $1, $4, $7
; MMR6-NEXT:    not16 $2, $7
; MMR6-NEXT:    srl16 $3, $5, 1
; MMR6-NEXT:    srlv $2, $3, $2
; MMR6-NEXT:    or $1, $1, $2
; MMR6-NEXT:    andi16 $3, $7, 32
; MMR6-NEXT:    seleqz $1, $1, $3
; MMR6-NEXT:    sllv $4, $5, $7
; MMR6-NEXT:    selnez $2, $4, $3
; MMR6-NEXT:    or $2, $2, $1
; MMR6-NEXT:    seleqz $3, $4, $3
; MMR6-NEXT:    jrc $ra
entry:

  %r = shl i64 %a, %b
  ret i64 %r
}

define signext i128 @shl_i128(i128 signext %a, i128 signext %b) {
; MIPS2-LABEL: shl_i128:
; MIPS2:       # %bb.0: # %entry
; MIPS2-NEXT:    addiu $sp, $sp, -8
; MIPS2-NEXT:    .cfi_def_cfa_offset 8
; MIPS2-NEXT:    sw $17, 4($sp) # 4-byte Folded Spill
; MIPS2-NEXT:    sw $16, 0($sp) # 4-byte Folded Spill
; MIPS2-NEXT:    .cfi_offset 17, -4
; MIPS2-NEXT:    .cfi_offset 16, -8
; MIPS2-NEXT:    lw $8, 36($sp)
; MIPS2-NEXT:    addiu $1, $zero, 64
; MIPS2-NEXT:    subu $10, $1, $8
; MIPS2-NEXT:    srlv $3, $6, $10
; MIPS2-NEXT:    andi $13, $10, 32
; MIPS2-NEXT:    addiu $2, $zero, 0
; MIPS2-NEXT:    bnez $13, $BB5_2
; MIPS2-NEXT:    addiu $25, $zero, 0
; MIPS2-NEXT:  # %bb.1: # %entry
; MIPS2-NEXT:    move $25, $3
; MIPS2-NEXT:  $BB5_2: # %entry
; MIPS2-NEXT:    not $9, $8
; MIPS2-NEXT:    sllv $11, $5, $8
; MIPS2-NEXT:    andi $12, $8, 32
; MIPS2-NEXT:    bnez $12, $BB5_4
; MIPS2-NEXT:    move $16, $11
; MIPS2-NEXT:  # %bb.3: # %entry
; MIPS2-NEXT:    sllv $1, $4, $8
; MIPS2-NEXT:    srl $14, $5, 1
; MIPS2-NEXT:    srlv $14, $14, $9
; MIPS2-NEXT:    or $16, $1, $14
; MIPS2-NEXT:  $BB5_4: # %entry
; MIPS2-NEXT:    addiu $24, $8, -64
; MIPS2-NEXT:    srl $17, $7, 1
; MIPS2-NEXT:    sllv $14, $7, $24
; MIPS2-NEXT:    andi $15, $24, 32
; MIPS2-NEXT:    bnez $15, $BB5_6
; MIPS2-NEXT:    move $gp, $14
; MIPS2-NEXT:  # %bb.5: # %entry
; MIPS2-NEXT:    sllv $1, $6, $24
; MIPS2-NEXT:    not $24, $24
; MIPS2-NEXT:    srlv $24, $17, $24
; MIPS2-NEXT:    or $gp, $1, $24
; MIPS2-NEXT:  $BB5_6: # %entry
; MIPS2-NEXT:    sltiu $24, $8, 64
; MIPS2-NEXT:    beqz $24, $BB5_8
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  # %bb.7:
; MIPS2-NEXT:    or $gp, $16, $25
; MIPS2-NEXT:  $BB5_8: # %entry
; MIPS2-NEXT:    sllv $25, $7, $8
; MIPS2-NEXT:    bnez $12, $BB5_10
; MIPS2-NEXT:    move $16, $25
; MIPS2-NEXT:  # %bb.9: # %entry
; MIPS2-NEXT:    sllv $1, $6, $8
; MIPS2-NEXT:    srlv $9, $17, $9
; MIPS2-NEXT:    or $16, $1, $9
; MIPS2-NEXT:  $BB5_10: # %entry
; MIPS2-NEXT:    bnez $12, $BB5_12
; MIPS2-NEXT:    addiu $9, $zero, 0
; MIPS2-NEXT:  # %bb.11: # %entry
; MIPS2-NEXT:    move $9, $25
; MIPS2-NEXT:  $BB5_12: # %entry
; MIPS2-NEXT:    addiu $1, $zero, 63
; MIPS2-NEXT:    sltiu $25, $8, 1
; MIPS2-NEXT:    beqz $25, $BB5_22
; MIPS2-NEXT:    sltu $17, $1, $8
; MIPS2-NEXT:  # %bb.13: # %entry
; MIPS2-NEXT:    beqz $17, $BB5_23
; MIPS2-NEXT:    addiu $8, $zero, 0
; MIPS2-NEXT:  $BB5_14: # %entry
; MIPS2-NEXT:    beqz $17, $BB5_24
; MIPS2-NEXT:    addiu $9, $zero, 0
; MIPS2-NEXT:  $BB5_15: # %entry
; MIPS2-NEXT:    beqz $13, $BB5_25
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  $BB5_16: # %entry
; MIPS2-NEXT:    beqz $12, $BB5_26
; MIPS2-NEXT:    addiu $6, $zero, 0
; MIPS2-NEXT:  $BB5_17: # %entry
; MIPS2-NEXT:    beqz $15, $BB5_27
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  $BB5_18: # %entry
; MIPS2-NEXT:    bnez $24, $BB5_28
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  $BB5_19: # %entry
; MIPS2-NEXT:    bnez $25, $BB5_21
; MIPS2-NEXT:    nop
; MIPS2-NEXT:  $BB5_20: # %entry
; MIPS2-NEXT:    move $5, $2
; MIPS2-NEXT:  $BB5_21: # %entry
; MIPS2-NEXT:    move $2, $4
; MIPS2-NEXT:    move $3, $5
; MIPS2-NEXT:    move $4, $9
; MIPS2-NEXT:    move $5, $8
; MIPS2-NEXT:    lw $16, 0($sp) # 4-byte Folded Reload
; MIPS2-NEXT:    lw $17, 4($sp) # 4-byte Folded Reload
; MIPS2-NEXT:    jr $ra
; MIPS2-NEXT:    addiu $sp, $sp, 8
; MIPS2-NEXT:  $BB5_22: # %entry
; MIPS2-NEXT:    move $4, $gp
; MIPS2-NEXT:    bnez $17, $BB5_14
; MIPS2-NEXT:    addiu $8, $zero, 0
; MIPS2-NEXT:  $BB5_23: # %entry
; MIPS2-NEXT:    move $8, $9
; MIPS2-NEXT:    bnez $17, $BB5_15
; MIPS2-NEXT:    addiu $9, $zero, 0
; MIPS2-NEXT:  $BB5_24: # %entry
; MIPS2-NEXT:    bnez $13, $BB5_16
; MIPS2-NEXT:    move $9, $16
; MIPS2-NEXT:  $BB5_25: # %entry
; MIPS2-NEXT:    not $1, $10
; MIPS2-NEXT:    sll $3, $6, 1
; MIPS2-NEXT:    srlv $6, $7, $10
; MIPS2-NEXT:    sllv $1, $3, $1
; MIPS2-NEXT:    or $3, $1, $6
; MIPS2-NEXT:    bnez $12, $BB5_17
; MIPS2-NEXT:    addiu $6, $zero, 0
; MIPS2-NEXT:  $BB5_26: # %entry
; MIPS2-NEXT:    bnez $15, $BB5_18
; MIPS2-NEXT:    move $6, $11
; MIPS2-NEXT:  $BB5_27: # %entry
; MIPS2-NEXT:    beqz $24, $BB5_19
; MIPS2-NEXT:    move $2, $14
; MIPS2-NEXT:  $BB5_28:
; MIPS2-NEXT:    bnez $25, $BB5_21
; MIPS2-NEXT:    or $2, $6, $3
; MIPS2-NEXT:  # %bb.29:
; MIPS2-NEXT:    b $BB5_20
; MIPS2-NEXT:    nop
;
; MIPS32-LABEL: shl_i128:
; MIPS32:       # %bb.0: # %entry
; MIPS32-NEXT:    lw $8, 28($sp)
; MIPS32-NEXT:    addiu $1, $zero, 64
; MIPS32-NEXT:    subu $1, $1, $8
; MIPS32-NEXT:    srlv $9, $6, $1
; MIPS32-NEXT:    andi $10, $1, 32
; MIPS32-NEXT:    move $2, $9
; MIPS32-NEXT:    movn $2, $zero, $10
; MIPS32-NEXT:    sllv $3, $4, $8
; MIPS32-NEXT:    not $11, $8
; MIPS32-NEXT:    srl $12, $5, 1
; MIPS32-NEXT:    srlv $12, $12, $11
; MIPS32-NEXT:    or $3, $3, $12
; MIPS32-NEXT:    sllv $12, $5, $8
; MIPS32-NEXT:    andi $13, $8, 32
; MIPS32-NEXT:    movn $3, $12, $13
; MIPS32-NEXT:    addiu $14, $8, -64
; MIPS32-NEXT:    or $15, $3, $2
; MIPS32-NEXT:    sllv $2, $6, $14
; MIPS32-NEXT:    srl $24, $7, 1
; MIPS32-NEXT:    not $3, $14
; MIPS32-NEXT:    srlv $3, $24, $3
; MIPS32-NEXT:    or $2, $2, $3
; MIPS32-NEXT:    sllv $3, $7, $14
; MIPS32-NEXT:    andi $14, $14, 32
; MIPS32-NEXT:    movn $2, $3, $14
; MIPS32-NEXT:    sltiu $25, $8, 64
; MIPS32-NEXT:    movn $2, $15, $25
; MIPS32-NEXT:    srlv $15, $7, $1
; MIPS32-NEXT:    not $1, $1
; MIPS32-NEXT:    sll $gp, $6, 1
; MIPS32-NEXT:    sllv $1, $gp, $1
; MIPS32-NEXT:    or $15, $1, $15
; MIPS32-NEXT:    sllv $1, $6, $8
; MIPS32-NEXT:    srlv $6, $24, $11
; MIPS32-NEXT:    or $1, $1, $6
; MIPS32-NEXT:    sllv $6, $7, $8
; MIPS32-NEXT:    movn $1, $6, $13
; MIPS32-NEXT:    movz $2, $4, $8
; MIPS32-NEXT:    movz $1, $zero, $25
; MIPS32-NEXT:    movn $15, $9, $10
; MIPS32-NEXT:    movn $12, $zero, $13
; MIPS32-NEXT:    or $4, $12, $15
; MIPS32-NEXT:    movn $3, $zero, $14
; MIPS32-NEXT:    movn $3, $4, $25
; MIPS32-NEXT:    movz $3, $5, $8
; MIPS32-NEXT:    movn $6, $zero, $13
; MIPS32-NEXT:    movz $6, $zero, $25
; MIPS32-NEXT:    move $4, $1
; MIPS32-NEXT:    jr $ra
; MIPS32-NEXT:    move $5, $6
;
; MIPS32R2-LABEL: shl_i128:
; MIPS32R2:       # %bb.0: # %entry
; MIPS32R2-NEXT:    lw $8, 28($sp)
; MIPS32R2-NEXT:    addiu $1, $zero, 64
; MIPS32R2-NEXT:    subu $1, $1, $8
; MIPS32R2-NEXT:    srlv $9, $6, $1
; MIPS32R2-NEXT:    andi $10, $1, 32
; MIPS32R2-NEXT:    move $2, $9
; MIPS32R2-NEXT:    movn $2, $zero, $10
; MIPS32R2-NEXT:    sllv $3, $4, $8
; MIPS32R2-NEXT:    not $11, $8
; MIPS32R2-NEXT:    srl $12, $5, 1
; MIPS32R2-NEXT:    srlv $12, $12, $11
; MIPS32R2-NEXT:    or $3, $3, $12
; MIPS32R2-NEXT:    sllv $12, $5, $8
; MIPS32R2-NEXT:    andi $13, $8, 32
; MIPS32R2-NEXT:    movn $3, $12, $13
; MIPS32R2-NEXT:    addiu $14, $8, -64
; MIPS32R2-NEXT:    or $15, $3, $2
; MIPS32R2-NEXT:    sllv $2, $6, $14
; MIPS32R2-NEXT:    srl $24, $7, 1
; MIPS32R2-NEXT:    not $3, $14
; MIPS32R2-NEXT:    srlv $3, $24, $3
; MIPS32R2-NEXT:    or $2, $2, $3
; MIPS32R2-NEXT:    sllv $3, $7, $14
; MIPS32R2-NEXT:    andi $14, $14, 32
; MIPS32R2-NEXT:    movn $2, $3, $14
; MIPS32R2-NEXT:    sltiu $25, $8, 64
; MIPS32R2-NEXT:    movn $2, $15, $25
; MIPS32R2-NEXT:    srlv $15, $7, $1
; MIPS32R2-NEXT:    not $1, $1
; MIPS32R2-NEXT:    sll $gp, $6, 1
; MIPS32R2-NEXT:    sllv $1, $gp, $1
; MIPS32R2-NEXT:    or $15, $1, $15
; MIPS32R2-NEXT:    sllv $1, $6, $8
; MIPS32R2-NEXT:    srlv $6, $24, $11
; MIPS32R2-NEXT:    or $1, $1, $6
; MIPS32R2-NEXT:    sllv $6, $7, $8
; MIPS32R2-NEXT:    movn $1, $6, $13
; MIPS32R2-NEXT:    movz $2, $4, $8
; MIPS32R2-NEXT:    movz $1, $zero, $25
; MIPS32R2-NEXT:    movn $15, $9, $10
; MIPS32R2-NEXT:    movn $12, $zero, $13
; MIPS32R2-NEXT:    or $4, $12, $15
; MIPS32R2-NEXT:    movn $3, $zero, $14
; MIPS32R2-NEXT:    movn $3, $4, $25
; MIPS32R2-NEXT:    movz $3, $5, $8
; MIPS32R2-NEXT:    movn $6, $zero, $13
; MIPS32R2-NEXT:    movz $6, $zero, $25
; MIPS32R2-NEXT:    move $4, $1
; MIPS32R2-NEXT:    jr $ra
; MIPS32R2-NEXT:    move $5, $6
;
; MIPS32R6-LABEL: shl_i128:
; MIPS32R6:       # %bb.0: # %entry
; MIPS32R6-NEXT:    lw $3, 28($sp)
; MIPS32R6-NEXT:    sllv $1, $4, $3
; MIPS32R6-NEXT:    not $2, $3
; MIPS32R6-NEXT:    srl $8, $5, 1
; MIPS32R6-NEXT:    srlv $8, $8, $2
; MIPS32R6-NEXT:    or $1, $1, $8
; MIPS32R6-NEXT:    sllv $8, $5, $3
; MIPS32R6-NEXT:    andi $9, $3, 32
; MIPS32R6-NEXT:    seleqz $1, $1, $9
; MIPS32R6-NEXT:    selnez $10, $8, $9
; MIPS32R6-NEXT:    addiu $11, $zero, 64
; MIPS32R6-NEXT:    subu $11, $11, $3
; MIPS32R6-NEXT:    srlv $12, $6, $11
; MIPS32R6-NEXT:    andi $13, $11, 32
; MIPS32R6-NEXT:    seleqz $14, $12, $13
; MIPS32R6-NEXT:    or $1, $10, $1
; MIPS32R6-NEXT:    selnez $10, $12, $13
; MIPS32R6-NEXT:    srlv $12, $7, $11
; MIPS32R6-NEXT:    not $11, $11
; MIPS32R6-NEXT:    sll $15, $6, 1
; MIPS32R6-NEXT:    sllv $11, $15, $11
; MIPS32R6-NEXT:    or $11, $11, $12
; MIPS32R6-NEXT:    seleqz $11, $11, $13
; MIPS32R6-NEXT:    addiu $12, $3, -64
; MIPS32R6-NEXT:    or $10, $10, $11
; MIPS32R6-NEXT:    or $1, $1, $14
; MIPS32R6-NEXT:    sllv $11, $6, $12
; MIPS32R6-NEXT:    srl $13, $7, 1
; MIPS32R6-NEXT:    not $14, $12
; MIPS32R6-NEXT:    srlv $14, $13, $14
; MIPS32R6-NEXT:    or $11, $11, $14
; MIPS32R6-NEXT:    andi $14, $12, 32
; MIPS32R6-NEXT:    seleqz $11, $11, $14
; MIPS32R6-NEXT:    sllv $12, $7, $12
; MIPS32R6-NEXT:    selnez $15, $12, $14
; MIPS32R6-NEXT:    sltiu $24, $3, 64
; MIPS32R6-NEXT:    selnez $1, $1, $24
; MIPS32R6-NEXT:    or $11, $15, $11
; MIPS32R6-NEXT:    sllv $6, $6, $3
; MIPS32R6-NEXT:    srlv $2, $13, $2
; MIPS32R6-NEXT:    seleqz $8, $8, $9
; MIPS32R6-NEXT:    or $8, $8, $10
; MIPS32R6-NEXT:    or $6, $6, $2
; MIPS32R6-NEXT:    seleqz $2, $11, $24
; MIPS32R6-NEXT:    seleqz $10, $zero, $24
; MIPS32R6-NEXT:    sllv $7, $7, $3
; MIPS32R6-NEXT:    seleqz $11, $7, $9
; MIPS32R6-NEXT:    selnez $11, $11, $24
; MIPS32R6-NEXT:    seleqz $4, $4, $3
; MIPS32R6-NEXT:    or $1, $1, $2
; MIPS32R6-NEXT:    selnez $1, $1, $3
; MIPS32R6-NEXT:    or $2, $4, $1
; MIPS32R6-NEXT:    or $1, $10, $11
; MIPS32R6-NEXT:    seleqz $4, $6, $9
; MIPS32R6-NEXT:    selnez $6, $7, $9
; MIPS32R6-NEXT:    seleqz $5, $5, $3
; MIPS32R6-NEXT:    selnez $7, $8, $24
; MIPS32R6-NEXT:    seleqz $8, $12, $14
; MIPS32R6-NEXT:    seleqz $8, $8, $24
; MIPS32R6-NEXT:    or $7, $7, $8
; MIPS32R6-NEXT:    selnez $3, $7, $3
; MIPS32R6-NEXT:    or $3, $5, $3
; MIPS32R6-NEXT:    or $4, $6, $4
; MIPS32R6-NEXT:    selnez $4, $4, $24
; MIPS32R6-NEXT:    or $4, $10, $4
; MIPS32R6-NEXT:    jr $ra
; MIPS32R6-NEXT:    move $5, $1
;
; MIPS3-LABEL: shl_i128:
; MIPS3:       # %bb.0: # %entry
; MIPS3-NEXT:    sll $3, $7, 0
; MIPS3-NEXT:    dsllv $6, $5, $7
; MIPS3-NEXT:    andi $8, $3, 64
; MIPS3-NEXT:    beqz $8, .LBB5_3
; MIPS3-NEXT:    move $2, $6
; MIPS3-NEXT:  # %bb.1: # %entry
; MIPS3-NEXT:    beqz $8, .LBB5_4
; MIPS3-NEXT:    daddiu $3, $zero, 0
; MIPS3-NEXT:  .LBB5_2: # %entry
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    nop
; MIPS3-NEXT:  .LBB5_3: # %entry
; MIPS3-NEXT:    dsllv $1, $4, $7
; MIPS3-NEXT:    dsrl $2, $5, 1
; MIPS3-NEXT:    not $3, $3
; MIPS3-NEXT:    dsrlv $2, $2, $3
; MIPS3-NEXT:    or $2, $1, $2
; MIPS3-NEXT:    bnez $8, .LBB5_2
; MIPS3-NEXT:    daddiu $3, $zero, 0
; MIPS3-NEXT:  .LBB5_4: # %entry
; MIPS3-NEXT:    jr $ra
; MIPS3-NEXT:    move $3, $6
;
; MIPS4-LABEL: shl_i128:
; MIPS4:       # %bb.0: # %entry
; MIPS4-NEXT:    dsllv $1, $4, $7
; MIPS4-NEXT:    dsrl $2, $5, 1
; MIPS4-NEXT:    sll $4, $7, 0
; MIPS4-NEXT:    not $3, $4
; MIPS4-NEXT:    dsrlv $2, $2, $3
; MIPS4-NEXT:    or $2, $1, $2
; MIPS4-NEXT:    dsllv $3, $5, $7
; MIPS4-NEXT:    andi $1, $4, 64
; MIPS4-NEXT:    movn $2, $3, $1
; MIPS4-NEXT:    jr $ra
; MIPS4-NEXT:    movn $3, $zero, $1
;
; MIPS64-LABEL: shl_i128:
; MIPS64:       # %bb.0: # %entry
; MIPS64-NEXT:    dsllv $1, $4, $7
; MIPS64-NEXT:    dsrl $2, $5, 1
; MIPS64-NEXT:    sll $4, $7, 0
; MIPS64-NEXT:    not $3, $4
; MIPS64-NEXT:    dsrlv $2, $2, $3
; MIPS64-NEXT:    or $2, $1, $2
; MIPS64-NEXT:    dsllv $3, $5, $7
; MIPS64-NEXT:    andi $1, $4, 64
; MIPS64-NEXT:    movn $2, $3, $1
; MIPS64-NEXT:    jr $ra
; MIPS64-NEXT:    movn $3, $zero, $1
;
; MIPS64R2-LABEL: shl_i128:
; MIPS64R2:       # %bb.0: # %entry
; MIPS64R2-NEXT:    dsllv $1, $4, $7
; MIPS64R2-NEXT:    dsrl $2, $5, 1
; MIPS64R2-NEXT:    sll $4, $7, 0
; MIPS64R2-NEXT:    not $3, $4
; MIPS64R2-NEXT:    dsrlv $2, $2, $3
; MIPS64R2-NEXT:    or $2, $1, $2
; MIPS64R2-NEXT:    dsllv $3, $5, $7
; MIPS64R2-NEXT:    andi $1, $4, 64
; MIPS64R2-NEXT:    movn $2, $3, $1
; MIPS64R2-NEXT:    jr $ra
; MIPS64R2-NEXT:    movn $3, $zero, $1
;
; MIPS64R6-LABEL: shl_i128:
; MIPS64R6:       # %bb.0: # %entry
; MIPS64R6-NEXT:    dsllv $1, $4, $7
; MIPS64R6-NEXT:    dsrl $2, $5, 1
; MIPS64R6-NEXT:    sll $3, $7, 0
; MIPS64R6-NEXT:    not $4, $3
; MIPS64R6-NEXT:    dsrlv $2, $2, $4
; MIPS64R6-NEXT:    or $1, $1, $2
; MIPS64R6-NEXT:    andi $2, $3, 64
; MIPS64R6-NEXT:    sll $3, $2, 0
; MIPS64R6-NEXT:    seleqz $1, $1, $3
; MIPS64R6-NEXT:    dsllv $4, $5, $7
; MIPS64R6-NEXT:    selnez $2, $4, $3
; MIPS64R6-NEXT:    or $2, $2, $1
; MIPS64R6-NEXT:    jr $ra
; MIPS64R6-NEXT:    seleqz $3, $4, $3
;
; MMR3-LABEL: shl_i128:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    addiusp -40
; MMR3-NEXT:    .cfi_def_cfa_offset 40
; MMR3-NEXT:    swp $16, 32($sp)
; MMR3-NEXT:    .cfi_offset 17, -4
; MMR3-NEXT:    .cfi_offset 16, -8
; MMR3-NEXT:    move $17, $7
; MMR3-NEXT:    sw $7, 4($sp) # 4-byte Folded Spill
; MMR3-NEXT:    move $7, $6
; MMR3-NEXT:    move $1, $4
; MMR3-NEXT:    lw $16, 68($sp)
; MMR3-NEXT:    li16 $2, 64
; MMR3-NEXT:    subu16 $6, $2, $16
; MMR3-NEXT:    srlv $9, $7, $6
; MMR3-NEXT:    andi16 $4, $6, 32
; MMR3-NEXT:    sw $4, 24($sp) # 4-byte Folded Spill
; MMR3-NEXT:    li16 $3, 0
; MMR3-NEXT:    move $2, $9
; MMR3-NEXT:    movn $2, $3, $4
; MMR3-NEXT:    sllv $3, $1, $16
; MMR3-NEXT:    sw $3, 16($sp) # 4-byte Folded Spill
; MMR3-NEXT:    not16 $4, $16
; MMR3-NEXT:    sw $4, 20($sp) # 4-byte Folded Spill
; MMR3-NEXT:    sw $5, 28($sp) # 4-byte Folded Spill
; MMR3-NEXT:    srl16 $3, $5, 1
; MMR3-NEXT:    srlv $3, $3, $4
; MMR3-NEXT:    lw $4, 16($sp) # 4-byte Folded Reload
; MMR3-NEXT:    or16 $3, $4
; MMR3-NEXT:    sllv $5, $5, $16
; MMR3-NEXT:    sw $5, 8($sp) # 4-byte Folded Spill
; MMR3-NEXT:    andi16 $4, $16, 32
; MMR3-NEXT:    sw $4, 16($sp) # 4-byte Folded Spill
; MMR3-NEXT:    movn $3, $5, $4
; MMR3-NEXT:    addiu $4, $16, -64
; MMR3-NEXT:    or16 $3, $2
; MMR3-NEXT:    sllv $2, $7, $4
; MMR3-NEXT:    sw $2, 12($sp) # 4-byte Folded Spill
; MMR3-NEXT:    srl16 $5, $17, 1
; MMR3-NEXT:    not16 $2, $4
; MMR3-NEXT:    srlv $2, $5, $2
; MMR3-NEXT:    lw $17, 12($sp) # 4-byte Folded Reload
; MMR3-NEXT:    or16 $2, $17
; MMR3-NEXT:    lw $17, 4($sp) # 4-byte Folded Reload
; MMR3-NEXT:    sllv $8, $17, $4
; MMR3-NEXT:    andi16 $4, $4, 32
; MMR3-NEXT:    sw $4, 12($sp) # 4-byte Folded Spill
; MMR3-NEXT:    movn $2, $8, $4
; MMR3-NEXT:    sltiu $10, $16, 64
; MMR3-NEXT:    movn $2, $3, $10
; MMR3-NEXT:    srlv $4, $17, $6
; MMR3-NEXT:    not16 $3, $6
; MMR3-NEXT:    sll16 $6, $7, 1
; MMR3-NEXT:    sllv $3, $6, $3
; MMR3-NEXT:    or16 $3, $4
; MMR3-NEXT:    sllv $6, $7, $16
; MMR3-NEXT:    lw $4, 20($sp) # 4-byte Folded Reload
; MMR3-NEXT:    srlv $4, $5, $4
; MMR3-NEXT:    or16 $4, $6
; MMR3-NEXT:    sllv $6, $17, $16
; MMR3-NEXT:    lw $17, 16($sp) # 4-byte Folded Reload
; MMR3-NEXT:    movn $4, $6, $17
; MMR3-NEXT:    movz $2, $1, $16
; MMR3-NEXT:    li16 $5, 0
; MMR3-NEXT:    movz $4, $5, $10
; MMR3-NEXT:    lw $7, 24($sp) # 4-byte Folded Reload
; MMR3-NEXT:    movn $3, $9, $7
; MMR3-NEXT:    lw $5, 8($sp) # 4-byte Folded Reload
; MMR3-NEXT:    li16 $7, 0
; MMR3-NEXT:    movn $5, $7, $17
; MMR3-NEXT:    or16 $5, $3
; MMR3-NEXT:    lw $3, 12($sp) # 4-byte Folded Reload
; MMR3-NEXT:    movn $8, $7, $3
; MMR3-NEXT:    li16 $7, 0
; MMR3-NEXT:    movn $8, $5, $10
; MMR3-NEXT:    lw $3, 28($sp) # 4-byte Folded Reload
; MMR3-NEXT:    movz $8, $3, $16
; MMR3-NEXT:    movn $6, $7, $17
; MMR3-NEXT:    li16 $3, 0
; MMR3-NEXT:    movz $6, $3, $10
; MMR3-NEXT:    move $3, $8
; MMR3-NEXT:    move $5, $6
; MMR3-NEXT:    lwp $16, 32($sp)
; MMR3-NEXT:    addiusp 40
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: shl_i128:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    addiu $sp, $sp, -16
; MMR6-NEXT:    .cfi_def_cfa_offset 16
; MMR6-NEXT:    sw $17, 12($sp) # 4-byte Folded Spill
; MMR6-NEXT:    sw $16, 8($sp) # 4-byte Folded Spill
; MMR6-NEXT:    .cfi_offset 17, -4
; MMR6-NEXT:    .cfi_offset 16, -8
; MMR6-NEXT:    move $11, $4
; MMR6-NEXT:    lw $3, 44($sp)
; MMR6-NEXT:    sllv $1, $4, $3
; MMR6-NEXT:    not16 $2, $3
; MMR6-NEXT:    sw $2, 4($sp) # 4-byte Folded Spill
; MMR6-NEXT:    srl16 $16, $5, 1
; MMR6-NEXT:    srlv $8, $16, $2
; MMR6-NEXT:    or $1, $1, $8
; MMR6-NEXT:    sllv $8, $5, $3
; MMR6-NEXT:    andi16 $16, $3, 32
; MMR6-NEXT:    seleqz $1, $1, $16
; MMR6-NEXT:    selnez $9, $8, $16
; MMR6-NEXT:    li16 $17, 64
; MMR6-NEXT:    subu16 $17, $17, $3
; MMR6-NEXT:    srlv $10, $6, $17
; MMR6-NEXT:    andi16 $2, $17, 32
; MMR6-NEXT:    seleqz $12, $10, $2
; MMR6-NEXT:    or $1, $9, $1
; MMR6-NEXT:    selnez $9, $10, $2
; MMR6-NEXT:    srlv $10, $7, $17
; MMR6-NEXT:    not16 $17, $17
; MMR6-NEXT:    sll16 $4, $6, 1
; MMR6-NEXT:    sllv $4, $4, $17
; MMR6-NEXT:    or $4, $4, $10
; MMR6-NEXT:    seleqz $2, $4, $2
; MMR6-NEXT:    addiu $4, $3, -64
; MMR6-NEXT:    or $10, $9, $2
; MMR6-NEXT:    or $1, $1, $12
; MMR6-NEXT:    sllv $9, $6, $4
; MMR6-NEXT:    srl16 $2, $7, 1
; MMR6-NEXT:    not16 $17, $4
; MMR6-NEXT:    srlv $12, $2, $17
; MMR6-NEXT:    or $9, $9, $12
; MMR6-NEXT:    andi16 $17, $4, 32
; MMR6-NEXT:    seleqz $9, $9, $17
; MMR6-NEXT:    sllv $14, $7, $4
; MMR6-NEXT:    selnez $12, $14, $17
; MMR6-NEXT:    sltiu $13, $3, 64
; MMR6-NEXT:    selnez $1, $1, $13
; MMR6-NEXT:    or $9, $12, $9
; MMR6-NEXT:    sllv $6, $6, $3
; MMR6-NEXT:    lw $4, 4($sp) # 4-byte Folded Reload
; MMR6-NEXT:    srlv $2, $2, $4
; MMR6-NEXT:    seleqz $8, $8, $16
; MMR6-NEXT:    li16 $4, 0
; MMR6-NEXT:    or $8, $8, $10
; MMR6-NEXT:    or $6, $6, $2
; MMR6-NEXT:    seleqz $2, $9, $13
; MMR6-NEXT:    seleqz $9, $4, $13
; MMR6-NEXT:    sllv $7, $7, $3
; MMR6-NEXT:    seleqz $10, $7, $16
; MMR6-NEXT:    selnez $10, $10, $13
; MMR6-NEXT:    seleqz $11, $11, $3
; MMR6-NEXT:    or $1, $1, $2
; MMR6-NEXT:    selnez $1, $1, $3
; MMR6-NEXT:    or $2, $11, $1
; MMR6-NEXT:    or $1, $9, $10
; MMR6-NEXT:    seleqz $6, $6, $16
; MMR6-NEXT:    selnez $7, $7, $16
; MMR6-NEXT:    seleqz $5, $5, $3
; MMR6-NEXT:    selnez $8, $8, $13
; MMR6-NEXT:    seleqz $4, $14, $17
; MMR6-NEXT:    seleqz $4, $4, $13
; MMR6-NEXT:    or $4, $8, $4
; MMR6-NEXT:    selnez $3, $4, $3
; MMR6-NEXT:    or $3, $5, $3
; MMR6-NEXT:    or $4, $7, $6
; MMR6-NEXT:    selnez $4, $4, $13
; MMR6-NEXT:    or $4, $9, $4
; MMR6-NEXT:    move $5, $1
; MMR6-NEXT:    lw $16, 8($sp) # 4-byte Folded Reload
; MMR6-NEXT:    lw $17, 12($sp) # 4-byte Folded Reload
; MMR6-NEXT:    addiu $sp, $sp, 16
; MMR6-NEXT:    jrc $ra
entry:

; o32 shouldn't use TImode helpers.
; GP32-NOT:       lw        $25, %call16(__ashlti3)($gp)
; MM-NOT:         lw        $25, %call16(__ashlti3)($2)

  %r = shl i128 %a, %b
  ret i128 %r
}
