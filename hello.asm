bits 64
global _start

section .data
    msg db "Bonjour depuis ASM x64 !", 10
    len equ $ - msg

section .text
_start:
    ; Afficher le message
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg]
    mov rdx, len
    syscall

    ; Terminer le programme
    mov rax, 60
    xor rdi, rdi
    syscall
