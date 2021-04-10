extern debug
global notec

section .rodata

; Constants.
ZERO                    equ 0
STACK_CHUNK             equ 8   ; In 64 bit mode, stack's chunk is 8 bytes.
ZERO_CHAR               equ 48  ; ASCII for '0' character.
NINE_CHAR               equ 57  ; ASCII for '9' character.
A_CHAR                  equ 65  ; ASCII for 'A' character.
F_CHAR                  equ 70  ; ASCII for 'F' character.
a_CHAR                  equ 97  ; ASCII for 'a' character.
f_CHAR                  equ 102 ; ASCII for 'f' character.
DECIMAL_BASIS           equ 10  ; Decimal basis.
WRI_NUMBER_MODE_ON      equ 1   ; Writing number mode on.
WRI_NUMBER_MODE_OFF     equ 0   ; Writing number mode off.
EQUAL_SIGN              equ 61  ; ASCII for '='.
PLUS_SIGN               equ 43  ; ASCII for '+'.
MULTIPLY_SIGN           equ 42  ; ASCII for '*'.
MINUS_SIGN              equ 45  ; ASCII for '-'.
AND_SIGN                equ 38  ; ASCII for '&'.
OR_SIGN                 equ 124 ; ASCII for '|'.
XOR_SIGN                equ 94  ; ASCII for '^'.
NOT_SIGN                equ 126 ; ASCII for '~'.
Z_CHAR                  equ 90  ; ASCII for 'Z' character.
Y_CHAR                  equ 89  ; ASCII for 'Y' character.
X_CHAR                  equ 88  ; ASCII for 'X' character.
N_CHAR                  equ 78  ; ASCII for 'N' character.
n_CHAR                  equ 110 ; ASCII for 'n' character.
g_CHAR                  equ 103 ; ASCII for 'g' character.
W_CHAR                  equ 87  ; ASCII for 'W' character.
NOTEC_AT_WORK           equ 1   ; Notec's instance is on.
ALIGNMENT_CONST         equ 16  ; ABI stack before call alignment constant.

; which_notec_to_wait_for equals -1 after a swap is done.
EXCHANGE_DONE           equ -1

section .bss

align 8

which_notec_to_wait_for resq N ; Used when W appears.
top_stack_number        resq N ; Used to store top stack numbers.

section .text

align 8
notec:
; Saving registers in order to suffice ABI.
  push    rbx
  push    rbp
  push    r12
  push    r13
  push    r14

  ; rsp will be saved in rbp
  mov     rbp, rsp ; Saving frame.
  mov     r13, rdi ; Saving rdi to ABI protected register.
  mov     r14, rsi ; Saving rsi to ABI protected register.

  ; Mechanism to prevent mistakes considering 'w' operation with notec number 0.
  mov     r8, which_notec_to_wait_for
  mov     [r8+r13*8], r13

  xor     rbx, rbx ; Number writing mode off.

read_data:
  xor     rdx, rdx
  mov     dl, byte [r14] ; Get one ASCIIZ character.
  test    dl, dl ; Check for \0.
  je      traversal_finished ; No more characters to read.

check_for_0_to_9_digit:
  cmp     dl, ZERO_CHAR
  jl      check_for_A_to_F_char ; Not a 0-9 char.
  cmp     dl, NINE_CHAR
  jg      check_for_A_to_F_char ; Not a 0-9 char.

  ; It is a 0-9 char.
  sub     dl, ZERO_CHAR ; Conversion into a digit.
  jmp     parse_number

check_for_A_to_F_char:
  cmp     dl, A_CHAR
  jl      check_for_a_to_f_char ; Not an A-F char.
  cmp     dl, F_CHAR
  jg      check_for_a_to_f_char ; Not an A-F char.

  ; It is an A-F char. Conversion into a 10-15 number.
  sub     dl, A_CHAR
  add     dl, DECIMAL_BASIS
  jmp     parse_number

check_for_a_to_f_char:
  cmp     dl, a_CHAR
  jl      check_equal_sign ; Not an a-f char.
  cmp     dl, f_CHAR
  jg      check_equal_sign ; Not an a-f char.

  ; It is an a-f char. Conversion into a 10-15 number.
  sub     dl, a_CHAR
  add     dl, DECIMAL_BASIS

parse_number:
  cmp     rbx, WRI_NUMBER_MODE_ON
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
  mov     rbx, WRI_NUMBER_MODE_ON ; Turn on writing number mode.
  jmp     parsing_character_finished

; Turns off writing number mode off.
check_equal_sign:
  mov     rbx, WRI_NUMBER_MODE_OFF ; Turn off writing number mode.
  cmp     dl, EQUAL_SIGN
  jne     check_plus_sign
  jmp     parsing_character_finished

; Sums two top stack elements.
check_plus_sign:
  cmp     dl, PLUS_SIGN
  jne     check_multiply_sign
  pop     r8 ; First argument.
  pop     r9 ; Second argument.
  add     r8, r9
  push    r8 ; Operation result.
  jmp     parsing_character_finished

; Multiplies two top stack elements.
check_multiply_sign:
  cmp     dl, MULTIPLY_SIGN
  jne     check_minus_sign
  pop     rax ; First argument.
  pop     r9 ; Second argument.
  mul     r9
  push    rax ; Operation result.
  jmp     parsing_character_finished

; Arithmetically negates the top stack element.
check_minus_sign:
  cmp     dl, MINUS_SIGN
  jne     check_and_sign
  pop     r8 ; Argument.
  neg     r8
  push    r8 ; Result of arithmetic negation.
  jmp     parsing_character_finished

