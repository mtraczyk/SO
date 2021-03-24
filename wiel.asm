section .data

; Define constants.
SYS_EXIT  equ 60          ; Call code for terminate.
EXIT_SUC  equ 0           ; Return code on an successful exit.
EXIT_FAI  equ 1           ; Return code on an unsuccessful exit.

section .bss

global _start

section .text

_start:
  mov     rbp, [rsp]      ; Number of polynomial`s coefficients.
  imul    rbp, 0x08       ; Number of coefficients multiplied by 0x08.

; Parses coefficients and stores their value modulo 0x10FF80 on the stack.
read_coefficients:
  cmp     rbp, 0x08       ; Checks whether there are coefficients to parse.
  je      read_input      ; No coefficients to parse - starts reading stdin.
  mov     rdi, [rsp + rbp]; Stores next coefficient to parse in rdi register.
  sub     rbp, 0x08       ; Where to look for next coefficient on the stack.
  jmp     atoi            ; Convert coefficient to an integer.

atoi:
  xor     rax, rax        ; Set initial total to 0.
  xor     r10, r10        ; First digit has not been read.

convert:
  movzx   rsi, byte [rdi] ; Get the current character.
  test    rsi, rsi        ; Check for \0.
  je      read_coefficients
  cmp     rsi, 48         ; Anything less than 0 is invalid.
  jl      error

  cmp     rsi, 57         ; Anything greater than 9 is invalid.
  jg      error
  sub     rsi, 48         ; Convert from ASCII to decimal.
  imul    rax, 10         ; Multiply total by 10.
  add     rax, rsi        ; Add current digit to total.
  inc     rdi             ; Get the address of the next character.
  mov     r10, 1          ; First digit is read.
  jmp     convert

; Parses input from stdin.
read_input:

; Exit with return code 0.
error:
  mov     eax, SYS_EXIT
  mov     edi, EXIT_FAI         ; Return 1 on error
  syscall

; Exit with return code 0.
exit:
  mov     eax, SYS_EXIT
  mov     edi, EXIT_SUC        ; Return code is zero.
  syscall