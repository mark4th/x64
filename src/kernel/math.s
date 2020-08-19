; math.1         - x4 basic math words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _constant_ '0', zero,  0
  _constant_ '1', one,   1
  _constant_ '2', two,   2
  _constant_ '3', three, 3
  _constant_ '4', four,  4

; ------------------------------------------------------------------------
; add top two items on parameter stack

;       ( n1 n2 --- n3 )

code '+', plus
  apop rax                   ; get n2
  add rbx, rax               ; add it to n1
  next

; ------------------------------------------------------------------------
; subtract top item from second item

;       ( n1 n2 --- n3 )

code '-', minus
  apop rax
  sub rax, rbx
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; compute absolute value of top item of parameter stack

;       ( n1 --- n1 | +n1 )

code 'abs', abs_
  mov rax, rbx
  neg rbx
  cmovl rbx, rax
  next

; ------------------------------------------------------------------------
; shift left n1 by n2 bits

;       ( n1 n2 --- n3 )

code '<<', shl_
  apop rcx                   ; get number to be shifted
  xchg rbx, rcx              ; get n1 in ebx n2 in ecx
  shl rbx, cl
  next

; ------------------------------------------------------------------------
; signed shift right n1 by n2 bits

;       ( n1 n2 --- n3 )

code '>>', shr_
  apop rcx
  xchg rbx, rcx
  sar rbx, cl
  next

; ------------------------------------------------------------------------
; unsigned shift right n1 by n2 bits

;       ( n1 n2 --- n3 )

code 'u>>', u_shr
  apop rcx                   ; get number to be shifted
  xchg rbx, rcx              ; get n1 in ebx and n2 in ecx
  shr rbx, cl
  next

; ------------------------------------------------------------------------
; multiply top item of parameter stack by 2

;       ( n1 --- n2 )

code '2*', two_star
  add rbx, rbx
  next

; ------------------------------------------------------------------------
; divide top item of parameter stack by 2

;       ( n1 --- n2 )

code '2/', two_slash
  sar rbx, byte 1            ; divide by 2
  next

; ------------------------------------------------------------------------
; divide unsigned number at top of parameter stack by 2

;       ( n1 --- n2 )

code 'u2/', u_2_slash
  shr rbx, byte 1            ; divide it by 2 (unsigned)
  next

; ------------------------------------------------------------------------
; multiply top item of parameter stack by 4

;       ( n1 --- n2 )

code '4*', four_star
  shl rbx, byte 2
  next

; ------------------------------------------------------------------------
; add 1 to top item of parameter stack

;       ( n1 --- n2 )

code '1+', one_plus
  inc rbx
  next

; ------------------------------------------------------------------------
; decrement top item of parameter stack

;       ( n1 --- n2 )

code '1-', one_minus
  dec rbx
  next

; ------------------------------------------------------------------------
; add 2 to top item of parameter stack

;       ( n1 --- n2 )

code '2+', two_plus
  add rbx, byte 2
  next

; ------------------------------------------------------------------------
; subtract 2 from top item of parameter stacl

;       ( n1 --- n2 )

code '2-', two_minus
  sub rbx, byte 2
  next

; ------------------------------------------------------------------------

;       ( n1 --- n2 )

code '4+', four_plus
  add rbx, byte 4
  next

; ------------------------------------------------------------------------

;       ( n1 --- n2 )

code '4-', four_minus
  sub rbx, byte 4
  next

; ------------------------------------------------------------------------
; flip sign

;       ( n --- -n )

code 'negate', negate
  neg rbx
  next

; ------------------------------------------------------------------------
; conditionally flip sign

;       ( n1 f1 --- )

colon '?negate', q_negate
  xt z_less
  xt q_colon
  xt negate
  xt _exit
  exit

; ------------------------------------------------------------------------
; unsigned mixed multiply

;       ( n1 n2 --- d1 )

code 'um*', umstar
  apop rax                   ; get n2
  mul rbx                    ; multiply
  apush rdx                  ; return 64 bit result
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; multiply n1 by n2

;       ( n1 n2 --- n3 )

code '*', star
  apop rax                   ; get n1
  mul rbx                    ; multiply
  mov rbx, rax               ; return result
  next

; ------------------------------------------------------------------------

code 'm*', mstar
  apop rax
  imul rbx
  apush rax
  mov rbx, rdx
  next

; ------------------------------------------------------------------------

;       ( ud un --- uremainder uquotient)

code 'um/mod', u_m_s_mod
  apop2 rdx, rax
  div rbx
  apush rdx
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; signed version of above

;       ( d1 n1 -- rem quot )

code 'sm/rem', s_m_rem
  apop2 rdx, rax
  idiv rbx
  apush rdx
  mov rbx, rax
  next

; ------------------------------------------------------------------------

colon 'mu/mod', m_u_s_mod
  xt to_r
  xt zero
  xt r_fetch
  xt u_m_s_mod
  xt r_to
  xt swap
  xt to_r
  xt u_m_s_mod
  xt r_to
  exit

; ------------------------------------------------------------------------

;       ( d# n1 --- rem quot)

code 'm/mod', m_mod
  apop rdx
  mov rax, rdx
  xor rax, rbx
  jns .L1

  apop rax
  idiv rbx
  test rdx, rdx
  je .L2
  add rdx, rbx
  dec rax
  jmp short .L2

.L1:
  apop rax
  idiv rbx

.L2:
  apush rdx
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; floored division and remainder.

;       ( num den --- rem quot )

code '/mod', s_mod
  apop rcx
  mov rax, rcx
  xor rax, rbx
  jns .L1

  mov rax, rcx
  xor rcx, rdx
  cqo
  idiv rbx
  test rdx, rdx
  je .L2

  add rdx, rbx
  dec rax
  jmp short .L2

.L1:
  mov rax, rcx
  mov rdx, rdx
  cqo
  idiv rbx

.L2:
  apush rdx
  mov rbx, rax
  next

; ------------------------------------------------------------------------

colon '/', slash
  xt s_mod
  xt nip
  exit

; ------------------------------------------------------------------------

colon 'mod', mod
  xt s_mod
  xt drop
  exit

; ------------------------------------------------------------------------

code '*/mod', s_s_mod
  apop2 rcx, rax
  imul rcx
  mov rcx, rdx
  xor rcx, rbx
  jns .L1

  idiv rbx
  test rdx, rdx
  je short .L2
  add rdx, rbx
  dec rax
  jmp short .L2
.L1:
  idiv rbx
.L2:
  mov rbx, rax
  apush rdx
  next

; ------------------------------------------------------------------------

colon '*/', sslash
  xt s_s_mod
  xt nip
  exit

; ------------------------------------------------------------------------

code 'bswap', b_Swap
  bswap rbx
  next

code 's-bswap', s_bswap
  bswap ebx
  next

; ========================================================================
