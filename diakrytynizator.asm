section .data

; Constants.
SYSTEM_EXIT            equ 60 ; Syscall code for terminate.
EXIT_SUCCESS           equ 0 ; Return code on an successful exit.
EXIT_FAIL              equ 1 ; Return code on an unsuccessful exit.
STDIN                  equ 0 ; Code for stdin.
STDOUT	               equ 1 ; Code for stdout.
SYSTEM_READ            equ 0 ; Code for SYS_READ.
SYSTEN_WRITE           equ 1 ; Code for SYS_WRTIE.
ZERO_CHAR              equ 48 ; ASCII for '0' character.
NINE_CHAR              equ 57 ; ASCII for '9' character.
ZERO                   equ 0 ; Decimal zero.
CHUNK_SIZE             equ 2000 ; Size of buffer chunks.
STARTING_INDEX         equ 0 ; Starting index in arrays.
DECIMAL_BASIS          equ 10 ; Decimal basis.
MIN_NUM_OF_COEFF       equ 1 ; Minimum number of coefficients.
MODULO                 equ 0x10FF80 ; Value of the modulo.
NUM_OF_DIGITS          equ 11 ; Take modulo after reading NUM_OF_DIGITS digits.

; First byte schemes in UTF-8.
FB_ONE_BYTE_SCHEME     equ 00000000b ; One byte scheme UTF-8 is 0xxxxxxx.
FB_TWO_BYTES_SCHEME    equ 11000000b ; Two bytes UTF-8 is 110xxxxx.
FB_THREE_BYTES_SCHEME  equ 11100000b ; Three bytes UTF-8 is 1110xxxx.
FB_FOUR_BYTES_SCHEME   equ 11110000b ; Four bytes UTF-8 is 11110xxx.

; Maximum first byte's value when xored with corresponding first byte scheme.
FB_ONE_BYTE_MAX_VAL    equ 01111111b ; One byte UTF-8 character.
FB_TWO_BYTES_MAX_VAL   equ 00011111b ; Two bytes UTF-8 character.
FB_THREE_BYTES_MAX_VAL equ 00001111b ; Three bytes UTF-8 character.
FB_FOUR_BYTES_MAX_VAL  equ 00000111b ; Four bytes UTF-8 character.

; Used for projecting binary to UTF-8 characters and UTF-8 characters
; to binary using PEXT and PDEP.
TWO_BYTES_P            equ 0001111100111111b
THREE_BYTES_P          equ 000011110011111100111111b
FOUR_BYTES_P           equ 00000111001111110011111100111111b

; Scheme for two bytes UTF-8 is 110xxxxx10xxxxxx.
TWO_BYTES_CHAR_SC      equ 1100000010000000b
; Scheme for three bytes UTF-8 is 1110xxxx10xxxxxx10xxxxxx.
THREE_BYTES_CHAR_SC    equ 111000001000000010000000b
; Scheme for four bytes UTF-8 is 11110xxx10xxxxxx10xxxxxx10xxxxxx.
FOUR_CHAR_SC           equ 11110000100000001000000010000000b

; Maximum values for k-bytes UTF-8 characters.
MAX_ONE_B              equ 0x7F ; Maximum value for one byte UTF-8 character.
MAX_TWO_B              equ 0x7FF ; Maximum value for two bytes UTF-8 character.
MAX_THR_B              equ 0xFFFF ; Maximum value for three bytes UTF-8 char.
MAX_FOU_B              equ 0x1FFFFF ; Maximum value for four bytes UTF-8 char.

; Minimum values for k-bytes UTF-8 characters.
MIN_TWO_B              equ 0x80 ; Minimum value for two bytes UTF-8 character.
MIN_THREE_B            equ 0x800 ; Minimum value for three bytes UTF-8 char.
MIN_FOUR_B             equ 0x10000 ; Minimum value for four bytes UTF-8 char.

; How many bytes.
ONE_BYTE               equ 1
TWO_BYTES              equ 2
THREE_BYTES            equ 3
FOUR_BYTES             equ 4

; Scheme for not first bytes in UTF-8 is 1xxxxxxx.
ADDITIONAL_BYTES_SC    equ 10000000b
; Used for checking not first bytes correctness in UTF-8 characters.
AUXILIARY_BYTE         equ 11000000b

NUMBER_OF_BITS         equ 8 ; Eight bits.
LIT_BYTE               equ 11111111b ; Eight lit bits.
POINTER_SIZE           equ 0x08 ; Pointer size in bytes.

DIA_CONSTANT          equ 0x80 ; Diacritization constant.

section .bss

input      resb 4000
input_size resq 1
input_ind  resq 1
output     resb 4000
output_siz resq 1
output_ind resq 1

