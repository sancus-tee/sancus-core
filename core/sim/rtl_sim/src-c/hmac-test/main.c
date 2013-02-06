#include <msp430.h>
#include <stdio.h>
#include <string.h>

#include <spm-support.h>

SPM_ENTRY("foo") spm_id spm_foo();
SPM_ENTRY("bar") void spm_bar();

char signature[16] = "AAAAAAAAAAAAAAAA";

DECLARE_SPM(foo, 0xcafe);
DECLARE_SPM(bar, 0xcafe);

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
    puts("foo");
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
    puts("Calling bar 2");
    spm_bar();
    return id;
}

void spm_bar()
{
    puts("bar");
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    puts("main() started");
    WDTCTL = WDTPW|WDTHOLD;

    protect_spm(&foo);
    protect_spm(&bar);
    spm_id id = spm_foo();
    printf("ID of bar: %u\n", id);

    puts("main() done");
    P2OUT = 0x01;
    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;
    return c;
}
