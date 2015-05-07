; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 2Ch
;
; GET SYSTEM TIME
;	IN: AH = 2Ch
;
;	OUT: CH = Hour
;	OUT: CL = Minute
;	OUT: DH = Second
;	OUT: DL = 00h
;
; ==================================================================
int21_2C:
	mov ax, 0200h
	int 1Ah 			; Get Time from BIOS

	mov al, ch			; Hour
	call os_bcd_to_int
	mov ch, al

	mov al, cl			; Minute
	call os_bcd_to_int
	mov cl, al

	mov al, dh			; Second
	call os_bcd_to_int
	mov dh, al

	xor dl, dl			; We always return 00h in DL

	iret