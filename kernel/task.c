#include "include/kernel.h"
#include <pico/time.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>


task_t * volatile  current_task;
static uint32_t next_task_id = 0;


void task_exit(void)
{
    current_task->task_state = TASK_TERMINATED;
    printf("Task completed, shutting down\n");
    while(1){}
}




void task_init(
    task_t *task,
    uint32_t *stack_bottom,
    size_t stack_size_bytes,
    void *argument,
    task_entry_t task_entry,
    uint32_t priority
)
{
     if (task == NULL || stack_bottom == NULL) {
        return;
    }
    task->stack_size_bytes = stack_size_bytes;
    task->id = next_task_id++;
    task->priority = priority;
    task->task_entry = task_entry;
    task->stack_bottom = stack_bottom;

    task->task_state = TASK_READY;


    uint32_t *stack_top = task->stack_bottom + task->stack_size_bytes / 4;

    uint32_t *hw = stack_top - 8; //R0-R4 reserved space
    
    //Save arguments to R0-R3
    hw[0] = (uintptr_t)argument; //R0
    hw[1] = 0;   //R1
    hw[2] = 0;   //R2
    hw[3] = 0;   //R3
    
    hw[4] = 0;   //R12
    hw[5] = (uintptr_t)task_exit; //LR - function exit pointer

    hw[6] = (uintptr_t)task_entry; //PC - function entry pointer
    hw[7] = XPSR_THUMB_BIT; // XPSR - thumb bit


    //R4-R11
    uint32_t *sw = hw - 8;
    for(size_t i = 0; i < 8; i++)
    {
        sw[i] = 0;
    }
    task->stack_pointer = sw;
    
};