; Bitwise and of two top stack elements.
check_and_sign:
  cmp     dl, AND_SIGN
  jne     check_or_sign
  pop     r8 ; First argument.
  pop     r9 ; Second argument.
  and     r8, r9
  push    r8 ; Operation result.
  jmp     parsing_character_finished

; Bitwise or of two top stack elements.
check_or_sign:
  cmp     dl, OR_SIGN
  jne     check_xor_sign
  pop     r8 ; First argument.
  pop     r9 ; Second argument.
  or      r8, r9
  push    r8 ; Operation result.
  jmp     parsing_character_finished

; Bitwise xor of two top stack elements.
check_xor_sign:
  cmp     dl, XOR_SIGN
  jne     check_not_sign
  pop     r8 ; First argument.
  pop     r9 ; Second argument.
  xor     r8, r9
  push    r8 ; Operation result.
  jmp     parsing_character_finished

; Bitwise not of the top stack element.
check_not_sign:
  cmp     dl, NOT_SIGN
  jne     check_Z_char
  pop     r8
  not     r8
  push    r8
  jmp     parsing_character_finished

; Pops top element from the stack.
check_Z_char:
  cmp     dl, Z_CHAR
  jne     check_Y_char
  pop     r8
  jmp     parsing_character_finished

; Pushes copy of the top element onto the stack.
check_Y_char:
  cmp     dl, Y_CHAR
  jne     check_X_char
  mov     r8, top_stack_number
  mov     r9, [r8+r13*8] ; Acquire top stack element.
  push    r9
  jmp     parsing_character_finished

; Swaps two top stack elements.
check_X_char:
  cmp     dl, X_CHAR
  jne     check_N_char
  pop     r8 ; First argument.
  pop     r9 ; Second argument.

  ; Perform swap.
  push    r8
  push    r9
  jmp     parsing_character_finished

; Pushes compilation parameter N onto the stack.
check_N_char:
  cmp     dl, N_CHAR
  jne     check_n_char
  mov     rax, N ; N is a compilation parameter.
  push    rax
  jmp     parsing_character_finished

; Pushes instance number of a notec onto the stack.
check_n_char:
  cmp     dl, n_CHAR
  jne     check_g_char
  push    r13 ; Instance number is stored in r13.
  jmp     parsing_character_finished

; Calls extern debug function.
check_g_char:
  cmp     dl, g_CHAR
  jne     check_W_char
  mov     rdi, r13 ; First argument of debug function.
  mov     r12, rsp ; Save stack pointer in an ABI protected register.
  mov     rsi, rsp ; Second argument of debug function.
  mov     rax, rsi ; Copy of rsi/rsp for division.
  xor     rdx, rdx
  mov     r9, ALIGNMENT_CONST
  div     r9
  cmp     dl, ZERO ; Check whether an alignment is needed.
  je      call_debug
  sub     rsp, STACK_CHUNK ; Aligning stack in order to suffice ABI.

call_debug:
  call    debug
  lea     rax, [rax*8] ; Get number of bytes.
  mov     rsp, r12 ; Get the pre-debug stack frame.
  add     rsp, rax ; Adjust frame according to the result of a debug call.
  jmp     parsing_character_finished

; Synchronization operation.
check_W_char:
  pop     rax ; Notec instance to wait for.
  pop     r9 ; Get number to swap.
  mov     r8, top_stack_number
  mov     [r8+r13*8], r9 ; Now r9 is at the top of the stack.
  mov     r8, which_notec_to_wait_for
  mov     [r8+r13*8], rax ; Notec is waiting for notec with rax number.
  cmp     r13, rax
  je      parsing_character_finished ; Undefined operation.
  jl      wait_for_notec_with_bigger_number ; Smaller notec.

; In order to synchronize only mov atomicity is used.
; Bigger notec means an instance with bigger number.

; Waiting for bigger notec to finally swap elements.
is_notec_with_smaller_number_waiting_for_me:
  mov     r8, which_notec_to_wait_for
  mov     r9, [r8+rax*8]
  cmp     r13, r9
  jne     is_notec_with_smaller_number_waiting_for_me

; The swap can be performed. It is performed by bigger notec.
exchange_stack_top_elements:
  mov     r8, top_stack_number

  ; Get top elements.
  mov     r10, [r8+r13*8] ; Bigger notec's top element.
  mov     r11, [r8+rax*8] ; Smaller notec's top element.

  ; Swap top elements.
  mov     [r8+rax*8], r10
  mov     [r8+r13*8], r11

  push    r11 ; Adjust top stack number of bigger notec.

  ; Signalizing the smaller notec that the swap had been performed.
  mov     r8, which_notec_to_wait_for
  mov     r9, EXCHANGE_DONE
  mov     [r8+rax*8], r9
  jmp     parsing_character_finished

; Wait performed by smaller notec.
wait_for_notec_with_bigger_number:
  mov     r8, which_notec_to_wait_for
  mov     rax, [r8+r13*8]
  cmp     rax, EXCHANGE_DONE ; Checking whether the swap has been performed.
  jne     wait_for_notec_with_bigger_number

  ; Adjust stack top of smaller notec.
  mov     r8, top_stack_number
  mov     rax, [r8+r13*8]
  push    rax

parsing_character_finished:
  inc     r14 ; Where to look for next character.
  pop     rax
  mov     r8, top_stack_number
  mov     [r8+r13*8], rax ; Update stack_top for this notec.
  push    rax
  jmp     read_data ; Continue reading input.

traversal_finished:
  pop     rax ; Obtain the returning value.
  mov     rsp, rbp ; Move to the correct frame.

; Recovering registers in order to suffice ABI.
recover_registers:
  mov     rsp, rbp ; Get the correct frame.
  pop     r14
  pop     r13
  pop     r12
  pop     rbp
  pop     rbx

  ret