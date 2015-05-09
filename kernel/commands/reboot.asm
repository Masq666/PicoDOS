; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERNAL COMMAND
;
; REBOOT - Display supported commands
;
; Functions:
;	os_cli_reboot 		      - Reboot the PC
; ==================================================================


; ==================================================================
; os_cli_reboot - Reboot the PC
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_cli_reboot:
	mov si, .reboot
	call os_print_string		; Print our reboot message
	call os_wait_for_key		; and wait for a keypress
	call os_reboot				; Reboot
	jmp get_cmd					; Return to CLI/CMD

	.reboot		db 13, 10, 'Press any key to reboot...', 0