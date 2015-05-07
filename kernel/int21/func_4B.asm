; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 4Bh
;
; EXEC - LOAD AND/OR EXECUTE PROGRAM
;	IN: AH = 4Bh
;	    AL = type of load
;	    - 00h load and execute
;	    - 01h load but do not execute
;	    - 03h load overlay
;	    - 04h load and execute in background (European MS-DOS 4.0 only)
;	    - 05h load and execute (MikeOS .BIN or PicoDOS .PTE)
;	    DS:DX -> ASCIZ program name (must include extension)
;	    ES:BX -> parameter block
;	    CX = mode (subfunction 04h only)
;	    - 0000h child placed in zombie mode after termination
;	    - 0001h child's return code discarded on termination
;
;	OUT: CF clear if successful, set on error
;	     AX = error code (01h,02h,05h,08h,0Ah,0Bh)
;
; ==================================================================
int21_4B:
	pusha

	popa
	iret