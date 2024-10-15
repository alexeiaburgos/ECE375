
;***********************************************************
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;*  	Rock Paper Scissors
;* 	Requirement:
;* 	1. USART1 communication
;* 	2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*	 Author: Alexei Burgos, Matthew Cummings
;*	   Date: 3/7/2024
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register

.def	txdata = r24
.def	rxdata = r23
.def	i = r17
.def	waitcnt = r25				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000                   ; Beginning of IVs
	    rjmp    INIT            	; Reset interrupt

.org	$0002
		rcall CHOICE
		reti

.org	$0032					;USART1, Rx complete interrupt
		rcall RECEIVE
		;SBI PORTB, PB7
		reti

.org    $0056                   ; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi mpr, low(RAMEND)	;	gets the low bits of the last address of SRAM
	out SPL, mpr			; loads low bits to stack pointer
	ldi	mpr, high(RAMEND)
	out	SPH, mpr			; repeats the process above but with the high bits

	;I/O Ports
	ldi mpr, 0b0000_1000 ; Set Port D pin 2 (RXD1) for input and Port D pin 3 (TXD1) for output
	out DDRD, mpr 

	;sets PORTD for input on PD7 and PD4
	ldi mpr, $00
	out DDRD, mpr
	ldi mpr, 0b1001_0000
	out PORTD, mpr

	;sets PORTB for output
	ldi mpr, 0b1111_1111
	out DDRB, mpr
	ldi	mpr, 0b0000_0000		; Initialize Port B Data Register
	out	PORTB, mpr		; so all Port B outputs are low

	;USART1
		;Set baudrate at 2400bps = UBBR = 416 (datasheet)
		;Enable receiver and transmitter
		;Set frame format: 8 data bits, 2 stop bits

	;setting baud rate at 300 with UBBR value of 1666
	ldi mpr, high(416)
	sts UBRR1H, mpr
	ldi mpr, low(416)
	sts UBRR1L, mpr

	;enable transreceiver functionality (need to check) 
	ldi mpr, 0b1001_1000	;enables RX complete interrupt, RX and TX enabled
	sts UCSR1B, mpr

	;Set frame format: 8 data bits, 2 stop bits, parity mode disabled, async (need to verify)
	ldi mpr, 0b0000_1110
	sts UCSR1C, mpr


	;setting TCNT1 to normal mode with prescaler to 1024
	ldi mpr, 0b0000_0000
	sts TCCR1A, mpr
	ldi mpr, 0b0000_0101
	sts TCCR1B, mpr

	;senses falling edge
	ldi mpr, 0b0000_0010
	sts EICRA, mpr

	;inits LCD
	rcall LCDINIT
	rcall LCDClr

	sei

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:

		 ;Poll PD7 and use interrupts for PD4
		
		
		;Displays welcome message
		rcall WELCOME_

		;Polls for PD7 input
		in mpr, PIND
		andi mpr, 0b1000_0000
		cpi mpr, 0b1000_0000
		breq MAIN	;if no input is received, then the program goes back to the beginning of MAIN

		rcall READYUP	;displays "Ready. Waiting for the opponent” and waits for data to be sent/received

		rcall PROCESS	;begins the rock, paper, scissors game and displays game results on LCD
		

		rjmp	MAIN	;restarts the game from the beginning

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: TRANSMITT
; Desc: Function that checks whether the transmitter is ready
;        and sends data from the transmitt buffer
;-----------------------------------------------------------
TRANSMITT:
	
	;checks if transmitter is ready
	lds mpr, UCSR1A
	sbrs mpr, UDRE1 ;checks if the UDRE1 bit is set (if set, buffer is ready to be written)
	rjmp TRANSMITT	;jumps back to beginning if not set and loops until it is set

	sts UDR1, txdata	;moves data to transmitt buffer and transmitt
	ret
;-----------------------------------------------------------
; Func: RECEIVE
; Desc: ISR for when data is received. Stores data from UDR1 to rxdata register
;-----------------------------------------------------------
RECEIVE:

	;clears rxdata register
	clr rxdata
	;moves recevied data into rxdata
	lds rxdata, UDR1
	ret
;-----------------------------------------------------------
; Func: WAIT_1_5sec
; Desc: Delays the program execution for approximately 1.5 seconds
;-----------------------------------------------------------
WAIT_1_5sec:

	; Load high byte of the timer counter value for 1.5 seconds
	ldi r18, high(53816)
	sts TCNT1H, r18

	; Load low byte of the timer counter value for 1.5 seconds
	ldi r18, low(53816)
	sts TCNT1L, r18

TIME_LOOP:

	; Check if Timer/Counter1 overflow flag (TOV1) is set
	SBIS TIFR1, TOV1 ; Skip the next instruction if TOV1 is not set
	rjmp TIME_LOOP ;If TOV1 is set, continue looping until it clears

	; If TOV1 is set, clear the overflow flag to prepare for the next use
	sbi TIFR1, TOV1
	
	ret


