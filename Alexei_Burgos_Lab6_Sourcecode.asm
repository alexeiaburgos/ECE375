;***********************************************************
;*
;*	Sourcecode for Lab 6 of ECE 375
;*
;*	 Author: Alexei Burgos
;*	   Date: 3/7/2024
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	spd = r23				; register that stores speed level count

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		
		;Speeds up motor	
		rcall SPEED_UP
		reti

.org $0004
	
		;slows down motor
		rcall SPEED_DOWN
		reti

.org $0008
		
		;sets motor to max speed
		rcall SPEED_MAX
		reti

.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi mpr, low(RAMEND)	;	gets the low bits of the last address of SRAM
		out SPL, mpr			; loads low bits to stack pointer
		ldi	mpr, high(RAMEND)
		out	SPH, mpr			; repeats the process above but with the high bits

		;inits count registers with 0s
		ldi spd, $0
		ldi r17, MovFwd
		; Configure I/O ports

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low


		; Configure External Interrupts, if needed

		; Configure 16-bit Timer/Counter 1A and 1B - Fast PWM, 8-bit mode, no prescaling
		ldi mpr, 0b1111_0001	;loads bit pattern for correct WGM and COM. Sets WGM to 8-bit PWM, Sets COM to non-inverting
		sts TCCR1A, mpr	
		ldi mpr, 0b0000_1001	;loads bit pattern for correct CS and COM. Sets COM to non-inverting and disables pre-scaler
		sts TCCR1B, mpr	

		;sets ORC values to init speed value of 0. Sets motor to halt (0 speed)
		sts OCR1AH, spd		;loads the high byte to high(ORC1A)
		sts OCR1AL, spd		;loads the low byte to low(OCR1A)

		sts OCR1BH, spd		;loads the high byte to high(ORC1B)
		sts OCR1BL, spd		;loads the low byte to low(OCR1B)

		; Set TekBot to Move Forward (PB7 and PB4) (1<<EngDirR|1<<EngDirL) on Port B
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		; Initialize external interrupts
		; Set the Interrupt Sense Control to falling edge
		;loads bits to mpr that correspond to falling edge
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC31)|(0<<ISC30)
		sts EICRA, mpr

		; Configures the External Interrupt Mask so that EISMK enables interrupts
		ldi mpr, 0b0000_1011
		out EIMSK, mpr

		; Enable global interrupts 
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:

		in mpr, PIND
		
								; if pressed, adjust speed
								; also, adjust speed indication

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	SPEED_DOWN
; Desc:	This function slows down the motor by decrementing
;		the speed by 1
;-----------------------------------------------------------
SPEED_DOWN:	


		;disable interrupts as we perform the ISR
		ldi mpr, 0b0000_0000
		out EIMSK, mpr

		;checks if speed is at 0, skips to avoid overflow from decrementing 0
		cpi spd, 0
		breq Skip1

		;decrements speed counter
		dec spd

		;updates the counter OCR values to modify the LEDs
		rcall UPDATE_LEDS

Skip1:

		;enables interrupts as we exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr
		ret						; End a function with RET
			


;-----------------------------------------------------------
; Func:	SPEED_UP
; Desc:	This function speeds up the motor by incrementing
;		the speed by 1
;-----------------------------------------------------------
SPEED_UP:	

		;disable interrupts as we perform the ISR
		ldi mpr, 0b0000_0000
		out EIMSK, mpr

		;increments speed counter, if speed count = 15, we skip increment to avoid overflow
		cpi spd, 15
		BREQ Skip2
		inc spd

		;updates the counter OCR values to modify the LEDs
		rcall UPDATE_LEDS

Skip2:

		;enables interrupts as we exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	SPEED_MAX
; Desc:	Sets motor to max speed by setting speed count to max
;		value of 15
;-----------------------------------------------------------
SPEED_MAX:

		;disable interrupts as we perform the ISR
		ldi mpr, 0b0000_0000
		out EIMSK, mpr

		;sets speed counter to max speed of 15
		ldi spd, 15
		
		;updates counter and LED values
		rcall UPDATE_LEDS

		;enables interrupts as we exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	UPDATE_LEDS
; Desc:	Modifies to counters by setting the OCRnX registers
;		to the value of current speed count register
;-----------------------------------------------------------

UPDATE_LEDS:

		;sets the intensity of LED by mult. speed value with 17 for each speed step 
		ldi mpr, 17
		mul spd, mpr

		;loads the intensity
		sts OCR1AH, r1		;loads the high byte to high(ORC1)
		sts OCR1AL, r0		;loads the low byte to low(OCR1)

		sts OCR1BH, r1		;loads the high byte to high(ORC1)
		sts OCR1BL, r0		;loads the low byte to low(OCR1)

		;copies speed count to mpr
		mov mpr, spd

		;performs logical OR operations with PB7 and PB4 to set the valye for the 3:0 LEDs
		ORI mpr, MovFwd
		out PORTB, mpr		;loads result of OR to LEDs

		ret
;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program
