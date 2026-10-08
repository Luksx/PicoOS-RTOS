#ifndef TASKS_H
#define TASKS_H

#define LED_PIN 25

// stdlib
#include "pico/stdlib.h"



// hardware APIs
#include "hardware/clocks.h"
#include <hardware/sync.h>

#include <stdint.h>
#include <stdio.h>


void task_a(void *argument);
void task_b(void *argument);
void IDLE_TASK(void * argument);

#endif
