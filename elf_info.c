#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <elf.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("Usage: %s <fichier>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    if (f == NULL) {
        perror("Erreur ouverture");
        return 1;
    }

    Elf64_Ehdr header;

    if (fread(&header, sizeof(header), 1, f) != 1 ||
        memcmp(header.e_ident, ELFMAG, SELFMAG) != 0 ||
        header.e_ident[EI_CLASS] != ELFCLASS64 ||
        header.e_ident[EI_DATA] != ELFDATA2LSB ||
        header.e_phentsize != sizeof(Elf64_Phdr)) {
        printf("ELF64 non pris en charge\n");
        fclose(f);
        return 1;
    }

    printf("Point d'entree : 0x%lx\n",
           (unsigned long)header.e_entry);

    printf("Nombre de segments : %u\n", header.e_phnum);

    for (unsigned int i = 0; i < header.e_phnum; i++) {
        Elf64_Phdr segment;

        if (fseek(f, (long)(header.e_phoff +
                  i * sizeof(segment)), SEEK_SET) != 0 ||
            fread(&segment, sizeof(segment), 1, f) != 1) {
            printf("Erreur lecture segment\n");
            fclose(f);
            return 1;
        }

        if (segment.p_type == PT_NOTE ||
            segment.p_type == PT_LOAD) {
            printf("%u | %s | Offset: 0x%lx | Adresse: 0x%lx\n",
                   i,
                   segment.p_type == PT_NOTE ? "PT_NOTE" : "PT_LOAD",
                   (unsigned long)segment.p_offset,
                   (unsigned long)segment.p_vaddr);
        }
    }

    fclose(f);
    return 0;
}
