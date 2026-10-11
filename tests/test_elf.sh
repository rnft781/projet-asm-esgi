#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "[1/4] Test de demo"
./elf_info demo > /tmp/esgi_elf_demo_$$.txt
cat /tmp/esgi_elf_demo_$$.txt

echo "[2/4] Comparaison avec readelf"
attendu=$(readelf -lW demo | awk '$1 == "LOAD" {n++} END {print n+0}')
obtenu=$(awk '$2 == "PT_LOAD" {n++} END {print n+0}' /tmp/esgi_elf_demo_$$.txt)
if [[ "$attendu" != "$obtenu" ]]; then
  echo "ECHEC : attendus=$attendu, obtenus=$obtenu" >&2
  rm -f /tmp/esgi_elf_demo_$$.txt
  exit 1
fi
rm -f /tmp/esgi_elf_demo_$$.txt

echo "[3/4] Test sur /bin/ls"
./elf_info /bin/ls >/dev/null

echo "[4/4] Refus d'un fichier texte"
if ./elf_info /etc/hosts >/dev/null 2>&1; then
  echo "ECHEC : fichier non ELF accepte" >&2
  exit 1
fi

echo "TOUS LES TESTS SONT PASSES"
