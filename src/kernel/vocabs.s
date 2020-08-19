; vocabs.s     - x4 vocabulary creating words etc
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; can not put this in rehash.s as it has to be 100% headerless

  _defer_ 'rehash', rehash, _rehash

; ------------------------------------------------------------------------
; remembers most recently defined vocabulary

  _variable_ 'voclink', voc_link, root_b

; ------------------------------------------------------------------------

  _constant_ '#threads', num_thread, 64
  _var_ 'current', current, forth_b

  _var_ 'context', context, context0_b
  _var_ '#context', num_context, 3
  _var_ 'contexts', contexts, 0

; ------------------------------------------------------------------------
; the context stack - the search order

; enough space to have 16 vocabularies in the search order
; i.e. overkill

code 'context0', context0
  call do_variable
context0_b:
  dq root_b
  dq compiler_b
  dq forth_b
  times 13 dq 0

; ------------------------------------------------------------------------
; run time for vocabularies

; push specified vocabulary onto context stack or rotate it out to top
; if its already in there

;       ( a1 --- )

code 'dovoc', do_voc
  mov rdi, qword [context_b]     ; get address of active context stack
  mov rcx, qword [num_context_b] ; get context stack depth
  pop rax

  repnz scasq               ; is vocabulary already in context?
  jne .L1
  jecxz .L2

  ; already in context - rotate it out to top of stack

  sub rdi, byte CELL        ; point back at found vocab

.L0:
  mov rdx, qword [rdi + CELL] ; shift each voc down 1 pos in stack
  mov qword [rdi], rdx
  add rdi, byte CELL
  dec rcx
  jne .L0
  mov qword [rdi], rax       ; put vocab a1 at top of context stack
  next

.L1:
  inc qword [num_context_b] ; no - increment depth
  stosq                     ; add vocabulary to context
.L2:
  next

; ------------------------------------------------------------------------
; create a new vocabulary

colon 'vocabulary', vocabulary
  xt current                ; remember where definitions are being linked
  literal root_b            ; all vocabs created into root
  xt p_store_to
  dq current_b
  xt create                 ; create header, make voc use dovoc
  xt s_uses
  xt do_voc
  xt here                   ; create vocabulary thread array
  xt dup
  literal 512
  xt dup
  xt allot
  xt erase
  xt voc_link               ; link new voc to previous one
  xt fetch
  xt comma
  xt voc_link               ; remember most recent vocabulary
  xt store
  xt p_store_to             ; restore current
  dq current_b
  exit

; ------------------------------------------------------------------------
; make all new definitions go into first vocab in search order

code "definitions", definitions
  mov rdx, qword [context_b]     ; get address of active context stack
  mov rax, qword [num_context_b] ; get context stack depth
  dec rax
  mov rax, qword [rdx +8* rax]
  mov qword [current_b], rax
  next

; ------------------------------------------------------------------------
; drop top item of context stack

code 'previous', previous
  mov rdx, qword [context_b]
  mov rax, qword [num_context_b]
  dec qword [num_context_b]
  xor rcx, rcx
  mov qword [rdx +8* rax], rcx
  next

; ------------------------------------------------------------------------

  _vocab_ "forth",    forth,    f_link, 0
  _vocab_ "compiler", compiler, c_link, forth_b
  _vocab_ "root",     root,     root_n,  compiler_b

; tribal knowledge:  cannot  use r_link in the definition of the root
; vocabulary becuse it is not set till we switch to a different vocabulary
; and were not doing that.  this item is the most recently defined word
; in the root vocabulary which we always link into the first thread.
; after assembly the vocabulary is *not* hashed but that will be fixed
; when we extend the kernel (see rehash.s)

; ========================================================================















