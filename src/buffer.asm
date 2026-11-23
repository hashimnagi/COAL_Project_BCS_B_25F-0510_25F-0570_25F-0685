; double buffering & frame buffer memory


; allocated 64000 byte offscreen frame buffer
alloc_frame_buffer:
    push ax
    push bx
    push es

    mov ax, cs
    mov es, ax
    mov ah, 4Ah
    mov bx, 1000h               ; 64 KB = 4096 paragraphs
    int 21h
    jc .fail

    mov ah, 48h
    mov bx, 0FA0h               ; 64,000 bytes = 4000 paragraphs
    int 21h
    jc .fail

    mov [fb_seg], ax
    clc
    jmp .done

.fail:
    stc
.done:
    pop es
    pop bx
    pop ax
    ret

; free frame buffer segment
free_frame_buffer:
    push ax
    push es
    mov ax, [fb_seg]
    cmp ax, 0
    je .done
    mov es, ax
    mov ah, 49h
    int 21h
    mov word [fb_seg], 0
.done:
    pop es
    pop ax
    ret

; fill entire buffer with color
clear_buffer:
    push bp
    mov bp, sp
    push ax
    push cx
    push di
    push es

    mov es, [fb_seg]
    xor di, di
    mov al, [bp+4]
    mov ah, al
    mov cx, 32000
    cld
    rep stosw

    pop es
    pop di
    pop cx
    pop ax
    pop bp
    ret 2

; clear gameplay area with sky color
clear_sky:
    push ax
    push cx
    push di
    push es

    mov es, [fb_seg]
    mov di, 16 * SCREEN_W
    mov al, COL_SKY
    mov ah, al
    mov cx, 176 * (SCREEN_W / 2)
    cld
    rep stosw

    pop es
    pop di
    pop cx
    pop ax
    ret

; copy buffer to vga segment 0a000h
flip_buffer:
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, 0A000h
    mov es, ax
    mov ds, [fb_seg]
    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

