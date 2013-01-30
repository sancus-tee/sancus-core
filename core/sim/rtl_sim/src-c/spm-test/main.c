#include <stdio.h>
#include <msp430.h>

#include <spm-support.h>

#include "spm.h"

#define get_reg(x) asm("mov r4, %0" : "=m"(x));

DECLARE_SPM(foo);
DECLARE_SPM(bar);

void init_io()
{
    WDTCTL = WDTPW|WDTHOLD;
    P1DIR = 0xff;
    P2DIR = 0xff;
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    puts("main() started");
    init_io();

    protect_spm(&foo);
    protect_spm(&bar);

    puts("calling spm_foo0");
    int ret = spm_foo0();
    printf("Got %x back\n", ret);

    puts("main() done");
    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;
    return c;
}
