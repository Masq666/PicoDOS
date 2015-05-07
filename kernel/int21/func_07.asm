; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 07h
;
; READ CHARACTER WITHOUT ECHO
;	IN: AH = 07h
;
;	OUT: AL = character read from standard input
;
; ==================================================================
int21_07:
	xor   ax, ax			    ; 0 AX
	int   16h			    	; Call BIOS function.
	iret