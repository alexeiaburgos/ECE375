;***********************************************************
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;*	 Author: Alexei Burgos
;*	   Date: 2/15/2024
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr2 = r15
.def	mpr = r16				; Multipurpose register
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable
.def	Z1 = r5					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter
.def	rcnt = r20
.def	lcnt = r21

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine

		; Initialize Stack Pointer
		ldi mpr, low(RAMEND)	;	gets the low bits of the last address of SRAM
		out SPL, mpr			; loads low bits to stack pointer
		ldi	mpr, high(RAMEND)
		out	SPH, mpr			; repeats the process above but with the high bits


		; TODO

		clr		zero			; Set the zero register to zero, maintain
										; these semantics, meaning, don't
										; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		; Call function to load ADD16 operands
		rcall LoadADD
		nop ; Check load ADD16 operands (Set Break point here #1)

		; Call ADD16 function to display its results (calculate FCBA + FFFF)
		rcall ADD16
		nop ; Check ADD16 result (Set Break point here #2)


		; Call function to load SUB16 operands
		rcall LoadSUB
		nop ; Check load SUB16 operands (Set Break point here #3)

		; Call SUB16 function to display its results (calculate FCB9 - E420)
		rcall SUB16
		nop ; Check SUB16 result (Set Break point here #4)


		; Call function to load MUL24 operands
		rcall LoadMUL
		nop ; Check load MUL24 operands (Set Break point here #5)

		; Call MUL24 function to display its results (calculate FFFFFF * FFFFFF)
		rcall MUL24
		nop ; Check MUL24 result (Set Break point here #6)

		; Call the COMPOUND function, loading occurs within COMPOUND function
		rcall COMPOUND
		nop ; Check COMPOUND result (Set Break point here #7)


DONE:	rjmp	DONE			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
		; Load beginning address of first operand into 

		/*
	

		ldi ZL, low(OperandA << 1)		;get low bytes of 1st operand from program memory and store into Z
		ldi ZH, high(OperandA << 1)		;get high bytes of 1st operand from program memory and store into Z

		ldi XL, low(ADD16_OP1)		;get low bytes of 1st operand from program memory and store into Z
		ldi XH, high(ADD16_OP1)		;get high bytes of 1st operand from program memory and store into Z

		ldi YL, low(ADD16_OP2)		;get low bytes of 1st operand from program memory and store into Z
		ldi YH, high(ADD16_OP2)		;get high bytes of 1st operand from program memory and store into Z

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		st X+, mpr			;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z						;load high bytes of program memory to pr
		st X, mpr		;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandB << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandB << 1)		

		lpm mpr, z+						
		st Y+, mpr				
		lpm mpr, z
		st Y, mpr

		*/


		;clr xl
		;clr xh
		;clr yl
		;clr yh
		
		
		;ldi		XL, low(ADD16_OP1)	; Load low byte of address
		;ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		;ldi		YL, low(ADD16_OP2)
		;ldi		YL, high(ADD16_OP2)

		; Load beginning address of result into Z
		ldi	ZL, low(ADD16_Result)
		ldi ZH, high(ADD16_Result)

		ldi XL, low(ADD16_OP1)		;get low bytes of 1st operand from program memory and store into Z
		ldi XH, high(ADD16_OP1)		;get high bytes of 1st operand from program memory and store into Z

		ldi YL, low(ADD16_OP2)		;get low bytes of 1st operand from program memory and store into Z
		ldi YH, high(ADD16_OP2)		;get high bytes of 1st operand from program memory and store into Z
		
		; Execute the function
		ld mpr, X+				;load mpr with the first (low) byte of op1, and post increment to access the high byte of the 1st operand
		ld mpr2, Y+				;load mpr2 with the 1st (low) byte of op2
		add mpr2, mpr			;adds the operands and result goes mpr2
		st Z+, mpr2				; stores the result in mpr2 in data memory and post increment to access the high byte
		ld mpr, X				;load mpr with second byte (high) of op1
		ld mpr2, Y				;load mpr with second high byte of op2
		adc mpr2, mpr			; adds the operands with carry and result goes to mpr2
		st Z+, mpr2				;stores result in data memory
		brcc EXIT				;if not carry is present, function branches to exit and return
		
		ldi r21, $01			;loads hex value of 1 to register r21, which represent the carry bit that is present from SREG
		st	Z, r21				;stores the carry into data memory
		
		EXIT:
			
			ret

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;       result. Always subtracts from the bigger values.
;-----------------------------------------------------------
SUB16:
		; Load beginning address of first operand into 

		/*
		ldi ZL, low(OperandC << 1)		;get low bytes of 1st operand from program memory and store into Z
		ldi ZH, high(OperandC << 1)		;get high bytes of 1st operand from program memory and store into Z

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		sts low(SUB16_OP1), mpr			;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z						;load high bytes of program memory to pr
		sts high(SUB16_OP1), mpr		;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandD << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandD << 1)		

		lpm mpr, z+						
		sts low(SUB16_OP2), mpr				
		lpm mpr, z
		sts high(SUB16_OP2), mpr
		*/
		
		; Load beginning address of result into Z
		ldi	ZL, low(SUB16_Result)
		ldi ZH, high(SUB16_Result)

		; Load beginning address of 1st operand into X
		ldi		XL, low(SUB16_OP1)	; Load low byte of address
		ldi		XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)
		ldi		YH, high(SUB16_OP2)

		ld mpr, X+				;load mpr with the first (low) byte of op1, and post increment to access the high byte of the 1st operand
		ld mpr2, Y+				;load mpr2 with the 1st (low) byte of op2
		sub mpr, mpr2			;subtract the low bytes without carry and store in mpr
		st Z+, mpr				;stores the result in mpr2 in data memory and post increment to access the high byte
		ld mpr, X				;load mpr with the high byte of op1
		ld mpr2, Y				;load mpr2 with high byte of op2
		brcc NoCarry			;if sub operation resulted in a borrow (represented by the carry), the program will not branch and subtract with carry in the high bits
		sbc mpr, mpr2			;subtract mpr from mpr2 with carry (due to the borrow from the previous subtraction)
		
		NoCarry:				;if not carry is present, meaning no borrow during subtraction, the program will branch NoCarry where mpr and mpr2 will subtracted with no carry

			sub mpr, mpr2

		st Z, mpr				;stores the high bytes of the subtraction result into data memory 

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit
;       result.
;-----------------------------------------------------------
MUL24:
;* - Simply adopting MUL16 ideas to MUL24 will not give you steady results. You should come up with different ideas.
		; Execute the function here

		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(MUL24_OP1)	; Load low byte
		ldi		YH, high(MUL24_OP1)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MUL24_Result)	; Load low byte
		ldi		ZH, high(MUL24_Result); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(MUL24_OP2)	; Load low byte
		ldi		XH, high(MUL24_OP2)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter. Since we have 24 bits, we will need to perform this loop 3 times for byte (8)
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A		need to account for carry here
		
		brcs CarryPresent		;if carry is set, it branches to the Carry Present label
		CarryPresent_back:
	;	CarryPresent:
			
	;		adiw	ZH:ZL, 1		; Z <= Z + 1
	;		ldi r21, $01
	;		st z, r21
	;		sbiw	ZH:ZL, 1		;Z <= Z - 1

		st		Z, A			; Store third byte to memory	
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		
		; End outer for loop and jumps to the end
		jmp mul_done

		;if carry is present, the z-register stores the carry
		CarryPresent:
			
			adiw	ZH:ZL, 1		; Z <= Z + 1
			ldi r21, $01			;loads carry bit to temp register
			st z, r21				;stores carry bit to memory
			sbiw	ZH:ZL, 1		;Z <= Z - 1
			jmp 		CarryPresent_back ;jumps back to the inner loop
		
		mul_done:

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;       A - Operand A is gathered from address $0101:$0100
;       B - Operand B is gathered from address $0103:$0102
;       Res - Result is stored in address
;             $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A		need to account for carry here
		st		Z, A			; Store third byte to memory	
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: LoadADD
; Desc: Loads ADD operands from program memory to data memory
;-----------------------------------------------------------
LoadADD:							; Begin a function with a label
		; Save variable by pushing them to the stack

		ldi ZL, low(OperandA << 1)		;get low bytes of 1st operand from program memory and store into Z
		ldi ZH, high(OperandA << 1)		;get high bytes of 1st operand from program memory and store into Z

		ldi XL, low(ADD16_OP1)		;get low bytes of 1st operand from data memory
		ldi XH, high(ADD16_OP1)		;get high bytes of 1st operand from data memory

		ldi YL, low(ADD16_OP2)		;get low bytes of 2nd operand from data memory
		ldi YH, high(ADD16_OP2)		;get high bytes of 2nd operand from data memory

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		st X+, mpr			;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z						;load high bytes of program memory to pr
		st X, mpr		;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandB << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandB << 1)		

		lpm mpr, z+						
		st Y+, mpr				
		lpm mpr, z
		st Y, mpr

		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


		;-----------------------------------------------------------
; Func: LoadSUB
; Desc: Loads SUB operands from program memory to data memory
;-----------------------------------------------------------
LoadSUB:							; Begin a function with a label
		; Save variable by pushing them to the stack

		ldi ZL, low(OperandC << 1)		;get low bytes of 1st operand from program memory and store into Z
		ldi ZH, high(OperandC << 1)		;get high bytes of 1st operand from program memory and store into Z

		ldi XL, low(SUB16_OP1)		;get low bytes of 1st operand from data memory
		ldi XH, high(SUB16_OP1)		;get high bytes of 1st operand from data memory

		ldi YL, low(SUB16_OP2)		;get low bytes of 2nd operand from data memory
		ldi YH, high(SUB16_OP2)		;get low bytes of 2nd operand from data memory

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		st X+, mpr			;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z						;load high bytes of program memory to pr
		st X, mpr		;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandD << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandD << 1)		

		lpm mpr, z+						
		st Y+, mpr				
		lpm mpr, z
		st Y, mpr

		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET



;-----------------------------------------------------------
; Func: LoadMUL
; Desc: Loads MUL operands from program memory to data memory
;-----------------------------------------------------------
LoadMUL:							; Begin a function with a label
		; Save variable by pushing them to the stack

		ldi ZL, low(OperandE1 << 1)		;get low bytes of 1st operand from program memory 
		ldi ZH, high(OperandE1 << 1)		;get high bytes of 1st operand from program memory 

		ldi XL, low(MUL24_OP1)		;get low bytes of 1st operand from data memory
		ldi XH, high(MUL24_OP1)		;get high bytes of 1st operand from data memory

		ldi YL, low(MUL24_OP2)		;get low bytes of 1st operand from data memory
		ldi YH, high(MUL24_OP2)		;get high bytes of 1st operand from data memory

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		st X+, mpr						;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z+						;load middle bytes of program memory to store
		st X+, mpr
		lpm mpr, z						;load high bytes of program memory to store
		st X, mpr
				;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandF1 << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandF1 << 1)		

		lpm mpr, z+						;loads low byte
		st Y+, mpr				
		lpm mpr, z+						;load middle bytes 
		st Y+, mpr
		lpm mpr, z						;load high bytes 
		st Y, mpr

		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((G - H) + I)^2
;       by making use of SUB16, ADD16, and MUL24.
;
;       D, E, and F are declared in program memory, and must
;       be moved into data memory for use as input operands.
;
;       All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:							; Begin a function with a label
		; Save variable by pushing them to the stack

		ldi ZL, low(OperandG << 1)		;get low bytes of 1st operand from program memory 
		ldi ZH, high(OperandG << 1)		;get high bytes of 1st operand from program memory 

		ldi XL, low(SUB16_OP1)		;get low bytes of 1st operand from data memory
		ldi XH, high(SUB16_OP1)		;get high bytes of 1st operand from data memory

		ldi YL, low(SUB16_OP2)		;get low bytes of 1st operand from data memory
		ldi YH, high(SUB16_OP2)		;get high bytes of 1st operand from data memory

		lpm mpr, z+						;loads low bytes high of program memory from z address to mpr and post increment z to access high byte
		st X+, mpr						;stores the low bytes of program memory to the low bytes of data memory
		lpm mpr, z+						;load high bytes of program memory to pr
		st X+, mpr						;stores the high bytes of program memory to the high bytes of data memory

		ldi ZL, low(OperandH << 1)		;Process from above is repeated but for the second operand
		ldi ZH, high(OperandH << 1)		

		lpm mpr, z+						
		st Y+, mpr				
		lpm mpr, z+						;load high bytes of program memory to pr
		st Y+, mpr

		rcall SUB16						;performs SUB16 execution

		ldi ZL, low(SUB16_Result) ;		loads stores sub16 result for add16 operand
		ldi ZH, high(SUB16_Result)
		ld mpr, Z+
		;ld r17,Z

		sts ADD16_OP1, mpr ; stores sub16 result into add16 operand1 afterwards do ld mpr, Z and then sts ADD16_OP1+1, mpr
		ld mpr, Z		;get high byte and then stores
		;sts ADD16_OP1+1, r17
		sts ADD16_OP1 + 1, mpr
		;sts high(ADD16_OP1), ZH

		ldi ZL, low(OperandI << 1)		;Process is repeated above before the OperandI in program memory
		ldi ZH, high(OperandI << 1)		

		ldi YL, low(ADD16_OP2)			;grabs data memory
		ldi YH, high(ADD16_OP2)		

		lpm mpr, z+						;loads low bytes		
		st Y+, mpr				
		lpm mpr, z+						;load high bytes 
		st Y+, mpr

		ldi mpr, $0						;clears carry bit from previous ADD16 call
		sts ADD16_Result + 2, mpr

		rcall ADD16						;calls add16 function to perform addition

		ldi ZL, low(ADD16_Result)		;loads result of add16
		ldi ZH, high(ADD16_Result)
		
		ld mpr, Z+						;store result of add16 into MUL24 operands
		sts MUL24_OP1, mpr				;stores low byte
		sts MUL24_OP2, mpr
		ld mpr, Z+
		sts MUL24_OP1+1, mpr			;stores middle byte
		sts MUL24_OP2+1, mpr
		ld mpr, Z+
		sts MUL24_OP1+2, mpr			;stores high byte
		sts MUL24_OP2+2, mpr

		ldi mpr, 0						;loads 0 to mpr to clear MUL24 result
		ldi r21, 6						;counter for loop, 6 times for 6 bytes of the MUL24 result
		ldi ZL, low(MUL24_Result)		;loads MUL24 result
		ldi ZH, high(MUL24_Result)

		;loops that clears previous MUL24 result
		L1:

			st z+, mpr					;stores zero to current bit
			dec r21						;decrements counter 
			brne L1						;loops until r21 = 0

		

		/*
		sts MUL24_OP2, mpr
		
		ld mpr, Z+
		sts MUL24_OP1+1, mpr
		sts MUL24_OP2+1, mpr ;need to account for carry

		ld mpr, Z+			;accounting for carry
		sts MUL24_OP1+2, mpr
		sts MUL24_OP2+2, mpr
		*/

		rcall MUL24						;calls MUL24 function for final COMPOUND Operation

	; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;*	Do not  section.
;***********************************************************
; ADD16 operands
OperandA:
	.DW 0xFCBA
OperandB:
	.DW 0xFFFF

; SUB16 operands
OperandC:
	.DW 0XFCB9
OperandD:
	.DW 0XE420

; MUL24 operands
OperandE1:
	.DW	0XFFFF
OperandE2:
	.DW	0X00FF
OperandF1:
	.DW	0XFFFF
OperandF2:
	.DW	0X00FF

; Compoud operands
OperandG:
	.DW	0xFCBA				; test value for operand G
OperandH:
	.DW	0x2022				; test value for operand H
OperandI:
	.DW	0x21BB				; test value for operand I

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.
.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0130
SUB16_OP1:					; the same from above is repeated for SUB16
		.byte 2
SUB16_OP2:
		.byte 2
SUB16_Result:
		.byte 2

.org	$0140
MUL24_OP1:
		.byte 3				;3 bytes are allocated for 24-bits for the operands and result
MUL24_OP2:
		.byte 3
MUL24_Result:
		.byte 6

.org	$0150
COM_OP_G:
	.byte 2
COM_OP_H:
	.byte 2
COM_OP_I:
	.byte 2
COM_ADD_Result:
	.byte 3
COM_MUL_Result:
	.byte 6


;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
