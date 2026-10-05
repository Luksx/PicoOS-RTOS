#include <hardware/gpio.h>
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
    printf("TASK A IN PROGRESS\n==================\n");
    sleep_ms(100);
    printf("LED ON!\n");
    gpio_put(LED_PIN, 1);
    sleep_ms(1000);

    printf("LED OFF!\n");
    gpio_put(LED_PIN, 0);
    sleep_ms(1000);
    return;
}


task_t task_A_block;
static uint32_t task_A_stack[256];




int main()
{
    
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    stdio_init_all();


    printf("System Clock Frequency is %d Hz\n", clock_get_hz(clk_sys));
    printf("USB Clock Frequency is %d Hz\n", clock_get_hz(clk_usb));

    printf("Task A init: \n");
    task_init(
        &task_A_block,
        task_A_stack,
        sizeof(task_A_stack),
        NULL,
        task_a,
        0,
        0);

    printf("Task A run\n");

    //Manual load of task A
    current_task = &task_A_block;
    load(task_a, NULL);

    while (true) {
        printf("ERORR main loop\n");
    }
}
