; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; VIRTUAL FILESYSTEM ROUTINES
;
; Functions:
;	vfs_init			-		       - INITIALIZE THE VFS
;	vfs_create			- 3Ch	- "CREAT"      - CREATE OR TRUNCATE FILE
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
; Internal / Non DOS Functions:
;	vfs_file_exists 		- Check if a file exists
; ==================================================================

;	 include "kernel/filesys/fat12.asm"	      ; FAT12 Filesystem
;	 include "kernel/filesys/os_fat.asm"	      ; FAT12 Filesystem
	include "kernel/disk.asm"		      ; FAT12 Filesystem

	struc DRIVE {
	      .boot			db   0		      ; Boot device number
	      .current		db   0		      ; Current Drive
	}

	struc VFS {
	      .create		dw   vfs_create
	      .read			dw   vfs_read
	      .write		dw   vfs_write
	      .open			dw   vfs_open
	      .close		dw   vfs_close
	      .unlink		dw   vfs_unlink
	      .rename		dw   vfs_rename
	      .lseek		dw   vfs_lseek
	      .chmod		dw   vfs_chmod

	      .get_ftime	dw   vfs_get_ftime
	      .set_ftime	dw   vfs_set_ftime

	      .cwd			dw   vfs_cwd
	      .chdir		dw   vfs_chdir
	      .mkdir		dw   vfs_mkdir
	      .rmdir		dw   vfs_rmdir

	      .freespace	dw   vfs_freespace
	      .get_drive	dw   vfs_get_drive
	      .set_drive	dw   vfs_set_drive

	      .file_exists	dw   vfs_file_exists
	}

	; Initialize the Struct
	vfs VFS


vfs_init:

; ==================================================================
; AH = 3Ch - "CREAT" - CREATE OR TRUNCATE FILE
;
; IN: CX = File attributes
;     DS:DX -> ASCIZ filename
;
; OUT: CF clear if successful, AX = file handle
;      CF set on error AX = error code (03h,04h,05h)
; ==================================================================
vfs_create:
vfs_read:
vfs_write:
vfs_open:
vfs_close:
vfs_unlink:
vfs_rename:
vfs_lseek:
vfs_chmod:

vfs_get_ftime:
vfs_set_ftime:

vfs_cwd:
vfs_chdir:
vfs_mkdir:
vfs_rmdir:

vfs_freespace:
vfs_get_drive:
vfs_set_drive:

vfs_file_exists: