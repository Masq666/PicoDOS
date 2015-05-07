; ==================================================================
; The Mike Operating System bootloader
; Copyright (C) 2006 - 2013 MikeOS Developers -- see doc/LICENSE.TXT
;
; Based on a free boot loader by E Dehling. It scans the FAT12
; floppy for KERNEL.BIN (the MikeOS kernel), loads it and executes it.
; This must grow no larger than 512 bytes (one sector), with the final
; two bytes being the boot signature (AA55h). Note that in FAT12,
; a cluster is the same as a sector: 512 bytes.
; ==================================================================


	use16

	jmp short bootloader_start	; Jump past disk description section
	nop				; Pad out before disk description


; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

OEMLabel		db "PICOBOOT"	; Disk label
BytesPerSector		dw 512		; Bytes per sector
SectorsPerCluster	db 1		; Sectors per cluster
ReservedForBoot 	dw 1		; Reserved sectors for boot record
NumberOfFats		db 1		; Number of FS Bitmaps
RootDirEntries		dw 128		; Number of entries in root dir
					; (128 * 32 = 4096 = 8 sectors to read)
LogicalSectors		dw 2880 	; Number of logical sectors
MediumByte		db 0F0h 	; Medium descriptor byte
SectorsPerFat		dw 9		; Sectors per FAT
SectorsPerTrack 	dw 18		; Sectors per track (36/cylinder)
Sides			dw 2		; Number of sides/heads
HiddenSectors		dd 0		; Number of hidden sectors
LargeSectors		dd 0		; Number of LBA sectors
DriveNo 		dw 0		; Drive No: 0
Signature		db 41		; Drive signature: 41 for floppy
VolumeID		dd 00000000h	; Volume ID: any number
VolumeLabel		db "PICODOS    "; Volume Label: any 11 chars
FileSystem		db "PICOFS  "	; File system type: don't change!


; ------------------------------------------------------------------
; Main bootloader code

