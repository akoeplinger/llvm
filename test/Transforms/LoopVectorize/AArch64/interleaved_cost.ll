; RUN: opt -loop-vectorize -force-vector-width=2 -debug-only=loop-vectorize -disable-output < %s 2>&1 | FileCheck %s --check-prefix=VF_2
; RUN: opt -loop-vectorize -force-vector-width=8 -debug-only=loop-vectorize -disable-output < %s 2>&1 | FileCheck %s --check-prefix=VF_8
; RUN: opt -loop-vectorize -force-vector-width=16 -debug-only=loop-vectorize -disable-output < %s 2>&1 | FileCheck %s --check-prefix=VF_16
; REQUIRES: asserts

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128"
target triple = "aarch64--linux-gnueabi"

%i8.2 = type {i8, i8}
define void @i8_factor_2(%i8.2* %data, i64 %n) {
entry:
  br label %for.body

; VF_8-LABEL:  Checking a loop in "i8_factor_2"
; VF_8:          Found an estimated cost of 2 for VF 8 For instruction: %tmp2 = load i8, i8* %tmp0, align 1
; VF_8-NEXT:     Found an estimated cost of 0 for VF 8 For instruction: %tmp3 = load i8, i8* %tmp1, align 1
; VF_8-NEXT:     Found an estimated cost of 0 for VF 8 For instruction: store i8 0, i8* %tmp0, align 1
; VF_8-NEXT:     Found an estimated cost of 2 for VF 8 For instruction: store i8 0, i8* %tmp1, align 1
; VF_16-LABEL: Checking a loop in "i8_factor_2"
; VF_16:         Found an estimated cost of 2 for VF 16 For instruction: %tmp2 = load i8, i8* %tmp0, align 1
; VF_16-NEXT:    Found an estimated cost of 0 for VF 16 For instruction: %tmp3 = load i8, i8* %tmp1, align 1
; VF_16-NEXT:    Found an estimated cost of 0 for VF 16 For instruction: store i8 0, i8* %tmp0, align 1
; VF_16-NEXT:    Found an estimated cost of 2 for VF 16 For instruction: store i8 0, i8* %tmp1, align 1
for.body:
  %i = phi i64 [ 0, %entry ], [ %i.next, %for.body ]
  %tmp0 = getelementptr inbounds %i8.2, %i8.2* %data, i64 %i, i32 0
  %tmp1 = getelementptr inbounds %i8.2, %i8.2* %data, i64 %i, i32 1
  %tmp2 = load i8, i8* %tmp0, align 1
  %tmp3 = load i8, i8* %tmp1, align 1
  store i8 0, i8* %tmp0, align 1
  store i8 0, i8* %tmp1, align 1
  %i.next = add nuw nsw i64 %i, 1
  %cond = icmp slt i64 %i.next, %n
  br i1 %cond, label %for.body, label %for.end

for.end:
  ret void
}

%i64.8 = type {i64, i64, i64, i64, i64, i64, i64, i64}
define void @i64_factor_8(%i64.8* %data, i64 %n) {
entry:
  br label %for.body

; The interleave factor in this test is 8, which is greater than the maximum
; allowed factor for AArch64 (4). Thus, we will fall back to the basic TTI
; implementation for determining the cost of the interleaved load group. The
; stores do not form a legal interleaved group because the group would contain
; gaps.
;
; VF_2-LABEL: Checking a loop in "i64_factor_8"
; VF_2:         Found an estimated cost of 6 for VF 2 For instruction: %tmp2 = load i64, i64* %tmp0, align 8
; VF_2-NEXT:    Found an estimated cost of 0 for VF 2 For instruction: %tmp3 = load i64, i64* %tmp1, align 8
; VF_2-NEXT:    Found an estimated cost of 10 for VF 2 For instruction: store i64 0, i64* %tmp0, align 8
; VF_2-NEXT:    Found an estimated cost of 10 for VF 2 For instruction: store i64 0, i64* %tmp1, align 8
for.body:
  %i = phi i64 [ 0, %entry ], [ %i.next, %for.body ]
  %tmp0 = getelementptr inbounds %i64.8, %i64.8* %data, i64 %i, i32 2
  %tmp1 = getelementptr inbounds %i64.8, %i64.8* %data, i64 %i, i32 6
  %tmp2 = load i64, i64* %tmp0, align 8
  %tmp3 = load i64, i64* %tmp1, align 8
  store i64 0, i64* %tmp0, align 8
  store i64 0, i64* %tmp1, align 8
  %i.next = add nuw nsw i64 %i, 1
  %cond = icmp slt i64 %i.next, %n
  br i1 %cond, label %for.body, label %for.end

for.end:
  ret void
}
