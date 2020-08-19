; rehash.s
; ------------------------------------------------------------------------

l_head:
  dq v_link                 ; address of last header defined in kernel

; ------------------------------------------------------------------------
; link header at esi into vocabulary at edi

link:
  mov bh, byte [rsi]        ; get nfa hash
  and bh, 0x1f
  mov bl, byte [rsi + 1]
  add bl, bl
  cmp bh, 1
  je .L1
  add bl, byte [rsi + 2]    ; add second char to total
  add bl, bl                ; *2

.L1:
  add bl, bh                ; add nfa length to hash
  and ebx, 0x3f             ; there are 64 threads per vocabulary

  shl rbx, 3                ; and 8 bytes per thread entry
  add rbx, rdi              ; point ebx at thread to link into

  mov rax, qword [rbx]      ; get header currently at end of this thread
  mov qword [rbx], rsi      ; put new header at end of this thread
  mov qword [rsi - CELL], rax ; link new end to old end
  ret

; ------------------------------------------------------------------------
; hashify one vocabulary pointed to by edi

hash_voc:
  xor rcx, rcx              ; number of words in thread 0
  mov rsi, qword [rdi]      ; point esi at end of vocabularies thread 0

  ; nasm chained all words onto the first thread.

.L0:
  push rsi                  ; save address of header to rehash
  inc rcx                   ; keep count
  mov rsi, qword [rsi - CELL] ; scan back to previous word in thread
  or rsi, rsi               ; found the end of the chain ?
  jnz .L0

  ; reached end of thread zero. nfas of all words in this thread are now
  ; on the stack and ecx it the total thereof

.L1:
  mov qword [rdi], 0        ; erase first chain of vocabulary
.L2:
  pop rsi                   ; get nfa of header to hash
  call link                 ; link it to one of the threads
  loop .L2
  ret

; ------------------------------------------------------------------------

_rehash:
  mov rax, noop             ; neuter this word so it can never be run
  mov qword [rehash_b], rax ;  again

  push rsi                  ; save sp
  push rdi                  ; save rp
  push rbx                  ; save top of parameter stack
  mov rdi, qword [voc_link_b] ; point to first vocabulary to rehash

.L0:
  call hash_voc             ; hashify one vocabulary
  mov rdi, qword [edi + 512]; get address of next vocabulary
  or rdi, rdi               ; end of vocabulary chain ?
  jnz .L0

  pop rbx                   ; yes... restore top of stack and ip
  pop rdi
  pop rsi
  next

; ========================================================================
