; text & font rendering engine


; --- text, sprites, and tile drawing ---

; draw 8x8 bitmap character
draw_char:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, [bp+6]
    cmp al, 'a'
    jb .case_ok
    cmp al, 'z'
    ja .case_ok
    sub al, 32
.case_ok:
    cmp al, 32
    jae .c_min_ok
    jmp .done
.c_min_ok:
    cmp al, 90
    jbe .c_max_ok
    jmp .done
.c_max_ok:

    mov bx, [bp+10]
    cmp bx, 0
    jge .x_min_ok
    jmp .done
.x_min_ok:
    cmp bx, SCREEN_W - 8
    jle .x_max_ok
    jmp .done
.x_max_ok:
    mov dx, [bp+8]
    cmp dx, 0
    jge .y_min_ok
    jmp .done
.y_min_ok:
    cmp dx, SCREEN_H - 8
    jle .y_max_ok
    jmp .done
.y_max_ok:

    sub al, 32
    xor ah, ah
    mov cl, 3
    shl ax, cl
    mov si, font_table
    add si, ax

    mov ax, dx
    mov di, dx
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, bx

    mov es, [fb_seg]
    mov ah, [bp+4]
    mov dx, 8
.row_loop:
    mov bl, [si]
    inc si
    mov cx, 8
.col_loop:
    shl bl, 1
    jnc .skip
    mov [es:di], ah
.skip:
    inc di
    loop .col_loop
    add di, SCREEN_W - 8
    dec dx
    jnz .row_loop

.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 8

; draw null-terminated string
draw_string:
    push bp
    mov bp, sp
    push ax
    push bx
    push si

    mov bx, [bp+10]
    mov si, [bp+6]
.char_loop:
    mov al, [si]
    cmp al, 0
    je .done
    xor ah, ah
    push bx
    push word [bp+8]
    push ax
    push word [bp+4]
    call draw_char
    add bx, 8
    inc si
    jmp .char_loop

.done:
    pop si
    pop bx
    pop ax
    pop bp
    ret 8

; draw number in decimal
draw_number:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [bp+10]
    mov dx, [bp+8]
    mov cx, [bp+6]
    mov bx, 10

    ; Safe 32-bit by 16-bit division loop
.div_loop:
    push cx
    mov si, ax
    mov ax, dx
    xor dx, dx
    div bx
    mov cx, ax
    mov ax, si
    div bx
    mov si, dx
    mov dx, cx
    pop cx

    add si, '0'
    push si
    loop .div_loop

    mov bx, [bp+14]
    mov cx, [bp+6]
.draw_loop:
    pop ax
    push bx
    push word [bp+12]
    push ax
    push word [bp+4]
    call draw_char
    add bx, 8
    loop .draw_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 12

; draw 8x8 hud heart 
draw_heart:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, [bp+6]
    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, [bp+8]

    mov es, [fb_seg]
    mov si, heart_bitmap
    mov ah, [bp+4]
    mov dx, 8
.row_loop:
    mov bl, [si]
    inc si
    mov cx, 8
.col_loop:
    shl bl, 1
    jnc .skip
    mov [es:di], ah
.skip:
    inc di
    loop .col_loop
    add di, SCREEN_W - 8
    dec dx
    jnz .row_loop

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

