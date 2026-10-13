#!/usr/bin/env bash
# Démonstration pédagogique : transformation d'un ELF créé pour le laboratoire.
# Aucun code ajouté, aucun shell réseau et aucun ELF extérieur au projet.
set -euo pipefail

cd "$(dirname "$0")/.."

for cmd in nasm ld readelf; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'ERREUR : commande manquante : %s\n' "$cmd" >&2
        exit 1
    fi
done

if [ ! -x ./elf_lab ]; then
    echo 'ERREUR : elf_lab manquant. Lancez make elf_lab.' >&2
    exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

printf '\n===== 1. CONSTRUCTION DE NOTRE ELF =====\n'
nasm -f elf64 hello.asm -o "$tmp/hello.o"
ld -T layout_note_separe.ld "$tmp/hello.o" -o "$tmp/hello_original"

printf '\n===== 2. AVANT MODIFICATION =====\n'
./elf_lab inspect "$tmp/hello_original"
printf '\nLecture indépendante avec readelf :\n'
readelf -lW "$tmp/hello_original" | grep -E '^[[:space:]]*(LOAD|NOTE)[[:space:]]'

printf '\n===== 3. TRANSFORMATION DU FICHIER =====\n'
./elf_lab transform "$tmp/hello_original" "$tmp/hello_modifie"

printf '\n===== 4. APRÈS MODIFICATION =====\n'
./elf_lab inspect "$tmp/hello_modifie"
printf '\nLecture indépendante avec readelf :\n'
readelf -lW "$tmp/hello_modifie" | grep -E '^[[:space:]]*(LOAD|NOTE)[[:space:]]'

printf '\n===== 5. COMPORTEMENT DU PROGRAMME =====\n'
original_output=$("$tmp/hello_original")
modified_output=$("$tmp/hello_modifie")
printf 'Original : %s\n' "$original_output"
printf 'Modifié  : %s\n' "$modified_output"
if [ "$original_output" != "$modified_output" ]; then
    echo 'ÉCHEC : comportement différent' >&2
    exit 1
fi
if [ "$modified_output" != 'Bonjour depuis ASM x64 !' ]; then
    echo 'ÉCHEC : sortie inattendue' >&2
    exit 1
fi

printf '\nDÉMONSTRATION RÉUSSIE : ELF de laboratoire modifié et toujours exécutable.\n'
printf 'Limite : aucun nouveau code exécuté, aucun bind shell intégré.\n'
