#ifndef KERNEL_H
#define KERNEL_H

#include <stdint.h>
#include <stddef.h>

#define XPSR_THUMB_BIT (1u << 24) //macro for the bit

#define DEFAULT_TIME_SLICE 1

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
    uint32_t time_slices;

} task_t;


void task_init(
    task_t *task,
    uint32_t *stack_bottom,
    size_t stack_size_bytes,
    void *argument,
    task_entry_t task_entry,
    uint32_t priority
);


typedef struct queue_item
{
    task_t * task_pointer;
    task_t * next_task;
} queue_item_t;

extern task_t* volatile  current_task;

void load(task_entry_t entry, void *argument);

void save(uint32_t *sp);

uint32_t *get_PSP();

void context_switch(task_t *old, task_t *new);
void scheduler_init_task(task_t *task);
void scheduler_select_next(void);
void start_first_task();


void kernel_init();

#endif