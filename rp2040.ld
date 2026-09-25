MEMORY
{
    FLASH (rx)  : ORIGIN = 0x10000100, LENGTH = 2048K - 0x100
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 264K
}

_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .text :
    {
        . = ALIGN(256);
        _vectors_start = .;
        KEEP(*(.vectors))
        _vectors_end = .;

        *(.text.Reset_Handler)
        *(.text*)
        *(.rodata*)
    } > FLASH

    .data : AT(LOADADDR(.text) + SIZEOF(.text))
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM

    _sidata = LOADADDR(.data);

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
}