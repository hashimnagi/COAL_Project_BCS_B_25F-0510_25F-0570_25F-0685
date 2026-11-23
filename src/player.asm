; mario player physics & animation


; player physics, input handling, and collision
update_mario:
    push bp
    mov bp, sp
    sub sp, 4                   ; -2:height, -4:max_speed
    push ax
    push bx
    push cx
    push dx

    ; Height and previous feet Y for stomp detection
    mov ax, 16
    cmp byte [mario_form], 0
    je .h_set
    mov ax, 32
.h_set:
    mov [bp-2], ax
    mov bx, [mario_y]
    add bx, ax
    dec bx
    mov [mario_prev_bot], bx

    ; Max speed: walk (1.5) or run with Shift (2.5)

    mov word [bp-4], MAX_WALK_SPD
    cmp byte [key_table + KEY_LSHIFT], 1
    je .set_run

    cmp byte [key_table + KEY_RSHIFT], 1
    jne .spd_ok

.set_run:
    mov word [bp-4], MAX_RUN_SPD
.spd_ok:

    ; horizontal input, acceleration, braking & friction
    mov al, [key_table + KEY_LEFT]
    mov ah, [key_table + KEY_RIGHT]
    cmp al, ah
    jne .has_dir
    jmp .apply_friction
.has_dir:
    cmp ah, 1
    jne .do_left
    jmp .move_right

.do_left:
    mov byte [mario_facing], 1
    mov ax, [mario_vx]
    cmp ax, 0
    jle .accel_left
    sub ax, BRAKE_DECEL
    jge .store_vx_l
    xor ax, ax
    jmp .store_vx_l
.accel_left:
    sub ax, WALK_ACCEL
    mov bx, [bp-4]
    neg bx
    cmp ax, bx
    jge .store_vx_l
    mov ax, bx
.store_vx_l:
    mov [mario_vx], ax
    jmp .horiz_move

.move_right:
    mov byte [mario_facing], 0
    mov ax, [mario_vx]
    cmp ax, 0
    jge .accel_right
    add ax, BRAKE_DECEL
    jle .store_vx_r
    xor ax, ax
    jmp .store_vx_r
.accel_right:
    add ax, WALK_ACCEL
    cmp ax, [bp-4]
    jle .store_vx_r
    mov ax, [bp-4]
.store_vx_r:
    mov [mario_vx], ax
    jmp .horiz_move

.apply_friction:
    mov ax, [mario_vx]
    cmp ax, 0
    je .horiz_move
    jg .fric_pos
    add ax, FRICTION
    jle .fric_done
    xor ax, ax
    jmp .fric_done
.fric_pos:
    sub ax, FRICTION
    jge .fric_done
    xor ax, ax
.fric_done:
    mov [mario_vx], ax

    ; move horizontally (8.8 fixed point)
.horiz_move:
    mov ax, [mario_vx]
    add [mario_x_frac], al
    mov al, ah
    cbw
    adc [mario_x], ax

    ; Clamp to camera left edge and level right edge
    mov ax, [camera_x]
    cmp [mario_x], ax
    jge .check_rmap
    mov [mario_x], ax
    mov byte [mario_x_frac], 0
    mov word [mario_vx], 0

.check_rmap:
    mov ax, MAP_WIDTH - 16
    cmp [mario_x], ax
    jle .check_wall
    mov [mario_x], ax
    mov byte [mario_x_frac], 0
    mov word [mario_vx], 0

    ; horizontal tile collision
.check_wall:
    mov ax, [mario_vx]
    cmp ax, 0
    jne .do_wall
    jmp .vert_logic
.do_wall:
    jg .wall_right
    mov bx, [mario_x]
    add bx, 2
    jmp .wall_test
.wall_right:
    mov bx, [mario_x]
    add bx, 13

.wall_test:
    mov dx, [mario_y]
    add dx, 2
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .wall_hit

    mov dx, [mario_y]
    add dx, [bp-2]
    sub dx, 2
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .wall_hit

    cmp byte [mario_form], 0
    jne .wall_mid
    jmp .vert_logic
.wall_mid:
    mov dx, [mario_y]
    add dx, 16
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .wall_hit
    jmp .vert_logic

.wall_hit:
    and bx, 0FFF0h
    cmp word [mario_vx], 0
    jg .snap_right
    add bx, 14
    mov [mario_x], bx
    jmp .zero_vx
.snap_right:
    sub bx, 14
    mov [mario_x], bx
.zero_vx:
    mov byte [mario_x_frac], 0
    mov word [mario_vx], 0

    ; vertical physics: jump, variable jump cut-off, gravity
