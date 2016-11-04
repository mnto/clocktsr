Microsoft (R) Macro Assembler Version 6.11		    10/18/16 22:08:14
demo							     Page 1 - 1


				TITLE demo

				; Alistair Campbell
				; keyboard interrupt

				include irvine16.inc
			      C ; Irvine16.inc - Include file for programs using
			      C ; the Irvine16.lib (Real-address mode library).
			      C 
			      C ; Last update: 7/29/05
			      C 
			      C .NOLIST
			      C .LIST
			      C 

 0000				.code

 0000 30 31 32 33 34 35		hex byte "0123456789abcdef"
       36 37 38 39 61 62
       63 64 65 66

 0010				Out16 PROC
					; STDCALL 16-bit value parameter
					; output in hex

 0010  55				push bp
 0011  8B EC				mov bp, sp
					
 0013  50				push ax
 0014  53				push bx
 0015  51				push cx
 0016  52				push dx
					
 0017  8B 56 04				mov	dx, [bp + 4]
 001A  B9 0004				mov	cx, 4
 001D  B4 0E				mov	ah, 0Eh		; bios output routine
 001F  51			L1:	push	cx
 0020  B9 0004				mov	cx, 4
 0023  D3 C2				rol	dx, cl
 0025  59				pop	cx
 0026  8B DA				mov	bx, dx
 0028  83 E3 0F				and	bx, 000Fh
 002B  2E: 8A 87 0000 R			mov	al, hex[bx]
 0030  CD 10				int	10h
 0032  E2 EB				loop	L1

 0034  5A				pop dx
 0035  59				pop cx
 0036  5B				pop bx
 0037  58				pop ax

 0038  8B E5				mov sp, bp
 003A  5D				pop bp
 003B  C2 0002				ret 2
 003E				Out16 ENDP

 003E				JumpCursor PROC
					; IN: DH row, DL column
					; Move the cursor on page 0.
 003E  50				push ax
 003F  53				push bx
 0040  B7 00				mov bh, 0
 0042  B8 0200				mov ax, 0200h
 0045  CD 10				int 10h
 0047  5B				pop bx
 0048  58				pop ax
 0049  C3				ret
 004A				JumpCursor ENDP

 004A				Out16Corner PROC
					; IN: 16 bit parameter
 004A  55				push bp
 004B  8B EC				mov bp, sp

 004D  50				push ax
 004E  53				push bx
 004F  51				push cx
 0050  52				push dx
					
 0051  B7 00				mov bh, 0
 0053  B8 0300				mov ax, 0300h		; get cursor position
 0056  CD 10				int 10h
 0058  52				push dx			; remember it

 0059  B6 01				mov dh, 1
 005B  B2 4B				mov dl, 75
 005D  E8 FFDE				call JumpCursor

 0060  FF 76 04				push [bp + 4]		; output the parameter
 0063  E8 FFAA				call Out16

 0066  5A				pop dx			; move the cursor back!
 0067  E8 FFD4				call JumpCursor

 006A  5A				pop dx
 006B  59				pop cx
 006C  5B				pop bx
 006D  58				pop ax

 006E  8B E5				mov sp, bp
 0070  5D				pop bp
 0071  C2 0002				ret 2
 0074				Out16Corner ENDP

 0074 00000000			orig_09 dword ?
 0078 0000			count word ?



 007A				handle09 PROC

 007A  9C				pushf
 007B  2E: FF 1E 0074 R			call orig_09	; handle the keyboard interrupt!
							; Note well, this is an indirect far call.

 0080  50				push ax
 0081  B4 00				mov ah, 0
 0083  E4 60				in al, 60h	; read the current key.  (input 