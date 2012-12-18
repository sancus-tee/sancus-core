#include <msp430.h>
#include <stdio.h>
#include <string.h>

typedef struct
{
    char hash[64];
    const char* expected_hash;
    long secret;
    const char* public;
    size_t size;
} Spm;

#define INIT_SPM(x, p, h) \
    static const char x##_public[sizeof(p) - 1] __attribute__((aligned(2), section(".data"))) = p; \
    Spm x = {{0}, h, 0, x##_public, sizeof(x##_public)}

#define TEST_SPM(x) do {puts("Testing SPM " #x); test_spm(&x);} while (0)

// PS(simple, "\xde\xad\xbe\xef");

INIT_SPM(simple,
         "\xde\xad\xbe\xef",
         "\x88\x39\xe9\x9f\xb1\xbb\xb5\x55\x99\xf5\x49\x3e\xdc\x4c\xff\xaa\x53\xf1\xf4\x5f\x7f\xc9\xb8\xa2\x5f\x12\x06\xa6\x12\x80\xe8\x0d\x59\x7c\x84\x46\x36\x63\xcf\x6b\xeb\x77\x4f\x32\xc4\x26\xd0\xa4\xde\x56\x06\xf2\x76\x05\xe2\x5f\x28\xb2\xa6\x71\x94\x85\x0b\xa9");

void print_nibble(unsigned char n)
{
    if (n > 0xf)
        putchar('?');
    else if (n < 0xa)
        putchar(n + '0');
    else
        putchar(n - 0xa + 'a');
}

void print_mem(const unsigned char* start, size_t size, int swap)
{
    size_t i;
    for (i = 0; i < size; i++)
    {
        unsigned char b = start[swap ? (i % 2 ? i - 1 : i + 1) : i];
        print_nibble(b >> 4);
        print_nibble(b & 0x0f);
    }
}

void protect_spm(Spm* spm)
{
    puts("Protecting SPM...");

    asm("mov %0, r12\n\t"
        "mov %1, r13\n\t"
        "mov %2, r14\n\t"
        "mov %3, r15\n\t"
        ".word 0x1381"
        :
        : "m"(spm->public), "r"(spm->public + spm->size - 1),
          "r"(&spm->secret), "r"((char*)&spm->secret + sizeof(spm->secret) - 1)
        : "r12", "r13", "r14", "r15");
}

void hash_spm(Spm* spm)
{
    unsigned spm_id;
    puts("Hashing spm");

    asm("mov %1, r14\n\t"
        "mov %2, r15\n\t"
        ".word 0x1382\n\t"
        "mov r15, %0\n\t"
        : "=m"(spm_id)
        : "m"(spm->public), "r"(spm->expected_hash)
        : "r14", "r15");

    printf("Got id %x\n", spm_id);
}

void test_spm(Spm* spm)
{
    protect_spm(spm);
    hash_spm(spm);
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    puts("main() started");
    WDTCTL = WDTPW|WDTHOLD;

    TEST_SPM(simple);

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
