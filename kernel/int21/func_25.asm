; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 25h
;
; SET INTERRUPT VECTOR
;	IN: AH = 25h
;	IN: AL = interrupt number
;	IN: DS:DX -> new interrupt handler
;
;	OUT: None
;
; ==================================================================
int21_25:
	cmp   al, 19h			; No change int 19h (for rebooting)
	je    int21_error		; Jump to int21_error label

	cli						; Turn off int's
	xor   ah, ah			; AH = 0
	shl   ax, 2				; Mul whats in AX by 4

	push  si				; Save SI
	push  bx				; Save BX
	push  es				; Save ES

	mov   si, ax			; Move AX into SI
	xor   bx, bx			; BX = 0
	mov   es, bx			; Move BX into ES
	mov   word[es:si], dx	; Move offset address to ES:SI points to.
	mov   bx, ds			; Move DS into BX
	mov   word[es:si+2], bx ; Move segment of address to ES:SI+2 points too.

	pop   es				; Restore ES
	pop   bx				; Restore BX
	pop   si				; Restore SI

	sti						; Turn int's on
	iret