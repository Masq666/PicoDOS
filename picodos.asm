; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; System Requirements
; CPU: 386+
; RAM: 640kb
; DISK: Floppy or HDD, PicoFS/FAT12/FAT16
; ==================================================================

format binary as "sys"			; File will be assembled to picodos.sys
use16							; 16bit addressing
org 0

disk_buffer	equ	24576		    ; 8K disk buffer starts at this offset.
								; 0	- 24575 Kernel Space			24K
								; 24576 - 32767 Disk Buffer			8K
								; 32768 - 65536 Application Space (.BIN)	32K
; ------------------------------------------------------------------
; OS CALL VECTORS -- Static locations for system call vectors
; Note: these cannot be moved, or it'll break the calls!

; The comments show exact locations of instructions in this section,
; and are used in dev/syscall.inc so that an external program can
; use a PicoDOS system call without having to know its exact position
; in the kernel source code. Each jmp instruction takes 3 bytes.

; This list will be as compatible with MikeOS as possible.
; Direct system calls can only be used by .bin files, and have a max size of 32Kb.
os_call_vectors:
	jmp   os_boot					; 0000h - Jump to label os_boot
	jmp   os_print_string		    ; 0003h - Write Sting to STDOUT
	jmp   os_move_cursor		    ; 0006h - Move Cursor
	jmp   os_clear_screen		    ; 0009h - Clear Screen
	jmp   os_missing_mikeos 	    ; 000Ch - os_print_horiz_line (NOT IMPLEMENTED)
	jmp   os_print_newline		    ; 000Fh - Print a New Line (13, 10)
	jmp   os_wait_for_key		    ; 0012h
	jmp   os_check_for_key		    ; 0015h
	jmp   os_int_to_string		    ; 0018h
	jmp   os_missing_mikeos 	    ; 001Bh - os_speaker_tone
	jmp   os_missing_mikeos 	    ; 001Eh - os_speaker_off
	jmp   os_load_file				; 0021h
	jmp   os_pause					; 0024h
	jmp   os_fatal_error		    ; 0027h
	jmp   os_missing_mikeos 	    ; 002Ah - os_draw_background
	jmp   os_string_length		    ; 002Dh
	jmp   os_string_uppercase	    ; 0030h
	jmp   os_string_lowercase	    ; 0033h
	jmp   os_input_string		    ; 0036h
	jmp   os_string_copy		    ; 0039h
	jmp   os_missing_mikeos 	    ; 003Ch - os_dialog_box
	jmp   os_string_join		    ; 003Fh - Join two strings into a third string
	jmp   os_get_file_list		    ; 0042h
	jmp   os_string_compare 	    ; 0045h
	jmp   os_string_chomp		    ; 0048h
	jmp   os_string_strip		    ; 004Bh - Removes specified character from a string (max 255 chars)
	jmp   os_string_truncate	    ; 004Eh - Chop string down to specified number of characters
	jmp   os_bcd_to_int				; 0051h
	jmp   os_missing_mikeos 	    ; 0054h - os_get_time_string
	jmp   os_missing_mikeos 	    ; 0057h - os_get_api_version
	jmp   os_missing_mikeos 	    ; 005Ah - os_file_selector
	jmp   os_missing_mikeos 	    ; 005Dh - os_get_date_string
	jmp   os_send_via_serial	    ; 0060h
	jmp   os_get_via_serial 	    ; 0063h
	jmp   os_find_char_in_string	; 0066h - Find location of character in a string
	jmp   os_get_cursor_pos 	    ; 0069h
	jmp   os_print_space		    ; 006Ch - Print a space to the screen
	jmp   os_dump_string	 	    ; 006Fh - os_dump_string
	jmp   os_print_digit		    ; 0072h - Displays contents of AX as a single digit
	jmp   os_print_1hex				; 0075h - Displays low nibble of AL in hex format
	jmp   os_print_2hex				; 0078h - Displays AL in hex format
	jmp   os_print_4hex				; 007Bh - Displays AX in hex format
	jmp   os_missing_mikeos 	    ; 007Eh - os_long_int_to_string
	jmp   os_missing_mikeos 	    ; 0081h - os_long_int_negate
	jmp   os_missing_mikeos 	    ; 0084h - os_set_time_fmt
	jmp   os_missing_mikeos 	    ; 0087h - os_set_date_fmt
	jmp   os_missing_mikeos 	    ; 008Ah - os_show_cursor
	jmp   os_missing_mikeos 	    ; 008Dh - os_hide_cursor
	jmp   os_dump_registers 	    ; 0090h
	jmp   os_string_strincmp	    ; 0093h
	jmp   os_write_file				; 0096h
	jmp   os_file_exists		    ; 0099h
	jmp   os_create_file		    ; 009Ch
	jmp   os_remove_file		    ; 009Fh
	jmp   os_rename_file		    ; 00A2h
	jmp   os_get_file_size		    ; 00A5h
	jmp   os_missing_mikeos 	    ; 00A8h - os_input_dialog
	jmp   os_missing_mikeos 	    ; 00ABh - os_list_dialog
	jmp   os_missing_mikeos 	    ; 00AEh - os_string_reverse
	jmp   os_missing_mikeos 	    ; 00B1h - os_string_to_int
	jmp   os_missing_mikeos 	    ; 00B4h - os_draw_block
	jmp   os_missing_mikeos 	    ; 00B7h - os_get_random
	jmp   os_missing_mikeos 	    ; 00BAh - os_string_charchange
	jmp   os_serial_port_enable	    ; 00BDh - Set up the serial port for transmitting data
	jmp   os_missing_mikeos 	    ; 00C0h - os_sint_to_string
	jmp   os_string_parse		    ; 00C3h - Take string (eg "run foo bar baz") and return pointers to zero-terminated strings
	jmp   os_missing_mikeos 	    ; 00C6h - os_run_basic
	jmp   os_port_byte_out		    ; 00C9h - Send byte to a port
	jmp   os_port_byte_in		    ; 00CCh - Receive byte from a port
	jmp   os_string_tokenize	    ; 00CFh - Reads tokens separated by specified char from a string
	
	;--- End of MikeOS System Calls ---
	MikeOS_Sys_Calls: times 30 db 0     ; Room Reserved for an additional 10 future MikeOS System Calls
	;--- PicoDOS spesific System Calls ---
	
	jmp   os_print_8hex				; 00F0h - Displays EAX in hex format
	jmp   os_send_string_via_serial ; 00F3h - Send a string via the serial port
	jmp   os_set_serial_port	    ; 00F6h - Set port to use (00h-03h)
	jmp   os_byte_to_bcd		    ; 00F9h - Converts a byte to a binary coded decimal number
	jmp   os_memcpy 			    ; 00FCh - Copy bytes in memory to another location
	jmp   os_memset 			    ; 00FFh - Fill block of memory
									; 0102h -
