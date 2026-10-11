#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[1/3] Verification du programme original"
test "$(./hello_lab)" = "Bonjour depuis ASM x64 !"

echo "[2/3] Verification du conflit"
if cmp -s <(./hello_lab) <(./hello_lab_load); then
    echo "ERREUR : comportement inattendu"
    exit 1
fi

echo "[3/3] Verification de la correction"
cmp <(./hello_lab) <(./hello_lab_corrige)

echo "TOUS LES TESTS DE CHARGEMENT SONT PASSES"
