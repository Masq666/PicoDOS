; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 0Ah
;
; BUFFERED INPUT
;	IN: AH = 0Ah
;	IN: DS:DX -> buffer
;
;	OUT: Buffer filled with user input
;
;	Format of DOS input buffer:
;
;	Offset	Size	Description
;	00h	BYTE	maximum characters buffer can hold
;	01h	BYTE	(call) number of chars from last input which may be recalled
;			(ret) number of characters actually read, excluding CR
;	02h	N BYTEs actual characters read, including the final carriage return
; ==================================================================
int21_0A:
	pusha

	mov di, dx

	inc di				; Skip first byte (buffer size)
	inc di				; Skip second byte (chars entered)

	xor cx, cx			; Counter for characters entered
.more:
	call os_wait_for_key
	cmp al, 13			; Quit if enter pressed
	je .done

	mov [di], al			; Otherwise store entered char
	inc di				; And move on in the string
	inc cx
	jmp .more

.done:
	mov di, dx			; Starting point of string
	mov byte [di], 1		; Buffer size
	inc di
	mov [di], cx			; Chars read

	popa
	iret