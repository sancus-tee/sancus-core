#include <msp430.h>
#include <stdio.h>

#include "hardware.h"

#include "spm.h"
#include "spm_support.h"

#define get_reg(x) asm("mov r4, %0" : "=m"(x));

extern int secret;

extern int putchar_impl(int);

void init_io()
{
    WDTCTL = WDTCTL_INIT;               //Init watchdog timer

    P1OUT  = P1OUT_INIT;                //Init output data of port1
    P1SEL  = P1SEL_INIT;                //Select port or module -function on port1
    P1DIR  = P1DIR_INIT;                //Init port direction register of port1
    P1IES  = P1IES_INIT;                //init port interrupts
    P1IE   = P1IE_INIT;

    P2OUT  = P2OUT_INIT;                //Init output data of port2
    P2SEL  = P2SEL_INIT;                //Select port or module -function on port2
    P2DIR  = P2DIR_INIT;                //Init port direction register of port2
    P2IES  = P2IES_INIT;                //init port interrupts
    P2IE   = P2IE_INIT;

    P3DIR  = 0xff;
    P3OUT  = 0xff;                      //light LED during init
    //delay(65535);                       //Wait for watch crystal startup
    //delay(65535);
    P3OUT  = 0x00;                      //switch off LED

    P4DIR = 0x00;

    TACTL  = TACTL_AFTER_FLL;           //setup timer (still stopped)
    CCTL0  = CCIE|CAP|CM_2|CCIS_1|SCS;  //select P2.2 with UART signal
    CCTL1  = 0;                         //
    CCTL2  = 0;                         //
    TACTL |= MC1;                       //start timer

    asm volatile("eint");                             //enable interrupts
}

// void protect_spm()
// {
//     puts("Protecting SPM...");
// 
//     asm("mov %0, r12\n\t"
//         "mov %1, r13\n\t"
//         "mov %2, r14\n\t"
//         "mov %3, r15\n\t"
//         ".word 0x1381"
//         :
//         : "i"(spm_text_start), "i"(spm_text_end),
//           "i"(spm_data_start), "i"(spm_data_end)
//         : "r12", "r13", "r14", "r15");
//     puts("...done");
// }

typedef long test_t;
test_t q = 0;

test_t test2()
{
    return 5;
}

void test(test_t x, test_t y)
{
    q = test2();
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    //struct Foo foo = {1, 2, 3, 4, 5, 6, 7, 8};

    init_io();

    puts("========== main() started ==========");
    test_t x, y;
    x = 10;
    y = 2;
    test(x, y);
    printf("%ld/%ld==%ld\n", x, y, q);

    //protect_spm();
    //protect_spm();

    //spm0();
    //i = spm1(foo);
    //printf("spm1=%d\n", i);

    //puts("Writing secret");
    secret = 0xdead;
    puts("========== main() done ==========");
    //while (1);

    return 0;
}

int putchar(int c)
{
    if (c == '\n')
        putchar_impl('\r');

    putchar_impl(c);
    return c;
}
