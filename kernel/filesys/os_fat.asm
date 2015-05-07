; =================================================================
; TomOS -- The Tomasz Operating System kernel
; Copyright (C) 2006 - 2008 TomOS Developers -- see doc/LICENSE.TXT
;
; FAT12 FILESYSTEM (FLOPPY) SUPPORT ROUTINES
; =================================================================

;include "tomos.inc"
define SIZE_OF_FAT12_83FILEFORMAT 32
define SIZE_OF_ADIR 2 + SIZE_OF_FAT12_83FILEFORMAT

; active directory

active_directory: times SIZE_OF_ADIR db 0

working_directory: times SIZE_OF_ADIR db 0

boot_record: times SIZE_OF_BOOT_RECORD_STRUC db 0

; **************************************************************************************
; *
; *	    next 2 soubroutines aren't used yet.
; *
; **************************************************************************************

;; --------------------------------------------------
;; @proc _os_file_open
;; open a file
;;
;; @param_in si - filename
;; @param_in dx - permissions
;; @param_out ax - file descriptor
;; @section "files"

_os_file_open:

    call _os_file_get_free_desc
    test ax, ax
    jz .error

	mov word [si + FILE_DESC.permissions], dx
	xor dx, dx
	mov word [si + FILE_DESC.file_pos], dx

    .error:
    ret

ret


;; ----------------------------------------------------------
;; @proc _os_file_get_free_desc
;; get free descriptor address
;;
;; @param_in Nothing
;; @param_out Nothing
;; @section "files"

_os_file_get_free_desc:
    push cx
    push si

    mov si, opened_files
    mov cx, MAX_OPENED_FILES

    .loop:
	test cx, cx
	jz .error
	cmp word [si], FREE_DESC
	jz .exit
	add si, SIZE_FILE_DESC 
	dec cx
    jmp .loop
    .exit:
    pop cx
    pop cx
    
    xor ax, ax
    inc ax
    ret

    .error:
    pop si
    pop cx
    xor ax, ax
    ret



; --------------------------------------------------------------------------
; @proc os_file_write
; Save (max 64K) file to disk
;
; @param_in  SI - filename, 
; @param_in  BX - data location, 
; @param_in  CX - bytes to write
; @param_out  Carry clear if OK, set if failure
; @section "files"

_os_file_write:
	pusha

	mov word [.filesize], cx
	mov word [.location], bx
	mov word [.filename], si


	; First, zero out the .free_clusters list from any previous execution

	pusha

	mov di, .free_clusters
	mov cx, 127
	mov dl, 0
	call _os_memory_set	 ; reset free clusters

	popa


	; Next, we need to calculate now many 512 byte clusters are required

	mov ax, cx
	cwd
	mov bx, word [boot_record + BOOT_RECORD_STRUC.BytesPerSector]	 ; Divide file size by 512 to get clusters needed
	div bx
	cmp dx, 0
	jle .carry_on

.add_a_bit:		; If there's a remainder, we need another cluster
	add ax, 1
.carry_on:

	mov word [.clusters_needed], ax

	call _os_disk_read_fat		; Get FAT copy into RAM
	mov di, os_buffer		; And point SI at it (skipping first two clusters)

	mov dx, 3			; Current cluster counter
	mov word cx, [.clusters_needed]
	mov bx, 0			; Offset in .free_clusters list


.next:
	call _os_fat_calculate_next_cluster


	test ax, ax
	jnz .next_cluster			; Free entry?

	mov word [.free_clusters + bx], dx

	dec cx				; Got all the clusters we need?
	cmp cx, 0
	je .finished_list

	sub bx, -2				; Next word in our list
	.next_cluster:
	inc dx
	jmp .next

.finished_list:

	xor bx, bx
	.loop_bx:
	    cmp bx, 127
	    jz .exit_bx
	    shl bx, 1
	    mov dx, word [.free_clusters + bx]
	    push bx
	    call _os_print_4hex
	    call _os_print_space
	    pop bx
	    shr bx, 1
	    inc bx 
	 jmp .loop_bx
	 .exit_bx:

	call _os_print_newline


	; Now the .free_clusters table contains a series of numbers (words)
	; that correspond to free clusters on the disk; the next job is to
	; create a cluster chain in the FAT for our file

	mov cx, 0			; .free_clusters offset counter
	mov word [.count], 1		; General cluster counter
	mov di, os_buffer

.chain_loop:
	mov word ax, [.count]		; Is this the last cluster?
	cmp word ax, [.clusters_needed]

	mov bx, cx
	mov word dx, [.free_clusters + bx]		; Get cluster

	je .last_cluster

	mov word bx, [.free_clusters + bx +2]		; Get number of NEXT free cluster

	call  _os_fat_set_cluster			; chain them

	inc word [.count]
	sub cx, -2

	jmp .chain_loop



.last_cluster:

	mov bx, 0FF8h

	call  _os_fat_set_cluster

.finito:

	call _os_disk_write_fat 	; Save our FAT back to disk


	; Now time to save the sectors to disk!

	mov cx, 0

	call _os_fat_get_cluster_size_bytes
	mov word [.cluster_size], ax

.save_loop:
	mov di, .free_clusters
	add di, cx
	mov word dx, [di]

	cmp dx, 0
	je near .write_root_entry

	pusha

	mov bx, boot_record
	call _os_fat_get_first_sector_of_cluster

	call _os_disk_convert_l2hts

	mov word bx, [.location]

	mov ah, 0x03
	mov al, 1
	stc
	int 13h

	popa

	mov ax, word [.cluster_size]
	add word [.location], ax

	sub cx, -2
	jmp .save_loop


.write_root_entry:

	; Now it's time to head back to the root directory, find our
	; entry and update it with the cluster in use and file size

	call _os_file_get_free_FAT_entry
	jc .failure

	mov word bx, [.filename]	; Get filename back
	mov di, ax
	call _os_fat_create_empty_FAT_entry

	mov word ax, [.free_clusters]	; Get first free cluster

	mov word [di + FAT12_83FILEFORMAT.FirstClusterLow], ax		; Save cluster location into root dir entry

	mov word cx, [.filesize]
	mov word [di + FAT12_83FILEFORMAT.Size], cx
	mov word [di + FAT12_83FILEFORMAT.Size + 2], 0

	mov si, os_buffer
	call _os_disk_write_root_dir

	popa
	clc
	ret

.failure:
	stc
	ret


	.filesize	dw 0
	.cluster	dw 0
	.count		dw 0
	.location	dw 0

	.clusters_needed	dw 0

	.filename	dw 0

	.free_clusters:  times 128 dw 0

	.cluster_size dw 0


; --------------------------------------------------------------------------
; @proc os_file_exists
; Check for presence of file on the floppy
;
; @param_in  AX = filename location
; @param_out carry clear if found, set if not
; @section "files"

_os_file_exists:
	pusha

	push ax 			; Save filename

	call _os_disk_read_root_dir

	pop ax				; Restore filename

	call _os_disk_get_root_entry	; Set or clear carry flag

	popa
	ret

; -------------------------------------------------------------------------
; @proc _os_fat_convert_filename_d2f
; converts filename from fat format to dot format
;
; @param_in ES:DI - destination buffer ( 11 bytes)
; @param_in DS:SI - dot format
; @param_out Nothing
; @section "FAT12"

_os_fat_convert_filename_d2f:

    pusha

    mov bx, 11
    mov al, ' '
    .space_loop:
       test bx, bx
       jz .convert
       mov byte [di + bx -1], al
       dec bx
    jmp .space_loop
    .convert:

    cmp word [si] , 002eh   ; chceck if '.'
    jz .1dot

    cmp word [si] , 2e2eh   ; check if '..'
    jnz .nodot
    cmp byte [si+2], 0
    jz .2dot

    .nodot:

    mov cx, 9
    .loop_name:
	test cx, cx
	jz .no_ext
	mov dl, byte [si]
	cmp dl, '.'
	jz .ext
	test dl, dl
	jz .no_ext

	call _os_char_uppercase
	mov byte [di], al
	inc di
	inc si
	dec cx
    jmp .loop_name
  
    .ext:
    inc si
    mov cx, 3
    .loop_ext:
	test cx, cx
	jz .no_ext
	mov dl, byte [si]
	cmp dl, '0'
	jz .no_ext
	mov byte [di], dl
	inc di
	inc si
	dec cx
    jmp .loop_ext
  
    .no_ext:

    popa

    ret
       
    .1dot:
    mov byte [di], '.'
    popa 
    ret

    .2dot:
    mov word [di], '..'
    popa
    ret



