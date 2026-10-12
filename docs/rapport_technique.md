# Rapport technique — Projet Assembleur x64 ESGI

## 1. Objectif

Le sujet porte sur la manipulation du format ELF64 sous Linux,
la transformation d'un segment PT_NOTE en PT_LOAD et
l'exécution de code assembleur dans un contexte réseau.

Notre travail actuel comprend un laboratoire d'analyse ELF,
une modification d'en-tête sur un binaire préparé,
et une démonstration TCP indépendante.

## 2. Environnement

- Linux Ubuntu sous WSL2
- Architecture x86-64
- Langage C
- Assembleur NASM
- Python 3
- GCC, ld, Make
- readelf, objdump et strace
- Git et GitHub
- Kali Linux sous VirtualBox pour les essais réseau

## 3. Analyse des exécutables ELF

Le programme elf_info.c ouvre un fichier en lecture seule.

Il vérifie son format, lit l'en-tête ELF64 et parcourt
la table des segments.

Pour chaque segment, il affiche :
- Son type
- Son offset dans le fichier
- Son adresse virtuelle
- Ses tailles fichier et mémoire
- Ses permissions
- Son alignement

Il vérifie également certaines incohérences,
notamment les limites et l'alignement des segments.

Le programme elf_check.c ajoute plusieurs contrôles
sur les segments PT_LOAD et le point d'entrée.

Ces vérifications ne garantissent pas à elles seules
qu'un exécutable fonctionnera correctement.

## 4. Assembleur x64

Le programme hello.asm utilise directement les
appels système Linux.

L'appel write affiche le message :

    Bonjour depuis ASM x64 !

L'appel exit termine le programme.

L'assemblage est effectué avec NASM et la création
de l'exécutable avec ld.

## 5. Modification directe du fichier ELF

Le fichier layout_note_separe.ld sert à construire
un ELF de laboratoire contenant un segment PT_NOTE
séparé des deux segments PT_LOAD.

Le script patch_note_lab.py ouvre cet exécutable
et charge ses octets dans un tableau modifiable.

Il contrôle notamment :
- La signature ELF
- Le format ELF64 little-endian
- La présence d'une table de segments valide
- La présence d'un unique PT_NOTE en lecture seule
- L'alignement du segment concerné
- Les limites du fichier
- L'absence de conflit avec les pages des PT_LOAD existants

Il modifie ensuite deux champs du Program Header :
- p_type : PT_NOTE devient PT_LOAD
- p_align : alignement fixé à 4096

Le script ne change pas le point d'entrée et
n'ajoute aucune instruction machine.

## 6. Démonstration observée

Avant modification :
- 2 PT_LOAD
- 1 PT_NOTE

Après modification :
- 3 PT_LOAD
- 0 PT_NOTE

L'exécution du fichier modifié affiche toujours :

    Bonjour depuis ASM x64 !

La transformation est limitée à notre ELF spécialement
préparé. Elle n'est pas généralisée à tous les binaires.

## 7. Difficulté rencontrée

Dans une expérience précédente, deux segments utilisaient
une même page mémoire.

À l'exécution, le programme envoyait 25 octets nuls
au lieu du message attendu.

Nous avons comparé :
- Les sorties de strace
- Les octets affichés avec od
- Les données des sections avec objdump
- Les segments déclarés avec readelf

La séparation et l'alignement des zones de chargement
ont permis de retrouver le fonctionnement attendu.

## 8. Réseau

Le programme serveur_test.c implémente une communication
TCP simple avec socket, bind, listen, accept et write.

Il transmet un message fixe au client.

Le code actuel écoute sur 127.0.0.1:9090.

Un essai de communication depuis Kali a été réalisé.
La configuration de relais réseau devra être précisée.

La partie assembleur réseau du binôme sera documentée
après réception et vérification de son code.

## 9. Vérifications

Les commandes suivantes permettent de tester
les outils existants :

    make test
    make test-layout

La modification directe se démontre avec :

    nasm -f elf64 hello.asm -o hello.o
    ld -T layout_note_separe.ld hello.o -o hello_lab_note
    python3 patch_note_lab.py
    readelf -lW hello_lab_note
    readelf -lW hello_lab_patche
    ./hello_lab_patche

## 10. Limites et bilan

La transformation PT_NOTE vers PT_LOAD est fonctionnelle
sur le binaire préparé pour le laboratoire.

En revanche, elle n'implémente pas un infecteur générique,
n'injecte pas de nouveau code exécutable
et ne crée pas de bind shell.

Le travail réalisé permet de comprendre les en-têtes ELF,
les contraintes d'alignement, les appels système Linux
et les outils de diagnostic.

Ce rapport sera complété après intégration
des contributions vérifiées du binôme.

## 11. Contribution assembleur du binôme

Le dépôt commun contient également :
- bind_shell.asm : source assembleur x86-64.
- bind_shell.bin : représentation binaire.
- shellcode.h : tableau d'octets utilisable en C.

Le code source comprend des appels système liés
aux sockets TCP et au lancement d'un shell.

Etat de validation :
- Sources présentes dans le dépôt : oui.
- Binaire présent : oui.
- Test en VM : résultat à documenter.
- Intégration à l'ELF modifié : non confirmée.

Ces éléments ne doivent pas être présentés comme
fonctionnels avant vérification par le binôme.
