; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 0Eh
;
; SELECT DEFAULT DRIVE
;	IN: AH = 0Eh
;	IN: DL = new default drive (0=A:, 1=B:, etc)
;
;	OUT: AL = number of potentially valid drive letters
;
;	Notes: the return value is the highest drive present
;
; ==================================================================
int21_0E:
	; For now we only support drive A: floppy.
	mov   byte [cs:bootdev], 0	    ; Set new active drive.
	mov   al, 0			    ; Return A: as last valid drive.
	iret