; -------------------------------------------------------------------------
; @proc _os_fat_convert_filename_f2d
; converts filename from fat format to dot format
;
; @param_in ES:DI - destination buffer (min 13 bytes)
; @param_in DS:SI - FAT format
; @param_out Nothing
; @section "FAT12"

_os_fat_convert_filename_f2d:
    pusha

    mov cx, 8
    xor bx, bx
    .loop:
       test cx, cx
       jz .ext
       mov dl, byte [si + bx]
       cmp dl, ' '
       jz .ext
       mov byte [di], dl
       inc di
       inc bx
       dec cx

    jmp .loop

    .ext:

    add si , 8
    mov dl , byte [si]
    cmp dl , ' ' 
    jz .terminate

    mov byte [di], '.'
    inc di
    mov byte [di], dl
    inc di

    mov cx, 2
    mov bx, 1
    .loop_ext:
       test cx, cx
       jz .terminate
       mov dl, byte [si + bx]
       cmp dl, ' '
       jz .terminate
       mov byte [di], dl
       inc di
       inc bx
       dec cx
    jmp .loop_ext


    .terminate:
    mov byte [di], 0
    
    popa
    ret




; --------------------------------------------------------------------------
; @proc _os_file_get_free_FAT_entry
; get a pointer of a free entry in the FAT table
;
; @param_in Nothing
; @param_out AX - pointer to the FAT free entry.
; @section "FAT12"

_os_file_get_free_FAT_entry:
	push di
	push cx

	mov bx, os_buffer
	call _os_fat_get_root_directory
	test ax, ax
	jz .exists_error

	mov di, bx

	mov cx, word [boot_record + BOOT_RECORD_STRUC.RootDirEntries]			; Cycle through root dir entries 
.next_entry:
	mov byte al, [di]
	cmp al, 0			; Is this a free entry?
	je .found_free_entry
	cmp al, 0xE5			; Is this a free entry?
	je .found_free_entry
	add di, 32			; If not, go onto next entry

	loop .next_entry

.exists_error:				; We also get here if above loop finds nothing

	pop cx
	pop di

	stc				; Set carry for failure
	ret


.found_free_entry:
	mov ax, di

	pop cx
	pop di
	clc				; Clear carry for success
	ret

; --------------------------------------------------------------------------
; @proc _os_fat_create_empty_FAT_entry
; Creates a new 0-byte file on the floppy disk
;
; @param_in BX - location of filename
; @param_in DI - location of the entry to fill
; @param_out Nothing
; @section "FAT12"

_os_fat_create_empty_FAT_entry:
    push si
    push cx
  
    mov si, bx				; Get filename back
    mov cx, 11

    call _os_memory_copy

    mov byte [di + FAT12_83FILEFORMAT.Attributes], 0
    mov byte [di + FAT12_83FILEFORMAT.Reserved], 0
    mov byte [di + FAT12_83FILEFORMAT.CreationTime10sec], 0xC6		; Creation time
    mov word [di + FAT12_83FILEFORMAT.CreationTime], 0x7E		; Creation time
    mov word [di + FAT12_83FILEFORMAT.CreationDate], 0		; Creation date
    mov word [di + FAT12_83FILEFORMAT.LastAccessDate], 0		; Creation date
    mov word [di + FAT12_83FILEFORMAT.ReservedFAT32], 0 	; Ignore in FAT12
    mov word [di + FAT12_83FILEFORMAT.LastModificationTime], 0xC6		; Last write time
    mov word [di + FAT12_83FILEFORMAT.LastModificationDate], 0		; Last write date
    mov word [di + FAT12_83FILEFORMAT.FirstClusterLow], 0		; First logical cluster
    mov word [di + FAT12_83FILEFORMAT.Size], 0		; File size
    mov word [di + FAT12_83FILEFORMAT.Size + 2], 0		; File size

    pop cx
    pop si

    ret


; --------------------------------------------------------------------------
; @proc os_remove_file
; Deletes the specified file from the filesystem
;
; @param_in AX = location of filename to remove
; @section "files"

_os_remove_file:
	push ax 			; Save filename

	clc

	call _os_disk_read_root_dir	; Get root dir into os_buffer

	mov di, os_buffer		; Point DI to root dir

	pop ax				; Get chosen filename back

	call _os_disk_get_root_entry	; Entry will be returned in DI
	jc .failure


	mov ax, word [es:di + FAT12_83FILEFORMAT.FirstClusterLow]		; Get first cluster number from the dir entry
	mov word [.cluster], ax 	; And save it

	mov byte [di], 0xE5		; Mark directory entry (first byte of filename) as empty

	inc di

	mov cx , SIZE_OF_FAT12_83FILEFORMAT-1	; Set rest of data in root dir entry to zeros
	xor dx, dx
	call _os_memory_set

	call _os_disk_write_root_dir	; Save back the root directory from RAM


	call _os_disk_read_fat		; Now FAT is in os_buffer
	mov di, os_buffer		; And DI points to it


.more_clusters:
	mov word ax, [.cluster] 	; Get cluster contents

	cmp ax, 0			; If it's zero, this was an empty file
	je .nothing_to_do

	mov dx, ax
	call _os_fat_calculate_next_cluster

	push ax

	mov dx, ax
	xor bx, bx
	call _os_fat_set_cluster

	pop ax

	mov word [.cluster], ax 	; Store cluster
	cmp ax, 0x0FF8			; Final cluster marker?
	jb .more_clusters

.end:
	call _os_disk_write_fat
	jc .failure

.nothing_to_do:
	ret

.failure:
	stc
	ret


	.cluster dw 0


; --------------------------------------------------------------------------
; @proc os_rename_file
; Change the name of a file on the disk
;
; @param_in  AX = filename to change
; @param_in  BX = new filename (zero-terminated strings)
; @param_out carry set on error
; @section "files"

_os_rename_file:
	push bx 			; Save filenames
	push ax

	clc

	call _os_disk_read_root_dir	; Get root dir into os_buffer

	mov di, os_buffer		; Point DI to root dir

	pop ax				; Get chosen filename back

	call _os_disk_get_root_entry	; Entry will be returned in DI
	jc .fail_read

	pop si				; Get new filename string (passed in BX)

	call _os_string_uppercase

	mov cx, 11			; Copy new filename string into root dir entry in os_buffer
	rep movsb

	call _os_disk_write_root_dir	; Save root dir to disk
	jc .fail_write

	ret

.fail_read:
	pop ax
	stc
	ret

.fail_write:
	stc
	ret


; --------------------------------------------------------------------------
; @proc os_get_file_size
; Get file size information for specified file
;
; @param_in AX = filename
; @param_out  BX = file size in bytes (up to 64K) or carry set if file not found
; @section "files"

_os_get_file_size:
	pusha

	clc

	call _os_disk_read_root_dir
	jc .failure
	call _os_disk_get_root_entry
	jc .failure

	mov word bx, [di+28]

	mov word [.tmp], bx

	popa

	mov word bx, [.tmp]

	ret

.failure:
	popa
	stc
	ret


	.tmp	dw 0


; --------------------------------------------------------------------------
; @proc _os_disk_get_root_entry
; Search RAM copy of root dir for file entry
;
; @param_in  AX = filename
; @param_out  DI = location in os_buffer of root dir entry or carry set if file not found
; @section "FAT12"

_os_disk_get_root_entry:
	pusha

	mov [.filename], ax

	mov cx, 224			; Search all (224) entries
	mov ax, 0			; Searching at offset 0

.to_next_root_entry:
	xchg cx, dx			; We use CX in the inner loop...

	mov si, [.filename]		; Start searching for filename
	mov cx, 11
	rep cmpsb
	je .found_file			; Pointer DI will be at offset 11, if file found

	add ax, 32			; Bump searched entries by 1 (32 bytes/entry)

	mov di, os_buffer		; Point to next root dir entry
	add di, ax

	xchg dx, cx			; Get the original CX back
	loop .to_next_root_entry

	popa
	stc				; Set carry if entry not found
	ret


