%include "video.mac"
; Frame buffer location

section .data

global SNAKE_SIZE
global SNAKE_SIZE2
global MAP_HEIGHT
global MAP_WIDTH
global EIGHTY
global TWO
global SNAKE_TIME
global FRUIT_TIME

SNAKE_SIZE dw 4
SNAKE_SIZE2 dw 4
EIGHTY dw 80
TWO dw 2
MAP_HEIGHT db 25
MAP_WIDTH db 40
SNAKE_TIME dd 800
FRUIT_TIME dd 6000


section .bss
global MAP
global FRUIT
global FREE_SPACES
global NUM_FREE_SPACES
global SNAKE
global SNAKE_HEAD
global SNAKE_TAIL
global LAST_POS
global SNAKE2
global SNAKE_HEAD2
global SNAKE_TAIL2
global LAST_POS2
global DIFFICULTY
global TIMER
global TIMER2
global FRUIT_POSITION
global FRUIT_TIMER


MAP resw COLS*ROWS*2
FREE_SPACES resw COLS*ROWS*2
NUM_FREE_SPACES resd 1
SNAKE resw COLS*ROWS*2
SNAKE_AUX resw COLS*ROWS*2
SNAKE_HEAD resw 1
SNAKE_TAIL resw 1
LAST_POS resw 1
SNAKE2 resw COLS*ROWS*2
SNAKE_AUX2 resw COLS*ROWS*2
SNAKE_HEAD2 resw 1
SNAKE_TAIL2 resw 1
LAST_POS2 resw 1
DIFFICULTY resw 1
TIMER resq 1
TIMER2 resq 1
FRUIT_POSITION resw 1
FRUIT_TIMER resq 1 ;storesw the timer fot the fruit to be reset


section .text 

extern rtcs

; clear(byte char, byte attrs)
; Clear the screen by filling it with char and attributes.
global clear
clear:
  mov ax, [esp + 4] ; char, attrs
  mov edi, FBUFFER
  mov ecx, COLS * ROWS
  cld
  rep stosw
  ret

;params(word char&format, word position), do not affect registers
global print_pixel
print_pixel:
  prologue
  mov ax, [ebp + 8]
  xor ebx, ebx
  mov bx, [ebp + 10]
  mov [FBUFFER + ebx], ax
  epilogue
  ret

;params(word posF, word posC), initialize snake values, size 4, do not affect registers
global init_snake
init_snake:
  ;initiaizing snake
  prologue
  mov [SNAKE_SIZE], word 4
  mov bx, [ebp+8]
  mov cx, [ebp+10]
  GET_POS bx, cx
  mov [SNAKE], ax
  mov [SNAKE_TAIL], ax ;setting tail
  sub ax, 160
  mov [SNAKE+2], ax
  sub ax, 160
  mov [SNAKE+4], ax
  mov [LAST_POS], ax
  sub ax, 160
  mov [SNAKE+6], ax
  mov [SNAKE_HEAD], ax ;setting head
  epilogue
  ret
;params(word posF, word posC), initialize snake values, size 4, do not affect registers
global init_snake2
init_snake2:
  ;initiaizing snake
  prologue
  mov [SNAKE_SIZE2], word 4
  mov bx, [ebp+8]
  mov cx, [ebp+10]
  GET_POS bx, cx
  mov [SNAKE2], ax
  mov [SNAKE_TAIL2], ax ;setting tail
  add ax, 160
  mov [SNAKE2+2], ax
  add ax, 160
  mov [SNAKE2+4], ax
  mov [LAST_POS2], ax
  add ax, 160
  mov [SNAKE2+6], ax
  mov [SNAKE_HEAD2], ax ;setting head
  epilogue
  ret

;no params, draw the snake, do not affect registers
global paint_snake
paint_snake:
  prologue
  mov cx, [SNAKE_SIZE]
  xor edx, edx
  ciclo:
    ;this is to prevent painting green the HEAD or TAIL before it got painted
    ;if it is HEAD/TAIL jump to the next loop
    mov ax, [SNAKE+edx]
    cmp ax, [SNAKE_HEAD]
    je jump
    cmp ax, [SNAKE_TAIL]
    je jump
    push word[SNAKE + edx] ;pixel adress
    push word 'o'|FG.GREEN|BG.BLACK ;snake color
    call print_pixel
    add esp, 4
    jump:
    add edx, 2
    loop ciclo
  ;painting HEAD
  push word[SNAKE_HEAD] ;head adress
  push word 1|FG.YELLOW|BG.BLACK ;head color
  call print_pixel
  add esp, 4
  push word[SNAKE_TAIL] ;tail adress
  push word 'o'|FG.CYAN|BG.BLACK ;tail color
  call print_pixel
  add esp, 4
  epilogue
  ret
