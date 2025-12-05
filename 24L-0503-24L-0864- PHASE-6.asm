;24L-0503;24L-0864
[org 0x0100]
jmp start

; Lane positions (3 lanes)
lane1: dw 15
lane2: dw 27
lane3: dw 39

; Player car
carx: dw 27
cary: dw 20
currentLane: dw 2  ; Start in middle lane (1, 2, or 3)
carwidth: dw 5

; Colors
road: dw 0x77
car: dw 0x44
obs: dw 0x11

; Coin positions
coincolor: dw 0x0E
c1x: dw 25
c1y: dw 5
c2x: dw 35
c2y: dw 10

; Fuel positions
fuel: dw 10
fuelcolor: dw 0x09
fuelx: dw 20
fuely: dw 15

; Obstacle positions
obs1x: dw 15
obs1y: dw 2
obs2x: dw 30
obs2y: dw 8

; Game state
score: dw 0
fuelTimer: dw 0
moveDelay: dw 0
playerName: times 20 db 0
gameOver: db 0
randomSeed: dw 0

; Multitasking variables
taskstates: times 15 dw 0  ; 3 tasks * 5 registers (ax,bx,ip,cs,flags)
current: db 0              ; index of current task
musicEnabled: db 1         ; flag to enable/disable music
oldTimerIP: dw 0           ; Store original timer interrupt
oldTimerCS: dw 0

; Music data (slower, smoother melody)
musicNotes: dw 392, 440, 494, 523  ; G, A, B, C - simple ascending pattern
musicIndex: dw 0
musicDelay: dw 0
noteCounter: dw 0

; Background music task
musicTask:
    cmp byte [cs:musicEnabled], 0
    je .noSound
    
    ; Increment delay counter slowly
    mov ax, [cs:musicDelay]
    inc ax
    mov [cs:musicDelay], ax
    
    ; Change note every 30000 cycles (slow, smooth transitions)
    cmp ax, 30000
    jl .keepPlaying
    
    ; Reset delay
    xor ax, ax
    mov [cs:musicDelay], ax
    
    ; Turn off speaker for smooth transition
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
    ; Move to next note
    mov bx, [cs:musicIndex]
    inc bx
    and bx, 3  ; Only 4 notes
    mov [cs:musicIndex], bx
    
    ; Get note frequency
    shl bx, 1
    mov cx, [cs:musicNotes+bx]
    
    ; Calculate divisor: 1193180 / frequency
    mov dx, 0x12
    mov ax, 0x34DC
    div cx
    
    ; Program timer
    push ax
    mov al, 0xB6
    out 0x43, al
    pop ax
    out 0x42, al
    mov al, ah
    out 0x42, al
    
    ; Turn on speaker
    in al, 0x61
    or al, 3
    out 0x61, al
    
.keepPlaying:
    jmp musicTask
    
.noSound:
    ; Turn off speaker
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    jmp musicTask

; Timer interrupt service routine for multitasking
timer:
    push ax
    push bx
    mov bl, [cs:current]
    mov ax, 10
    mul bl
    mov bx, ax
    pop ax
    mov [cs:taskstates+bx+2], ax
    pop ax
    mov [cs:taskstates+bx+0], ax
    pop ax
    mov [cs:taskstates+bx+4], ax
    pop ax
    mov [cs:taskstates+bx+6], ax
    pop ax
    mov [cs:taskstates+bx+8], ax
    inc byte [cs:current]
    cmp byte [cs:current], 2  ; 2 tasks (main + music)
    jne .skipreset
    mov byte [cs:current], 0
.skipreset:
    mov bl, [cs:current]
    mov ax, 10
    mul bl
    mov bx, ax
    mov al, 0x20
    out 0x20, al
    push word [cs:taskstates+bx+8]
    push word [cs:taskstates+bx+6]
    push word [cs:taskstates+bx+4]
    mov ax, [cs:taskstates+bx+0]
    mov bx, [cs:taskstates+bx+2]
    iret

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

