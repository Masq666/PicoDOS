; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 4Ch
;
; EXIT - TERMINATE WITH RETURN CODE
;	IN: AH = 4Ch
;	    AL = Return code
;
;	OUT: Nothing
;
; NOTES:
;	INT 20h, INT 21h and INT 21h func 4C ends up here.
; ==================================================================
int21_4C:
	mov [ERRORLEVEL], al		    ; Save return code, can be fetched again with int 21h, func 4Dh

int21_00:
int20:
	cli				    			; Disable Interrupts

	push  cs			   			; Push CS on stack
	pop   bx			    		; BX now = CS   
	mov   ds, bx			    	; Move BX into DS
	mov   es, bx			    	; Move BX into ES
	mov   ss, bx			    	; Move BX into SS
	xor   sp, sp			    	; 0 SP

	sti				    			; Enable Interrupts

	cmp byte [CONTROLC], 1
	jne .exit
	mov si, .msg
	call os_print_string
	
	.exit:
	call get_cmd			    	; When program has finished, return to CLI
	
	.msg db '^C or ^Break pressed. Program terminated', 10, 13, 0