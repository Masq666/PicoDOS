; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT HANDLERS
;
; Functions:
;	os_install_interrupts
;	int20							- Is handled by int21 func 4C
;	int21
;	int29
; ==================================================================
os_install_interrupts:
	push  ds			    		; Save DS
	cli				    			; Turn off int's
	xor   ax, ax
	mov   ds, ax			    	; 0 DS
	mov   word [ds:20h*4],int20	    ; load int vector with int20h address
	mov   word [ds:20h*4+2],cs	    ; + CS

	mov   word [ds:21h*4],int21	    ; load int vector with int21h address
	mov   word [ds:21h*4+2],cs	    ; + CS
	
	mov   word [ds:29h*4],int29	    ; load int vector with int29h address
	mov   word [ds:29h*4+2],cs	    ; + CS
	
	sti				    			; Turn on int's
	pop   ds			    		; restore DS
	ret				    			; Return

; ==================================================================
; INT 21h Jump Table
; ==================================================================
int21:
	sti				    		; Int's on
	cmp   ah, 00h			    ; Does AH = 0
	je    int21_00			    ; Terminate program
	cmp   ah, 01h			    ; Does AH = 1
	je    int21_01			    ; Read char with echo
	cmp   ah, 02h			    ; Does AH = 2
	je    int21_02			    ; Write char
	cmp   ah, 03h			    ; Is AH = 03h
	je    int21_03			    ; Read Char from STDAUX (COM1)
	cmp   ah, 04h			    ; Is AH = 04h
	je    int21_04			    ; Write Char to STDAUX (COM1)
	cmp   ah, 05h
	je    int21_05
	cmp   ah, 06h			    ; Does AH = 6   (Added by asiekierka)
	je    int21_06			    ; Direct console output
	cmp   ah, 7h			    ; Does AH = 7
	je    int21_07			    ; Read char without echo
	cmp   ah, 08h			    ; Does AH = 8
	je    int21_07			    ; Read char
	cmp   ah, 09h			    ; Does AH = 9
	je    int21_09			    ; Write string
	cmp   ah, 0Ah			    ; Does AH = 0x0A
	je    int21_0A			    ; Enter string
	cmp   ah, 0Bh			    ; Is AH = 0Bh
	je    int21_0B			    ; GET STDIN STATUS
	cmp   ah, 0Eh			    ; Is AH = 0Eh
	je    int21_0E			    ; SELECT DEFAULT DRIVE
	cmp   ah, 19h			    ; Does AH = 0x19
	je    int21_19			    ; Current drive
	cmp   ah, 20h
	je    int21_20
	cmp   ah, 25h			    ; Does AH = 0x25
	je    int21_25			    ; Set int vec
	cmp   ah, 2Ah			    ; Does AH = 0x2A
	je    int21_2A			    ; Get date
	cmp   ah, 2Bh			    ; Does AH = 0x2B
	je    int21_2B			    ; Set date
	cmp   ah, 2Ch			    ; Does AH = 0x2C
	je    int21_2C			    ; Get time
	cmp   ah, 2Dh			    ; Does AH = 0x2D
	je    int21_2D			    ; Set time
	cmp   ah, 30h			    ; Does AH = 0x30
	je    int21_30			    ; Get dos version
	cmp   ah, 35h			    ; Does AH = 0x35
	je    int21_35			    ; Get int vec
	cmp   ah, 48h			    ; Does AH = 0x48
	je    int21_48			    ; Alloc ram memory
	cmp   ah, 4Bh			    ; Does AH = 4Bh
	je    int21_4B			    ; Load and/or execute program
	cmp   ah, 4Ch			    ; Does AH = 0x4C
	je    int21_4C			    ; Terminate program
	cmp   ah, 4Dh			    ; Does AH = 4Dh
	je    int21_4C			    ; GET RETURN CODE (ERRORLEVEL)
	jmp int21_error

; ==================================================================
; INCLUDE INT 21h Functions
; ==================================================================
	include "kernel/int21/func_01.asm"  ; 01h - READ CHARACTER FROM STANDARD INPUT, WITH ECHO
	include "kernel/int21/func_02.asm"  ; 02h - WRITE CHARACTER TO STANDARD OUTPUT
	include "kernel/int21/func_03.asm"  ; 03h - READ CHARACTER FROM STDAUX
	include "kernel/int21/func_04.asm"  ; 04h - WRITE CHARACTER TO STDAUX
	include "kernel/int21/func_05.asm"  ; 05h - WRITE CHARACTER TO PRINTER
	include "kernel/int21/func_06.asm"  ; 06h - DIRECT CONSOLE OUTPUT
	include "kernel/int21/func_07.asm"  ; 07h - READ CHARACTER FROM STANDARD INPUT, WITHOUT ECHO
	include "kernel/int21/func_09.asm"  ; 09h - WRITE STRING TO STANDARD OUTPUT
	include "kernel/int21/func_0A.asm"  ; 0Ah - BUFFERED INPUT
	include "kernel/int21/func_0B.asm"  ; 0Bh - GET STDIN STATUS
	include "kernel/int21/func_0E.asm"  ; 0Eh - SELECT DEFAULT DRIVE
	include "kernel/int21/func_19.asm"  ; 19h - GET CURRENT DEFAULT DRIVE
	include "kernel/int21/func_20.asm"  ; 20h - DUMP REGISTERS TO STDOUT (PicoDOS ONLY!)
	include "kernel/int21/func_25.asm"  ; 25h - SET INTERRUPT VECTOR
	include "kernel/int21/func_2A.asm"  ; 2Ah - GET SYSTEM DATE
	include "kernel/int21/func_2B.asm"  ; 2Bh - SET SYSTEM DATE
	include "kernel/int21/func_2C.asm"  ; 2Ch - GET SYSTEM TIME
	include "kernel/int21/func_2D.asm"  ; 2Dh - SET SYSTEM TIME
	include "kernel/int21/func_30.asm"  ; 30h - GET DOS VERSION
	include "kernel/int21/func_35.asm"  ; 35h - GET INTERRUPT VECTOR
	include "kernel/int21/func_41.asm"  ; 41h - UNLINK - DELETE FILE
	include "kernel/int21/func_4B.asm"  ; 4Bh - LOAD AND/OR EXECUTE PROGRAM
	include "kernel/int21/func_4C.asm"  ; 4Ch - "EXIT" - TERMINATE WITH RETURN CODE
	include "kernel/int21/func_4D.asm"  ; 4Dh - GET RETURN CODE (ERRORLEVEL)
	
; ==================================================================
; INT 29h Handler - Fast Console Output
; ==================================================================
int29:
	call os_print_char		    ; Call our print char function
	iret

;====================================================;
; alloc ram memory				     ;
;====================================================; 
int21_48:
	mov   ax,word [cs:end_memory]	   ; Move whats in the var [cs:end_memory] into AX
	add   ax,bx			   ; Add BX to the var
	cmp   ax,word [cs:top_memory]	   ; Is it more than whats in the var [cs:top_memory] ?
	jg    .error			   ; If yes jump .error label
	mov   word [cs:top_memory],ax	   ; If not it is now, put in [cs:top_memory] var.
.error:
	mov   bx, word [cs:top_memory]	   ; return in bx free paragraphs
	sub   bx, word [cs:end_memory]	   ; Show what memory is available.
	stc				   ; Set CF ti 1
	jmp   int21_error		   ; Jump to int21_error label

;====================================================;
; int21 error					     ;
;====================================================; 
int21_error:
	call os_dump_registers

	jmp   int20	; End Program.
	; ---

	mov   ax,0xffff 		   ; Move AX 0xFFFF to show error
