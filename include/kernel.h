#ifndef KERNEL_H
#define KERNEL_H

#include <stdint.h>
#include <stddef.h>

#define XPSR_THUMB_BIT (1u << 24) //macro for the bit



// TASK Setup

typedef enum{
    TASK_READY,
    TASK_RUNNING,
    TASK_BLOCKED,
    TASK_TERMINATED
} task_state_t;

typedef void (*task_entry_t)(void *argument);

__attribute__((noreturn))
void task_exit(void);


typedef struct task{
    uint32_t *stack_pointer;
    uint32_t *stack_bottom;
    size_t stack_size_bytes;

    void *argument;

    task_entry_t task_entry;
    task_state_t task_state;
    uint32_t id;
    uint32_t priority;
} task_t;


void task_init(
    task_t *task,
    uint32_t *stack_bottom,
    size_t stack_size_bytes,
    void *argument,
    task_entry_t task_entry,
    uint32_t id,
    uint32_t priority
);

extern task_t* volatile  current_task;
extern task_t* volatile  next_task;

void load(task_entry_t entry, void *argument);

void save(uint32_t *sp);

uint32_t *get_PSP();

void context_switch(task_t *old, task_t *new);


#endif