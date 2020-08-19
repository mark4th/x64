; parse.s
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------

  _var_ '>in',  to_in, 0    ; current position within TIB
  _var_ '#tib', num_tib, 0  ; number of chars in TIB
  _var_ "tib",  tib, 0      ; address of tib

; ------------------------------------------------------------------------
; default input source address and char count

;       ( --- a1 n1 )

colon '(source)', p_source
  xt tib                    ; get address of terminal input buff
  xt num_tib                ; get char count
  exit

; ------------------------------------------------------------------------
; return # characters as yet unparsed in tib

;       ( --- n1 )

colon 'left', left
  xt num_tib                ; number of chars in tib (total)
  xt to_in                  ; how far we have parsed
  xt minus                  ; calculate difference
  exit

; ------------------------------------------------------------------------

colon '?refill', q_refill
  xt left                   ; if there is nothing left to parse out of tib
  xt q_exit
  xt refill                 ; refill tib from input stream
  exit

; ------------------------------------------------------------------------
; parse a word from input, delimited by c1

;       ( c1 --- a1 n1 )

colon 'parse', parse
  xt to_r
  xt source
  xt to_in
  xt s_string
  xt over
  xt swap
  xt r_to
  xt scan_eol
  xt to_r
  xt over
  xt minus
  xt dup
  xt r_to
  xt z_not_equals
  xt minus
  xt p_plus_store_to
  dq to_in_b
  exit

; ------------------------------------------------------------------------
; like parse but skips leading delimiters - used by word

;       ( c1 --- a1 n1 )

colon 'parse-word', parse_word
  xt to_r
  xt source
  xt tuck
  xt to_in
  xt s_string
  xt r_fetch
  xt skip
  xt over
  xt swap
  xt r_to
  xt scan_eol
  xt to_r
  xt over
  xt minus
  xt rot
  xt r_to
  xt dup
  xt z_not_equals
  xt plus
  xt minus
  xt p_store_to
  dq to_in_b
  exit

; ------------------------------------------------------------------------
; parse string from input. refills tib if empty

;       ( c1 --- )

colon 'word', word_
  xt q_refill
  xt parse_word             ; ( a1 n1 --- )
  xt h_here                 ; copy string to hhere
  xt str_store
  exit

; ========================================================================
