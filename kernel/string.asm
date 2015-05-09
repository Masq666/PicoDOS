; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; STRING MANIPULATION ROUTINES
;
; Functions:
;	os_string_length	      - Return length of a string
;	os_string_uppercase	      - Convert zero-terminated string to upper case
;	os_string_lowercase	      - Convert zero-terminated string to lower case
;	os_int_to_string	      - Convert unsigned integer to string
;	os_string_compare	      - See if two strings match
;	os_string_chomp 	      - Strip leading and trailing spaces from a string
;	os_string_tokenize	      - Reads tokens separated by specified char from a string. Returns pointer to next token, or 0 if none left
;	os_string_copy		      - Copy one string into another
;	os_string_strincmp	      - See if two strings match up to set number of chars
;	os_string_parse 	      - Take string (eg "run foo bar baz") and return pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
;	os_string_join		      - Join two strings into a third string
;	os_string_strip 	      - Removes specified character from a string (max 255 chars)
;	os_string_truncate	      - Chop string down to specified number of characters
;	os_find_char_in_string	      - Find location of character in a string
; ==================================================================


; ==================================================================
; os_string_length - Return length of a string
;
; IN: AX = string location
;
; OUT: AX = length (other regs preserved)
; ==================================================================
os_string_length:
	push gs 			; The GS register can be used as temp store (386+)
	pusha

	mov bx, ax			; Move location of string to BX

	xor cx, cx			; Counter CX = 0

.more:
	cmp byte [bx], 0	; Zero (end of string) yet?
	je .done
	inc bx				; If not, keep adding
	inc cx
	jmp .more

.done:
	mov gs, cx			; Store count before restoring other registers
	popa

	mov ax, gs			; Put count back into AX before returning
	pop gs
	ret

; ==================================================================
; os_string_uppercase - Convert zero-terminated string to upper case
;
; IN: AX = string location
;
; OUT: AX = string location
; ==================================================================
os_string_uppercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'a'		; In the lower case A to Z range?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; If so, convert input char to upper case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret

; ==================================================================
; os_string_lowercase - Convert zero-terminated string to lower case
;
; IN: AX = string location
;
; OUT: AX = string location
; ==================================================================
os_string_lowercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'A'		; In the upper case A to Z range?
	jb .noatoz
	cmp byte [si], 'Z'
	ja .noatoz

	add byte [si], 20h		; If so, convert input char to lower case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret

; ==================================================================
; os_int_to_string -- Convert unsigned integer to string
;
; IN: AX = signed int
;
; OUT: AX = string location
; ==================================================================
os_int_to_string:
	pusha

	xor cx, cx			; CX = 0
	mov bx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

.push:
	xor dx, dx			; DX = 0
	div bx				; Remainder in DX, quotient in AX
	inc cx				; Increase pop loop counter
	push dx 			; Push remainder, so as to reverse order when popping
	test ax, ax			; Is quotient zero?
	jnz .push			; If not, loop again
