; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; MISCELLANEOUS ROUTINES
;
; Functions:
;	os_save_regs 			  - Save all registers
;	os_pause		       	  - Delay execution for specified 110ms chunks
;	os_reboot 				  - Reboots the system
;	os_fatal_error		      - Display error message and halt execution
;	os_missing_mikeos	      - Does nothing, unimplemented MikeOS calls ends up here
; ==================================================================

	MIKEOS_API_VER = 16			; API version for programs to check

; ==================================================================
; os_save_regs - Save all registers
;
; IN: Nothing 
; OUT: Nothing
; ==================================================================
os_save_regs:
	mov [cs:OS_REG.AX], ax
	mov [cs:OS_REG.BX], bx
	mov [cs:OS_REG.CX], cx
	mov [cs:OS_REG.DX], dx
	
	mov [cs:OS_REG.CS], cs
	mov [cs:OS_REG.DS], ds
	mov [cs:OS_REG.ES], es
	mov [cs:OS_REG.SS], ss
	mov [cs:OS_REG.FS], fs
	mov [cs:OS_REG.GS], gs
	
	mov [cs:OS_REG.SI], si
	mov [cs:OS_REG.DI], di
	mov [cs:OS_REG.BP], bp
	mov [cs:OS_REG.SP], sp
	
	ret

; ==================================================================
; os_restore_regs - Registers restored from OS_REG struct.
;
; IN: Nothing 
; OUT: All registers changed
; ==================================================================	
os_restore_regs:
	cli
	;mov ax, [cs:OS_REG.AX]
	;mov bx, [cs:OS_REG.BX]
	;mov cx, [cs:OS_REG.CX]
	;mov dx, [cs:OS_REG.DX]
	
	;xor ax, ax
	mov ax, cs
	;mov cs, [cs:OS_REG.CS]
	mov ds, [cs:OS_REG.DS]
	mov es, [cs:OS_REG.ES]
	mov ss, ax
	mov fs, [cs:OS_REG.FS]
	mov gs, [cs:OS_REG.GS]
	
	;mov si, [cs:OS_REG.SI]
	;mov di, [cs:OS_REG.DI]
	;mov bp, [cs:OS_REG.BP]
	;mov sp, [cs:OS_REG.SP]
	;xor sp, sp
	mov sp, os_stack+512
	sti
	ret
; ==================================================================
; os_get_api_version - Return current version of MikeOS API
;
; IN: Nothing 
; OUT: AL = API version number
; ==================================================================
os_get_api_version:
	mov al, MIKEOS_API_VER
	ret

; ==================================================================
; os_pause - Delay execution for specified 110ms chunks
;
; IN: AX = 100 millisecond chunks to wait (max delay is 32767,
;     which multiplied by 55ms = 1802 seconds = 30 minutes)
; OUT: Nothing
; ==================================================================
os_pause:
	pusha
	cmp ax, 0
	je .time_up			; If delay = 0 then bail out

	mov cx, 0
	mov [.counter_var], cx		; Zero the counter variable

	mov bx, ax
	xor ax, ax

	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; Multiply by number of 110ms chunks required 
	mov [.orig_req_delay], ax	; Save it

	mov ah, 0
	int 1Ah 			; Get tick count	

	mov [.prev_tick_count], dx	; Save it for later comparison

.checkloop:
	mov ah, 0
	int 1Ah 			; Get tick count again

	cmp [.prev_tick_count], dx	; Compare with previous tick count

	jne .up_date			; If it's changed check it
	jmp .checkloop			; Otherwise wait some more

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Inc counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; Is counter_var = required delay?
	jge .time_up			; Yes, so bail out

	mov [.prev_tick_count], dx	; No, so update .prev_tick_count 

	jmp .checkloop			; And go wait some more


	.orig_req_delay 	dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0

; ==================================================================
; os_reboot - Reboots the system
;
; IN: Nothing
;
; OUT: Nothing
; ==================================================================	
os_reboot:
       db 0xea			; Machine language to jump to
       dw 0x0000		; address FFFF:0000 (reboot)
       dw 0xffff		; we're rebooting!

; ==================================================================
; os_fatal_error - Display error message and halt execution
;
; IN: AX = error message string location
;
; OUT: Nothing
; ==================================================================
os_fatal_error:
	mov bx, ax			; Store string location for now

	xor dx, dx
	call os_move_cursor

	pusha
	mov ah, 09h			; Draw red bar at top
	mov al, ' '
	mov bh, 0
	mov bl, 01001111b
	mov cx, 240

	int 10h
	popa

	xor dx, dx
	call os_move_cursor

	mov si, .msg_inform		; Inform of fatal error
	call os_print_string

	mov si, bx			; Program-supplied error message
	call os_print_string

	jmp $				; Halt execution

	
	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0

; ==================================================================
; MISSING MIKEOS SYSTEM CALL POINTS HERE.
; ==================================================================
os_missing_mikeos:

	ret
