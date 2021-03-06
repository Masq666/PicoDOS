; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; A20 GATE ROUTINES
;
; Functions:
;	os_enable_a20	       	  - Enable the A20 Gate using the BIOS
;	os_disable_a20 			  - Disable the A20 Gate using the BIOS
;	os_status_a20 			  - Check A20 Gate Status
; ==================================================================

; ==================================================================
; os_enable_a20 - Enable the A20 Gate using the BIOS
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_enable_a20:
	push ax
	mov ax, 2401h
	int 15h
	pop ax
	ret
	
; ==================================================================
; os_disable_a20 - Disable the A20 Gate using the BIOS
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_disable_a20:
	push ax
	mov ax, 2400h
	int 15h
	pop ax
	ret

; ==================================================================
; os_status_a20 - Check A20 Gate Status
;
; IN: Nothing
;
; OUT: AL = 00h disabled, 01h enabled
; ==================================================================	
os_status_a20:
	mov ax, 2402h
	int 15h
	ret