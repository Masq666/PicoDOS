; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 41h
;
; UNLINK - DELETE FILE
;	IN: AH = 41h
;	    DS:DX -> ASCIZ filename (no wildcards, but see notes)
;	    CL = attribute mask for deletion (server call only, see notes)
;
;	OUT: CF clear if successful
;	     AX destroyed (DOS 3.3) AL seems to be drive of deleted file
;
; ==================================================================
int21_41:
	pusha

	mov ax, dx			    ; Move Filename pointer into AX
	call vfs.unlink

	popa
	iret