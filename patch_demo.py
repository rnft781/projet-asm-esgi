from pathlib import Path
import shutil

source = Path("demo")
destination = Path("demo_modifie")

ancien = b"Projet ASM ESGI : test ELF"
nouveau = b"Projet ASM ESGI : test OK!"

donnees = source.read_bytes()

if donnees.count(ancien) != 1:
    raise SystemExit("Message introuvable ou present plusieurs fois")

donnees = donnees.replace(ancien, nouveau)

shutil.copy2(source, destination)
destination.write_bytes(donnees)

print("ELF modifie avec succes !")
