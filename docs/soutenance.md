# Preparation de la soutenance (15 minutes par groupe)

> Ce document sert de plan de presentation pour ce qui a effectivement ete realise. Ne pas annoncer l'infecteur ou le bind shell comme fonctionnels s'ils ne le sont pas.

## Plan de presentation possible
1. 1 min — Sujet et objectifs (ELF, PT_NOTE, PT_LOAD).
2. 3 min — Format ELF et difference entre code source et executable.
3. 4 min — Demonstration de l'analyseur : `./elf_info demo`, comparaison avec `readelf -lW demo`.
4. 3 min — Explication des controles (signature ELF, tailles et positions, permissions).
5. 2 min — Historique Git, tests et limites.
6. 2 min — Questions.

## Questions / reponses courtes
- **Qu'est-ce qu'ELF ?** Un format de fichiers executables et de bibliotheques sur Linux.
- **Qu'est-ce qu'un offset ?** Une position mesuree en octets depuis le debut du fichier.
- **A quoi sert `PT_LOAD` ?** Il decrit une zone que le chargeur doit placer en memoire.
- **A quoi sert `PT_NOTE` ?** Il contient des notes/metadonnees relatives au binaire.
- **Quel est le role de GCC ?** Compiler le C en executable machine, avec l'edition des liens.
- **Que fait `make test` ?** Il compile puis execute des tests automatises du lecteur ELF.
- **Pourquoi ne pas travailler sur `/bin/ls` en ecriture ?** C'est un programme du systeme ; l'analyseur n'y fait que des lectures.
- **Que signifie `R-X` ?** Lisible et executable, non inscriptible selon les flags du segment.
