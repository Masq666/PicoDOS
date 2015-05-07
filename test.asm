os_testzone:
	pusha
	
	;	 mov   ax,0x80                       ; mov used sector in KB(128) into AX
    ;    shl   ax, 6                         ; and convert it to paragraphs
    ;    mov   word[end_memory],ax           ; save (to know free memory)
    ;    int   12h                           ; get conventional memory size (in KBs)
    ;    shl   ax,6                          ; and convert it to paragraphs
    ;    mov   word[top_memory],ax
	;mov ax, 2401h
	;int 15h

	mov si, prompt
	mov ax, si
	call os_print_4hex
	
	call os_print_newline
	
	mov ax, 0000h
	mov ds, ax
	mov es, ax
	mov esi, prompt
	mov eax, esi
	call os_print_8hex
	
	mov eax, 9fff0000h
	mov ds, eax
	mov es, eax
	call os_print_char
	
	call os_dump_registers

	popa
	ret