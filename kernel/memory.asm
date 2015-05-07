; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; MEMORY ROUTINES
;
; Functions:
;	os_memcpy		      - Copy bytes in memory to another location
;	os_memset		      - Fill block of memory
; ==================================================================


; ==================================================================
; os_memcpy - Copy bytes in memory to another location
;
; IN: ES:DI - Destination
;     DS:SI - Source
;     CX    - Number of bytes to copy
;
; OUT: Nothing
; ==================================================================
os_memcpy:
	push bx
	push dx

	mov bx, cx
	clc				    			; Clear the Carry Flag
	bt bx, 0			    		; If the last bit is set, then this is an odd number
									; CF will be set if the last bit was odd
	jnc .loop			    		; If odd number skip to .loop and copy word for word

	mov dl, byte [ds:si+bx-1]	    ; It was even, copy a single byte first
	mov byte [es:di+bx-1], dl
	dec bx
.loop:
	mov dx, word [ds:si+bx-2]	    ; Copy the rest word for word as this is
	mov word [es:di+bx-2], dx	    ; 2x faster than copying byte for byte.
	sub bx, 2
	test bx, bx
	jnz .loop

	pop dx
	pop bx
	ret

; ==================================================================
; os_memcpy32 - Copy a double in memory to another location
;
; IN: EDI - Destination
;     ESI - Source
;     ECX - Number of doubles to copy
;
; OUT: Nothing
; ==================================================================
os_memcpy32:
	pushad
	
	.loop:
	mov eax, [esi] ; load from source
	mov [edi], eax ; store to destination
	add esi, 4
	add edi, 4

	sub ecx, 1 ; ecx -= 1
	cmp ecx, 0 ; is ecx 0?

	; if ecx does not equal 0, jump to the beginning of the loop
	jne .loop
	
	popad
	ret
; ==================================================================
; os_memset - Fill block of memory.
;
; IN: DL - Character to set
;     CX - Number of bytes
;     ES:DI - Memory address
;
; OUT: Nothing
; ==================================================================
os_memset:
	push cx
	push di

.loop:
	test cx ,cx
	jz .exit
	mov byte [es:di], dl
	inc di
	dec cx
	jmp .loop

.exit:
	pop di
	pop cx
	ret
