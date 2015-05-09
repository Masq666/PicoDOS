; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERNAL COMMAND
;
; CLS - Display supported commands
;
; Functions:
;	os_cli_cls 		      - Display supported commands
; ==================================================================


; ==================================================================
; os_cli_cls - Clear Screen
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_cli_cls:
	call os_clear_screen		; Clear the screen
	jmp get_cmd					; Return to CLI/CMD
