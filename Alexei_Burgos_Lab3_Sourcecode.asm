;***********************************************************
;*	This is the source code for Lab 3 of ECE 375

;*	This program loads strings from the program memory and loads them
;*	onto the LCD display's data memory. Buttons PD4, PD5, and PD7
;*	clear, load, and move the strings onto the LCD display

;*	 Author: Alexei Burgos
;*	   Date: 2/8/2024
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver

.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 25				; Time to wait in wait loop
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer (from Lab1 example code)
		ldi mpr, low(RAMEND)	;	gets the low bits of the last address of SRAM
		out SPL, mpr			; loads low bits to stack pointer
		ldi	mpr, high(RAMEND)
		out	SPH, mpr			; repeats the process above but with the high bits

		; Initialize LCD Display
		rcall LCDInit
		rcall LCDClr
	
		; Initialize Port D for input (from Lab1 example code)
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State


		;Clears X and Z registers for data manipulation
		clr zl
		clr zh
		clr xl
		clr xh

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		in mpr, PIND ; gets input from PIND in mpr
		andi mpr, 0b11110000 ;does AND Logic to check MDR from PinD input
		cpi mpr, 0b11100000 ;compares the bit values for PD4
		brne Button5 ;branches to Button5 if PD4 is not hit
		rcall ClearLCD ;clear LCD if PD4 hit
		rjmp MAIN ;jumps back to main

Button5:
		cpi mpr, 0b11010000
		brne Button7
		rcall DisplayNames ; Display the strings on the LCD Display
		rjmp MAIN

Button7:
		cpi mpr, 0b01110000
		brne MAIN
		rcall Shift ;shift the LCD text
		rjmp MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: LoadStrings
; Desc: Loads strings from program memory to data memory and displays string on LCD
;-----------------------------------------------------------
LoadStrings:							

		ldi zl, LOW(STRING1_BEG << 1) ;loads low bits of string1 to z register
		ldi zh, HIGH(STRING1_BEG << 1)
		ldi xl, low($0100)		;loads low/high bits of LCD memory address to x register
		ldi xh, high($0100)

		StartLoop:

			lpm mpr, z+	; loads string from z-register to program memory and post-increments to access the next address value
			st x+, mpr	; stores the address of LCD memory to data memory to access. Increments to get to the next address
			cpi zl, LOW(STRING1_END << 1)	; compares the address value of the z-register to the end of string1 to check whether the entire string has been loaded in the program memory
			brne StartLoop	;reloops until string has reached the end


		ldi zl, LOW(STRING2_BEG << 1) ;loads low bits of string1 to z register
		ldi zh, HIGH(STRING2_BEG << 1)
		ldi xl, low($0110)		;loads low/high bits of LCD memory address to x register
		ldi xh, high($0110)

		;loop2 repeats the same process as above but for the second string
		StartLoop2:

			lpm mpr, z+	; loads string from z-register to program memory and post-increments to access the next address value
			st x+, mpr	; stores the address of LCD memory to program memory to access the next address
			cpi zl, LOW(STRING2_END << 1)	; compares the address value of the z-register to the end of string1 to check whether the entire string has been loaded in the program memory
			brne StartLoop2	;reloops until string has reached the end

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: DisplayNames
; Desc: Displays the strings on LCD
;-----------------------------------------------------------
DisplayNames:							; Begin a function with a label
		; Save variables by pushing them to the stack


		; Execute the function here
		rcall LCDClr ;clears LCD
		rcall LoadStrings ;Loads the string from program to data memory
		rcall LCDBacklightOn ;turns on display
		rcall LCDWrite ;writes string onto LCD
		
		ret						; End a function with RET

;-----------------------------------------------------------


;-----------------------------------------------------------
; Func: ClearLCD
; Desc: Clears LCD contents
;-----------------------------------------------------------
ClearLCD:							

		; Execute the function here
		rcall LCDClr ;clears LCD
		rcall LCDBacklightOff ;turns of LED light

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Shift
; Desc: Shift lines towards the right
;-----------------------------------------------------------
Shift:

	ldi xl, low($0100) ;the loads the beginning low/high bits of LCD memory address to x register
	ldi xh, high($0100)
	
	ldi yl, low($011F) ;loads the last high/low bits of LCD memory to y register
	ldi yh, high($011F)
	ld r20, y ;stores last character of LCD memory in temp register r20

	ldi r17, $1F ;sets counter (i = 31) for loop1. We go up the 31st index of the LCD, not reaching the last 32nd index since we already stored that address

	Loop1: ;loop to push LCD memory to stack
		
		ld mpr, x+ ;loads the current index of memory of the x-register to mpr
		push mpr ;pushes mpr (current index of LCD memory) to stack
		dec r17 ;decrements counter to zero
		brne Loop1
	
	ldi xl, low($0120) ;loads the address that is higher than last LCD memory address ($011F), so that when we pre-decrement, we're begin at the end of the LCD memory ($011F)
	ldi xh, high($0120)

	ldi r17, $1F ;sets counter (i = 31). We decrement downwards from 31 until the first index. The first index will be replaced by the temp register

	Loop2: ;loop pops the stack and stores characters into LCD program memory
		
		pop mpr ;pops the current memory addresss to mpr
		st -x, mpr	;stores the memory from mpr (that was pop. from stack) to data memory. Pre-decrements as we start from the end of the LCD memory range, decrementing to the beginning
		dec r17 ;decrements the counter until 0
		brne Loop2

		rcall LCDWrite ;writes strings onto LCD
		;ldi		waitcnt, WTime	; Wait for 0.25 second
		;rcall	Wait			; Call wait function using the waitcnt register
		
	ldi xl, low($0100) ;loads the last high/low bits of the 1st index of LCD memory to x register
	ldi xh, high($0100)
	st x, r20 ;stores the memory contents of r17 into the x-register, which contains the first index of LCD program memory
	rcall LCDWrite ;writes final character to LCD
	
	ldi		waitcnt, WTime	; Wait for 0.25 second
	rcall	Wait			; Call wait function using the waitcnt register

	ret

;----------------------------------------------------------------
; Sub:	Wait (from Lab1 example code)
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING1_BEG:
.DB		"Alexei B"		; Declaring data in ProgMem
STRING1_END:

STRING2_BEG:
.DB		"HelloWorld"
STRING2_END:


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

