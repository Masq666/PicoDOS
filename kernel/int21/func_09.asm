; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 09h
;
; WRITE STRING TO STANDARD OUTPUT
;	IN: AH = 09h
;	IN: DS:DX -> '$' or zero terminated string
;
;	OUT: AL = 24h (the '$' terminating the string, despite official docs which
;		      state that nothing is returned)
; ==================================================================
int21_09:
	push  si
	mov   si, dx
	call  os_print_string		    ; Print the string
	pop   si
	mov   al, 24h			    ; Move '$' into AL
	iret