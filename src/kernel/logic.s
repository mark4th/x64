; logic.1        - x4 boolean logic etc
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; bool constants

;       ( --- f1 )

  _constant_ 'true', true, -1
  _constant_ 'false', false, 0

; ------------------------------------------------------------------------

;       ( n1 n2 --- n3 )

code 'and', and_
  apop rax
  and rbx, rax
  next

; ------------------------------------------------------------------------

;       ( n1 n2 --- n3)

code 'or', or_
  apop rax
  or rbx, rax
  next

; ------------------------------------------------------------------------

;       ( n1 n2 --- n3 )

code 'xor', xor_
  apop rax
  xor rbx, rax
  next

; ------------------------------------------------------------------------
; 1s compliment top stack item

;       ( n1 --- n2 )

code 'not', not_
  not rbx
  next

; ------------------------------------------------------------------------
; test for equality with zero (THIS IS NOT A NOT OPERATION)

;       ( n1 --- f1 )

code '0=', z_equals
  sub rbx, byte 1           ; subtract 1 from n1 (carry if n1 was 0 )
  sbb rbx, rbx              ; subtract n1 from n1 (-1 if ther was a carry)
  next

; ------------------------------------------------------------------------

;       ( n1 n2 --- f1 )

code '=', equals
  apop rax
  sub rbx, rax
  jmp z_equals

;-------------------------------------------------------------------------

;       ( n1 ---  f1 )

code '0<', z_less
  sar rbx, byte 63
  next

; ------------------------------------------------------------------------
; see if n1 is greater than 0

;       ( n1 --- f1 )

code '0>', z_greater
  neg rbx                   ; negate n1
  sar rbx, byte 63
  next

; ------------------------------------------------------------------------
; return true if n1 is posative

;       ( n1 --- f1 )

code '0<>', z_not_equals
  neg rbx                   ; sets carry if rbx not zero, else clear it
  sbb rbx, rbx
  next

; ------------------------------------------------------------------------
; see if n1 is unequal to n2

;       ( n1 n2 --- f1 )

code '<>', not_equals
  apop rax                  ; get n1 and n2
  sub rbx, rax              ; get difference
  neg rbx                   ; convert to a true or false
  sbb rbx, rbx
  next

; ------------------------------------------------------------------------
; see if unsigned n2 is less than unsigned n1

;       ( n1 n2 --- f1 )

code 'u<', u_less
  apop rax                  ; get n1
.L0:
  sub rax, rbx              ; get difference
  sbb rax, rax              ; return true if n2 < n1
  mov rbx, rax
  next

; ------------------------------------------------------------------------
; see if unsigned n2 is greater than unsigned n1

;       ( n1 n2 --- f1 )

code 'u>', u_greater
  apop rax                  ; get n2 and n1 in oposite order from above
  xchg rax, rbx
  jmp u_less.L0             ; use above code !!!

; ------------------------------------------------------------------------
; see if n2 is less than n1

;       ( n1 n2 --- f1 )

code '<', less
  apop rax
  cmp rax, rbx
  mov rbx, -1
  jl .L1
  xor rbx, rbx
.L1:
  next

; ------------------------------------------------------------------------
; see if n2 is greater than n1

;       ( n1 n2 --- f1 )

code '>', greater
  apop rax
  cmp rax, rbx
  mov rbx, -1
  jg .L1
  xor rbx, rbx
.L1:
  next

; ------------------------------------------------------------------------
; return the smallest of 2 unsigned values

;       ( n1 n2 --- n1 | n2 )

code 'umin', u_min
  apop rax
  pop rax
  cmp rax, rbx
  ja .L1
  mov rbx, rax
.L1:
  next

; ------------------------------------------------------------------------
; return the smallest of 2 signed values

;       ( n1 n2 --- n1 | n2 )

code 'min', min
  apop rax
  cmp rax, rbx
  jg .L1
  mov rbx, rax
.L1:
  next

; ------------------------------------------------------------------------
; return the larger of 2 unsigned values

;       ( n1 n2 --- n1 | n2 )

code 'umax', u_max
  apop rax
  cmp rax, rbx
  jna .L1
  mov rbx, rax
.L1:
  next

; ------------------------------------------------------------------------
; return the larger of two signed values

;       ( n1 n2 --- n1 | n2 )

code 'max', max
  apop rax
  cmp rax, rbx
  jl .L1
  mov rbx, rax
.L1:
  next

; ------------------------------------------------------------------------
; return n1 or zero if n1 is negative

;       ( n1 --- n1 | 0 )

code '0max', z_max
  xor rax, rax
  cmp rbx, rax
  jg .L1
  mov rbx, rax
.L1:
  next

; ------------------------------------------------------------------------
; see if n1 is within upper and lower limits (not inclusive)

;       ( n1 n2 n3 --- f1 )

code 'within', within
  mov rax, rbx              ; get upper limit
  apop2 rcx, rdx            ; get lower limit and n1
  xor rbx, rbx              ; assume false
  cmp rdx, rax              ; is n1 below upper limit?
  jge .L0
  cmp rdx, rcx              ; is n1 above lower limit?
  jl .L0
  dec rbx                   ; yes we are in limits
.L0:
  next

; ------------------------------------------------------------------------
; see if n1 is between upper and lower limits inclusive

;       ( n1 n2 n3 --- f1 )

code 'between', between
  mov rax, rbx              ; get upper limit
  apop2 rcx, rdx            ; get lower limit and n1
  xor rbx, rbx              ; assume false
  cmp rdx, rax              ; is n1 less that or equal to uper limit?
  jg .L0
  cmp rdx, rcx              ; is n1 greater than or equal to lower limit?
  jl .L0
  dec rbx                   ; we are within limits, eax = true
.L0:
  next

; ------------------------------------------------------------------------
; return true if n1 equals either n2 or n3

colon 'either', either
  xt dash_rot
  xt over
  xt equals
  xt dash_rot
  xt equals
  xt or_
  exit

; ------------------------------------------------------------------------
; return true if n1 is not equal to eithe n2 or n3

;       ( n1 n2 n3 --- f1 )

colon 'neither', neither
  xt dash_rot
  xt over
  xt not_equals
  xt dash_rot
  xt not_equals
  xt and_
  exit

;=========================================================================
