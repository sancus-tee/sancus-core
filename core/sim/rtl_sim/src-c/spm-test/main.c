#include <stdio.h>
#include <msp430.h>

#define __spm __attribute__((section(".spm.public")))
#define __secret __attribute__((section(".spm.secret")))

extern char spm_public_start, spm_public_end, spm_secret_start, spm_secret_end;

int __secret secret = 0;

void __spm spm()
{
    puts("Writing secret from spm...");
    secret = 0xbabe;
    puts("...OK");
}

void write_secret()
{
    puts("Writing secret from unprotected...");
    secret = 0xdead;
    puts("...OK");
}

void protect_spm()
{
    puts("Protecting SPM");
    asm("mov %0, r12\n"
        "mov %1, r13\n"
        "mov %2, r14\n"
        "mov %3, r15\n"
        ".word 0x1381\n"
        :
        : "i"(&spm_public_start), "i"(&spm_public_end),
          "i"(&spm_secret_start), "i"(&spm_secret_end));
    puts("...OK");
}

void __spm unprotect_spm()
{
    puts("Unprotecting SPM");
    asm(".word 0x1380");
    puts("...OK");
}

void init_io()
{
    P1DIR = 0xff;
    P2DIR = 0xff;
}

int main(void)
{
    init_io();
    puts("main() started");

    write_secret();
    protect_spm();
    protect_spm();
    spm();
    write_secret();
    unprotect_spm();
    write_secret();

    puts("main() done");
    P2OUT = 0xff;
    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;
    return c;
}
