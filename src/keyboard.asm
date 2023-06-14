%include "keyboard.mac"

section .data

; Previous scancode.
key db 0

section .text
; scan()
; Scan for new keypress. Returns new scancode if changed since last call, zero
; otherwise.
global scan
scan:
  ; Scan.
  in al, 0x60

  ; If scancode has changed, update key and return it.
  cmp al, [key]
  je .zero
  mov [key], al
  jmp .ret

  ; Otherwise, return zero.
  .zero:
    xor eax, eax

  .ret:
    ret

;params(word Key), determines the direction to move based on the last key pressed
; and stores it in ax (al posF, ah posC)
global convert_key
convert_key:
  mov ax, [esp+4]
  cmp ax, KEY.UP
  je up
  cmp ax, KEY.RIGHT
  je right
  cmp ax, KEY.DOWN
  je down
  cmp ax, KEY.LEFT
  je left
  xor eax, eax
  jmp end
  up:
    mov al, -1
    mov ah, 0
    jmp end
  right:
    mov al, 0
    mov ah, 1
    jmp end
  down:
    mov al, 1
    mov ah, 0
    jmp end
  left:
    mov al, 0
    mov ah, -1
end:
ret
;params(word Key), determines the direction to move based on the last key pressed
; and stores it in ax (al posF, ah posC)
global convert_key2
convert_key2:
  mov ax, [esp+4]
  cmp ax, KEY.W
  je up2
  cmp ax, KEY.D
  je right2
  cmp ax, KEY.S
  je down2
  cmp ax, KEY.A
  je left2
  xor eax, eax
  jmp end2
  up2:
    mov al, -1
    mov ah, 0
    jmp end2
  right2:
    mov al, 0
    mov ah, 1
    jmp end2
  down2:
    mov al, 1
    mov ah, 0
    jmp end2
  left2:
    mov al, 0
    mov ah, -1
end2:
ret
