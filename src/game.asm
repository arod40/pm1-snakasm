%include "video.mac"
%include "keyboard.mac"
%include "sound.mac"

section .data 
DIFF dd 1 ;stores difficulty
APPLES dw 0 ;stores apples ate by both players
SCORE dd 0 ;stores score by player1
SCORE12 dd 0 ;stores score by player2
INCREMENT dd 10 ;stores the value of an apple
LEVEL dd 0 ;stores the current map
FRUIT_COUNTER dd 0
SONG dd NOTE_A2, 500, NOTE_FS7 , 800,NOTE_DS3 , 1000

section .bss
manual?  resb 1 ;boolean to know if the snake has to move by itself or by arrows
two_P resb 1 ;stores if it is a two players game or not
MENU_POS resb 1 ;stores the row of the menu 0 = 1 PLAYER, 1 = 2 PLAYER, 2 = SETTINGS, 3 = EXIT
MAPS resd 10;array that stores the labels of the maps
FRUIT_TIMER2 resq 1

section .text

extern clear
extern scan
extern calibrate
extern print_pixel
extern paint_map_borders
extern init_snake
extern paint_snake
extern mov_snake
extern mov_snake_head
extern move_next_pos
extern grow_snake
extern init_snake2
extern paint_snake2
extern mov_snake2
extern mov_snake_head2
extern move_next_pos2
extern grow_snake2
extern convert_key
extern convert_key2
extern get_random
extern set_free_spaces
extern ate_fruit?
extern set_new_fruit
extern reset_fruit
extern render_image
extern check_crash
extern delay
extern setfreq
extern on
extern off
extern play_song
extern SNAKE_TIME
extern TIMER
extern LAST_POS
extern SNAKE_HEAD
extern TIMER2
extern LAST_POS2
extern SNAKE_HEAD2
extern FRUIT_POSITION
extern FRUIT_TIME
extern FRUIT_TIMER
extern SONG_TIMER
extern CURRENT_NOTE

;renders
extern LEVELONE0
extern LEVELTWO0
extern LINE0
extern MENU0
extern FLECHA
extern EMPTY
extern EMPTY2
extern BLOOD
extern BLOOD0
extern GAME
extern OVER
extern TABLA0
extern SCORE1
extern SCORE2
extern SCORE3
extern SCORE4
extern SCORE5
extern SCORE6
extern SCORE7
extern SCORE8
extern SCORE9
extern SCORE10
extern DIFF0
extern DIFFX
extern DIFF9
extern LVLUP0
extern BAG0
extern PLAYER0
extern WINS0
extern ONE0
extern TWO0
extern TIEDUP0
extern PAUSE0


; Bind a key to a procedure jumping
%macro bind 2
  cmp byte [esp], %1
  jne %%next
  jmp %2
  %%next:
%endmacro

; Bind a key to a procedure calling
%macro bind1 2
  cmp byte [esp], %1
  jne %%next
  call %2
  %%next:
%endmacro

; Fill the screen with the given background color
%macro FILL_SCREEN 1
  push word %1
  call clear
  add esp, 2
%endmacro

%macro RENDER 5.nolist
    push %1
    push dword %2
    push dword %3
    push word %4
    push word %5
    call render_image
    add esp, 16
%endmacro

%macro BEEP 1.nolist
  push eax
  push dword %1
  call setfreq
  add esp, 4
  call on
  
  rdtsc
  mov [TIMER], eax
  mov [TIMER+4], edx

  %%aki:
    push dword 100
    push TIMER
    call delay
    add esp, 8
    cmp eax, 0
    je %%aki

  call off
  pop eax
%endmacro

