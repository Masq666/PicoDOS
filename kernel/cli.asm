; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; COMMAND LINE INTERFACE
;
; Functions:
;	os_command_line 	      - Prints welcome message
;	get_cmd 		      	  - Parses CMD input
;
; Todo:
;	* Support for ENV variables, PATH etc...
;	* Parsing of .bat files
; ==================================================================


; ==================================================================
; os_command_line - Prints welcome message
; ==================================================================
os_command_line:
	mov si, welcome_msg		    ; Print our
	call os_print_string		; welcome message.
	ret
; ==================================================================
; get_cmd - Parses CMD input
; ==================================================================
get_cmd:				    	; Main processing loop
	hlt				  		    ; Even though HLT was not used by MS-DOS
								; we want to save some CPU, and not let QEMU go at full throttle
	mov di, input			    ; Clear input buffer each time
	mov al, 0
	mov cx, 256
	rep stosb

	mov di, command 		    ; And single command buffer
	mov cx, 32
	rep stosb

	mov si, prompt			    ; Prompt A:\
	call os_print_string

	mov ax, input			    ; Get command string from user
	call os_input_string

	call os_print_newline

	mov ax, input			    ; Remove trailing spaces
	call os_string_chomp

	mov si, input			    ; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

	mov si, input			    ; Separate out the individual command
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Store location of full parameters

	mov si, input			    ; Store copy of command for later modifications
	mov di, command
	call os_string_copy



	; First, let's check to see if it's an internal command...

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, s_cli_dump			; 'DUMP' entered?
	call os_string_compare
	jc near os_cli_dump

	mov di, s_cli_testzone	 	; 'TESTZONE' entered?
	call os_string_compare
	jc near testzone

	mov di, s_cli_help			; 'HELP' entered?
	call os_string_compare
	jc near os_cli_help

	mov di, s_cli_cls			; 'CLS' entered?
	call os_string_compare
	jc near os_cli_cls

	mov di, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near list_directory

	mov di, s_cli_ver			; 'VER' entered?
	call os_string_compare
	jc near print_ver

;	 mov di, time_string		 ; 'TIME' entered?
;	 call os_string_compare
;	 jc near print_time

;	 mov di, date_string		 ; 'DATE' entered?
;	 call os_string_compare
;	 jc near print_date

	mov di, cat_string			; 'CAT' entered?
	call os_string_compare
	jc near cat_file

	mov di, del_string			; 'DEL' entered?
	call os_string_compare
	jc near del_file

	mov di, copy_string			; 'COPY' entered?
	call os_string_compare
	jc near copy_file

	mov di, ren_string			; 'REN' entered?
	call os_string_compare
	jc near ren_file

	mov di, size_string			; 'SIZE' entered?
	call os_string_compare
	jc near size_file

	mov di, s_cli_mem			; 'MEM' entered?
	call os_string_compare
	jc near os_cli_mem

	mov di, s_cli_reboot		; 'REBOOT' entered?
	call os_string_compare
	jc near os_cli_reboot
	
	; If the user hasn't entered any of the above commands, then we
	; need to check for an executable file -- .BIN, .COM or .EXE, and the
	; user may not have provided the extension

	mov ax, command
	call os_string_uppercase
	call os_string_length


	; If the user has entered, say, MEGACOOL.BIN, we want to find that .BIN
	; bit, so we get the length of the command, go four characters back to
	; the full stop, and start searching from there

	mov si, command
	add si, ax

	sub si, 4


	mov di, pte_extension		; .PTE and .BIN load the same way.
	call os_string_compare
	jc bin_file

	mov di, bin_extension		; Is there a .BIN extension?
	call os_string_compare
	jc bin_file

	mov di, com_extension		; Or is there a .COM extension?
	call os_string_compare
	jc execute_com

	jmp no_extension

; ==================================================================
; EXECUTE MikeOS .BIN executable
; ==================================================================
bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	xor ax, ax					; Clear all registers
	xor bx, bx
	xor cx, cx
	xor dx, dx
	mov word si, [param_list]
	mov di, 0

	call 32768					; Call the external program

	jmp get_cmd					; When program has finished, start again

; ==================================================================
; EXECUTE DOS .COM Executables
; ==================================================================
execute_com:
	mov ax, command
	mov bx, 0
	mov cx, 8100h
	call os_load_file
	jc total_fail
	
	cli							; We need to prevent Interrupts while changing segments
	mov ax, [COM_LOAD]			; We're loading .COM at segment 0860h
	mov	es, ax	

	 
	sub	ax, 10h 				; "org 100h" stuff :)
	mov	es, ax
	mov	ds, ax
	mov	ss, ax
	xor	sp, sp

	push 0x0010					; Points to int20 function
	push es
	push word 100h
	
	sti							; Turn Interrupts on again
	retf						; Make a far jump into application
	jmp $
	
no_extension:
	;mov ax, command
	;call os_string_length

	;mov si, command
	;add si, ax

	;mov byte [si], '.'
	;mov byte [si+1], 'P'
	;mov byte [si+2], 'T'
	;mov byte [si+3], 'E'
	;mov byte [si+4], 0

	mov ax, command
	mov bx, pte_extension
	mov cx, tmp_string
	call os_string_join

	mov ax, cx
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bin_ext

	jmp execute_bin


try_bin_ext:
;	 mov ax, command
;	 call os_string_length

;	 mov si, command
;	 add si, ax
;	 sub si, 4

