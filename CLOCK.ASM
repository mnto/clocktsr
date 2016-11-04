TITLE	clock.asm

; Author: Minh To
; Last update: October 30, 2016
; This program demonstrates a clock program. It displays
; the clock in the upper right corner of the screen when the clock is toggled
; by the user's pressing 2 shift keys

include irvine16.inc

.code

hex byte "0123456789abcdef"	; array of hex values
rt BYTE 0			; boolean value to keep track of right shift
lft BYTE 0			; boolean value to keep track of left shift
other BYTE 0			; boolean value to keep track of other keys
showit BYTE 0			; boolean value to show the clock
orig_09 dword ?			; original 08 value
orig_08 dword ?			; original 09 value
count word ?			; timer counter to count seconds
am BYTE 0			; boolean value for am/pm

GetTime PROC
    ; OUT: CH = hour, CL = minute, DH = second
    push ax
    mov ah, 2
    int 1Ah
    pop ax
    ret
GetTime ENDP

Out8 PROC
    ; IN: value to be printed out in AL
    ; output a byte at a time

    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx

    mov dx, [bp + 4]
    mov cx, 8
    rol dx, cl			; only look at 8 bits
    mov cx, 2			; only output 2 nybbles
    mov ah, 0Eh     		; bios output routine
L1: push    cx
    mov cx, 4
    rol dx, cl			; look at each nybble
    pop cx
    mov bx, dx
    and bx, 000Fh
    mov al, hex[bx]		; print out its hex value
    int 10h
    loop    L1

    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp
    ret 2
Out8 ENDP

JumpCursor PROC
    ; IN: DH row, DL column
    ; Move the cursor on page 0.
    push ax
    push bx
    mov bh, 0
    mov ax, 0200h
    int 10h
    pop bx
    pop ax
    ret
JumpCursor ENDP

colon PROC
    ; Print out a cursor
    push ax
    mov ah, 0Eh
    mov al, ':'
    int 10h
    pop ax
    ret
colon ENDP

printAM PROC
    push ax
    mov ah, 0Eh
    mov al, 'A'
    int 10h
    mov al, 'M'
    int 10h
    pop ax
    ret
printAM ENDP

printPM PROC
    push ax
    mov ah, 0Eh
    mov al, 'P'
    int 10h
    mov al, 'M'
    int 10h
    pop ax
    ret
printPM ENDP

handle08 PROC
    ; Handle 08 interrupt: the 2 shift keys should toggle the clock
    ; on and off
    push ax
    push bx
    push cx
    push dx

    mov bh, 0
    mov ax, 0300h       	; get cursor position
    int 10h
    push dx         		; remember it

    cmp showit, 0		; if (showit == 0)
    je noShow			;   clear the clock

    mov dh, 0			; otherwise jump to upper right corner
    mov dl, 70			; to print clock
    call JumpCursor

    call GetTime		; get system time

    cmp ch, 12h			; change from 24-hour format to 12-hour format
    jbe outputTime		; (am = 0 indicates the morning,
    sub ch, 12h			;  am = 1 indicates the afternoon)
    mov am, 1

    add count, 55		; update and only print out the clock
    cmp count, 1000		; every second
    jle CursorBack
    sub count, 1000

    ; OUTPUT THE CLOCK IN THIS FORMAT: HH:MM:SS(AM/PM)
outputTime:
    mov ah, 0
    mov al, ch
    push ax
    call Out8			; output the hour

    call colon			; output colon

    mov al, cl
    push ax
    call Out8			; output the minute

    call colon			; output colon

    mov al, dh
    push ax
    call Out8			; out the second

    cmp am, 0			; if (am == 0)
    je morning			;   it is morning, print AM after the time
    call printPM		; else
    jmp CursorBack		;   it is afternoon, print PM after the time

morning:
    call printAM
    jmp CursorBack		; jump cursor back to its original position

noShow:				; if clock is toggled off
    mov dh, 0
    mov dl, 70			; wipe out the clock off of screen
    call JumpCursor
    mov cx, 10
    mov ah, 0Eh