checkobscollision:
    push bp
    mov bp, sp
    push ax
    push bx
    
    ; Check obstacle 1
    mov ax, [obs1y]
    cmp ax, 0
    jl .checkobs2
    cmp ax, 24
    jge .checkobs2
    
    ; Condition 1: carx < obs1x + 5
    mov ax, [obs1x]
    add ax, 5
    cmp word [carx], ax
    jge .checkobs2          ; If carx >= obs1x+5, no overlap
    
    ; Condition 2: carx + 5 > obs1x
    mov ax, [carx]
    add ax, 5
    cmp ax, [obs1x]
    jle .checkobs2          ; If carx+5 <= obs1x, no overlap
    
    ; Condition 3: cary < obs1y + 3
    mov ax, [obs1y]
    add ax, 3
    cmp word [cary], ax
    jge .checkobs2          ; If cary >= obs1y+3, no overlap
    
    ; Condition 4: cary + 3 > obs1y
    mov ax, [cary]
    add ax, 3
    cmp ax, [obs1y]
    jle .checkobs2          ; If cary+3 <= obs1y, no overlap
    
    ; COLLISION with obstacle 1!
    mov byte [gameOver], 1
    jmp .done
    
.checkobs2:
    ; Check obstacle 2
    mov ax, [obs2y]
    cmp ax, 0
    jl .done
    cmp ax, 24
    jge .done
    
    ; Condition 1: carx < obs2x + 5
    mov ax, [obs2x]
    add ax, 5
    cmp word [carx], ax
    jge .done               ; If carx >= obs2x+5, no overlap
    
    ; Condition 2: carx + 5 > obs2x
    mov ax, [carx]
    add ax, 5
    cmp ax, [obs2x]
    jle .done               ; If carx+5 <= obs2x, no overlap
    
    ; Condition 3: cary < obs2y + 3
    mov ax, [obs2y]
    add ax, 3
    cmp word [cary], ax
    jge .done               ; If cary >= obs2y+3, no overlap
    
    ; Condition 4: cary + 3 > obs2y
    mov ax, [cary]
    add ax, 3
    cmp ax, [obs2y]
    jle .done               ; If cary+3 <= obs2y, no overlap
    
    ; COLLISION with obstacle 2!
    mov byte [gameOver], 1

.done:
    pop bx
    pop ax
    pop bp
    ret

; Check coin and fuel collision
checkCoinFuelCollision:
    push ax
    push bx
    
    ; Check coin 1
    mov ax, [c1y]
    cmp ax, 0
    jl .checkCoin2
    cmp ax, 24
    jge .checkCoin2
    
    ; Check if coin1 X within car width: c1x >= carx AND c1x < carx+5
    mov ax, [c1x]
    cmp ax, [carx]
    jl .checkCoin2          ; c1x < carx, no collision
    mov bx, [carx]
    add bx, 5
    cmp ax, bx
    jge .checkCoin2         ; c1x >= carx+5, no collision
    
    ; Check if coin1 Y within car height: c1y >= cary AND c1y < cary+3
    mov ax, [c1y]
    cmp ax, [cary]
    jl .checkCoin2          ; c1y < cary, no collision
    mov bx, [cary]
    add bx, 3
    cmp ax, bx
    jge .checkCoin2         ; c1y >= cary+3, no collision
    
    ; COIN 1 COLLECTED!
    mov ax, [score]
    add ax, 10
    mov [score], ax
    mov word [c1y], -2      ; Reset off-screen
    call getRandomX
    add ax, 2
    mov [c1x], ax
    
.checkCoin2:
    ; Check coin 2
    mov ax, [c2y]
    cmp ax, 0
    jl .checkFuel
    cmp ax, 24
    jge .checkFuel
    
    ; Check if coin2 X within car width
    mov ax, [c2x]
    cmp ax, [carx]
    jl .checkFuel
    mov bx, [carx]
    add bx, 5
    cmp ax, bx
    jge .checkFuel
    
    ; Check if coin2 Y within car height
    mov ax, [c2y]
    cmp ax, [cary]
    jl .checkFuel
    mov bx, [cary]
    add bx, 3
    cmp ax, bx
    jge .checkFuel
    
    ; COIN 2 COLLECTED!
    mov ax, [score]
    add ax, 10
    mov [score], ax
    mov word [c2y], -2
    call getRandomX
    add ax, 2
    mov [c2x], ax
    