;-----------------------------------------------------------
; Func: LED_COUNTDOWN
; Desc: Sets LEDs (PB7-4) on and toggles them off after 1.5 seconds
;-----------------------------------------------------------
LED_COUNTDOWN:

	
	;turns on all the LEDs 7-4
	ldi mpr, 0b1111_0000
	out PORTB, mpr

	;turns off each LED after 1.5 second delay
	rcall WAIT_1_5sec
	cbi PORTB, PB7
	rcall WAIT_1_5sec
	cbi PORTB, PB6
	rcall WAIT_1_5sec
	cbi PORTB, PB5
	rcall WAIT_1_5sec
	cbi PORTB, PB4

	ret



;-----------------------------------------------------------
; Func: WriteLine
; Desc: Function that writes 16-byte string starting at
;        program memory location Z to data mem at Y
;-----------------------------------------------------------
WriteLine:
        ; Save variables by pushing them to the stack
        push mpr
        push i
        in mpr, SREG
        push mpr
        push ZL
        push ZH
        push YL
        push YH
        ; Execute the function here
        ldi i, $00                        ; create counter to manage repeating code
        rcall MoveLine                ; sub-function to copy first string to data memory
        rcall LCDWrite                    ; write from memory to LCD display
        ; Restore variables by popping them from the stack, in reverse order
        pop YH
        pop YL
        pop ZH
        pop ZL
        pop mpr
        out SREG, mpr
        pop i
        pop mpr
        ret                        ; End a function with RET
MoveLine:                    ; sub-function to move bytes from PM to DM
        inc i                    ; increment counter
        lpm mpr, Z+                ; read byte from program memory, incr Z
        st Y+, mpr                ; store byte/character in data memory for LCDWrite function, incr Y
        cpi i, $10                ; compare counter 'i' to 16
        brne MoveLine            ; repeat loop until counter reaches 16
        ret
; end of 'WriteLine' function
 
; Simple Subroutine to point Y to Ln1 of LCD
YToLn1:
        ldi YL, $00                        ; store address for location of first
        ldi YH, $01                        ; character on LCD screen
		ret
; Simple Subroutine to point Y to Ln2 of LCD
YToLn2:
        ldi YL, $10                        ; store address for location of 17th
        ldi YH, $01                        ; character on LCD screen (line 2 char 1)
		ret

;-----------------------------------------------------------
; Func:    ReadyUp
; Desc:    Prepares the system for interaction by displaying 
;          readiness messages on an LCD screen and ensuring
;          synchronization between communicating devices.
;-----------------------------------------------------------
READYUP:

        ; If needed, save variables by pushing to the stack
        push YH
        push YL
        push ZH
        push ZL

        ; Execute the function here

        ; Write Waiting Message to Screen
        ldi ZL, low(READY<<1)
        ldi ZH, high(READY<<1)
        rcall YToLn1
        rcall WriteLine
        ldi ZL, low(FOR<<1)
        ldi ZH, high(FOR<<1)
        rcall YToLn2
        rcall WriteLine


SEND_AGAIN:

		;loads SendReady data to txdata register
		ldi txdata, SendReady
		rcall TRANSMITT		;transmitts txdata 
		cpi rxdata, 0b11111111	;checks the received data, if not the same, branches to beginning of function to resend
		brne SEND_AGAIN

		;sbi PORTB, PB6
        ; Restore any saved variables by popping from stack
        pop ZL
        pop ZH
        pop YL
        pop YH
        ret
; end of 'READYUP' function

;-----------------------------------------------------------
; Func:   Process
; Desc:   This function manages the transmission and reception 
;         of the rock, paper, scissors choice between two devices.
;         It displays game start message on the LCD screen,
;         initiates countdown, and sends the choice made by the player.
;-----------------------------------------------------------
PROCESS:

        ; If needed, save variables by pushing to the stack
        push YH
        push YL
        push ZH
        push ZL

		;clears receive data register before getting choice
		clr rxdata
		clr txdata

		;enables INT0 interrupt for rock, paper, scissor choice
		ldi mpr, 0b0000_0001
		OUT EIMSK, mpr

        ; Write Game start message to Screen
		rcall LCDClr
        ldi ZL, low(GAME<<1)
        ldi ZH, high(GAME<<1)
        rcall YToLn1
        rcall WriteLine

		;starts countdown and delays for 1_5sec
		rcall LED_COUNTDOWN
		rcall WAIT_1_5sec
		
		 ;disables INT0 interrupt for rock, paper, scissor choice
		ldi mpr, 0b0000_0000
		OUT EIMSK, mpr

		;sends choice
		rcall TRANSMITT

		rcall WAIT_1_5sec

		; Display player's choice on LCD screen
		;checks if the rxdata is rock. If it is, displays rock on Line1
		cpi rxdata, 0
		brne DisplayP
		ldi ZL, low(rock<<1)
        ldi ZH, high(rock<<1)
		rcall YToLn1
		rcall WriteLine
		rjmp CHECK

