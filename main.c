#include <stdint.h>

#define GPIO25              (1u << 25)

#define SIO_BASE            0xD0000000u
#define GPIO_OUT_SET        (*(volatile uint32_t *)(SIO_BASE + 0x14))
#define GPIO_OUT_CLR        (*(volatile uint32_t *)(SIO_BASE + 0x18))
#define GPIO_OE_SET         (*(volatile uint32_t *)(SIO_BASE + 0x24))
#define GPIO_OE_CLR         (*(volatile uint32_t *)(SIO_BASE + 0x28))

#define IO_BANK0_BASE       0x40014000u
#define GPIO25_CTRL         (*(volatile uint32_t *)(IO_BANK0_BASE + 25u * 8u))

#define GPIO_FUNC_SIO       5u

int main(void)
{
    /* Route GPIO25 to the SIO peripheral. */
    GPIO25_CTRL = GPIO_FUNC_SIO;

    /* Configure GPIO25 as an output. */
    GPIO_OE_SET = GPIO25;

    /* Turn the onboard LED on. */
    GPIO_OUT_SET = GPIO25;

    while (1) {
    }
}