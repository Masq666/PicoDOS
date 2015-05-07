;====================================================;
;  Welcome.					     ;
;====================================================;
;Welcome:
;	 mov   si,mes			    ; Point SI to string
;	 call  os_print_string		    ; Call print function
;	 ret				    ; Return
;====================================================;
;  A: prompt.					     ;
;====================================================;
Aprompt:
	mov   si,prompt 		   ; Point SI to string
	call  os_print_string		   ; Call print function
	ret				   ; Return
;====================================================;
;  UpperCase.					     ;
;====================================================;
UpperCase:
	pusha				   ; Save genral regs
	push  es			   ; Save ES
UcaseNextChar:
	mov   al,byte[es:di]		   ; Move what ES:DI points to, into AL.
	cmp   al,0			   ; Compear it to 0
	je    UcaseDone 		   ; Jump = to label UcaseDone 
	cmp   al,0x61			   ; Compear it to 0x61
	jb    DontUcaseChar		   ; Jump bellow to lalel DontUcaseChar
	cmp   al,0x7a			   ; Compear it to 0x7a
	ja    DontUcaseChar		   ; Jump above to lalel DontUcaseChar
	sub   al,0x20			   ; Subtract 32 from AL
	mov   byte[es:di],al		   ; Move it to the address ES:DI points too
DontUcaseChar:
	inc   di			   ; Move the pointer by 1 byte
	jmp   UcaseNextChar		   ; Jump to label UcaseNextChar
UcaseDone:
	pop   es			   ; Restore ES
	popa				   ; Restore genral regs
	ret				   ; Return
;====================================================;
;  halt 					     ;
;====================================================; 
;halt:
;	 mov   si,halt_msg		    ; Point SI to string
;	 call  os_print_string			      ; Call our print function
;====================================================;
;  reboot					     ;
;====================================================;
reboot:
	mov   si,reboot_msg		   ; Point SI to string
	call  os_print_string		   ; Call our print function
	xor   ax,ax			   ; wait a key
	int   16h
	mov   ax,0E0Ah			   ; new line
	int   10h
	mov   ax,0E0Dh
	int   10h
	int   19h			   ; reboot
	jmp   $ 			   ; just incase
;====================================================;
;  ReBoot.					     ;
;====================================================; 
ReBootMe:
       db 0xea				   ; Machine language to jump to
       dw 0x0000			   ; address FFFF:0000 (reboot)
       dw 0xffff			   ; No return required
					   ; we're rebooting!
       jmp $				   ; Just incase ;-)
;====================================================;
; SetRet.					     ;
;====================================================; 
SetRet:
	pusha				   ; Save genral regs
	push   ds			   ; Save DS
	push   es			   ; Save ES
	push   cs			   ; Put CS on stack
	pop    ds			   ; Move it into DS
	mov    ax,0x1001		   ; Load AX with address
	mov    es, ax			   ; Move it in ES
	mov    si,Setin20		   ; Move the address of code to move
	xor    di,di			   ; 0 DI
	mov    cx,8			   ; Move count with 8
	rep    movsb			   ; Move what DS:SI points too, to what ES:DI points too
	pop    es			   ; Restore ES
	pop    ds			   ; Restore DS
	popa				   ; Restore genral regs
	ret				   ; Return

Setin20:
	int   0x20			   ; Code to be moved
Some0	dd    0 			   ; Some 0
;====================================================;
; Time. 					     ;
;====================================================; 
Time:
	pusha				   ; Save genral regs
	mov   si,TimeMsg		   ; Move TimeMsg address into SI 
	call  os_print_string			     ; Call our print function
m0:
	mov   ah,2			   ; Get's the (bios int's)
	int   1ah			   ; Time in BCD , dl=0
	push  cx			   ; Push CX onto stack
	push  dx			   ; Push DX onto stack
	pop   eax			   ; Move what was in CX:DX into EAX
m1:
	mov   al,163			   ; Move 163 intp AL
	sub   dl,160			   ; Gives c,c,nc,c,c,nc,c,nc+z
	ja    $+3			   ; h h :  m m  : s  s
	rol   eax,4			   ; If jump is taken, we're in the middle of this.
	push  ax			   ; Save AX
	mov   ah,0eh			   ; Display
	int   10h			   ; Call interrupt service
	pop   ax			   ; Restore AX
	jne   m1			   ; Jump to label m1
	mov   al,13			   ; CR to re-position cursor - looks crappy.
	mov   ah,0eh			   ; Request display
	int   10h			   ; Call interrupt service
	popa				   ; Restore regs
	ret				   ; Return
;====================================================;
; Date. 					     ;
;====================================================; 
Date:					   ; start of getdate 
	pusha				   ; Save genral regs
	mov   si,DateMsg		   ; Move DateMsg address into SI 
	call  os_print_string			     ; Call our print function
	mov   ah,04h			   ; get date from CMOS
	int   1ah			   ; invoke interrupt to get date
	push  cx
	push  dx
	mov   al,dl			   ; get day 
	call  convert			   ; convert day BCD to ASCII
	call  display_date		   ; display day
	pop   dx
	mov   al,dh			   ; get month
	call  convert			   ; convert month BCD to ASCII
	call  display_date		   ; display mouth
	pop   cx
	mov   al,cl			   ; get year
	call  convert			   ; convert year BCD to ASCII
	mov   si,val
	call  putstr			   ; invoke print proc to display
	popa				   ; Restore regs
	ret
convert:				   ; start of convert
	mov   ah,al			   ; copy AL to AH
	and   ax,0f00fh 		   ; mask bits
	mov   cl,4			   ; CL=04 for shift
	shr   ah,cl			   ; shift right AH to get unpacked BCD
	or    ax,3030h			   ; combine with 30 to get ASCII
	xchg  ah,al			   ; swap for ASCII storage convention
	mov   [val],ax			   ; store the ASCII value in VAL 
	ret
display_date:				   ; start of display_date
	mov   si,val
	call  putstr
	mov   ah,0eh			   ; display / to seperate months, days, and years
	mov   al,'/'
	int   10h
	ret
putstr: 				   ; SI = address of string to display
       lodsb
       or  al,al ;
       jz  putstrd
       mov ah,0eh
       mov bx,0007h
       int 10h				   ; print char
       jmp  putstr
putstrd:
       ret
;====================================================;
; ExitWrongFileExt.				     ;
;====================================================; 
ExitWrongFileExt:
	pusha
	mov   si,WrongExtMsg		    ; Move the address of WrongExtMsg into SI
	call  os_print_string			      ; Call our print function
	popa
	ret
;====================================================;
; Data. 					     ;
;====================================================;

TimeMsg db 10,13,'Current time is  ',0
DateMsg db 10,13,'Current date is  ',0
val dw 0,0