;***********************************************************
;*	Sourcecode for Lab 5 of ECE 375
;*
;*	 Author: Alexei Burgos
;*	   Date: 2/29/2024
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;************************************************************
;* Variable and Constant Declarations
;************************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	rcnt = r23				;right counter
.def	lcnt = r24				;left counter

.equ	WTime = 10				; Time to wait in wait loop.
.equ	BTime = 10				; time to wait in loop to reverse (which is now doubled)

.equ	WskrR = 4				; Right Whisker Input Bit
.equ	WskrL = 5				; Left Whisker Input Bit
.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt

.org $0002
	
	;calls ISR 
	rcall HitRight

	reti
.org $0004
	
	;calls ISR
	rcall HitLeft
	reti
.org $0008
	rcall ClrCnt
	reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr, low(RAMEND)	;	gets the low bits of the last address of SRAM
		out SPL, mpr			; loads low bits to stack pointer
		ldi	mpr, high(RAMEND)
		out	SPH, mpr			; repeats the process above but with the high bits

		; Initialize LCD Display
		rcall LCDInit
		rcall LCDClr

		;inits count registers with 0s
		ldi rcnt, $0
		ldi lcnt, $0

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize TekBot Forward Movement
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
		

		;displays initialized counters onto display
		rcall DisplayNames
		
		/*
		ldi mpr, 0b00000001		;loads bits to mpr that set the EISMK to 1 to enable
		out EIMSK, mpr			;enables EISMK INT0
		out EIMSK+1, mpr		;enables EISMK INT1
		out EIMSK+3, mpr		;enables EISMK INT3

		*/


		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; TODO
		sbi PORTB, PB5
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		cbi PORTB, PB5
		rcall	Wait			; Call wait function
		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the
;	left whisker interrupt, one to handle the right whisker
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;----------------------------------------------------------------
; Sub:	HitRight (from lab1 example code)
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:

		;disable interrupts as we perform the ISR
		ldi mpr, 0b0000_0000
		out EIMSK, mpr
	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		rcall INC_Rcnt		;increments the right hit counter


		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		;enables interrupts as we exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr

		ret				; Return from subroutine



;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:


		;disable interrupts as we perform the ISR
		ldi mpr, 0b00000000
		out EIMSK, mpr

		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		;increments left counter
		rcall INC_Lcnt

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		;enables interrupts as exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr

		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
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

		mov mpr, rcnt ;copies the right counter value to mpr
		rcall Bin2ASCII ;converts binary value to ASCII for LCD


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

		mov mpr, lcnt	;same is repeated from the right counter but for the left counter
		rcall Bin2ASCII

		ret						; End a function with RET


;-----------------------------------------------------------
; Func: INC_Rcnt
; Desc: Increments right counter and displays count onto LCD
;-----------------------------------------------------------
INC_Rcnt:							; Begin a function with a label

		inc rcnt	;increments the right counter register
		rcall DisplayNames ;displays counter onto LCD

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: INC_Lcnt
; Desc: Increments left counter and displays count onto LCD
;-----------------------------------------------------------
INC_Lcnt:							; Begin a function with a label

		inc lcnt	;increments the left count
		rcall DisplayNames ;display counter onto LCD

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: ClrCnt
; Desc: Clears the right and left counters on the LCD
;-----------------------------------------------------------
ClrCnt:							; Begin a function with a label

		;disable interrupts as we perform the ISR
		ldi mpr, 0b00000000
		out EIMSK, mpr

		;clears the count registers and re-displays the cleared count
		clr rcnt
		clr lcnt
		rcall DisplayNames

		;enables interrupts as exit the ISR
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out EIMSK, mpr

		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr

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

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here
STRING1_BEG:
.DB		"Hit R:"		; Declaring data in ProgMem
STRING1_END:

STRING2_BEG:
.DB		"Hit L:"
STRING2_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

