; fload.s   - file load.  interpret forth sources from a file
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _var_ 'lsp', lsp, 0       ; fload nest stack pointer
  _var_ 'floads', floads, 0 ; number of nested floads (max = 5)

; ------------------------------------------------------------------------

  _var_ 'fd', fd, 0         ; file handle of file being floaded

  _var_ 'line#', line_num, 0 ; current line number of file
  _var_ 'flsz', fl_sz, 0     ; fload file size
  _var_ 'fladdr', fl_addr, 0 ; fload memory map address
  _var_ 'fl>in', fl_to_in, 0 ; pointer to current line of file

  _constant_ 'ktotal', k_total, 0 ; total of all floaded file sizes

; ------------------------------------------------------------------------
; abort if file didnt open (n1 = file handle or error)

;       ( n1 --- )

colon '?open', q_open
  xt z_greater              ; open ok ???
  xt q_exit
  xt cr                     ; display offending filename
  xt h_here
  xt count
  xt type
  xt true                   ; abort with error message
  xt p_abort_q
  db 17, ' : File Not Found'
  exit

; ------------------------------------------------------------------------
; push one item onto fload stack

;       ( n1 --- )

fl_push:
  mov rax, qword [lsp_b]    ; get fload stack address in eax
  mov qword [rax], rbx      ; push item n1 onto stack
  add qword [lsp_b], byte CELL
  apop rbx
  next

; ------------------------------------------------------------------------
; pop one item off fload stack

;       ( --- n1 )

fl_pop:
  sub qword [lsp_b], byte CELL
  mov rax, qword [lsp_b]
  apush rbx
  mov rbx, qword [rax]
  next

; ------------------------------------------------------------------------
; list of items to pop off fload stack on completion of a nested fload

pop_list:
  call do_variable

  dq line_num_b
  dq fl_sz_b
  dq fl_addr_b
  dq fl_to_in_b
  dq refill_b
  dq to_in_b
  dq fd_b
  dq num_tib_b
  dq tib_b
  dq 0

; ------------------------------------------------------------------------

restore_state:
  call nest
  xt pop_list               ; point to list of items to be restored

  xt do_begin               ; restore previous fload state
.L0:
  xt q_count                ; get next item to be restored
  xt q_dup
  xt q_while                ; while it is not zero
  bv .L1

  xt fl_pop                 ; pop item off fload stack and store in item
  xt swap
  xt store
  xt do_repeat
  bv .L0

.L1:
  xt drop
  exit

; ------------------------------------------------------------------------
; fload completed, restore previous fload state

end_fload:
  call nest

  xt fl_sz                  ; count total size of all floads
  xt p_plus_store_to
  dq k_total_b
  xt fl_sz                  ; unmap file we completed
  xt fl_addr
  xt sys_munmap
  xt fd                     ; close the file
  xt sys_close
  xt two_drop
  xt restore_state          ; restore previous fload status
  xt p_decr_to              ; decremet fload nest depth counter
  dq floads_b
  exit

; ------------------------------------------------------------------------
; aborts an fload - leaves line# of error intact

abort_fload:
  xt line_num               ; save line number we aborted on so endfload
  xt end_fload              ; doesnt 'restore' it
  xt p_store_to
  dq line_num_b
  exit

; ------------------------------------------------------------------------
; determine byte size of file

; this sorta belongs in file.f but we cant put it there because the kernel
; would then have to forward reference an extension! :)

;       ( fd --- size )

colon '?fl-size', q_fs
  xt two
  xt zero
  xt rot
  xt sys_lseek
  exit

; ------------------------------------------------------------------------
; mmap file fd with r/w perms n2 with mapping type n1

;       ( fd flags prot --- address size )

colon 'fmmap', f_mmap
  xt two_to_r
  xt dup
  xt q_fs
  xt tuck
  xt zero
  xt dash_rot
  xt two_r_to
  xt rot
  xt zero
  xt sys_mmap
  xt swap
  exit

; ------------------------------------------------------------------------
; list of items to save when nesting floads

push_list:
  call do_variable

  dq tib_b
  dq num_tib_b
  dq fd_b
  dq to_in_b
  dq refill_b
  dq fl_to_in_b
  dq fl_addr_b
  dq fl_sz_b
  dq line_num_b
  dq 0

; ------------------------------------------------------------------------
; push all above listed items onto fload stack

save_state:
  call nest

  xt push_list              ; point to list of items to be saved

  xt do_begin
.L0:
  xt q_count                ; get next item
  xt q_dup
  xt q_while                ; while its not zero
  bv .L1

  xt fetch                  ; fetch and push its contents to fload stak
  xt fl_push
  xt do_repeat
  bv .L0

.L1:
  xt drop
  exit

; ------------------------------------------------------------------------
; init for interpreting of next line of memory mapped file being floaded

colon 'flrefill', flrefill
  xt fl_addr                ; did we interpret the entire file?
  xt fl_sz
  xt plus
  xt fl_to_in
  xt equals
  xt do_if                  ; if so end floading of this file
  bv .L1
  xt end_fload              ; and restore previous files fload state
  exit
  xt do_then

.L1:
  xt p_incr_to              ; not done, increment current file line number
  dq line_num_b
  xt fl_to_in               ; set tib = address of next line to interpret
  xt dup
  xt p_store_to
  dq tib_b
  literal 1024              ; scan for eol on this line of source
  literal 0xa
  xt scan
  xt z_equals               ; coder needs a new enter key
  xt p_abort_q
  db 19, 'Fload Line Too Long'
  xt one_plus               ; point beyond the eol
  xt dup
  xt fl_to_in               ; calculate total length of current line
  xt minus
  xt p_store_to             ; set tib size = line length
  dq num_tib_b
  xt p_store_to             ; set address of next line to interpret
  dq fl_to_in_b
  xt p_off_to               ; set parse offset to start of current line
  dq to_in_b
  exit

; ------------------------------------------------------------------------
; fload file whose name is an ascii string

;     ( 0 0 a1 --- )

colon '(fload)', p_fload
  xt sys_open               ; attempt to open specified file
  xt dup                    ; abort if not open
  xt q_open

  xt dup                    ; map private, prot read
  xt two
  xt three
  xt f_mmap                 ; memory map file

  xt save_state             ; save state of previous fload if any
  literal flrefill          ; make fload-refil forths input refill
  xt p_store_to
  dq refill_b
  xt p_store_to             ; remember size of memory mapping
  dq fl_sz_b
  xt dup
  xt p_store_to             ; set address of files memory mapping
  dq fl_addr_b
  xt p_store_to             ; set this address as current file parse point
  dq fl_to_in_b
  xt p_store_to             ; save open file descriptor
  dq fd_b
  xt p_incr_to              ; count fload nest depth
  dq floads_b
  xt p_off_to               ; reset current line of file being interpreted
  dq line_num_b
  xt refill
  exit

; ------------------------------------------------------------------------
; intepret from a file

colon 'fload', fload
  xt floads                 ; max fload nest depth is 5 and thats too many
  literal 5
  xt equals
  xt p_abort_q
  db 22, 'Floads Nested Too Deep'
  xt zero                   ; file perms and flags
  xt dup
  xt bl_                    ; parse in file name
  xt word_
  xt h_here                 ; make file name asciiz
  xt count
  xt s_to_z
  xt p_fload
  exit

; =========================================================================
