#include <hardware/gpio.h>
#include <pico/time.h>
#include <pico/types.h>
#include <stdint.h>
#include <stdio.h>



// KERNEL
#include "include/kernel.h"
// stdlib
#include "pico/stdlib.h"


// hardware APIs
#include "hardware/clocks.h"


#define LED_PIN 25


void task_a(void *argument)
{
    while(1){

        printf("TASK A IN PROGRESS\n==================\n");
        gpio_put(LED_PIN, 1);
        sleep_ms(1000);
        gpio_put(LED_PIN, 0);
        sleep_ms(1000);
    }
}

void task_b(void *argument)
{
    while(1){
        printf("TASK B IN PROGRESS\n==================\n");
        printf("System Clock Frequency is %d Hz\n", clock_get_hz(clk_sys));
        printf("USB Clock Frequency is %d Hz\n", clock_get_hz(clk_usb));
        
        
        uint32_t uptime_us = time_us_64();
        uint32_t uptime_ms = (uint32_t)(uptime_us / 1000u);
        uint32_t clock_khz = clock_get_hz(clk_sys) / 1000u;
        uint32_t core = get_core_num();

        printf("\n--- RP2040 STATUS ---\n");
        printf("Uptime      : %lu ms\n", (unsigned long)uptime_ms);
        printf("Core        : %lu\n", (unsigned long)core);
        printf("CPU clock   : %lu kHz\n", (unsigned long)clock_khz);
        sleep_ms(2000);
    }   
    return;
}

void IDLE_TASK(void * argument)
{
    while(1){};
}

task_t task_A_block;
static uint32_t task_A_stack[256];

task_t task_B_block;
static uint32_t task_B_stack[256];

task_t IDLE_block;
static uint32_t IDLE_stack[256];


int main()
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

    while (true) {
        printf("ERORR main loop\n");
    }
}
