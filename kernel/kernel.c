#include "include/kernel.h"
#include "include/tasks.h"
#include <hardware/regs/m0plus.h>
#include <hardware/structs/scb.h>
#include <hardware/timer.h>
#include <pico/types.h>

#define TICK_US 1000u
#define TIMER_ALARM_NUM 0
#define MAX_TASKS 3
#define TASK_STACK_WORDS 256

static uint64_t next_tick;


static task_t * task_list[MAX_TASKS];
static uint32_t task_count = 0;
static uint32_t task_cursor = 0;

task_t * volatile  current_task;
static uint32_t next_task_id = 0;

task_t task_A_block;
static uint32_t task_A_stack[TASK_STACK_WORDS];

task_t task_B_block;
static uint32_t task_B_stack[TASK_STACK_WORDS];

task_t IDLE_block;
static uint32_t IDLE_stack[TASK_STACK_WORDS];






/*
 ==================== SCHEDULER ==================== 



 
*/

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









void scheduler_select_next()
{
    //Round robin
    task_t *winner = NULL;
    uint32_t index = task_cursor % task_count;
    for(size_t i = index; i<task_count; i++)
    {
        task_t *check = task_list[i];
        if(check->task_state == TASK_READY)
        {
            winner = check;
        }
    }
    if(winner == NULL)
    {
        current_task = task_list[0];
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

void start_first_task(){
    //Manually loads IDLE task
    load(task_list[0]->task_entry, NULL);
}

void task_exit(void)
{
    current_task->task_state = TASK_TERMINATED;
    load(task_list[0]->task_entry, NULL);
    while(1){
        printf("IDLE TASK FAILED");
    }
}


/*
 ==================== INIT ==================== 




*/

//Adds task_t pointer into task lists
void scheduler_init_task(task_t *task)
{
    if(task_count>=MAX_TASKS || task==NULL)  
    {return;} 
    task->task_state = TASK_READY;
    task_list[task_count] = task;
    task_count++;
}

//Task inicialization
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
    task-> time_slices = DEFAULT_TIME_SLICE;
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
/*
 ==================== TICKS ==================== 



 
*/

void rtos_tick()
{
    //Interrupt

    scb_hw->icsr = M0PLUS_ICSR_PENDSVSET_BITS;
    __dsb();
    __isb();

    //Context switch should be done now
    /*
    
    IDK do some work here
    
    */
    //Setup next alarm
    next_tick += TICK_US;
    hardware_alarm_set_target(TIMER_ALARM_NUM, from_us_since_boot(next_tick));
    
}


/*
 ==================== TIMER INIIT ==================== 



 
*/


static void timer_callback(uint alarm_num)
{
    (void)alarm_num;
    
    //do a tick
    rtos_tick();
}




void timer_init(void)
{

    //claims the hardware timer
    hardware_alarm_claim(TIMER_ALARM_NUM);
    hardware_alarm_set_callback(TIMER_ALARM_NUM, timer_callback);
    
    //Setup first alarm
    next_tick += time_us_64() + TICK_US;
    hardware_alarm_set_target(TIMER_ALARM_NUM, from_us_since_boot(next_tick));

}



//Sets up the kernel and scheduler system
void kernel_init()
{
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);


    stdio_init_all();

    task_init(
        &IDLE_block,
        IDLE_stack,
        sizeof(IDLE_stack),
        NULL,
        IDLE_TASK,
        0);

    //TASK INIT
    task_init(
        &task_A_block,
        task_A_stack,
        sizeof(task_A_stack),
        NULL,
        task_a,
        0);

    task_init(
        &task_B_block,
        task_B_stack,
        sizeof(task_B_stack),
        NULL,
        task_b,
        0);
    
    scheduler_init_task(&IDLE_block);
    scheduler_init_task(&task_A_block);
    scheduler_init_task(&task_B_block);

}