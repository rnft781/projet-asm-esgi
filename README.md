# Projet ASM x86-64 — ELF PT_NOTE vers PT_LOAD

## Objectif
Étudier le format ELF64 sous Linux et la modification des segments d'un exécutable. Le travail comporte un prototype en assembleur autour de PT_NOTE → PT_LOAD et une étude des appels système réseau.

## Fichiers principaux
- `infecteur.asm` : prototype assembleur x86-64. Sur un exécutable ELF de laboratoire compatible, il ajoute une petite routine (« stager »), adapte les métadonnées ELF et prévoit le retour au point d'entrée original.
- `bind_shell.asm` : contribution réseau en assembleur, distincte du prototype ELF.
- `hello.asm` : code source du programme cobaye qui affiche « Bonjour depuis ASM x64 ! ».
- `layout_note_separe.ld` : script d'édition des liens pour fabriquer un ELF de laboratoire avec 2 PT_LOAD et 1 PT_NOTE.
- `elf_lab.c` : outil auxiliaire en C pour inspecter et transformer les métadonnées de cet ELF préparé.
- `Makefile`, `scripts/`, `tests/` : automatisation des démonstrations et vérifications.

Les fichiers `.asm` sont des sources ; les exécutables et les fichiers objets se génèrent lors de la compilation et ne sont pas nécessairement présents dans le dépôt.

## Reproduire les tests ELF

Prérequis : Linux x86-64, GCC, Make, NASM, `ld`, `readelf`, Bash et Python 3.

Depuis la racine du dépôt :

```bash
make test
make test-layout
make demo-elf
make test-elf-lab
make test-elf-hardening
```

### Résultats constatés le 13 octobre 2026 sur Ubuntu WSL2
- `make test` : succès (analyse des ELF et comparaison avec `readelf`).
- `make test-layout` : succès (3 étapes).
- `make demo-elf` : succès. L'ELF de laboratoire passe de **2 PT_LOAD + 1 PT_NOTE** à **3 PT_LOAD + 0 PT_NOTE** ; le programme original et le fichier transformé affichent tous deux « Bonjour depuis ASM x64 ! ».
- `make test-elf-lab` : **7 vérifications réussies**.
- `make test-elf-hardening` : un ELF sain accepté, **8 variantes malformées rejetées**, aucune sortie créée lors du refus testé.

Le linker peut afficher l'avertissement `allocated section '.note.projet' not in segment` lors de la génération de notre ELF expérimental ; les démonstrations ci-dessus se sont néanmoins terminées avec succès.

## Prototype ASM — résultat distinct

Lors d'un essai précédent sur une **copie** de notre ELF de laboratoire sous Ubuntu WSL2, le prototype `infecteur.asm` a affiché :

```text
[stager]
Bonjour depuis ASM x64 !
```

Le code retour était `0`. Cela illustre l'exécution d'une routine supplémentaire suivie du programme d'origine **sur cet échantillon précis**. Les cinq commandes `make` ci-dessus ne rejouent **pas** ce test du prototype ASM.

## Partie réseau et limites

- `bind_shell.asm` a été assemblé avec NASM et lié avec `ld` dans une VM Kali ; son format ELF64 x86-64 a été contrôlé avec `file` et `readelf`.
- La communication **Windows ↔ Kali** sur un réseau privé hôte a été vérifiée avec Netcat sur le **port 9090** (`TcpTestSucceeded : True`). Ce test concerne Netcat, **pas le bind shell**.
- Le fonctionnement complet du bind shell et son intégration au prototype ELF **ne sont pas validés**.
- Le prototype ELF ne doit pas être présenté comme compatible avec tous les exécutables Linux : il a été testé sur un ELF préparé pour le laboratoire.

## Documentation complémentaire

Consulter `docs/lexique.md`, `docs/rapport_technique.md` et `docs/soutenance.md`. Certaines notes retracent des étapes expérimentales antérieures ; le présent README distingue les vérifications récentes de celles qui restent à réaliser.

Le dépôt conserve l'historique Git et les contributions du binôme.
