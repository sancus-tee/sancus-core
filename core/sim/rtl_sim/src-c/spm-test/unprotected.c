#include "unprotected.h"

#include <stdio.h>

void unprotected0()
{
    puts("unprotected0");
}

struct Foo unprotected1(struct Foo g)
{
    printf("unprotected1: %d\n", g.a);
    g.a += 5;
//     printf("ret foo: %d %d %d %d %d %d %d %d\n", g.a, g.b, g.c, g.d, g.e, g.f, g.g, g.h);
    return g;
}
