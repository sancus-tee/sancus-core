cmake_minimum_required(VERSION 2.8)

find_package(SpmCompiler REQUIRED)

add_spm(foo spm.c)
add_spm_executable(spm-test main.c unprotected.c
                   SPMS foo
                   ROM_SIZE 16K RAM_SIZE 16K)
