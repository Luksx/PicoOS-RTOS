MEMORY
{
    FLASH (rx)  : ORIGIN = 0x10000000, LENGTH = 2048K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 264K
}

_estack = ORIGIN(RAM) + LENGTH(RAM);
__app_start = ORIGIN(FLASH) + 0x100;

SECTIONS
{
    .boot2 ORIGIN(FLASH) :
    {
        KEEP(*(.boot2))
    } > FLASH

    .text __app_start :
    {
        _vectors_start = .;
        KEEP(*(.vectors))
        _vectors_end = .;

        *(.text.Reset_Handler)
        *(.text*)
        *(.rodata*)
    } > FLASH

    .data : AT> FLASH
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

    ASSERT(ADDR(.boot2) == ORIGIN(FLASH), ".boot2 must start at 0x10000000")
    ASSERT(SIZEOF(.boot2) == 0x100, ".boot2 must be exactly 256 bytes")
    ASSERT(ADDR(.text) == __app_start, ".text must start at 0x10000100")
    ASSERT(_vectors_start == __app_start, "Vector table must start at 0x10000100")
}