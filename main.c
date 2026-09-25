#include <stdint.h>

#define SIO_BASE   0xD0000000
#define GPIO_OUT   (*(volatile uint32_t*)(SIO_BASE + 0x14))
#define GPIO_SET   (*(volatile uint32_t*)(SIO_BASE + 0x18))
#define GPIO_CLR   (*(volatile uint32_t*)(SIO_BASE + 0x1C))
#define GPIO_OE    (*(volatile uint32_t*)(SIO_BASE + 0x24))



int main(void) {
    GPIO_OE = (1 << 25);
    GPIO_SET = (1 << 25);
    while (1) {}
}