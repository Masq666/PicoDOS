; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 4Dh
;
; GET RETURN CODE (ERRORLEVEL)
;	IN: AH = 4Dh
;
;	OUT: AH = Termination type (00=normal, 01h control-C abort, 02h=critical error abort, 03h terminate and stay resident)
;	     AL = Return code
;
;	NOTES: The word in which DOS stores the return code is cleared after being read by this function,
;	       so the return code can only be retrieved once.
;	       COMMAND.COM stores the return code of the last external command it executed as ERRORLEVEL
; ==================================================================
int21_4D:
	mov ah, 00h
	mov al, byte [cs:ERRORLEVEL]	    ; Return code
	mov [cs:ERRORLEVEL], 00h	    ; Can only be read once, clear return code.
	iret