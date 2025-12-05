;24L-0503;24L-0864
[org 0x0100]
jmp start
char: dw 0x12
width: dw 1
length: dw 24
i: dw 0
j1: dw 10
j2: dw 40
carx: dw 24
cary: dw 20
carwidth: dw 3
carlength: dw 1
road: dw 0x77
car: dw 0x44
obs: dw 0x11
;coin positions:
coincolor: dw 0x0E
c1x: dw 25
c1y: dw 5
c2x: dw 35
c2y: dw 10

;fuel positions:
fuelcolor: dw 0x09
fuelx: dw 20
fuely: dw 15

; Obstacle positions
obs1x: dw 15
obs1y: dw 2
obs2x: dw 30
obs2y: dw 8

gameOver: db 0
randomSeed: dw 0    ; Add a seed for better randomization
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

gamename: db 'Raceless Zone Zero',0
startmessage: db 'Press any key to start...',0


;function to show start screen
startscreen:
    call clrscr
push bp
mov bp, sp
push es
push ax
push cx
push si
push di
mov ah, 0x13
mov al, 1
mov bh, 0
mov bl, 7
mov dx, 0x0A1D
mov cx, 18
push cs 
pop es
mov bp, gamename
int 0x10
mov bp, startmessage
mov dx, 0x1205
push cs
pop es
mov cx, 24
int 0x10
  mov ah, 0
    int 0x16
    
pop di
pop si
pop cx
pop ax
pop es
pop bp
; Move cursor to bottom of screen
mov ah, 02h
mov bh, 0
mov dh, 24
mov dl, 0
int 10h
ret

quitmessage: db 'Do you want to quit? (Y/N)',0

exitscreen:
    call clrscr
    push bp
    mov bp, sp
    push es
    push ax
    push cx
    push si
    push di
    mov ah, 0x13
    mov al, 1
    mov bh, 0
    mov bl, 7
    mov dx, 0x0A1D
    mov cx, 18
    push cs 
    pop es
    mov bp, gamename
    int 0x10
    mov bp, quitmessage
    mov dx, 0x1205
    push cs
    pop es
    mov cx, 28
    int 0x10
    ; Don't wait for keypress here - checkInput will handle it
    
    pop di
    pop si
    pop cx
    pop ax
    pop es
    pop bp
    ; Move cursor to bottom of screen
    mov ah, 02h
    mov bh, 0
    mov dh, 24
    mov dl, 0
    int 10h
    ret
    ret

;function to draw road
drawroad:
push bp
mov bp, sp
push es
push ax
push cx
push si
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov cx, 25
mov ax, 0x7720 ; road character with attribute
mov di, 0
add di, 20
l1:
mov [es:di], ax
add di, 160 ; move to next row
loop l1 ; repeat for the whole string

mov di, 0
add di, 80
mov cx, 25
l2:
mov [es:di], ax
add di, 160 ; move to next row
loop l2 ; repeat for the whole string

done:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret

;function to draw fuel or coin
drawfc:
push bp
mov bp, sp
push es
push ax
push cx
push si
push di
mov ax, 0xb800
mov es, ax ; point es to video base
mov ax, 80
mul byte [bp+6] ; multiply with y position
add ax, [bp+4] ; add x position
shl ax, 1 ; turn into byte offset
mov di, ax ; point di to required location
mov ah, [bp+8];fc attribute
mov al, 0x6F ; 'o' character
cld ; auto increment mode
stosw ; print char/attribute pair


.donefc:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret 6

;function to draw car
drawcar:
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
mov ah, [bp+8];car attribute
mov al, 0x00
cld ; auto increment mode
l3:
mov cx, 2
line1:
stosw ; print char/attribute pair
loop line1 ; repeat for the whole string

mov ah, 0x77
mov cx, 2
add di, 156
line2:
stosw ; print char/attribute pair
loop line2 ; repeat for the whole string

mov ah, [bp+8];car attribute
mov cx, 2
add di, 156
line4:
stosw ; print char/attribute pair
loop line4 ; repeat for the whole string

done2:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret 6



drawemptycar:
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
mul byte [cary] ; multiply with y position
add ax, [carx] ; add x position
shl ax, 1 ; turn into byte offset
mov di,ax ; point di to required location
mov ax, 0x0720 ; space character in normal attribute
cld ; auto increment mode
le3:
mov cx, 2
line13:
stosw ; print char/attribute pair
loop line13 ; repeat for the whole string

