; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; MATH ROUTINES
;
; Functions:
;	os_bcd_to_int		      - Converts BCD number to an integer
;	os_byte_to_bcd		      - Converts a byte to a BCD number
;	os_checksum_f16 	      - Calculate the 16-bit Fletcher Checksum Algorithm
; ==================================================================


; ==================================================================
; os_bcd_to_int - Converts binary coded decimal number to an integer
;
; IN: AL = BCD number
;
; OUT: AX = integer value
; ==================================================================
os_bcd_to_int:
	push gs 			    ; We use GS register to hold temp value
	pusha

	and ax, 00F0h
	shr ax, 4
	mov dx, 10
	mul dx
	mov bx, ax

	and ax, 0fh
	add bx, ax

	mov gs, bx
	popa
	mov ax, gs
	pop gs
	ret

; ==================================================================
; os_byte_to_bcd - Converts a byte to a binary coded decimal number
;
; IN: AL = byte
;
; OUT: AL = BCD number
; ==================================================================
os_byte_to_bcd:
	push gs 			    ; We use GS register to hold temp value
	pusha

	xor ah, ah
	mov cx, ax
	shr ax, 4

	mov dx, 10
	mul dx

	and cx, 000Fh
	add ax, cx

	mov gs, ax
	popa
	mov ax, gs
	pop gs
	ret
; ==================================================================
; os_checksum_f16 - Calculate the 16-bit Fletcher Checksum Algorithm
;
; IN: AX - Pointer to data
;     CX - Number of bytes
;
; OUT: AX - Checksum
; ==================================================================
os_checksum_f16:

