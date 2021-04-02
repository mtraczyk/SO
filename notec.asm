extern debug
global notec

section .data

; Constants.
ZERO_CHAR               equ 48 ; ASCII for '0' character.
NINE_CHAR               equ 57 ; ASCII for '9' character.
A_CHAR                  equ 65 ; ASCII for 'A' character.
F_CHAR                  equ 70 ; ASCII for 'F' character.
DECIMAL_BASIS           equ 10 ; Decimal basis.
WRI_NUMBER_MODE_ON      equ 1  ; Writing number mode on.
WRI_NUMBER_MODE_OFF     equ 0  ; Writing number mode off.
EQUAL_SIGN              equ 61 ; ASCII for '='.
PLUS_SIGN               equ 43 ; ASCII for '+'.
MINUS_SIGN              equ 45 ; ASCII for '-'.

section .bss

align 8

%ifdef N
which_notec_to_wait_for resq N ; Used when W appears.
top_stack_number        resq N ; Used to store top stack numbers.
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
  jl      check_equal_sign ; Not an A-F char.
  cmp     rdx, F_CHAR
  jg      check_equal_sign ; Not an A-F char.

  ; It is an A-F char. Conversion into a 10-15 number.
  sub     rdx, A_CHAR
  add     rdx, DECIMAL_BASIS

parse_number:
  cmp     rcx, WRI_NUMBER_MODE_ON
  jne     add_new_number_to_stack ; A new number has to be added onto the stack.

  ; Writing mode is on, adjust the number on the top of the stack.
  pop     rax
  lea     rax, [rax*8]
  lea     rax, [rax*2]
  add     rax, rdx
  push    rax
  jmp     parsing_character_finished

add_new_number_to_stack:
  push    rdx ; Pushing new number onto the stack.
  mov     rcx, WRI_NUMBER_MODE_ON ; Turn on writing number mode.
  jmp     parsing_character_finished

check_equal_sign:
  cmp     rdx, EQUAL_SIGN
  jne     check_plus_sign
  mov     rcx, WRI_NUMBER_MODE_OFF ; Turn off writing number mode.
  jmp     parsing_character_finished

check_plus_sign:
  cmp     rdx, PLUS_SIGN
  jne     check_minus_sign
  pop     r8
  pop     r9
  add     r8, r9
  push    r8
  jmp     parsing_character_finished

check_minus_sign:
  cmp     rdx, MINUS_SIGN
  jne     keep_parsing
  pop     r8
  neg     r8
  push    r8
  jmp     parsing_character_finished

keep_parsing:

parsing_character_finished:
  inc     rsi ; Where to look for next character.
  pop     rax
  mov     [top_stack_number+rdi*8], rax ; Update stack_top for this notec.
  push    rax
  jmp     read_data ; Continue reading input.

traversal_finished:
  pop     rax ; Obtain the returning value.
  ret