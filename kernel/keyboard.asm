; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; KEYBOARD HANDLING ROUTINES
;
; Functions:
;	os_wait_for_key
;	os_check_for_key
;	os_check_for_key_status
; ==================================================================



; ==================================================================
;	os_wait_for_key - Waits for keypress and returns key
;
;	IN: Nothing
;
;	OUT: AH = BIOS scan code
;	OUT: AL = ASCII character
; ==================================================================
os_wait_for_key:

	mov ax, 1000h			; BIOS call to wait for key AH = 10h
	int 16h

	ret

; ==================================================================
; os_check_for_key - Scans keyboard for input, but doesn't wait
;
; IN: Nothing
;
; OUT: AH = BIOS scan code
; OUT: AL = ASCII character
;
; NOTE: AX = 0 if no key pressed
; ==================================================================
os_check_for_key:

	mov ax, 0100h			; BIOS call to check for key AH = 01h
	int 16h

	jz .nokey			; If no key, skip to end

	xor ax, ax			; Otherwise get it from buffer
	int 16h

	ret

.nokey:
	xor ax, ax			; Zero result if no key pressed
	ret

; ------------------------------------------------------------------
; os_check_for_key_status -- Checks if a character is available
; IN: Nothing; OUT: AL = 00h if no key pressed, AL = FFh otherwise
os_check_for_key_status:

	mov ax, 0100h			; BIOS call to check for key AH = 01h
	int 16h

	jz .nokey

	mov ax, 00FFh			; AL = FFh if character is available
	ret
.nokey:
	xor ax, ax			; Zero result if no key pressed
	ret

; ==================================================================
; os_check_for_ctrlc - Sets CONTROLC flag, if CTRL-C is pressed.
;
; IN: Nothing
;
; OUT: AH = 00h abort program
;
; NOTE: DOS will abort program with errorlevel 0
;		This function is called from top of int 21h handler.
; ==================================================================
os_check_for_ctrlc:
	push ax
	
	call os_check_for_key
	cmp ax, 2E03h				; is CTRL-C pressed?
	jz .exit
	
	mov byte [CONTROLC], 1		; Set CTRL-C / CTRL-Break flag.
	pop ax
	mov ah, 00h					; Int21 handler will call func 00h, abort program.
	ret
	
.exit:
	pop ax
	ret
; ==================================================================

