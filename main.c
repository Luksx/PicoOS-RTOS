#include <hardware/gpio.h>

#include <pico/time.h>
#include <pico/types.h>
#include <stdint.h>
#include <stdio.h>

// KERNEL
#include "include/kernel.h"

#pragma region MAIN
int main()
{
 
    kernel_init();

    start_first_task();

    while (true) {
        printf("ERORR main loop\n");
    }
}
#pragma endregion
