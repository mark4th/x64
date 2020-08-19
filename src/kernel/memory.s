; memory.i       - x4 memory access words (fetch and store etc)
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _constant_ 'cell', cell, CELL

; ------------------------------------------------------------------------

code 'cell+', cell_plus
  add rbx, byte CELL
  next

; ------------------------------------------------------------------------

code 'cell-', cell_minus
  sub rbx, byte CELL
  next

; ------------------------------------------------------------------------

code 'cells', cells
  shl rbx, byte 3
  next

; ------------------------------------------------------------------------

code 'cell/', cell_slash
  shr rbx, byte 3
  next

; ------------------------------------------------------------------------

;     ( a1 --- a1` )

code 'align', align_
  add rbx, byte 7
  and rbx, byte -7
  next

; ------------------------------------------------------------------------
; compute address of indexted cell in array

;       ( a1 ix --- a2 )

code '[]+', cells_plus
  apop rax                  ; get a1
  lea rbx, [rax +8* rbx]
  next

; ------------------------------------------------------------------------
; fetch indexed cell of array

;       ( a1 ix --- n2 )

code '[]@', cells_fetch
  apop rax
  mov rbx, qword [rax +8* rbx]
  next

; ------------------------------------------------------------------------
; store data at indexed cell of array

;       ( n1 a1 ix --- )

code '[]!', cells_store
  apop2 rax, rcx
  mov qword [rax +8* rbx], rcx
  apop rbx
  next

; ------------------------------------------------------------------------

code '[s]@', shorts_fetch
  apop rax
  mov ebx, dword [rax +4* rbx]
  next

; ------------------------------------------------------------------------
; cant call this [d]! because that implies a double not a dword

code '[s]!', shorts_store
  apop2 rax, rcx
  mov dword [rax +4* rbx], ecx
  apop rbx
  next

; ------------------------------------------------------------------------

;       ( a1 ix --- w1 )

code '[w]@', words_fetch
  apop rax
  movzx bx, [eax +2* ebx]
  next

; ------------------------------------------------------------------------

;       ( w1 a1 ix --- )

code '[w]!', words_store
  apop2 rax, rcx
  mov word [rax +2* rbx], cx
  apop rbx
  next

; ------------------------------------------------------------------------

;       ( a1 ix --- c1 )

code '[c]@', chars_fetch
  apop rax
  movzx rbx, byte [rax + rbx]
  next

; ------------------------------------------------------------------------

;	( c1 a1 ix --- )

code '[c]!', chars_store
  apop2 rax, rcx
  mov byte [rax + rbx], cl
  apop rbx
  next

; ------------------------------------------------------------------------
; fetch data from address (fetches 32 bits)

;       ( a1 --- n1 )

code '@', fetch
  mov rbx, qword [rbx]
  next

; ------------------------------------------------------------------------

code 's@', s_fetch
   mov ebx, dword [rbx]
   next

; ------------------------------------------------------------------------
; fetch word from address a1

;       ( a1 --- w1 )

code 'w@', w_fetch
  movzx ebx, word [rbx]
  next

; ------------------------------------------------------------------------
; fetch character from address a1

;       ( a1 --- c1 )

code 'c@', c_fetch
  movzx ebx, byte [rbx]     ; get character
  next

; ------------------------------------------------------------------------
; store data at adderss

;       ( n1 a1 --- )

code '!', store
  apop rax
  mov qword [rbx], rax
  apop rbx
  next

; ------------------------------------------------------------------------

code 's!', s_store
  apop rax
  mov dword [rbx], eax
  apop rbx
  next

; ------------------------------------------------------------------------
; store word w1 at address a1

;       ( w1 a1 --- )

code 'w!', w_store
  apop rax
  mov word [rbx], ax
  apop rbx
  next

; ------------------------------------------------------------------------
; store character c1 at address a1

;       ( c1 a1 --- )

code 'c!', c_store
  apop rax
  mov byte [rbx], al
  apop rbx
  next

; ------------------------------------------------------------------------
; swap contents of two memory cells

;       ( a1 a2 --- )

code 'juggle', juggle
  apop2 rax, rbp

  mov rcx, qword [rax]
  mov rdx, qword [rbx]
  mov qword [rbx], rcx
  mov qword [rax], rdx

  mov rbx, rbp
  next

; ------------------------------------------------------------------------
; convert a counted string to an address and count

;       ( a1 --- a2 n1 )

code 'count', count
  movzx rcx, byte [rbx]     ; get length byte from string
  inc rbx                   ; advance address past count byte
  apush rbx                 ; return address and length
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; like count but fetches 64 bit item and advances address by 8

code 'qcount', q_count
  mov rcx, qword [rbx]
  add rbx, byte CELL
  apush rbx
  mov rbx, rcx
  next

; ------------------------------------------------------------------------

code 'scount', s_count
  mov ecx, dword [rbx]
  add rbx, byte 4
  apush rbx
  mov rbx, rcx
  next

; ------------------------------------------------------------------------

code 'wcount', w_count
  movzx ecx, word [rbx]
  add rbx, byte 2
  apush rbx
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; move contents of address a1 to address a2

;           ( a1 a2 --- )

code 'qmove', q_move
  apop rax                   ; get a1
  mov rax, qword [rax]       ; get contents thereof
  mov qword [rbx], rax       ; store it at a2
  apop rbx                   ; cache tos
  next

; ------------------------------------------------------------------------
; get length of asciiz string

;       ( a1 --- a1 n1 )

code 'strlen', str_len
  mov rax, rbx
.L0:
  cmp byte [rbx], 0
  jz .L1
  inc rbx
  jmp short .L0
.L1:
  sub rbx, rax
  apush rax
  next

; ------------------------------------------------------------------------
; set bits of data at specified address

;       ( n1 a1 --- )

code 'cset', c_set
  apop rax
  or [rbx], al
  apop rbx
  next

; ------------------------------------------------------------------------
; clear bits of data at specified address

;       ( n1 a1 --- )

code 'cclr', c_clr
  apop rax
  not rax
  and byte [rbx], al
  apop rbx
  next

; ------------------------------------------------------------------------
; set data at address to true

;       ( a1 --- )

code 'on', on
  mov qword [rbx], -1
  apop rbx
  next

; ------------------------------------------------------------------------
; set data at address to false

;       ( a1 --- )

code 'off', off
  mov qword [rbx], 0
  apop rbx
  next

; ------------------------------------------------------------------------
; increment data at specified address

;       ( a1 --- )

code 'incr', incr
  inc qword [rbx]
  apop rbx
  next

; ------------------------------------------------------------------------
; decrement data at specified address

;       ( a1 --- )

code 'decr', decr
  dec qword [rbx]
  apop rbx
  next

; ------------------------------------------------------------------------
; decrement data at specified address but dont decrement throught zero

;       ( a1 --- )

code '0decr', z_decr
  mov rax, qword [rbx]      ; read current value
  jnz decr                  ; if it is not already 0 then decrement it
  apop rbx                  ; else dont :)
  next

; ------------------------------------------------------------------------
; add n1 to data at a1

;       ( n1 a1 --- )

code '+!', plus_store
  apop rax                  ; get data
  add qword [rbx], rax      ; add data to address
  apop rbx
  next

; ------------------------------------------------------------------------
; store n1 in var whose address is compiled into definition

;       ( n1 --- )

code '(!>)', p_store_to
  mov rax, qword [rsp]      ; get address of var to modify
  mov rax, [rax]
  mov qword [rax], rbx      ; store tos in body of word
.L0:
  apop rbx
.L1:
  add qword [rsp], byte CELL; advance ip past parameter
  next

; ------------------------------------------------------------------------
; add n1 to var whose address is compiled into current definition

;       ( n1 --- )

code '(+!>)', p_plus_store_to
  mov rax, qword [rsp]
  mov rax, [rax]
  add qword [rax], rbx
  jmp p_store_to.L0

; ------------------------------------------------------------------------

code "%?'", z_q_tick
  apush rbx
  mov rax, qword[rsp]       ; return address contains address of body
  mov rbx, [rax]            ; fetch contents of body
mov rbx, [rbx]
  jmp p_store_to.L1

; ------------------------------------------------------------------------
; zero var whose address is compiled into current definition

;       ( --- )

code '(off>)', p_off_to
  mov rax, qword [rsp]
  mov rax, [rax]
  mov qword [rax], 0
  jmp p_store_to.L1

; ------------------------------------------------------------------------
; set var whose address is compiled into current definition to true

;       ( --- )

code '(on>)', p_on_to
  mov rax, qword [rsp]
  mov rax, [rax]
  mov qword [rax], -1
  jmp p_store_to.L1

; ------------------------------------------------------------------------
; increment var whose address is compiled into current definition

;       ( --- )

code '(incr>)', p_incr_to
  mov rax, qword [rsp]
  mov rax, [rax]
  inc qword [rax]
  jmp p_store_to.L1

; ------------------------------------------------------------------------
; decrement var whose address is conpiled into current definition

;       ( --- )

code '(decr>)', p_decr_to
  mov rax, qword [rsp]
  mov rax, [rax]
  dec qword [rax]
  jmp p_store_to.L1

; ------------------------------------------------------------------------

;       ( src dst len --- )

code 'cmove', cmove_
  mov rcx, rbx              ; get # bytes to move
  apop2 rdi, rsi            ; get destination and source addresses

  shr rcx, 2
  rep movsd
  mov rcx, rbx
  and rcx, 3
  rep movsb

  apop rbx
  next

; ------------------------------------------------------------------------
; as above but starting at end of buffers and moving downwards in mem

;       ( a1 a2 n1 --- )

code 'cmove>', cmove_to
  mov rcx, rbx              ; get byte count in ecx
  apop2 rdi, rsi            ; get destination and source addresses
  jecxz .L1

  add rdi, rcx              ; point to end of source and destination
  add rsi, rcx
  dec rdi
  dec rsi

  std                       ; moving backwards
  rep movsb                 ; move data
  cld                       ; restore default direction

.L1:
  apop rbx
  next

; ------------------------------------------------------------------------
; fill block of memory with character

;       ( a1 n1 c1 --- )

code 'fill', fill
  mov rax, rbx              ; get fill char
  apop2 rcx, rdi            ; fill count and fill address

.L0:
  rep stosb
  apop rbx
  next

; ------------------------------------------------------------------------
; fill memory with short words (32 bits)

;       ( a1 n1 d1 --- )

code 'sfill', s_fill    ; dfill
  mov rax, rbx
  apop2 rcx, rdi
  rep stosd
  apop rbx
  next

; ------------------------------------------------------------------------
; fill block of memory with spaces

;       ( a1 n1 --- )

code 'blank', blank
  mov al,' '
.L0:
  mov rcx, rbx
  apop rdi
  jmp short fill.L0

; ------------------------------------------------------------------------
; fill block of memory with nulls

;       ( a1 n1 --- )

code 'erase', erase
  xor al, al
  jmp short blank.L0

; ------------------------------------------------------------------------
; ascii upper case translation table

atbl:
  db  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
  db 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
  db '!"#$%&', "'"
  db '()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`ABCDEFG'
  db 'HIJKLMNOPQRSTUVWXYZ{|}~', 127

; ------------------------------------------------------------------------
; convert a single character to upper case.

;       ( c1 --- c2 )

code 'upc', upc
  mov rax, atbl
  and rbx, 07fh
  xchg rax, rbx
  xlatb
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; compare 2 strings.

;       ( a1 a2 n1 --- -1 | 0 | 1 )

code 'comp', comp
  mov rcx, rbx              ; get string length
  apop2 rdi, rsi            ; get addresses of strings
  jecxz .L1                 ; n1 is zero? skip this..
  repz cmpsb                ; comp strings
  jz .L1                    ; ecx=0
  jnb .L0
  mov rcx, -1
  jmp .L1
.L0:
  mov rcx, 1
.L1:
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; convert string from counted to asciiz - useful for os calls

;       ( a1 n1 --- a1 )

colon 's>z', s_to_z
  xt over
  xt plus
  xt zero
  xt swap
  xt c_store
  exit

; ------------------------------------------------------------------------
; store string a1 of length n1 at address a2 as a counted string

;       ( a1 n1 a2 -- )

colon '$!', str_store
  xt two_dup
  xt c_store
  xt one_plus
  xt swap
  xt cmove_
  exit

; ------------------------------------------------------------------------
; tag counted string a1 onto end of counted string a2

; combined length should not be more than 255 bytes.
;  this is not checked

;     ( a1 n1 a2 --- )

colon '$+', strplus
  xt dup_to_r               ; remember address of destination string
  xt count                  ; save current length, get address of end
  xt dup_to_r
  xt plus
  xt dash_rot
  xt to_r
  xt swap
  xt r_fetch
  xt cmove_
  xt two_r_to
  xt plus
  xt r_to
  xt c_store
  exit

; ========================================================================
