; loops.1        - x4 looping and branching constructs
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; compute bounds of a do loop

;       ( a1 n1 --- a2 a1 )

code 'bounds', bounds
  add rbx, qword [SP]      ; get a1 + a2 in
  xchg rbx, qword [SP]     ; return start add at top of stack
  next

; ------------------------------------------------------------------------
; these noop words exist only for the decompiler

;       ( ---)

code 'dothen', do_then
  next

; ------------------------------------------------------------------------

;       ( --- )

code 'dobegin', do_begin
  next

; ------------------------------------------------------------------------
; unconditional branches within high elvel definition

;       ( --- )

code 'branch', branch
  pop rax
  movzx edx, word [rax]
  movsx rdx, dx
  add rax, rdx
  jmp rax

; ------------------------------------------------------------------------

;       ( --- )

code 'doelse', do_else
  jmp short branch

; ------------------------------------------------------------------------
; unconditional branch

;       ( --- )

code 'doagain', do_again
  jmp short branch

; ------------------------------------------------------------------------
; unconditional branch

;       ( --- )

code 'dorepeat', do_repeat
  jmp short branch

; ------------------------------------------------------------------------
; conditional branches within high level definition

;       ( f1 --- )

code '?branch', q_branch
  mov rax, rbx
  apop rbx
  test rax, rax             ; if its NOT zero go to branch code above
  jz branch
  add qword [rsp], byte 2   ; advance IP past branch vector
  next

; ------------------------------------------------------------------------

code 'doif', do_if
  jmp short q_branch

; ------------------------------------------------------------------------

code '?while', q_while
  jmp short q_branch

;-------------------------------------------------------------------------

code '?until', q_until
  jmp short q_branch

; ------------------------------------------------------------------------

;       ( n1 --- )

code 'docase', do_case
  pop rsi                   ; point to case statement
  lodsq                     ; push case exit point
  push rax
  lodsq                     ; fetch default vecot
  mov rbp, rax
  lodsq                     ; fetch case count
  mov rcx, rax

.L0:
  cmp rbx, qword [rsi]
  jz .L1
  add rsi, 2* CELL
  loop .L0

  cmp rbp, 0                ; option not found, do we have a default?
  jz .L2
  apop rbx                  ; if so take it
  jmp rbp

.L1:
  push qword [rsi + CELL]
.L2:                        ; eax has selected vector (can be default)
  apop rbx                  ; cache new top of stack
  ret


; ------------------------------------------------------------------------
; clean do loop stuff off return stack

code 'undo', undo
  add RP, byte 24          ; do placed 3 items on return stack. drop them
  next

; ------------------------------------------------------------------------
; increment loop index and loop back if not at limit

code '(loop)', p_loop
  inc qword [RP]            ; increment loop index. OV will set on limit
  jno branch                ; if not at limit take loop branch
.L0:
  add qword [rsp], byte 2   ; skip past branch vector
  jmp short undo            ; and undo loop

; ------------------------------------------------------------------------
; add N to loop index and loop back if not at limit

;       ( n1 --- )

code '(+loop)', p_p_loop
  apop rcx
  add qword [RP], rbx       ; add n1 to loop index
  mov rbx, rcx
  jno branch                ; if not at limit branch back in definition
  jo p_loop.L0              ; else clean up loop stuff and exit loop

; ------------------------------------------------------------------------
; initiate a do loop

;       ( end start --- )

code '(do)', p_do
  apop rdx                  ; get loop end index
.L0:
  mov rax, qword [rsp]      ; get address of loop exit point
  movzx ecx, word [rax]
  add rax, rcx

  add qword [rsp], byte 2   ; advance IP past it

  rpush rax                 ; put exit point on stack

  mov rbp, 0x8000000000000000
  add rdx, rbp              ; fudge loop index
  sub rbx, rdx

  rpush rdx
  rpush rbx           ; push fudged loop indicies onto return stack

  apop rbx                  ; cache new top of stack iten
  next

; ------------------------------------------------------------------------
; initiate a do loop if start index != limit

;       ( n1 n2 --- )

code '(?do)', p_q_do
  apop rdx                  ; get limit
  cmp rbx, rdx              ; same ?
  jne p_do.L0               ; if not then go ahead an init loop
  apop rbx
  jmp branch

; ------------------------------------------------------------------------
; leave do loop

code '(leave)', p_leave
  mov rax, qword [RP + 16] ; set ip to loop exit point
  mov qword [rsp], rax
  jmp undo

; ------------------------------------------------------------------------
; leave loop if flag is true

;       ( f1 --- )

code '(?leave)', p_q_leave
  mov rax, rbx
  apop rbx
  or rax, rax               ; f1 is true/false ?
  jnz short p_leave
  next

; ------------------------------------------------------------------------

;     ( n1 --- )

code 'dofor', do_for
  cmp rbx, 0                ; zero itteration loop?
  jz .L0
  dec rbx                   ; zero base the loop index
  add qword [rsp], byte 2   ; skip loop exit vector
  jmp to_r
.L0:
  apop rbx                  ; pop new top of stack
  jmp branch                ; branch to loop end

; ------------------------------------------------------------------------
; i refuse to call this word "next" because "next" is special!

;       ( --- )

code '(nxt)', p_nxt
  dec qword [RP]            ; decrement index
  cmp qword [RP], -1        ; did index decrement through zero?
  jnz branch                ; no  : loop back
  add RP, byte CELL         ; yes : clean return stack
  add qword [rsp], byte 2   ; and skip past branch vector
  next

; ------------------------------------------------------------------------

;     ( ... cfa n1 --- ??? )

colon "(rep)", p_rep
  xt swap
  xt do_for
  bv .L2
.L1:
  xt dup_to_r
  xt execute
  xt r_to
  xt p_nxt
  bv .L1
.L2:
  xt drop
  exit

; ------------------------------------------------------------------------

;     ( n1 --- )

colon "dorep", do_rep
  xt p_compile              ; fetch xt to be repeated
  xt p_rep                  ; execute it n1 times
  exit

; ------------------------------------------------------------------------
; get outermost loop index

code 'i', i
  xor rax, rax              ; calculate i from r stack [+ 0] and [+ 4]
.L0:
  apush rbx                 ; flush cached top of stack
  mov rbx, qword [rax + RP]      ; get current index (fudged)
  add rbx, qword [rax + RP + CELL] ; defudge by adding in fudged limit
  next

; ------------------------------------------------------------------------
; get second inner loop index

code 'j', j
  mov rax, 24               ;calculate j from r stack [+ 12] and [+ 16]
  jmp short i.L0

;-------------------------------------------------------------------------
;get third inner loop index

code 'k', k
  mov rax, 48                ;calculate k from r stack [+ 24] and [+ 28]
  jmp short i.L0

;=========================================================================