;no params, draw the snake, do not affect registers
global paint_snake2
paint_snake2:
  prologue
  mov cx, [SNAKE_SIZE2]
  xor edx, edx
  ciclo2:
    ;this is to prevent painting green the HEAD or TAIL before it got painted
    ;if it is HEAD/TAIL jump to the next loop
    mov ax, [SNAKE2+edx]
    cmp ax, [SNAKE_HEAD2]
    je jump2
    cmp ax, [SNAKE_TAIL2]
    je jump2
    push word[SNAKE2 + edx] ;pixel adress
    push word 'o'|FG.BLUE|BG.BLACK ;snake color
    call print_pixel
    add esp, 4
    jump2:
    add edx, 2
    loop ciclo2
  ;painting HEAD
  push word[SNAKE_HEAD2] ;head adress
  push word 1|FG.YELLOW|BG.BLACK ;head color
  call print_pixel
  add esp, 4
  push word[SNAKE_TAIL2] ;tail adress
  push word 'o'|FG.CYAN|BG.BLACK ;tail color
  call print_pixel
  add esp, 4
  epilogue
  ret

;params(word width, word height), do not affect registers
global paint_map_borders
paint_map_borders:
  prologue
  mov cx, [ebp+10] ;# of loops
  ciclo21:
    cmp cx, 0
    je end_ciclo ;break condition
    mov bx, 1 ;bx is the column iterator
    cmp cx, [ebp+10] ;is it top line?
    je ext
    cmp cx, 1  ;is it bottom line?
    je ext
    
    ;if it is not top/bottom line
    ;print 1st pixel if the line
    GET_POS cx, 1
    push ax
    push word BG.GRAY
    call print_pixel
    add esp, 4
    ;print 2nd pixel of the line
    GET_POS cx, [ebp+8]
    push ax
    push word BG.GRAY
    call print_pixel
    add esp, 4
    ;jump to next line
    dec cx 
    jmp ciclo21 
    
    ;if it is top/bottom
    ext:      
      cmp bx, [ebp+8] ;break condition
      jg end_ext
      ;print pixel at position (cx,bx)
      GET_POS cx, bx 
      push ax
      push word BG.GRAY
      call print_pixel
      add esp, 4
      ;jump to next column
      inc bx
      jmp ext
    end_ext: ;end of the top/bottom line
    ;jump to next line
    dec cx    
    jmp ciclo21
  ;loop end  
  end_ciclo:
  epilogue
  ret
 
;params (word dirF&dirC), re-locate the SNAKE, do not affect registers
global mov_snake
mov_snake:
  prologue
  mov ax, [ebp+8]
  cmp ax, 0
  je end_mov  
  ;asks first if param=0 in which case the snake do not move
  
  mov ax, [SNAKE_HEAD]
  mov [LAST_POS], ax ;setting last position

  ;refreshes the previous TAIL position by painting it black
  push word[SNAKE_TAIL]
  push word BG.BLACK
  call print_pixel
  add esp, 4
  ;storing head position
  push word[ebp+8]
  call mov_snake_head 
  add esp, 2
  ;this code stores in cx the offset of the TAIL from the begining of the SNAKE, bx stores the length
  mov ecx, 0
  mov bx, 0
  ciclo3:
    mov dx, [SNAKE_TAIL]
    cmp [SNAKE+ecx], dx
    je end_ciclo3
    add ecx, 2
    inc bx
    jmp ciclo3
    end_ciclo3:
  ;reasigns the HEAD position in the previous TAIL position
  mov [SNAKE+ecx], ax 
  mov [SNAKE_HEAD], ax 
  add ecx, 2
  inc bx
  cmp bx, [SNAKE_SIZE]
  je reset_ecx
  keep_doing:
  ;reasigns the TAIL position
  mov dx, [SNAKE+ecx]
  mov [SNAKE_TAIL],dx
  jmp end_mov
  reset_ecx:
    mov ecx, 0
    jmp keep_doing
  end_mov:
  epilogue
  ret