.vert_logic:
    mov al, [key_table + KEY_SPACE]
    cmp al, 1
    jne .space_up
    cmp byte [prev_space], 0
    jne .after_jump
    cmp byte [mario_on_ground], 1
    jne .after_jump

    ; start jump  ground
    mov word [mario_vy], JUMP_VEL
    mov byte [mario_on_ground], 0
    push 2400
    push 4
    call play_sound
    jmp .after_jump

.space_up:
    mov ax, [mario_vy]
    cmp ax, JUMP_CUTOFF
    jge .after_jump
    mov word [mario_vy], JUMP_CUTOFF

.after_jump:
    mov al, [key_table + KEY_SPACE]
    mov [prev_space], al

    mov ax, [mario_vy]
    add ax, GRAVITY
    cmp ax, MAX_FALL_SPD
    jle .vy_ok
    mov ax, MAX_FALL_SPD
.vy_ok:
    mov [mario_vy], ax

    add [mario_y_frac], al
    mov al, ah
    cbw
    adc [mario_y], ax

    ; Do not enter HUD row
    cmp word [mario_y], 16
    jge .vert_col
    mov word [mario_y], 16
    mov byte [mario_y_frac], 0
    cmp word [mario_vy], 0
    jge .vert_col
    mov word [mario_vy], 0

    ; vertical tile collision
.vert_col:
    cmp byte [mario_on_ground], 1
    jne .vc_dir
    mov byte [mario_on_ground], 2
.vc_dir:
    cmp word [mario_vy], 0
    jge .feet_chk
    jmp .head_check

.feet_chk:
    ; Test pixel right below feet (mario_y + height)
    mov dx, [mario_y]
    add dx, [bp-2]

    mov bx, [mario_x]
    add bx, 3
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .landed

    mov bx, [mario_x]
    add bx, 12
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .landed
    jmp .after_vcol

.landed:
    and dx, 0FFF0h
    sub dx, [bp-2]
    mov [mario_y], dx
    mov byte [mario_y_frac], 0
    mov word [mario_vy], 0
    mov byte [mario_on_ground], 1
    mov byte [mario_stomp_chain], 0
    jmp .after_vcol

.head_check:
    mov dx, [mario_y]
    mov bx, [mario_x]
    add bx, 3
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .head_hit

    mov bx, [mario_x]
    add bx, 12
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .head_hit
    jmp .after_vcol

.head_hit:
    ; Used tile under horizontal center of Mario's head 
    mov ax, [mario_x]
    add ax, 8
    push ax
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .trig_center
    mov ax, bx
    jmp .do_trig
.trig_center:
    mov ax, [mario_x]
    add ax, 8
.do_trig:
    mov cl, 4
    shr ax, cl
    mov bx, dx
    shr bx, cl
    push ax
    push bx
    call trigger_block

    and dx, 0FFF0h
    add dx, 16
    mov [mario_y], dx
    mov byte [mario_y_frac], 0
    mov word [mario_vy], 0

    ; running animation counter (run1 -> run2 -> run3)
.after_vcol:
    cmp byte [mario_on_ground], 1
    jne .check_coins
    mov ax, [mario_vx]
    cmp ax, 0
    je .reset_anim

    cmp ax, 0
    jge .abs_vx
    neg ax
.abs_vx:
    mov bl, 5
    cmp ax, 01C0h
    jb .anim_step
    mov bl, 3
.anim_step:
    inc byte [mario_anim_cnt]
    cmp byte [mario_anim_cnt], bl
    jb .check_coins
    mov byte [mario_anim_cnt], 0
    inc byte [mario_anim_frm]
    cmp byte [mario_anim_frm], 3
    jb .check_coins
    mov byte [mario_anim_frm], 0
    jmp .check_coins

.reset_anim:
    mov byte [mario_anim_cnt], 0
    mov byte [mario_anim_frm], 0

.check_coins:
    call collect_map_coins

    ; Pit check (y >= 192)
    cmp word [mario_y], 192
    jl .check_flag
    push 1
    call start_death
    jmp .done

.check_flag:
    mov bx, [mario_x]
    add bx, 8
    mov dx, [mario_y]
    add dx, [bp-2]
    dec dx

    push bx
    push dx
    call get_tile
    cmp al, TILE_FLAGPOLE
    je .hit_flag
    cmp al, TILE_FLAGTOP
    je .hit_flag

    push bx
    push word [mario_y]
    call get_tile
    cmp al, TILE_FLAGPOLE
    je .hit_flag
    cmp al, TILE_FLAGTOP
    je .hit_flag
    jmp .done

.hit_flag:
    mov cl, 4
    shr dx, cl
    push dx
    call start_win_seq

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret

