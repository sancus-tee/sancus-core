#include <msp430.h>
#include <stdio.h>
#include <string.h>

typedef unsigned spm_id;

extern spm_id hmac_verify(const char* expected_hmac, const void* spm_entry);
extern spm_id hmac_write(char* dst, const void* spm_entry);

extern spm_id spm();
extern char signature;

typedef struct
{
    char hash[64];
    const char* expected_hmac;
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

void test_verify(Spm* spm, spm_id expected_id)
{
    puts("* Verifying HMAC...");
    spm_id id = hmac_verify(spm->expected_hmac, spm->public);

    if (id != expected_id)
        printf(" - Failed: expected id %u, got %u\n", expected_id, id);
    else
        puts(" - Passed");
}

void test_write(Spm* spm, spm_id expected_id)
{
    char hmac[16];

    puts("* Writing HMAC...");
    spm_id id = hmac_write(hmac, spm->public);

    if (id != expected_id)
        printf(" - Failed: expected id %u, got %u\n", expected_id, id);
    else if (memcmp(hmac, spm->expected_hmac, sizeof(hmac)) != 0)
    {
        printf(" - Failed: wrong HMAC: ");
        print_mem(hmac, sizeof(hmac), 0);
        printf("\n");
    }
    else
        puts(" - Passed");
}

void test_spm(Spm* spm)
{
    static spm_id next_id = 1;
    next_id++;
    protect_spm(spm);
    test_verify(spm, next_id);
    test_write(spm, next_id);
}

void test_sign()
{
    puts("Protecting SPM...");

    asm("mov #public_start, r12\n\t"
        "mov #public_end-1, r13\n\t"
        "mov #secret_start, r14\n\t"
        "mov #secret_end-1, r15\n\t"
        ".word 0x1381"
        : : : "r12", "r13", "r14", "r15");

    puts("* Signing secret section...");
    spm_id id = spm();

    if (id != 1)
        printf(" - Failed: expected id 1, got %u\n", id);
    else if (memcmp(&signature, "\x87\x18\x3f\x19\xa1\x58\x57\xbd\x72\x8c\x04\xb4\xa7\x31\xb6\x8c", 16) != 0)
    {
        printf(" - Failed: wrong HMAC: ");
        print_mem(&signature, 16, 0);
        printf("\n");
    }
    else
        puts(" - Passed");
}

int __attribute__((section(".init9"), aligned(2))) main(void)
{
    puts("main() started");
    WDTCTL = WDTPW|WDTHOLD;

    test_sign();
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
