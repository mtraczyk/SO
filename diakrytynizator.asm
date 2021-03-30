section .data

; Define constants.
SYS_EXIT  equ 60          ; Call code for terminate.
EXIT_SUC  equ 0           ; Return code on an successful exit.
EXIT_FAI  equ 1           ; Return code on an unsuccessful exit.
ZERO_CHAR equ 48          ; ASCII for '0' character.
NINE_CHAR equ 57          ; ASCII for '9' character.
ZERO      equ 0
DEC_BASIS equ 10          ; Decimal basis.
START_IND equ 0           ; Starting index.
STDOUT	  equ 1           ; Code for stdout.
MI_N_OF_C equ 1           ; Minimum number of coefficients.
STDIN     equ 0           ; Code for stdin.
SYS_READ  equ 0           ; Code for SYS_READ.
SYS_WRITE equ 1           ; Code for SYS_WRTIE.
MODULO    equ 0x10FF80    ; Value of the modulo.
NUM_OF_DI equ 11          ; Take modulo after reading NUM_OF_DI digits.
FB_OB_SC  equ 00000000b   ; First byte scheme for one byte UTF-8 is 0xxxxxxx.
FB_TWB_SC equ 11000000b   ; First byte scheme for two bytes UTF-8 is 110xxxxx.
FB_THB_SC equ 11100000b   ; First byte scheme for three bytes UTF-8 is 1110xxxx.
FB_FOB_SC equ 11110000b   ; First byte scheme for four bytes UTF-8 is 11110xxx.

FOB_MA_V  equ 01111111b
FTWB_MA_V equ 00011111b
FTHB_MA_V equ 00001111b
FFOB_MA_V equ 00000111b

; Used for projecting UTF-8 characters with PEXT and PDEP.
FB_TWB_P  equ 0001111100111111b
FB_THB_P  equ 000011110011111100111111b
FB_FOB_P  equ 00000111001111110011111100111111b

; Scheme for two bytes UTF-8 is 110xxxxx10xxxxxx.
TWB_CH_SC equ 1100000010000000b
; Scheme for three bytes UTF-8 is 1110xxxx10xxxxxx10xxxxxx.
THB_CH_SC equ 111000001000000010000000b
 ; Scheme for four bytes UTF-8 is 11110xxx10xxxxxx10xxxxxx10xxxxxx.
FOB_CH_SC equ 11110000100000001000000010000000b

; Maximum values for k-bytes UTF-8 characters.
MAX_ONE_B equ 0x7F        ; Maximum value for one byte UTF-8 character
MAX_TWO_B equ 0x7FF       ; Maximum value for two bytes UTF-8 character
MAX_THR_B equ 0xFFFF      ; Maximum value for three bytes UTF-8 character
MAX_FOU_B equ 0x1FFFFF    ; Maximum value for four bytes UTF-8 character

; Minimum values for k-bytes UTF-8 characters.
MIN_TWO_B equ 0x80        ; Minimum value for two bytes UTF-8 character
MIN_THR_B equ 0x800       ; Minimum value for three bytes UTF-8 character
MIN_FOU_B equ 0x10000     ; Minimum value for four bytes UTF-8 character

; How many bytes.
ONE_BYTE  equ 1
TWO_BYTES equ 2
THR_BYTES equ 3
FOU_BYTES equ 4

ADDB_SCHE equ 10000000b
AUX_BYTE  equ 11000000b

EIG_BITS  equ 8            ; Eight bits.
EL_BIT_MA equ 11111111b

section .bss

str_num    resb 20         ; Used to store integers as strings.
input      resb 10
output     resb 10

%macro write_byte_to_output 3
  mov     r11, %1         ; Get the integer.
  mov     rcx, %2         ; Which byte, Little Endian.
  mov     r15, %3
  mov     rdi, EL_BIT_MA
  lea     rcx, [rcx*8]
  shr     r11, cl
  and     r11, rdi
  mov     rcx, output
  mov     [rcx+r15], r11
%endmacro

global _start

section .text

_start:
  mov     rbp, [rsp]      ; Number of polynomial's coefficients plus one.
  cmp     rbp, MI_N_OF_C  ; There must be at least one coefficient.
  je      error
  lea     rbp, [rbp*8]    ; Number of coefficients multiplied by 0x08.
  mov     r14, rbp        ; r14 used later for saving coefficients on the stack.
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
  ret

; Parses coefficients and stores their value modulo 0x10FF80 on the stack.
read_coefficients:
  cmp     rbp, 0x08       ; Checks whether there are coefficients to parse.
  je      read_input      ; No coefficients to parse - starts reading stdin.
  mov     rdi, [rsp+rbp]  ; Stores next coefficient to parse in rdi register.
  sub     rbp, 0x08       ; Where to look for next coefficient on the stack.

atoi:
  xor     rax, rax        ; Set initial total to 0.
  xor     r12, r12

convert:
  movzx   rsi, byte [rdi] ; Get the current character.
  test    rsi, rsi        ; Check for \0.
  je      number_is_read
  cmp     rsi, ZERO_CHAR  ; Anything less than 0 is invalid.
  jl      error
  mov     r11, rsi        ; Copy of rsi register.
  cmp     rsi, NINE_CHAR  ; Anything greater than 9 is invalid.
  jg      error
  sub     rsi, ZERO_CHAR  ; Convert from ASCII to decimal.
  ; Multiplying rax by 10.
  lea     rax, [rax*4+rax]
  lea     rax, [rax*2+rsi]
  inc     rdi             ; Get the address of the next character.
  inc     r12
  cmp     r12, NUM_OF_DI  ; When r12 equals NUM_OF_DI then take modulo.
  jne     convert
  call    _modulo         ; Get value under rax modulo 0x10FF80.
  jmp     convert

