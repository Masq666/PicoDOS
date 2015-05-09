; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; INTERNAL COMMAND
;
; HELP - Display supported commands
;
; Functions:
;	os_cli_help		      - Display supported commands
; ==================================================================


; ==================================================================
; os_cli_help - Display supported commands
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================
os_cli_help:
	mov si, .help_text
	call os_print_string		; Print supported commands
	jmp get_cmd					; Return to CLI/CMD

	.help_text	db 13, 10,'Supported commands:', 13, 10
				db 'CAT       Print content of file', 13, 10
				db 'CLS       Clears the screen', 13, 10
				db 'COPY      Copy file to another location', 13, 10
				db 'DATE      Displays current date', 13, 10
				db 'DEL       Delete file', 13, 10
				db 'DIR       Lists all files and subfolders in a directory', 13, 10
				db 'DUMP      Dump registers to screen', 13, 10
				db 'MEM       Display memory information', 13, 10
				db 'REBOOT    Reboot PC', 13, 10
				db 'REN       Rename file', 13, 10
				db 'SIZE      Display file size', 13, 10
				db 'TIME      Displays current time', 13, 10
				db 'VER       Display PicoDOS version number', 13, 10, 0