; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 2Ah
;
; GET SYSTEM DATE
;	IN: AH = 2Ah
;
;	OUT: CX = year (1980 - 2099)
;	OUT: DH = month
;	OUT: DL = day
;	OUT: AL = day of week (00h = Sunday)
;
; Todo:
;	* Add Day of Week calculation, for now it's always sunday.
; ==================================================================
int21_2A:
	mov  ax, 0400h			; Get date from BIOS
	int  1Ah			; Registers now hold these values.
					; CH = century (BCD)
					; CL = year (BCD)
					; DH = month (BCD)
					; DL = day (BCD)

	mov  al, ch			; Move Century into AL so we can convert to decimal
	call os_bcd_to_int		; Convert BCD to int
	mov  ch, al			; Move decimal Century value back to CH

	mov  al, cl			; Move Year into AL so we can convert to decimal
	call os_bcd_to_int		; Convert BCD to int
	mov  cl, al			; Move decimal Century value back to CH
					; Full year (2014) should now be stored in CX

	mov  al, dh			; Move Month into AL so we can convert to decimal
	call os_bcd_to_int		; Convert BCD to int
	mov  dh, al			; Move decimal Month value back to DH

	mov  al, dl			; Move Day into AL so we can convert to decimal
	call os_bcd_to_int		; Convert BCD to int
	mov  dl, al			; Move decimal Day value back to DL

	xor  al, al			; AL = 00h It's always Sunday.
	iret