; update mushroom movement and collision
update_mushroom:
    push ax
    push bx
    push cx
    push dx

    cmp byte [mush_active], 0
    jne .is_active
    jmp .done
.is_active:

    mov ax, [mush_vx]
    add [mush_x_frac], al
    mov al, ah
    cbw
    adc [mush_x], ax

    mov bx, [mush_x]
    cmp word [mush_vx], 0
    jle .m_left
    add bx, 15
.m_left:
    mov dx, [mush_y]
    add dx, 8
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    jne .m_grav
    neg word [mush_vx]

.m_grav:
    mov ax, [mush_vy]
    add ax, GRAVITY
    cmp ax, MAX_FALL_SPD
    jle .m_vy_ok
    mov ax, MAX_FALL_SPD
.m_vy_ok:
    mov [mush_vy], ax
    add [mush_y_frac], al
    mov al, ah
    cbw
    adc [mush_y], ax

    mov dx, [mush_y]
    add dx, 16
    mov bx, [mush_x]
    add bx, 3
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    je .m_land

    mov bx, [mush_x]
    add bx, 12
    push bx
    push dx
    call get_tile
    push ax
    call is_tile_solid
    cmp al, 1
    jne .m_despawn

.m_land:
    and dx, 0FFF0h
    sub dx, 16
    mov [mush_y], dx
    mov byte [mush_y_frac], 0
    mov word [mush_vy], 0

.m_despawn:
    cmp word [mush_y], 192
    jge .kill_mush
    mov ax, [mush_x]
    add ax, 32
    cmp ax, [camera_x]
    jge .m_pickup
.kill_mush:
    mov byte [mush_active], 0
    jmp .done

.m_pickup:
    mov ax, 16
    cmp byte [mario_form], 0
    je .mh_ok
    mov ax, 32
.mh_ok:
    mov bx, [mario_x]
    add bx, 2
    push bx
    push word [mario_y]
    push 12
    push ax
    push word [mush_x]
    push word [mush_y]
    push 16
    push 16
    call check_rect_overlap
    cmp al, 1
    je .do_collect
    jmp .done

.do_collect:
    mov byte [mush_active], 0
    push 1000
    call add_score
    push word [mush_x]
    push word [mush_y]
    push str_pop_1000
    call spawn_popup
    push 1300
    push 8
    call play_sound

    cmp byte [mario_form], 0
    jne .done
    mov byte [mario_form], 1
    mov byte [mario_hp], 2
    sub word [mario_y], 16      ; keep feet fixed

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; draw mushroom
draw_mushroom:
    push ax
    cmp byte [mush_active], 0
    je .done
    mov ax, [mush_x]
    sub ax, [camera_x]
    cmp ax, -16
    jle .done
    cmp ax, SCREEN_W
    jge .done
    push ax
    push word [mush_y]
    push spr_mushroom
    push 16
    push 16
    push 0
    call draw_sprite
.done:
    pop ax
    ret

; render mario sprite
draw_mario:
    push ax
    push bx
    push cx

    cmp byte [win_mario_hidden], 1
    jne .chk_blink
    jmp .done
.chk_blink:
    cmp byte [mario_invuln], 0
    je .choose_pose
    cmp byte [frame_parity], 1
    jne .choose_pose
    jmp .done

.choose_pose:
    ; 0=static, 1..3=run1..3, 4=jump, 5=stop
    xor bx, bx
    cmp byte [game_state], STATE_DYING
    je .pose_jump
    cmp byte [mario_on_ground], 0
    je .pose_jump

    mov ax, [mario_vx]
    cmp ax, 0
    je .pose_ready

    cmp ax, 0
    jl .moving_left
    cmp byte [key_table + KEY_LEFT], 1
    je .pose_stop
    jmp .pose_run
.moving_left:
    cmp byte [key_table + KEY_RIGHT], 1
    je .pose_stop

.pose_run:
    mov bl, [mario_anim_frm]
    inc bl
    jmp .pose_ready
.pose_jump:
    mov bl, 4
    jmp .pose_ready
.pose_stop:
    mov bl, 5

.pose_ready:
    shl bx, 1
    cmp byte [mario_form], 0
    je .small_spr
    mov ax, [mario_b_table + bx]
    mov cx, 32
    jmp .do_draw
.small_spr:
    mov ax, [mario_s_table + bx]
    mov cx, 16

.do_draw:
    mov bx, [mario_x]
    sub bx, [camera_x]
    push bx
    push word [mario_y]
    push ax
    push 16
    push cx
    mov al, [mario_facing]
    xor ah, ah
    push ax
    call draw_sprite

.done:
    pop cx
    pop bx
    pop ax
    ret

