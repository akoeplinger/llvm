; Test that the ToAsciiOptimizer works correctly
; RUN: llvm-as < %s | opt -simplify-libcalls | llvm-dis | not grep 'call.*%ffs'

declare int %ffs(int)
declare int %ffsl(int)
declare int %ffsll(long)

implementation   ; Functions:

int %main () {
  %val1 = call int %ffs(int 1)
  %val2 = call int %ffs(int 2048)
  %val3 = call int %ffsl(int 65536)
  %val4 = call int %ffsll(long 1024)
  %val5 = call int %ffsll(long 17179869184)
  %val6 = call int %ffsll(long 1152921504606846976)
  %rslt1 = add int %val1, %val2
  %rslt2 = add int %val3, %val4
  %rslt3 = add int %val5, %val6
  %rslt4 = add int %rslt1, %rslt2
  %rslt5 = add int %rslt4, %rslt3
  ret int %rslt5
}
