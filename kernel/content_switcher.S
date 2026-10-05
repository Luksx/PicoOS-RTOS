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



/*
.global save
.type save, %function
.thumb_func

save:


.size save, .-save
*/