#define _POSIX_C_SOURCE 200809L
#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX_FILE_SIZE (64u * 1024u * 1024u)
#define PAGE_SIZE_ 4096u

typedef struct { unsigned char *bytes; size_t size; Elf64_Ehdr *header; Elf64_Phdr *segments; } ElfLab;

static int fail(const char *msg) { fprintf(stderr, "ERREUR : %s\n", msg); return 1; }

static void free_lab(ElfLab *e) { free(e->bytes); memset(e, 0, sizeof *e); }

/* Ces vérifications portent sur les métadonnées, pas sur l'exécution du fichier. */
static int validate_segments(const ElfLab *e) {
    const Elf64_Ehdr *h = e->header;
    int entry_executable = (h->e_entry == 0);

    for (unsigned int i = 0; i < h->e_phnum; ++i) {
        const Elf64_Phdr *p = &e->segments[i];

        /* Ne jamais lire au-delà des octets réellement disponibles. */
        if (p->p_offset > e->size ||
            p->p_filesz > e->size - p->p_offset)
            return fail("segment avec des donnees hors du fichier");

        if (p->p_type != PT_LOAD) continue;

        if (p->p_filesz > p->p_memsz)
            return fail("PT_LOAD : taille fichier superieure a taille memoire");

        if (p->p_align > 1 &&
            ((p->p_align & (p->p_align - 1)) != 0 ||
             p->p_offset % p->p_align != p->p_vaddr % p->p_align))
            return fail("PT_LOAD : alignement invalide");

        if (p->p_memsz > UINT64_MAX - p->p_vaddr)
            return fail("PT_LOAD : debordement de l'adresse virtuelle");

        if ((p->p_flags & PF_X) && h->e_entry >= p->p_vaddr &&
            h->e_entry - p->p_vaddr < p->p_memsz)
            entry_executable = 1;
    }

    if (!entry_executable)
        return fail("point d'entree hors d'un segment PT_LOAD executable");

    return 0;
}

static int read_lab(const char *path, ElfLab *e) {
    memset(e, 0, sizeof *e);
    struct stat st;
    if (stat(path, &st) || !S_ISREG(st.st_mode) || st.st_size < (off_t)sizeof(Elf64_Ehdr) ||
        st.st_size > (off_t)MAX_FILE_SIZE) return fail("fichier introuvable, non regulier ou taille non prise en charge");
    FILE *f = fopen(path, "rb");
    if (!f) return fail("impossible d'ouvrir l'ELF source");
    e->size = (size_t)st.st_size;
    e->bytes = malloc(e->size);
    if (!e->bytes) { fclose(f); return fail("memoire insuffisante"); }
    if (fread(e->bytes, 1, e->size, f) != e->size) {
        fclose(f); free_lab(e); return fail("lecture incomplete");
    }
    fclose(f);
    e->header = (Elf64_Ehdr *)e->bytes;
    Elf64_Ehdr *h = e->header;
    if (memcmp(h->e_ident, ELFMAG, SELFMAG) || h->e_ident[EI_CLASS] != ELFCLASS64 ||
        h->e_ident[EI_DATA] != ELFDATA2LSB || h->e_ident[EI_VERSION] != EV_CURRENT ||
        h->e_machine != EM_X86_64 || h->e_version != EV_CURRENT ||
        h->e_ehsize != sizeof(Elf64_Ehdr) || h->e_phentsize != sizeof(Elf64_Phdr) ||
        h->e_phnum == 0 || h->e_phnum == PN_XNUM ||
        (h->e_type != ET_EXEC && h->e_type != ET_DYN)) {
        free_lab(e); return fail("ELF64 x86-64 little-endian attendu");
    }
    if (h->e_phoff > e->size ||
        h->e_phnum > (e->size - (size_t)h->e_phoff) / sizeof(Elf64_Phdr)) {
        free_lab(e); return fail("table des segments hors limites");
    }
    /* La structure Elf64_Phdr est lue via un pointeur : offset aligne. */
    if (h->e_phoff % _Alignof(Elf64_Phdr) != 0) {
        free_lab(e);
        return fail("table des segments mal alignee");
    }
    e->segments = (Elf64_Phdr *)(e->bytes + h->e_phoff);
    if (validate_segments(e)) {
        free_lab(e);
        return 1;
    }
    return 0;
}

static const char *segment_name(uint32_t kind) {
    switch (kind) {
        case PT_LOAD: return "PT_LOAD";
        case PT_NOTE: return "PT_NOTE";
        case PT_DYNAMIC: return "PT_DYNAMIC";
        case PT_PHDR: return "PT_PHDR";
        default: return "AUTRE";
    }
}

