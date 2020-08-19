; reloc.1        - x4 head space relocation words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

rethread:
  push rsi
  mov rsi, qword [voc_link_b] ; point to first vocabulary
.L0:
  mov rcx, 64               ; number of threads in vocabulary
.L1:
  cmp rdx, qword [rsi]      ; is start of this thread the header we just
  jne .L2                   ;  relocated?
  mov qword [rsi], rbp      ; yes - point thread at headers new address
  jmp short .L3             ; break out of loop - job complete
.L2:
  add rsi, byte CELL        ; point to next thread
  loop .L1
  mov rsi, qword [rsi]      ; link back to next vocabulary
  cmp rsi, 0                ; no more vocabs ?
  jne .L0
.L3:
  pop rsi
  ret

; ------------------------------------------------------------------------

h_reloc:
  mov rax, qword [rsi]      ; get soruce link field
  cmp rax, 0                ; start of thread ?
  jz .L0
  mov rax, qword [rax - CELL]
.L0:
  stosq                     ; save link in destination
  mov qword [rsi], rdi      ; save where this header gets relocated to
  add rsi, byte CELL
  mov rbp, rdi              ; and destination nfa too
  mov rdx, rsi              ; remember source nfa hdr we just relocated
  movzx rcx, byte [rsi]
  mov rax, rcx
  and rcx, LEX
  inc rcx
  rep movsb                 ; relocate nfa
  and rax, ALIAS            ; is this an alias ?
  jnz .L2
  mov rax, qword [rsi]      ; get cfa of this word
  mov qword [rax - CELL], rbp ; point cfa - 8 at new header location
.L2:
  movsq                     ; relocate cfa pointer
  ret

; ------------------------------------------------------------------------
; relocate all headers to address edi

relocate:
  call h_reloc              ; relocate one header
  call rethread             ; check all threads of all vocabs for relocated
  cmp rdx, rbx              ; finished ?
  jne relocate
  ret

; ------------------------------------------------------------------------
; relocate all headers to allocated head space

unpack:
  mov rax, qword [turnkeyd_b] ; are there any headers to relocate ?
  or rax, rax
  jnz .L0

  mov rsi, qword [dp_b]     ; get address of end of list space
  mov rdi, qword [hp_b]     ; where to relocate to
  mov rbx, qword [l_head]   ; address of last header defined

  call relocate

  mov qword [l_head], rbp   ; save address of highest header in memory
  mov qword [hp_b], rdi     ; correct h-here

.L0:
  ret

; ------------------------------------------------------------------------
; relocate all headers to here. point here at end of packed headers

code 'pack', pack
  push rbx                  ; retain cached top of stack
  push rsi                  ; forths sp
  push rdi                  ; and rp
  mov rsi, qword [b_head_b] ; point to start of head space
  mov rdi, qword [dp_b]     ; point to reloc destination
  mov rbx, qword [last_b]
  call relocate             ; relocate all headers
  mov qword [hp_b], rdi
  mov qword [l_head], rbp
  pop rdi
  pop rsi
  pop rbx
  next

;=========================================================================
