# Projet ASM ESGI - Etat de la réalisation

## Objectif du laboratoire

Etudier la structure des exécutables ELF64 x86-64,
les segments PT_NOTE et PT_LOAD, ainsi que leur
chargement par Linux.

## Fonctionnalités réalisées

- Analyse des en-têtes ELF64.
- Vérification des segments PT_LOAD.
- Programme assembleur x64 utilisant les syscalls Linux.
- Création d'un ELF personnalisé avec PT_NOTE.
- Etude d'un conflit de chargement mémoire.
- Correction de l'organisation et de l'alignement.
- Modification directe du type PT_NOTE vers PT_LOAD
  dans un exécutable de laboratoire déjà compilé.
- Tests automatisés et historique Git.

## Reproduire la modification directe

Depuis la racine du dépôt :

    nasm -f elf64 hello.asm -o hello.o
    ld -T layout_note_separe.ld hello.o -o hello_lab_note
    python3 patch_note_lab.py
    readelf -lW hello_lab_note
    readelf -lW hello_lab_patche
    ./hello_lab_patche

Le script modifie uniquement un ELF de laboratoire
spécifiquement préparé. Il conserve le point d'entrée.

## Résultat observé

Avant : deux PT_LOAD et un PT_NOTE.
Après : trois PT_LOAD.
Le programme affiche toujours :

    Bonjour depuis ASM x64 !

## Limites

Il ne s'agit pas d'un infecteur ELF complet.
Le programme n'injecte pas de code exécutable.
Il ne réalise pas de bind shell ni d'accès distant.

## Tests complémentaires

    make test
    make test-layout
