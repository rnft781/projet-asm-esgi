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

    xor rax, rax        
    push rax            ; Remplir sockaddr_in avec zéros (8 octets)
    mov dword [rsp-4], 0x115c0002 ; sin_port = 4444
    sub, rsp, 4
    sub rsp, 4 push word 0 ; sin_addr = INADDR_ANY (0.0.0.0) 
    mov rax, 49 ; Syscall #49 = sys_bind 
    mov rsi, rsp ; Pointe vers la structure sockaddr sur la pile 
    mov rdx, 16 ; Taille de la structure (16 octets) 
    syscall