.found_file:
	sub di, 11			; Move back to start of this root dir entry

	mov word [.tmp], di		; Restore all registers except for DI

	popa
	clc

	mov word di, [.tmp]

	ret

	.filename	dw 0
	.tmp		dw 0


; --------------------------------------------------------------------------
; @proc _os_disk_read_fat
; Read FAT entry from floppy into os_buffer
;
; @param_in  Nothing
; @param_out carry set if failure
; @section "FAT12"

_os_disk_read_fat:
	pusha

	mov ax, 1			; FAT starts at logical sector 1 (after boot sector)
	call _os_disk_convert_l2hts

	mov si, os_buffer		; Set ES:BX to point to 8K OS buffer
	mov bx, 0x2000
	mov es, bx
	mov bx, si

	mov ah, 0x02			; Params for int 13h: read floppy sectors
	mov al, 9			; And read 9 of them for first FAT

	pusha				; Prepare to enter loop


.read_fat_loop:
	popa
	pusha

	stc				; A few BIOSes do not set properly on error
	int 13h 			; Read sectors

	jnc .fat_done
	call _os_disk_reset_floppy	; Reset controller and try again
	jnc .read_fat_loop		; Floppy reset OK?

	popa
	jmp .read_failure		; Fatal double error

.fat_done:
	popa				; Restore registers from main loop

	popa				; And restore registers from start of system call
	clc
	ret

.read_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; @proc _os_disk_write_fat
; Save FAT contents from os_buffer in RAM to disk
;
; @param_in FAT in os_buffer
; @param_out carry set if failure
; @section "FAT12"

_os_disk_write_fat:
	pusha

	mov ax, 1			; FAT starts at logical sector 1 (after boot sector)
	call _os_disk_convert_l2hts

	mov si, os_buffer		; Set ES:BX to point to 8K OS buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 0x03			; Params for int 13h: write floppy sectors
	mov al, 9			; And write 9 of them for first FAT

	stc				; A few BIOSes do not set properly on error
	int 13h 			; Write sectors

	jc .write_failure		; Fatal double error

	popa				; And restore from start of system call
	clc
	ret

.write_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; @proc _os_disk_read_root_dir
; Get the root directory contents
;
; @param_in  Nothing
; @param_out  root directory contents in os_buffer, carry set if error
; @section "FAT12"

_os_disk_read_root_dir:
	pusha

	mov ax, 19			; Root dir starts at logical sector 19
	call _os_disk_convert_l2hts

	mov si, os_buffer		; Set ES:BX to point to OS buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 0x02			; Params for int 13h: read floppy sectors
	mov al, 14			; And read 14 of them (from 19 onwards)

	pusha				; Prepare to enter loop


.read_root_dir_loop:
	popa
	pusha

	stc				; A few BIOSes do not set properly on error
	int 13h 			; Read sectors

	jnc .root_dir_finished
	call _os_disk_reset_floppy	; Reset controller and try again
	jnc .read_root_dir_loop 	; Floppy reset OK?

	popa
	jmp .read_failure		; Fatal double error


.root_dir_finished:
	popa				; Restore registers from main loop

	popa				; And restore from start of this system call
	clc				; Clear carry (for success)
	ret

.read_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; @proc _os_disk_write_root_dir
; Write root directory contents from os_buffer to disk
;
; @param_in  root dir copy in os_buffer;
; @param_in DS:SI - FAT table to write
; @param_out carry set if error
; @section "FAT12"

_os_disk_write_root_dir:
	pusha

	call _os_fat_get_root_dir_region
	call _os_disk_convert_l2hts

	mov bx, ds
	mov es, bx
	mov bx, si

	call _os_fat_get_root_dir_size
	mov ah, 0x03			  ; Params for int 13h: write floppy sectors

	stc				; A few BIOSes do not set properly on error
	int 13h 			; Write sectors
	jc .write_failure

	popa				; And restore from start of this system call
	clc
	ret

.write_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; @proc _os_disk_reset_floppy
; Reset floppy drive
;
; @param_in Nothing
; @param_out carry flag set on error
; @section "FAT12"

_os_disk_reset_floppy:
	push ax
	push dx

	xor ax, ax
	mov dl, byte 0
	stc
	int 13h

	pop dx
	pop ax

	ret

; -----------------------------------------------------------------
; @proc _os_fat_get_root_dir_size
; return a size of root directory
; 
; @param_out: AX - size of root directory in sectors
; @section "FAT12"

_os_fat_get_root_dir_size:
    push dx
    push bx
    push ds

    push TOMOS_KERNEL_SEGMENT
    pop ds

    mov ax, word [boot_record + FAT12_TABLE.RootDirEntries]	; get number od diretories on the disk
    shl ax, 5						  ; multiply by size of FAT directory (32 bytes)
    mov bx, word [boot_record + FAT12_TABLE.BytesPerSector]	; add size of sector
    add ax, bx
    dec ax			      ; divide it by size of sector
    cwd
    div bx

    pop ds
    pop bx
    pop dx
    ret


; -----------------------------------------------------------------
; @proc _os_fat_get_data_region
; return first sector of data region
; 
; @param_out: AX - first sector number of root directory
; @section "FAT12"

_os_fat_get_data_region:
    push bx
    push dx
    push cx
    push si
    push ds

    push TOMOS_KERNEL_SEGMENT
    pop ds

    call _os_fat_get_root_dir_size
    mov cx, ax

    xor ax, ax
    mov al, byte [boot_record + FAT12_TABLE.NumberOfFats] 
    mov bx, word [boot_record + FAT12_TABLE.SectorsPerFat]
    cwd
    mul bx
    add ax, word [boot_record + FAT12_TABLE.ReservedForBoot]
   
    add ax, cx

    pop ds
    pop si
    pop cx
    pop dx
    pop bx
    ret


; ------------------------------------------------------------------
; @proc _os_fat_get_root_dir_region
; gets the first section number of the root directory
;
; @param_in Nothing
; @param_out AX first sector of root directory
; @section "FAT12"

_os_fat_get_root_dir_region:
    push bx
    push dx
    push si
    push ds


    push TOMOS_KERNEL_SEGMENT
    pop ds

    xor ax, ax
    mov al, byte [boot_record + BOOT_RECORD_STRUC.NumberOfFats] 
    mov bx, word [boot_record + BOOT_RECORD_STRUC.SectorsPerFat]
    cwd
    mul bx
    add ax, word [boot_record + BOOT_RECORD_STRUC.ReservedForBoot]

    pop ds
    pop si
    pop dx
    pop bx
    ret


; ------------------------------------------------------------------
; @proc _os_fat_get_root_directory
; copy the root directory to the buffer.
;
; @param_in ES:BX buffer for the directory
; @param_out if success AX=1 otherwise AX=0
; @section "FAT12"
; @note the size of buffer can be fetch by os_root_dir_get_size_bytes

_os_fat_get_root_directory:

    push bx
    push si
    push cx
   
    mov eax, 0			; Needed for some older BIOSes

    call _os_int_reset_floppy	; In case floppy has been changed
    jnc .floppy_ok			; Did the floppy reset OK?

    mov bx, .err_msg_floppy_reset	; If not, bail out
    jmp _os_fatal_error


.floppy_ok:				; Ready to read first block of data

    call _os_fat_get_root_dir_region 

    mov dx, ax

    call _os_int_l2hts

    ; ES:BX contains buffer address

    call _os_fat_get_root_dir_size

    mov ah, 0x02			; Params for int 13h: read floppy sectors

    pusha				; Prepare to enter loop


.read_root_dir:
    popa
    pusha

    stc 			; A few BIOSes clear, but don't set properly
    int 13h				; Read sectors
    jnc .reading_successful	; No errors = continue

    call _os_int_reset_floppy	; Problem = reset controller and try again
    jnc .read_root_dir

    popa
    jmp .root_problem		; Double error = exit

.reading_successful:
    popa

    pop cx
    pop si
    pop bx
    mov ax,  1
    ret

.root_problem:		; Double error = exit
    pop cx
    pop si
    pop bx
    mov ax, 0
    ret
    
.err_msg_floppy_reset	db 'os_root_dir_get: Floppy failed to reset', 0

; -----------------------------------------------------------------
; @proc _os_fat_get_FAT_table_region
; return the fisrt sector of FAT table
;
; @param_in DX number of fat table
; @param_out AX= 1 if ok ,0 if error
; @section "FAT12"

