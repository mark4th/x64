; number.s  - number input
; ------------------------------------------------------------------------

  _var_ 'base', base, 10    ; default radix is 10

; ------------------------------------------------------------------------
; is character c1 a valid digit in the current base

;       ( c1 base --- n1 true | false )

code 'digit', digit
  apop rdx                  ; get base

  sub bl, '0'               ; un askify character
  jb .L2                    ; oopts - not a valid digit in any base

  cmp bl, 9                 ; greater than 9 ?
  jle .L1
  cmp bl, 17                ; make sure its not ascii $3a through $40
  jb .L2
  sub bl, 7                 ; convert a,b,c,d etc into 10,11,12,13 etc

.L1:
  cmp bl, dl                ; valid digit in current base?
  jge .L2

  apush rbx                 ; yes!!!
  mov rbx, -1
  next

.L2:
  xor rbx, rbx              ; not a valid digit
  next

; ------------------------------------------------------------------------
; see if string of length n1 at addres a1 is a valid number in base

;       ( a1 n1 base --- n1 true | false )

colon '(number)', p_number
  xt dash_rot               ; ( base result a1 n1 -- )
  xt zero
  xt dash_rot
  xt bounds                 ; ( base result a1 a2 --- )
  xt p_do                   ; for length of string a1 do
  bv .L3
.L1:
  xt over                   ; ( base result base c --- )
  xt i
  xt c_fetch                ; ( base result [n1 t | f] ---)
  xt upc
  xt digit
  xt not_
  xt do_if
  bv .L2

  xt three_drop             ; oopts, not a number
  xt undo
  xt false
  exit
  xt do_then

.L2:
  xt swap                   ; ( base n1 result --- )
  xt pluck
  xt star
  xt plus
  xt p_loop                 ; ( base result --- )
  bv .L1

.L3:
  xt nip                    ; discard base
  xt true
  exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 base --- n2 true | false )

; e.g.       123
;           -456

colon '(num)', p_num
  xt p_number               ; convert string at a1 to number if can
  xt dup                    ; was it a number ?
  xt not_
  xt q_exit
  xt to_r                   ; yes, negate it if f1 is true
  xt swap
  xt q_negate
  xt r_to
  exit

; ------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

; e.g.       'x'
;           -'y'

chr_num:
  call nest
  xt over                   ; must have closing tick
  xt two_plus
  xt c_fetch
  literal 0x27
  xt equals
  xt not_
  xt p_abort_q
  db 9, "Missing '"
  xt drop
  xt one_plus
  xt c_fetch
  xt swap
  xt q_negate
  xt true
  exit

; ------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

; e.g.       %1101
;           -%1001

bin_num:
  call nest
  xt one
  xt s_string
  xt two
  xt p_num
  exit

; ------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

;e.g.       \023
;          -\034

oct_num:
  call nest
  xt one
  xt s_string
  literal 8
  xt p_num
  exit

; ------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

; e.g.       $65
;           -$48

hex_num:
  call nest
  xt one
  xt s_string
  literal 16
  xt p_num
  exit

; ------------------------------------------------------------------------
; default case, no base prefix specified, use current default base

def_num:        ; ( f1 a1 n1 --- )
  call nest
  xt base
  xt p_num
  exit

; ------------------------------------------------------------------------
; see if string has a '-' prefix

;       ( a1 n1 --- f1 a1' n1' )

colon '?negative', q_negative
  xt over
  xt c_fetch
  literal '-'
  xt equals
  xt dash_rot
  xt pluck
  xt do_if
  bv .L0
  xt one
  xt s_string
  xt do_then
.L0:
  exit

; ------------------------------------------------------------------------
; convert string at a1 to a number in current base (if can)

;       ( a1 --- n1 true | false )

colon 'number', number
  xt count                  ; ( a1 n1 --- )
  xt q_negative             ; is first char of # a '-' ?
  xt over                   ; get next char of string...
  xt c_fetch                ; ( f1 a2 n2 c2 --- )

  xt do_case
  dq .L1                    ; case exit point
  dq def_num                ; default case
  dq 4                      ; case count

  dq '$',  hex_num
  dq '\',  oct_num
  dq '%',  bin_num
  dq 0x27, chr_num

.L1:
  exit

; ========================================================================