.checkFuel:
    ; Check fuel
    mov ax, [fuely]
    cmp ax, 0
    jl .doneCoinFuel
    cmp ax, 24
    jge .doneCoinFuel
    
    ; Check if fuel X within car width
    mov ax, [fuelx]
    cmp ax, [carx]
    jl .doneCoinFuel
    mov bx, [carx]
    add bx, 5
    cmp ax, bx
    jge .doneCoinFuel
    
    ; Check if fuel Y within car height
    mov ax, [fuely]
    cmp ax, [cary]
    jl .doneCoinFuel
    mov bx, [cary]
    add bx, 3
    cmp ax, bx
    jge .doneCoinFuel
    
    ; FUEL COLLECTED!
    mov ax, [fuel]
    add ax, 3
    cmp ax, 10
    jle .setFuel
    mov ax, 10              ; Cap at 10
.setFuel:
    mov [fuel], ax
    mov word [fuely], -2
    call getRandomX
    add ax, 2
    mov [fuelx], ax
    
.doneCoinFuel:
    pop bx
    pop ax
    ret

printfuelguage:
push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push di
mov ax, 0xb800
mov es, ax ; point es to video base

; Draw "FUEL" label at row 3, col 60
mov di, 600  ; (row 3, col 60) * 2
mov ah, 0x0E  ; bright yellow
mov al, 'F'
mov [es:di], ax
add di, 2
mov al, 'U'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, 'L'
mov [es:di], ax

; Draw top border at row 4, col 60-64 (5 blocks)
mov di, 760  ; (row 4, col 60) * 2
mov ax, 0x07DB ; white top border
mov cx, 5
.topBorder:
mov [es:di], ax
add di, 2
loop .topBorder

; Draw 11 vertical fuel rows (rows 5-15) - 11th bar is always hidden
mov di, 920  ; Start at row 5, col 60
mov cx, 11   ; 11 fuel blocks (one extra hidden)
mov bx, [fuel]

.drawBar:
cmp cx, 0
jle .bottomBorder

; Left border
mov ax, 0x07DB ; white left border
mov [es:di], ax
add di, 2

; Determine if this cell should be filled (3 blocks wide)
cmp cx, bx
jg .emptyCell

; Filled cell - color based on fuel level
mov al, 0xDB ; Full block
push cx
mov cx, 3    ; 3 blocks wide
cmp bx, 7
jge .greenFill
cmp bx, 4
jge .yellowFill
mov ah, 0x0C  ; bright red
jmp .fillLoop
.yellowFill:
mov ah, 0x0E  ; bright yellow
jmp .fillLoop
.greenFill:
mov ah, 0x0A  ; bright green
.fillLoop:
mov [es:di], ax
add di, 2
loop .fillLoop
pop cx
jmp .rightBorder

.emptyCell:
; Empty greyed out cell (3 blocks wide)
push cx
mov ax, 0x08B0 ; dark gray
mov cx, 3
.emptyLoop:
mov [es:di], ax
add di, 2
loop .emptyLoop
pop cx

.rightBorder:
mov ax, 0x07DB ; white right border
mov [es:di], ax
add di, 160 - 8  ; Next row, back to col 60 (160 - 4*2)
dec cx
jmp .drawBar

.bottomBorder:
; Bottom border at row 15, col 60-64
mov ax, 0x07DB ; white bottom border
mov cx, 5
.bottomLoop:
mov [es:di], ax
add di, 2
loop .bottomLoop

.done:
pop di
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret

printscore: 
push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push di
mov ax, 0xb800
mov es, ax ; point es to video base

; Display score at top-right corner (row 1, starting at column 60)
mov di, 280  ; (row 1, col 60) * 2

; "SCORE:" text in bright yellow
mov ah, 0x0E  ; bright yellow on black
mov al, 'S'
mov [es:di], ax
add di, 2
mov al, 'C'
mov [es:di], ax
add di, 2
mov al, 'O'
mov [es:di], ax
add di, 2
mov al, 'R'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, ':'
mov [es:di], ax
add di, 2
mov al, ' '
mov [es:di], ax
add di, 2

