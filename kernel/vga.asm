; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; VGA GRAPHICS ROUTINES
;
; These are not high performance graphics functions and should
; not be used for games, these functions are here to be the backbone
; of a very simple GUI.
; 
; Functions:
;	os_vga_init	       	  	- Set video mode 12h
;	os_vga_pset 			- Put Pixel at X/Y
; ==================================================================

VIDEO_SEG = 0A000h

; ==================================================================
; os_vga_init - Set video mode 12h
;
; IN: None
; OUT: Nothing (registers preserved)
; ==================================================================
os_vga_init:
	mov ax, 0012h			; mode = 12h (640x480x16)
	int 10h 				; Call BIOS service
	ret

; ==================================================================
; os_vga_pset - Put Pixel at X/Y
;
; IN: AL = Color
;	  CX = X
;	  DX = Y
; OUT: Nothing (registers preserved)
; ==================================================================	
os_vga_pset:	
	mov ah, 0Ch	  			; function 0Ch
	int 10h 				; Call BIOS service
	ret