;params (word dirF&dirC), re-locate the SNAKE, do not affect registers
global mov_snake2
mov_snake2:
  prologue
  mov ax, [ebp+8]
  cmp ax, 0
  je end_mov2  
  ;asks first if param=0 in which case the snake do not move
  
  mov ax, [SNAKE_HEAD2]
  mov [LAST_POS2], ax ;setting last position

  ;refreshes the previous TAIL position by painting it black
  push word[SNAKE_TAIL2]
  push word BG.BLACK
  call print_pixel
  add esp, 4
  ;storing head position
  push word[ebp+8]
  call mov_snake_head2 
  add esp, 2
  ;this code stores in cx the offset of the TAIL from the begining of the SNAKE, bx stores the length
  mov ecx, 0
  mov bx, 0
  ciclo32:
    mov dx, [SNAKE_TAIL2]
    cmp [SNAKE2+ecx], dx
    je end_ciclo32
    add ecx, 2
    inc bx
    jmp ciclo32
    end_ciclo32:
  ;reasigns the HEAD position in the previous TAIL position
  mov [SNAKE2+ecx], ax 
  mov [SNAKE_HEAD2], ax 
  add ecx, 2
  inc bx
  cmp bx, [SNAKE_SIZE2]
  je reset_ecx2
  keep_doing2:
  ;reasigns the TAIL position
  mov dx, [SNAKE2+ecx]
  mov [SNAKE_TAIL2],dx
  jmp end_mov2
  reset_ecx2:
    mov ecx, 0
    jmp keep_doing2
  end_mov2:
  epilogue
  ret

;params(word dirF&dirC), sets in ax the new head position, destroys ax, bx and cx registers
global mov_snake_head
mov_snake_head:
  ;asks first if the parameter is 0, in which case the snake is not moving, so, returns a neutral value 0 
  cmp [esp+4], word 0
  jne real_method
  mov ax, 0
  jmp return

  real_method: 
  mov bx, [SNAKE_HEAD]
  GET_POS_INV bx
  mov bx, [esp+4]
  add al, bl
  add ah, bh
  ;this code determines whether the new position is correct
  cmp al, [MAP_HEIGHT]  
  jne noth1
  mov al, 2 ;reaches the end of the line, back to the begining
  jmp noth4
  noth1:
    cmp ah, [MAP_WIDTH]
    jne noth2
    mov ah, 2 ;reaches the end of the column, back to the begining
    jmp noth4
  noth2:
    cmp al, 1
    jne noth3
    mov al, [MAP_HEIGHT]
    dec al
  noth3:
    cmp ah, 1
    jne noth4
    mov ah, [MAP_WIDTH]
    dec ah
  noth4:
  ;this code converts the (i,j) position in a linear position and stores it in ax
  mov cl, ah ;save ah value
  cbw ;converts the al in to ax
  mov bx, ax ;save ax value
  mov al, cl
  cbw ;converts the ah value(stored now in al) to ax
  mov cx, ax ;save ax value
  GET_POS bx, cx
  return:
  ret
;params(word dirF&dirC), sets in ax the new head position, destroys ax, bx and cx registers
global mov_snake_head2
mov_snake_head2:
  ;asks first if the parameter is 0, in which case the snake is not moving, so, returns a neutral value 0 
  cmp [esp+4], word 0
  jne real_method2
  mov ax, 0
  jmp return2

  real_method2: 
  mov bx, [SNAKE_HEAD2]
  GET_POS_INV bx
  mov bx, [esp+4]
  add al, bl
  add ah, bh
  ;this code determines whether the new position is correct
  cmp al, [MAP_HEIGHT]  
  jne noth12
  mov al, 2 ;reaches the end of the line, back to the begining
  jmp noth42
  noth12:
    cmp ah, [MAP_WIDTH]
    jne noth22
    mov ah, 2 ;reaches the end of the column, back to the begining
    jmp noth42
  noth22:
    cmp al, 1
    jne noth32
    mov al, [MAP_HEIGHT]
    dec al
  noth32:
    cmp ah, 1
    jne noth42
    mov ah, [MAP_WIDTH]
    dec ah
  noth42:
  ;this code converts the (i,j) position in a linear position and stores it in ax
  mov cl, ah ;save ah value
  cbw ;converts the al in to ax
  mov bx, ax ;save ax value
  mov al, cl
  cbw ;converts the ah value(stored now in al) to ax
  mov cx, ax ;save ax value
  GET_POS bx, cx
  return2:
  ret