%macro write_byte_to_output 2
  mov     r11, %1 ; Byte value.
  mov     rcx, %2 ; Which byte minus one in the UTF-8 character.
  mov     rdi, LIT_BYTE
  lea     rcx, [rcx*8] ; Change number of bytes into number of bits.
  shr     r11, cl ; The byte is now the first one in the integer.
  and     r11, rdi ; Obtaining integer value of the byte.
  mov     r15, [output_ind] ; Get an actual index of the output buffer.
  mov     [output+r15], r11 ; Write byte to the output buffer.

  ; Increasing the output buffer's size and index.
  mov     r11, [output_siz]
  inc     r11
  inc     r15
  mov     [output_ind], r15
  mov     [output_siz], r11

  cmp     r11, CHUNK_SIZ ; Check whether buffer should be written to stdout.
  jl      do_not_write_bytes

write_bytes:
  mov     rcx, %2
  cmp     rcx, ZERO
  jne     do_not_write_bytes ; Do not write partial characters to stdin.

  call    _write_to_stdout

do_not_write_bytes:

%endmacro

global _start

section .text

_start:
  mov     rbp, [rsp] ; Number of polynomial's coefficients plus one.
  cmp     rbp, MIN_NUM_OF_COEFF ; There must be at least one coefficient.
  je      error
  lea     rbp, [rbp*8]
  mov     r14, rbp ; r14 used later for saving coefficients on the stack.
  jmp     read_coefficients

; Calculates value under rax register modulo 0x10FF80.
; This function was obtained by disassembling C code, it performs much better
; than simply using div because we can use the fact that the modulo is a
; constant. One can read https://gmplib.org/~tege/division-paper.pdf to get a grasp of it.
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
  cmp     rbp, POINTER_SIZE ; Checks whether there are coefficients to parse.
  je      read_input ; No coefficients to parse - starts reading stdin.
  mov     rdi, [rsp+rbp] ; Stores next coefficient to parse in rdi register.
  sub     rbp, POINTER_SIZE ; Where to look for next coefficient on the stack.

; Numbers with starting zeroes are valid.
atoi:
  xor     rax, rax ; Set the initial total to 0.
  xor     r12, r12 ; Number of digits parsed set to 0.

convert:
  movzx   rsi, byte [rdi] ; Get the current character.
  test    rsi, rsi ; Check for \0.
  je      number_is_read
  cmp     rsi, ZERO_CHAR ; Anything less than 0 is invalid.
  jl      error
  mov     r11, rsi ; Copy of rsi register.
  cmp     rsi, NINE_CHAR ; Anything greater than 9 is invalid.
  jg      error
  sub     rsi, ZERO_CHAR  ; Convert from ASCII to decimal.

  ; Adding contribution of a single digit.
  lea     rax, [rax*4+rax]
  lea     rax, [rax*2+rsi]

  inc     rdi ; Get the address of the next character.
  inc     r12 ; Successfully parsed another digit.
  cmp     r12, NUM_OF_DIGITS ; When r12 equals NUM_OF_DIGITS then take modulo.
  jne     convert
  call    _modulo ; Get value under rax modulo 0x10FF80.
  jmp     convert

number_is_read:
  call    _modulo ; Get value under rax modulo 0x10FF80.
  add     r14, POINTER_SIZE ; Where to save next coefficient.
  mov     [rsp+r14], rax ; Save next coefficient.
  jmp     read_coefficients ; Continue parsing coefficients.

get_polynomial_value:
  mov     r13, [rsp] ; Get number of coefficients+1.
  lea     r14, [r13*8] ; Multiply number of coefficients by 8, pointer size is 8.
  dec     r13 ; Number of coefficients.
  mov     rdi, rax ; The answer will be in rax, save x to rdi.
  xor     rax, rax

