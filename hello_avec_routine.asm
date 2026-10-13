BITS 64
global _start

section .rodata
    message_extra db "Routine pedagogique executee !", 10
    taille_extra equ $ - message_extra

    message_original db "Bonjour depuis ASM x64 !", 10
    taille_original equ $ - message_original

section .text

_start:
    call routine_extra

    ; Programme original
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel message_original]
    mov rdx, taille_original
    syscall

    ; Terminer
    mov rax, 60
    xor rdi, rdi
    syscall

routine_extra:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel message_extra]
    mov rdx, taille_extra
    syscall
    ret
