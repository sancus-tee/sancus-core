#include "spm.h"
#include "unprotected.h"
// #include "spm_support.h"

#include <stdio.h>

int secret;

void spm0()
{
    puts("spm0");
    secret = 0xbabe;
    unprotected0();
}

int spm1(struct Foo f)
{
    puts("spm1");
    struct Foo g = unprotected1(f);
//     printf("got foo: %d %d %d %d %d %d %d %d\n", g.a, g.b, g.c, g.d, g.e, g.f, g.g, g.h);
    return f.a + f.b + f.c + f.d + f.e + f.f + f.g + f.h + g.a;
}
