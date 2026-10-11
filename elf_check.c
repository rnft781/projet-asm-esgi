#include <elf.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Utilisation : %s <fichier ELF>\n", argv[0]);
        return 2;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f) {
        perror("Ouverture");
        return 2;
    }

    if (fseek(f, 0, SEEK_END) != 0) {
        perror("fseek");
        fclose(f);
        return 2;
    }
    long taille = ftell(f);
    if (taille < 0 || fseek(f, 0, SEEK_SET) != 0) {
        fprintf(stderr, "Impossible de mesurer le fichier\n");
        fclose(f);
        return 2;
    }
    uint64_t taille_fichier = (uint64_t)taille;

    Elf64_Ehdr h;
    if (fread(&h, sizeof h, 1, f) != 1 ||
        memcmp(h.e_ident, ELFMAG, SELFMAG) != 0 ||
        h.e_ident[EI_CLASS] != ELFCLASS64 ||
        h.e_ident[EI_DATA] != ELFDATA2LSB ||
        h.e_machine != EM_X86_64 ||
        h.e_ehsize != sizeof h ||
        h.e_phentsize != sizeof(Elf64_Phdr) ||
        h.e_phnum == 0 || h.e_phnum == PN_XNUM ||
        (h.e_type != ET_EXEC && h.e_type != ET_DYN)) {
        fprintf(stderr, "Format non pris en charge (ELF64 x86-64 attendu)\n");
        fclose(f);
        return 2;
    }

    if (h.e_phoff > taille_fichier ||
        h.e_phnum > (taille_fichier - h.e_phoff) / sizeof(Elf64_Phdr)) {
        fprintf(stderr, "ERREUR : table des segments hors du fichier\n");
        fclose(f);
        return 1;
    }

    int erreurs = 0;
    unsigned int nombre_load = 0;
    int entree_executable = 0;
    printf("Verification de %s\n", argv[1]);

    for (unsigned int i = 0; i < h.e_phnum; ++i) {
        Elf64_Phdr p;
        uint64_t position = h.e_phoff + (uint64_t)i * sizeof p;
        if (fseek(f, (long)position, SEEK_SET) != 0 ||
            fread(&p, sizeof p, 1, f) != 1) {
            fprintf(stderr, "ERREUR : lecture segment %u\n", i);
            fclose(f);
            return 1;
        }
        if (p.p_type != PT_LOAD)
            continue;
        ++nombre_load;
        printf("  PT_LOAD #%u : offset=0x%" PRIx64
               " adresse=0x%" PRIx64 "\n",
               i, (uint64_t)p.p_offset, (uint64_t)p.p_vaddr);

        if (p.p_filesz > p.p_memsz) {
            printf("    ERREUR : taille disque > taille memoire\n");
            ++erreurs;
        }
        if (p.p_offset > taille_fichier ||
            p.p_filesz > taille_fichier - p.p_offset) {
            printf("    ERREUR : segment depasse la fin du fichier\n");
            ++erreurs;
        }
        if (p.p_align > 1 &&
            (p.p_align & (p.p_align - 1)) != 0) {
            printf("    ERREUR : alignement non valide\n");
            ++erreurs;
        } else if (p.p_align > 1 &&
                   p.p_offset % p.p_align != p.p_vaddr % p.p_align) {
            printf("    ERREUR : offset et adresse mal alignes\n");
            ++erreurs;
        }
        if (p.p_memsz > UINT64_MAX - p.p_vaddr) {
            printf("    ERREUR : debordement d'adresse\n");
            ++erreurs;
        }
        if ((p.p_flags & PF_X) && h.e_entry >= p.p_vaddr &&
            h.e_entry - p.p_vaddr < p.p_memsz)
            entree_executable = 1;
    }

    if (nombre_load == 0) {
        puts("ERREUR : aucun PT_LOAD");
        ++erreurs;
    }
    if (h.e_entry != 0 && !entree_executable) {
        puts("ERREUR : point d'entree hors des segments executables");
        ++erreurs;
    }
    printf("Bilan : %u PT_LOAD, %d erreur(s)\n", nombre_load, erreurs);
    fclose(f);
    return erreurs ? 1 : 0;
}
