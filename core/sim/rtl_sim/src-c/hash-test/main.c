#include <msp430.h>
#include <stdio.h>

long public = 0xdeadbeef;
long secret = 0xcafebabe;
unsigned int hash[32];

void protect_spm()
{
    puts("Protecting SPM...");

    asm("mov %0, r12\n\t"
        "mov %1, r13\n\t"
        "mov %2, r14\n\t"
        "mov %3, r15\n\t"
        ".word 0x1381"
        :
        : "i"(&public), "i"((char*)&public + sizeof(public) - 1),
          "i"(&secret), "i"((char*)&secret + sizeof(secret) - 1)
        : "r12", "r13", "r14", "r15");
//     puts("...done");
}

void hash_spm()
{
    puts("Hashing spm");

    asm("mov %0, r14\n\t"
        "mov %1, r15\n\t"
        ".word 0x1382"
        :
        : "i"(&public), "i"(hash)
        : "r14", "r15");
}

void print_hash()
{
    int i;
    printf("Hash: ");
    for (i = 0; i < sizeof(hash); i++)
        printf("%02x", hash[i]);
    printf("\n");
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    puts("main() started");
    WDTCTL = WDTPW|WDTHOLD;
    protect_spm();
    hash_spm();
    print_hash();
    puts("main() done");
    return 0;
}

int putchar(int c)
{
    P1OUT = c;
    P1OUT |= 0x80;
    return c;
}
