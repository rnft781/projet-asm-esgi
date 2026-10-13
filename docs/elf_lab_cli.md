# ELF Lab — Outil d'analyse et de transformation ELF64

## Objectif

Développer et compiler notre propre utilitaire en C pour **inspecter** un exécutable Linux ELF64 et transformer **uniquement notre ELF de laboratoire** `hello_lab_note` de la forme `2 PT_LOAD + 1 PT_NOTE` en `3 PT_LOAD`.

Le script existant `patch_note_lab.py` fonctionne déjà ; cet outil fournit maintenant un **exécutable utilisable depuis le terminal**, avec arguments, validations et refus des écrasements.

## À quoi correspondent les commandes ?

- `gcc` : compilateur C, qui transforme `elf_lab.c` en exécutable Linux `elf_lab`.
- `nasm` : assembleur x64, qui convertit le fichier `hello.asm` en fichier objet.
- `ld` : éditeur de liens, qui construit l'exécutable ELF avec la disposition de segments décrite dans `layout_note_separe.ld`.
- `readelf` : outil qui affiche les en-têtes ELF sans lancer le programme.
- `./elf_lab inspect` : outil que nous avons écrit qui inspecte les segments du fichier.
- `./elf_lab transform` : outil que nous avons écrit qui transforme la description de la note prévue pour le laboratoire.

## Démonstration rapide

Depuis `~/projet-asm` :

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic -O2 elf_lab.c -o elf_lab
nasm -f elf64 hello.asm -o hello.o
ld -T layout_note_separe.ld hello.o -o hello_lab_note
./elf_lab inspect hello_lab_note
./elf_lab transform hello_lab_note hello_lab_patche_c
./elf_lab inspect hello_lab_patche_c
readelf -lW hello_lab_patche_c
./hello_lab_patche_c
```

Résultat attendu : `2 PT_LOAD + 1 PT_NOTE` avant, `3 PT_LOAD` après, et `Bonjour depuis ASM x64 !` à l'exécution des deux fichiers.

**Important :** `elf_lab transform` **refuse d'écraser** `hello_lab_patche_c` s'il existe. Choisis un nouveau nom ou supprime explicitement la sortie de ton propre laboratoire si tu veux refaire la démo.

## Vérifications

```bash
bash tests/test_elf_lab_cli.sh
```

Le test compile le programme, construit une cible isolée dans un dossier temporaire, transforme celle-ci, compare les résultats et vérifie le refus d'écrasement ainsi que le rejet de fichiers incompatibles.

## Limite honnête du résultat

Cet outil **n'est pas un infecteur complet** : il n'ajoute aucun code machine, ne change pas le point d'entrée, n'ouvre pas de port et n'intègre pas le code réseau de votre binôme. Il ne fonctionne que sur la note identifiable du fichier de laboratoire construit avec `layout_note_separe.ld`. La conversion `PT_NOTE → PT_LOAD` seule ne suffit pas à créer un comportement supplémentaire.

## Pour la présentation

« Nous avons créé un utilitaire Linux qui examine la table des segments ELF64, valide notre binaire de laboratoire et transforme le segment `PT_NOTE` en `PT_LOAD` sans modifier le point d'entrée ni les octets du programme d'origine. Nous comparons les en-têtes avant et après et vérifions que l'exécutable fonctionne encore. »
