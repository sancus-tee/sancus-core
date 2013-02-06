#ifndef MAIN_H
#define MAIN_H

#define __msp430_have_port3
#define __MSP430_HAS_PORT3__
#define __msp430_have_port4
#define __MSP430_HAS_PORT4__

#include <msp430.h>
// #include <signal.h>
#include <iomacros.h>

#define P3IN  (*(volatile char*)0x0018)
#define P3OUT (*(volatile char*)0x0019)
#define P3DIR (*(volatile char*)0x001A)
#define P3SEL (*(volatile char*)0x001B)

#define P4IN  (*(volatile char*)0x001C)
#define P4OUT (*(volatile char*)0x001D)
#define P4DIR (*(volatile char*)0x001E)
#define P4SEL (*(volatile char*)0x001F)

//PINS
//PORT1
#define TX              BIT1

//PORT2
#define RX              BIT2
#define LED             BIT1

//Port Output Register 'P1OUT, P2OUT':
#define P1OUT_INIT      TX              //Init Output data of port1
#define P2OUT_INIT      0               //Init Output data of port2
#define P3OUT_INIT      0               //Init Output data of port3

//Port Direction Register 'P1DIR, P2DIR':
#define P1DIR_INIT      TX              //Init of Port1 Data-Direction Reg (Out=1 / Inp=0)
#define P2DIR_INIT      ~RX             //Init of Port2 Data-Direction Reg (Out=1 / Inp=0)
#define P3DIR_INIT      0xff            //Init of Port3 Data-Direction Reg (Out=1 / Inp=0)

//Selection of Port or Module -Function on the Pins 'P1SEL, P2SEL'
#define P1SEL_INIT      0               //P1-Modules:
#define P2SEL_INIT      RX              //P2-Modules:
#define P3SEL_INIT      0               //P3-Modules:

//Interrupt capabilities of P1 and P2
#define P1IE_INIT       0               //Interrupt Enable (0=dis 1=enabled)
#define P2IE_INIT       0               //Interrupt Enable (0=dis 1=enabled)
#define P1IES_INIT      0               //Interrupt Edge Select (0=pos 1=neg)
#define P2IES_INIT      0               //Interrupt Edge Select (0=pos 1=neg)

#define IE_INIT         0
#define WDTCTL_INIT     WDTPW|WDTHOLD

#define BCSCTL1_FLL     XT2OFF|DIVA1|RSEL2|RSEL0
#define BCSCTL2_FLL     0
#define TACTL_FLL       TASSEL_2|TACLR
#define CCTL2_FLL       CM0|CCIS0|CAP

#define TACTL_AFTER_FLL TASSEL_2|TACLR|ID_0

#define BAUD            174

#endif // MAIN_H
