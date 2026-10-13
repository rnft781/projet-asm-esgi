CC = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -O2 -g

.PHONY: all test clean
all: demo elf_info

demo: demo.c
	$(CC) $(CFLAGS) $< -o $@

elf_info: elf_info.c
	$(CC) $(CFLAGS) $< -o $@

test: all
	bash tests/test_elf.sh

clean:
	rm -f demo elf_info

# Construction du programme ASM personnalise
hello_lab: hello.asm layout.ld
	nasm -f elf64 hello.asm -o hello.o
	ld -T layout.ld hello.o -o hello_lab

.PHONY: test-lab
test-lab: hello_lab elf_info
	./hello_lab
	./elf_info hello_lab
	readelf -n hello_lab

hello_lab_load: hello.asm layout_load.ld
	nasm -f elf64 hello.asm -o hello.o
	ld -T layout_load.ld hello.o -o hello_lab_load

hello_lab_corrige: hello.asm layout_corrige.ld
	nasm -f elf64 hello.asm -o hello.o
	ld -T layout_corrige.ld hello.o -o hello_lab_corrige

.PHONY: test-layout
test-layout: hello_lab hello_lab_load hello_lab_corrige
	bash tests/test_layout.sh

# Outil ELF en C et démonstration reproductible pour la soutenance.
elf_lab: elf_lab.c
	$(CC) $(CFLAGS) $< -o $@

.PHONY: demo-elf test-elf-lab test-elf-hardening
demo-elf: elf_lab
	bash scripts/demo_elf.sh

test-elf-lab:
	bash tests/test_elf_lab_cli.sh

# Verifications additionnelles sur des ELF volontairement corrompus.
test-elf-hardening: elf_lab
	bash tests/test_elf_hardening.sh
