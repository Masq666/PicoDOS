; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 06h
;
; DIRECT CONSOLE OUTPUT
;	IN: AH = 06h
;	IN: DL = Character (except FFh)
;
;	OUT: AL = Character output
;
; ==================================================================
int21_06:
	cmp dl, 255
	je int21_07
	jmp int21_02