#define _POSIX_C_SOURCE 200809L
#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int lire_exactement(int fd, void *destination, size_t longueur, off_t position) {
    size_t lus = 0;
    while (lus < longueur) {
        ssize_t n = pread(fd, (char *)destination + lus, longueur - lus,
                          position + (off_t)lus);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) return -1;
        lus += (size_t)n;
    }
    return 0;
}

static const char *nom_type(uint32_t type) {
    switch (type) {
        case PT_NULL: return "PT_NULL";
        case PT_LOAD: return "PT_LOAD";
        case PT_DYNAMIC: return "PT_DYNAMIC";
        case PT_INTERP: return "PT_INTERP";
        case PT_NOTE: return "PT_NOTE";
        case PT_PHDR: return "PT_PHDR";
        case PT_TLS: return "PT_TLS";
        case PT_GNU_STACK: return "PT_GNU_STACK";
        case PT_GNU_RELRO: return "PT_GNU_RELRO";
        case PT_GNU_EH_FRAME: return "PT_GNU_EH_FRAME";
#ifdef PT_GNU_PROPERTY
        case PT_GNU_PROPERTY: return "PT_GNU_PROPERTY";
#endif
        default: return "AUTRE";
    }
}

static void permissions(uint32_t flags, char texte[4]) {
    texte[0] = (flags & PF_R) ? 'R' : '-';
    texte[1] = (flags & PF_W) ? 'W' : '-';
    texte[2] = (flags & PF_X) ? 'X' : '-';
    texte[3] = '\0';
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage : %s <fichier ELF64 x86-64>\n", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) { perror("open"); return 1; }

    struct stat info;
    if (fstat(fd, &info) != 0 || info.st_size < (off_t)sizeof(Elf64_Ehdr)) {
        fprintf(stderr, "Erreur : fichier trop petit ou inaccessible.\n");
        close(fd);
        return 1;
    }

    Elf64_Ehdr ehdr;
    if (lire_exactement(fd, &ehdr, sizeof(ehdr), 0) != 0 ||
        memcmp(ehdr.e_ident, ELFMAG, SELFMAG) != 0 ||
        ehdr.e_ident[EI_CLASS] != ELFCLASS64 ||
        ehdr.e_ident[EI_DATA] != ELFDATA2LSB ||
        ehdr.e_ident[EI_VERSION] != EV_CURRENT ||
        ehdr.e_machine != EM_X86_64 ||
        ehdr.e_phentsize != sizeof(Elf64_Phdr) ||
        ehdr.e_phnum == PN_XNUM) {
        fprintf(stderr, "Erreur : ELF64 x86-64 little-endian invalide ou non pris en charge.\n");
        close(fd);
        return 1;
    }

    uint64_t taille = (uint64_t)info.st_size;
    if (ehdr.e_phoff > taille ||
        (uint64_t)ehdr.e_phnum > (taille - ehdr.e_phoff) / sizeof(Elf64_Phdr)) {
        fprintf(stderr, "Erreur : table des segments hors du fichier.\n");
        close(fd);
        return 1;
    }

    printf("Fichier : %s\n", argv[1]);
    printf("Format : ELF64 / x86-64 / little-endian\n");
    printf("Type : %s\n", ehdr.e_type == ET_DYN ? "DYN (executable PIE ou bibliotheque)" :
                           ehdr.e_type == ET_EXEC ? "EXEC" : "autre");
    printf("Point d'entree : 0x%" PRIx64 "\n", (uint64_t)ehdr.e_entry);
    printf("Nombre de segments : %u\n\n", ehdr.e_phnum);
    printf(" N  TYPE             OFFSET       ADRESSE      FICHIER  MEMOIRE  DROITS  ALIGN\n");

    unsigned loads = 0, notes = 0, avertissements = 0;
    int entree_executable = 0;
    for (unsigned i = 0; i < ehdr.e_phnum; i++) {
        Elf64_Phdr phdr;
        uint64_t pos = ehdr.e_phoff + (uint64_t)i * sizeof(phdr);
        if (lire_exactement(fd, &phdr, sizeof(phdr), (off_t)pos) != 0) {
            fprintf(stderr, "Erreur de lecture du segment %u.\n", i);
            close(fd);
            return 1;
        }
        char droits[4];
        permissions(phdr.p_flags, droits);
        printf("%2u  %-16s 0x%08" PRIx64 "   0x%08" PRIx64 "  %-8" PRIu64 " %-8" PRIu64 " %-6s  0x%" PRIx64 "\n",
               i, nom_type(phdr.p_type), (uint64_t)phdr.p_offset,
               (uint64_t)phdr.p_vaddr, (uint64_t)phdr.p_filesz,
               (uint64_t)phdr.p_memsz, droits, (uint64_t)phdr.p_align);

        if (phdr.p_type == PT_LOAD) {
            loads++;
            if (phdr.p_filesz > phdr.p_memsz) {
                fprintf(stderr, "  ! Segment %u : taille fichier > taille memoire\n", i);
                avertissements++;
            }
            if (phdr.p_align > 1 &&
                (phdr.p_offset % phdr.p_align) != (phdr.p_vaddr % phdr.p_align)) {
                fprintf(stderr, "  ! Segment %u : alignement incoherent\n", i);
                avertissements++;
            }
            if ((phdr.p_flags & PF_X) &&
                (uint64_t)ehdr.e_entry >= phdr.p_vaddr &&
                (uint64_t)ehdr.e_entry - phdr.p_vaddr < phdr.p_memsz) {
                entree_executable = 1;
            }
        } else if (phdr.p_type == PT_NOTE) {
            notes++;
        }
        if (phdr.p_type != PT_NULL &&
            (phdr.p_offset > taille || phdr.p_filesz > taille - phdr.p_offset)) {
            fprintf(stderr, "  ! Segment %u : donnees hors du fichier\n", i);
            avertissements++;
        }
    }
    printf("\nResume : %u PT_LOAD / %u PT_NOTE / %u avertissement(s)\n",
           loads, notes, avertissements);
    printf("Point d'entree dans un PT_LOAD executable : %s\n",
           entree_executable ? "oui" : "non / non detecte");
    close(fd);
    return avertissements ? 2 : 0;
}
