#include "spm.h"
#include "unprotected.h"

#include <stdio.h>

int spm_foo0()
{
    puts("spm_foo0");
    int ret = spm_bar0();
    puts("spm_foo0 returning");
    return ret;
}

int spm_bar0()
{
    puts("spm_bar0");
    int ret = spm_foo1();
    puts("spm_bar0 returning");
    return ret;
}