;no params, set at FREE_SPACES all the map free spaces in the moment called, do not affect registers 
global set_free_spaces
set_free_spaces:
  prologue
  mov dword[NUM_FREE_SPACES], 0 ;stores the number of free spaces
  mov ecx, 0 ;offset from FREE_SPACES
  xor bx, bx
  xor dx, dx
  mov bl, 2 ;iterator in i
  mov dl, 2 ;iterator in j
  ;previous values started in 2 because the position ofthe 1rst pixel of the map is at (2,2)
  for_i:
    cmp bl, [MAP_HEIGHT]
    je end_for_i 
    mov dl, 2 ;re-starts the iteration in j
    for_j:
      cmp dl, [MAP_WIDTH]
      je end_for_j ; till here checking for conditions
      xor eax, eax
      GET_POS bx, dx ;gets the linear position at (bx,dx)      
      cmp [FBUFFER+eax], word BG.BLACK ; asks if is black, which means is free
      jne not_free ;case not free
      mov [FREE_SPACES+ecx], ax ;stores at the proper postion at FREE_SPACES the position 
      ;of the current free space
      add ecx, 2
      inc dword[NUM_FREE_SPACES] ;increments the variable that stores the total amount of free spaces
      not_free:
        inc dl
        jmp for_j ;iteration in j
    end_for_j:
      inc bl
      jmp for_i ;iteration in i
  end_for_i:
  epilogue
  ret
  
;recieves in ax the new head position, returns in bx 1 if ate, 0 if not
global ate_fruit?
ate_fruit?:
  mov bx, 1
  cmp [FBUFFER+eax], word 15 | FG.RED | BG.BLACK ;fruit color 
  je true
  false:
   mov bx, 0
  true:
  ret

;no params, set a new random fruit in a map free space, do not affect registers
global set_new_fruit
set_new_fruit:
  prologue
  call set_free_spaces ;sets FREE_SPACES and NUM_FREE_SPACES given the current state
  push dword[NUM_FREE_SPACES] ;the number of free spaces is the rank where to be determined a random number 
  call get_random
  add esp, 4
  mov bx, word[FREE_SPACES+eax]
  mov [FRUIT_POSITION], bx ;storing fruit position for it could be deleted later
  push word[FREE_SPACES+eax]
  push word 15 | FG.RED | BG.BLACK ;fruit color
  call print_pixel ;put a fruit in the free position generated randomly
  add esp, 4
  epilogue
  ret

;no params; reset the fruit, including the timer; do no affect registers
global reset_fruit
reset_fruit:
  prologue
  xor eax, eax
  mov ax, [FRUIT_POSITION]
  mov [FBUFFER+eax], word BG.BLACK
  call set_new_fruit
  rdtsc
  mov [FRUIT_TIMER], eax
  mov [FRUIT_TIMER+4], edx
  epilogue
  ret
;params(word rank), stores in eax a random number in the rank(0, rank-1), affect edx register
global get_random
get_random:
  push ebp
  mov ebp, esp
  push edx
  push ebx
  push ecx
  rdtsc 
  div dword[ebp+8]
  mov eax, edx
  mov ecx, 2
  mul ecx
  pop ecx
  pop ebx
  pop edx
  pop ebp
  ret

;no params; moves automatically the snake to the appropriate new position; do no affect registers
global move_next_pos
move_next_pos:
  push bx
  push cx
  xor eax, eax ;clean garbage from subroutine "delay"
  mov cx, [LAST_POS]
  GET_POS_INV cx
  mov bx, ax ;stores in (bl, bh) the (i,j) position of the last position the snake were in
  mov cx, [SNAKE_HEAD]
  GET_POS_INV cx ;stores in (al, ah) the (i,j) position of the current snake position
  
  ;this next code does the appropriatte thing if the snake moved out the MAP
  cmp al, 2
  jne nothing1
  cmp bl, 24
  jne nothing1
  mov bl, 1
  jmp solved
  
  nothing1:
  cmp al, 24
  jne nothing2
  cmp bl, 2
  jne nothing2
  mov bl, 25
  jmp solved

  nothing2:
  cmp ah, 2
  jne nothing3
  cmp bh, 39
  jne nothing3
  mov bh, 1
  jmp solved

  nothing3:
  cmp ah, 39
  jne solved
  cmp bh, 2
  jne solved
  mov bh, 40
  jmp solved

  solved:
  sub al, bl ;stores in the al the new offset that has to be added to the current position to get new position
  sub ah, bh ;the same but in columns

  pop cx
  pop bx
  ret
