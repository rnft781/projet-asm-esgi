# Soutenance — Projet ELF x86-64 (15 minutes en binome)

## 1. Sujet et notions (2 min)
- ELF : format des executables sous Linux.
- Un Program Header decrit un segment.
- PT_NOTE : notes/metadonnees ; PT_LOAD : segment charge en memoire.
- e_entry : point d'entree du programme.

## 2. Partie ELF et assembleur (5 min)
- `hello.asm` sert de programme cobaye.
- `layout_note_separe.ld` cree un ELF de test avec deux PT_LOAD et un PT_NOTE.
- `make demo-elf` montre le passage a trois PT_LOAD et le maintien du message original.
- `infecteur.asm` est le prototype ASM distinct ; sur un ELF prepare, son test a affiche `[stager]` puis `Bonjour depuis ASM x64 !`, code retour 0 (validation anterieure sur WSL2).

## 3. Partie reseau (4 min)
- `bind_shell.asm` : socket, bind, listen, accept, dup2, execve.
- Compilation controlee sur Kali.
- Test Netcat Windows ↔ Kali sur port 9090 : connexion TCP reussie.
- Bien separer le test de connectivite du fonctionnement d'un bind shell, **non confirme**.

## 4. Tests et bilan (4 min)
- `make test` : demonstration ELF, 7 verifications, tests sur 8 fichiers incorrects.
- Limites : laboratoire controle, ELF specifique, pas d'integration reseau validee.
- Historique Git conserve et rendu par fichier .bundle.

## Questions frequentes
**Pourquoi PT_NOTE vers PT_LOAD ?** Le chargeur Linux utilise PT_LOAD pour decrire les zones a charger en memoire ; la modification exige aussi des adresses et alignements coherents.

**Pourquoi un cobaye ?** Eviter d'alterer un veritable executable du systeme et verifier que le programme d'origine fonctionne toujours.

**A quoi sert e_entry ?** A identifier l'adresse de depart du programme.

**Votre bind shell fonctionne-t-il ?** Sa compilation est validee ; son fonctionnement reseau reel et son integration ne sont pas encore prouves.
