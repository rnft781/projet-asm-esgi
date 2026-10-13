#!/usr/bin/env bash
# Tests NEGATIFS uniquement sur des copies temporaires de notre ELF pédagogique.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

printf '%s\n' '== Creation de l ELF de reference =='
nasm -f elf64 hello.asm -o "$tmp/hello.o"
ld -T layout_note_separe.ld "$tmp/hello.o" -o "$tmp/hello_lab_note"

./elf_lab inspect "$tmp/hello_lab_note" > "$tmp/valid.log"
grep -q 'Bilan : 2 PT_LOAD / 1 PT_NOTE' "$tmp/valid.log"
printf '%s\n' 'ELF sain : accepte'

python3 - "$tmp/hello_lab_note" "$tmp" <<'PY'
import pathlib
import struct
import sys

original = bytearray(pathlib.Path(sys.argv[1]).read_bytes())
out = pathlib.Path(sys.argv[2])
phoff = struct.unpack_from("<Q", original, 32)[0]
phentsize = struct.unpack_from("<H", original, 54)[0]
phnum = struct.unpack_from("<H", original, 56)[0]

loads = [
    phoff + i * phentsize
    for i in range(phnum)
    if struct.unpack_from("<I", original, phoff + i * phentsize)[0] == 1
]
assert len(loads) == 2
first = loads[0]
memsz = struct.unpack_from("<Q", original, first + 40)[0]

def variant(name, *edits):
    data = bytearray(original)
    for fmt, pos, value in edits:
        struct.pack_into(fmt, data, pos, value)
    (out / name).write_bytes(data)

variant("bad_segment_offset", ("<Q", first + 8, len(original) + 1))
variant("bad_file_size", ("<Q", first + 32, memsz + 1))
variant("bad_alignment", ("<Q", first + 48, 3))
variant("bad_mapping_congruence", ("<Q", first + 16,
                                  struct.unpack_from("<Q", original, first + 16)[0] + 1))
variant("bad_entry", ("<Q", 24, 0x700000))
variant("bad_virtual_overflow", ("<Q", first + 48, 1),
        ("<Q", first + 16, (1 << 64) - 2))
variant("bad_program_header_alignment", ("<Q", 32, 65))
variant("bad_program_header_boundary", ("<Q", 32, len(original) - 1))
PY

printf '%s\n' '== Huit fichiers malformes doivent etre rejetes =='
cases=(
    bad_segment_offset bad_file_size bad_alignment
    bad_mapping_congruence bad_entry bad_virtual_overflow
    bad_program_header_alignment bad_program_header_boundary
)
for case in "${cases[@]}"; do
    if ./elf_lab inspect "$tmp/$case" > "$tmp/$case.log" 2>&1; then
        printf 'ECHEC : %s a ete accepte\n' "$case" >&2
        exit 1
    fi
    printf 'OK %-34s %s\n' "$case" "$(head -n 1 "$tmp/$case.log")"
done

printf '%s\n' '== Un fichier malforme ne doit produire aucune sortie =='
if ./elf_lab transform "$tmp/bad_alignment" "$tmp/sortie_interdite" > "$tmp/rejet.log" 2>&1; then
    echo 'ECHEC : la transformation aurait du etre refusee' >&2
    exit 1
fi
test ! -e "$tmp/sortie_interdite"

printf '\nVALIDATION OK : 1 ELF sain accepte, 8 ELF malformes rejetes, 0 sortie invalide.\n'
