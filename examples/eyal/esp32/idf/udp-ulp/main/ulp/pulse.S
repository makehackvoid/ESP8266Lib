#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "config.h"
#include "io.h"

.macro	inc32 x		// uses: r2, r3

/* increment counter (2 words = 32 bits) */
/* note: zero(EQ) after increment is usigned overflow */
	move r2, \x			// r2 = &x

	ld r3, r2, 0			// increment x[0]
	add r3, r3, 1
	st r3, r2, 0

	jump 1f, eq			// overflow
	jump 2f
1:
	ld r3, r2, 4			// increment x[1]
	add r3, r3, 1
	st r3, r2, 4
2:
.endm

.macro	inc48 x		// uses: r2, r3

/* increment counter (3 words = 48 bits) */
/* note: zero(EQ) after increment is usigned overflow */
	move r2, \x			// r2 = &x

	ld r3, r2, 0			// increment x[0]
	add r3, r3, 1
	st r3, r2, 0

	jump 1f, eq			// overflow
	jump 3f
1:
	ld r3, r2, 4			// increment x[1]
	add r3, r3, 1
	st r3, r2, 4

	jump 2f, eq			// overflow
	jump 3f
2:

	ld r3, r2, 8			// increment x[2]
	add r3, r3, 1
	st r3, r2, 8
3:
.endm

.macro pulse gpio, count, noise
	.bss

	.global \count
\count:
	.long 0
	.long 0
	.long 0

	.global \noise
\noise:
	.long 0
	.long 0

.set state,     8f	// last state
.set countdown, 9f	// time since falling edge to debounce noise
.set runt_size, 15	// reject pulses much shorter than 600us
			// measured: about 46,000 loops/s -> 22us/loop
			// the DSO shows 600us shortest pulse at 1200us period (so 50% duty).
			// we need to reject pulses shorter than 600us ->27 loops
.set return,    7f

	.text

// check if low and counting down
	move r0, \gpio
	ld r0, r0, 0			// r0 = gpio
	jumpr return, 128, gt		// whatever, large number means -ve unsigned, no pin
	rsh r0, r1, r0			// r0 = r1 >> GPIO

	and r0, r0, 1			// r0 = r0 & 1	// r0 = bit
	jump 1f, eq			// low
	jump 3f				// high
1:
// ## state is low
	move r2, countdown		// check countdown counter
	ld r3, r2, 0
	or r3, r3, 0			// set ALU flags
	jump 3f, eq			// not counting down
// ## counting down
	sub r3, r3, 1
	st r3, r2, 0
	jump 2f, eq
	jump 3f
2:
// ## countdown expired (and still low), valid pulse
	inc48 \count			// reached zero, count pulse
3:
// ## any
// check if state changed
	move r2, state
	ld r3, r2, 0			// r3=old state
	add r3, r3, r0			// r0 is new state
	and r3, r3, 1			// r3=old^new
	jump return, eq			// if zero then no change, done

// ## new state
// save new state
	st r0, r2, 0			// save new state

// on falling edge start countdown to zero
// on rising  edge and waiting we have a runt (count as noise)
	jumpr 4f, 0, gt			// r0=new state
// ## falling edge
	move r0, runt_size
	move r2, countdown		// start countdown = runt_size
	st r0, r2, 0
	jump return
4:
// ## rising edge
	move r2, countdown		// check countdown
	ld r0, r2, 0			// r0=countdown
	jumpr return, 0, eq		// countdown = 0
// ## rising edge, countdown non zero

#ifdef MY_ULP_DEBUG	// find shortest runt pulse
	// if  longest < countdown -> countdown-longest > 0
	move r3, longest
	ld r2, r3, 0			// r2 = longest
	sub r2, r0, r2			// r2 = countdown-longest
	and r2, r2, 0x8000		// get sign bit
	jump 5f, eq			// eq (zero sign) means +ve
	jump 6f
5:
	st r0, r3, 0			// longest <- countdown
6:
#endif	// MY_ULP_DEBUG

	inc32 \noise			// count as noise
	jump return
8:			// state
	.long 0
	.long 0
9:			// countdown
	.long 0
7:
.endm

	.bss

//#ifdef MY_ULP_DEBUG	// only used in debug, but always referenced
	.global longest
longest:
	.long	0
	.global timer
timer:
	.long	0
	.long	0
	.long	0

//#endif	// MY_ULP_DEBUG

	.global p1_pin
p1_pin:
	.long	0	// set by ulp.c

	.global p2_pin
p2_pin:
	.long	0	// set by ulp.c

	.text

	.global entry
entry:
#ifdef MY_ULP_NULL
	jump entry
#endif

loop:
#ifdef MY_ULP_DEBUG	// count loops
	inc48 timer	// about 46,000 counts/s, 22us/loop
#endif

// The Arduino sketch uses:
//	hallSensor1Pin  34		// rain  on esp-32h
//	hallSensor2Pin  35		// water on esp-32h
// From the ULP they are:
//	GPIO34 RTC_GPIO4
//	GPIO35 RTC_GPIO5

	/* read the RTC pins and store it into global variables ; just read the pin register once and store it into R1 */
	READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S, 16)
	move r1, r0			// r1 = RTC GPIO bits

	pulse p1_pin, p1_count, p1_noise
	pulse p2_pin, p2_count, p2_noise

	jump loop

