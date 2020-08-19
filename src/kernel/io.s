; io.1      - x4 i/o words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _defer_ 'emit', emit, p_emit
  _defer_ 'key', key, p_key

; ------------------------------------------------------------------------

  _constant_ 'bs', bs, 8         ; a backspace
  _constant_ 'bl', bl_, 32       ; a space

  _var_ '#out', num_out,   0     ; # characters thus far emmited on line
  _var_ '#line', num_line, 0     ; how far down the screen we are

  _var_ 'fdout', fd_out,   1     ; defaults file descriptor for emit

; ------------------------------------------------------------------------
; these constants are patched by an extension to reflect reality

  _constant_ 'rows', rows, 25    ; default terminal size to 80 by 25
  _constant_ 'cols', cols, 80

; ------------------------------------------------------------------------
; output a character to stdout

;       ( c1 --- )

colon '(emit)', p_emit
  xt sp_fetch               ; point to character to emit
  xt fd_out                 ; normally stdout
  xt swap
  xt one                    ; writing one character only to stdout
  xt sys_write              ; discard return value and character
  xt two_drop               ; drop error and c1

  xt p_incr_to              ; #out++
  dq num_out_b
  exit

; ------------------------------------------------------------------------
; uses qkfd pollfd structure to poll standardin

;       ( --- f1 )

colon 'key?', key_q
  xt zero                   ; timeout in ms
  xt one                    ; we only have one pollfd structure
  literal .L0               ; at this address
  xt sys_poll
  xt one                    ; ok i know this is bad but - meh
  xt equals
  exit
.L0:
  dd 0                      ; stdin file handle
  dw 1                      ; want to know when data is there to read
  dw 0                      ; returned events placed here23F0000

; ------------------------------------------------------------------------
; wait for data to become available on stdin then read stdin

;       ( --- c1 )

colon '(key)', p_key
  xt zero                   ; create read buffer
  xt sp_fetch               ; point at it :)
  xt one                    ; read one character
  xt swap
  xt zero                   ; from stdin
  xt sys_read               ; return if there was no error
  xt q_exit
; syscall returned error - if the terminals have a controlling tty this
; is fine (ish) but if we are running from a script this is considered
; fatal
  xt in_tty                 ; if stdin is on a tty
  xt q_exit                 ; then ignore the error (todo?)
  xt bye                    ; else we are running from a #! script

; ------------------------------------------------------------------------
; output string of length n1 at a1

;     ( a1 --- a1` )

colon "(type)", p_type
  xt count                  ; ( a1 --- a2 c1 )
  xt emit
  exit

; ------------------------------------------------------------------------

;     ( a1 n1 --- )

colon "type", type
  xt do_rep
  xt p_type
  xt drop
  exit

; ------------------------------------------------------------------------
; emit a carriage return (or is it a new line :)

;       ( --- )

colon 'cr', cr
  literal 0xa
  xt emit
  xt num_line
  xt one_plus
  xt rows
  xt min
  xt p_store_to
  dq num_line_b
  xt p_off_to
  dq num_out_b
  exit

; ------------------------------------------------------------------------
; emit a blank (a space character)

;       ( --- )

colon 'space', space
  literal 0x20              ; emit a space
  xt emit
  exit

; ------------------------------------------------------------------------
; display n1 spaces

;       ( n1 --- )

colon 'spaces', spaces
  xt do_rep
  xt space
  exit

; ------------------------------------------------------------------------
; emit a backspace and adjust #out

;       ( --- )

colon '(bs)', p_bs
  xt bs                     ; emit increments #out and we moved it <--
  xt emit
  literal -2                ; so we must subtract 2 from it
  xt p_plus_store_to
  dq num_out_b
  exit

; ------------------------------------------------------------------------
; output n1 backspaces

;       ( n1 --- )

colon 'backspaces', backspaces
  xt num_out
  xt min
  xt do_rep
  xt p_bs
  exit

; ------------------------------------------------------------------------
; output an inline string

;       ( --- )

colon '(.")', p_dot_q
  xt r_to                   ; get address of string to display
  xt count                  ; get length of string
  xt two_dup                ; set return address past end of string
  xt plus
  xt to_r
  xt type                   ; display string
  exit

; ------------------------------------------------------------------------
; return address of scratchpad

;       ( --- a1 )

colon 'pad', pad
  xt here
  literal 256
  xt plus
  exit

; ------------------------------------------------------------------------
; if f1 is true abort with a message

;       ( f1 --- )

colon '(abort")', p_abort_q
  xt r_to                   ; get address of abort message
  xt count
  xt rot                    ; get f1 back at top of stack
  xt do_if                  ; is f1 true ?
  bv .L0
  xt type                   ; yes display message and abort
  xt cr
  xt abort
  xt do_then

.L0:
  xt plus                   ; nope - add string length to string address
  xt to_r
  exit                      ; and put it as our return address

; ------------------------------------------------------------------------
; return the right side of the string, starting at position n1

;       ( a1 n1 n2 --- a2 n3 )

; adds n2 to a1, subtracts n2 from n1

code '/string', s_string
  sub qword [SP], rbx
  add qword [SP + CELL], rbx
  apop rbx
  next

; ========================================================================