;no params; moves automatically the snake to the appropriate new position; do no affect registers
global move_next_pos2
move_next_pos2:
  push bx
  push cx
  xor eax, eax ;clean garbage from subroutine "delay"
  mov cx, [LAST_POS2]
  GET_POS_INV cx
  mov bx, ax ;stores in (bl, bh) the (i,j) position of the last position the snake were in
  mov cx, [SNAKE_HEAD2]
  GET_POS_INV cx ;stores in (al, ah) the (i,j) position of the current snake position
  
  ;this next code does the appropriatte thing if the snake moved out the MAP
  cmp al, 2
  jne nothing12
  cmp bl, 24
  jne nothing12
  mov bl, 1
  jmp solved2
  
  nothing12:
  cmp al, 24
  jne nothing22
  cmp bl, 2
  jne nothing22
  mov bl, 25
  jmp solved2

  nothing22:
  cmp ah, 2
  jne nothing32
  cmp bh, 39
  jne nothing32
  mov bh, 1
  jmp solved2

  nothing32:
  cmp ah, 39
  jne solved2
  cmp bh, 2
  jne solved2
  mov bh, 40
  jmp solved2

  solved2:
  sub al, bl ;stores in the al the new offset that has to be added to the current position to get new position
  sub ah, bh ;the same but in columns

  pop cx
  pop bx
  ret
  
;params(word positionF, word positionC, dword height, dword width, dword FIGURA(label))
; renders an image do not affect registers
global render_image
render_image:
    prologue
    xor eax, eax
    GET_POS [ebp+8], [ebp+10] ;stores in ax the linear position of the image
    mov esi, 0 ;iterator in i
    mov edi, 0 ;iterator in j
    mov ebx, dword[ebp+20] ;stores the label 
    for_F:
       cmp esi, [ebp+12]
       je end_for_F 
       mov edi, 0 ;re-starts the iteration in j
       for_C:
         cmp edi, [ebp+16]
         je end_for_C ; till here checking for conditions
      
         ;calculates the direction in memory of the character to print and stores it in cx
         call store.char
         ;calculates the position of the character and prints it
         call print.char          
      
         inc edi
         jmp for_C
       end_for_C:
         inc esi
         jmp for_F ;iteration in i
    end_for_F:
	epilogue
	ret

;auxiliar functions to make above code clearer 
store.char:
    push eax
    push edx
    mov eax, [ebp+16]
    mul esi
    mov edx, 2
    mul edx
    add eax, edi
    add eax, edi
    add eax, ebx
    mov cx, [eax];eax=calculated direction in memory of the character to print     
    pop edx
    pop eax
    ret 
print.char:
	push eax
    push ebx
    push edx
    mov ebx, eax
    mov eax, esi
    mov edx, 160
    mul edx
    add eax, edi
    add eax, edi    
	add eax, ebx
    mov [FBUFFER+eax], cx ;eax=calculated position of the character to print
    pop edx
    pop ebx
    pop eax
 	ret

;params(word newHeadPosition); grows the snake; do not affect registers
global grow_snake
grow_snake:
	prologue
	;this code stores in cx the offset of the TAIL from the begining of the SNAKE, bx stores the length
	mov ecx, 0
	mov bx, 0  
	mov dx, [SNAKE_TAIL]
    ciclo_tail:
	   cmp [SNAKE+ecx], dx
	   je end_ciclo_tail
	   add ecx, 2
	   inc bx
	   jmp ciclo_tail
	   end_ciclo_tail:	  

	;this code stores in SNAKE_AUX the new snake after growing, with the tail at the begining, 
	;and the head at the end
	mov edi, 0
	ciclo_aux1:    
	   cmp bx, [SNAKE_SIZE]
	   je end_ciclo_aux1    
	   mov ax, [SNAKE+ecx]
	   mov [SNAKE_AUX+edi], ax 
	   add ecx, 2
	   add edi, 2
	   inc bx
	   jmp ciclo_aux1
	   end_ciclo_aux1:
	
	;push word BG.BLACK
	;call clear
	;add esp, 2

	sub edi, 2
	mov ecx, -2 ; these changes are done because of the next loop characteristics
	ciclo_aux2:
	   add ecx, 2
	   add edi, 2
	   mov ax, [SNAKE+ecx]
	   mov [SNAKE_AUX+edi], ax
	   mov bx, [SNAKE+ecx]
	   cmp bx, [SNAKE_HEAD] ;determining wether the loop has finished or noth
	   jne ciclo_aux2

	;from this point resetting the SNAKE_SIZE, the SNAKE_HEAD and TAIL
	;swaping the labels
	mov bx, 0
	mov ecx, 0
	swap_loop:
	   cmp bx, [SNAKE_SIZE]
	   je end_swap_loop
	   mov ax, [SNAKE_AUX+ecx]
	   mov [SNAKE+ecx], ax
	   inc bx
	   add ecx, 2
	   jmp swap_loop
	   end_swap_loop:

	inc word[SNAKE_SIZE]
	mov ax, [ebp+8] ;new head position
	mov [SNAKE+ecx], ax
	mov ax, [SNAKE] 
	mov [SNAKE_TAIL], ax ;setting new tail
	mov ax, [SNAKE+ecx]
	mov [SNAKE_HEAD], ax ;setting new head
	mov ax, [SNAKE+ecx-2]
	mov [LAST_POS], ax ;setting new last pos
	epilogue
	ret
