; header.s
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; name hash of most recently defined word.

; this selects which thread of the current vocabulary the new word will
; be linked to when it is revealed

  _var_ 'thread', thread, 0

; ------------------------------------------------------------------------
; return next free dictionary address

;       ( --- a1 )

code 'here', here
  apush rbx                  ; save top of stack cache
  mov rbx, qword [dp_b]     ; return dp
  next

; ------------------------------------------------------------------------
; return next free head space address

;       ( --- a1 )

code 'hhere', h_here
  apush rbx                 ; save top of stack cache
  mov rbx, qword [hp_b]     ; return hp
  next

; ------------------------------------------------------------------------
; word to mask out lex (immdiate etc) bits from a count byte

;       ( n1 --- n1` )

code 'lexmask', lex_mask
  and rbx, LEX              ; mask out everything except length bits
  next                      ; max lengh for word name is 32 charactes

; ------------------------------------------------------------------------
; move from code field address to body field address

;       ( a1 --- a2 )

code '>body', to_body
  add rbx, byte BODY        ; call instruction in cfa is 5 bytes
  next

; ------------------------------------------------------------------------
; move from body field address back to code field address

;       ( a1 --- a2 )

code 'body>', body_to
  sub rbx, byte BODY        ; skip back to call instruction in cfa
  next

; ------------------------------------------------------------------------
; move from name field to link field

;       ( a1 --- a2 )

code 'n>link', n_to_link
  sub rbx, byte CELL        ; link field is 4 bytes just behind nfa
  next

; ------------------------------------------------------------------------
; move from link field to name field

;       ( a1 --- a2 )

code 'l>name', l_to_name
  add rbx, byte CELL        ; link field is 4 bytes
  next

; ------------------------------------------------------------------------
; move from nfa to cfa

;       ( a1 --- a2 )

colon 'name>', name_to
  xt count                  ; convert a1 to a1+1 n1
  xt lex_mask               ; mask lex bits out of count and add n1 to a1
  xt plus
  xt fetch                  ; fetch contents of cfa pointer
  exit

; ------------------------------------------------------------------------
; move from cfa to name field

colon '>name', to_name
  xt cell_minus             ; cell preceeding cfa points to nfa
  xt fetch
  exit

; ------------------------------------------------------------------------
; create a new word header

colon '(head,)', p_head
  xt h_here                 ; remember link field address of new header
  xt to_r
  xt zero                   ; dummy link to as yet unknown thread
  xt h_comma
  xt h_here                 ; get address where nfa will be compiled
  xt dup
  xt p_store_to             ; remember address of new words nfa
  dq last_b
  xt comma                  ; link cell below cfa to nfa
  xt h_here                 ; store string at hhere
  xt str_store
  xt current                ; get address of first thread of current voc
  xt h_here                 ; hash new word name, get thread to link it into
  xt hash
  xt plus
  xt dup                    ; remember address of thread (for reveal)
  xt p_store_to
  dq thread_b
  xt fetch                  ; link new word to previous one in thread
  xt r_to
  xt store
  xt h_here                 ; allocate name field !!
  xt c_fetch
  xt one_plus
  xt h_allot
  xt here                   ; compile address of cfa into header
  xt h_comma
  exit

; ------------------------------------------------------------------------
; create a new word header in head space

colon 'head,', head_comma
  xt bl_                    ; parse name from tib
  xt parse_word
  xt p_head                 ; create header from name
  exit

; ------------------------------------------------------------------------
; link most recently created header into current vocabulary chain

colon 'reveal', reveal
  xt last                   ; get nfa of most recent definition
  xt thread                 ; get address of thread to link into
  xt store                  ; link new header into chain
  exit

; ========================================================================