; ------------------------------------------------------------------
; Change these params to fake DOS version number, 6.22 for example.
	PICO_VER	equ  "1.01"	    ; PicoDOS Version String.
	PICO_VER_HI	=  5		    ; Set hi part of version
	PICO_VER_LO	=  0		    ; Set lo part of version
	PICO_VER_NR	=  0500h	    ; This is the one used by int21 - 30h
								; We pretend to be DOS 5.0
; ==================================================================
; START OF MAIN KERNEL CODE
; ==================================================================
os_boot:
	;mov   [SaveNameAddress],dx	     ; Save the address of file to load from bootloader
	;mov   [SaveCS],ax		     ; Save its CS
	;push  cs			     ; Push CS on stack
	;pop   ds			     ; Move CS into DS
	;push  ds			     ; Push DS
	;pop   es			     ; Move DS into ES
	cli				    		; Clear interrupts

	xor   ax, ax			    ; AX = 0
	mov   ss, ax			    ; Set stack segment and pointer
	mov   sp, 0FFFFh
	sti
	cld							; Make movs process from left to right.

	mov   ax, cs			    ; Set all segments to match where kernel is loaded
	mov   ds, ax
	mov   es, ax
	mov   fs, ax
	mov   gs, ax

	cmp   dl, 0
	je    .no_change
	mov   [bootdev], dl		    ; Save boot device number
	push  es
	mov   ah, 8					; Get drive parameters
	int   13h
	pop   es
	and   cx, 3Fh			    ; Maximum sector number
	mov   [SecsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			    ; Maximum head number
	inc   dx					; Head numbers start at 0 - add 1 for total
	mov   [Sides], dx

.no_change:

	call  os_install_interrupts	; Install Interrupt Services

	xor   ax, ax			    ; Use COM1 9600 bps AX = 0
	call  os_serial_port_enable	; System is now ready for serial communication

	call  os_clear_screen		; Clear the screen
Start2:

	call  os_command_line
; ==================================================================
; os_main - Starts the CLI which is our main loop.
; ==================================================================
os_main:
	call  get_cmd			    ; Start CLI / Command.com emulation

	jmp   os_main			    ; Not used, but if get_cmd for some reason issues a ret, start over.
; ==================================================================
; INCLUDES
; ==================================================================
	include "kernel/a20.asm"	    ; A20 Gate functions
	include "kernel/cli.asm"	    ; CLI / Command.com emulation
	include "kernel/int21.asm"	    ; DOS Interrupts
	include "kernel/screen.asm"	    ; Screen I/O functions
	include "kernel/keyboard.asm"	; Keyboard functions
	include "kernel/serial.asm"	    ; Serial Communication
	include "kernel/ports.asm"	    ; Port functions
	include "kernel/math.asm"	    ; Math functions
	include "kernel/string.asm"	    ; String functions
	include "kernel/vfs.asm"	    ; Virtual Filesystem
	include "kernel/misc.asm"	    ; Misc functions
	include "kernel/memory.asm"	    ; Memory functions

	include "test.asm"				; TESTZONE!
; ==================================================================
; DATA
; ==================================================================
	top_memory	dw 0
	end_memory	dw 0

	SaveNameAddress dw 0
	SaveCS		dw 0

	;KRNL_SEG	dw 0050h
	COM_LOAD	dw 0860h			; We Load COM/EXE at this segment, 67K from memory start.
									; the Kernel is loaded before this. 

	include "kernel/Data.inc"	    ; Data include files

; ==================================================================
; END OF KERNEL
; ==================================================================