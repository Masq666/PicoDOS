; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT 1Bh
;
; CONTROL-BREAK HANDLER
;
; ==================================================================

int1B:
	mov byte [CONTROLC], 1		; Set CTRL-C / CTRL-Break flag.
	iret