#include "include/tasks.h"


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
    while(1){
        __wfi();
    }
}
