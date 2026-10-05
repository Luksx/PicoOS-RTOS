#include "include/kernel.h"
#include <stdint.h>


void context_switch(task_t *old, task_t *new)
{
    //Find Old stack pointer
    uint32_t *sp = get_PSP();
    //Save R4-R11
    save(sp);
    //Set old pointer to stack pointer
    old->stack_pointer = sp;
    //Load new task
    load(new->task_entry, NULL);
    current_task = new;
};