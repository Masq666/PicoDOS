; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 2Bh
;
; SET SYSTEM DATE
;	IN: CH = Century	- CX = 2014
;	IN: CL = Year
;	IN: DH = Month		- DX = 1231
;	IN: DL = Day
;
;	OUT: AL = 00h Successful (FFh if invalid date, system time unchanged)
;		  PicoDOS always returns AL = 00h
;
; ==================================================================
int21_2B:
	pusha

	mov al, ch
	call os_byte_to_bcd		; Century
	mov ch, al

	mov al, cl
	call os_byte_to_bcd		; Year
	mov cl, al

	mov al, dh
	call os_byte_to_bcd		; Month
	mov dh, al

	mov al, dl
	call os_byte_to_bcd		; Month
	mov dl, al

	mov ax, 0400h
	int 1Ah 			; Set time with BIOS interrupt

	popa
	xor al, al			; AL = 00h Successful

	iret