; Score number in bright white
mov ax, [score]
mov bx, 10
mov cx, 0
.nextdigit:
mov dx, 0
div bx
add dl, 0x30
push dx
inc cx
cmp ax, 0
jnz .nextdigit

; Print digits
.nextpos:
pop dx
mov dh, 0x0F  ; bright white on black
mov [es:di], dx
add di, 2
loop .nextpos

pop di
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret

overmessage: db 'GAME OVER ! Press esc to exit or Y to retry',0
overscreen:
call clrscr
push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push si
push di

mov ax, 0xb800
mov es, ax

; Display "GAME OVER" at row 10, centered (col 35)
mov di, 1670  ; (row 10, col 35) * 2
mov ah, 0x0C  ; bright red
mov al, 'G'
mov [es:di], ax
add di, 2
mov al, 'A'
mov [es:di], ax
add di, 2
mov al, 'M'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, ' '
mov [es:di], ax
add di, 2
mov al, 'O'
mov [es:di], ax
add di, 2
mov al, 'V'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, 'R'
mov [es:di], ax

; Draw separator line at row 11
mov di, 1760  ; (row 11, col 0) * 2
mov ax, 0x07C4 ; gray horizontal line
mov cx, 80
.line1:
mov [es:di], ax
add di, 2
loop .line1

; Display "PLAYER:" label at row 13, col 33
mov di, 2146  ; (row 13, col 33) * 2
mov ah, 0x0B  ; bright cyan
mov al, 'P'
mov [es:di], ax
add di, 2
mov al, 'L'
mov [es:di], ax
add di, 2
mov al, 'A'
mov [es:di], ax
add di, 2
mov al, 'Y'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, 'R'
mov [es:di], ax
add di, 2
mov al, ':'
mov [es:di], ax
add di, 4  ; Extra space

; Display player name
mov ah, 0x0E  ; bright yellow
mov si, playerName
.printName:
mov al, [si]
cmp al, 0
je .afterName
mov [es:di], ax
add di, 2
inc si
jmp .printName

.afterName:
; Display "SCORE:" label at row 15, col 35
mov di, 2470  ; (row 15, col 35) * 2
mov ah, 0x0B  ; bright cyan
mov al, 'S'
mov [es:di], ax
add di, 2
mov al, 'C'
mov [es:di], ax
add di, 2
mov al, 'O'
mov [es:di], ax
add di, 2
mov al, 'R'
mov [es:di], ax
add di, 2
mov al, 'E'
mov [es:di], ax
add di, 2
mov al, ':'
mov [es:di], ax
add di, 4  ; Extra space

; Display score number
mov ax, [score]
mov bx, 10
mov cx, 0
.nextdigit:
mov dx, 0
div bx
add dl, 0x30
push dx
inc cx
cmp ax, 0
jnz .nextdigit
.nextpos:
pop dx
mov dh, 0x0E  ; bright yellow
mov [es:di], dx
add di, 2
loop .nextpos

; Draw separator line at row 16
mov di, 2560  ; (row 16, col 0) * 2
mov ax, 0x07C4 ; gray horizontal line
mov cx, 80
.line2:
mov [es:di], ax
add di, 2
loop .line2

; Display "Press Y to Restart or ESC to Quit" at row 19, centered
mov di, 3084  ; (row 19, col 22) * 2
mov ah, 0x07  ; gray
mov si, restartmsg
mov cx, 34
.printRestart:
mov al, [si]
mov [es:di], ax
add di, 2
inc si
loop .printRestart

pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret

restartmsg: db 'Press Y to Restart or ESC to Quit'



