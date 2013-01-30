#include "spm.h"

#include <stdio.h>

SPM_DATA("bar") int secret = 5;

int spm_foo1()
{
    puts("spm_foo1");
    secret = 0xdead;
    int ret = spm_bar1();
    puts("spm_foo1 returning");
    return ret;
}

int spm_bar1()
{
    puts("spm_bar1");
    secret = 0xbabe;
    return secret;
}
