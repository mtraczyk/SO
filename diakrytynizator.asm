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
START_IND equ 0           ; Starting index.
STDOUT	  equ 1
SYS_WRITE equ 1
NULL      equ 0           ; ASCII code for NULL.
MODULO    equ 0x10FF80
NUM_OF_DI equ 11          ; Take modulo after reading NUM_OF_DI digits.

section .bss

str_num    resb 20         ; Used to store integers as strings.
num_of_co  resq 1          ; Used to store number of coefficients.

; Macro used for printing integers.
%macro printVa 1
  mov     rax, %1         ; Get the integer.
  mov     rcx, 0          ; Digit count equals zero.

%%divideLoop:
  mov     edx, 0
  mov     rbx, DEC_BASIS
  div     rbx             ; Divide number by 10.
  push    rdx             ; Push remainder.
  inc     rcx             ; Increment digit count.
  cmp     rax, 0          ; if (result > 0)
  jne     %%divideLoop    ;   goto divideLoop

  mov     rbx, str_num    ; Get address of string.
  mov     r10, START_IND  ; Current index is zero.

%%popLoop:
  pop     rax             ; Pop digit.
  add     al, ZERO_CHAR   ; Digit into ASCII.

  ; Storing digit in strNum.
  mov     byte [rbx+r10], al
  inc     r10             ; Increment index.
  dec     rcx             ; Decrease number of digits left to change into ASCII.
  cmp     rcx, 0          ; Check whether there are still digits to process.
  jne     %%popLoop

  xor     r12, r12

%%writeToStdout:
  mov     rax, SYS_WRITE
  mov     rdi, STDOUT
  lea     r11, [rbx+r12]
  mov     rsi, r11
  mov     rdx, 1          ; Write one byte to stdout.
  syscall

  cmp     rax, 0
  jl      error

  inc     r12
  cmp     r12, r10        ; Check whether there are still some digits.
  jne     %%writeToStdout

%endmacro

global _start

section .text

_start:
  mov     rbp, [rsp]      ; Number of polynomial's coefficients plus one.
  mov     rbx, num_of_co
  mov     [rbx], rbp
  cmp     rbp, 1          ; There must be at least one coefficient.
  je      error
  lea     rbp, [rbp*8]    ; Number of coefficients multiplied by 0x08.
  mov     r14, rbp
  jmp     read_coefficients

; Calculates value under rax register modulo 0x10FF80.
_modulo:
  mov     rdx, 0x787c03a5c11c4499
  mov     r15, rax
  mul     rdx
  mov     rax, r15
  shr     rdx, 0x13
  imul    rdx, rdx, MODULO
  sub     rax, rdx
  xor     r12, r12
nic:
  ret

; Parses coefficients and stores their value modulo 0x10FF80 on the stack.
read_coefficients:
  cmp     rbp, 0x08       ; Checks whether there are coefficients to parse.
  je      read_input      ; No coefficients to parse - starts reading stdin.
  mov     rdi, [rsp+rbp]  ; Stores next coefficient to parse in rdi register.
  sub     rbp, 0x08       ; Where to look for next coefficient on the stack.
  jmp     atoi            ; Convert coefficient to an integer.

atoi:
  xor     rax, rax        ; Set initial total to 0.
  xor     r10, FD_N_READ  ; First digit has not been read.
  xor     r12, r12

convert:
  movzx   rsi, byte [rdi] ; Get the current character.
  test    rsi, rsi        ; Check for \0.
  je      number_is_read
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
  lea     rax, [rax*4+rax]
  lea     rax, [rax*2+rsi]

  inc     rdi             ; Get the address of the next character.
  mov     r10, FD_READ    ; First digit is read.
  inc     r12
  cmp     r12, NUM_OF_DI
  jne     convert
  call    _modulo         ; Get value under rax modulo 0x10FF80.
  jmp     convert

number_is_read:
  call    _modulo         ; Get value under rax modulo 0x10FF80.
  add     r14, 0x08
  mov     [rsp+r14], rax
  jmp     read_coefficients

get_polynomial_value:
  mov     r13, [num_of_co]
  lea     r14, [r13*8]
  dec     r13
  mov     rdi, rax
  xor     rax, rax

traverse_coefficients:
  add     r14, 0x08
  imul    rax, rdi
  add     rax, [rsp+r14]
  call    _modulo
  dec     r13
  cmp     r13, 0
  jne     traverse_coefficients
  jmp     exit

; Parses input from stdin.
read_input:
  mov     rbp, rsp
  mov     rax, 1
  jmp     get_polynomial_value
  jmp     exit

; Exit with return code 0.
error:
  mov     eax, SYS_EXIT
  mov     edi, EXIT_FAI   ; Return 1 on error
  syscall

; Exit with return code 0.
exit:
  printVa rax
  mov     eax, SYS_EXIT
  mov     edi, EXIT_SUC   ; Return code is zero.
  syscall
