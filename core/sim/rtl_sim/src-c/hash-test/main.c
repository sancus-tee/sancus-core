#include <msp430.h>
#include <stdio.h>
#include <string.h>

typedef unsigned spm_id;

extern spm_id hash_spm(const char* expected_hash, const void* spm_entry);

typedef struct
{
    char hash[64];
    const char* expected_hash;
    long secret;
    const char* public;
    size_t size;
} Spm __attribute__((aligned(2)));

#define INIT_SPM(x, p, h) \
    static const char x##_public[sizeof(p) - 1] __attribute__((aligned(2), section(".data"))) = p; \
    static const char x##_hash[64] __attribute__((aligned(2))) = h; \
    Spm x = {{0}, x##_hash, 0, x##_public, sizeof(x##_public)}

#define TEST_SPM(x) do {puts("Testing SPM " #x); test_spm(&x);} while (0)

INIT_SPM(simple,
         "\xde\xad\xbe\xef",
         "\xbc\x1e\x61\xb2\xe6\xbd\x67\xa5\x14\x44\x6f\xb8\x0f\x80\xb2\xf1");

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

void test_spm(Spm* spm)
{
    static spm_id next_id = 0;
    spm_id id;
    protect_spm(spm);
    puts("Hashing SPM...");
    id = hash_spm(spm->expected_hash, spm->public);

    if (id != ++next_id)
        puts(" - Failed");
        //printf(" - Failed: expected id %u, got %u\n", next_id, id);
    else
        puts(" - Passed");
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
