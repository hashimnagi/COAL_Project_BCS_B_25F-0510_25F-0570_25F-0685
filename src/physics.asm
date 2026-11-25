; camera tracking & world physics


; --- camera and physics ---

; update camera following player
update_camera:
    push ax

    mov ax, [mario_x]
    sub ax, [camera_x]
    cmp ax, 160
    jle .check_left

    mov ax, [mario_x]
    sub ax, 160
    cmp ax, MAX_CAMERA
    jle .cap_ok
    mov ax, MAX_CAMERA
.cap_ok:
    cmp ax, [camera_x]
    jle .check_left
    mov [camera_x], ax

.check_left:
    mov ax, [camera_x]
    cmp [mario_x], ax
    jge .done
    mov [mario_x], ax
    mov byte [mario_x_frac], 0
    mov word [mario_vx], 0

.done:
    pop ax
    ret

; aabb box overlap test
check_rect_overlap:
    push bp
    mov bp, sp
    push bx

    mov ax, [bp+18]
    add ax, [bp+14]
    cmp ax, [bp+10]
    jle .no

    mov ax, [bp+10]
    add ax, [bp+6]
    cmp ax, [bp+18]
    jle .no

    mov ax, [bp+16]
    add ax, [bp+12]
    cmp ax, [bp+8]
    jle .no

    mov ax, [bp+8]
    add ax, [bp+4]
    cmp ax, [bp+16]
    jle .no

    mov ax, 1
    jmp .done

.no:
    xor ax, ax
.done:
    pop bx
    pop bp
    ret 16

; hit block from underneath
trigger_block:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov bx, [bp+6]
    mov dx, [bp+4]
    mov cl, 4
    shl bx, cl
    shl dx, cl

    push bx
    push dx
    call get_tile

    cmp al, TILE_BRICK
    je .hit_brick
    cmp al, TILE_QCOIN
    jne .chk_qmush
    jmp .hit_qcoin
.chk_qmush:
    cmp al, TILE_QMUSH
    jne .go_done
    jmp .hit_qmush
.go_done:
    jmp .done

.hit_brick:
    cmp byte [mario_form], 1
    je .break_brick
    push 3600
    push 3
    call play_sound
    jmp .done

.break_brick:
    push word [bp+6]
    push word [bp+4]
    push TILE_SKY
    call set_tile
    push 50
    call add_score
    push bx
    push dx
    push str_pop_50
    call spawn_popup

    ; 4 brick debris chunks
    push 2
    push bx
    push dx
    push -2
    push -6
    call spawn_particle
    push 2
    mov ax, bx
    add ax, 10
    push ax
    push dx
    push 2
    push -6
    call spawn_particle
    push 2
    push bx
    mov ax, dx
    add ax, 8
    push ax
    push -1
    push -4
    call spawn_particle
    push 2
    mov ax, bx
    add ax, 10
    push ax
    mov ax, dx
    add ax, 8
    push ax
    push 1
    push -4
    call spawn_particle
    push 2200
    push 4
    call play_sound
    jmp .done

.hit_qcoin:
    push word [bp+6]
    push word [bp+4]
    push TILE_EMPTY
    call set_tile
    push 200
    call add_score
    call add_coin
    mov ax, dx
    sub ax, 16
    push 1
    push bx
    push ax
    push 0
    push -5
    call spawn_particle
    push bx
    push ax
    push str_pop_200
    call spawn_popup
    push 1100
    push 4
    call play_sound
    jmp .done

.hit_qmush:
    push word [bp+6]
    push word [bp+4]
    push TILE_EMPTY
    call set_tile
    mov byte [mush_active], 1
    mov [mush_x], bx
    mov byte [mush_x_frac], 0
    mov ax, dx
    sub ax, 16
    mov [mush_y], ax
    mov byte [mush_y_frac], 0
    mov word [mush_vx], MUSH_SPD
    mov word [mush_vy], 0
    push 1500
    push 6
    call play_sound

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 4

; collect overlapping coin tiles
collect_map_coins:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, 16
    cmp byte [mario_form], 0
    je .h_ok
    mov ax, 32
.h_ok:
    mov bx, [mario_x]
    add bx, 2
    mov cl, 4
    shr bx, cl
    mov si, [mario_x]
    add si, 13
    shr si, cl

    mov dx, [mario_y]
    shr dx, cl
    mov di, [mario_y]
    add di, ax
    dec di
    shr di, cl

.row_loop:
    cmp dx, di
    jle .r_ok1
    jmp .done
.r_ok1:
    cmp dx, 1
    jl .next_row
    cmp dx, MAP_ROWS
    jl .r_ok2
    jmp .done
.r_ok2:

    push bx
.col_loop:
    cmp bx, si
    jg .end_col
    mov ax, bx
    mov cl, 4
    shl ax, cl
    push ax
    mov ax, dx
    shl ax, cl
    push ax
    call get_tile
    cmp al, TILE_COIN
    jne .next_col

    push bx
    push dx
    push TILE_SKY
    call set_tile
    push 200
    call add_score
    call add_coin

    mov ax, bx
    mov cl, 4
    shl ax, cl
    push ax
    mov ax, dx
    shl ax, cl
    push ax
    push str_pop_200
    call spawn_popup
    push 1100
    push 3
    call play_sound

.next_col:
    inc bx
    jmp .col_loop
.end_col:
    pop bx
.next_row:
    inc dx
    jmp .row_loop

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

