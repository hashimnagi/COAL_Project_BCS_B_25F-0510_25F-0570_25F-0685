; drawing primitives (pixels, rects, borders)


; put pixel with clipping
put_pixel:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push di
    push es

    mov bx, [bp+8]
    cmp bx, 0
    jl .done
    cmp bx, SCREEN_W
    jge .done

    mov ax, [bp+6]
    cmp ax, 0
    jl .done
    cmp ax, SCREEN_H
    jge .done

    ; offset = y*320 + x = (y<<8) + (y<<6) + x
    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, bx

    mov es, [fb_seg]
    mov al, [bp+4]
    mov [es:di], al

.done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; draw clipped filled rectangle
fill_rect:
    push bp
    mov bp, sp
    sub sp, 8                   ; -2:x1, -4:y1, -6:cw, -8:ch
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, [bp+12]
    mov bx, [bp+8]
    cmp bx, 0
    jg .w_pos
    jmp .done
.w_pos:
    mov dx, ax
    add dx, bx

    cmp ax, 0
    jge .x1_ok
    xor ax, ax
.x1_ok:
    cmp dx, SCREEN_W
    jle .x2_ok
    mov dx, SCREEN_W
.x2_ok:
    sub dx, ax
    cmp dx, 0
    jg .x_vis
    jmp .done
.x_vis:
    mov [bp-2], ax
    mov [bp-6], dx

    mov ax, [bp+10]
    mov bx, [bp+6]
    cmp bx, 0
    jg .h_pos
    jmp .done
.h_pos:
    mov dx, ax
    add dx, bx

    cmp ax, 0
    jge .y1_ok
    xor ax, ax
.y1_ok:
    cmp dx, SCREEN_H
    jle .y2_ok
    mov dx, SCREEN_H
.y2_ok:
    sub dx, ax
    cmp dx, 0
    jg .y_vis
    jmp .done
.y_vis:
    mov [bp-4], ax
    mov [bp-8], dx

    ; DI = y1 * 320 + x1
    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, [bp-2]

    mov es, [fb_seg]
    mov al, [bp+4]
    mov dx, [bp-8]
    mov bx, SCREEN_W
    sub bx, [bp-6]
    cld
.row_loop:
    mov cx, [bp-6]
    rep stosb
    add di, bx
    dec dx
    jnz .row_loop

.done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 10

; draw rectangle with border
draw_box_border:
    push bp
    mov bp, sp
    push ax

    push word [bp+14]
    push word [bp+12]
    push word [bp+10]
    push word [bp+8]
    push word [bp+4]
    call fill_rect

    mov ax, [bp+14]
    add ax, 2
    push ax
    mov ax, [bp+12]
    add ax, 2
    push ax
    mov ax, [bp+10]
    sub ax, 4
    push ax
    mov ax, [bp+8]
    sub ax, 4
    push ax
    push word [bp+6]
    call fill_rect

    pop ax
    pop bp
    ret 12

