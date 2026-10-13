#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

printf '== Compilation de l outil C ==\n'
gcc -std=c11 -Wall -Wextra -Wpedantic -O2 -g elf_lab.c -o elf_lab

printf '== Creation du fichier de laboratoire ==\n'
nasm -f elf64 hello.asm -o "$tmp/hello.o"
ld -T layout_note_separe.ld "$tmp/hello.o" -o "$tmp/hello_lab_note"

printf '== Inspection avant ==\n'
./elf_lab inspect "$tmp/hello_lab_note" | tee "$tmp/before.txt"
grep -q 'Bilan : 2 PT_LOAD / 1 PT_NOTE' "$tmp/before.txt"

printf '== Transformation ==\n'
./elf_lab transform "$tmp/hello_lab_note" "$tmp/hello_lab_patche"

printf '== Inspection apres ==\n'
./elf_lab inspect "$tmp/hello_lab_patche" | tee "$tmp/after.txt"
grep -q 'Bilan : 3 PT_LOAD / 0 PT_NOTE' "$tmp/after.txt"

printf '== Le comportement original est conserve ==\n'
test "$("$tmp/hello_lab_note")" = 'Bonjour depuis ASM x64 !'
test "$("$tmp/hello_lab_patche")" = 'Bonjour depuis ASM x64 !'

printf '== Interdiction d ecraser la sortie ==\n'
if ./elf_lab transform "$tmp/hello_lab_note" "$tmp/hello_lab_patche" >"$tmp/refus.log" 2>&1; then
    echo 'ERREUR : le fichier existant a ete ecrase'; exit 1
fi

printf '== Rejet d un faux ELF ==\n'
printf 'pas un elf\n' >"$tmp/invalid"
if ./elf_lab transform "$tmp/invalid" "$tmp/invalid_output" >"$tmp/invalid.log" 2>&1; then
    echo 'ERREUR : le faux ELF a ete accepte'; exit 1
fi

printf '== Verifier que seuls p_type et p_align ont change ==\n'
python3 - "$tmp/hello_lab_note" "$tmp/hello_lab_patche" <<'PY'
import pathlib, struct, sys
original, patched = [pathlib.Path(x).read_bytes() for x in sys.argv[1:]]
assert len(original) == len(patched), 'taille modifiee'
phoff = struct.unpack_from('<Q', original, 32)[0]
phnum = struct.unpack_from('<H', original, 56)[0]
phentsize = struct.unpack_from('<H', original, 54)[0]
notes = [i for i in range(phnum) if struct.unpack_from('<I', original, phoff+i*phentsize)[0] == 4]
assert len(notes) == 1
pos = phoff + notes[0]*phentsize
allowed = set(range(pos, pos+4)) | set(range(pos+48, pos+56))
differences = {i for i, (a, b) in enumerate(zip(original, patched)) if a != b}
assert differences and differences <= allowed, f'modifications inattendues: {differences - allowed}'
assert struct.unpack_from('<Q', original, 24)[0] == struct.unpack_from('<Q', patched, 24)[0], 'point entree modifie'
print('Diff du fichier limite a la description du segment, point entree inchange')
PY

printf '\n7 VERIFICATIONS REUSSIES (ELF DE LABORATOIRE)\n'
