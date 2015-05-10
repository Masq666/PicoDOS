; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; SCREEN HANDLING ROUTINES
;
; Functions:
;	os_print_char		      - Write Character to STDOUT
;	os_print_string 	      - Write Sting to STDOUT
;	os_print_newline	      - Print a New Line (13,10)
;	os_print_space		      - Print a Space
;	os_clear_screen 	      - Clear Screen
;	os_move_cursor		      - Moves cursor in text mode
;	os_get_cursor_pos
;	os_input_string
;	os_print_digit
;	os_print_hex		      - Print x bits of EAX/AX register
;	os_print_1hex
;	os_print_2hex
;	os_print_4hex
;	os_print_8hex
;	os_dump_registers	      - Displays register contents in hex on the screen
; ==================================================================


; ==================================================================
; os_print_char - Write Character to STDOUT
;
; IN: AL = Character to write
;
; OUT: Nothing
; ==================================================================
os_print_char:
	push ax 			   ; AX is the only register we use, save it.

	cmp al, 9			   ; Compear AL to 9
	je .tabchar			   ; Jump = to label .tabchar
	mov ah, 0Eh			   ; Request display
	int 10h 			   ; Call interrupt service

	pop ax				   ; Restore AX
	ret				   ; Return

.tabchar:				   ; expand tab character (8 spaces)
	mov ax, 0E20h			   ; Same as mov al,' ' and mov ah,0Eh - 20h = ascii space

	rept 8 {
	       int 10h			   ; Call function 8 times
	}

	pop ax				   ; Restore AX
	ret				   ; Return

; ------------------------------------------------------------------
; os_print_string -- Write Sting to STDOUT
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_print_string:
	push ax

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	or al, al
	jz .done			; If char is zero, end of string

	cmp al,'$'			; Or if it is a $ terminated string.
	je .done

	int 10h 			; Otherwise, print it
	jmp .repeat			; And move on to next char

.done:
	pop ax
	ret

; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)

os_print_newline:
	push ax

	mov ax, 0E0Dh			 ; Print a new line using BIOS func 0E, int 10h

	int 10h
	mov al, 10
	int 10h

	pop ax
	ret

; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing

os_print_space:
	push ax

	mov ax, 0E20h			; BIOS teletype function
	int 10h 			 	; Space is character 20h

	pop ax
	ret

; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

os_clear_screen:
	pusha

	xor dx, dx				; Position cursor at top-left DX = 0
	call os_move_cursor

	mov ax, 0600h			; Scroll full-screen
							; Normal white on black
	mov bh, 7				;
	xor cx, cx				; Top-left CX = 0
	mov dx, 184Fh			; Bottom-right
	int 10h

	popa
	ret

; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0			; Page number 0
	mov ah, 2			; BIOS Set Cursor function
	int 10h 			; BIOS interrupt to move cursor

	popa
	ret

; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
	push ax
	push bx
	push cx

	mov bh, 0
	mov ah, 3
	int 10h 			; BIOS interrupt to get cursor position

	pop cx
	pop bx
	pop ax
	ret

; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 255 characters, zero-terminated)

os_input_string:
	pusha

	mov di, ax			; DI is where we'll store input (buffer)
	xor cx, cx			; Character received counter for backspace

.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp ah, 72			; Key UP pressed?
	je .backspace			; If not, skip following checks
	
	cmp al, ' '			; In ASCII range (32 - 126)?
	jb .more			; Ignore most non-printing characters

	cmp al, '~'
	ja .more

	jmp .nobackspace


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	call os_get_cursor_pos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			; If not, write space and move cursor back
	mov al, 8
	int 10h 			; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
					; character or terminator at end

	dec cx				; Step back counter

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call os_move_cursor

	mov al, ' '			; Print space there
	mov ah, 0Eh
	int 10h

	mov dl, 79			; And jump back before the space
	call os_move_cursor

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .more


.nobackspace:
	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	cmp cx, 254			; Make sure we don't exhaust buffer
	jae near .done

	jmp near .more			; Still room for more


.done:
	xor ax, ax
	stosb

	popa
	ret
	
; ==================================================================
; os_dump_string - Dump string as hex bytes and printable characters
;
; IN: SI = points to string to dump
;
; OUT: Nothing
; ==================================================================
os_dump_string:
	pusha

	mov bx, si			; Save for final print

.line:
	mov di, si			; Save current pointer
	mov cx, 0			; Byte counter

.more_hex:
	lodsb
	cmp al, 0
	je .chr_print

	call os_print_2hex
	call os_print_space		; Single space most bytes
	inc cx

	cmp cx, 8
	jne .q_next_line

	call os_print_space		; Double space centre of line
	jmp .more_hex