.pop:
	pop dx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov [di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [di], 0		; Zero-terminate string

	popa
	mov ax, .t			; Return location of string
	ret

	.t: times 7 db 0

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

os_string_compare:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di
	jmp .more

.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret

.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret

; ------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location

os_string_chomp:
	pusha

	mov dx, ax			; Save string location

	mov di, ax			; Put location into DI
	xor cx, cx			; Space counter, CX = 0

.keepcounting:				; Get number of leading spaces into BX
	cmp byte [di], ' '
	jne .counted
	inc cx
	inc di
	jmp .keepcounting

.counted:
	cmp cx, 0			; No leading spaces?
	je .finished_copy

	mov si, di			; Address of first non-space character
	mov di, dx			; DI = original string start

.keep_copying:
	mov al, [si]			; Copy SI into DI
	mov [di], al			; Including terminator
	cmp al, 0
	je .finished_copy
	inc si
	inc di
	jmp .keep_copying

.finished_copy:
	mov ax, dx			; AX = original string start

	call os_string_length
	cmp ax, 0			; If empty or all blank, done, return 'null'
	je .done

	mov si, dx
	add si, ax			; Move to end of string

.more:
	dec si
	cmp byte [si], ' '
	jne .done
	mov byte [si], 0		; Fill end spaces with 0s
	jmp .more			; (First 0 will be the string terminator)

.done:
	popa
	ret

; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none

os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret

; ------------------------------------------------------------------
; os_string_copy -- Copy one string into another
; IN/OUT: SI = source, DI = destination (programmer ensure sufficient room)

os_string_copy:
	pusha

.more:
	mov al, [si]			; Transfer contents (at least one byte terminator)
	mov [di], al
	inc si
	inc di
	cmp byte al, 0			; If source string is empty, quit out
	jne .more

.done:
	popa
	ret

; ------------------------------------------------------------------
; os_string_strincmp -- See if two strings match up to set number of chars
; IN: SI = string one, DI = string two, CL = chars to check
; OUT: carry set if same, clear if different

os_string_strincmp:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di

	dec cl				; If we've lasted through our char count
	cmp cl, 0			; Then the bits of the string match!
	je .terminated

	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret

; ------------------------------------------------------------------
; os_string_parse -- Take string (eg "run foo bar baz") and return
; pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
; IN: SI = string; OUT: AX, BX, CX, DX = individual strings

os_string_parse:
	push si

	mov ax, si			; AX = start of first string

	xor bx, bx			; By default, other strings start empty
	xor cx, cx			; Therefore we set BX, CX and DX to 0
	xor dx, dx

	push ax 			; Save to retrieve at end

.loop1:
	lodsb				; Get a byte
	cmp al, 0			; End of string?
	je .finish
	cmp al, ' '			; A space?
	jne .loop1
	dec si
	mov byte [si], 0		; If so, zero-terminate this bit of the string

	inc si				; Store start of next string in BX
	mov bx, si

.loop2: 				; Repeat the above for CX and DX...
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	pop ax

	pop si
	ret

; ------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
; IN/OUT: AX = string one, BX = string two, CX = destination string

os_string_join:
	pusha

	mov si, ax			; Put first string into CX
	mov di, cx
	call os_string_copy

	call os_string_length		; Get length of first string

	add cx, ax			; Position at end of first string

	mov si, bx			; Add second string onto it
	mov di, cx
	call os_string_copy

	popa
	ret

; ------------------------------------------------------------------
; os_string_strip -- Removes specified character from a string (max 255 chars)
; IN: SI = string location, AL = character to remove

os_string_strip:
	pusha

	mov di, si

	mov bl, al			; Copy the char into BL since LODSB and STOSB use AL
.nextchar:
	lodsb
	stosb
	cmp al, 0			; Check if we reached the end of the string
	je .finish			; If so, bail out
	cmp al, bl			; Check to see if the character we read is the interesting char
	jne .nextchar			; If not, skip to the next character

.skip:					; If so, the fall through to here
	dec di				; Decrement DI so we overwrite on the next pass
	jmp .nextchar

.finish:
	popa
	ret

; ==================================================================
; os_string_truncate - Chop string down to specified number of characters
;
; IN: SI = String location
;     AX = Number of characters
;
; OUT: String modified, registers preserved
; ==================================================================
os_string_truncate:
	add si, ax
	mov byte [si], 0
	ret

; ==================================================================
; os_find_char_in_string - Find location of character in a string
;
; IN: SI = String location
;     AL = Character to find
;
; OUT: AX = location in string, or 0 if char not present
; ==================================================================
os_find_char_in_string:
	pusha

	mov cx, 1			; Counter -- start at first char (we count
					; from 1 in chars here, so that we can
					; return 0 if the source char isn't found)

.more:
	cmp byte [si], al
	je .done
	cmp byte [si], 0
	je .notfound
	inc si
	inc cx
	jmp .more

.done:
	mov [.tmp], cx
	popa
	mov ax, [.tmp]
	ret

.notfound:
	popa
	xor ax, ax
	ret


	.tmp	dw 0