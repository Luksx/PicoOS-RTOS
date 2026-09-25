.syntax unified
.cpu cortex-m0plus
.thumb

.section .vectors, "ax"
.global _vectors
_vectors: //Vector table VTOR
        .word _estack
        .word Reset_Handler
        .word NMI_Handler
        .word HardFault_Handler
        /* Exception */
        .word 0
        .word 0
        .word 0
        .word 0
        .word 0
        .word 0
        .word 0

        .word SVCall_Handler
        .word 0
        .word 0

        .word PendSV_Handler
        .word SysTick_Handler
        .rept 26
        .word Default_Handler
        .endr
    .size_vectors, . - _vectors

.section .text.Reset_Handler, "ax", %progbits
.thumb_func
.global Reset_Handler
.type Reset_Handler, %function

Reset_Handler:
    ldr r0, =_estack
    mov sp, r0

    ldr r0, =_vectors
    ldr r1, =0xE000ED08 //VTOR
    str r0, [r1]
    // Copy data from flash to SRAM
    ldr  r0, =_sdata
    ldr  r1, =_edata
    ldr  r2, =_sidata

.Lcopy:
    ldr r3, [r2]
    str r3, [r0]
    add r0, r0, #4
    add r2, r2, #4
.Lcopy_check:
    cmp r0, r1
    bne .Lcopy


    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0
    b   .Lzero_check
.Lzero:
    str r2, [r0]
    add r0, r0, #4
.Lzero_check:
    cmp r0, r1
    bne .Lzero

    bl main
    b .

    .thumb_func
NMI_Handler:
    b .

    .thumb_func
HardFault_Handler:
    b .

    .thumb_func
SVCall_Handler:
    b .

    .thumb_func
PendSV_Handler:
    b .

    .thumb_func
SysTick_Handler:
    b .   