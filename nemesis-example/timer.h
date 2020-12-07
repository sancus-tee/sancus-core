#ifndef SANCUS_SUPPORT_TIMER_H
#define SANCUS_SUPPORT_TIMER_H
#include <msp430.h>
#include <stdint.h>

#define TACTL_DISABLE       (TACLR) // 0x04
#define TACTL_ENABLE        (TASSEL_2 + MC_1 + TAIE) // 0x212
#define TACTL_CONTINUOUS    ((TASSEL_2 + MC_2) & ~TAIE) // 0x220
#define TACTL_ENABLE_CONT   (TASSEL_2 + MC_2 + TAIE)
#define TACCTL_ENABLE_CONT  (CM_1 + CCIS_0 + SCS + CCIE)
#define TACCTL_DISABLE      (0)

#define TIMER_IRQ_VECTOR    16 /* IRQ number 8 */
#define TIMER_IRQ_VECTOR2   18 /* IRQ number 9 */

#define ISR_STACK_SIZE (512)

extern void* __isr_sp;

void timer_disable(void);

/*
 * Fire an IRQ after the specified number of cycles have elapsed. Timer_A TAR
 * register will continue counting from zero after IRQ generation.
 */
void timer_irq(int interval);

/*
 * Fire an IRQ after the specified number of cycles have elapsed. Timer_A TAR
 * register will continue counting from interval after IRQ generation.
 */
void timer_irqc(int interval);

/*
 * Operate Timer_A in continuous mode to act like a Time Stamp Counter.
 */
void timer_tsc_start(void);
int  timer_tsc_end(void);

/* Use for reactive OS support (sancus-support/src/main/main.c) */
void timer_init(void);


#define TIMER_ISR_ENTRY(fct)                                        \
__attribute__((naked)) __attribute__((interrupt(TIMER_IRQ_VECTOR))) \
void timerA_isr_entry(void)                                         \
{                                                                   \
    __asm__ __volatile__(                                           \
            "cmp #0x0, r1\n\t"                                      \
            "jne 1f\n\t"                                            \
            "mov &__isr_sp, r1\n\t"                                 \
            "push r15\n\t"                                          \
            "push r2\n\t"                                           \
            "1: push r15\n\t"                                       \
            "push r14\n\t"                                          \
            "push r13\n\t"                                          \
            "push r12\n\t"                                          \
            "push r11\n\t"                                          \
            "push r10\n\t"                                          \
            "push r9\n\t"                                           \
            "push r8\n\t"                                           \
            "push r7\n\t"                                           \
            "push r6\n\t"                                           \
            "push r5\n\t"                                           \
            "push r4\n\t"                                           \
            "push r3\n\t"                                           \
            "call #" #fct "\n\t"                                    \
            "pop r3\n\t"                                            \
            "pop r4\n\t"                                            \
            "pop r5\n\t"                                            \
            "pop r6\n\t"                                            \
            "pop r7\n\t"                                            \
            "pop r8\n\t"                                            \
            "pop r9\n\t"                                            \
            "pop r10\n\t"                                           \
            "pop r11\n\t"                                           \
            "pop r12\n\t"                                           \
            "pop r13\n\t"                                           \
            "pop r14\n\t"                                           \
            "pop r15\n\t"                                           \
            "reti\n\t"                                              \
            :::);                                                   \
}

#endif
