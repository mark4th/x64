; interpret.s    - x4 inner interpreter and compiler
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _defer_ 'quit', quit, p_quit
  _defer_ '%interpret', z_interpret, p_interpret
  _defer_ '.status', dot_status, noop
  _defer_ '.line#', dot_l, noop

  _defer_ 'source', source, p_source
  _defer_ 'refill', refill, query

  _var_ 'ok?', q_ok, -1     ; display ok messages in quit ?

; ------------------------------------------------------------------------
; compile a number or return its value

;   ( n1 --- n1 | )

colon '?comp#', q_comp_num
  xt state                  ; if we are  in compile mode then compile n1
  xt q_colon                ; as a literal.  otherwise return n1
  xt literal_
  xt _exit
  exit

; ------------------------------------------------------------------------
; we input an unknown word. is it it a valid number in current radix?

;       ( --- | n1 )

colon '?#', q_num
  xt h_here                 ; null input ?
  xt c_fetch
  xt z_equals               ; null input is not an error
  xt q_exit

  xt h_here                 ; ( --- n1 true | false )
  xt number
  xt z_equals               ; abort if not valid number
  xt q_missing
  xt q_comp_num             ; otherwise compile it as a literla or return
  exit                      ; it

; ------------------------------------------------------------------------
; input is a known word. compile it or execute it

; if we are in interpret mode execute the word whose cfa on the stack
; if we are in compile mode and the word is immediate then execute it
; if we are in compile mode and the word is not immediate compile it

;       ( xt [ t | 1 ] --- )

colon '?exec', q_exec
  xt state
  xt xor_
  xt q_colon
  xt execute
  xt comma_xt
  exit

; state | flag  | action  |
; ------+-------+---------+
;  0    |  1    | execute |
;  0    | -1    | execute |
; -1    |  1    | execute |
; -1    | -1    | compile |
; ------+-------+---------+

; ------------------------------------------------------------------------
; interpret/compile word or number (%interpret vectors to here normally)

;       ( xt [t | 1] | false --- | n1 )

colon '(interpret)', p_interpret
  xt q_dup                  ; ?exec needs the -1/1 but ?# does not need 0
  xt q_colon
  xt q_exec
  xt q_num
  exit

; ------------------------------------------------------------------------
; interpret input buffers till nothing left to interpreet

colon 'interpret', interpret
  xt do_begin               ; repeat till tib is empty
.L0:
  xt defined                ; is the typed in stuff a valid forth word?
  xt z_interpret            ; interpret, compile or abort
  xt q_stack                ; did any of the above over/underflow?
  xt left
  xt z_equals
  xt q_until
  bv .L0
  exit                      ; else return to quit for an "ok"

; ------------------------------------------------------------------------
; conditionally display "ok" after user input

colon '.ok', dot_ok
  xt floads                 ; never display ok when floading
  xt q_exit

  xt state                  ; no ok mesage while still in compile mode
  xt not_
  xt q_ok                   ; and abort errors are never ok
  xt and_
  xt do_if                  ; but go ahead and output a cr
  bv .L0

  xt p_dot_q                ; ok... display ok message
  db 3, ' ok'
  xt do_then

.L0:
  xt cr                     ; output a new line
  xt p_on_to                ; reset ?ok till next error
  dq q_ok_b
  exit

; ------------------------------------------------------------------------
; forths inner interpret (erm compiler :) loop

; this is an infinite loop.  any abort will cause a jump back to here

colon '(quit)', p_quit
  xt psp0                   ; reset processors stack
  mov rsp, rbx
  apop rbx

  xt l_bracket              ; state off

  xt rp0                    ; reset forths stack pointers
  xt rp_store
  xt sp0
  xt sp_store

  xt do_begin               ; stay a while... stay forever! <-- props to
.L0:                        ; anyone who knows what game this is from :)
  xt dot_status             ; display status and ok message (maybe)
  xt dot_ok
  xt interpret              ; interpret user input
  xt do_again
  bv .L0

; ------------------------------------------------------------------------
; an error occurred. reset and jump back into quit

colon '(abort)', p_abort
  xt dot_l                  ; kludgy but it works
  xt xs                     ; \\s abort all file loads
  xt p_off_to               ; flush input on abort
  dq num_tib_b
  xt p_off_to
  dq to_in_b
  xt p_off_to               ; no ok message
  dq q_ok_b
  xt quit                   ; jump back into quit loop

; ========================================================================
