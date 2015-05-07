; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 19h
;
; GET CURRENT DEFAULT DRIVE
;	IN: AH = 19h
;
;	OUT: AL = drive (0=A:, 1=B:, etc)
;
; ==================================================================
int21_19:
	mov   al, byte [cs:bootdev]	    ; Move boot drive number into AL
	iret