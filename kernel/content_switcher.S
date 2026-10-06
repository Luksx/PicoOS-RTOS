.syntax unified
.cpu cortex-m0plus
.thumb

.text




.global load
.type load, %function
.thumb_func

load:
        movs r2, r0
        mov r0, r1
        blx r2
        bl task_exit

.size load, .-load


.global save
.type save, %function
.thumb_func

save:
        msr psp, r0
        bx lr
.size save, .-save


.global get_PSP
.type get_PSP, %function
.thumb_func

get_PSP:
        mrs r0, psp
        bx lr
.size get_PSP, .-get_PSP


.global isr_pendsv
.type isr_pendsv, %function
.thumb_func

isr_pendsv:

        //Loads the psp from interrupted stack onto r0 (address)
        mrs r0, psp
        // Loads r4 into r0 - 4 bytes
        str r4, [r0, #4]
        str r5, [r0, #8]
        str r6, [r0, #12]
        str r7, [r0, #16]
        adds r0, #16

        //Stored R4-R7
        //Higher addresses needs to go lower
        mov r4, r8
        str r4, [r0, #20]
        mov r4, r9
        str r4, [r0, #24]
        mov r4, r10
        str r4, [r0, #28]
        mov r4, r11
        str r4, [r0, #32]
        adds r0, #16


        //Stores PSP into task structure - stack_pointer
        ldr r1, =current_task
        ldr r2, [r1]
        str r0, [r2, #0]

        //Calls for next, while preserving lr
        push    {r4, lr}
        bl      scheduler_select_next
        pop     {r4, r7}
        mov     lr, r7

        //Loads new task

        



        bx      lr

.size isr_pendsv, . - isr_pendsv