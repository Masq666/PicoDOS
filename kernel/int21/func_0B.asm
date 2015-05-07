; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 0Bh
;
; GET STDIN STATUS
;	IN: AH = 0Bh
;
;	OUT: AL = 00h If no character available
;		  FFh If character is available
;
; ==================================================================
int21_0B:
	call os_check_for_key_status
	iret