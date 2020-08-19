; stack.1        - x4 stack manipulation words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; pointers to bottom of stacks

;       ( --- a1 )

  _constant_ 'sp0', sp0, 0 ; these are initialised in init.s
  _constant_ 'rp0', rp0, 0 ;

; ------------------------------------------------------------------------
; push top of stack

code 'apush', a_push
  apush rbx
  next

; ------------------------------------------------------------------------

code 'apop', a_pop
  apop rbx
  next

; ------------------------------------------------------------------------
; get current sp address

;       ( --- a1 )

code 'sp@', sp_fetch
  apush rbx
  mov rbx, SP
  next

; ------------------------------------------------------------------------
; set new sp address

;       ( a1 -- )

code 'sp!', sp_store
  mov SP, rbx
  apop rbx
  next

; ------------------------------------------------------------------------
; get current return stack pointer address

;       ( -- a1 )

code 'rp@', rp_fetch
  apush rbx
  mov rbx, RP
  next

; ------------------------------------------------------------------------
; set new rp address

;       ( a1 -- )

code 'rp!', rp_store
  mov RP, rbx               ; set rp
  apop rbx
  next

; ------------------------------------------------------------------------
; duplicate top item of parameter stack

;       ( n1 --- n1 n1 )

code 'dup', dup
  apush rbx                 ; push copy of top stack item
  next

; ------------------------------------------------------------------------
; duplicate top item of parameter stack ONLY if it is NON ZERO

;       ( n1 --- n1 n1 | 0 )

code '?dup', q_dup
  or rbx, rbx               ; is top stack item zero ?
  jnz dup
  next

; ------------------------------------------------------------------------
; duplicate top two items of parameter stack

;       ( n1 n2 --- n1 n2 n1 n2 )

code '2dup', two_dup
  mov rax, qword [SP]        ; get copy of second stack item
  apush2 rbx, rax            ; psuh copy of tos and 2os
  next

; ------------------------------------------------------------------------
; duplicate top 3 items of stack

;       ( n1 n2 n3 --- n1 n2 n3 n1 n2 n3 )

code '3dup', three_dup
  mov rcx, qword [SP]
  mov rdx, qword [SP + CELL]
  apush3 rbx, rdx, rcx
  next

; ------------------------------------------------------------------------
; swap top two items of parameter stack

;       ( n1 n2 --- n2 n1 )

code 'swap', swap
  xchg rbx, [SP]
  next

; ------------------------------------------------------------------------
; swap second two items with top two items of parameter stack

;       ( n1 n2 n3 n4 --- n3 n4 n1 n2 )

code '2swap', two_swap
   apop rax
   xchg rbx, qword [SP]
   xchg rax, qword [SP + CELL]
   apush rax
   next

; ------------------------------------------------------------------------
; discard top item of parameter stack

;       ( n1 --- )

code 'drop', drop
  apop rbx
  next

; ------------------------------------------------------------------------
; discard top two items of parameter stack

;       ( n1 n2 --- )

code '2drop', two_drop
  add SP, byte CELL
  apop rbx
  next

; ------------------------------------------------------------------------
; discard top 3 items of parameter stack

code '3drop', three_drop
  add SP, byte 2 * CELL
  apop rbx
  next

; ------------------------------------------------------------------------
; copy second stack item over top of top item

;       ( n1 n2 --- n1 n2 n1 )

code 'over', over
  apush rbx                  ; push cached tos onto stack
  mov rbx, qword [SP + CELL] ; get copy of 2os in cache
  next

; ------------------------------------------------------------------------
; discard second stack item

;       ( n1 n2 --- n2 )

code 'nip', nip
  add SP, byte CELL        ; discard 2os
  next

; ------------------------------------------------------------------------
; push copy of top item under second item

;       ( n1 n2 --- n2 n1 n2 )

code 'tuck', tuck
  mov rax, qword [SP]
  mov qword [SP], rbx
  apush rax
  next

; ------------------------------------------------------------------------
; get copy of third stack item

;       ( n1 n2 n3 --- n1 n2 n3 n1 )

code 'pluck', pluck
  apush rbx
  mov rbx, qword [SP + 2* CELL]
  next

; ------------------------------------------------------------------------
; push copy of nth stack item

;       ( ... n1 --- ... n2 )

code 'pick', pick
  mov rbx, qword [SP +8* rbx]
  next

; ------------------------------------------------------------------------
; rotate third item of parameter stack out to top position

;       ( n1 n2 n3 --- n2 n3 n1 )

code 'rot', rot
  xchg rbx, qword [SP]
  xchg rbx, qword [SP + CELL]
  next

; ------------------------------------------------------------------------
; rotate third item of parameter stack out to top position

;       ( n1 n2 n3 --- n3 n1 n2 )

code '-rot', dash_rot
  xchg rbx, qword [SP + CELL]
  xchg rbx, qword [SP]
  next

; ------------------------------------------------------------------------
; split 32 bit value into two 16 bit valuse

;       ( n1 --- lo hi )

code 'split', split
  mov rdx, rbx              ; copy n1 hi to dx
  or edx, edx               ; zero extend n1 lo 32 to 64 bits
  shr rbx, byte 32
  apush rdx
  next

; ------------------------------------------------------------------------
; join two 16 bit data items into one 32 bit item

;       ( lo hi --- n1 )

code 'join', join
  apop rax                  ;
  shl rbx, byte 32          ; shift hi into upper word
  or rbx, rax
  next

; ------------------------------------------------------------------------
; move top item of parameter stack to return stack

;       ( n1 --- )

code '>r', to_r
 rpush rbx                  ; push n1 onto return stack
 apop rbx
 next

; ------------------------------------------------------------------------
; move top two items off parameter stack onto return stack

;       ( n1 n2 --- )

code '2>r', two_to_r
  apop2 rax, rcx
  rpush2 rbx, rax
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; move item off return stack onto parameter stack

;       ( --- n1 )

code 'r>', r_to
  apush rbx                 ; push cached top of stack
  rpop rbx                  ; pop top item off return stack
  next

; ------------------------------------------------------------------------
; move 2 items off return stack onto parameter stack

;       ( --- n1 n2 )

code '2r>', two_r_to
  rpop2  rcx, rdx
  apush2 rbx, rcx
  mov rbx, rdx
  next

; ------------------------------------------------------------------------
; copy top item of parameter stack to return stack

;       ( n1 --- n1 )

code 'dup>r', dup_to_r
  rpush rbx
  next

; ------------------------------------------------------------------------
; drop one item off return stack

;       ( --- )

code 'r>drop', r_drop
  add RP, byte CELL         ; discard top item of return stack
  next

; ------------------------------------------------------------------------
; get copy of top item of return stack onto parameter stack

;       ( --- n1 )

code 'r@', r_fetch
  apush rbx
  mov rbx, qword [RP]       ; push copy of r stack item onto p stack
  next

; ------------------------------------------------------------------------

;       ( --- n1 )

colon 'depth', depth
  xt sp_fetch
  xt sp0
  xt swap
  xt minus
  xt cell_slash
  exit

; ------------------------------------------------------------------------
; abort on stack underflow

colon '?stack', q_stack
  xt sp_fetch
  xt sp0
  xt u_greater
  xt rp_fetch
  xt rp0
  xt u_greater
  xt or_
  xt p_abort_q
  db 15, 'Stack Underflow'
  xt rp_fetch
  xt rp0
  literal STKSZ
  xt minus
  xt u_less
  xt p_abort_q
  db 14, 'Stack Overflow'
  exit

; ========================================================================
