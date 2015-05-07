; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; PORT ROUTINES
;
; Functions:
;	os_port_byte_out	      - Send byte to a port
;	os_port_byte_in 	      - Receive byte from a port
;
; ==================================================================


; ==================================================================
; os_port_byte_out - Send byte to a port
; IN: DX = port address, AL = byte to send
;
; OUT: Nothing
; ==================================================================
os_port_byte_out:
	out dx, al
	ret

; ==================================================================
; os_port_byte_in - Receive byte from a port
; IN: DX = port address
;
; OUT: AL = byte from port
; ==================================================================
os_port_byte_in:
	pusha

	in al, dx
	mov word [.tmp], ax

	popa
	mov ax, [.tmp]
	ret

	.tmp dw 0

