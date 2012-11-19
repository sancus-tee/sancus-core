#include <stdio.h>
#include <msp430.h>

#include "spm.h"
#include "spm_support.h"

#define get_reg(x) asm("mov r4, %0" : "=m"(x));

extern int secret;

void init_io()
{
    P1DIR = 0xff;
    P2DIR = 0xff;
}

void protect_spm()
{
    puts("Protecting SPM...");

    asm("mov %0, r12\n\t"
        "mov %1, r13\n\t"
        "mov %2, r14\n\t"
        "mov %3, r15\n\t"
        ".word 0x1381"
        :
        : "i"(spm_text_start), "i"(spm_text_end),
          "i"(spm_data_start), "i"(spm_data_end)
        : "r12", "r13", "r14", "r15");
//     puts("...done");
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    int i = 0;
    void* reg;
    struct Foo foo = {1, 2, 3, 4, 5, 6, 7, 8};
    puts("main() started");
    init_io();

    protect_spm();
    //protect_spm();

    spm0();
    //i = spm1(foo);
    //printf("spm1=%d\n", i);

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
