; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 02h
;
; WRITE CHARACTER TO STANDARD OUTPUT
;	IN: AH = 02h
;	IN: DL = Character to write
;
;	OUT: AL = Last character output
;
; ==================================================================
int21_02:
	push  ax			   ; Save AX
	mov   al, dl			   ; Put whats in DL into AL
	call  os_print_char		   ; Call our print char function
	pop   ax			   ; Restore AX
	mov   al, dl			   ; Return char in AL, move it from DL.
	iret