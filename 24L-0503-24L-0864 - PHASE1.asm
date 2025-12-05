; hello world printing using string instructions
[org 0x0100]
jmp start
char: dw 0x12
width: dw 1
length: dw 24
i: dw 0
j1: dw 10
j2: dw 40
carx: dw 15
cary: dw 20
carwidth: dw 3
carlength: dw 1
road: dw 0x77
car: dw 0x44
obs: dw 0x11
clrscr: 
push es
push ax
push cx
push di
mov ax, 0xb800
mov es, ax ; point es to video base
xor di, di ; point di to top left column
mov ax, 0x0720 ; space char in normal attribute
mov cx, 2000 ; number of screen locations
cld ; auto increment mode
rep stosw ; clear the whole screen
pop di
pop cx
pop ax
pop es
ret
; subroutine to print a string
; takes the x position, y position, attribute, address of string and
; its length as parameters
printsqr:
push bp
mov bp, sp
push es
push ax
push cx
push si
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov al, 80 ; load al with columns per row
mul byte [bp+6] ; multiply with y position
add ax, [bp+4] ; add x position
shl ax, 1 ; turn into byte offset
mov di,ax ; point di to required location
mov dx, [bp+8] ;width
mov ah, [bp+12];attribte
mov al, [char]
mov bx, [bp+10]; length
cld ; auto increment mode



l2: 
mov cx, [bp+8]
push cx
nextchar:
stosw ; print char/attribute pair
loop nextchar ; repeat for the whole string
pop cx
shl cx, 1
sub di, cx
add di, 160
shr cx, 1
sub dx, 1
jz next
jmp l2

next:
mov dx, [bp+8] ;width

sub bx, 1
jz done
jmp l2
done:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret 10

start: 
call clrscr ; call the clrscr subroutine
push word [road]
push word [length]
push word [width]
push word [i]
push word [j1]
call printsqr ; call the printstr subroutine

push word [road]
push word [length]
push word [width]
push word [i]
push word [j2]
call printsqr ; call the printstr subroutine

push word [car]
push word [carlength]
push word [carwidth]
push word [cary]
push word [carx]
call printsqr ; call the printstr subroutine

push word [obs]
push word [carlength]
push word [carwidth]
mov ah, 00h
int 1Ah           ; CX:DX = tick count (18.2 ticks/sec)
mov ax, dx        ; use low word of tick count
and ax, 000Fh     ; keep lowest 4 bits (0–15 range)
; AX now holds a pseudo-random number between 0–15      ; shift to range 10–40
push ax



mov ah, 00h
int 1Ah           ; get BIOS tick count
mov ax, dx
mov bx, 31        ; (max - min + 1) = 40 - 10 + 1 = 31
xor dx, dx
div bx            ; DX = remainder (0–30)
mov ax, dx        ; random part
add ax, 10        ; shift to range 10–40



push ax
call printsqr ; call the printstr subroutine

mov ax, 0x4c00 ; terminate program
int 0x21