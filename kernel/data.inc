; ==================================================================
; PicoDOS -- A Minimalistic DOS Clone
; Copyright (C) 2014 - 2015 PicoDOS Developers
;
; DATA AND STRUCTURES
;
; ==================================================================

ERRORLEVEL	db 0			    ; Return code from program

; ==================================================================
; DATA STRUCTURES
; ==================================================================

; ==================================================================
; INPUT - Struct containing addresses of input functions
;
; The idea is that one could change this struct to use
; COM1 or other input instead of keyboard as default
; input device.
;
; So we will call functions like this:
;   call INPUT.GetKey
; Instead of calling os_check_for_key directly.
; ==================================================================
struc INPUT {
      .GetKey		     dw   os_check_for_key
      .GetKeyWait	     dw   os_wait_for_key
      .Status		     dw   os_check_for_key_status
}

; ==================================================================
; PSP - Program Segment Prefix
;
; The Program Segment Prefix (PSP) is a data structure used in DOS
; systems to store the state of a program. It resembles the Zero Page
; in the CP/M operating system. The PSP has the following structure:
; ==================================================================
struc PSP {
      .ExitCall 	     resw 1	    ; 2b  - CP/M exit (always contain INT 20h)
      .Segment		     resw 1	    ; 2b  - Segment of the first byte beyond the memory allocated to the program
      .Reserved1	     resb 1	    ; 1b  - Reserved
      .CPM_Call 	     resb 5	    ; 5b  - Far call to CP/M compatibility code within DOS (code)
      .Exit		    	 resd 1	    ; 4b  - Terminate address of previous program (old INT 22h)
      .Break		     resd 1	    ; 4b  - Break address of previous program (old INT 23h)
      .CriticalErr	     resd 1	    ; 4b  - Critical error address of previous program (old INT 24h)
      .ParentPSP	     resw 1	    ; 2b  - Parent's PSP segment (usually COMMAND.COM - internal)
      .JFT		    	 resb 20	; 20b - Job File Table (JFT) (internal)
      .ENV		   		 resw 1	    ; 2b  - Environment segment
      .Stack		     resd 1	    ; 4b  - SS:SP on entry to last INT 21h call (internal)
      .JFT_Size 	     resw 1	    ; 2b  - JFT size (internal)
      .JFT_Pointer	     resd 1	    ; 4b  - Pointer to JFT (internal)
      .PrevPSP		     resd 1	    ; 4b  - Pointer to previous PSP (only used by SHARE in DOS 3.3 and later)
      .Reserved2	     resd 1	    ; 4b  - Reserved
      .Version		     resw 1	    ; 2b  - DOS version to return (DOS 4 and later, alterable via SETVER in DOS 5 and later)
      .Reserved3	     resb 14	; 14b - Reserved

      .CMD_Size 	     resb 1	    ; 1b  - Number of bytes on command-line
      .CMD		     	 resb 127	; 127b- Command-line (terminated by a 0Dh)
}

; ==================================================================
; STP - Serial Transfer Protocol
;
; A very simple protocol to transfer data over serial. (COM)
; .Length is number of bytes being sent.
; .Checksum contains a CRC-16 checksum of sent data.
;
; SIZE: 8 bytes
; ==================================================================
struc STP {
      .Length		     dw 0	    ; Length of data being sent in bytes
      .Checksum 	     dw 0	    ; Checksum so receiver can check data integrity (CRC-16)
}

; ==================================================================
; REGS16 - All 16-bit Registers
;
; A very simple protocol to transfer data over serial. (COM)
; .Length is number of bytes being sent.
; .Checksum contains a CRC-16 checksum of sent data.
;
; SIZE: 30 bytes
; ==================================================================
struc REGS16 {
      .AX		     dw   0	    ; Main Registers
      .BX		     dw   0
      .CX		     dw   0
      .DX		     dw   0

      .CS		     dw   0	    ; Segment Registers
      .DS		     dw   0
      .ES		     dw   0
      .SS		     dw   0
      .FS		     dw   0
      .GS		     dw   0

      .SI		     dw   0	    ; Index Registers
      .DI		     dw   0
      .BP		     dw   0
      .SP		     dw   0

      .FLAGS		 dw   0	    ; FLAGS Register
}