#include <msp430.h>
#include <stdio.h>
#include <string.h>

#include <spm-support.h>

#include "hardware.h"

extern void putchar_impl(int);

SPM_ENTRY("foo") spm_id spm_foo();
SPM_ENTRY("bar") void spm_bar();

char signature[16] = "AAAAAAAAAAAAAAAA";

DECLARE_SPM(foo, 0xcafe);
DECLARE_SPM(bar, 0xcafe);

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

void print_nibble(unsigned char n)
{
    if (n > 0xf)
        putchar('?');
    else if (n < 0xa)
        putchar(n + '0');
    else
        putchar(n - 0xa + 'a');
}

void print_mem(const char* start, size_t size, int swap)
{
    size_t i;
    for (i = 0; i < size; i++)
    {
        unsigned char b = start[swap ? (i % 2 ? i - 1 : i + 1) : i];
        print_nibble(b >> 4);
        print_nibble(b & 0x0f);
    }
}

extern char __spm_foo_hmac_bar;

spm_id spm_foo()
{
    puts("Verifying bar");
    hmac_write(signature, &bar);
    print_mem(signature, sizeof(signature), 0);
    putchar('\n');
    print_mem(&__spm_foo_hmac_bar, sizeof(signature), 0);
    putchar('\n');

    spm_id id;
    asm("mov %1, r15\n\t"
        ".word 0x1385\n\t"
        "mov r15, %0" : "=m"(id) : "r"(bar.public_start) : "r15");

    puts("Calling bar");
    spm_bar();
    return id;
}

void spm_bar()
{
    puts("bar");
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    init_io();
    puts("main() started");
    WDTCTL = WDTPW|WDTHOLD;

    protect_spm(&foo);
    protect_spm(&bar);
    spm_id id = spm_foo();
    printf("ID of bar: %u\n", id);

    puts("main() done");
    while (1) {}
    return 0;
}

int putchar(int c)
{
    if (c == '\n')
        putchar_impl('\r');

    putchar_impl(c);
    return c;
}