keys: db 'Use Arrow Keys to Move the Car',0
fuelinfo: db 'Collect Fuel to keep going!',0
coininfo: db 'Collect Coins to score points!',0
quitting: db 'Press ESC to Quit the Game Anytime',0
;function for instruction screen
instructionscreen:
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
mov dx, 0x021D
mov cx, 18
push cs 
pop es
mov bp, gamename
int 0x10
mov bp, keys
mov dx, 0x0805
push cs
pop es
mov cx, 30
int 0x10
mov bp, fuelinfo
mov dx, 0x0A05
push cs
pop es
mov cx, 29
int 0x10
mov bp, coininfo
mov dx, 0x0C05
push cs
pop es
mov cx,  30
int 0x10
mov bp, quitting
mov dx, 0x0F05
push cs
pop es
mov cx, 34
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








mem1: db 'Muhammad Hassan -- 24L-0503',0
mem2: db 'Muhammad Abdullah -- 24L-0864',0

;function for info screen
infoscreen:
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
mov bp, mem1
mov dx, 0x1205
push cs
pop es
mov cx, 27
int 0x10
mov bp, mem2
mov dx, 0x1405
push cs
pop es
mov cx, 29
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

gamename: db 'Raceless Zone Zero',0
entername: db 'Enter Your Name: ',0
startmessage: db 'Press any key to start...',0

;function to get player name
namescreen:
call clrscr
push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push si
push di

mov ax, 0xb800
mov es, ax

; Display "Enter Your Name:" at row 10, col 30
mov di, 1660  ; (row 10, col 30) * 2
mov ah, 0x0E  ; bright yellow
mov si, entername
mov cx, 17
.printPrompt:
mov al, [si]
mov [es:di], ax
add di, 2
inc si
loop .printPrompt

; Get input from keyboard
mov si, playerName
mov cx, 0  ; Character count
.getChar:
mov ah, 0
int 16h

; Check for Enter key
cmp al, 13
je .done

; Check for backspace
cmp al, 8
jne .notBackspace
cmp cx, 0
je .getChar
; Handle backspace
dec si
mov byte [si], 0
dec cx
; Clear character on screen
sub di, 2
mov ax, 0x0720
mov [es:di], ax
jmp .getChar

.notBackspace:
; Check if printable character and not full
cmp al, 32
jl .getChar
cmp al, 126
jg .getChar
cmp cx, 19
jge .getChar

; Store character
mov [si], al
inc si
inc cx

; Display character on screen
mov ah, 0x0F  ; bright white
mov [es:di], ax
add di, 2
jmp .getChar

.done:
mov byte [si], 0  ; Null terminate

pop di
pop si
pop dx
pop cx
pop bx
pop ax
pop es
pop bp
ret

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

;function to draw road with 3 visible lanes
drawroad:
push bp
mov bp, sp
push es
push ax
push bx
push cx
push dx
push si
push di
mov ax, 0xb800
mov es, ax ; point es to video base

; Draw left road edge (X=10 to X=12) - green grass/border
mov cx, 25
mov ax, 0x22B2 ; green medium shade (grass-like)
mov di, 0
add di, 20     ; X=10 in bytes
.leftEdge:
mov [es:di], ax
mov [es:di+2], ax  ; X=11
mov [es:di+4], ax  ; X=12
add di, 160 ; move to next row
loop .leftEdge

; Draw lane divider 1 (X=23, between lane 1 and 2) - dashed white line
mov bx, 0      ; row counter
mov di, 0
add di, 46     ; X=23 in bytes
.divider1:
mov ax, bx
and ax, 3      ; Check if row % 4 is 0 or 1 (creates gaps)
cmp ax, 2
jge .skip1
mov ax, 0x0FDB ; white dashed line
mov [es:di], ax
.skip1:
add di, 160
inc bx
cmp bx, 25
jl .divider1

; Draw lane divider 2 (X=35, between lane 2 and 3) - dashed white line
mov bx, 0      ; row counter
mov di, 0
add di, 70     ; X=35 in bytes
.divider2:
mov ax, bx
and ax, 3      ; Check if row % 4 is 0 or 1 (creates gaps)
cmp ax, 2
jge .skip2
mov ax, 0x0FDB ; white dashed line
mov [es:di], ax
.skip2:
add di, 160
inc bx
cmp bx, 25
jl .divider2

