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
    .size _vectors, . - _vectors

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
    ldr  r0, =_sdata // start SRAM
    ldr  r1, =_edata //end SRAM
    ldr  r2, =_sidata //load adress flash

.Lcopy_check:
    cmp r0, r1
    beq .Lcopy_done

    ldr r3, [r2]
    str r3, [r0]

    adds r0, #4
    adds r2, #4
    b   .Lcopy_check
.Lcopy_done:
    ldr r0, =_sbss
    ldr r1, =_ebss
    movs r2, #0

.Lzero_check:
    cmp r0, r1
    beq .Lzero_done

    str r2, [r0]
    adds r0, #4
    b .Lzero_check
.Lzero_done:
    bl main
.Lhang:
    b   .Lhang

.size Reset_Handler, . - Reset_Handler
.section .text.Default_Handler, "ax", %progbits
.thumb_func
.global Default_Handler
.type Default_Handler, %function

Default_Handler:
    b Default_Handler

.size Default_Handler, . - Default_Handler


.thumb_func
.global NMI_Handler
.type NMI_Handler, %function
NMI_Handler:
    b    Default_Handler


.thumb_func
.global HardFault_Handler
.type HardFault_Handler, %function
HardFault_Handler:
    b    Default_Handler


.thumb_func
.global SVCall_Handler
.type SVCall_Handler, %function
SVCall_Handler:
    b    Default_Handler


.thumb_func
.global PendSV_Handler
.type PendSV_Handler, %function
PendSV_Handler:
    b    Default_Handler


.thumb_func
.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
    b    Default_Handler