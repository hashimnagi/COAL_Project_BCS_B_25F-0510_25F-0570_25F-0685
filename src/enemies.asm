; enemy logic, ai & collision

; --- enemy logic ---

; initialize enemy table from spawn data
reset_enemies:
    push ax
    push cx
    push si
    push di
    push es

    mov ax, cs
    mov es, ax
    mov di, enemies
    mov cx, MAX_ENEMIES * ENEMY_SIZE
    xor al, al
    cld
    rep stosb

    mov si, level_enemies
    mov di, enemies
    mov cx, MAX_ENEMIES
.load_loop:
    mov al, [si]
    cmp al, 0
    je .done
    mov [di + EN_TYPE], al
    mov byte [di + EN_STATE], 1
    mov ax, [si+1]
    mov [di + EN_X], ax
    mov ax, [si+3]
    mov [di + EN_Y], ax
    add si, 5
    add di, ENEMY_SIZE
    loop .load_loop

.done:
    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

; update enemy positions, logic, and collisions
update_enemies:
    push bp
    mov bp, sp
    sub sp, 2                   ; -2:active_on_screen count
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov word [bp-2], 0
    mov si, enemies
    mov cx, MAX_ENEMIES
.cnt_loop:
    cmp byte [si + EN_STATE], 2
    jb .cnt_next
    inc word [bp-2]
.cnt_next:
    add si, ENEMY_SIZE
    loop .cnt_loop

    mov si, enemies
    mov cx, MAX_ENEMIES
.en_loop:
    push cx
    mov al, [si + EN_STATE]
    cmp al, 0
    jne .not_dead
    jmp .next_en
.not_dead:
    cmp al, 1
    jne .not_waiting

    cmp word [bp-2], 8
    jb .can_act
    jmp .next_en
.can_act:
    mov ax, [camera_x]
    add ax, SCREEN_W + 16
    cmp [si + EN_X], ax
    jle .do_act
    jmp .next_en
.do_act:
    mov byte [si + EN_STATE], 2
    mov byte [si + EN_DIR], 0
    mov word [si + EN_VY], 0
    cmp byte [si + EN_TYPE], 1
    jne .act_koopa
    mov word [si + EN_VX], -GOOMBA_SPD
    jmp .act_inc
.act_koopa:
    mov word [si + EN_VX], -KOOPA_SPD
.act_inc:
    inc word [bp-2]
    jmp .next_en

.not_waiting:
    cmp al, 3
    jne .not_flat
    dec byte [si + EN_TIMER]
    jnz .next_en_jmp
    mov byte [si + EN_STATE], 0
.next_en_jmp:
    jmp .next_en

.not_flat:
    cmp byte [si + EN_TIMER], 0
    je .no_grace
    dec byte [si + EN_TIMER]
.no_grace:

    inc byte [si + EN_ANIM]

    cmp byte [si + EN_STATE], 4
    jne .move_en_x
    jmp .en_grav
.move_en_x:

    mov ax, [si + EN_VX]
    add [si + EN_XFRAC], al
    mov al, ah
    cbw
    adc [si + EN_X], ax

    ; Wall check
    mov bx, [si + EN_X]
    cmp word [si + EN_VX], 0
    jle .w_chk_l
    add bx, 15
.w_chk_l:
    mov dx, [si + EN_Y]
    add dx, 8
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .turn_around

    ; Koopa Troopa turns around at platform ledges
    cmp byte [si + EN_TYPE], 2
    jne .en_grav
    cmp byte [si + EN_STATE], 2
    jne .en_grav
    mov bx, [si + EN_X]
    cmp word [si + EN_VX], 0
    jle .ledge_l
    add bx, 15
.ledge_l:
    mov dx, [si + EN_Y]
    add dx, 18
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 0
    jne .en_grav

.turn_around:
    neg word [si + EN_VX]
    xor byte [si + EN_DIR], 1
    cmp word [si + EN_VX], 0
    jge .nudge_r
    dec word [si + EN_X]
    jmp .en_grav
.nudge_r:
    inc word [si + EN_X]

.en_grav:
    mov ax, [si + EN_VY]
    add ax, GRAVITY
    cmp ax, MAX_FALL_SPD
    jle .evy_ok
    mov ax, MAX_FALL_SPD
