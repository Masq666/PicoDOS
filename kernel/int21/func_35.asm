; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 35h
;
; GET INTERRUPT VECTOR
;	IN: AH = 35h
;	IN: AL = Interrupt number
;
;	OUT: ES:BX -> Current interrupt handler
;
; ==================================================================
int21_35:
	push  ds			; Save DS
	push  si			; Save SI

	xor   ah, ah			; AH = 0
	shl   ax, 2			; Mul whats in AX by 4

	mov   si, ax			; Move AX into SI
	xor   bx, bx			; BX = 0
	mov   ds, bx			; DS = 0

	mov   bx, word[ds:si+2] 	; Move the word that DS:SI+2 points to, into BX
	push  bx			; Save BX
	mov   bx, word [ds:si]		; Move the word that DS:SI points to, into BX

	pop   es			; Move what was in the pushed BX into ES
	pop   si			; Restore SI
	pop   ds			; Restore DS

	iret