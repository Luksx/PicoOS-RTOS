#include "include/kernel.h"
#include <stdint.h>
#include <stdio.h>

#define MAX_TASKS 2

static task_t *ready_tasks[MAX_TASKS];
static uint32_t ready_count = 0;
static uint32_t task_cursor = 0;

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



void scheduler_init_task(task_t *task)
{
    if(ready_count>=MAX_TASKS || task==NULL)  
    {return;} 
    task->task_state = TASK_READY;
    ready_tasks[ready_count] = task;
    ready_count++;
}



void scheduler_select_next()
{
    //Round robin
    task_t *winner = NULL;
    uint32_t index = task_cursor % ready_count;
    for(size_t i = index; i<ready_count; i++)
    {
        task_t *check = ready_tasks[i];
        if(check->task_state == TASK_READY)
        {
            winner = check;
        }
    }
    if(winner == NULL)
    {
        current_task = ready_tasks[0];
    }


    /*
    //====== some priority thingy idk ====
    task_t *highest_priority = NULL;
    for(size_t i = 0; i<ready_count; i++)
    {
        task_t *check = ready_tasks[i];
        if(check->task_state == TASK_READY)
        {
            if(highest_priority == NULL || check->priority > highest_priority->priority)
                highest_priority = check;
        }
    }
    if(highest_priority != NULL)
        current_task = highest_priority;
    */
}