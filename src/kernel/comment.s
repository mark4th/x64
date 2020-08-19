; comment.s
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; line comment

;    : \
;        $a parse 2drop ; immediate

  _immediate_

colon '\', backslash
  literal 0xa               ; end of line char
  xt parse                  ; parse to end of line
  xt two_drop               ; discard it all
  exit

; ------------------------------------------------------------------------
; stack comment - ignore everything in input stream till next )

;    : (
;      ')' parse 2drop ; immediate

  _immediate_

colon '(', l_paren
  literal ')'               ; parse to closing paren
  xt parse
  xt two_drop               ; send it all to /dev/null
  exit

; ------------------------------------------------------------------------
; ignore but echo evrything till next ) in input stream

;    : .(
;        ')' parse type ; immediate

  _immediate_

colon '.(', dotlparen
  literal ')'               ; parse to clising paren but instead of
  xt parse                  ; throwing it all away
  xt type                   ; echo it all to console
  exit

; ------------------------------------------------------------------------
; ignore rest of file

;    : \s
;        floads ?: abort-fload noop ; immediate

  _immediate_

colon '\s', backs
  xt floads                 ; are we in the middle of an fload operation?
  xt q_colon
  xt abort_fload            ; if so abort it
  xt _exit
  exit

; ------------------------------------------------------------------------
; abort all nested floads

;    : \\s
;        begin
;            floads
;        while
;            abort-fload
;        repeat ; immediate

  _immediate_

colon "\\s", xs
  xt do_begin
.L0:
  xt floads                 ; while were still floading files
  xt q_while
  bv .L1
  xt abort_fload            ; abort current fload
  xt do_repeat
  bv .L0
.L1:
  exit

; ========================================================================