mov cx, 2
add di, 156
line23:
stosw ; print char/attribute pair
loop line23 ; repeat for the whole string

mov cx, 2
add di, 156
line43:
stosw ; print char/attribute pair
loop line43 ; repeat for the whole string

done23:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret
; Generate random X position for obstacle (between 11 and 37)
getRandomX:
    push bx
    push cx
    push dx
    
    ; Increment seed by a larger prime number for better variation
    add word [randomSeed], 17
    
    mov ah, 00h
    int 1Ah           ; Get BIOS tick count (DX = low word)
    
    ; Combine tick count with seed using XOR for more randomness
    mov ax, dx
    xor ax, [randomSeed]
    add ax, [randomSeed]  ; Add seed again
    
    ; Get random number in range 11-37
    mov bx, 27        ; Range (37 - 11 + 1 = 27)
    xor dx, dx
    div bx            ; DX = remainder (0-26)
    add dx, 11        ; Shift to range 11-37
    mov ax, dx
    
    pop dx
    pop cx
    pop bx
    ret

; Move obstacles down
moveObstacles:
    push ax
    push bx
    
    ; Move obstacle 1 down by 1
    mov ax, [obs1y]
    inc ax
    mov [obs1y], ax
    
    ; If obstacle 1 goes off screen (>= 24), reset to top with random X
    cmp ax, 24
    jl .checkObs2
    mov word [obs1y], -2     ; Start slightly above screen
    call getRandomX
    mov [obs1x], ax
    
    .checkObs2:
    ; Move obstacle 2 down by 1
    mov ax, [obs2y]
    inc ax
    mov [obs2y], ax
    
    ; If obstacle 2 goes off screen (>= 24), reset to top with random X
    cmp ax, 24
    jl .checkc1
    mov word [obs2y], -2     ; Start slightly above screen
    call getRandomX
    mov [obs2x], ax
    .checkc1:
    ; Move coin 1 down by 1
    mov ax, [c1y]
    inc ax
    mov [c1y], ax
    
    ; If coin 1 goes off screen (>= 24), reset to top with random X
    cmp ax, 24
    jl .checkc2
    mov word [c1y], -2     ; Start slightly above screen
    call getRandomX
    mov [c1x], ax
    .checkc2:
    ; Move coin 2 down by 1
    mov ax, [c2y]
    inc ax
    mov [c2y], ax
    
    ; If coin 2 goes off screen (>= 24), reset to top with random X
    cmp ax, 24
    jl .checkfuel
    mov word [c2y], -2     ; Start slightly above screen
    call getRandomX
    mov [c2x], ax
    .checkfuel:
    ; Move fuel down by 1
    mov ax, [fuely]
    inc ax
    mov [fuely], ax
    
    ; If fuel goes off screen (>= 24), reset to top with random X
    cmp ax, 24
    jl .done
    mov word [fuely], -2     ; Start slightly above screen
    call getRandomX
    mov [fuelx], ax
    .done:
    pop bx
    pop ax
    ret

; Delay function (adjust for speed)
gameDelay:
    push cx
    push dx
    
    mov cx, 0x0A      ; Outer loop count (increased from 0x02 for slower speed)
    .outer:
    push cx
    mov cx, 0xFFFF    ; Inner loop count
    .inner:
    loop .inner
    pop cx
    loop .outer
    
    pop dx
    pop cx
    ret

