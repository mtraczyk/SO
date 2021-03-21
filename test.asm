section .data
    texta db "Argument(s): ",0
    textb1 db "Argument #",0
    textb2 db ": ",0
    newline db 10,0

section .bss
    argc resb 8
    argPos resb 8

%macro printVal 1
    mov rax, %1
%%printRAX:
    mov rcx, digitSpace
;   mov rbx, 10
;   mov [rcx], rbx
;   inc rcx
    mov [digitSpacePos], rcx

%%printRAXLoop:
    mov rdx, 0
    mov rbx, 10
    div rbx
    push rax
    add rdx, 48

    mov rcx, [digitSpacePos]
    mov [rcx], dl
    inc rcx
    mov [digitSpacePos], rcx

    pop rax
    cmp rax, 0
    jne %%printRAXLoop

%%printRAXLoop2:
    mov rcx, [digitSpacePos]

    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, 1
    syscall

    mov rcx, [digitSpacePos]
    dec rcx
    mov [digitSpacePos], rcx

    cmp rcx, digitSpace
    jge %%printRAXLoop2

%endmacro

global _start

section .text

_start:
    mov rdi [rsp + 8]
    call atoi
    printVal rax

exit:
    mov     eax, SYS_EXIT
    xor     edi, edi        ; kod powrotu 0
    syscall

atoi:
    mov rax, 0              ; Set initial total to 0

convert:
    movzx rsi, byte [rdi]   ; Get the current character
    test rsi, rsi           ; Check for \0
    je done

    cmp rsi, 48             ; Anything less than 0 is invalid
    jl error

    cmp rsi, 57             ; Anything greater than 9 is invalid
    jg error

    sub rsi, 48             ; Convert from ASCII to decimal
    imul rax, 10            ; Multiply total by 10
    add rax, rsi            ; Add current digit to total

    inc rdi                 ; Get the address of the next character
    jmp convert

error:
    mov rax, -1             ; Return -1 on error

done:
    ret                     ; Return total or error code