bootloader_start:
	mov ax, 07C0h			; Set up 4K of stack space above buffer
	add ax, 544			; 8k buffer = 512 paragraphs + 32 paragraphs (loader)
	cli				; Disable interrupts while changing stack
	mov ss, ax
	mov sp, 4096
	sti				; Restore interrupts

	mov ax, 07C0h			; Set data segment to where we're loaded
	mov ds, ax

	; NOTE: A few early BIOSes are reported to improperly set DL

	cmp dl, 0
	je no_change
	mov [bootdev], dl		; Save boot device number
	mov ah, 8			; Get drive parameters
	int 13h
	jc fatal_disk_error
	and cx, 3Fh			; Maximum sector number
	mov [SectorsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx

no_change:
	xor eax, eax			; Needed for some older BIOSes

; First, we need to load the root directory from the disk. Technical details:
; This is very easy, the root directory always starts at logical sector 3
; for images smaller than 2Mb, first sector is bootsector, second in bitmap.

floppy_ok:				; Ready to read first block of data
	mov ax, 2			; Root dir starts at logical sector 3
	call l2hts

	mov si, buffer			; Set ES:BX to point to our buffer (see end of code)
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 8			; And read 8 of them

	pusha				; Prepare to enter loop


read_root_dir:
	popa				; In case registers are altered by int 13h
	pusha

	stc				; A few BIOSes do not set properly on error
	int 13h 			; Read sectors using BIOS

	jnc search_dir			; If read went OK, skip ahead
	call reset_floppy		; Otherwise, reset floppy controller and try again
	jnc read_root_dir		; Floppy reset OK?

	jmp reboot			; If not, fatal double error


search_dir:
	popa

	mov ax, ds			; Root dir is now in [buffer]
	mov es, ax			; Set DI to this info
	mov di, buffer

	mov cx, word [RootDirEntries]	; Search all (128) entries
	xor ax, ax			; Searching at offset 0


next_root_entry:
	xchg cx, dx			; We use CX in the inner loop...

	mov si, kern_filename		; Start searching for kernel filename
	mov cx, 11
	rep cmpsb
	je found_file_to_load		; Pointer DI will be at offset 11

	add ax, 32			; Bump searched entries by 1 (32 bytes per entry)

	mov di, buffer			; Point to next entry
	add di, ax

	xchg dx, cx			; Get the original CX back
	loop next_root_entry

	mov si, file_not_found		; If kernel is not found, bail out
	call print_string
	jmp reboot


found_file_to_load:			; Fetch cluster and load Kernel into RAM
	mov si, file_found	    ; If kernel is not found, bail out
	call print_string
	mov ax, word [es:di+0Fh]      ; Offset 11 + 15 = 26, contains 1st cluster
	mov word [cluster], ax

	mov ax, word [es:di+1Eh]      ; Offset 11 + 17 = 28, contains file size
					; Sectors to read = (Size / Sector Size) + 1

	mov cx, 512			; Sector size in bytes.
	div cx				; Divide AX by 512 (File Size / Sector Size)
	inc ax				; Add 1 to number of sectors to read.
	mov word [size], ax

	mov ax, [cluster]		; First cluster of Kernel
	call l2hts


	mov ax, 0050h
	mov es, ax
	mov di, buffer			; ES:BX points to our buffer
	mov bx, di

	mov ah, 2			; int 13h params: read sectors
	mov al, 11 ; byte [size]	  ; Read sectors containing kernel

	pusha				; Prepare to enter loop


read_fat:
	popa				; In case registers are altered by int 13h
	pusha

	stc
	int 13h 			; Read sectors using the BIOS

	jnc read_fat_ok 		; If read went OK, skip ahead
	call reset_floppy		; Otherwise, reset floppy controller and try again
	jnc read_fat			; Floppy reset OK?

; ******************************************************************
fatal_disk_error:
; ******************************************************************
	mov si, disk_error		; If not, print error message and reboot
	call print_string
	jmp reboot			; Fatal double error


read_fat_ok:
	mov si, file_found	    ; If kernel is not found, bail out
	call print_string
	popa

       ; mov ax, 0050h			 ; Segment where we'll load the kernel
       ; mov es, ax
       ; xor bx, bx			 ; mov bx, 0

	mov dl, byte [bootdev]		; Provide kernel with boot device info

	jmp 0050h:0100h 		; Jump to entry point of loaded kernel!

; ------------------------------------------------------------------
; BOOTLOADER SUBROUTINES

reboot:
	xor ax, ax			; mov ax, 0
	int 16h 			; Wait for keystroke
	xor ax, ax			; mov ax, 0
	int 19h 			; Reboot the system


print_string:				; Output string in SI to screen
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string
	int 10h 			; Otherwise, print it
	jmp short .repeat

.done:
	popa
	ret


reset_floppy:		; IN: [bootdev] = boot device; OUT: carry set on error
	push ax
	push dx
	xor ax, ax			; mov ax, 0
	mov dl, byte [bootdev]
	stc
	int 13h
	pop dx
	pop ax
	ret


l2hts:			; Calculate head, track and sector settings for int 13h
			; IN: logical sector in AX, OUT: correct registers for int 13h
	push bx
	push ax

	mov bx, ax			; Save logical sector

	xor dx, dx			; DX = 0 First the sector
	div word [SectorsPerTrack]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	xor dx, dx			; Now calculate the head
	div word [SectorsPerTrack]
	xor dx, dx
	div word [Sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	mov dl, byte [bootdev]		; Set correct device

	ret


; ------------------------------------------------------------------
; STRINGS AND VARIABLES

	kern_filename	db "PICODOS SYS"	; MikeOS kernel filename

	disk_error	db "Floppy error! Press any key...", 0
	file_not_found	db "PICODOS.SYS not found!", 0
	file_found	db "found!", 0

	bootdev 	db 0	; Boot device number
	cluster 	dw 0	; Cluster of the file we want to load
	size		dw 0	; Size of file we want to load.


; ------------------------------------------------------------------
; END OF BOOT SECTOR AND BUFFER START

	times 510-($-$$) db 0	; Pad remainder of boot sector with zeros
	dw 0AA55h		; Boot signature (DO NOT CHANGE!)


buffer: 			; Disk buffer begins (8k after this, stack starts)


; ==================================================================

