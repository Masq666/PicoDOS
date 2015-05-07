; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 2Dh
;
; SET SYSTEM TIME
;	IN: CH = Hour
;	IN: CL = Minute
;	IN: DH = Second
;	IN: DL = 1/100 seconds (Ignored)
;
;	OUT: AL = 00h Successful (FFh if invalid time, system time unchanged)
;		  PicoDOS always returns AL = 00h
;
; ==================================================================
int21_2D:
	pusha

	mov al, ch
	call os_byte_to_bcd		; Hour
	mov ch, al

	mov al, cl
	call os_byte_to_bcd		; Minutes
	mov cl, al

	mov al, dh
	call os_byte_to_bcd		; Seconds
	mov dh, al

	xor dl, dl			; Midnight flag

	mov ax, 0300h
	int 1Ah 			; Set time with BIOS interrupt

	popa
	xor al, al			; AL = 00h Successful

	iret