_os_fat_get_FAT_table_region:
    push bx
    push cx
    push dx
    push di
 
    cmp dl, byte [boot_record + BOOT_RECORD_STRUC.NumberOfFats]    ; check if number of expected FAT table exits
    ja .error					       ; if no indicate error

    mov cx, word [boot_record + BOOT_RECORD_STRUC.ReservedForBoot] ; skip boot sector
    
    mov ax, word [boot_record + BOOT_RECORD_STRUC.SectorsPerFat]   ; sectors per fat
    dec dx
    mov bx, dx	       
    cwd
    mul bx					       ; multiply by (number of section-1)

    add ax, cx

    pop di 
    pop dx
    pop cx
    pop bx

    ret

.error:
    pop di 
    pop dx
    pop cx
    pop bx

    xor ax, ax
    ret

; -----------------------------------------------------------------
; @proc _os_fat_get_FAT_table
; copy fat table to the buffer
; 
; @param_in: DS:SI - buffer for the table
; @param_in DX number of fat table
; @param_out AX= 1 if ok ,0 if error
; @section "FAT12"

_os_fat_get_FAT_table:
    push bx
    push cx
    push dx
 
    call _os_fat_get_FAT_table_region

    call _os_int_l2hts					; set registers for reading FAT section

    mov ax, word [boot_record + BOOT_RECORD_STRUC.SectorsPerFat]
    mov ah, 0x02			; Params for int 13h: read floppy sectors

    mov bx, si

    pusha				; Prepare to enter loop

.read_FAT:
    popa
    pusha

    stc 			; A few BIOSes clear, but don't set properly
    int 13h			; Read sectors
    jnc .reading_successful	; No errors = continue

    call _os_int_reset_floppy	; Problem = reset controller and try again
    jnc .read_FAT

    popa
    jmp .error		; Double error = exit

.reading_successful:
    popa

   
    pop dx
    pop cx
    pop bx

    xor ax, ax
    inc ax

    ret

    .error:
    pop dx
    pop cx
    pop bx

    xor ax, ax
    ret



; -----------------------------------------------------------------
; @proc _os_get_disk_description_table
; return first sector of root directory
; 
; @param_in: ES:BX - buffer for description table
; @param_out: Nothing
; @section "floppy"
; @note: minimum size of buffer is SIZE_OF_DISK_DESCRIPTION_TABLE

_os_get_disk_description_table:

    push si
    push ds
    push di
    push es
    push bx
    push cx
    push dx
   
    push es
    pop word [.dest_segment]
    mov word [.dest_offset], bx

    mov bx, os_buffer
    push TOMOS_KERNEL_SEGMENT
    pop es

    mov ax, 0

    call _os_int_l2hts

    mov ax, 0201h

    pusha				; Prepare to enter loop

.read_1st_sector:
    popa
    pusha

    stc 		     ; A few BIOSes clear, but don't set properly
    int 13h		     ; Read sectors
    jnc .copy_table	     ; No errors = continue

    call _os_int_reset_floppy	 ; Problem = reset controller and try again
    jnc .read_1st_sector

    popa
    jmp .error		      ; Double error = exit

    .copy_table:

    popa

    mov di, word [.dest_offset]
    push word [.dest_segment]
    pop es
   
    mov si, os_buffer
    push TOMOS_KERNEL_SEGMENT
    pop ds

    mov cx, SIZE_OF_DISK_DESCRIPTION_TABLE
    call _os_memory_copy
    
    xor ax, ax
    inc ax

    pop dx
    pop cx
    pop bx
    pop es
    pop di
    pop ds
    pop si

    ret

.error:
    pop dx
    pop cx
    pop bx
    pop es
    pop di
    pop ds
    pop si

    xor ax, ax
    ret

.dest_offset dw 0
.dest_segment dw 0

; -----------------------------------------------------------------
; @proc _os_fat_set_cluster
; set a 12 bit value under a specigied cluster in the FAT table
;
; @param_in DX - cluster
; @param_in BX - data to save
; @param_in ES:DI - FAT table
; @param_out AX - cluster
; @section "FAT12"

_os_fat_set_cluster:
    push bx
    push dx
    push di
    push cx

    push bx

    mov ax, dx

    mov bx, ax			; multiply ax by 3
    shl ax, 1
    add ax, bx

    mov dx, ax
    and dx, 1			; DX = cluster mod 2
    shr ax, 1
    mov bx, ax

    shl dx, 2			; DX either 4 if (odd) or 0 if (even)
    mov cx, dx			; save DX in CX

    mov dx, 0F000h		; load mask
    rol dx, cl			; DX=F000h for even or DX=000Fh for odd

    and  word [es:di + bx], dx	; applay mask

    pop ax			; get cluster number from the stack
    
    shl ax, cl			; shift left 4 bits if odd or 0 bits if even

    mov dx, 0FFFh		; load mask
    shl dx, cl			; if even DX=0x0FFF if odd DX=0xFFF0
    and ax, dx			; appaly the mask to the cluster number

    or word [es:di + bx], ax	; save new cluster number
    
.exit:

    pop cx
    pop di
    pop dx
    pop bx
    ret

; -----------------------------------------------------------------
; @proc _os_fat_calculate_next_cluster
; calculate next cluster
;
; @param_in DX - cluster
; @param_in ES:DI - FAT table
; @param_out AX - next cluster
; @section "FAT12"

_os_fat_calculate_next_cluster:
    push bx
    push dx
    push di
    push cx


    mov ax, dx

    mov bx, ax			; multiply ax by 3
    shl ax, 1
    add ax, bx

    mov dx, ax
    and dx, 1			; DX = cluster mod 2
    shr ax, 1
    mov bx, ax
    mov ax, word [es:di + bx]	; AX = word in FAT for the 12 bits
  
    shl dx, 2			; DX either 4 if (odd) or 0 if (even)
    mov cx, dx			; save DX in CX
    
    mov dx, 0FFFh		; load mask
    shl dx, cl			; if even DX=0x0FFF if odd DX=0xFFF0

    and ax, dx			; applay the mask
    shr ax, cl			; shift right 4 bits if odd or 0 bits if even
  
.exit:

    pop cx
    pop di
    pop dx
    pop bx
    ret

; ------------------------------------------------------------------
; @proc _os_fat_get_first_sector_of_cluster
; translates cluster number to the cector number
;
; @param_in DX - cluster number
; @param_out AX - first sector number of the cluster
; @section "FAT12"

_os_fat_get_first_sector_of_cluster:
    push bx
    push cx
    push dx

    call _os_fat_get_data_region 

    mov cx, ax

    mov ax, dx
    sub ax, 2
    mov bl , byte [boot_record +  BOOT_RECORD_STRUC.SectorsPerCluster]
    and bx, 00FFh
    cwd
    mul bx
  
    add ax, cx

    pop dx
    pop cx
    pop bx 
    ret 

; ------------------------------------------------------------------
; @proc  _os_fat_get_cluster_size_bytes
; return a cluster size in bytes
;
; @param_in Nothing
; @param_out AX - cluster size in bytes
; @section "FAT12"
    
_os_fat_get_cluster_size_bytes:
    push bx
    push dx

    xor ax, ax
    mov al, byte [boot_record + BOOT_RECORD_STRUC.SectorsPerCluster]
    mov bx, word [boot_record + BOOT_RECORD_STRUC.BytesPerSector]
    cwd
    mul bx

    pop dx
    pop bx
    ret


; --------------------------------------------------------------------------
; @proc _os_disk_convert_l2hts
; Calculate head, track and sector for int 13h
;
; @param_in logical sector in AX
; @param_out correct registers for int 13h
; @section "floppy"

_os_disk_convert_l2hts:
	push bx
	push ax

	mov bx, ax			; Save logical sector

	xor dx, dx			; First the sector
	div word [SecsPerTrack] 	; Sectors per track
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	xor dx, dx			; Now calculate the head
	div word [SecsPerTrack] 	; Sectors per track
	xor dx, dx
	div word [Sides]		; Floppy sides
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	mov dl, byte 0			; Set correct device

	ret


; --------------------------------------------------------------------------


	Sides dw 2
	SecsPerTrack dw 18

	
	opened_files: times MAX_OPENED_FILES*SIZE_FILE_DESC  db 0


