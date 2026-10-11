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