;	 mov byte [si], '.'
;	 mov byte [si+1], 'B'
;	 mov byte [si+2], 'I'
;	 mov byte [si+3], 'N'
;	 mov byte [si+4], 0

;	 jmp execute_bin
	mov ax, command
	mov bx, bin_extension
	mov cx, tmp_string
	call os_string_join

	mov ax, cx
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	jmp execute_bin

total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd

; ==================================================================

;print_time:
	;mov bx, tmp_string
	;call os_get_time_string
	;mov si, bx
	;call os_print_string
	;call os_print_newline
;	 jmp get_cmd


; ------------------------------------------------------------------

;print_date:
	;mov bx, tmp_string
	;call os_get_date_string
	;mov si, bx
	;call os_print_string
	;call os_print_newline
;	 jmp get_cmd

; ==================================================================
; INTERNAL COMMAND
; TESTZONE - Test zone
; ==================================================================
testzone:
	call os_testzone
	jmp get_cmd
; ==================================================================
; INTERNAL COMMAND
; VER - Print PicoDOS version number
; ==================================================================
print_ver:
	mov si, version_msg
	call os_print_string
	jmp get_cmd

; ==================================================================
; INTERNAL COMMAND
; DIR - Displays Directory Contents
; ==================================================================
list_directory:
	xor cx, cx			; Counter

	mov ax, dirlist 		; Get list of files on disk
	call os_get_file_list

	mov si, dirlist
	mov ah, 0Eh			; BIOS teletype function

.repeat:
	lodsb				; Start printing filenames
	cmp al, 0			; Quit if end of string
	je .done

	cmp al, ','			; If comma in list string, don't print it
	jne .nonewline
	pusha
	call os_print_newline		; But print a newline instead
	popa
	jmp .repeat

.nonewline:
	int 10h
	jmp .repeat

.done:
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

cat_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		; Check if file exists
	jc .not_found

	mov cx, 32768			; Load file into second 32K
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			; Nothing in the file?
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			; int 10h teletype function
.loop:
	lodsb				; Get byte from loaded file

	cmp al, 0Ah			; Move to start of line if we get a newline char
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h 			; Display it
	dec bx				; Count down file size
	cmp bx, 0			; End of file?
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

del_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Deleted file: ', 0
	.failure_msg	db 'Could not delete file - does not exist or write protected', 13, 10, 0


; ------------------------------------------------------------------

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_get_file_size
	jc .failure

	mov si, .size_msg
	call os_print_string

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd


.failure:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


	.size_msg	db 'Size (in bytes) is: ', 0


; ------------------------------------------------------------------

copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			; Store first filename temporarily
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd


	.tmp		dw 0
	.success_msg	db 'File copied successfully', 13, 10, 0


; ==================================================================
; INTERNAL COMMAND
; REN - Rename File
;
; USAGE: ren old_filename new_filename
; ==================================================================
ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			; Store first filename temporarily
	mov ax, bx			; Get destination
	call os_file_exists		; Check to see if it exists
	jnc .already_exists

	mov ax, cx			; Get first filename back
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'File renamed successfully', 13, 10, 0
	.failure_msg	db 'Operation failed - file not found or invalid filename', 13, 10, 0


; ==================================================================
; INCLUDES
; ==================================================================
	include "kernel/commands/cls.asm"		; CLS Command
	include "kernel/commands/dump.asm"		; DUMP Command
	include "kernel/commands/help.asm"		; HELP Command
	include "kernel/commands/mem.asm"		; MEM Command
	include "kernel/commands/reboot.asm"	; REBOOT Command

; ==================================================================
; DATA
; ==================================================================

	input:			times 256 db 0
	command:		times 32 db 0

	dirlist:		times 1024 db 0
	tmp_string:		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	; If no extension, try extensions in this order.
	pte_extension		db '.PTE', 0	; PicoEXE - Tiny Executable Format
	bin_extension		db '.BIN', 0	; MikeOS Application
	com_extension		db '.COM', 0	; DOS .COM file org 100h
	exe_extension		db '.EXE', 0	; DOS MZ .EXE

	prompt			db 13, 10,'A:\', 0

	invalid_msg		db 'Bad command or file name', 13, 10, 0
	nofilename_msg	db 'No filename or not enough filenames', 13, 10, 0
	notfound_msg	db 'File not found', 13, 10, 0
	writefail_msg	db 'Could not write file. Write protected or invalid filename?', 13, 10, 0
	exists_msg		db 'Target file already exists!', 13, 10, 0

	welcome_msg		db 'Welcome to PicoDOS ',PICO_VER, 13, 10, 0
	version_msg		db 13, 10,'PicoDOS [Version ',PICO_VER,']',13,10,0
	
	dir_string		db 'DIR', 0
	;time_string		 db 'TIME', 0
	;date_string		 db 'DATE', 0

	cat_string		db 'CAT', 0		; Should be an external app
	del_string		db 'DEL', 0		; Should be an external app
	ren_string		db 'REN', 0		; Should be an external app
	copy_string		db 'COPY', 0		; Should be an external app
	size_string		db 'SIZE', 0		; Merge with DIR

; ==================================================================
; INTERNAL COMMANDS
; ==================================================================
	s_cli_cls		db 'CLS', 0
	s_cli_dump		db 'DUMP', 0
	s_cli_help		db 'HELP', 0
	s_cli_mem		db 'MEM', 0	
	s_cli_reboot	db 'REBOOT', 0
	s_cli_testzone	db 'TESTZONE', 0
	s_cli_ver		db 'VER', 0

; ==================================================================