; DISK ERROR VALUES

	ERR_DISK_FILE_NOT_FOUND 	equ	1
	ERR_DISK_FULL			equ	2
	ERR_DISK_READ_FAIL		equ	3
	ERR_DISK_WRITE_FAIL		equ	4
	ERR_DISK_FILE_EXISTS		equ	5


; --------------------------------------------------------------------------

; --------------------------------------------------------------------------
; @proc _os_fat_get_number_of_clusters
; 
; @param_in DS:SI - FAT12_83FILEFORMAT entity address
; @param_out AX - number of clusters taken by the file
; @section "FAT12"

_os_fat_get_number_of_clusters:
    push es
    push di
    push ds
    push si
    push dx
    push cx
    push bx

    mov dx, word [si + FAT12_83FILEFORMAT.FirstClusterLow]
    mov word [.first_cluster], dx

    mov ax, TOMOS_KERNEL_SEGMENT
    mov ds, ax
    mov es, ax
    mov si, os_buffer

    mov dx, 1
    call _os_fat_get_FAT_table
    test ax, ax
    jz .error


    mov dx, word [.first_cluster]
    mov ax, dx
    mov di, si
    xor cx, cx

    .loop1:

	call  _os_fat_calculate_next_cluster
	cmp ax , 0FF8h
	jae .exit_success

	inc cx
	jmp .loop1

    .exit_success:

    mov ax, cx
    inc ax

    .error:

    pop bx
    pop cx
    pop dx
    pop si
    pop ds
    pop di
    pop es
    ret

.first_cluster dw 0

; --------------------------------------------------------------------------
; @proc _os_fat_get_cluster
; get n-th cluster of the file
;
; @param_in DS:SI - FAT12_83FILEFORMAT entity address
; @param_in AX - index of a cluster to get
; @param_out AX - cluster number, if AX = 0FFFFh means out of file.
; @section "FAT12"

_os_fat_get_cluster:
    push es
    push di
    push ds
    push si
    push dx
    push cx
    push bx

    mov cx, ax

    mov dx, word [si + FAT12_83FILEFORMAT.FirstClusterLow]
    mov word [.first_cluster], dx

    mov ax, TOMOS_KERNEL_SEGMENT
    mov ds, ax
    mov es, ax
    mov si, os_buffer

    mov dx, 1
    call _os_fat_get_FAT_table
    test ax, ax
    jz .error


    mov dx, word [.first_cluster]
    mov ax, dx
    mov di, si

    .loop1:
	test cx, cx
	jz .exit_success

	call  _os_fat_calculate_next_cluster
	cmp ax , 0FF8h
	jae .exit_eof
	mov dx, ax
	dec cx
	jmp .loop1

    .exit_eof:
    xor ax, ax
    dec ax
    .error:
    .exit_success:

    pop bx
    pop cx
    pop dx
    pop si
    pop ds
    pop di
    pop es
    ret

.first_cluster dw 0

; --------------------------------------------------------------------------
; @proc _os_fat_copy_cluster
;
; @param_in DX - cluster number
; @param_in ES:DI destination (must be greater by cluster)
; @param_out AX = 1 success, AX = 0 fail
; @section "FAT12"

_os_fat_copy_cluster:

    push bx
    push cx
    push dx
    push es

    mov bx, boot_record
    push TOMOS_KERNEL_SEGMENT
    pop es

    mov al, byte [boot_record + FAT12_TABLE.SectorsPerCluster]
    mov byte [.number_to_read], al

    call _os_fat_get_first_sector_of_cluster  
    mov word [.start_sector], ax

    mov bx, di

    .loop1:

      mov ax, word [.start_sector]
      call _os_int_l2hts

      mov ah, 02h
      mov al, byte [.number_to_read]
   

      stc
      int 13h

      jnc .readed

	call _os_disk_reset_floppy	; Reset controller and try again
	jnc .loop1			; Floppy reset OK?

	xor ax, ax

	jmp .error

      .readed:

      sub byte [.number_to_read], al

      cmp byte [.number_to_read], 0
      je .success

      xor ah, ah
      add word [.start_sector], ax

      mov cx, 512      ; sector size
      cwd
      mul cx

      add bx, ax

    jmp .loop1	    

    .success:
    xor ax, ax
    inc ax

    .error:
    pop es
    pop dx
    pop cx
    pop bx
    ret

.number_to_read db 0
.start_sector dw 0



; --------------------------------------------------------------------------
; @proc _os_fat_copy_block
; 
; @param_in DS:SI - FAT12_83FILEFORMAT entity address
; @param_in ES:DI - destination
; @param_in DX - block size
; @param_in BX - start address
; @param_out AX - number of copied bytes, if less than DX means eof. AX = 0FFFFh fails
; @section "FAT12"

_os_fat_copy_block:

    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    mov word [.start_addr], bx
    push es
    pop word [.dest + far_address.segment]
    mov word [.dest + far_address.offset], di
    push ds
    pop word [.fat12_ent + far_address.segment]
    mov word [.fat12_ent + far_address.offset], si

    mov word [.readed_bytes], 0

    cmp word [si + FAT12_83FILEFORMAT.Attributes], 10h	 ; check if directory
    jz .directory
       mov ax, word [si + FAT12_83FILEFORMAT.Size]
       jmp .go
    .directory:
       call _os_fat_get_number_of_clusters
       push bx
       mov bx , ax
       call _os_fat_get_cluster_size_bytes
    
       mov cx, dx 
       cwd
       mul bx
       mov dx, cx
       pop bx
      
    .go:
    sub ax, dx
    sub ax, bx

    cmp ax, 0
    jge .in_file
      add dx, ax
    .in_file: 

    mov word [.block_size], dx

    call _os_fat_get_cluster_size_bytes
    mov [.cluster_size], ax
    
    xchg bx, ax
    cwd

    div bx

    mov word [.start_byte_number], dx

    call _os_fat_get_cluster 

    mov word [.cluster], ax

    mov ax, word [.block_size]
    mov bx, word [.cluster_size]
    cwd
    div bx

    mov word [.full_clusters_number], ax
    mov word [.remaining_cluster_bytes], dx

    mov cx, ax
  
    .full_cluster_loop:
      test cx, cx
      jz .remaining    

      mov di, os_buffer
      push TOMOS_KERNEL_SEGMENT
      pop es

      mov dx, word [.cluster]

      call _os_fat_copy_cluster
      test ax , ax
      jz .error

      add di, word [.start_byte_number]
      mov si, di
      push es
      pop ds

      mov di, word [.dest + far_address.offset]
      mov ax, word [.dest + far_address.segment]
      mov es, ax

      push cx

      mov cx, word [.cluster_size]
      sub cx, word [.start_byte_number]

      call _os_memory_copy

      add word [.dest + far_address.offset], cx
      add word [.readed_bytes] , cx

 
      pop cx

      xor ax, ax

      dec cx

      mov word [.start_byte_number], ax  
       
      mov si, os_buffer
      push TOMOS_KERNEL_SEGMENT
      pop ds 
      mov dx, 1
      call _os_fat_get_FAT_table
      test ax, ax
      jz .error

      mov dx, word [.cluster]

      mov di, si
      push ds
      pop es
      call _os_fat_calculate_next_cluster

      cmp ax, 0FF8h
      jae .eof
   
      mov word [.cluster], ax

    jmp .full_cluster_loop
      
    .remaining: 
      mov di, os_buffer

      mov ax, TOMOS_KERNEL_SEGMENT
      mov es, ax

      mov dx, word [.cluster]

      call _os_fat_copy_cluster
      test ax , ax
      jz .error

      add di, word [.start_byte_number]
      mov si, di
      push es
      pop ds

      mov di, word [.dest + far_address.offset]
      mov ax, word [.dest + far_address.segment]
      mov es, ax

      mov cx, word [.remaining_cluster_bytes]

      add word [.readed_bytes] , cx

      call _os_memory_copy



    .eof:

      mov ax,  word [.readed_bytes]

    jmp .exit
    .error:
    xor ax, ax
    dec ax
    .exit:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

.remaining_cluster_bytes dw 0
.full_clusters_number dw 0
.start_byte_number dw 0

.sector dw 0
.cluster dw 0
.cluster_size dw 0
.block_size dw 0
.start_addr dw 0
.fat12_ent: times 2 dw 0
.dest: times 2 dw 0
.readed_bytes dw 0


