# Lexique du projet ELF

- **Code source** : instructions lisibles par les developpeurs, par exemple `demo.c`.
- **Compilateur (GCC)** : outil qui traduit le C en code machine executable, avec les etapes d'assemblage et d'edition de liens.
- **ELF** : format de fichier d'executable ou de bibliotheque utilise par Linux.
- **En-tete ELF (`Elf64_Ehdr`)** : fiche d'identite du fichier.
- **Program header (`Elf64_Phdr`)** : description d'un segment pour le chargeur Linux.
- **Segment** : zone du fichier associee a un usage lors du chargement.
- **PT_NOTE** : type de segment contenant des notes et metadonnees.
- **PT_LOAD** : type de segment dont les donnees doivent etre chargees en memoire.
- **Offset** : position d'une information a l'interieur du fichier.
- **Adresse virtuelle** : emplacement dans l'espace memoire du processus.
- **Permissions R/W/X** : read (lecture), write (ecriture), execute (execution).
- **Point d'entree** : adresse a partir de laquelle commence l'execution du programme.
- **Shellcode** : suite d'instructions machine concue pour etre executee dans un contexte donne.
- **Bind shell** : mecanisme ouvrant un interpreteur de commandes sur une interface reseau, accessible depuis une autre machine ; a manipuler uniquement en laboratoire autorise.
- **Git commit** : sauvegarde versionnee du code et de son historique.
- **Git bundle** : archive transportable d'un depot et de son historique Git.
