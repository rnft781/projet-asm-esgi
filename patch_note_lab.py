from pathlib import Path
import struct

source = Path("hello_lab_note")
destination = Path("hello_lab_patche")
data = bytearray(source.read_bytes())

# Vérifier le format ELF64 little-endian
if data[:4] != b"\x7fELF" or data[4:6] != b"\x02\x01":
    raise SystemExit("Erreur : ELF64 little-endian attendu")

# Emplacement de la table des segments
phoff = struct.unpack_from("<Q", data, 32)[0]
phentsize = struct.unpack_from("<H", data, 54)[0]
phnum = struct.unpack_from("<H", data, 56)[0]

if phentsize < 56 or phoff + phentsize * phnum > len(data):
    raise SystemExit("Erreur : table des segments invalide")

candidats = []

for i in range(phnum):
    position = phoff + i * phentsize
    type_segment, permissions = struct.unpack_from("<II", data, position)

    if type_segment == 4 and permissions == 4:
        candidats.append((i, position))

if len(candidats) != 1:
    raise SystemExit("Erreur : une seule note en lecture seule attendue")

index, position = candidats[0]

offset, adresse, _, taille_fichier, taille_memoire, _ = (
    struct.unpack_from("<QQQQQQ", data, position + 8)
)

# Limiter cette expérience à une note isolée sur une page
if (offset % 4096 != 0 or adresse % 4096 != 0
        or taille_fichier == 0 or taille_fichier > taille_memoire):
    raise SystemExit("Erreur : segment non adapté au laboratoire")

# Modifier uniquement le type du segment et son alignement
struct.pack_into("<I", data, position, 1)       # PT_LOAD
struct.pack_into("<Q", data, position + 48, 4096)

destination.write_bytes(data)
destination.chmod(0o755)

print(f"Segment {index} : PT_NOTE -> PT_LOAD")
print("Permissions : lecture seule")
print("Point d'entree : inchange")
print(f"Fichier cree : {destination}")
