; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 30h
;
; GET DOS VERSION
;	IN: AH = 30h
;
;	OUT: AL = Major version number
;	OUT: AH = Minor version number
;	OUT: BL:CX = 24-bit user serial number (most versions do not use this)
;	OUT: BH = version flag bit 3: DOS is in ROM other: reserved (0)
;
; ==================================================================
int21_30:
	mov   ax, PICO_VER_NR		   ; Add Minor/Major version to AH:AL
	xor   bx, bx			   ; We don't care about OEM number and Flags
	xor   cx, cx			   ; Serial number? I don't think so..

	iret