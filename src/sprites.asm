; sprite & tile rendering engine


; draw sprite with transparency and optional horizontal flip
draw_sprite:
    push bp
    mov bp, sp
    sub sp, 12                  ; -2:cx,-4:vw,-6:sl,-8:cy,-10:vh,-12:src
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; Horizontal clipping
    mov ax, [bp+14]
    mov dx, ax
    add dx, [bp+8]
    mov word [bp-6], 0

    cmp ax, 0
    jge .x1_ok
    mov bx, ax
    neg bx
    mov [bp-6], bx
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
    mov [bp-4], dx

    ; Vertical clipping
    mov ax, [bp+12]
    mov dx, ax
    add dx, [bp+6]
    xor bx, bx

    cmp ax, 0
    jge .y1_ok
    mov bx, ax
    neg bx
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
    mov [bp-8], ax
    mov [bp-10], dx

    ; row_src = spr_ptr + skip_t * w
    mov ax, bx
    mul word [bp+8]
    add ax, [bp+10]
    mov [bp-12], ax

    ; DI = clip_y * 320 + clip_x
    mov ax, [bp-8]
    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, [bp-2]

    mov es, [fb_seg]
    mov bx, SCREEN_W
    sub bx, [bp-4]
    mov dx, [bp-10]
    cld

    cmp word [bp+4], 0
    jne .row_flip

.row_norm:
    mov si, [bp-12]
    add si, [bp-6]
    mov cx, [bp-4]
.pix_norm:
    lodsb
    or al, al
    jz .sk_n
    mov [es:di], al
.sk_n:
    inc di
    loop .pix_norm

    add di, bx
    mov ax, [bp+8]
    add [bp-12], ax
    dec dx
    jnz .row_norm
    jmp .done

.row_flip:
    mov si, [bp-12]
    add si, [bp+8]
    dec si
    sub si, [bp-6]
    mov cx, [bp-4]
.pix_flip:
    mov al, [si]
    dec si
    or al, al
    jz .sk_f
    mov [es:di], al
.sk_f:
    inc di
    loop .pix_flip

    add di, bx
    mov ax, [bp+8]
    add [bp-12], ax
    dec dx
    jnz .row_flip

.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 12

; draw 16x16 opaque tile
draw_opaque_tile:
    push bp
    mov bp, sp
    sub sp, 4                   ; -2:vis_w, -4:skip_src
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov bx, [bp+8]
    mov ax, [bp+6]
    cmp ax, 0
    jge .y_ok1
    jmp .done
.y_ok1:
    cmp ax, SCREEN_H - 16
    jle .y_ok2
    jmp .done
.y_ok2:

    mov es, [fb_seg]
    mov si, [bp+4]
    cld

    cmp bx, 0
    jl .clipped
    cmp bx, SCREEN_W - 16
    jg .clipped

    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, bx

    mov dx, 16
.fast_row:
    mov cx, 8
    rep movsw
    add di, SCREEN_W - 16
    dec dx
    jnz .fast_row
    jmp .done

.clipped:
    mov dx, bx
    add dx, 16
    cmp bx, 0
    jge .cx1_ok
    mov cx, bx
    neg cx
    add si, cx
    xor bx, bx
.cx1_ok:
    cmp dx, SCREEN_W
    jle .cx2_ok
    mov dx, SCREEN_W
.cx2_ok:
    sub dx, bx
    cmp dx, 0
    jg .cw_ok
    jmp .done
.cw_ok:
    mov [bp-2], dx
    mov cx, 16
    sub cx, dx
    mov [bp-4], cx

    mov di, ax
    mov cl, 8
    shl ax, cl
    mov cl, 6
    shl di, cl
    add di, ax
    add di, bx

    mov bx, SCREEN_W
    sub bx, [bp-2]
    mov dx, 16
.clip_row:
    mov cx, [bp-2]
    rep movsb
    add si, [bp-4]
    add di, bx
    dec dx
    jnz .clip_row

.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 6

; draw 16x16 map tile
draw_tile:
    push bp
    mov bp, sp
    push ax
    push bx

    mov ax, [bp+4]
    cmp al, 1
    jb .done
    cmp al, MAX_TILE_ID
    ja .done

    ; Animated "?" blocks (IDs 3 & 4) toggle tile_qblock <-> obs1shadow
    cmp al, TILE_QCOIN
    je .anim_qblock
    cmp al, TILE_QMUSH
    je .anim_qblock

    mov bx, ax
    dec bx
    shl bx, 1
    add bx, tile_ptr_table
    mov bx, [bx]

    ; Opaque tiles: 1..5, 10, 15..18
    cmp al, 5
    jbe .opaque
    cmp al, 10
    je .opaque
    cmp al, 15
    jae .opaque

    push word [bp+8]
    push word [bp+6]
    push bx
    push 16
    push 16
    push 0
    call draw_sprite
    jmp .done