; --------------------------------------------------------------------------
; @proc _os_fat_get_entity
; 
; @param_in DS:SI - name of the entity to get
; @param_in ES:DI - pointer to the structure FAT12_83FILEFORMAT
; @param_out AX =1 and structure pointed by ES:DI is filled, AX = file does not exists
; @section "FAT12"

_os_fat_get_entity:
    push es
    push si
    push di
    push ds
    push bx
    push cx
    push dx

    push ds
    pop word [.seg_src]
    mov word [.off_src], si

    push es
    pop word [.seg_dest]
    mov word [.off_dest], di

    mov ax, TOMOS_KERNEL_SEGMENT
    mov ds, ax

    mov ax , word [active_directory + ADIR.index]
    test ax, ax
    jz .root_directory

    mov si, active_directory + ADIR.e_fat

    ;mov ax, word [si + FAT12_83FILEFORMAT.Size]
    mov ax, 512
    mov cx, SIZE_OF_FAT12_83FILEFORMAT
    cwd

    div cx

    push ax

    mov dx, word [si + FAT12_83FILEFORMAT.FirstClusterLow]

    call _os_fat_get_first_sector_of_cluster

    call _os_int_l2hts

    mov bx, os_buffer
    mov ah, 0x02
    mov al, 1
    stc
    int 13h

    pop cx

    jmp .go_through_entities

    .root_directory:

    mov cx, word [boot_record + BOOT_RECORD_STRUC.RootDirEntries]     ; get number of diretories on the disk


    mov bx, os_buffer
    push TOMOS_KERNEL_SEGMENT
    pop es
    call _os_fat_get_root_directory
    test ax, ax
    jz .exit

    .go_through_entities:

    mov si, os_buffer
    push es
    pop ds
    mov di , word [.off_src]
    mov ax, word [.seg_src]
    mov es, ax

    .e_loop:

	test cx, cx
	jz .exit_error

	mov al, [si + FAT12_83FILEFORMAT.Attributes]
	cmp al, 0Fh			; Windows marker, skip it
	je .continue

	mov al, [si]
	cmp al, 0E5h			; If we read E5h (229d) = deleted filename
	je .continue

	cmp al, 0			; 1st byte = entry never used
	je .continue

	push cx
	mov cx, 11

	push si
	lea si, [si + FAT12_83FILEFORMAT.FileName]

	call _os_string_n_compare

	pop si
	pop cx

	jc .exit_found

	.continue:
	add si, SIZE_OF_FAT12_83FILEFORMAT
	dec cx
    jmp .e_loop
  
    .exit_found:

    mov di , word [.off_dest]
    mov ax, word [.seg_dest]
    mov es, ax

    mov cx, SIZE_OF_FAT12_83FILEFORMAT

    call _os_memory_copy
    
    xor ax, ax
    inc ax
    
    jmp .exit

    .exit_error:
    xor ax, ax
    .exit:

    pop dx
    pop cx
    pop bx
    pop ds
    pop di
    pop si
    pop es

    ret

.seg_dest dw 0
.off_dest dw 0

.seg_src dw 0
.off_src dw 0

; --------------------------------------------------------------------------
; @proc _os_fat_get_entity_by_index
; 
; @param_in DS:SI - name of the entity to get
; @param_in ES:DI - pointer to the structure FAT12_83FILEFORMAT
; @param_in DS:BX - BIOS Parameter Block
; @param_in DX - index
; @param_out AX =1 and structure pointed by ES:DI is filled, AX = file does not exists
; @section "FAT12"

_os_fat_get_entity_by_index:

    push ds
    pop word [.seg_src]
    mov word [.off_src], si

    push es
    pop word [.seg_dest]
    mov word [.off_dest], di

    mov ax , word [active_directory + ADIR.index]
    test ax, ax
    jz .root_directory

    lea si, [active_directory + ADIR.e_fat]
    mov ax, TOMOS_KERNEL_SEGMENT
    mov ds, ax

    mov ax, word [ds:si + FAT12_83FILEFORMAT.Size]
    mov cx, FAT12_83FILEFORMAT
    cwd

    div cx

    push ax

    mov ax, word [ds:si + FAT12_83FILEFORMAT.FirstClusterLow]

    call _os_int_l2hts

    mov bx, os_buffer
    mov ah, 0x02
    mov al, 1
    stc
    int 13h

    pop cx

    jmp .go_through_entities

    .root_directory:

    mov cx, word [ds:bx + FAT12_TABLE.RootDirEntries]	  ; get number of diretories on the disk

    mov bx, os_buffer
    call _os_fat_get_root_directory

    .go_through_entities:

    mov si, os_buffer
    mov di , word [.off_src]
    mov ax, word [.seg_src]
    mov es, ax

    cmp cx, dx
    jb .exit_error
    mov ax, dx

    mov cx, SIZE_OF_FAT12_83FILEFORMAT
    cwd
    mul cx
 
    add si, ax

    mov di , word [.off_dest]
    mov ax, word [.seg_dest]
    mov es, ax

    ; CX consist SIZE_OF_FAT12_83FILEFORMAT
    call _os_memory_copy
    
    xor ax, ax
    inc ax
    
    jmp .exit

    .exit_error:
    xor ax, ax
    .exit:
    ret

.seg_dest dw 0
.off_dest dw 0

.seg_src dw 0
.off_src dw 0

; ----------------------------------------------------------------------
; @proc _os_fat_setup
; setup FAT12 filesystem env
;
; @param_in Nothing
; @param_out Nothing
; @section  "FAT12"

_os_fat_setup:
    push dx
    push bx
    push es
    
    push TOMOS_KERNEL_SEGMENT
    pop es
    mov bx, boot_record
    call _os_get_disk_description_table

    xor si, si
    dec si

    call _os_fat_change_working_dir    


    pop es
    pop bx
    pop dx
    ret

; --------------------------------------------------------------------------
; @proc _os_fat_change_active_dir
; change a directory. Directory must exist in an active directory
;
; @param_in DS:SI - string with directory name, 0xFFFF back to root dir
; @param_out AX - 1 success; 0 error
; @section "FAT12"

_os_fat_change_active_dir:
    push di
    push cx
    push dx
    push es
   
    mov ax, si
    inc ax 
    test ax, ax
    jz .back_to_root
   
    mov di, .entity
    mov ax, TOMOS_KERNEL_SEGMENT
    mov es, ax
 
    call _os_fat_get_entity
    test ax, ax
    jz .error

    ;IS_DIRECTORY(di)
     cmp word [fat12 + FAT12_83FILEFORMAT.Attributes], 10h
    jnz .error

    call _os_fat_get_jump_index
    add word [active_directory + ADIR.index], ax

    cmp word [active_directory + ADIR.index], 0
    jz .back_to_root

    mov si, di
    push es
    pop si

    mov di , active_directory + ADIR.e_fat
 
    mov cx , SIZE_OF_FAT12_83FILEFORMAT

    call _os_memory_copy

    inc word [active_directory + ADIR.index]

    xor ax, ax
    inc ax
      
    jmp .exit
    .back_to_root:

    mov di , active_directory + ADIR.e_fat

    xor dx , dx
    mov cx , SIZE_OF_FAT12_83FILEFORMAT
    call _os_memory_set 		    ; reset the structre for security reasons

    xor ax, ax
    mov word [active_directory + ADIR.index], ax   ; write 0 as a type to indicate ROOT DIR
    inc ax

     jmp .exit
    .error:
    xor ax, ax
    .exit:

    pop es
    pop dx
    pop cx
    pop di
    ret

.entity: times FAT12_83FILEFORMAT db 0

; --------------------------------------------------------------------------
; @proc _os_fat_change_working_dir
; change a directory. Directory must exist in an active directory
;
; @param_in DS:SI - string with directory name, 0xFFFF back to root dir
; @param_out AX - 1 success; 0 error
; @section "FAT12"

