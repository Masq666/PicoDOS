;====================================================;
; GetCommand					     ;
;====================================================;
GetCommand:
	pusha				    ; Save genral regs
	push  es			    ; Save ES
	push  cs			    ; Move CS to stack
	pop   es			    ; Move CS from stack in to ES      
	mov   di,CommandBuffer		    ; Move the address of CommandBuffer in DI
	mov   cx,64			    ; move 64 in to counter
	mov   dx,di			    ; Remember initial offset
getkey:
	xor   ax,ax			    ; Get a key
	int   16h			    ; Call interrupt service
	cmp   al,13			    ; Enter?
	je    AH_3hd			    ; Jump = to label AH_3hd
	cmp   al,8			    ; Backspace?
	je    backspace 		    ; Jump = to label backspace

	mov   bx,di			    ; Are we at CX bytes already?
	sub   bx,dx
	cmp   bx,cx
	jae   getkey			    ; Jump above or = to label getkey
	mov   ah,0Eh			    ; Write Character
	mov   bx,0x0001
	int   10h			    ; Call interrupt service
	stosb				    ; Record and display keystroke
	jmp   getkey			    ; Jump to label getkey

backspace:	
	cmp   di,CommandBuffer		    ; Compear pointer to start of buffer
	jbe   getkey			    ; Jump bellow or = to label getkey	
	dec   di			    ; Go back in buffer
	mov   al,8			    ; Move cursor back
	mov   ah,0Eh			    ; Request display
	mov   bx,0x0001
	int   10h			    ; Call interrupt service
	mov   al,32			    ; Print a space
	mov   ah,0Eh			    ; Request display
	mov   bx,0x0001
	int   10h			    ; Call interrupt service
	mov   al,8			    ; Move cursor back again
	mov   ah,0Eh			    ; Request display
	mov   bx,0x0001
	int   10h			    ; Call interrupt service
	jmp   getkey			    ; Get another key
AH_3hd: 				    ; Finish up
	mov   cx,di			    ; CX = byte count
	sub   cx,dx
	xor   al,al			    ; Zero-terminate
	stosb				    ; Store a byte
	xor   ax,ax			    ; Success
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   ax,si			    ; Move SI into AX
	mov   dx,si			    ; Move SI into DX
	pop   es			    ; Restore ES
	popa				    ; Restore genral regs
	ret				    ; Return
;====================================================;
; ProcessCMD					     ;
;====================================================; 
ProcessCMD:
	pusha				    ; Save genral regs
	push  es			    ; Save ES
	mov   di,CommandBuffer		    ; Move the address of CommandBuffer in DI
	call  UpperCase 		    ; Call UpperCase function
;====================================================;
;  CLS. 	   compare command buffer with 'cls' ;					     
;====================================================; 
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,4			    ; Move number of letters into CX			
	mov   di,cli_CLS		    ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_cls			    ; If not =, jump to label not_cls
	call  os_clear_screen		    ; call our function

	call  Welcome			    ; call our function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_cls:
;====================================================;
;  TIME.	  compare command buffer with 'time' ;					     
;====================================================; 
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,5			    ; Move number of letters into CX			
	mov   di,cli_TIME		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_time			    ; If not =, jump to label not_time
	call  Time			    ; call time function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_time:
;====================================================;
;  DATE.	  compare command buffer with 'date' ;					     
;====================================================; 
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,5			    ; Move number of letters into CX			
	mov   di,cli_DATE		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_date			    ; If not =, jump to label not_time
	call  Date			    ; call date function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_date:
;====================================================;
;  HELP.	  compare command buffer with 'help' ;
;====================================================;
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,5			    ; Move number of letters into CX			       
	mov   di,cli_HELP		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_help			    ; If not =, jump to label not_help
	mov   si,HelpMsg		    ; Point SI to string
	call  os_print_string			      ; call our print function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_help:

;====================================================;
;  VER. 	 compare command buffer with 'ver' ;
;====================================================;
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,4			    ; Move number of letters into CX
	mov   di,cli_VER		      ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_ver			   ; If not =, jump to label not_help
	mov   si,VerMsg 		   ; Point SI to string
	call  os_print_string			      ; call our print function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_ver:

; DUMP
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,5			    ; Move number of letters into CX
	mov   di,cli_DUMP		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_dump			    ; If not =, jump to label not_help
	call  os_dump_registers
	jmp   ExitFound 		    ; Jump to label ExitFound
not_dump:





;====================================================;
;  Reboot.	compare command buffer with 'reboot' ;
;====================================================;
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,7			    ; Move number of letters into CX		     
	mov   di,cli_REBOOT		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_reboot		    ; If not =, jump to label not_reboot  
	jmp   ReBootMe			    ; Jump to label ReBootMe
not_reboot:
;====================================================;
;  Dir. 	   compare command buffer with 'DIR' ;
;====================================================;
	mov   si,CommandBuffer		    ; Move the address of CommandBuffer in SI
	mov   cx,4			    ; Move number of letters into CX		       
	mov   di,cli_DIR		       ; Point to label
	repe  cmpsb			    ; Test if =.
	jne   not_dir			    ; If not =, jump to label not_dir 
	call  DirPrintFile		    ; call our function
	jmp   ExitFound 		    ; Jump to label ExitFound
not_dir:
	pop   es
	popa
;====================================================;
;  Load program.				     ;
;====================================================; 
LoadProg:
       call  ConvertFileName		    ; Convert CLI file name, to fat readable.
       jnc   FileExtOK			    ; File ext OK, jump to label FileExtOK
       call  ExitWrongFileExt		    ; Wrong file ext, call ExitWrongFileExt
       call  Aprompt			    ; Call our function
       jmp   os_main			    ; Jump to label os_main
FileExtOK:
       mov   si,nextline		    ; Move the address of nextline in SI
       call  os_print_string		    ; Call our print function
;====================================================;
;  How much RAM is there?.			     ;
;====================================================; 
	mov   ax,0x80			    ; mov used sector in KB(128) into AX
	shl   ax, 6			    ; and convert it to paragraphs
	mov   word[end_memory],ax	    ; save (to know free memory)
	int   12h			    ; get conventional memory size (in KBs)
	shl   ax,6			    ; and convert it to paragraphs
	mov   word[top_memory],ax
;====================================================;
;  Reserve memory for the boot sector and the stack  ;
;====================================================;
	sub   ax,512 / 16		    ; reserve 512 bytes for the boot sector code
	mov   es,ax			    ; es:0 -> top - 512
	sub   ax,2048 / 16		    ; reserve 2048 bytes for the stack
	mov   ss,ax			    ; ss:0 -> top - 512 - 2048
	mov   sp,2048			    ; 2048 bytes for the stack
;====================================================;
;  Copy program to load name to top of memory	     ;
;====================================================;
	mov   cx, 11			    ; Move number of letters in load file name in CX
	mov   si, RootConvertedFileName     ; Move the address of CommandBuffer in SI
	mov   di,[SaveNameAddress]	    ; Move the address of where to move name to.
	rep   movsb			    ; Move name of file from cli to new address
;====================================================;
;  Jump to Load code at top of memory code	     ;
;====================================================;
	push  es			    ; Push ES
	mov   bx,[SaveCS]		    ; Move saved CS into BX
	push  bx			    ; Push it on stack
	xor   bx,bx			    ; 0 BX
	retf				    ; Jump to that address
	jmp    $

ExitFound:
	call  Aprompt			    ; Call our function
	pop   es			    ; Restore ES
	popa				    ; Restore genral regs
	jmp   os_main			    ; Jump to label os_main

; ==================================================================

	cli_CLS 	   db 'CLS',0
	cli_TIME	   db 'TIME',0
	cli_DATE	   db 'DATE',0
	cli_DIR 	   db 'DIR',0
	cli_HELP	   db 'HELP',0
	cli_REBOOT	   db 'REBOOT',0
	cli_VER 	   db 'VER',0
	cli_DUMP	   db 'DUMP',0