; Draw right road edge (X=47 to X=49) - green grass/border
mov cx, 25
mov ax, 0x22B2 ; green medium shade (grass-like)
mov di, 0
add di, 94     ; X=47 in bytes
.rightEdge:
mov [es:di], ax
mov [es:di+2], ax  ; X=48
mov [es:di+4], ax  ; X=49
add di, 160 ; move to next row
loop .rightEdge

done:
pop di
pop si
pop dx
pop cx
pop bx
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

;function to draw car (5 blocks wide)
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
mov al, 0xDB ; Full block character
cld ; auto increment mode

; Top row - 5 blocks wide (car color)
mov cx, 5
line1:
stosw ; print char/attribute pair
loop line1

; Middle row - 5 blocks wide (white/light gray)
mov ah, 0x77  ; White on gray background
mov cx, 5
add di, 150
line2:
stosw ; print char/attribute pair
loop line2

; Bottom row - 5 blocks wide (car color)
mov ah, [bp+8];car attribute
mov cx, 5
add di, 150
line4:
stosw ; print char/attribute pair
loop line4

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

; Clear top row - 5 blocks
mov cx, 5
line13:
stosw ; print char/attribute pair
loop line13

; Clear middle row - 5 blocks
mov cx, 5
add di, 150
line23:
stosw ; print char/attribute pair
loop line23

; Clear bottom row - 5 blocks
mov cx, 5
add di, 150
line43:
stosw ; print char/attribute pair
loop line43

done23:
pop di
pop si
pop cx
pop ax
pop es
pop bp
ret
; Generate random lane position (returns 15, 25, or 35)
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
    
    ; Get random lane (0, 1, or 2)
    mov bx, 3         ; 3 lanes
    xor dx, dx
    div bx            ; DX = remainder (0, 1, or 2)
    
    ; Convert to lane position
    cmp dx, 0
    je .lane1
    cmp dx, 1
    je .lane2
    ; Lane 3
    mov ax, [lane3]   ; X = 35
    jmp .done
    
    .lane1:
    mov ax, [lane1]   ; X = 15
    jmp .done
    
    .lane2:
    mov ax, [lane2]   ; X = 25
    
    .done:
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
    mov word [obs1y], -2
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
    mov word [obs2y], -2
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
    add ax, 2              ; Center in lane (lane is 5 blocks wide)
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
    add ax, 2              ; Center in lane (lane is 5 blocks wide)
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
    add ax, 2              ; Center in lane (lane is 5 blocks wide)
    mov [fuelx], ax
    .done:
    pop bx
    pop ax
    ret

; Consume fuel over time (every ~5 seconds)
consumeFuel:
    push ax
    push bx
    
    ; Increment fuel timer
    mov ax, [fuelTimer]
    inc ax
    mov [fuelTimer], ax
    
    ; Check if 5 seconds have passed (~50 frames for testing)
    cmp ax, 35
    jl .done
    
    ; Reset timer
    mov word [fuelTimer], 0
    
    ; Decrease fuel by 1
    mov ax, [fuel]
    dec ax
    mov [fuel], ax
    
    ; Check if fuel reached 0 or below
    cmp ax, 0
    jle .gameOver
    jmp .done
    
    .gameOver:
    mov byte [gameOver], 1
    
    .done:
    pop bx
    pop ax
    ret