static void inspect(const char *label, const ElfLab *e) {
    printf("Fichier : %s\nPoint d'entree : 0x%" PRIx64 "\n", label, (uint64_t)e->header->e_entry);
    unsigned int loads = 0, notes = 0;
    for (unsigned int i = 0; i < e->header->e_phnum; ++i) {
        const Elf64_Phdr *p = &e->segments[i];
        if (p->p_type == PT_LOAD) ++loads;
        if (p->p_type == PT_NOTE) ++notes;
        printf("  #%u %-10s offset=0x%" PRIx64 " adresse=0x%" PRIx64
               " memsz=0x%" PRIx64 " permissions=%c%c%c\n", i,
               segment_name(p->p_type), (uint64_t)p->p_offset,
               (uint64_t)p->p_vaddr, (uint64_t)p->p_memsz,
               (p->p_flags & PF_R) ? 'R' : '-',
               (p->p_flags & PF_W) ? 'W' : '-',
               (p->p_flags & PF_X) ? 'X' : '-');
    }
    printf("Bilan : %u PT_LOAD / %u PT_NOTE\n", loads, notes);
}

static int overlaps(uint64_t a, uint64_t alen, uint64_t b, uint64_t blen) {
    if (!alen || !blen) return 0;
    if (a > UINT64_MAX - alen || b > UINT64_MAX - blen) return 1;
    const uint64_t aend = a + alen, bend = b + blen;
    if (aend > UINT64_MAX - (PAGE_SIZE_ - 1) || bend > UINT64_MAX - (PAGE_SIZE_ - 1)) return 1;
    const uint64_t aa = a & ~(uint64_t)(PAGE_SIZE_ - 1);
    const uint64_t ab = (aend + PAGE_SIZE_ - 1) & ~(uint64_t)(PAGE_SIZE_ - 1);
    const uint64_t ba = b & ~(uint64_t)(PAGE_SIZE_ - 1);
    const uint64_t bb = (bend + PAGE_SIZE_ - 1) & ~(uint64_t)(PAGE_SIZE_ - 1);
    return aa < bb && ba < ab;
}

static int transform(ElfLab *e) {
    // Laboratory-only constraint: require the ESGI note from layout_note_separe.ld.
    // No executable code is inserted and the original entry point is left unchanged.
    unsigned int loads = 0, notes = 0;
    Elf64_Phdr *target = NULL;
    for (unsigned int i = 0; i < e->header->e_phnum; ++i) {
        Elf64_Phdr *p = &e->segments[i];
        if (p->p_type == PT_LOAD) ++loads;
        if (p->p_type != PT_NOTE) continue;
        ++notes;
        if (p->p_flags != PF_R || p->p_filesz < 24 || p->p_filesz > p->p_memsz ||
            p->p_offset % PAGE_SIZE_ || p->p_vaddr % PAGE_SIZE_ ||
            p->p_offset > e->size || p->p_filesz > e->size - p->p_offset) continue;
        const unsigned char *note = e->bytes + p->p_offset;
        // ELF note: namesz=5, descsz=4, type=1, name="ESGI\0", desc=0x12345678.
        const unsigned char marker[] = {
            5,0,0,0, 4,0,0,0, 1,0,0,0,
            'E','S','G','I',0,0,0,0, 0x78,0x56,0x34,0x12
        };
        if (memcmp(note, marker, sizeof marker) != 0) continue;
        if (target) return fail("plusieurs notes laboratoire candidates");
        target = p;
    }
    if (loads != 2 || notes != 1 || !target)
        return fail("transformations reservees au ELF ESGI de laboratoire (2 LOAD + 1 NOTE identifiee)");
    for (unsigned int i = 0; i < e->header->e_phnum; ++i) {
        Elf64_Phdr *p = &e->segments[i];
        if (p->p_type == PT_LOAD && overlaps(target->p_vaddr, target->p_memsz, p->p_vaddr, p->p_memsz))
            return fail("conflit de pages entre les segments");
    }
    target->p_type = PT_LOAD;
    target->p_align = PAGE_SIZE_;
    puts("Transformation : PT_NOTE -> PT_LOAD sur l'ELF ESGI de laboratoire");
    puts("Point d'entree et octets du programme : inchanges");
    return 0;
}

static int write_output(const char *path, const ElfLab *e) {
    int fd = open(path, O_WRONLY | O_CREAT | O_EXCL, 0755);
    if (fd < 0) return fail("sortie existante ou non accessible : refus de l'ecraser");
    size_t done = 0;
    while (done < e->size) {
        ssize_t n = write(fd, e->bytes + done, e->size - done);
        if (n <= 0) {
            close(fd); unlink(path); return fail("ecriture incomplete");
        }
        done += (size_t)n;
    }
    if (close(fd) != 0) { unlink(path); return fail("fermeture du fichier de sortie impossible"); }
    printf("Fichier genere : %s\n", path);
    return 0;
}

int main(int argc, char **argv) {
    if (!((argc == 3 && !strcmp(argv[1], "inspect")) ||
          (argc == 4 && !strcmp(argv[1], "transform")))) {
        fprintf(stderr, "Utilisation :\n  %s inspect <fichier ELF>\n  %s transform <ELF de laboratoire> <sortie>\n", argv[0], argv[0]);
        return 2;
    }
    ElfLab e;
    if (read_lab(argv[2], &e)) return 1;
    int status = 0;
    if (!strcmp(argv[1], "inspect")) inspect(argv[2], &e);
    else {
        status = transform(&e);
        if (!status) status = write_output(argv[3], &e);
    }
    free_lab(&e);
    return status;
}
