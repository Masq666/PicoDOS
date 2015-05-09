; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERNAL COMMAND
;
; DUMP - Display supported commands
;
; Functions:
;	os_cli_dump 		      - Dump Registers to STDOUT
; ==================================================================


; ==================================================================
; os_cli_dump - Dump Registers to STDOUT
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_cli_dump:
	call os_dump_registers		; Dump registers
	jmp get_cmd					; Return to CLI/CMD