number_is_read:
  call    _modulo         ; Get value under rax modulo 0x10FF80.
  add     r14, 0x08       ; Where to save next coefficient.
  mov     [rsp+r14], rax  ; Save next coefficient.
  jmp     read_coefficients

get_polynomial_value:
  mov     r13, [rsp]      ; Get number of coefficients+1.
  lea     r14, [r13*8]    ; Multiply number of coefficients by 8.
  dec     r13             ; Number of coefficients.
  mov     rdi, rax        ; The answer will be in rax, save x to rdi.
  xor     rax, rax

; Using Horner's Method to find polynomial's value at x.
; Therefore coefficients` traversal starting with an not a0.
traverse_coefficients:
  add     r14, 0x08
  imul    rax, rdi        ; Using Horner's Method. Multiply by x.
  add     rax, [rsp+r14]  ; Using Horner's Method. Add next coefficient.
  call    _modulo
  dec     r13             ; Decrease number of coefficients to traverse.
  cmp     r13, ZERO       ; Check whether there are still some coefficients.
  jne     traverse_coefficients
  add     rax, 0x80
  call    _modulo
  jmp     write_utf_8_char

_read_one_byte:
  mov     rax, SYS_READ
  mov     rdi, STDIN
  mov     rsi, input
  mov     rdx, 1
  syscall
  cmp     rax, ZERO
  jl      error
  je      exit
  ret

; Parses input from stdin.
read_input:
  call    _read_one_byte
  movzx   rax, byte [input]
  mov     r9, FB_FOB_SC
  xor     r9, [input]
  cmp     r9, FFOB_MA_V
  jle     read_four_bytes_utf_8_char
  mov     r9, FB_THB_SC
  xor     r9, [input]
  cmp     r9, FTHB_MA_V
  jle     read_three_bytes_utf_8_char
  mov     r9, FB_TWB_SC
  xor     r9, [input]
  cmp     r9, FTWB_MA_V
  jle     read_two_bytes_utf_8_char
  mov     r9, FB_OB_SC
  xor     r9, [input]
  cmp     r9, FOB_MA_V
  jle     read_one_byte_utf_8_char
  jmp     error

_get_additional_byte:
  shl     rax, EIG_BITS
  push    rax
  call    _read_one_byte
  mov     rdi, [input]
  xor     rdi, ADDB_SCHE
  and     rdi, AUX_BYTE
  cmp     rdi, ZERO
  jne     error
  pop     rax
  add     rax, [input]
  ret

polynomial_value:
  mov     rax, rdx
  sub     rax, 0x80
  jmp     get_polynomial_value

read_one_byte_utf_8_char:
  jmp     write_utf_8_char

read_two_bytes_utf_8_char:
  call    _get_additional_byte
  mov     r11, FB_TWB_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_TWO_B
  jl      error
  jmp     polynomial_value

read_three_bytes_utf_8_char:
  call    _get_additional_byte
  call    _get_additional_byte
  mov     r11, FB_THB_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_THR_B
  jl      error
  jmp     polynomial_value

read_four_bytes_utf_8_char:
  call    _get_additional_byte
  call    _get_additional_byte
  call    _get_additional_byte
  mov     r11, FB_FOB_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_FOU_B
  jl      error
  cmp     rdx, 0x10FFFF
  jg      error
  jmp     polynomial_value

write_bytes:
  mov     rax, SYS_WRITE
  mov     rdi, STDOUT
  mov     rsi, r9
  mov     rdx, r10
  syscall
  cmp     rax, ZERO
  jl      error
  jmp     read_input

write_utf_8_char:
  mov     r9, output
  cmp     rax, MAX_ONE_B
  jle     write_one_byte_utf_8_char
  cmp     rax, MAX_TWO_B
  jle     write_two_bytes_utf_8_char
  cmp     rax, MAX_THR_B
  jle     write_three_bytes_utf_8_char
  cmp     rax, MAX_FOU_B
  jle     write_four_bytes_utf_8_char

write_one_byte_utf_8_char:
  mov     [r9], rax
  mov     r10, ONE_BYTE
  jmp     write_bytes

write_to_output:
  mov     r14, START_IND
  mov     r10, r13
loop:
  dec     r13
  write_byte_to_output rdx, r13, r14
  inc     r14
  cmp     r13, ZERO
  je      write_bytes
  jmp     loop

write_two_bytes_utf_8_char:
  mov     r11, FB_TWB_P
  pdep    rdx, rax, r11
  mov     r11, TWB_CH_SC
  add     rdx, r11
  mov     r13, TWO_BYTES
  jmp     write_to_output

write_three_bytes_utf_8_char:
  mov     r11, FB_THB_P
  pdep    rdx, rax, r11
  mov     r11, THB_CH_SC
  add     rdx, r11
  mov     r13, THR_BYTES
  jmp     write_to_output

write_four_bytes_utf_8_char:
  mov     r11, FB_FOB_P
  pdep    rdx, rax, r11
  mov     r11, FOB_CH_SC
  add     rdx, r11
  mov     r13, FOU_BYTES
  jmp     write_to_output

; Exit with return code 0.
error:
  mov     eax, SYS_EXIT   ; Use SYS_EXIT.
  mov     edi, EXIT_FAI   ; Return 1 on error
  syscall

; Exit with return code 0.
exit:
  mov     eax, SYS_EXIT   ; Use SYS_EXIT.
  mov     edi, EXIT_SUC   ; Return code is zero.
  syscall
