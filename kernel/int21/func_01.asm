; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 01h
;
; READ CHARACTER FROM STANDARD INPUT, WITH ECHO
;	IN: AH = 01h
;
;	OUT: AL = Character read
;
; ==================================================================
int21_01:
	xor   ax,ax			   ; 0 AX
	int   16h			   ; Call BIOS function.
	call  os_print_char		   ; Call our print char function
	iret