global game
game:
  ; Initialize game

  FILL_SCREEN BG.BLACK

  ; Calibrate the timings
  call calibrate
  ;jmp game_start
  ;jmp high_scores.loop
  ;jmp game_over.loop
  menu.loop:
    push dword[SONG]
    call setfreq
    add esp, 4 ;setting the initial note
    call on ;turn on the bocine
    mov word[CURRENT_NOTE], 0
    rdtsc
    mov [SONG_TIMER], eax
    mov [SONG_TIMER+4], edx

    FILL_SCREEN BG.BLACK
    mov [MENU_POS], byte 0
    RENDER LINE0, 52, 8, 15, 2
    RENDER MENU0, 10, 4, 25, 15
    RENDER FLECHA, 1, 1, 24, 15
    
    ;initializing maps
    mov dword[MAPS], LEVELONE0
    mov dword[MAPS+4], LEVELTWO0

    ;initializing scores
    mov dword[SCORE], 0
    mov dword[SCORE12], 0

    menu:
    push word 3
    push dword SONG
    call play_song
    add esp, 6

    call scan
    push ax
    bind KEY.ENTER, produce_action
    bind1 KEY.UP, cursor_up
    bind1 KEY.DOWN, cursor_down
    add esp, 2
    jmp menu

  game_over.loop:
    FILL_SCREEN BG.BLACK
    mov dword[LEVEL], 0
    BEEP NOTE_C1
    rdtsc
    mov [TIMER], eax
    mov [TIMER+4], edx
    mov cx, 1
    ciclo_blood:
    cmp cx, 26
    je end_blood0

    RENDER BLOOD, 40, 1, 1, cx
    inc cx
    RENDER BLOOD, 40, 7, 1, cx
    
    waiter:
    push dword 100
    push TIMER
    call delay
    add esp, 8
    cmp eax, 0
    je waiter
    jmp ciclo_blood    

    end_blood0:
    FILL_SCREEN BG.BLACK 
    
    end_blood:
    RENDER GAME, 35, 8, 2, 1
    RENDER OVER, 36, 8, 42, 1

    cmp byte[two_P], 1
    je sigueX    
    mov eax, [SCORE]
    cmp eax, [SCORE12]
    je tiedup
    RENDER PLAYER0, 38, 8, 2, 9
    mov eax, [SCORE]
    cmp eax, [SCORE12]
    ja player1
    cmp eax, [SCORE12]
    jb player2
    player1: 
    RENDER ONE0, 7, 8, 44, 9
    RENDER WINS0, 39, 8, 2, 18 
    jmp sigueX
    player2:    
    RENDER TWO0, 7, 8, 44, 9
    RENDER WINS0, 39, 8, 2, 18 
    jmp sigueX
    tiedup:
    RENDER TIEDUP0, 7, 1, 8, 16
    
    sigueX:    
    call scan
    push ax 
    cmp byte[two_P], 1
    je play1
    bind KEY.ENTER, menu.loop
    add esp, 2
    jmp end_blood
    play1
    bind KEY.ENTER, high_scores.loop
    add esp, 2
    jmp end_blood

    jmp game_over.loop

  high_scores.loop:
    FILL_SCREEN BG.BLACK  
    mov ecx, 0
    .wait:
    call scan
    push ax 
    bind KEY.ENTER, menu.loop
    add esp, 2
    cmp ecx, 0
    jne .wait ; for this just to be painted once, to avoid blinking

    RENDER TABLA0, 40, 23, 20, 2
    RENDER SCORE1, 35, 1, 24, 5
    RENDER SCORE2, 35, 1, 24, 7
    RENDER SCORE3, 35, 1, 24, 9
    RENDER SCORE4, 35, 1, 24, 11
    RENDER SCORE5, 35, 1, 24, 13
    RENDER SCORE6, 35, 1, 24, 15
    RENDER SCORE7, 35, 1, 24, 17
    RENDER SCORE8, 35, 1, 24, 19
    RENDER SCORE9, 35, 1, 24, 21
    RENDER SCORE10, 35, 1, 24, 23
    inc ecx   
    jmp .wait
    jmp high_scores.loop

  diff.loop:
    FILL_SCREEN BG.BLACK
    mov dword[DIFF], 1
    RENDER DIFF9, 33, 1, 5, 11
    here:
    call scan
    push ax
    bind1 KEY.UP, inc_diff
    bind1 KEY.DOWN, dec_diff
    bind KEY.ENTER, menu.loop
    add esp, 2
    jmp here

    inc_diff:
      cmp dword[DIFF], 10
      je end_inc
      BEEP NOTE_DS8
      RENDER DIFF0, 33, 10, 5, 2
      inc dword[DIFF]
      add dword[INCREMENT], 10
      mov eax, [DIFF]
      mov ecx, 0
      mov edx, 10
      sub edx, eax
      del:
      cmp ecx, edx 
      je end_inc
      add cx, 2
      RENDER DIFFX, 33, 1, 5, cx
      sub cx, 2
      inc cx
      jmp del
      end_inc:
      ret

    dec_diff:
      cmp dword[DIFF], 1
      je end_dec
      BEEP NOTE_DS8
      RENDER DIFF0, 33, 10, 5, 2
      dec dword[DIFF]
      sub dword[INCREMENT], 10
      mov eax, [DIFF]
      mov ecx, 0
      mov edx, 10
      sub edx, eax
      del1:
      cmp ecx, edx 
      je end_dec
      add cx, 2
      RENDER DIFFX, 33, 1, 5, cx
      sub cx, 2
      inc cx
      jmp del1
      end_dec:
      ret

  pause.loop:
    ;saving timer
    rdtsc
    push eax
    push edx

    RENDER PAUSE0, 5, 1,57, 16
    pause:
    call scan
    push ax
    bind KEY.ENTER, pause.end
    add esp, 2
    jmp pause
    pause.end:
    RENDER EMPTY2, 6, 1, 57, 16
    add esp, 2

    ;re-setting timers
    pop edx
    pop eax
    mov ebx, eax
    mov ecx, edx
    
    rdtsc
    sub eax, ebx
    sub edx, ecx
    
    add [FRUIT_TIMER2], eax
    adc [FRUIT_TIMER2+4],edx
    add [FRUIT_TIMER], eax
    adc [FRUIT_TIMER+4], edx
    add [TIMER2], eax
    adc [TIMER2+4], edx
    add [TIMER], eax
    adc [TIMER+4], edx
    jmp game.loop

  game_start:
    xor edx, edx
    mov eax, 800
    div dword[DIFF]
    mov dword[SNAKE_TIME], eax

    FILL_SCREEN BG.BLACK
    push word 25
    push word 40
    call paint_map_borders  
    add esp, 4

    ;setting map
    inc dword[LEVEL]
    mov eax, [LEVEL]
    dec eax
    mov eax, [MAPS+4*eax]
    RENDER eax, 38, 23, 2, 2
    ;setting fruit
    mov dword [FRUIT_COUNTER], 0
    mov dword[APPLES], 0
    call set_new_fruit 

    ;setting images
    mov word[FBUFFER+1048], 15|FG.RED|BG.BLACK
    RENDER LVLUP0, 9, 1, 45, 9
    RENDER BAG0, 21, 1, 54, 9
    ;1player
    push word 20
    push word 23
    call init_snake
    add esp, 4
    call paint_snake 
  
    ;setting timers
    rdtsc
    mov [TIMER], eax
    mov [TIMER+4], edx
    mov [FRUIT_TIMER], eax
    mov [FRUIT_TIMER+4], edx
    mov [FRUIT_TIMER2], eax
    mov [FRUIT_TIMER2+4], edx
    
    cmp byte[two_P], 1
    je game.loop
    
    ;2players
    push word 20
    push word 3
    call init_snake2
    add esp, 4
    call paint_snake2

    rdtsc
    mov [TIMER2], eax
    mov [TIMER2+4], edx 
  
  ; Snakasm main loop
  game.loop:
    .input:
      xor eax, eax 
      call scan
      push ax
      bind KEY.ENTER, pause.loop
      pop ax
      push ax
      ;1player
      call convert_key 
      cmp eax, 0
      jne reset_timer
      ;if not
      push dword[SNAKE_TIME]
      push TIMER
      call delay
      add esp, 8
      cmp eax, 0
      je real_input
        mov [manual?], byte 0
        call move_next_pos
        jmp  real_input_auto
      

      ;reset the timer cause you moved the snake
      reset_timer:
      push eax
      push edx
      rdtsc
      mov [TIMER], eax
      mov [TIMER+4], edx
      pop edx
      pop eax      

      real_input:  
      mov [manual?], byte 1
      real_input_auto:
      push ax
      call mov_snake_head
      add esp, 2
      call ate_fruit?
      cmp bx, 1
      jne no_fruit
      fruit:
       BEEP NOTE_FS7
       inc word[APPLES]
       xor ebx, ebx
       mov bx, [APPLES]
       mov word[FBUFFER+1386+4*ebx], 15| FG.RED | BG.BLACK
       mov ebx, [INCREMENT]
       add [SCORE], ebx
       cmp word[APPLES], 10 
       jne continue
       cmp dword[LEVEL], 10
       jbe game_start ;load new level
       continue:
       call restore_fruit_issues
       call set_new_fruit
       jmp growth
      no_fruit:
      call check_crash
      cmp bx, 0
      jne game_over.loop

      ;asks wether the snake must be moved manually or automatically
      cmp [manual?], byte 1
      je manual_mov

      ;moves automatically the snake
      auto_mov:
      call move_next_pos
      jmp move
      ;moves manually the snake
      manual_mov:
      call convert_key
      
      move:
      push ax      
      call mov_snake     
      add esp, 2
      call paint_snake
      jmp no_growth
      
      growth:       
       push ax ;still stored the new head position
       call grow_snake
       call paint_snake
       add esp, 2

      no_growth:
      cmp byte[two_P], 1
      je game.finish

      ;2players
      pop ax
      push ax

      call convert_key2
      cmp eax, 0
      jne reset_timer2
      ;if not
      push dword[SNAKE_TIME]
      push TIMER2
      call delay
      add esp, 8
      cmp eax, 0
      je real_input2
        mov [manual?], byte 0
        call move_next_pos2
        jmp  real_input_auto2
      

      ;reset the timer cause you moved the snake
      reset_timer2:
      push eax
      push edx
      rdtsc
      mov [TIMER2], eax
      mov [TIMER2+4], edx
      pop edx
      pop eax      

      real_input2:  
      mov [manual?], byte 1
      real_input_auto2:
      push ax
      call mov_snake_head2
      add esp, 2
      call ate_fruit?
      cmp bx, 1
      jne no_fruit2
      fruit2:
       BEEP NOTE_FS7
       inc word[APPLES]
       xor ebx, ebx
       mov bx, [APPLES]
       mov word[FBUFFER+1386+4*ebx], 15| FG.RED | BG.BLACK
       mov ebx, [INCREMENT]
       add [SCORE12], ebx
       cmp word[APPLES], 10 
       jne continue2
       cmp dword[LEVEL], 10
       jbe game_start ;load new level
       continue2:
       call restore_fruit_issues
       call set_new_fruit
       jmp growth2
      no_fruit2:
      call check_crash
      cmp bx, 0
      jne game_over.loop

      ;asks wether the snake must be moved manually or automatically
      cmp [manual?], byte 1
      je manual_mov2

      ;moves automatically the snake
      auto_mov2:
      call move_next_pos2
      jmp move2
      ;moves manually the snake
      manual_mov2:
      call convert_key2
      
      move2:
      push ax      
      call mov_snake2     
      add esp, 2
      call paint_snake2
      jmp no_growth2
      
      growth2:       
       push ax ;still stored the new head position
       call grow_snake2
       call paint_snake2
       add esp, 2

      no_growth2:
      
      game.finish:
      ;fruit timer loop
      mov eax, 1000
      push eax
      push FRUIT_TIMER2
      call delay
      add esp, 8
      cmp eax, 0
      je otherloop
        mov eax, [FRUIT_COUNTER]
        mov word[FBUFFER + 1050 +2*eax], 186 | FG.GREEN | BG.BLACK
        inc dword[FRUIT_COUNTER]

      otherloop:
      push dword[FRUIT_TIME]
      push FRUIT_TIMER
      call delay
      add esp, 8
      cmp eax, 0
      je game.end
        call reset_fruit 
        mov dword[FRUIT_COUNTER], 0
        RENDER EMPTY2, 6, 1, 46, 7
      game.end:
      add esp, 2 ; free the stack
      jmp game.loop


    ; Main loop.
      
    ; Here is where you will place your game logic.
    ; Develop procedures like paint_map and update_content,
    ; declare it extern and use here.
    

