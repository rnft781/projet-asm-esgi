# Projet ESGI — Assembleur x86-64 / ELF PT_NOTE → PT_LOAD

## Objectif
Etudier un executable ELF64 sous Linux, ses segments `PT_NOTE` et `PT_LOAD`, et l'execution de routines assembleur. Le travail comprend un prototype de modification ELF et une contribution reseau distincte.

## Par ou commencer ?
| Fichier | Role |
| --- | --- |
| `infecteur.asm` | Prototype NASM de modification d'un ELF de laboratoire avec execution d'un stager, puis retour au programme initial |
| `bind_shell.asm` | Contribution reseau en assembleur du binome |
| `hello.asm` | Source assembleur du programme cobaye « Bonjour depuis ASM x64 ! » |
| `layout_note_separe.ld` | Construction d'un ELF de test avec 2 PT_LOAD et 1 PT_NOTE |
| `elf_lab.c` | Petit outil auxiliaire en C pour examiner/transformer les metadonnees du fichier de test |
| `Makefile`, `scripts/`, `tests/` | Demonstration reproductible et controles |
| `docs/` | Lexique et preparation de la soutenance |

`bind_shell.bin` et `shellcode.h` conservent les octets fournis pour la partie assembleur reseau ; ils ne sont pas integres au prototype ELF valide.

## Compilation et demonstration sur Linux x86-64
Prerequis : GCC, Make, NASM, binutils (`ld` et `readelf`), Bash et Python 3.

Depuis la racine du depot :

```bash
make
make demo-elf
make test
```

Pour creer explicitement l'ELF de reference : `make hello_lab_note`.

`make test` enchaine la demonstration, les 7 tests du composant ELF et les tests de rejet des fichiers incorrects.

## Resultats constates sur Ubuntu WSL2 le 13 octobre 2026
- Demonstration de transformation d'un ELF prepare : **2 PT_LOAD / 1 PT_NOTE** avant, **3 PT_LOAD / 0 PT_NOTE** apres.
- Le programme original et le fichier transforme affichent tous deux `Bonjour depuis ASM x64 !`.
- **7 verifications** de l'outil de laboratoire reussies.
- **8 fichiers ELF malformes rejetes** sans sortie invalide dans le cas teste.
- Les anciens tests de structure de segments (`test-layout`) et l'analyseur `elf_info.c` ont ete utilises durant le developpement ; ils restent consultables dans l'historique Git mais ne font pas partie de cette version epuree.

L'avertissement possible `allocated section '.note.projet' not in segment` provient de notre agencement pedagogique des segments ; les tests precedemment executes sont passes.

## Prototype en assembleur : verification distincte
Sur une copie d'ELF compatible creee pour le laboratoire, un essai precedent de `infecteur.asm` sous Ubuntu WSL2 a donne :

```text
[stager]
Bonjour depuis ASM x64 !
code retour : 0
```

Ce comportement illustre l'execution d'une routine supplementaire, suivie du programme initial, **sur cet echantillon seulement**. Les cibles `make` ci-dessus ne rejouent pas ce test.

## Contribution reseau et limites
- `bind_shell.asm` : compilation NASM + `ld` validee dans une VM Kali, executable identifie comme ELF64 x86-64.
- Communication Windows-Kali testee avec Netcat sur le port **9090** : connexion TCP reussie. Ce test reseau n'est **pas** un test fonctionnel du bind shell.
- L'execution complete du bind shell et son integration au prototype ELF **ne sont pas validees**.
- La compatibilite du prototype ELF avec des executables arbitraires **n'est pas etablie**.

Les fichiers sources sont suivis par Git. Les binaires compiles ne sont pas requis dans le depot. Les essais precedents et leurs commits restent accessibles dans l'historique du Git bundle.
