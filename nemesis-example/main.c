#include <msp430.h>
#include <stdio.h>

#include <sancus/sm_support.h>

#include "timer.h"

DECLARE_SM(test, 1234);

SM_DATA(test) int module_entries;

SM_ENTRY(test) void module_function()
{
    module_entries++;
}

int main()
{
    WDTCTL = WDTPW | WDTHOLD;
    timer_init();

    puts("main started");

    sancus_enable(&test);

    asm volatile("eint");

    // This triggers an interrupt during the third cycle of a 4-cycle instruction
    timer_irq(100);
    module_function();

    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;

    return c;
}

void timer_isr()
{
    timer_disable();
    puts("Timer interrupt");
}

TIMER_ISR_ENTRY(timer_isr);
