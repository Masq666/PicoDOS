; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 04h
;
; WRITE CHARACTER TO STDAUX
;	IN: AH = 04h
;	IN: DL = Character to write
;
;	OUT: None
;
; ==================================================================
int21_04:
	pusha
	mov al, dl			; Move char at DL into AL and send.
	call os_send_via_serial
	popa
	iret