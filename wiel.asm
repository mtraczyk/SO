section .data

; Define constants.
SYS_EXIT  equ 60          ; Call code for terminate.
EXIT_SUC  equ 0           ; Return code on an successful exit.
EXIT_FAI  equ 1           ; Return code on an unsuccessful exit.
FD_READ   equ 0           ; First digit has been already read.
FD_N_READ equ 1           ; First digit hasn't been already read.
ZERO_CHAR equ 48          ; ASCII for '0' character.
NINE_CHAR equ 57          ; ASCII for '9' character.
DEC_BASIS equ 10          ; Decimal basis.

section .bss

global _start

section .text

_start:
  mov     rbp, [rsp]      ; Number of polynomial's coefficients.
  imul    rbp, 0x08       ; Number of coefficients multiplied by 0x08.
  jmp     read_coefficients

; Calculates value under rax register modulo 0x10FF80.
_modulo:
  movabs rdx, 0x787c03a5c11c4499
  mov    rax, rdi
  mul    rdx
  mov    rax, rdi
  shr    rdx, 0x13
  imul   rdx, rdx, 0x10ff80
  sub    rax, rdx
  ret

; Parses coefficients and stores their value modulo 0x10FF80 on the stack.
read_coefficients:
  cmp     rbp, 0x08       ; Checks whether there are coefficients to parse.
  je      read_input      ; No coefficients to parse - starts reading stdin.
  mov     rdi, [rsp + rbp]; Stores next coefficient to parse in rdi register.
  sub     rbp, 0x08       ; Where to look for next coefficient on the stack.
  jmp     atoi            ; Convert coefficient to an integer.

atoi:
  xor     rax, rax        ; Set initial total to 0.
  xor     r10, FD_N_READ  ; First digit has not been read.

convert:
  movzx   rsi, byte [rdi] ; Get the current character.
  test    rsi, rsi        ; Check for \0.
  je      number_read
  cmp     rsi, ZERO_CHAR  ; Anything less than 0 is invalid.
  jl      error
  mov     r11, rsi        ; Copy of rsi register.

  ; r11 equals rsi if first digit is being read, otherwise zero.
  imul    r11, r10
  ; If r11 equals 48 then the first digit is zero.
  cmp     r11, ZERO_CHAR
  je      error           ; The first digit of a number can't be zero.

  cmp     rsi, NINE_CHAR  ; Anything greater than 9 is invalid.
  jg      error
  sub     rsi, ZERO_CHAR  ; Convert from ASCII to decimal.
  imul    rax, DEC_BASIS  ; Multiply total by 10.
  add     rax, rsi        ; Add current digit to total.
  call    _modulo         ; Get value under rax modulo 0x10FF80.
  inc     rdi             ; Get the address of the next character.
  mov     r10, FD_READ    ; First digit is read.
  jmp     convert

number_read:
  push    rax             ; Store integer on the stack.
  jmp     read_coefficients

; Parses input from stdin.
read_input:
  jmp     exit

; Exit with return code 0.
error:
  mov     eax, SYS_EXIT
  mov     edi, EXIT_FAI         ; Return 1 on error
  syscall

; Exit with return code 0.
exit:
  mov     eax, SYS_EXIT
  mov     edi, EXIT_SUC         ; Return code is zero.
  syscall