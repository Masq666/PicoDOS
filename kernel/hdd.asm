; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; LBA28 HARD DRIVE FUNCTIONS
;
; Functions:
;	os_read_sectors			  - Read sectors on the hard drive
;	os_write_sectors		  - Write sectors on the hard drive
;
; Notes:
; These functions use LBA28. Maximum visible drive size is 128GiB
; LBA48 would be needed to access sectors over 128GiB (up to 128PiB)
; These functions are hard coded to access the Primary Master HDD.
; These functions are based on the HDD functions from BareMetal OS.
; ==================================================================


; ==================================================================
; os_read_sectors - Read sectors on the hard drive
;
; IN:	EAX = starting sector to read
;		ECX = number of sectors to read (1 - 256)
;		EDI = memory location to store sectors
; OUT:	EAX = EAX + number of sectors that were read
;		ECX = number of sectors that were read (0 on error)
;		EDI = EDI + (number of sectors * 512)
;		All other registers preserved
; ==================================================================
os_read_sectors:
	push edx
	push ecx
	push ebx
	push eax

	push ecx					; Save RCX for use in the read loop
	mov ebx, ecx				; Store number of sectors to read
	cmp ecx, 256
	jg .fail					; Over 256? Fail!
	jne .skip					; Not 256? No need to modify CL
	xor ecx, ecx				; 0 translates to 256
	
.skip:
	push eax					; Save RAX since we are about to overwrite it
	mov dx, 0x01F2				; 0x01F2 - Sector count Port 7:0
	mov al, cl					; Read CL sectors
	out dx, al
	pop eax						; Restore RAX which is our sector number
	inc dx						; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx						; 0x01F4 - LBA Mid Port 15:8
	shr eax, 8
	out dx, al
	inc dx						; 0x01F5 - LBA High Port 23:16
	shr eax, 8
	out dx, al
	inc dx						; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr eax, 8
	and al, 00001111b 			; Clear bits 4-7 just to be safe
	or al, 01000000b			; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx						; 0x01F7 - Command Port
	mov al, 0x20				; Read sector(s). 0x24 if LBA48
	out dx, al

	mov ecx, 4
.wait:
	in al, dx					; Read status from 0x01F7
	test al, 0x80				; BSY flag set?
	jne .retry
	test al, 0x08				; DRQ set?
	jne .dataready
.retry:
	dec ecx
	jg .wait
.nextsector:
	in al, dx					; Read status from 0x01F7
	test al, 0x80				; BSY flag set?
	jne .nextsector
	test al, 0x21				; ERR or DF set?
	jne .fail

.dataready:
	sub dx, 7					; Data port (0x1F0)
	mov ecx, 256				; Read 
	rep insw					; Copy a 512 byte sector to RDI
	add dx, 7					; Set DX back to status register (0x01F7)
	in al, dx					; Delay ~400ns to allow drive to set new values of BSY and DRQ
	in al, dx
	in al, dx
	in al, dx

	dec ebx						; RBX is the "sectors to read" counter
	cmp ebx, 0
	jne .nextsector

	pop ecx
	pop eax
	pop ebx
	add eax, ecx
	pop ecx
	pop edx
	ret

.fail:
	pop ecx
	pop eax
	pop ebx
	pop ecx
	pop edx
	xor ecx, ecx				; Set RCX to 0 since nothing was read
	ret

; ==================================================================
; os_write_sectors - Write sectors on the hard drive
;
; IN:	EAX = starting sector to write
;		ECX = number of sectors to write (1 - 256)
;		ESI = memory location of sectors
; OUT:	EAX = EAX + number of sectors that were written
;		ECX = number of sectors that were written (0 on error)
;		ESI = ESI + (number of sectors * 512)
;		All other registers preserved
; ==================================================================
os_write_sectors:
	push edx
	push ecx
	push ebx
	push eax

	push ecx					; Save RCX for use in the write loop
	mov ebx, ecx				; Store number of sectors to write
	cmp ecx, 256
	jg .fail					; Over 256? Fail!
	jne .skip					; Not 256? No need to modify CL
	xor ecx, ecx				; 0 translates to 256

.skip:	
	push eax					; Save RAX since we are about to overwrite it
	mov dx, 0x01F2				; 0x01F2 - Sector count Port 7:0
	mov al, cl					; Write CL sectors
	out dx, al
	pop eax						; Restore RAX which is our sector number
	inc dx						; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx						; 0x01F4 - LBA Mid Port 15:8
	shr eax, 8
	out dx, al
	inc dx						; 0x01F5 - LBA High Port 23:16
	shr eax, 8
	out dx, al
	inc dx						; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr eax, 8					; Bits 7 and 5 are obsolete in LBA mode so set to 0
	and al, 00001111b 			; Clear bits 4-7 just to be safe
	or al, 01000000b			; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx						; 0x01F7 - Command Port
	mov al, 0x30				; Write sector(s). 0x34 if LBA48
	out dx, al

	mov ecx, 4
.wait:
	in al, dx					; Read status from 0x01F7
	test al, 0x80				; BSY flag set?
	jne .retry
	test al, 0x08				; DRQ set?
	jne .dataready
.retry:
	dec ecx
	jg .wait
.nextsector:
	in al, dx					; Read status from 0x01F7
	test al, 0x80				; BSY flag set?
	jne .nextsector
	test al, 0x21				; ERR or DF set?
	jne .fail

.dataready:
	sub dx, 7					; Data port (0x01F0)
	mov ecx, 256				; Write 256 words (512 bytes)
.nextword:
	outsw						; Cannot use rep as a small delay is needed between each out
	sub ecx, 1
	cmp ecx, 0
	jne .nextword
	add dx, 7					; Set DX back to Command / Status Register (0x01F7)
	mov al, 0xE7				; Cache Flush command
	out dx, al
	in al, dx					; Delay ~400ns to allow drive to set new values of BSY and DRQ
	in al, dx
	in al, dx
	in al, dx

	dec ebx						; RBX is the "sectors to write" counter
	cmp ebx, 0
	jne .nextsector

	pop ecx
	pop eax
	pop ebx
	add eax, ecx
	pop ecx
	pop edx
	ret

.fail:
	pop ecx
	pop eax
	pop ebx
	pop ecx
	pop edx
	xor ecx, ecx				; Set RCX to 0 since nothing was written
	ret
