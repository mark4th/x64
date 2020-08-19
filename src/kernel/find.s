; find.s   - x4 dictionary searches
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; calculate hash value (thread number) for counted string at a1

;       ( a1 --- thread )

code "hash", hash
  mov ax, word [rbx]        ; get count byte and first char of name
  and al, LEX               ; mask out lex bits
  add ah, ah                ; double char 1
  cmp al, 1                 ; only 1 char in name ?
  je .L1
  add ah, byte [rbx + 2]    ; add second char
  add ah, ah                ; and double again
.L1:
  add al, ah                ; add to length byte
  and rax, 0x3f             ; 64 threads per vocabulary
  mov rbx, rax
  shl rbx, 3                ; 8 bytes per thread
  next


; ------------------------------------------------------------------------
; search one dictionary thread for specified word (at hhere)

;   ( thread --- cfa f1 | false )

;   f1: 1 if immediate, -1 otherwise

code '(find)', p_find
  or rbx, rbx               ; empty thread?
  jz .L3                    ; if so get out now

  mov rdi, qword [hp_b]     ; point to string to search for
  movzx rcx, byte [rdi]     ; get string length
  inc rdi                   ; point to string

.L0:                        ; main loop of search
  mov al, byte [rbx]        ; get count byte from dictionary entry
  and al, LEX               ; mask out lex bits
  cmp al, cl                ; lengths match ?
  je .L2

.L1:                        ; not a match
  mov rbx, qword [rbx -CELL]; scan back to next word in dictionary
  or rbx, rbx               ; end of chain?
  jne .L0
  next

.L2:                        ; length bytes match...
  push rdi                  ; keep copy of string address
  push rcx                  ; and length

  mov rsi, rbx              ; point esi at dictionary entry
  inc rsi                   ; skip count byte
  repe cmpsb                ; compare strings

  pop rcx                   ; retrieve length and address of string
  pop rdi
  jne .L1                   ; was the above a match ?

  mov rbp, qword [rbx + rcx + 1]
  apush rbp

  movzx eax, byte [rbx]     ; get count byte of matched word
  mov rbx, 1                ; assume word is immediate
  test rax, IMM             ; is it ?
  jne .L3
  neg rbx                   ; no

.L3:
  next

; ------------------------------------------------------------------------
; search all vocabularies that are in context for word name at hhere

;    ( --- cfa f1 | false )

colon 'find', find
  xt h_here                 ; pre-calculate hash of item to search for
  xt hash
  xt context                ; get address and depth of context stack
  xt num_context
  xt do_for                 ; for each voc in context
  bv .L2
.L0:
  xt dup
  xt r_fetch                ; collect the voc address
  xt cells_fetch
  xt pluck                  ; index to hashed bucket
  xt plus
  xt fetch
  xt p_find                 ; search for word thats at hhere
  xt q_dup
  xt do_if
  bv .L1

  xt two_swap               ; found it, clean up, return -1 or 1
  xt two_drop
  xt r_drop
  exit

  xt do_then
.L1:
  xt p_nxt
  bv .L0
.L2:
  xt two_drop               ; not found, clean up, return false
  xt false
  exit

; ------------------------------------------------------------------------
; abort if f1 is false (used after a find :)

;       ( f1 --- )

colon '?missing', q_missing
  xt z_equals               ; is word specified defined?
  xt q_exit
  xt h_here                 ; display name of unknown word
  xt count
  xt space
  xt type
  xt true                   ; and abort
  xt p_abort_q
  db 2,' ?'
  exit

; ------------------------------------------------------------------------
; parse input stream and see if word is defined anywhere in search order

;     ( --- f1 | false )

colon 'defined', defined
  xt bl_                    ; parse space delimited string from input
  xt word_
  xt find                   ; search dictionary for a word of this name
  exit

; ------------------------------------------------------------------------
; find cfa of word specified in input stream

; return cfa of word parsed out of input stream. abort if not found

colon "'", tick
  xt defined                ; is next word in input stream defined ?
  xt z_equals
  xt q_missing              ; if not then abort
  exit

; ========================================================================