;params(word newHeadPosition); grows the snake; do not affect registers
global grow_snake2
grow_snake2:
	prologue
	;this code stores in cx the offset of the TAIL from the begining of the SNAKE, bx stores the length
	mov ecx, 0
	mov bx, 0  
	mov dx, [SNAKE_TAIL2]
    ciclo_tail2:
	   cmp [SNAKE2+ecx], dx
	   je end_ciclo_tail2
	   add ecx, 2
	   inc bx
	   jmp ciclo_tail2
	   end_ciclo_tail2:	  

	;this code stores in SNAKE_AUX the new snake after growing, with the tail at the begining, 
	;and the head at the end
	mov edi, 0
	ciclo_aux12:    
	   cmp bx, [SNAKE_SIZE2]
	   je end_ciclo_aux12    
	   mov ax, [SNAKE2+ecx]
	   mov [SNAKE_AUX+edi], ax 
	   add ecx, 2
	   add edi, 2
	   inc bx
	   jmp ciclo_aux12
	   end_ciclo_aux12:
	
	;push word BG.BLACK
	;call clear
	;add esp, 2

	sub edi, 2
	mov ecx, -2 ; these changes are done because of the next loop characteristics
	ciclo_aux22:
	   add ecx, 2
	   add edi, 2
	   mov ax, [SNAKE2+ecx]
	   mov [SNAKE_AUX+edi], ax
	   mov bx, [SNAKE2+ecx]
	   cmp bx, [SNAKE_HEAD2] ;determining wether the loop has finished or noth
	   jne ciclo_aux22

	;from this point resetting the SNAKE_SIZE, the SNAKE_HEAD and TAIL
	;swaping the labels
	mov bx, 0
	mov ecx, 0
	swap_loop2:
	   cmp bx, [SNAKE_SIZE2]
	   je end_swap_loop2
	   mov ax, [SNAKE_AUX+ecx]
	   mov [SNAKE2+ecx], ax
	   inc bx
	   add ecx, 2
	   jmp swap_loop2
	   end_swap_loop2:

	inc word[SNAKE_SIZE2]
	mov ax, [ebp+8] ;new head position
	mov [SNAKE2+ecx], ax
	mov ax, [SNAKE2] 
	mov [SNAKE_TAIL2], ax ;setting new tail
	mov ax, [SNAKE2+ecx]
	mov [SNAKE_HEAD2], ax ;setting new head
	mov ax, [SNAKE2+ecx-2]
	mov [LAST_POS2], ax ;setting new last pos
	epilogue
	ret

;recieves in ax the new headPosition; check if the snake crashed at any obstacle; bx=0if not crashed
global check_crash
check_crash:
  mov bx, 1
  ;cmp [FBUFFER+eax],word '*'|BG.BLACK|FG.RED ;fruit format
  ;je clean
  cmp [FBUFFER+eax], word BG.BLACK ;empty place format
  je clean
  cmp [FBUFFER+eax], word BG.GRAY ;map border format, neutral zone
  ;(it is necessary cause at the first time, when youre not moving, 
  ;the subroutine mov_snake_head returns 0, where there is a map border)
  je clean
  jmp not_clear
  clean:
  mov bx, 0
  not_clear:  
  ret