.evy_ok:
    mov [si + EN_VY], ax
    add [si + EN_YFRAC], al
    mov al, ah
    cbw
    adc [si + EN_Y], ax

    mov dx, [si + EN_Y]
    add dx, 16
    mov bx, [si + EN_X]
    add bx, 3
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .en_land

    mov bx, [si + EN_X]
    add bx, 12
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    jne .en_despawn

.en_land:
    and dx, 0FFF0h
    sub dx, 16
    mov [si + EN_Y], dx
    mov byte [si + EN_YFRAC], 0
    mov word [si + EN_VY], 0

.en_despawn:
    cmp word [si + EN_Y], 192
    jge .remove_en
    mov ax, [si + EN_X]
    add ax, 32
    cmp ax, [camera_x]
    jge .en_vs_en
.remove_en:
    mov byte [si + EN_STATE], 0
    jmp .next_en

.en_vs_en:
    mov di, enemies
    mov cx, MAX_ENEMIES
.other_loop:
    cmp di, si
    je .other_next
    mov al, [di + EN_STATE]
    cmp al, 2
    jb .other_next
    cmp al, 3
    je .other_next

    push word [si + EN_X]
    push word [si + EN_Y]
    push 16
    push 16
    push word [di + EN_X]
    push word [di + EN_Y]
    push 16
    push 16
    call check_rect_overlap
    cmp al, 1
    jne .other_next

    ; Sliding shell kills other enemy for +500
    cmp byte [si + EN_STATE], 5
    jne .walker_bump
    mov byte [di + EN_STATE], 0
    push 500
    call add_score
    push word [di + EN_X]
    push word [di + EN_Y]
    push str_pop_500
    call spawn_popup
    push 1600
    push 4
    call play_sound
    jmp .other_next

.walker_bump:
    ; Flip once per pair (si < di) so walkers do not double-flip in same frame
    cmp si, di
    jae .other_next
    cmp byte [si + EN_STATE], 2
    jne .other_next
    cmp byte [di + EN_STATE], 2
    jne .other_next
    neg word [si + EN_VX]
    xor byte [si + EN_DIR], 1
    neg word [di + EN_VX]
    xor byte [di + EN_DIR], 1

.other_next:
    add di, ENEMY_SIZE
    dec cx
    jz .next_en
    jmp .other_loop

.next_en:
    pop cx
    add si, ENEMY_SIZE
    dec cx
    jz .done
    jmp .en_loop

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; award stomp chain points
award_stomp_points:
    push bp
    mov bp, sp
    push ax
    push bx

    mov bl, [mario_stomp_chain]
    xor bh, bh
    cmp bl, 10
    jae .give_1up

    shl bx, 1
    mov ax, [stomp_pts_table + bx]
    push ax
    call add_score

    mov ax, [stomp_str_table + bx]
    push word [bp+6]
    push word [bp+4]
    push ax
    call spawn_popup
    jmp .inc_chain

.give_1up:
    cmp byte [lives], 99
    jae .inc_chain
    inc byte [lives]
    push word [bp+6]
    push word [bp+4]
    push str_pop_1up
    call spawn_popup

.inc_chain:
    cmp byte [mario_stomp_chain], 20
    jae .done
    inc byte [mario_stomp_chain]

.done:
    pop bx
    pop ax
    pop bp
    ret 4

; handle mario taking damage
hurt_mario:
    cmp byte [mario_invuln], 0
    jne .done

    cmp byte [mario_hp], 2
    je .shrink

    push 0
    call start_death
    ret

.shrink:
    mov byte [mario_hp], 1
    mov byte [mario_form], 0
    add word [mario_y], 16      ; keep feet fixed
    mov byte [mario_invuln], 60 ; 2 seconds at 30 FPS
    push 3200
    push 8
    call play_sound

.done:
    ret

; handle collisions between mario and enemies
check_mario_enemies:
    push bp
    mov bp, sp
    sub sp, 2                   ; -2:mario_height
    push ax
    push bx
    push cx
    push si

    mov ax, 16
    cmp byte [mario_form], 0
    je .mh_ok
    mov ax, 32
.mh_ok:
    mov [bp-2], ax

    mov si, enemies
    mov cx, MAX_ENEMIES
.loop:
    cmp byte [game_state], STATE_PLAYING
    je .still_play
    jmp .done
