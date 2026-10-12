from pathlib import Path
import struct

source = Path("hello_lab_note")
destination = Path("hello_lab_patche")
data = bytearray(source.read_bytes())

if len(data) < 64:
    raise SystemExit("Erreur : en-tete ELF incomplet")

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

# Verifier que les donnees existent vraiment dans le fichier
if offset + taille_fichier > len(data):
    raise SystemExit("Erreur : segment hors limites")

# Refuser les conflits de pages avec les PT_LOAD existants
page = 4096
debut = (adresse // page) * page
fin = ((adresse + taille_memoire + page - 1) // page) * page

for j in range(phnum):
    if j == index:
        continue

    autre = phoff + j * phentsize

    if struct.unpack_from("<I", data, autre)[0] != 1:
        continue

    autre_adresse = struct.unpack_from("<Q", data, autre + 16)[0]
    autre_taille = struct.unpack_from("<Q", data, autre + 40)[0]

    autre_debut = (autre_adresse // page) * page
    autre_fin = ((autre_adresse + autre_taille + page - 1) // page) * page

    if debut < autre_fin and autre_debut < fin:
        raise SystemExit("Erreur : conflit entre segments PT_LOAD")

# Modifier uniquement le type du segment et son alignement
struct.pack_into("<I", data, position, 1)       # PT_LOAD
struct.pack_into("<Q", data, position + 48, 4096)

destination.write_bytes(data)
destination.chmod(0o755)

print(f"Segment {index} : PT_NOTE -> PT_LOAD")
print("Permissions : lecture seule")
print("Point d'entree : inchange")
print(f"Fichier cree : {destination}")
