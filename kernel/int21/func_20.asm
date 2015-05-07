; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 20h
;
; DUMP REGISTERS TO STDOUT (PicoDOS ONLY!)
;	IN: AH = 20h
;
;	OUT: None
;
; ==================================================================
int21_20:
	call os_dump_registers
	iret