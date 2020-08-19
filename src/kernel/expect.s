; expect.s
; ------------------------------------------------------------------------

  _defer_ 'expect', expect, p_expect

; ------------------------------------------------------------------------
; process input of a backspace character

;       ( #sofar --- 0 | #sofar-1 )

colon 'bsin', bs_in
  xt dup
  xt z_equals
  xt q_exit
  xt one_minus              ; decrement #sofar
  xt p_bs                   ; rub out 1 char left
  xt space
  xt p_bs
  exit

; ------------------------------------------------------------------------

;       ( max adr #sofar char --- max adr max )

colon 'cr-in', cr_in
  xt drop
  xt dup_to_r               ; remember # recieved chars
  xt p_store_to
  dq num_tib_b
  xt over                   ; return #sofar = max
  xt r_to
  xt z_equals
  xt q_exit
  xt space
  exit

; ------------------------------------------------------------------------

colon "?bsin", q_bs_in
  xt bs
  xt not_equals
  xt q_exit
  xt bs_in
  exit

; ------------------------------------------------------------------------

;        ( c1 --- )

colon '^char', ctrl_char
  xt dup
  literal 0xa
  xt equals
  xt q_colon
  xt cr_in
  xt q_bs_in
  exit

; ------------------------------------------------------------------------

;       ( adr #sofar char --- adr #sofar )

colon 'norm-char', norm_char
  xt three_dup              ; ( a1 n1 c1 a1 n1 c1 --- )
  xt emit                   ; echo c1
  xt chars_store            ; store c1 at (a1 + n1)
  xt one_plus               ; increment #sofar
  exit

; ------------------------------------------------------------------------
; input n1 chars max to buffer at a1

;       ( a1 n1 -- )

colon '(expect)', p_expect
  xt swap                   ; ( len adr #sofar )
  xt zero
  xt do_begin
.L1:
  xt pluck                  ; get diff between expected and #sofar
  xt over                   ; ( len adr #sofar #left )
  xt minus
  xt q_while                ; while #left != 0
  bv .L2
  xt key                    ; read key
  xt dup
  xt bl_                    ; < hex 20 ?
  xt less
  xt q_colon
  xt ctrl_char
  xt norm_char
  xt do_repeat
  bv .L1
.L2:
  xt three_drop             ; clear working parameters off stack
  exit

; ------------------------------------------------------------------------
; input string of 256 chars max to tib

colon 'query', query
  xt tib                    ; get 256 chars to tib
  literal TIBSZ
  xt expect
  xt p_off_to               ; reset parse index
  dq to_in_b
  exit

; ========================================================================
