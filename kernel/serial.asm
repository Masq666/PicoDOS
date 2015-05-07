; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; SERIAL COMMUNICATION ROUTINES
;
; Functions:
;	os_set_serial_port	      - Set port to use
;	os_serial_port_enable	      - Set up the serial port for transmitting data
;	os_serial_get_status	      - Get port status
;	os_send_via_serial	      - Send a byte via the serial port
;	os_send_string_via_serial     - Send a string via the serial port
;	os_get_via_serial	      - Get a byte from the serial port
;
; Todo:
;	* Move away from INT 14h and use the 8250 Serial Communications Chip
;	  directly, this way we can use speeds above 9600 bps.
;	  And also enable Interrupt driven communication.
; ==================================================================


COMPORT 		dw 0		; Port number (00h-03h) 0 = COM1


; ==================================================================
; os_set_serial_port - Set port to use
; IN: AX = Port number (00h-03h)
;
; OUT: Nothing
; ==================================================================
os_set_serial_port:
	mov [cs:COMPORT], ax
	ret

; ==================================================================
; os_serial_port_enable - Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 bps)
;	   1 for slow mode (1200 bps)
; OUT: Nothing
; ==================================================================
os_serial_port_enable:
	pusha

	mov dx, [cs:COMPORT]

	cmp ax, 1
	je .slow_mode

	mov ax, 0000000011100011b	; 9600 baud, no parity, 8 data bits, 1 stop bit
					; AH is zero, the first 8 zeros.
	jmp .finish

.slow_mode:
	mov ax, 0000000010000011b	; 1200 baud, no parity, 8 data bits, 1 stop bit
					; AH is zero, the first 8 zeros.
.finish:
	int 14h

	popa
	ret

; ==================================================================
; os_serial_get_status - Get port status
; IN: Nothing
;
; OUT: AH = line status
;      AL = modem status
; ==================================================================
os_serial_get_status:
	push dx

	mov ax, 0300h
	mov dx, [cs:COMPORT]
	int 14h

	pop dx
	ret
; ==================================================================
; os_send_via_serial - Send a byte via the serial port
; IN: AL = byte to send via serial
;
; OUT: AH = Bit 7 clear on success
; ==================================================================
os_send_via_serial:
	push dx

	mov ah, 01h
	mov dx, [cs:COMPORT]
	int 14h

	pop dx
	ret

; ==================================================================
; os_send_string_via_serial - Send a string via the serial port
; IN: SI = message location (zero or $ terminated string)
;
; OUT: Nothing
; ==================================================================
os_send_string_via_serial:
	pusha

.repeat:
	lodsb				; Get char from string
	or  al, al
	jz  .done			; If char is zero, end of string

	cmp al, '$'			; Or if it is a $ terminated string.
	je .done

	call os_send_via_serial 	; Otherwise, send byte via COM1
	jmp .repeat			; And move on to next char
.done:
	popa
	ret

; ==================================================================
; os_get_via_serial - Get a byte from the serial port
; IN: Nothing
;
; OUT: AL = byte that was received
;      AH = Bit 7 clear on success
; ==================================================================
os_get_via_serial:
	push dx

	mov ah, 02h
	mov dx, [cs:COMPORT]
	int 14h

	pop dx
	ret

