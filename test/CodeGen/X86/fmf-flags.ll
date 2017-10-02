; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown | FileCheck %s -check-prefix=X64
; RUN: llc < %s -mtriple=i686-unknown   | FileCheck %s -check-prefix=X86

declare float @llvm.sqrt.f32(float %x);

define float @fast_recip_sqrt(float %x) {
; X64-LABEL: fast_recip_sqrt:
; X64:       # BB#0:
; X64-NEXT:    sqrtss %xmm0, %xmm1
; X64-NEXT:    movss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-NEXT:    divss %xmm1, %xmm0
; X64-NEXT:    retq
;
; X86-LABEL: fast_recip_sqrt:
; X86:       # BB#0:
; X86-NEXT:    flds {{[0-9]+}}(%esp)
; X86-NEXT:    fsqrt
; X86-NEXT:    fld1
; X86-NEXT:    fdivp %st(1)
; X86-NEXT:    retl
  %y = call fast float @llvm.sqrt.f32(float %x)
  %z = fdiv fast float 1.0,  %y
  ret float %z
}

declare float @llvm.fmuladd.f32(float %a, float %b, float %c);

define float @fast_fmuladd_opts(float %a , float %b , float %c) {
; X64-LABEL: fast_fmuladd_opts:
; X64:       # BB#0:
; X64-NEXT:    movaps %xmm0, %xmm1
; X64-NEXT:    addss %xmm0, %xmm1
; X64-NEXT:    addss %xmm0, %xmm1
; X64-NEXT:    movaps %xmm1, %xmm0
; X64-NEXT:    retq
;
; X86-LABEL: fast_fmuladd_opts:
; X86:       # BB#0:
; X86-NEXT:    flds {{[0-9]+}}(%esp)
; X86-NEXT:    fld %st(0)
; X86-NEXT:    fadd %st(1)
; X86-NEXT:    faddp %st(1)
; X86-NEXT:    retl
  %res = call fast float @llvm.fmuladd.f32(float %a, float 2.0, float %a)
  ret float %res
}

; The multiply is strict.

@mul1 = common global double 0.000000e+00, align 4

define double @not_so_fast_mul_add(double %x) {
; X64-LABEL: not_so_fast_mul_add:
; X64:       # BB#0:
; X64-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    mulsd %xmm0, %xmm1
; X64-NEXT:    addsd %xmm1, %xmm0
; X64-NEXT:    movsd %xmm1, {{.*}}(%rip)
; X64-NEXT:    retq
;
; X86-LABEL: not_so_fast_mul_add:
; X86:       # BB#0:
; X86-NEXT:    fldl {{[0-9]+}}(%esp)
; X86-NEXT:    fld %st(0)
; X86-NEXT:    fmull {{\.LCPI.*}}
; X86-NEXT:    fadd %st(0), %st(1)
; X86-NEXT:    fstpl mul1
; X86-NEXT:    retl
  %m = fmul double %x, 4.2
  %a = fadd fast double %m, %x
  store double %m, double* @mul1, align 4
  ret double %a
}

; The sqrt is strict.

@sqrt1 = common global float 0.000000e+00, align 4

define float @not_so_fast_recip_sqrt(float %x) {
; X64-LABEL: not_so_fast_recip_sqrt:
; X64:       # BB#0:
; X64-NEXT:    sqrtss %xmm0, %xmm1
; X64-NEXT:    movss {{.*#+}} xmm0 = mem[0],zero,zero,zero
; X64-NEXT:    divss %xmm1, %xmm0
; X64-NEXT:    movss %xmm1, {{.*}}(%rip)
; X64-NEXT:    retq
;
; X86-LABEL: not_so_fast_recip_sqrt:
; X86:       # BB#0:
; X86-NEXT:    flds {{[0-9]+}}(%esp)
; X86-NEXT:    fsqrt
; X86-NEXT:    fld1
; X86-NEXT:    fdiv %st(1)
; X86-NEXT:    fxch %st(1)
; X86-NEXT:    fstps sqrt1
; X86-NEXT:    retl
  %y = call float @llvm.sqrt.f32(float %x)
  %z = fdiv fast float 1.0, %y
  store float %y, float* @sqrt1, align 4
  %ret = fadd float %z , 14.5
  ret float %z
}

