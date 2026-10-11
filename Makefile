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
