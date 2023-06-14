%include "video.mac"
section .bss
global SONG_TIMER
global CURRENT_NOTE

SONG_TIMER resq 1
CURRENT_NOTE resw 1
section .text
extern tpms
extern clear
extern delay

global on
on:
  in al,0x61
  or al,0b00000011
  out 0x61,al
  ret

global off
off:
  IN      AL, 61h
  AND     AL, 11111100b
  OUT     61h, AL
  RET

global setfreq
setfreq:
  mov al, 0xB6
  out 0x43, al
  xor edx, edx
  mov eax, 1193180
  div dword [esp+4]
  out 0x42, al
  mov al, ah
  out 0x42, al
  ret

;params(dword labelOfTheSong, word songSize)
global play_song
play_song:
  prologue
  xor esi, esi
  xor edx, edx

  mov si, [CURRENT_NOTE]
  mov ebx, [ebp+8]
  
  push dword [ebx+8*esi+4]
  push SONG_TIMER
  call delay
  add esp, 8
  cmp eax, 0
  je nope

  change_note:
  rdtsc
  mov [SONG_TIMER], eax
  mov [SONG_TIMER+4],edx
  inc word[CURRENT_NOTE]
  inc si
  cmp si, [ebp+12] ;song size
  jne not_restart
  mov word[CURRENT_NOTE], 0
  xor esi, esi ;re-starting the song
  not_restart:
  mov ebx, [ebp+8] ;storing song label
  push dword[ebx + 8*esi] ;pushing the note
  call setfreq
  add esp, 4

  nope:
  epilogue
  ret