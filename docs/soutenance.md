# Soutenance - Projet Assembleur x64 ESGI

Durée prévue : 15 minutes par groupe.

## 1. Présentation du sujet - 1 minute

Le projet porte sur la modification d'exécutables ELF64
sous Linux, avec une transformation PT_NOTE vers PT_LOAD
et une composante assembleur / réseau.

## 2. Comprendre le format ELF - 2 minutes

Expliquer :
- ELF Header : informations générales du fichier.
- Program Headers : description des segments.
- PT_NOTE : notes et métadonnées.
- PT_LOAD : segment chargé en mémoire.
- Offset : position dans le fichier.
- Adresse virtuelle : emplacement en mémoire.

## 3. Analyseur ELF - 2 minutes

Démonstration :

    make
    ./elf_info demo
    readelf -lW demo

Expliquer les contrôles de format et de structure.

## 4. Modification ELF - 4 minutes

Présentation de patch_note_lab.py.

Démonstration :

    nasm -f elf64 hello.asm -o hello.o
    ld -T layout_note_separe.ld hello.o -o hello_lab_note
    python3 patch_note_lab.py
    readelf -lW hello_lab_note
    readelf -lW hello_lab_patche
    ./hello_lab_patche

Résultats :
- Avant : 2 PT_LOAD et 1 PT_NOTE.
- Après : 3 PT_LOAD.
- Le programme affiche toujours son message.
- Le point d'entrée est conservé.

Préciser que le binaire de départ est spécialement préparé.

## 5. Difficulté technique - 2 minutes

Un premier laboratoire provoquait l'affichage
de 25 octets nuls.

Diagnostic avec strace et objdump.

Cause étudiée : conflit entre zones de chargement.
Correction : séparation et alignement des segments.

## 6. Assembleur et réseau - 2 minutes

Expliquer les syscalls Linux.

Présenter le serveur TCP de démonstration en C
et le test de communication Ubuntu WSL2 / Kali.

Ajouter la contribution assembleur de Miracle
uniquement après réception et validation de son code.

## 7. Bilan et questions - 2 minutes

Présenter :
- Fonctionnalités réalisées et testées.
- Contributions de chacun.
- Limites actuelles.
- Perspectives d'amélioration.

La démonstration ne constitue pas encore
un infecteur complet avec bind shell intégré.

## Questions possibles

Q : Pourquoi PT_NOTE vers PT_LOAD ?
R : PT_LOAD décrit une zone que Linux doit charger
en mémoire, contrairement à PT_NOTE.

Q : Pourquoi le programme affichait des zéros ?
R : Des segments partageaient une page mémoire,
ce qui perturbait les données chargées.

Q : Votre programme fonctionne-t-il sur tous les ELF ?
R : Non, la modification est limitée à un ELF
de laboratoire spécialement préparé.

Q : Quel est le rôle de Git ?
R : Suivre les modifications, conserver l'historique
et permettre le travail en binôme.