; Check for keyboard input (ESC to exit)
checkInput:
    push ax
    
    ; Check if key is available
    mov ah, 01h
    int 16h
    jz .noKey
    
    ; Get the key
    mov ah, 00h
    int 16h
    
    ; Check for ESC
    cmp al, 27
    je .exit
    
    cmp ah, 0x4B   ; Left arrow
    je .leftKey
    cmp ah, 0x4D   ; Right arrow
    je .rightKey
    cmp ah, 0x48   ; Up arrow
    je .upKey
    cmp ah, 0x50   ; Down arrow
    je .downKey


    .leftKey:
    call drawemptycar
    ; Move car left
    mov dx, [carx]
    sub dx, 2
    cmp dx, 11
    jl .noKey        ; Don't move if at edge
    mov [carx], dx
    jmp .noKey

    .rightKey:
    call drawemptycar
    ; Move car right
    mov dx, [carx]
    add dx, 2
    cmp dx, 39
    jg .noKey        ; Don't move if at edge
    mov [carx], dx
    jmp .noKey

    .upKey:
    call drawemptycar
    ; Move car up
    mov dx, [cary]
    sub dx, 1
    cmp dx, 0
    jl .noKey        ; Don't move if at edge
    mov [cary], dx
    jmp .noKey

    .downKey:
    call drawemptycar
    ; Move car down
    mov dx, [cary]
    add dx, 1
    cmp dx, 23
    jg .noKey        ; Don't move if at edge
    mov [cary], dx
    jmp .noKey
    
    .exit:
    call exitscreen
    ;check for Y or N, if Y then set gameOver else resume
    .waitValidKey:
    mov ah, 00h
    int 16h
    cmp al, 'Y'
    je .setGameOver
    cmp al, 'y'
    je .setGameOver
    cmp al, 'N'
    je .noKey
    cmp al, 'n'
    je .noKey
    cmp al, 27
    je .noKey
    ; Invalid key, wait for another keypress
    jmp .waitValidKey
    .setGameOver:
    mov byte [gameOver], 1
    
    .noKey:
    pop ax
    ret

; Main game loop function
gameLoop:
    ; Check if game over
    cmp byte [gameOver], 1
    je .endGame
    
    ; Clear screen
    call clrscr
    
    ; Draw road
    call drawroad
    
    ; Draw obstacle 1 (only if on screen)
    mov ax, [obs1y]
    cmp ax, 0
    jl .skipObs1
    cmp ax, 23
    jg .skipObs1
    mov ax, 0x0011      ; Red obstacle
    push ax
    push word [obs1y]
    push word [obs1x]
    call drawcar
    
    .skipObs1:
    ; Draw obstacle 2 (only if on screen)
    mov ax, [obs2y]
    cmp ax, 0
    jl .skipObs2
    cmp ax, 23
    jg .skipObs2
    mov ax, 0x0011      ; Red obstacle
    push ax
    push word [obs2y]
    push word [obs2x]
    call drawcar
    
    .skipObs2:
    ; Draw player car (always on screen)
    mov ax, 0x0044      ; Yellow car
    push ax
    push word [cary]
    push word [carx]
    call drawcar

    mov ax, [c1y]
    cmp ax, 0
    jl .skipCoin1
    cmp ax, 23
    jg .skipCoin1
    mov ax, [coincolor]      ; Coin color from variable
    push ax
    push word [c1y]
    push word [c1x]
    call drawfc
    .skipCoin1:
    mov ax, [c2y]
    cmp ax, 0
    jl .skipCoin2
    cmp ax, 23
    jg .skipCoin2
    mov ax, [coincolor]      ; Coin color from variable
    push ax
    push word [c2y]
    push word [c2x]
    call drawfc
    .skipCoin2:
    mov ax, [fuely]
    cmp ax, 0
    jl .skipFuel
    cmp ax, 23
    jg .skipFuel
    mov ax, [fuelcolor]      ; Fuel color from variable
    push ax
    push word [fuely]
    push word [fuelx]
    call drawfc
    .skipFuel:

    
    
    ; Move obstacles down
    call moveObstacles
    
    ; Delay to control obstacle speed
    call gameDelay
    
    ; Check for input (no delay for responsive controls)
    call checkInput
    
    ; Loop back (infinite loop until ESC pressed)
    jmp gameLoop

    .endGame:
    ; Clear screen before exit
    call clrscr
    ret

start: 

    call startscreen
        ; Wait for key press to start

    ; Initialize random seed
    mov ah, 00h
    int 1Ah
    mov [randomSeed], dx
    
    ; Initialize obstacle positions randomly
    call getRandomX
    mov [obs1x], ax
    mov word [obs1y], 2
    
    call getRandomX
    mov [obs2x], ax
    mov word [obs2y], 12    ; More spacing between obstacles

    call getRandomX
    mov [c1x], ax
    mov word [c1y], 5
    
    call getRandomX
    mov [c2x], ax
    mov word [c2y], 10
    
    call getRandomX
    mov [fuelx], ax
    mov word [fuely], 15
    
    ; Start the game loop
    call gameLoop
    
    ; Exit to DOS (after game ends)
    mov ax, 0x4c00
    int 0x21