draw.red:
  FILL_SCREEN BG.RED
  ret


draw.green:
  FILL_SCREEN BG.GREEN
  ret


get_input:
    call scan
    push ax
    ; The value of the input is on 'word [esp]'   
    
    add esp, 2 ; free the stack
    ret

 
produce_action:
  BEEP NOTE_AS6

  cmp byte [MENU_POS], 0
  je p1
  cmp byte [MENU_POS], 1
  je p2
  cmp byte [MENU_POS], 2
  je high_scores.loop
  cmp byte [MENU_POS], 3
  je diff.loop

  p1:
  mov byte[two_P], 1
  jmp game_start
  p2:
  mov byte[two_P], 0
  jmp game_start

  ;div byte 0
  ;div byte 0
  ;div byte 0
  ret

cursor_up:
  BEEP NOTE_DS8
  cmp byte[MENU_POS], 0
  je nada

  cmp byte[MENU_POS], 1
  je pos.1player

  cmp byte[MENU_POS], 2
  je pos.2player

  cmp byte[MENU_POS], 3
  je pos.scores

  pos.1player:
  RENDER EMPTY, 1, 1, 24, 16
  RENDER FLECHA, 1, 1, 24, 15
  dec byte[MENU_POS]
  jmp nada

  pos.2player:
  RENDER EMPTY, 1, 1, 24, 17
  RENDER FLECHA, 1, 1, 24, 16
  dec byte[MENU_POS]
  jmp nada

  pos.scores:
  RENDER EMPTY, 1, 1, 24, 18
  RENDER FLECHA, 1, 1, 24, 17
  dec byte[MENU_POS]
  jmp nada

  nada:
  ret

cursor_down:
  BEEP NOTE_DS8

  cmp byte[MENU_POS], 3
  je nada1

  cmp byte[MENU_POS], 2
  je pos.exit

  cmp byte[MENU_POS], 1
  je pos.scores1

  cmp byte[MENU_POS], 0
  je pos.2player1

  pos.2player1:
  RENDER EMPTY, 1, 1, 24, 15
  RENDER FLECHA, 1, 1, 24, 16
  inc byte[MENU_POS]
  jmp nada1

  pos.scores1:
  RENDER EMPTY, 1, 1, 24, 16
  RENDER FLECHA, 1, 1, 24, 17
  inc byte[MENU_POS]
  jmp nada1

  pos.exit:
  RENDER EMPTY, 1, 1, 24, 17
  RENDER FLECHA, 1, 1, 24, 18
  inc byte[MENU_POS]
  jmp nada1

  nada1:
  ret

restore_fruit_issues:
  pusha
  rdtsc
  mov [FRUIT_TIMER], eax
  mov [FRUIT_TIMER+4], edx
  mov dword[FRUIT_COUNTER], 0
  RENDER EMPTY2, 6, 1, 46, 7
  popa
  ret