; Delay function (adjust for speed)
gameDelay:
    push cx
    push dx
    
    mov cx, 0x05      ; Outer loop count (increased from 0x02 for slower speed)
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
    push bx
    
    ; Decrement move delay timer if active
    mov bx, [moveDelay]
    cmp bx, 0
    jle .checkKey
    dec bx
    mov [moveDelay], bx
    
    .checkKey:
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
    
    ; Check for 'M' to toggle music
    cmp al, 'M'
    je .toggleMusic
    cmp al, 'm'
    je .toggleMusic
    
    cmp ah, 0x4B   ; Left arrow
    je .leftKey
    cmp ah, 0x4D   ; Right arrow
    je .rightKey
    cmp ah, 0x48   ; Up arrow
    je .upKey
    cmp ah, 0x50   ; Down arrow
    je .downKey
    jmp .noKey
    
    .toggleMusic:
    mov al, [musicEnabled]
    xor al, 1
    mov [musicEnabled], al
    jmp .noKey


    .leftKey:
    ; Check if move delay is active
    mov bx, [moveDelay]
    cmp bx, 0
    jg .noKey        ; Still in delay, ignore input
    call drawemptycar
    ; Move car to left lane
    mov dx, [currentLane]
    cmp dx, 1
    jle .noKey       ; Already in leftmost lane
    dec dx
    mov [currentLane], dx
    ; Set movement delay (5 frames)
    mov word [moveDelay], 5
    ; Update carx based on lane
    cmp dx, 1
    je .setLane1L
    mov ax, [lane2]
    mov [carx], ax
    jmp .noKey
    .setLane1L:
    mov ax, [lane1]
    mov [carx], ax
    jmp .noKey

    .rightKey:
    ; Check if move delay is active
    mov bx, [moveDelay]
    cmp bx, 0
    jg .noKey        ; Still in delay, ignore input
    call drawemptycar
    ; Move car to right lane
    mov dx, [currentLane]
    cmp dx, 3
    jge .noKey       ; Already in rightmost lane
    inc dx
    mov [currentLane], dx
    ; Set movement delay (5 frames)
    mov word [moveDelay], 5
    ; Update carx based on lane
    cmp dx, 3
    je .setLane3R
    mov ax, [lane2]
    mov [carx], ax
    jmp .noKey
    .setLane3R:
    mov ax, [lane3]
    mov [carx], ax
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
    pop bx
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

    ; Consume fuel over time
    call consumeFuel
    
    ; Move obstacles down
    call moveObstacles

    ;print score
    call printscore

    ;print fuel gauge
    call printfuelguage

    ; Check collisions
    call checkobscollision
    call checkCoinFuelCollision

    ; Delay to control obstacle speed
    call gameDelay
    
    ; Check for input (no delay for responsive controls)
    call checkInput
    
    ; Loop back (infinite loop until ESC pressed)
    jmp gameLoop

    .endGame:
    ; Show game over screen
    call overscreen
    mov ah,0
    int 16h
    cmp al,27
    je .exit
    cmp al,'Y'
    je start
    cmp al,'y'
    je start
    cmp al,'N'
    je .exit
    cmp al,'n'
    je .exit
    jmp .endGame

    .exit:
    ; Clear screen before exit
    call clrscr
    
    ; Disable music and turn off speaker
    mov byte [musicEnabled], 0
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
    ; Restore original timer interrupt
    xor ax, ax
    mov es, ax
    cli
    mov ax, [oldTimerIP]
    mov [es:8*4], ax
    mov ax, [oldTimerCS]
    mov [es:8*4+2], ax
    sti
    
    ret

start: 
    ; Reset game variables
    mov word [score], 0
    mov word [fuel], 10
    mov byte [gameOver], 0
    mov word [fuelTimer], 0
    mov byte [musicEnabled], 1
    
    call infoscreen
        ; Wait for key press to continue
    call namescreen
        ; Get player name
    call instructionscreen
        ; Wait for key press to continue
    call startscreen
        ; Wait for key press to start

    ; NOW initialize multitasking (after all keyboard input is done)
    mov word [taskstates+10+4], musicTask
    mov [taskstates+10+6], cs
    mov word [taskstates+10+8], 0x0200
    mov word [current], 0
    
    ; Save and hook timer interrupt
    xor ax, ax
    mov es, ax
    cli
    mov ax, [es:8*4]
    mov [oldTimerIP], ax
    mov ax, [es:8*4+2]
    mov [oldTimerCS], ax
    mov word [es:8*4], timer
    mov [es:8*4+2], cs
    sti

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
    add ax, 2              ; Center in lane
    mov [c1x], ax
    mov word [c1y], 5
    
    call getRandomX
    add ax, 2              ; Center in lane
    mov [c2x], ax
    mov word [c2y], 10
    
    call getRandomX
    add ax, 2              ; Center in lane
    mov [fuelx], ax
    mov word [fuely], 15
    
    ; Start the game loop
    call gameLoop
    
    ; Exit to DOS (after game ends)
    mov ax, 0x4c00
    int 0x21