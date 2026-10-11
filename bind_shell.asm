bits 64
global _start

section .text
_start:
    ; création socket
    ; Assemble this Linux x86-64 syscall code in 64-bit mode.
    mov rax, 41          ; sys_socket
    mov rdi, 2          ; famille : AF_INET (ipv4)
    mov rsi, 1          ; type : SOCK_STREAM (TCP)
    xor rdx, rdx        ; protocole (ip/tcp)
    syscall

    mov rdi, rax        ; Sauvegarder descripteur sockfd dans rdi
