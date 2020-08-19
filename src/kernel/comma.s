; comma.s
; ------------------------------------------------------------------------

  _variable_ 'dp', dp, _end ; dictionary pointer - dont tuch
  _variable_ 'hp', hp, 0    ; head space pointer - dont touch

; meaning 'dont touch uless you know what you are doing' :)

; ------------------------------------------------------------------------
; align dictionary pointer to next cell

code 'align,', align_c
  add qword [dp_b], 7
  and qword [dp_b], -7
  next

; ------------------------------------------------------------------------
; alloate n1 bytes of dictionary space

;       ( n1 --- )

code 'allot', allot
  add qword [dp_b], rbx     ; add n1 to dictionary pointer
  apop rbx                  ; cache new top of stack
  next

; ------------------------------------------------------------------------
; allocate n1 bytes of head space

;       ( n1 --- )

code 'hallot', h_allot
  add qword [hp_b], rbx      ; add n1 to head space pointer
  apop rbx
  next

; ------------------------------------------------------------------------
; compile 64 bit data into dictionary space

;       ( n1 --- )

code ',', comma
  mov rax, qword [dp_b]       ; allot space for n1
  add qword [dp_b], byte CELL ; allot dictionary space
  mov qword [rax], rbx        ; write data n1 into dictionary
  apop rbx
  next

; ------------------------------------------------------------------------
; compile 32 bit (short) data into dictionary space

;       ( s1 --- )

code 's,', s_comma
  mov rax, qword [dp_b]
  add qword [dp_b], byte 4
  mov dword [rax], ebx
  apop rbx
  next

; ------------------------------------------------------------------------
; compile 16 bit word into dictionary space

;       ( w1 --- )

code 'w,', w_comma
  mov rax, qword [dp_b]     ; get dictionary pointer
  add qword [dp_b], byte 2
  mov word [rax], bx        ; store w1 in dictionary
  apop rbx
  next

; ------------------------------------------------------------------------
; compile 8 bit byte into dictionary space

;       ( c1 --- )

code 'c,', c_comma
  mov rax, qword [dp_b]     ; get next dictionary address
  inc qword [dp_b]          ; allocate one byte
  mov byte [rax], bl
  apop rbx
  next

; ------------------------------------------------------------------------
; compile n1 into head space

;       ( n1 --- )

code 'h,', h_comma
  mov rax, qword [hp_b]        ; get address of next free location in headers
  add qword [hp_b], byte CELL  ; alloocate the space
  mov qword [rax], rbx         ; store data in allocated space
  apop rbx
  next

; ------------------------------------------------------------------------
; compile string at a1 of length n1 into dictionary

;    : $,       ( a1 n1 --- )
;        here swap dup allot
;        cmove ;

colon '$,', str_comma
  xt here                   ; ( from to count --- )
  xt swap
  xt dup                    ; allocate the space first
  xt allot
  xt cmove_                 ; move string into place
  exit

; ------------------------------------------------------------------------
; compile counted string into the dictionary

;    : ,"
;        $22 parse
;        dup c, $, ;

colon ',"', comma_q
  literal 0x22
  xt parse                  ; parse '"' delimited string from input
  xt dup
  xt c_comma                ; compile its length
  xt str_comma              ; compile the string itself
  exit

; ------------------------------------------------------------------------
; compile uncounted string into dictionary

;    : ,'
;        $27 parse
;        $, ;

colon ",'", comma_tic
  literal 0x27
  xt parse                ; parse "'" delimited string from input
  xt str_comma            ; compile string wtih no count byte
  exit

; ========================================================================