space:
    mov al, ' '
    int 10h
    loop space

CursorBack:			; put cursor back to its original position
    pop dx
    call JumpCursor

done:
    pop dx
    pop cx
    pop bx
    pop ax

    pushf
    call orig_08		; handle timer interrupt

    iret
handle08 ENDP

handle09 PROC
    ; Handle the keyboard interrupt so that when 2 shift keys are pressed
    ; it changes the boolean value to show or clear the clock
    push ax

    in al, 60h  		; read the current key

    cmp al, 36h			; if right shift is pressed
    jnz leftDown
    not rt			; set right shift variable
    jmp done

leftDown:
    cmp al, 2Ah			; if left shift is pressed
    jnz rightUp
    not lft			; set left shift variable
    jmp done

rightUp:
    cmp al, 0B6h		; if right shift was released
    jnz leftUp
    mov rt, 1			; clear right variable
    jmp continue

leftUp:
    cmp al, 0AAh		; if left shift was released
    jnz otherKeys
    mov lft, 1			; clear left variable
    jmp continue

otherKeys:
    mov rt, 0			; if another key not left shift or right shift
    mov lft, 0			; was pressed, reset boolean values for both
    jz done			; keys and exit

continue:
    cmp rt, 1			; if both right shift
    jnz done
    cmp lft, 1			; and left shift were pressed
    jnz done
    not showit			; toggle the clock
    mov rt, 0			; reset boolean values after clock is toggled
    mov lft, 0

done:
    pop ax

    pushf
    call orig_09    		; handle the keyboard interrupt!

    iret 		        ; return to the point that was interrupted
handle09 ENDP

install09 PROC
    push ds
    push es
    push ax
    push bx
    push dx

    ; before changing the vector, 
    ; get the old vector and save it!
    mov ax, 3509h
    int 21h
    mov word ptr orig_09, bx
    mov word ptr orig_09+2, es

    ; Now install the new 09 vector
    push cs 	        	; put our code segment
    pop ds      	        ; into ds
    mov dx, offset handle09     ; with offset in dx
    mov ax, 2509h
    int 21h

    pop dx
    pop bx
    pop ax
    pop es
    pop ds
    ret
install09 ENDP

install08 PROC
    push ds
    push es
    push ax
    push bx
    push dx

    ; before changing the vector, 
    ; get the old vector and save it!
    mov ax, 3508h
    int 21h
    mov word ptr orig_08, bx
    mov word ptr orig_08+2, es

    ; Now install the new 08 vector
    push cs      	        ; put our code segment
    pop ds              	; into ds
    mov dx, offset handle08     ; with offset in dx
    mov ax, 2508h
    int 21h

    pop dx
    pop bx
    pop ax
    pop es
    pop ds
    ret
install08 ENDP

uninstall08 PROC
    ;; restore the original int 09h vector
    push ds
    push ax
    push dx

    mov dx, word ptr orig_08
    mov ds, word ptr orig_08 + 2
    mov ax, 2508h
    int 21h

    pop dx
    pop ax
    pop ds
    ret
uninstall08 ENDP

uninstall09 PROC
    ;; restore the original int 09h vector
    push ds
    push ax
    push dx

    mov dx, word ptr orig_09
    mov ds, word ptr orig_09 + 2
    mov ax, 2509h
    int 21h

    pop dx
    pop ax
    pop ds
    ret
uninstall09 ENDP

main PROC
.data
inputstr BYTE 255 DUP(0)

.code

    mov ax, @data
    mov ds, ax

    mov dx, offset inputstr
    mov bx, dx
    mov cx, lengthof inputstr

    ;; install handle08 and handle 09
    ;; as the new interrupt vector for int 08h and int 09h
    call install09
    call install08

top:	                    	; read strings and echo them until 
    call readstring         	; user enters an empty string
    call crlf
    cmp byte ptr [bx], 0
    je done
    call WriteString
    call crlf
    jmp top
done:
    ; uninstall handle08 and handle09
    call uninstall09
    call uninstall08
    mov ax, 4c00h
    int 21h

main ENDP
END main



