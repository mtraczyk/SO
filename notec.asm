global notec

section .data

; Constants.
ZERO_CHAR               equ 48 ; ASCII for '0' character.
NINE_CHAR               equ 57 ; ASCII for '9' character.
A_CHAR                  equ 65 ; ASCII for 'A' character.
F_CHAR                  equ 70 ; ASCII for 'F' character.
DECIMAL_BASIS           equ 10 ; Decimal basis.
IS_WRI_NUMBER_MODE_ON   equ 1  ; Value under rcx equals one when the mode is on.

section .bss

align 8

%ifdef N
which_notec_to_wait_for dq N ; Shared data between threads.
%endif

section .text

align 8
notec:
  xor     rcx, rcx ; Number writing mode off.

read_data:
  movzx   rdx, byte [rsi] ; Get one ASCIIZ character.
  test    rdx, rdx ; Check for \0.
  je      traversal_finished ; No more characters to read.

check_for_0_to_9_digit:
  cmp     rdx, ZERO_CHAR
  jl      check_for_A_to_F_char ; Not a 0-9 char.
  cmp     rdx, NINE_CHAR
  jg      check_for_A_to_F_char ; Not a 0-9 char.

  ; It is a 0-9 char.
  sub     rdx, ZERO_CHAR ; Conversion into a digit.
  jmp     parse_number

check_for_A_to_F_char:
  cmp     rdx, A_CHAR
  jl      keep_parsing ; Not an A-F char.
  cmp     rdx, F_CHAR
  jg      keep_parsing ; Not an A-F char.

  ; It is an A-F char. Conversion into a 10-15 number.
  sub     rdx, A_CHAR
  add     rdx, DECIMAL_BASIS

parse_number:
  cmp     rcx, IS_WRI_NUMBER_MODE_ON
  jne     add_new_number_to_stack ; A new number has to be added onto the stack.

  ; Writing mode is on, adjust the number on the top of the stack.
  pop     rax
  lea     rax, [rax*16]
  add     rax, rdx
  push    rax
  jmp     parsing_character_finished

add_new_number_to_stack:
  push    rdx
  jmp     parsing_character_finished

keep_parsing:

parsing_character_finished:
  inc     rsi ; Where to look for next character.
  jmp     read_data ; Continue reading input.

traversal_finished:
  pop     rax
  ret