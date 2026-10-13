# ESGI — laboratoire ELF64 x86-64
CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -O2 -g

.PHONY: all test demo-elf test-elf-lab test-elf-hardening clean
all: elf_lab

# Outil C de verification des en-tetes ELF de laboratoire
elf_lab: elf_lab.c
	$(CC) $(CFLAGS) $< -o $@

# ELF de reference avec deux PT_LOAD et un PT_NOTE
hello_lab_note: hello.asm layout_note_separe.ld
	nasm -f elf64 hello.asm -o hello.o
	ld -T layout_note_separe.ld hello.o -o hello_lab_note

# Tests confines aux fichiers ELF prepares pour le laboratoire
demo-elf: elf_lab
	bash scripts/demo_elf.sh

test-elf-lab:
	bash tests/test_elf_lab_cli.sh

test-elf-hardening: elf_lab
	bash tests/test_elf_hardening.sh

test: demo-elf test-elf-lab test-elf-hardening

clean:
	rm -f elf_lab hello.o hello_lab_note