DisplayP:

		;Check if the received data indicates the opponent chose "Paper"
		; If not "Paper", jump to check for "Scissors"
		
		; If opponent chose "Paper", prepare to display it on the LCD screen 
		cpi rxdata, 1
		brne DisplayS
		ldi ZL, low(Paper<<1)
        ldi ZH, high(Paper<<1)
		rcall YToLn1
		rcall WriteLine
		rjmp CHECK

DisplayS:
		
		; Check if the received data indicates the opponent chose "Scissors"
		cpi rxdata, 2	;debugging
		brne Check		;debugging
		ldi ZL, low(scissors<<1)
        ldi ZH, high(scissors<<1)
		rcall YToLn1
		rcall WriteLine


Check:
		;sbi PORTB, PB6
		;waits for 3 seconds and displays the winner
		rcall WAIT_1_5sec
		rcall WAIT_1_5sec
		rcall WINNER
		ret


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

Loop1:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop1			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine	



; simple wecome message subroutine, call from INIT:
WELCOME_:
    ldi ZL, low(WELCOME<<1) ;displays and write Welcome message onto LCD display
        ldi ZH, high(WELCOME<<1)
        rcall YToLn1
        rcall WriteLine
        ldi ZL, low(PLEASE<<1)
        ldi ZH, high(PLEASE<<1)
        rcall YToLn2
        rcall WriteLine
    ret
; end of welcome subroutine

;-----------------------------------------------------------
; Func:    CHOICE
; Desc:    Rock is encoded as $00, paper $01, scissors $02
;    This function rotates through them and displays selection
;-----------------------------------------------------------
CHOICE:
        ;increments choice data and branches if choice is out of range (overflow)
        inc txdata
        cpi txdata, $03
        brge OVERFLOW
CHOICECONT:
        cpi txdata, $01	; Check if choice is paper
        breq PAPERFUNC	; Branch if paper
        rjmp SCISSORSFUNC ; Otherwise, branch to scissors
CHOICELAST:
        rcall YToLn2	; Position Y register to the second line of the LCD
        rcall WriteLine	; Write the current choice on the LCD
		ldi waitcnt, 10	; Load wait count for debounce
        
		rcall Wait ;delays to avoid button debounce
		
		;clears the queue
		ldi mpr, 0b00001011
		out EIFR, mpr
        ret
OVERFLOW:
        ldi txdata, $00		; Reset choice to rock if overflow
        ldi ZL, low(ROCK<<1) ; Load the address of the "ROCK" message
        ldi ZH, high(ROCK<<1)
        rjmp CHOICELAST	; Jump to display the last choice
PAPERFUNC:
        ldi ZL, low(PAPER<<1) ; Load the address of the "PAPER" message
        ldi ZH, high(PAPER<<1)
        rjmp CHOICELAST
SCISSORSFUNC:
        ldi ZL, low(SCISSORS<<1) ; Load the address of the "SCISSORS" message
        ldi ZH, high(SCISSORS<<1)
        rjmp CHOICELAST
;----------
; END OF CHOICE FUNCTION
;----------
; END OF CHOICE FUNCTION

;-----------------------------------------------------------
; Func:    WINNER
; Desc:    Determines the winner of the rock, paper, scissors game
;          based on the selections made by the players, displaying
;          the result on an LCD screen. 
;-----------------------------------------------------------

WINNER:
		;SBI PORTB, PB6
       ;rcall LCDClr
		
		push mpr                ; save mpr value
        cp txdata, rxdata        ; check if move selections are equal
        brne WINCONT            ; report draw if selections are equal
        
		; point Z to the DRAW string
        ldi ZL, low(DRAW<<1)
        ldi ZH, high(DRAW<<1)
        rjmp WINEND                ; continue to end of function
WINCONT:
		; Check if mpr (player's selection) is $03 or greater
        mov mpr, txdata
        inc mpr
        cpi mpr, $03
        brge MPROV
WIN3:
		; Compare player's selection with opponent's selection
        cp mpr, rxdata ; If not equal, player wins
        brne WIN
        ldi ZL, low(LOST<<1) ; Point Z to the LOST string if player loses
        ldi ZH, high(LOST<<1)
WINEND:
		;writes the results onto the LCD
        rcall YToLn1	
        rcall WriteLine
        pop mpr                    ; restore mpr value
        rcall WAIT_1_5sec
        rcall WAIT_1_5sec
        ret                        ; END OF FUNCTION, return from here
WIN:
        ldi ZL, low(WON<<1)        ; Point Z to the WON string if player wins
        ldi ZH, high(WON<<1)    
        rjmp WINEND                ; resume program flow
MPROV:
        ldi mpr, $00            ; set mpr to $00 if it had value $03 or greater
        rjmp WIN3                ; resume program flow




;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
WELCOME:
.DB "Welcome!        "

PLEASE:
.DB "Please press PD7"

READY:
.DB "Ready. Waiting  "

FOR:
.DB "for the opponent"

GAME:
.DB "Game start      "

ROCK:
.DB "Rock            "

PAPER:
.DB "Paper           "

SCISSORS:
.DB "Scissors        "

LOST:
.DB "You lost        "

WON:
.DB "You Won!        "

DRAW:
.DB "DRAW            "


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
