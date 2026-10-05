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