.still_play:

    mov al, [si + EN_STATE]
    cmp al, 2
    jb .next_jmp
    cmp al, 3
    je .next_jmp

    mov ax, [mario_x]
    add ax, 2
    push ax
    push word [mario_y]
    push 12
    push word [bp-2]
    mov ax, [si + EN_X]
    inc ax
    push ax
    mov ax, [si + EN_Y]
    add ax, 2
    push ax
    push 14
    push 14
    call check_rect_overlap
    cmp al, 1
    je .overlapped

.next_jmp:
    jmp .next

.overlapped:
    mov al, [si + EN_STATE]

    ; Stationary shell -> kick (+400)
    cmp al, 4
    jne .not_still_shell
    cmp byte [si + EN_TIMER], 0
    jne .next_jmp

    mov byte [si + EN_STATE], 5
    mov byte [si + EN_TIMER], 8
    mov ax, [mario_x]
    cmp ax, [si + EN_X]
    jg .kick_left
    mov word [si + EN_VX], SHELL_SPD
    jmp .kick_pts
.kick_left:
    mov word [si + EN_VX], -SHELL_SPD
.kick_pts:
    push 400
    call add_score
    push word [si + EN_X]
    push word [si + EN_Y]
    push str_pop_400
    call spawn_popup
    push 1800
    push 4
    call play_sound
    jmp .next

.not_still_shell:
    cmp al, 5
    jne .test_stomp
    cmp byte [si + EN_TIMER], 0
    jne .next_jmp

.test_stomp:
    cmp word [mario_vy], 0
    jle .side_hit
    mov ax, [si + EN_Y]
    add ax, 10
    cmp [mario_prev_bot], ax
    jg .side_hit

    ; Stomp succeeded
    push word [si + EN_X]
    push word [si + EN_Y]
    call award_stomp_points

    mov word [mario_vy], STOMP_BOUNCE
    cmp byte [key_table + KEY_SPACE], 0
    je .bounce_ok
    mov word [mario_vy], STOMP_HI_BOUNCE
.bounce_ok:
    mov byte [mario_on_ground], 0
    push 2000
    push 4
    call play_sound

    cmp byte [si + EN_TYPE], 1
    jne .stomp_koopa
    mov byte [si + EN_STATE], 3
    mov byte [si + EN_TIMER], 30
    mov word [si + EN_VX], 0
    jmp .next

.stomp_koopa:
    mov byte [si + EN_STATE], 4
    mov byte [si + EN_TIMER], 8
    mov word [si + EN_VX], 0
    jmp .next

.side_hit:
    call hurt_mario

.next:
    add si, ENEMY_SIZE
    dec cx
    jz .done
    jmp .loop

.done:
    pop si
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; draw visible enemies
draw_enemies:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, enemies
    mov cx, MAX_ENEMIES
.loop:
    mov al, [si + EN_STATE]
    cmp al, 2
    jb .next

    mov bx, [si + EN_X]
    sub bx, [camera_x]
    cmp bx, -16
    jle .next
    cmp bx, SCREEN_W
    jge .next

    xor dx, dx
    cmp byte [si + EN_TYPE], 1
    jne .draw_koopa

    ; Goomba animation
    cmp al, 3
    jne .g_walk
    mov ax, spr_goomba_flat
    jmp .do_draw
.g_walk:
    mov ax, spr_goomba_w1
    test byte [si + EN_ANIM], 8
    jz .do_draw
    mov ax, spr_goomba_w2
    jmp .do_draw

    ; Koopa animation: w1 -> mouth_open -> w2 -> mouth_open
.draw_koopa:
    cmp al, 4
    jae .k_shell
    mov al, [si + EN_ANIM]
    shr al, 1
    shr al, 1
    shr al, 1
    and al, 3
    cmp al, 0
    je .k_f1
    cmp al, 2
    je .k_f2
    mov ax, spr_koopa_mo
    jmp .k_flip
.k_f1:
    mov ax, spr_koopa_w1
    jmp .k_flip
.k_f2:
    mov ax, spr_koopa_w2
.k_flip:
    mov dl, [si + EN_DIR]
    jmp .do_draw
.k_shell:
    mov ax, spr_koopa_shell

.do_draw:
    push bx
    push word [si + EN_Y]
    push ax
    push 16
    push 16
    push dx
    call draw_sprite

.next:
    add si, ENEMY_SIZE
    dec cx
    jz .done
    jmp .loop

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

