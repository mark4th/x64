; scan.s    - skip and scan etc
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------
; actual char that word delimited on (actually scan)

  _constant_ 'wchar', wchar, 0

; ------------------------------------------------------------------------
; skip leading characters equal to c1 within a string

;       ( a1 n1 c1 --- a2 n2 )

code 'skip', skip
  apop rcx                  ; get length
  jecxz .L1
  apop rdi
  mov rax, rbx              ; get c1 in al

  rep scasb                 ; scan string till no match
  jz .L0                    ; run out of string ?

  inc rcx                   ; jump back into string
  dec rdi

.L0:
  apush rdi                  ; return a2
.L1:
  mov rbx, rcx              ; return n2
  next

; ------------------------------------------------------------------------
; scan string for character c1

;       ( a1 n1 c1 --- a2 n2 )

;       a2 = address where c1 was found (end of string if not found)
;       n2 = length from a2 to end of string

code 'scan', scan
  apop rcx                  ; get length of string in ecx (n1)
  jecxz .L2                 ; null string ?

  apop rdi                  ; address of string in edi (a1)
  mov rax, rbx              ; get item to search for in eax (c1)
  repnz scasb               ; search string for char
  jnz .L1                   ; run out of string ? or find item ?

  inc rcx                   ; point back at located item
  dec rdi

.L1:
  apush rdi                 ; return a2

.L2:
  mov rbx, rcx              ; return n2
  next

; -----------------------------------------------------------------------
; scan memory for 16 bit item n2

;       ( a1 n1 w1 --- a2 n2 )

code 'wscan', wscan
  apop rcx                  ; get length of buffer to search (n1)
  jecxz .L2                 ; null string ?
  apop rdi                  ; get address of memory to search (a1)
  mov rax, rbx              ; get item to search for in eax (w1)
  repnz scasw               ; search...
  jnz .L1
  inc rcx
  sub rdi, byte 2
.L1:
  apush rdi
.L2:
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; scan memory for 32 bit item (short)

;       ( a1 n1 n2 --- a2 n2 )

code 'sscan', s_scan
  pop rcx                   ; get length of buffer to search (n1)
  jecxz .L2                 ; null string ?
  apop rdi                  ; get addess of memory to search (a1)
  mov rax, rbx              ; get item to search for in eax (n2)
  repnz scasd               ; search...
  jnz .L1
  inc rcx
  sub rdi, byte 4
.L1:
  apush rdi
.L2:
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; scan memory for 64 bit item

;       ( a1 n1 n2 --- a2 n2 )

code 'qscan', q_scan
  pop rcx                   ; get length of buffer to search (n1)
  jecxz .L2                 ; null string ?
  apop rdi                  ; get addess of memory to search (a1)
  mov rax, rbx              ; get item to search for in eax (n2)
  repnz scasq               ; search...
  jnz .L1
  inc rcx
  sub rdi, byte CELL
.L1:
  apush rdi
.L2:
  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; as above but also delimits on eol

; this word is used by parse-word now instead of the above so that we can
; consider an entire memory mapped source file to be our terminal input
; buffer.

;       ( a1 n1 c1 --- a2 n2 )

code 'scan-eol', scan_eol
  apop rcx                  ; get length of string to scan
  jecxz .L3                 ; empty string ?
  apop rdi                  ; no, get address of string

.L0:
  mov al, [rdi]             ; get next byte of string

  cmp al, 0xa               ; end of line ?
  je .L2
  cmp al, 0xd
  je .L2

  cmp al, bl                ; not eol, same as char c1 ?
  je .L2

  cmp bl, 0x20              ; if were scanning for blanks then
  jne .L1                   ; also delimit on the evil tab
  cmp al, 9                 ; the evil tab is a blank too
  je .L2                    ; DONT USE TABS!

.L1:
  inc rdi
  dec rcx
  jnz .L0                   ; ran out of string?

  xor al, al                ; we didnt delimit, we ran out of string

.L2:
  apush rdi

.L3:
  mov byte [wchar_b], al    ; remember char that we delimited on

  mov rbx, rcx
  next

; ------------------------------------------------------------------------
; scan for terminatig zero byte

;       ( a1 --- a2 )

code 'scanz', scan_z        ; bug fix modifications by stephen ma
  xor rax, rax              ; were looking for binary zero.
  mov rdi, rbx              ; edi = string address
  lea rcx, [rax - 1]        ; ecx = -1 (effectively infinite byte count)
  repne scasb               ; scan for zero byte.
  lea rbx, [rdi - 1]        ; return the address of the null byte.
  next

; ========================================================================