.q_next_line:
	cmp cx, 16
	jne .more_hex

.chr_print:
	call os_print_space
	mov ah, 0Eh			; BIOS teletype function
	mov al, '|'			; Break between hex and character
	int 10h
	call os_print_space

	mov si, di			; Go back to beginning of this line
	mov cx, 0

.more_chr:
	lodsb
	cmp al, 0
	je .done

	cmp al, ' '
	jae .tst_high

	jmp short .not_printable

.tst_high:
	cmp al, '~'
	jbe .output

.not_printable:
	mov al, '.'

.output:
	mov ah, 0Eh
	int 10h

	inc cx
	cmp cx, 16
	jl .more_chr

	call os_print_newline		; Go to next line
	jmp .line

.done:
	call os_print_newline		; Go to next line

	popa
	ret
; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print

os_print_digit:
	push ax

	cmp ax, 9			; There is a break in ASCII table between 9 and A
	jle .digit_format

	add ax, 'A'-'9'-1		; Correct for the skipped punctuation

.digit_format:
	add ax, '0'			; 0 will display as '0', etc.	

	mov ah, 0Eh			; May modify other registers
	int 10h

	pop ax
	ret

; ==================================================================
; os_print_hex - Displays (E)AX in hex format
;
; IN: EAX - Number to print
;     CX - Number of bytes to print from reg, 1 to 8
;
; OUT: Nothing
; ==================================================================
os_print_hex:
    pushad
    
    mov si, .hex
    mov di, .tmp
    mov bx, cx
    mov byte [di+bx], 0
    mov edx, eax

.loop:
    mov eax, edx
    shl al, 4
    shr al, 4
    mov bl, al

    mov al, byte [ds:si+bx]
    mov bx, cx
    mov byte [es:di+bx-1], al

    ror edx, 4
    loop .loop

.exit:
    popad

    mov si, .tmp
    call os_print_string
    ret 	
	
    .hex db "0123456789ABCDEF"
    .tmp db "       ",0

; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print

os_print_1hex:
	push ax

	and ax, 0Fh			; Mask off data to display
	call os_print_digit

	pop ax
	ret


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print

os_print_2hex:
	push ax

	push ax 			; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	call os_print_1hex

	pop ax
	ret


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print

os_print_4hex:
	push ax

	push ax 			; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	call os_print_2hex

	pop ax
	ret


; ------------------------------------------------------------------
; os_print_8hex -- Displays EAX in hex format
; IN: EAX = number to format and print

os_print_8hex:
	push eax

	ror eax, 16
	call os_print_4hex		    ; Output upper 16-bits

	ror eax, 16
	call os_print_4hex		    ; Output lower 16-bits

	pop eax
	ret
; ------------------------------------------------------------------
; os_dump_registers -- Displays register contents in hex on the screen
; IN:
; OUT: EAX/EBX/ECX/EDX
;      SI/DI/BP/SP
;      CS/DS/ES/SS/FS/GS

os_dump_registers:
	pushad

	call os_print_newline

	push gs
	push fs
	push ss
	push es
	push ds
	push cs

	push sp
	push bp
	push di
	push si

	push edx
	push ecx
	push ebx
	push eax

	push cs

	pop ds
	mov si, .main_reg
	call os_print_string

	pop eax
	mov si, .ax_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .bx_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .cx_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .dx_string
	call os_print_string
	call os_print_8hex

	call os_print_newline
	mov si, .index_reg
	call os_print_string

	pop ax
	mov si, .si_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .di_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .bp_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .sp_string
	call os_print_string
	call os_print_4hex

	call os_print_newline
	mov si, .segment_reg
	call os_print_string

	pop ax
	mov si, .cs_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .ds_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .es_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .ss_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .fs_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .gs_string
	call os_print_string
	call os_print_4hex

	popad
	ret

	.main_reg		db 'Main Registers:',13,10,0
	.ax_string		db 'EAX:', 0
	.bx_string		db ' EBX:', 0
	.cx_string		db ' ECX:', 0
	.dx_string		db ' EDX:', 0

	.index_reg		db 13,10,'Index Registers:',13,10,0
	.si_string		db 'SI:', 0
	.di_string		db ' DI:', 0
	.bp_string		db ' BP:', 0
	.sp_string		db ' SP:', 0

	.segment_reg		db 13,10,'Segment Registers:',13,10,0
	.cs_string		db 'CS:', 0
	.ds_string		db ' DS:', 0
	.es_string		db ' ES:', 0
	.ss_string		db ' SS:', 0
	.fs_string		db ' FS:', 0
	.gs_string		db ' GS:', 0