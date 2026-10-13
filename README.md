# Projet Assembleur x64 - ESGI

## Présentation

Projet d'étude des fichiers exécutables ELF64 sous Linux,
de leur chargement en mémoire et de l'assembleur x86-64.

## Travail réalisé

### Analyse des ELF
- Lecture des en-têtes ELF64.
- Identification des segments PT_LOAD et PT_NOTE.
- Affichage des permissions, offsets et adresses.
- Vérification de la structure des segments.

### Modification des ELF
- Création d'un ELF de laboratoire avec PT_NOTE.
- Modification directe de PT_NOTE vers PT_LOAD.
- Conservation du point d'entrée du programme.
- Vérification de son fonctionnement après modification.

### Assembleur x64
- Programme NASM utilisant les syscalls Linux.
- Etude des sections et segments mémoire.

### Réseau
- Serveur TCP de démonstration en C.
- Test de communication entre Ubuntu WSL2 et Kali Linux.
- Partie réseau en assembleur en cours de développement.

## Reproduire la démonstration ELF

Prérequis : GCC, Make, NASM, binutils et Python 3.

Compiler les outils :

    make

Exécuter les tests :

    make test
    make test-layout

Construire notre ELF de laboratoire :

    nasm -f elf64 hello.asm -o hello.o
    ld -T layout_note_separe.ld hello.o -o hello_lab_note

Modifier directement son en-tête :

    python3 patch_note_lab.py

Comparer les structures :

    readelf -lW hello_lab_note
    readelf -lW hello_lab_patche

Exécuter le programme modifié :

    ./hello_lab_patche

Résultat attendu :

    Bonjour depuis ASM x64 !


## Démonstration rapide pour la soutenance

Pour lancer une démonstration reproductible de l'ELF préparé, sous Ubuntu :

```bash
make demo-elf
```

Cette commande :
1. Compile `elf_lab.c` en exécutable `./elf_lab` si nécessaire.
2. Construit un programme de démonstration à partir de `hello.asm`.
3. Compare ses segments avant et après transformation avec `elf_lab` **et** `readelf`.
4. Exécute l'original et le programme modifié, puis compare leurs messages.

Tous les fichiers de travail de cette démonstration sont temporaires :
le script ne modifie pas les autres exécutables du dépôt.

Pour les sept tests du composant :

```bash
make test-elf-lab
```

**Portée :** seule la transformation PT_NOTE vers PT_LOAD de notre ELF préparé est démontrée. Aucun nouveau code machine n'est injecté, et aucun bind shell n'est intégré à ce fichier.

## Difficultés rencontrées

Lors des premières expériences, un conflit de chargement
entre segments provoquait l'affichage de 25 octets nuls.

Nous avons étudié le chargement mémoire et corrigé
l'organisation ainsi que l'alignement des segments.

## Limites actuelles

La modification ELF fonctionne sur un exécutable de
laboratoire spécialement préparé.

L'injection de code exécutable dans un ELF existant et
le bind shell demandé dans le sujet ne sont pas encore
validés.

## Documentation

- docs/etat_projet.md : réalisation technique et limites
- docs/lexique.md : vocabulaire
- docs/soutenance.md : préparation de la présentation

## Travail en équipe

Les contributions sont suivies avec Git et GitHub.

Chaque fonctionnalité doit être testée avant d'être
présentée comme fonctionnelle.
