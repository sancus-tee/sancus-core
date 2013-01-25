#include <stdio.h>
#include <msp430.h>

#include <spm-support.h>

#include "spm.h"

#define get_reg(x) asm("mov r4, %0" : "=m"(x));

extern int secret;

DECLARE_SPM(foo);

void init_io()
{
    WDTCTL = WDTPW|WDTHOLD;
    P1DIR = 0xff;
    P2DIR = 0xff;
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    int i = 0;
    void* reg;
//     struct Foo foo = {1, 2, 3, 4, 5, 6, 7, 8};
    puts("main() started");
    init_io();

    protect_spm(&foo);
    //protect_spm();

    puts("calling spm");
    spm0();
//     i = spm1(foo);
//     printf("spm1=%d\n", i);

    puts("writing secret");
    secret = 0xdead;

    puts("main() done");
    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;
    return c;
}
