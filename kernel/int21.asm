; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; DOS INTERRUPT ROUTINES
;
; Functions:
;	os_install_interrupts
;	int20
;	int21
; ==================================================================
os_install_interrupts:
	push  ds			    ; Save DS
	cli				    ; Turn off int's
	xor   ax, ax
	mov   ds, ax			    ; 0 DS
	mov   word [ds:20h*4],int20	    ; load int vecter with int20h address
	mov   word [ds:20h*4+2],cs	    ; + CS

	mov   word [ds:21h*4],int21	    ; load int vecter with int21h address
	mov   word [ds:21h*4+2],cs	    ; + CS
	sti				    ; Turn on int's
	pop   ds			    ; restore DS
	ret				    ; Return
; ==================================================================
;  INT 20h Terminate .COM program.
; ==================================================================
old_int20:					; Int 20h ends up here.
	cli				    	; Turn off int's
	push  cs			    ; Push CS on stack
	pop   bx			    ; BX now = CS   
	mov   ds,bx			    ; Move BX into DS
	mov   es,bx			    ; Move BX into ES
	mov   ss,bx			    ; Move BX into SS
	xor   sp,sp			    ; 0 SP
	sti				    	; Turn on int's
	cmp   ah,'R'			    ; Check for a 'R'(read error) in AH
	je    ReadError 		    ; Jump if =.
	cmp   al,'F'			    ; Check for a 'F'(read error) in AL
	je    FindError 		    ; Jump if =.
	jmp   Start2			    ; If not jump to label Start2 
FindError:
	mov   si,FindMsg		    ; Point SI to find error message.
	call  os_print_string		    ; Call print funtion.
;	 call  Aprompt			     ; Call prompt funtion.
	jmp   os_main			    ; If not jump to label os_main
ReadError:
	mov   si,ReadMsg		    ; Point SI to read error message.
	call  os_print_string		    ; Call print funtion.
;	 call  Aprompt			     ; Call prompt funtion.
	jmp   os_main			    ; If not jump to label MainLoop
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
;====================================================;
;  terminate program				     ;
;====================================================; 
old_int21_00:
	jmp   int20			   ; Jump to int20 label
; ------------------------------------------------------------------
; int21 Func 06h -- Direct console output
; IN: DL = character (except FFh); OUT: AL = Character output
;int21_06:
;	 cmp dl, 255
;	 je int21_07
;	 jmp int21_02
;====================================================;
;  read character without echo			     ;
;====================================================; 
;int21_07:
;	 xor   ax,ax			    ; 0 AX
;	 int   16h			    ; Call BIOS function.
;	 iret
;====================================================;
;  get current drive				     ;
;====================================================; 
;int21_19:
;	 mov   al,byte[cs:bootdev]	; Move boot drive number into AL
;	 iret
;====================================================;
;  Get date					     ;
;====================================================; 
;int21_2A:
;====================================================;
;  Set date					     ;
;====================================================; 
;int21_2B:
;	  jmp	int21_error		     ; Jump to int21_error label,as function not implemented
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
; End program					     ;
;====================================================; 
old_int21_4C:
	jmp   int20			   ; Jump to int20   label
;====================================================;
; int21 error					     ;
;====================================================; 
int21_error:
	call os_dump_registers

	jmp   int20	; End Program.
	; ---

	mov   ax,0xffff 		   ; Move AX 0xFFFF to show error
;====================================================;
; int21 exit					     ;
;====================================================;
;int21_exit:
;	 iret				    ; Int return.