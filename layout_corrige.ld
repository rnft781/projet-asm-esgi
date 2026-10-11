ENTRY(_start)

PHDRS {
    code  PT_LOAD FLAGS(5);
    data  PT_LOAD FLAGS(6);
    notes PT_LOAD FLAGS(4);
}

SECTIONS {
    . = 0x400000 + SIZEOF_HEADERS;

    .text : {
        *(.text*)
    } :code

    . = ALIGN(0x1000);

    .data : {
        *(.data*)
    } :data

    . = ALIGN(0x1000);

    .note.projet : {
        LONG(5);
        LONG(4);
        LONG(1);

        BYTE(69); BYTE(83); BYTE(71); BYTE(73);
        BYTE(0); BYTE(0); BYTE(0); BYTE(0);

        LONG(0x12345678);
    } :notes
}
