global notec

section .data

section .bss

align 8

#if N
which_notec_to_wait_for dq N
#endif

section .text

align 8
notec:
  ret