.anim_qblock:
    mov bx, tile_qblock
    test word [tick_count], 8
    jz .opaque
    mov bx, obs1shadow

.opaque:
    push word [bp+8]
    push word [bp+6]
    push bx
    call draw_opaque_tile

.done:
    pop bx
    pop ax
    pop bp
    ret 6

; get tile at world coords
get_tile:
    push bp
    mov bp, sp
    push bx
    push cx

    mov bx, [bp+6]
    cmp bx, 0
    jl .empty
    cmp bx, MAP_WIDTH
    jge .empty

    mov ax, [bp+4]
    cmp ax, 16
    jl .empty
    cmp ax, 192
    jge .empty

    mov cl, 4
    shr bx, cl
    shr ax, cl

    mov cl, 7
    shl ax, cl                  ; row * 128
    add bx, ax

    mov al, [work_map + bx]
    xor ah, ah
    jmp .done

.empty:
    xor ax, ax
.done:
    pop cx
    pop bx
    pop bp
    ret 4

; set tile in work map
set_tile:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx

    mov bx, [bp+8]
    cmp bx, 0
    jl .done
    cmp bx, MAP_COLS
    jge .done

    mov ax, [bp+6]
    cmp ax, 1
    jl .done
    cmp ax, MAP_ROWS
    jge .done

    mov cl, 7
    shl ax, cl
    add bx, ax
    mov al, [bp+4]
    mov [work_map + bx], al

.done:
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6

; returns 1 if tile is solid, else 0
is_tile_solid:
    push bp
    mov bp, sp
    mov ax, [bp+4]
    cmp al, 1
    jb .no
    cmp al, 10
    jbe .yes
.no:
    xor ax, ax
    jmp .done
.yes:
    mov ax, 1
.done:
    pop bp
    ret 2

; reload original map data into work_map
reset_map:
    push ax
    push cx
    push si
    push di
    push es

    mov ax, cs
    mov es, ax
    mov si, original_map
    mov di, work_map
    mov cx, MAP_SIZE
    cld
    rep movsb

    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

; draw visible scenery elements 
draw_scenery:
    push ax
    push si

    mov si, scenery_list
.loop:
    mov ax, [si]
    cmp ax, 0FFFFh
    je .done

    sub ax, [camera_x]
    cmp ax, -32
    jle .next
    cmp ax, SCREEN_W
    jge .next

    push ax
    push word [si+2]
    push word [si+4]
    push 32
    push 16
    push 0
    call draw_sprite

.next:
    add si, 6
    jmp .loop

.done:
    pop si
    pop ax
    ret

; draw visible columns of the tilemap
draw_map:
    push bp
    mov bp, sp
    sub sp, 6                   ; -2:first_col, -4:start_x, -6:row
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [camera_x]
    mov bx, ax
    mov cl, 4
    shr ax, cl
    mov [bp-2], ax

    and bx, 15
    neg bx
    mov [bp-4], bx

    mov word [bp-6], 1
    mov dx, 16

.row_loop:
    mov ax, [bp-6]
    mov cl, 7
    shl ax, cl
    add ax, [bp-2]
    mov si, work_map
    add si, ax

    mov bx, [bp-4]
    mov cx, 21
    mov ax, [bp-2]

.col_loop:
    cmp ax, MAP_COLS
    jge .skip_col
    push ax
    mov al, [si]
    cmp al, 0
    je .no_draw
    xor ah, ah
    push bx
    push dx
    push ax
    call draw_tile
.no_draw:
    pop ax
.skip_col:
    inc si
    inc ax
    add bx, 16
    dec cx
    jnz .col_loop

    add dx, 16
    inc word [bp-6]
    cmp word [bp-6], MAP_ROWS
    jl .row_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; draw flagpole ball and sliding flag
draw_win_flag:
    push ax
    push bx

    cmp byte [game_state], STATE_WIN_SEQ
    jne .done

    mov bx, FLAG_COL * 16
    sub bx, [camera_x]

    ; Top finial ball at row 2 (y=32)
    push bx
    push 32
    push spr_flag_ball
    push 16
    push 4
    push 0
    call draw_sprite

    ; Sliding white flag triangle
    push bx
    push word [flag_y]
    push spr_flag_tri
    push 8
    push 8
    push 0
    call draw_sprite

.done:
    pop bx
    pop ax
    ret