_os_fat_change_working_dir:
    push di
    push cx
    push dx
    push es
   
    mov ax, si
    inc ax 
    test ax, ax
    jz .back_to_root
   
    mov di, .entity
    mov ax, TOMOS_KERNEL_SEGMENT
    mov es, ax

    call _os_fat_get_entity
    test ax, ax
    jz .error

    ;IS_DIRECTORY(di)
     cmp word [fat12 + FAT12_83FILEFORMAT.Attributes], 10h
    jnz .error
 
    call _os_fat_get_jump_index
    add word [active_directory + ADIR.index], ax
    add word [working_directory + ADIR.index], ax

    cmp word [active_directory + ADIR.index], 0
    jz .back_to_root

    mov si, di

    push es
    pop ds

    mov di , active_directory + ADIR.e_fat

    mov cx , SIZE_OF_FAT12_83FILEFORMAT

    call _os_memory_copy


    mov di , working_directory + ADIR.e_fat
 
    mov cx , SIZE_OF_FAT12_83FILEFORMAT

    call _os_memory_copy


    xor ax, ax
    inc ax
      
    jmp .exit
    .back_to_root:

    mov di , active_directory + ADIR.e_fat

    xor dx , dx
    mov cx , SIZE_OF_FAT12_83FILEFORMAT
    call _os_memory_set 		    ; reset the structre for security reasons

    mov di , working_directory + ADIR.e_fat

    xor dx , dx
    mov cx , SIZE_OF_FAT12_83FILEFORMAT
    call _os_memory_set 		    ; reset the structre for security reasons

    xor ax, ax
    mov word [active_directory + ADIR.index], ax   ; write 0 as a type to indicate ROOT DIR
    mov word [working_directory + ADIR.index], ax
    inc ax

     jmp .exit
    .error:
    xor ax, ax
    .exit:

    pop es
    pop dx
    pop cx
    pop di
    ret

.entity: times SIZE_OF_FAT12_83FILEFORMAT db 0


; ------------------------------------------
; @proc _os_fat_get_jump_index
; get direction of jump in a directory tree
; directory  ..  is  -1
; directory  . is 0
; directory the rest is 1
;
; @param_in DS:SI - address of a filenam in FAT12 format
; @param_out AX - index
; @section "FAT12"

_os_fat_get_jump_index:
    xor ax, ax
    cmp word [si], 202eh     ; compare with '. '
    jz .exit
    cmp word [si], 2e2eh     ; compare with '..'
    jnz .no_dots
    cmp byte [si+2], ' '     ; when equals '..' compare with ' '
    jnz .no_dots
       dec ax
       jmp .exit
    .no_dots:
       inc ax
    .exit:
    ret

; --------------------------------------------------------------------------
; @proc _os_fat_open_dir
; open a directory to read
;
; @param_in DS:SI - directory to open, if si == 0FFFFh open working
; @param_out AX - 1 success ES:DI opened dir instance, AX - 0 fails
; @section "FAT12"

_os_fat_open_dir:

    push dx
    push si
    push ds

    mov ax, si
    inc ax
    test ax, ax
    jnz .next
 
       mov ax , word [active_directory + ADIR.index]
       test ax, ax
       jnz .no_root_active

	   call _os_fat_create_empty_HDIR
	   test ax, ax
	   jz .error_no_memory

	   push word [boot_record + BOOT_RECORD_STRUC.RootDirEntries]
	   pop word [di + HDIR_STRUC.num_ent]

	   xor ax, ax
	   mov word [di + HDIR_STRUC.index], ax
	   
	   xor ax, ax
	   inc ax

	   jmp .exit	  

       .no_root_active:
       mov si, .dir_dot 
       mov ax, TOMOS_KERNEL_SEGMENT
       mov ds, ax
    .next:

    mov di, .entity
    push TOMOS_KERNEL_SEGMENT
    pop es 
    call _os_fat_get_entity

    test ax, ax
    jz .error_not_exists
    
    ;IS_DIRECTORY(ES:.entity)
     cmp word [fat12 + FAT12_83FILEFORMAT.Attributes], 10h
    jnz .error_not_directory

    mov dx, word [di + FAT12_83FILEFORMAT.Size]

    call _os_fat_create_empty_HDIR
    test ax, ax
    jz .error_no_memory


    mov si, .entity
    push TOMOS_KERNEL_SEGMENT
    pop ds 

    push di
    lea di, [di + HDIR_STRUC.e_fat]
    mov cx, SIZE_OF_FAT12_83FILEFORMAT
    call _os_memory_copy

    xor ax, ax
  
    pop di 

    call _os_fat_dir_calculate_num_ent 

    mov word [di + ADIR.index], ax
    inc ax

    pop ds
    pop si
    pop dx
    ret

    .error_no_memory:
    .error_not_directory:
    .error_not_exists:
    xor ax, ax
    .exit:

    pop ds
    pop si
    pop dx
    ret

.entity: times SIZE_OF_FAT12_ENTITY db 0
.dir_dot db '.          ',0


; ----------------------------------------------------------------------
; @proc _os_fat_dir_next_file
; get file FAT12_ENTITY from the opened directory
;
; @param_in ES:DI - HDIR instance returned by os_fat_open_dir
; @param_in DS:SI - pointer to the FAT12_ENTITY
; @param_out AX - 1 success and DS:SI contains file info, AX = 0 no more file in the directory, AX - 0FFFFh error
; @section "FAT12"

_os_fat_dir_next_file:
    push bx
    push dx
    push cx
    push si
    push ds
    push di
    push es

    mov ax, word [di + HDIR_STRUC.index]

    cmp ax, word [di + HDIR_STRUC.num_ent]
    jae .no_more_files

    cmp ax, word [di + HDIR_STRUC.index_end]
    jb .no_reload

	call _os_fat_dir_reload_buffer
	test ax, ax
	jz .error
	jmp .get_entity


    .no_reload:
    sub ax, word [di + HDIR_STRUC.index_start]
    jae .get_entity

	call _os_fat_dir_reload_buffer
	test ax, ax
	jz .error

    .get_entity:

    mov ax, word [di + HDIR_STRUC.index]
    sub ax, word [di + HDIR_STRUC.index_start]
    mov bx, SIZE_OF_FAT12_83FILEFORMAT
    cwd
    mul bx

    push si
    push ds

    mov si, [di + HDIR_STRUC.buffer + far_address.offset]
    add si, ax
    mov ax, [di + HDIR_STRUC.buffer + far_address.segment]
    mov ds, ax 

    inc word [di + HDIR_STRUC.index]

    cmp byte [si + FAT12_83FILEFORMAT.FileName], 0

    pop es
    pop di

    jz .no_more_files

    mov cx, SIZE_OF_FAT12_ENTITY

    call _os_memory_copy

    xor ax, ax

    mov word [di + FAT12_ENTITY.Reserved1], ax
    mov word [di + FAT12_ENTITY.Reserved2], ax

    inc ax 

    jmp .exit
    .no_more_files:
    mov ax, 1

    .error:
    dec ax
    .exit:

    pop es
    pop di
    pop ds
    pop si
    pop cx
    pop dx
    pop bx
    ret


; --------------------------------------------------------------
; @proc _os_fat_root_dir_reload_buffer
; reload buffer for direcory entities stored by HDIR_STRUC
;
; @param_in ES:DI - HDIR_STRUC instance returned by _os_fat_open_dir
; @param_out AX - 1 success, AX - 0 fails.
; @section "FAT12"


_os_fat_root_dir_reload_buffer:

    push bx
    push dx
    push cx
    push si
    push ds
    push di
    push es

    push TOMOS_KERNEL_SEGMENT
    pop ds

    push es
    pop word [.hdir_tmp + far_address.segment]
    mov word [.hdir_tmp + far_address.offset], di


    mov ax , word [di + HDIR_STRUC.index]
    mov bx , SIZE_OF_FAT12_83FILEFORMAT
    cwd

    mul bx

    mov bx , word [boot_record + BOOT_RECORD_STRUC.BytesPerSector]

    cwd
    div bx

    mov word [.start_sector], ax
    mov word [.offset_in_sector], dx

    add dx, word [di + HDIR_STRUC.buffer_size]

    mov ax, dx
    cwd
    div bx

    test dx, dx
    jz .no_inc
	inc ax
    .no_inc:

    mov word [.number_of_sectors], ax

    call _os_fat_get_root_dir_region 

    add ax, word [.start_sector]

    call _os_int_l2hts

    mov ax, word [.number_of_sectors]
    mov ah, 02h

    mov bx, os_buffer
    push TOMOS_KERNEL_SEGMENT
    pop es

    stc
    int 13h

    jnc .success

	xor ax, ax
	jmp .error

    .success:

    add bx, word [.offset_in_sector]
    mov si, bx
    push es

    mov ax, word [.hdir_tmp  + far_address.segment]
    mov di, word [.hdir_tmp + far_address.offset]

    pop ds

    mov es, ax

    mov cx, word [di + HDIR_STRUC.buffer_size]

    mov ax, word [di + HDIR_STRUC.index]
    mov word [di + HDIR_STRUC.index_start], ax
    mov word [di + HDIR_STRUC.index_end], ax

    mov ax, cx
    mov bx, SIZE_OF_FAT12_83FILEFORMAT
    cwd

    div bx
 
    add word [di + HDIR_STRUC.index_end], ax

    mov ax, word [di + HDIR_STRUC.buffer + far_address.segment]
    mov di, word [di + HDIR_STRUC.buffer + far_address.offset]
    mov es, ax

    call _os_memory_copy

    xor ax, ax
    inc ax 

    .error:
    .exit:

    pop es
    pop di
    pop ds
    pop si
    pop cx
    pop dx
    pop bx

    ret


