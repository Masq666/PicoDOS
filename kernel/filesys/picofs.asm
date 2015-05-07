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

; 32 bytes
struc PICOFS_ENTRY {
    .FileName		   resb 8	  ; Filename  - Zero terminated if less than 8 chars long.
    .FileExtension	   resb 3	  ; Extension - Zero terminated if less than 3 chars long.
    .Attributes 	   resb 1	  ; Attributes
    .CreateDateTime	   resb 6	  ; 6 byte date string. dd.mm.yy hh:mm:ss (each xx represented with a byte)
    .ModifyDateTime	   resb 6	  ; yy is number of years since 1980 (MAX year: 2235)
    .FirstClusterLow	   resb 4	  ; First Logical Cluster of File / Directory
    .Size		   resb 4	  ; File Size (in bytes)
}
; ==================================================================
; INTERNAL ROUTINES
; ==================================================================