; Using Horner's Method to find polynomial's value at x.
; Therefore coefficients` traversal starting with a_n not a_0.
traverse_coefficients:
  add     r14, POINTER_SIZE
  imul    rax, rdi ; Using Horner's Method. Multiply by x.
  add     rax, [rsp+r14] ; Using Horner's Method. Add next coefficient.
  call    _modulo
  dec     r13 ; Decrease number of coefficients to traverse.
  cmp     r13, ZERO ; Check whether there are still some coefficients.
  jne     traverse_coefficients
  call    _modulo
  add     rax, DIA_CONSTANT
  jmp     write_utf_8_char

read_to_buffer:
  mov     rax, SYS_READ
  mov     rdi, STDIN
  mov     rsi, input ; Buffer address.
  mov     rdx, CHUNK_SIZE
  syscall
  cmp     rax, ZERO ; Check for syscall errors.
  jl      error
  je      exit
  mov     [input_size], rax ; Saving number of bytes read.
  mov     r11, ZERO
  mov     [input_ind], r11 ; Resetting starting index.

_read_one_byte:
  mov     r11, ZERO
  cmp     [input_size], r11
  je      read_to_buffer
  mov     r11, [input_ind]
  movzx   rax, byte [input+r11]
  inc     r11
  mov     [input_ind], r11
  mov     r12, [input_size]
  dec     r12
  mov     [input_size], r12
  ret

; Parses input from stdin.
read_input:
  call    _read_one_byte
  mov     r9, FB_FOB_SC
  xor     r9, rax
  cmp     r9, FFOB_MA_V
  jle     read_four_bytes_utf_8_char
  mov     r9, FB_THB_SC
  xor     r9, rax
  cmp     r9, FTHB_MA_V
  jle     read_three_bytes_utf_8_char
  mov     r9, FB_TWB_SC
  xor     r9, rax
  cmp     r9, FTWB_MA_V
  jle     read_two_bytes_utf_8_char
  mov     r9, FB_OB_SC
  xor     r9, rax
  cmp     r9, FOB_MA_V
  jle     read_one_byte_utf_8_char
  jmp     error

_get_additional_byte:
  shl     rax, EIG_BITS
  push    rax
  call    _read_one_byte
  mov     rdi, rax
  xor     rdi, ADDB_SCHE
  and     rdi, AUX_BYTE
  cmp     rdi, ZERO
  jne     error
  mov     rdi, rax
  pop     rax
  add     rax, rdi
  ret

polynomial_value:
  mov     rax, rdx
  sub     rax, 0x80
  jmp     get_polynomial_value

read_one_byte_utf_8_char:
  jmp     write_utf_8_char

read_two_bytes_utf_8_char:
  call    _get_additional_byte
  mov     r11, TWO_BYTES_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_TWO_B
  jl      error
  jmp     polynomial_value

read_three_bytes_utf_8_char:
  call    _get_additional_byte
  call    _get_additional_byte
  mov     r11, THREE_BYTES_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_THR_B
  jl      error
  jmp     polynomial_value

read_four_bytes_utf_8_char:
  call    _get_additional_byte
  call    _get_additional_byte
  call    _get_additional_byte
  mov     r11, FOUR_BYTES_P
  pext    rdx, rax, r11
  cmp     rdx, MIN_FOU_B
  jl      error
  cmp     rdx, 0x10FFFF
  jg      error
  jmp     polynomial_value

write_utf_8_char:
  cmp     rax, MAX_ONE_B
  jle     write_one_byte_utf_8_char
  cmp     rax, MAX_TWO_B
  jle     write_two_bytes_utf_8_char
  cmp     rax, MAX_THR_B
  jle     write_three_bytes_utf_8_char
  cmp     rax, MAX_FOU_B
  jle     write_four_bytes_utf_8_char

write_to_output:
  mov     r10, r13
loop:
  dec     r13
  write_byte_to_output rdx, r13
  cmp     r13, ZERO
  je      read_input
  jmp     loop

write_one_byte_utf_8_char:
  mov     rdx, rax
  mov     r13, ONE_BYTE
  jmp     write_to_output

write_two_bytes_utf_8_char:
  mov     r11, TWO_BYTES_P
  pdep    rdx, rax, r11
  mov     r11, TWB_CH_SC
  add     rdx, r11
  mov     r13, TWO_BYTES
  jmp     write_to_output

write_three_bytes_utf_8_char:
  mov     r11, THREE_BYTES_P
  pdep    rdx, rax, r11
  mov     r11, THB_CH_SC
  add     rdx, r11
  mov     r13, THR_BYTES
  jmp     write_to_output

write_four_bytes_utf_8_char:
  mov     r11, FOUR_BYTES_P
  pdep    rdx, rax, r11
  mov     r11, FOB_CH_SC
  add     rdx, r11
  mov     r13, FOU_BYTES
  jmp     write_to_output

_write_to_stdout:
  mov     rax, SYS_WRITE
  mov     rdi, STDOUT
  mov     rsi, output
  mov     rdx, [output_siz]
  syscall
  mov     r15, ZERO
  mov     [output_ind], r15
  mov     [output_siz], r15
  cmp     rax, ZERO
  jl      error
  ret

; Exit with return code 0.
error:
  call    _write_to_stdout
  mov     eax, SYS_EXIT   ; Use SYS_EXIT.
  mov     edi, EXIT_FAI   ; Return 1 on error
  syscall

; Exit with return code 0.
exit:
  call    _write_to_stdout
  mov     eax, SYS_EXIT   ; Use SYS_EXIT.
  mov     edi, EXIT_SUC   ; Return code is zero.
  syscall