.start_sector dw 0
.offset_in_sector dw 0
.number_of_sectors dw 0
.hdir_tmp: times 2 dw 0


; --------------------------------------------------------------
; @proc _os_fat_dir_reload_buffer
;
; @param_in ES:DI - HDIR_STRUC instance returned by _os_fat_open_dir
; @param_out AX - 1 success, AX - 0 fails
; @section "FAT12"

_os_fat_dir_reload_buffer:

    push bx
    push dx
    push di
    push si
    push es
    push ds

    mov word [.tmp_hdir + far_address.offset], di
    push es
    pop word [.tmp_hdir + far_address.segment]


    cmp word [di + HDIR_STRUC.e_fat + FAT12_83FILEFORMAT.FileName], 0
    jnz .no_root

	call _os_fat_root_dir_reload_buffer
	test ax, ax
	jz .error
	jmp .exit

    .no_root:

    mov ax, word [di + HDIR_STRUC.index]
    mov bx, SIZE_OF_FAT12_83FILEFORMAT
    cwd
    mul bx

    mov bx, ax
    mov dx, word [di + HDIR_STRUC.buffer_size]

    lea si,  [di + HDIR_STRUC.e_fat]
    push es
    pop ds

    mov ax, word [di + HDIR_STRUC.buffer + far_address.segment]
    mov di, word [di + HDIR_STRUC.buffer + far_address.offset]
    mov es, ax

    call _os_fat_copy_block

    inc ax
    test ax, ax
    jz .error


    mov di , word [.tmp_hdir + far_address.offset]
    mov ax , word [.tmp_hdir + far_address.segment]
    mov es, ax

    mov ax,  word [di + HDIR_STRUC.index]
    mov word [di + HDIR_STRUC.index_start], ax
    mov word [di + HDIR_STRUC.index_end], ax

    mov ax, word [di + HDIR_STRUC.buffer_size]
    mov bx, SIZE_OF_FAT12_83FILEFORMAT
    cwd

    div bx

    add word [di + HDIR_STRUC.index_end], ax

    xor ax, ax
    inc ax
    
    .error:
    .exit:
   
    pop ds
    pop es
    pop si
    pop di
    pop dx
    pop bx
    ret

.tmp_hdir: times 2 dw 0

; --------------------------------------------------------------
; @proc _os_fat_close_dir
;
; @param_in ES:DI - HDIR_STRUC instance returned by _os_fat_open_dir
; @param_out Nothing
; @section "FAT12"

_os_fat_close_dir:
    push si
    push ds
    push ax
 
    push es
    push di

    mov ax, word [di + HDIR_STRUC.buffer +  far_address.segment]

    test ax, ax
    jz .remove_hdir
	mov di, word [di + HDIR_STRUC.buffer +	far_address.offset]
	mov es, ax
	call _os_mm_free
    .remove_hdir:

    pop di
    pop es
    call _os_mm_free
 
    pop ax
    pop ds
    pop si
    ret


; ----------------------------------------------
; @proc _os_fat_create_empty_HDIR
; create empty HDIR_STRUCT instance
;
; @param_in Nothing
; @param_out AX = 1 success and ES:DI instance, AX = 0 fail
; @section "FAT12"

_os_fat_create_empty_HDIR:
   push ds
   push si
   push dx
   push bx
   push cx

   mov dx, SIZE_OF_HDIR_STRUC
   call _os_mm_alloc
   test ax, ax
   jz .error_no_memory

   mov cx, dx
   xor dx, dx
   call _os_memory_set

   mov dx, BUFOR_SIZE
   mov word [di + HDIR_STRUC.buffer_size], dx

   mov si, di
   mov bx, es

   call _os_mm_alloc
   test ax, ax
   jz .error_no_memory_free_HDIR

   mov ds, bx

   mov word [si + HDIR_STRUC.buffer + far_address.offset], di
   push es
   pop word [si + HDIR_STRUC.buffer + far_address.segment]

   mov di, si
   mov es, bx

   jmp .exit

   .error_no_memory_free_HDIR:
   mov di, si
   mov es, bx
   
   call _os_mm_free
   xor ax, ax

   .error_no_memory:

   .exit:

   pop cx
   pop bx
   pop dx
   pop si
   pop ds
   ret

; ----------------------------------------------------
; @proc _os_fat_dir_calculate_num_ent
;
; @param_in ES:DI	
; @param_out
; @section "FAT12"

_os_fat_dir_calculate_num_ent:
    push ax
    push dx
    push bx
    push si
    push ds
    
    lea si, [di + HDIR_STRUC.e_fat]
    push es
    pop ds
    call _os_fat_get_number_of_clusters

    mov bx, ax
   
    call _os_fat_get_cluster_size_bytes

    cwd

    mul bx

    mov bx, SIZE_OF_FAT12_83FILEFORMAT
    div bx

    mov word [di + HDIR_STRUC.num_ent], ax

    pop ds
    pop si
    pop bx
    pop dx
    pop ax

    ret

; -------------------------------------------------------------------------------
; @proc os_dir_open
; open a directory
;
; @param_in DS:SI - pointer with a directory name, if SI = 0FFFF open working directory
; @param_out AX - 1 success ES:DI opened dir instance, AX - 0 fails
; @section "files"
 
_os_dir_open:
    call _os_fat_open_dir
    ret

; --------------------------------------------------------------------------
; @proc os_dir_next_file
; get a file from the opened directory.
;
; @param_in ES:DI - opened directory instance returned by os_dir_open
; @param_in DS:SI - FAT12_ENTITY structure pointer
; @param_out AX - 1 success, AX - 0 no more files to get, AX - 0FFFFh other error
; @section "files"

_os_dir_next_file:

    .skip:
    call _os_fat_dir_next_file

    test ax, ax
    jz .exit

    cmp byte [si + FAT12_ENTITY.Attributes],  0Fh	; Windows marker, skip it
    jz .skip
    cmp byte [si + FAT12_ENTITY.FileName],  0e5h       ; Deleted file, skip it
    jz .skip

    .exit:
    ret

; -------------------------------------------------------------------------------
; @proc os_dir_close
; close a directory
;
; @param_in ES:DI - opened directory instance returned by os_dir_open
; @param_out Nothing
; @section "files"

_os_dir_close:
    call _os_fat_close_dir
    ret

; -----------------------------------------------------------------------------
; @proc os_dir_change
; change a directory
;
; @param_in DS:SI - directory name, if SI = 0FFFFh go to root dir
; @param_out AX - 1 success, AX - 0 fails (directory does not exists)
; @section "files"

_os_dir_change:
   call _os_fat_change_working_dir
   ret


; ----------------------------------------------------------------
; @proc os_file_convert_f2d
; converts filename from fat format to dot format
;
; @param_in ES:DI - destination buffer (min 13 bytes)
; @param_in DS:SI - FAT format
; @param_out Nothing
; @section "files"

_os_file_convert_f2d:
    call _os_fat_convert_filename_f2d
    ret

; ----------------------------------------------------------------
; @proc os_file_convert_d2f
; converts filename from dot format to fat format
;
; @param_in ES:DI - destination buffer ( 11 bytes)
; @param_in DS:SI - dot format
; @param_out Nothing
; @section "files"

_os_file_convert_d2f:
    call _os_fat_convert_filename_d2f
    ret
