; double.s  - double number math (not division)
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; add two double (64 bit) numbers

;       ( d1 d2 --- d3 )

code 'd+', dplus
  apop2 rax, rcx
  add qword [SP], rax        ; add d2 low to d1 low
  adc rbx, rcx               ; add d2 high to d1 high
  next

; ------------------------------------------------------------------------
; subtract 64 bit numbers

;       ( d1 d2 --- d3 )

code 'd-', d_minus
  apop2 rax, rcx
  sub qword [SP], rax        ; subtract d2 low from d1 low
  sbb rcx, rbx               ; subtract d2 high from d1 high
  mov rbx, rcx               ; return result high in ebx
  next

; ------------------------------------------------------------------------
; negate a double number

;       ( d1 --- -d1 )

code 'dnegate', d_negate
  apop rax                   ; get d1 low
  neg rbx                    ; negate n1 low and high
  neg rax
  sbb rbx, byte 0            ; did the neg mess with overflow or something?
  apush rax
  next

; ------------------------------------------------------------------------
; compute absolute value of a double

;       ( d1 ---- d1` )

code 'dabs', dabs
  test rbx, rbx              ; is d1 high negative?
  js d_negate                ; if so negate d1
  next

; ------------------------------------------------------------------------
; convert single to double (signed!)

;       ( n1 --- d1 )

code 's>d', s_to_d
  apush rbx                  ; push d1 low = n1
  add rbx, rbx               ; shift sign bit into carry
  sbb rbx, rbx               ; propogates sign of n1 throughout d1 high
  next

; ------------------------------------------------------------------------
; compare 2 double numbers

;    : d=    ( d1 d2 --- f1 )
;        d- or 0= ;

colon 'd=', d_equals
  xt d_minus                 ; stubract d2 from d1
  xt or_                     ; or together high and low of result
  xt z_equals                ; result will only be 0 when d1 = d2
  exit

; ------------------------------------------------------------------------
; is double number negative?

;       ( d1 --- f1 )

code 'd0<', d_z_lezz
  add rbx, rbx               ; shift sign bit into carry
  sbb rbx, rbx               ; propogates sign of n1 throughout d1 high
  apop rax
  next

; ------------------------------------------------------------------------
; see if double d1 is less than double d2

;       ( d1 d2 --- f1 )

code 'd<', d_less       ; TODO
  apop2 rax, rcx        ; not right need to apop all and the test
  cmp qword [SP], rax   ; and apush result
  apop rax
  sbb rcx, rbx
  mov rbx, 0
  jge .L1
  dec rbx
.L1:
  next

; ------------------------------------------------------------------------

;    : d>    ( d1 d2 --- f1 )
;        2swap d< ;

colon 'd>', d_greater
  xt two_swap
  xt d_less
  exit

; ------------------------------------------------------------------------

;    : d<>    ( d1 d2 --- f1 )
;        d= 0= ;

colon 'd<>', d_not_equals
  xt d_equals
  xt z_equals
  exit

; ========================================================================
