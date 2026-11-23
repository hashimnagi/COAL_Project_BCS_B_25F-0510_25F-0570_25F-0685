; video initialization & dac palette


; game engine routines: video, drawing, interrupts, physics, audio

; --- video and frame buffer routines ---

; init mode 13h (320x200) and load custom palette
init_video:
    push ax
    push cx
    push dx
    push si

    mov ax, 0013h
    int 10h

    ; Load colors 0..31 into VGA DAC
    mov dx, 03C8h
    xor al, al
    out dx, al
    inc dx
    mov si, palette_data
    mov cx, 32 * 3
.pal_loop:
    lodsb
    out dx, al
    loop .pal_loop

    pop si
    pop dx
    pop cx
    pop ax
    ret

; restore standard text mode (03h)
restore_video:
    push ax
    mov ax, 0003h
    int 10h
    pop ax
    ret

