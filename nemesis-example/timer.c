#include "timer.h"

uint16_t __isr_stack[ISR_STACK_SIZE];
void* __isr_sp = (void*) &__isr_stack[ISR_STACK_SIZE-1];

void timer_disable(void)
{
    TACTL = TACTL_DISABLE;
}

void timer_irq(int interval)
{
    TACTL = TACTL_DISABLE;
    /* 1 cycle overhead TACTL write */
    TACCR0 = interval - 1;
    TACCTL0 = TACCTL_DISABLE;
    /* source mclk, up mode */
    TACTL = TACTL_ENABLE;
}

void timer_irqc(int interval)
{
    TACTL = TACTL_DISABLE;
    TACCR0 = interval;
    TACCTL0 = TACCTL_ENABLE_CONT;
    TACTL = TACTL_CONTINUOUS;
}

void timer_tsc_start(void)
{
    TACTL = TACTL_DISABLE;
    TACCR0 = 0;
    TACCTL0 = TACCTL_DISABLE;
    TACTL = TACTL_CONTINUOUS;
}

int timer_tsc_end(void)
{
    return TAR;
}

void timer_init(void)
{
    TACTL = TASSEL_2 | // select SMCLK
            ID_0     | // /1 clock divider
            MC_0     | // Stop mode (timer halted)
            TACLR;     // clear timer

    // disable capture mode
    TACCTL0 = CM_0;
    TACCTL1 = CM_0;
    TACCTL2 = CM_0;

    // start timer (up mode)
    TACTL |= MC_2;
}
