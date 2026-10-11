# Projet assembleur x64 — base d'analyse ELF

## Ce qui fonctionne aujourd'hui
- `demo.c` : programme C de demonstration compile en fichier ELF.
- `elf_info.c` : analyseur **en lecture seule** des en-tetes ELF64 x86-64 et segments.
- `Makefile` : commandes pour compiler et tester.
- `tests/test_elf.sh` : verifications automatiques sur un ELF, `/bin/ls`, un fichier texte.

**Etat du projet :** l'analyseur fonctionne, mais **ce n'est pas encore l'infecteur ELF demande ni le bind shell**. L'outil n'ecrit jamais dans le binaire examine.

## Utilisation
```bash
make
./elf_info demo
./elf_info /bin/ls
make test
```

## Comment le programme fonctionne
1. `open` ouvre le fichier **en lecture seule**.
2. `fstat` recupere sa taille.
3. `pread` lit son en-tete ELF (`Elf64_Ehdr`).
4. On verifie la signature ELF, l'architecture et la position de la table de segments.
5. On lit chaque `Elf64_Phdr` (description d'un segment) et on affiche : type, offset, adresse, taille, permissions et alignement.
6. On verifie quelques incoherences, puis on ferme le fichier.

Un *offset* est une position en octets **dans le fichier** ; une adresse virtuelle est une position **en memoire** apres chargement (pour PIE, relative a une base de chargement).

`PT_NOTE` transporte des notes/metadonnees. `PT_LOAD` designe une region du fichier a charger en memoire. Le simple changement de nom/type d'un segment ne suffit pas a rendre du code executable.

## Limites actuelles
- ELF64 little-endian x86-64 uniquement.
- Cas `PN_XNUM` (nombre de segments etendu) non pris en charge.
- Lecture/analyse uniquement, aucune modification des executables.

## Historique et rendu
```bash
git add elf_info.c Makefile README.md tests/test_elf.sh
git commit -m "Ajout de l'analyse ELF detaillee et des tests"
# Pour preparer un fichier de depot une fois le travail termine :
git bundle create projet-asm.bundle --all
git bundle verify projet-asm.bundle
```

Le fichier `.bundle` n'est pas a considerer comme un rendu complet tant que le sujet technique n'est pas realise. Date dans le syllabus MyGES : **13 octobre 2026 a 23h59**. Soutenance : **15 minutes par groupe**. Verifier directement avec l'enseignant les regles sur la taille du groupe.
