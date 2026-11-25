; hud, scoring & particle system


; --- hud, scoring, and particles ---

; add score points (clamps at 999999)
add_score:
    push bp
    mov bp, sp
    push ax

    mov ax, [bp+4]
    add [score_lo], ax
    adc word [score_hi], 0

    ; Clamp to 999,999 (000F423Fh)
    cmp word [score_hi], 000Fh
    jb .done
    ja .clamp
    cmp word [score_lo], 423Fh
    jbe .done

.clamp:
    mov word [score_hi], 000Fh
    mov word [score_lo], 423Fh

.done:
    pop ax
    pop bp
    ret 2

; add coin count, gives 1up at 100
add_coin:
    push ax
    inc byte [coins]
    cmp byte [coins], 100
    jb .done
    mov byte [coins], 0
    cmp byte [lives], 99
    jae .done
    inc byte [lives]
    push word [mario_x]
    mov ax, [mario_y]
    sub ax, 10
    push ax
    push str_pop_1up
    call spawn_popup
    push 900
    push 8
    call play_sound
.done:
    pop ax
    ret

; spawn floating score popup
spawn_popup:
    push bp
    mov bp, sp
    push ax
    push cx
    push si

    mov si, popups
    mov cx, MAX_POPUPS
.find:
    cmp byte [si + POP_ACTIVE], 0
    je .use_slot
    add si, POPUP_SIZE
    loop .find
    mov si, popups

.use_slot:
    mov byte [si + POP_ACTIVE], 1
    mov byte [si + POP_TIMER], 24
    mov ax, [bp+8]
    mov [si + POP_X], ax
    mov ax, [bp+6]
    mov [si + POP_Y], ax
    mov ax, [bp+4]
    mov [si + POP_STR], ax

    pop si
    pop cx
    pop ax
    pop bp
    ret 6

; update floating popups
update_popups:
    push cx
    push si
    mov si, popups
    mov cx, MAX_POPUPS
.loop:
    cmp byte [si + POP_ACTIVE], 0
    je .next
    dec word [si + POP_Y]
    dec byte [si + POP_TIMER]
    jnz .next
    mov byte [si + POP_ACTIVE], 0
.next:
    add si, POPUP_SIZE
    loop .loop
    pop si
    pop cx
    ret

; draw active popups
draw_popups:
    push ax
    push cx
    push si
    mov si, popups
    mov cx, MAX_POPUPS
.loop:
    cmp byte [si + POP_ACTIVE], 0
    je .next
    mov ax, [si + POP_X]
    sub ax, [camera_x]
    cmp ax, 0
    jl .next
    cmp ax, SCREEN_W - 32
    jge .next
    push ax
    push word [si + POP_Y]
    push word [si + POP_STR]
    push COL_WHITE
    call draw_string
.next:
    add si, POPUP_SIZE
    loop .loop
    pop si
    pop cx
    pop ax
    ret

; spawn particle (1=coin, 2=brick chunk)
spawn_particle:
    push bp
    mov bp, sp
    push ax
    push cx
    push si

    mov si, particles
    mov cx, MAX_PARTS
.find:
    cmp byte [si + PT_TYPE], 0
    je .use
    add si, PART_SIZE
    loop .find
    mov si, particles
.use:
    mov al, [bp+12]
    mov [si + PT_TYPE], al
    mov byte [si + PT_TIMER], 18
    mov ax, [bp+10]
    mov [si + PT_X], ax
    mov ax, [bp+8]
    mov [si + PT_Y], ax
    mov ax, [bp+6]
    mov [si + PT_VX], ax
    mov ax, [bp+4]
    mov [si + PT_VY], ax

    pop si
    pop cx
    pop ax
    pop bp
    ret 10

; update particle positions and gravity
update_particles:
    push ax
    push cx
    push si
    mov si, particles
    mov cx, MAX_PARTS
.loop:
    cmp byte [si + PT_TYPE], 0
    je .next
    mov ax, [si + PT_VX]
    add [si + PT_X], ax
    mov ax, [si + PT_VY]
    add [si + PT_Y], ax
    inc word [si + PT_VY]
    dec byte [si + PT_TIMER]
    jnz .next
    mov byte [si + PT_TYPE], 0
.next:
    add si, PART_SIZE
    loop .loop
    pop si
    pop cx
    pop ax
    ret

; draw active particles
draw_particles:
    push ax
    push cx
    push si
    mov si, particles
    mov cx, MAX_PARTS
.loop:
    mov al, [si + PT_TYPE]
    cmp al, 0
    je .next
    mov ax, [si + PT_X]
    sub ax, [camera_x]
    cmp ax, -16
    jl .next
    cmp ax, SCREEN_W
    jge .next
    cmp byte [si + PT_TYPE], 1
    jne .brick_bit
    push ax
    push word [si + PT_Y]
    push tile_coin
    push 16
    push 16
    push 0
    call draw_sprite
    jmp .next
.brick_bit:
    push ax
    push word [si + PT_Y]
    push 4
    push 4
    push 17
    call fill_rect
.next:
    add si, PART_SIZE
    dec cx
    jnz .loop
    pop si
    pop cx
    pop ax
    ret

; draw top hud and bottom border
draw_hud:
    push ax

    push 0
    push 0
    push SCREEN_W
    push 16
    push COL_BLACK
    call fill_rect

    push 0
    push 192
    push SCREEN_W
    push 8
    push COL_BLACK
    call fill_rect

    push 4
    push 0
    push str_hud_score
    push COL_HUD_YEL
    call draw_string

    push 4
    push 8
    push word [score_lo]
    push word [score_hi]
    push 6
    push COL_WHITE
    call draw_number

    push 64
    push 0
    push str_hud_coins
    push COL_HUD_YEL
    call draw_string

    push 64
    push 8
    push 'X'
    push COL_WHITE
    call draw_char

    mov al, [coins]
    xor ah, ah
    push 72
    push 8
    push ax
    push 0
    push 2
    push COL_WHITE
    call draw_number

    ; WORLD 1-1
    push 116
    push 0
    push str_hud_world
    push COL_HUD_YEL
    call draw_string

    push 124
    push 8
    push str_hud_11
    push COL_WHITE
    call draw_string

    push 168
    push 0
    push str_hud_time
    push COL_HUD_YEL
    call draw_string

    mov ax, COL_WHITE
    cmp word [time_left], 100
    jae .time_col_ok
    cmp byte [frame_parity], 0
    je .time_col_ok
    mov ax, COL_RED
.time_col_ok:
    push 172
    push 8
    push word [time_left]
    push 0
    push 3
    push ax
    call draw_number

    push 212
    push 0
    push str_hud_lives
    push COL_HUD_YEL
    call draw_string

    push 216
    push 8
    push 'X'
    push COL_WHITE
    call draw_char

    mov al, [lives]
    xor ah, ah
    push 224
    push 8
    push ax
    push 0
    push 2
    push COL_WHITE
    call draw_number

    push 264
    push 0
    push str_hud_hp
    push COL_HUD_YEL
    call draw_string

    mov ax, COL_HEART_EMPTY
    cmp byte [mario_hp], 1
    jb .h1_draw
    mov ax, COL_HEART
.h1_draw:
    push 272
    push 8
    push ax
    call draw_heart

    mov ax, COL_HEART_EMPTY
    cmp byte [mario_hp], 2
    jb .h2_draw
    mov ax, COL_HEART
.h2_draw:
    push 284
    push 8
    push ax
    call draw_heart

    pop ax
    ret

