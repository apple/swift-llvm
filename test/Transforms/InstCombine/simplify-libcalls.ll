; RUN: opt -S < %s -instcombine | FileCheck %s
target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f80:128:128-v64:64:64-v128:128:128-a0:0:64-f80:32:32-n8:16:32-S32"

@G = constant [3 x i8] c"%s\00"		; <[3 x i8]*> [#uses=1]

declare i32 @sprintf(i8*, i8*, ...)

define void @foo(i8* %P, i32* %X) {
	call i32 (i8*, i8*, ...) @sprintf( i8* %P, i8* getelementptr ([3 x i8], [3 x i8]* @G, i32 0, i32 0), i32* %X )		; <i32>:1 [#uses=0]
	ret void
}

; PR1307
@str = internal constant [5 x i8] c"foog\00"
@str1 = internal constant [8 x i8] c"blahhh!\00"
@str2 = internal constant [5 x i8] c"Ponk\00"

define i8* @test1() {
        %tmp3 = tail call i8* @strchr( i8* getelementptr ([5 x i8], [5 x i8]* @str, i32 0, i32 2), i32 103 )              ; <i8*> [#uses=1]
        ret i8* %tmp3

; CHECK-LABEL: @test1(
; CHECK: ret i8* getelementptr inbounds ([5 x i8], [5 x i8]* @str, i32 0, i32 3)
}

declare i8* @strchr(i8*, i32)

define i8* @test2() {
        %tmp3 = tail call i8* @strchr( i8* getelementptr ([8 x i8], [8 x i8]* @str1, i32 0, i32 2), i32 0 )               ; <i8*> [#uses=1]
        ret i8* %tmp3

; CHECK-LABEL: @test2(
; CHECK: ret i8* getelementptr inbounds ([8 x i8], [8 x i8]* @str1, i32 0, i32 7)
}

define i8* @test3() {
entry:
        %tmp3 = tail call i8* @strchr( i8* getelementptr ([5 x i8], [5 x i8]* @str2, i32 0, i32 1), i32 80 )              ; <i8*> [#uses=1]
        ret i8* %tmp3

; CHECK-LABEL: @test3(
; CHECK: ret i8* null
}

@_2E_str = external constant [5 x i8]		; <[5 x i8]*> [#uses=1]

declare i32 @memcmp(i8*, i8*, i32) nounwind readonly

define i1 @PR2341(i8** %start_addr) {
entry:
	%tmp4 = load i8*, i8** %start_addr, align 4		; <i8*> [#uses=1]
	%tmp5 = call i32 @memcmp( i8* %tmp4, i8* getelementptr ([5 x i8], [5 x i8]* @_2E_str, i32 0, i32 0), i32 4 ) nounwind readonly 		; <i32> [#uses=1]
	%tmp6 = icmp eq i32 %tmp5, 0		; <i1> [#uses=1]
	ret i1 %tmp6

; CHECK-LABEL: @PR2341(
; CHECK: i32
}

define i32 @PR4284() nounwind {
entry:
	%c0 = alloca i8, align 1		; <i8*> [#uses=2]
	%c2 = alloca i8, align 1		; <i8*> [#uses=2]
	store i8 64, i8* %c0
	store i8 -127, i8* %c2
	%call = call i32 @memcmp(i8* %c0, i8* %c2, i32 1)		; <i32> [#uses=1]
	ret i32 %call

; CHECK-LABEL: @PR4284(
; CHECK: ret i32 -65
}

%struct.__sFILE = type { i8*, i32, i32, i16, i16, %struct.__sbuf, i32, i8*, i32 (i8*)*, i32 (i8*, i8*, i32)*, i64 (i8*, i64, i32)*, i32 (i8*, i8*, i32)*, %struct.__sbuf, i8*, i32, [3 x i8], [1 x i8], %struct.__sbuf, i32, i64, %struct.pthread_mutex*, %struct.pthread*, i32, i32, %union.anon }
%struct.__sbuf = type { i8*, i32, [4 x i8] }
%struct.pthread = type opaque
%struct.pthread_mutex = type opaque
%union.anon = type { i64, [120 x i8] }
@.str13 = external constant [2 x i8]		; <[2 x i8]*> [#uses=1]
@.str14 = external constant [2 x i8]		; <[2 x i8]*> [#uses=1]

define i32 @PR4641(i32 %argc, i8** %argv) nounwind {
entry:
	call void @exit(i32 0) nounwind
	%cond392 = select i1 undef, i8* getelementptr ([2 x i8], [2 x i8]* @.str13, i32 0, i32 0), i8* getelementptr ([2 x i8], [2 x i8]* @.str14, i32 0, i32 0)		; <i8*> [#uses=1]
	%call393 = call %struct.__sFILE* @fopen(i8* undef, i8* %cond392) nounwind		; <%struct.__sFILE*> [#uses=0]
	unreachable
}

declare %struct.__sFILE* @fopen(i8*, i8*)

declare void @exit(i32)

define i32 @PR4645() {
entry:
	br label %if.then

lor.lhs.false:		; preds = %while.body
	br i1 undef, label %if.then, label %for.cond

if.then:		; preds = %lor.lhs.false, %while.body
	call void @exit(i32 1)
	br label %for.cond

for.cond:		; preds = %for.end, %if.then, %lor.lhs.false
	%j.0 = phi i32 [ %inc47, %for.end ], [ 0, %if.then ], [ 0, %lor.lhs.false ]		; <i32> [#uses=1]
	unreachable

for.end:		; preds = %for.cond20
	%inc47 = add i32 %j.0, 1		; <i32> [#uses=1]
	br label %for.cond
}

@h = constant [2 x i8] c"h\00"		; <[2 x i8]*> [#uses=1]
@hel = constant [4 x i8] c"hel\00"		; <[4 x i8]*> [#uses=1]
@hello_u = constant [8 x i8] c"hello_u\00"		; <[8 x i8]*> [#uses=1]

define i32 @MemCpy() {
  %h_p = getelementptr [2 x i8], [2 x i8]* @h, i32 0, i32 0
  %hel_p = getelementptr [4 x i8], [4 x i8]* @hel, i32 0, i32 0
  %hello_u_p = getelementptr [8 x i8], [8 x i8]* @hello_u, i32 0, i32 0
  %target = alloca [1024 x i8]
  %target_p = getelementptr [1024 x i8], [1024 x i8]* %target, i32 0, i32 0
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %target_p, i8* %h_p, i32 2, i32 2, i1 false)
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %target_p, i8* %hel_p, i32 4, i32 4, i1 false)
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %target_p, i8* %hello_u_p, i32 8, i32 8, i1 false)
  ret i32 0

; CHECK-LABEL: @MemCpy(
; CHECK-NOT: llvm.memcpy
; CHECK: ret i32 0
}

declare void @llvm.memcpy.p0i8.p0i8.i32(i8* nocapture, i8* nocapture, i32, i32, i1) nounwind

declare i32 @strcmp(i8*, i8*) #0

define void @test9(i8* %x) {
; CHECK-LABEL: @test9(
; CHECK-NOT: strcmp
  %y = call i32 @strcmp(i8* %x, i8* %x) #1
  ret void
}

; rdar://problem/24220238 - Crash due to unchecked result of getCalledFunction()
%class.A = type { i32 (...)** }

define double @test10(%class.A* %this) unnamed_addr #2 align 2 {
; CHECK-LABEL: @test10(
  %1 = alloca %class.A*, align 8
  %a = alloca double, align 8
  store %class.A* %this, %class.A** %1, align 8
  %2 = load %class.A*, %class.A** %1, align 8
  %3 = bitcast %class.A* %2 to double (%class.A*)***
  %4 = load double (%class.A*)**, double (%class.A*)*** %3, align 8
  %5 = getelementptr inbounds double (%class.A*)*, double (%class.A*)** %4, i64 0
  %6 = load double (%class.A*)*, double (%class.A*)** %5, align 8
  %7 = call double %6(%class.A* %2)
  store double %7, double* %a, align 8
  %8 = load double, double* %a, align 8
  %9 = call double @llvm.pow.f64(double %8, double 0.000000e+00)
  ret double %9
}

declare double @llvm.pow.f64(double, double) #3

attributes #0 = { nobuiltin }
attributes #1 = { builtin }
attributes #2 = { ssp uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #3 = { nounwind readnone }
