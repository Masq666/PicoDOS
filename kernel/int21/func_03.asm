; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 03h
;
; READ CHARACTER FROM STDAUX
;	IN: AH = 03h
;
;	OUT: AL = Character read
;
; ==================================================================
int21_03:
	call os_get_via_serial
	iret