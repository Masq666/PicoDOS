; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERRUPT FUNCTION AH = 05h
;
; WRITE CHARACTER TO PRINTER
;	IN: AH = 05h
;	IN: DL = Character to print
;
;	OUT: None
;
; ==================================================================
int21_05:
	push ax
	push dx

.printit:
	xor ax, ax
	mov al, dl			; AL = chararcter to print
	xor dx, dx			; Printer number 0
	int 17h 			; Print it!
	push ax

	and al, 00001000b		; I/O error
	jnz .IOError

	pop ax
	push ax

	and al, 00100000b		; No paper
	jnz .NoPaper

	pop ax
	push ax

	and al, 10000000b		; Not busy
	jz .busy
	pop ax

.return:
	mov byte [.probes], 0		; Restore probes
	pop dx
	pop ax
	iret

.IOError:
	pop ax
	mov si, .IOmsg
	call os_print_string
	jmp .return

.NoPaper:
	pop ax
	mov si, .Papermsg
	call os_print_string
	jmp .return

.busy:					; If busy, DOS wait
	pop ax				; It was at 1980
	inc byte [.probes]		; Now, we don't have time :-)
	cmp byte [.probes], 3		; Only 3 probes, and we go away
	jnz .printit
	mov si, .busymsg
	call os_print_string
	jmp .return

	.probes 	db 0
	.IOmsg		db 'I/O error while printing. Please verify printer', 10, 13, 0
	.Papermsg	db 'No paper. Please verify printer', 10, 13, 0
	.busymsg	db 'Printer is busy. Please probe later', 10, 13, 0