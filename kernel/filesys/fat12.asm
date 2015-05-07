; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; FAT12 FILESYSTEM ROUTINES
;
; Functions:
;	fat12_create			- 3Ch	- "CREAT"      - CREATE OR TRUNCATE FILE
;	vfs_read			- 3Fh	- "READ"       - READ FROM FILE OR DEVICE
;	vfs_write			- 40h	- "WRITE"      - WRITE TO FILE OR DEVICE
;	vfs_open			- 3Dh	- "OPEN"       - OPEN EXISTING FILE
;	vfs_close			- 3Eh	- "CLOSE"      - CLOSE FILE
;	vfs_unlink			- 41h	- "UNLINK"     - DELETE FILE
;	vfs_rename			- 56h	- "RENAME"     - RENAME FILE
;	vfs_lseek			- 42h	- "LSEEK"      - SET CURRENT FILE POSITION
;	vfs_chmod			- 4300h - "CHMOD"      - GET FILE ATTRIBUTES
;					- 4301h - "CHMOD"      - SET FILE ATTRIBUTES
;	vfs_get_ftime			- 5700h -	       - GET FILE'S LAST-WRITTEN DATE AND TIME
;	vfs_set_ftime			- 5701h -	       - SET FILE'S LAST-WRITTEN DATE AND TIME
;
;	vfs_cwd 			- 47h	- "CWD"        - GET CURRENT DIRECTORY
;	vfs_chdir			- 3Bh	- "CHDIR"      - SET CURRENT DIRECTORY
;	vfs_mkdir			- 39h	- "MKDIR"      - CREATE SUBDIRECTORY
;	vfs_rmdir			- 3Ah	- "RMDIR"      - REMOVE SUBDIRECTORY
;
;	vfs_freespace			- 36h	-	       - GET FREE DISK SPACE
;	vfs_get_drive			- 19h	-	       - GET CURRENT DEFAULT DRIVE
;	vfs_set_drive			- 0Eh	-	       - SELECT DEFAULT DRIVE
;
; Internal Functions:
;	fat12_file_exists		- Check if a file exists
;	int_filename_convert
; ==================================================================

; ==================================================================
; DATA STRUCTURES
; ==================================================================
struc FAT12_BOOTSECTOR {
    .Bootjmp		   resb 3	  ; 3 bytes for jump over the structure
    .OEMLabel		   resb 8	  ; Disk label
    .BytesPerSector	   resw 1	  ; Bytes per sector
    .SectorsPerCluster	   resb 1	  ; Sectors per cluster
    .ReservedForBoot	   resw 1	  ; Reserved sectors for boot record
    .NumberOfFats	   resb 1	  ; Number of copies of the FAT
    .RootDirEntries	   resw 1	  ; Number of entries in root dir
    .LogicalSectors	   resw 1	  ; Number of logical sectors
    .MediumByte 	   resb 1	  ; Medium descriptor byte
    .SectorsPerFat	   resw 1	  ; Sectors per FAT
    .SectorsPerTrack	   resw 1	  ; Sectors per track (36/cylinder)
    .Sides		   resw 1	  ; Number of sides/heads
    .HiddenSectors	   resd 1	  ; Number of hidden sectors
    .LargeSectors	   resd 1	  ; Number of LBA sectors
    .DriveNo		   resw 1	  ; Drive No: 0
    .Signature		   resb 1	  ; Drive signature: 41 for floppy
    .VolumeID		   resd 1	  ; Volume ID: any number
    .VolumeLabel	   resb 11	  ; Volume Label: any 11 chars
    .FileSystem 	   resb 8	  ; File system type: don't change!
    .BootCode		   resb 448	  ; Code to load OS.
    .BootSignature	   resw 1	  ; 55AAh
}

; Attributes:
; BIT	MASK	ATTRIBUTE
; 0	01h	Read-only
; 1	02h	Hidden
; 2	04h	System
; 3	08h	Volume Label
; 4	10h	Subdirectory
; 5	20h	Archive
; 6	40h	Unused
; 7	80h	Unused
struc FAT12_DIR_ENTRY {
    .FileName		   resb 8	  ; Filename
    .FileExtension	   resb 3	  ; Extension
    .Attributes 	   resb 1	  ; Attributes
    .Reserved		   resb 1	  ; Reserved
    .CreationTime10sec	   resb 1	  ; Creation time in tents of a second
    .CreationTime	   resw 1	  ; Creation time
    .CreationDate	   resw 1	  ; Creation date
    .LastAccessDate	   resw 1	  ; Last Access Date
    .ReservedFAT32	   resw 1	  ; Reserved for FAT32 (Ignore in FAT12)
    .LastModificationTime  resw 1	  ; Last Write Time
    .LastModificationDate  resw 1	  ; Last Write Date
    .FirstClusterLow	   resw 1	  ; First Logical Cluster
    .Size		   resd 1	  ; File Size (in bytes)
}
; ==================================================================
; INTERNAL ROUTINES
; ==================================================================

; ==================================================================
; int_filename_convert -- Change 'TEST.BIN' into 'TEST	  BIN' as per FAT12
;
;	IN: AX = filename string
;
;	OUT: AX = location of converted string (carry set if invalid)
; ==================================================================
int_filename_convert:
	pusha

	mov si, ax

	call os_string_length
	cmp ax, 14			; Filename too long?
	jg .failure			; Fail if so

	cmp ax, 0
	je .failure			; Similarly, fail if zero-char string

	mov dx, ax			; Store string length for now

	mov di, .dest_string

	mov cx, 0
.copy_loop:
	lodsb
	cmp al, '.'
	je .extension_found
	stosb
	inc cx
	cmp cx, dx
	jg .failure			; No extension found = wrong
	jmp .copy_loop

.extension_found:
	cmp cx, 0
	je .failure			; Fail if extension dot is first char

	cmp cx, 8
	je .do_extension		; Skip spaces if first bit is 8 chars

	; Now it's time to pad out the rest of the first part of the filename
	; with spaces, if necessary

.add_spaces:
	mov byte [di], ' '
	inc di
	inc cx
	cmp cx, 8
	jl .add_spaces

	; Finally, copy over the extension
.do_extension:
	lodsb				; 3 characters
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb

	mov byte [di], 0		; Zero-terminate filename

	popa
	mov ax, .dest_string
	clc				; Clear carry for success
	ret


.failure:
	popa
	stc				; Set carry for failure
	ret


	.dest_string:	 times 13 db 0