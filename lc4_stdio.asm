;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Description: 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This file has 1 big job:
;;;
;;; It defines "wrapper" subroutines for the TRAPS
;;; in os.asm.  The purpose of which is to provide
;;; a standard way of passing arguments to and from 
;;; the TRAPS in os.asm
;;;
;;; NOTE: each time we add a trap to os.asm
;;; we must create a 'wrapper' in this file
;;; if we wish to call that trap from our C programs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TEMPS   .UCONST x4200 ; 'alias' for Address of temporary storage

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; WRAPPER SUBROUTINES FOLLOW ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
.CODE
.ADDR x0010    ;; we start after line 10, to preserve USER_START


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTC Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_putc

	;; prologue
	STR R7, R6, #-2	; save caller’s return address
	STR R5, R6, #-3	; save caller’s frame pointer
	ADD R6, R6, #-3 ; update stack pointer
	ADD R5, R6, #0	; update frame pointer
	; no local variables, so no need to allocate for them

	;; function body 

	; setup arguments for TRAP_PUTC:
	LDR R0, R5, #3	; copy param (c) from stack, into register R0
	TRAP x01        ; R0 has been set, so we can call TRAP_PUTC
	
	; TRAP_PUTC has no return value, so nothing to copy back to stack

	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_GETC Wrapper ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_getc
	;; prologue
	STR R7, R6, #-2	; save caller’s return address
	STR R5, R6, #-3	; save caller’s frame pointer
	ADD R6, R6, #-3 ; update stack pointer
	ADD R5, R6, #0	; update frame pointer

	;; function body 
	
	TRAP x00        ; we call TRAP_GETC
	ADD R7, R0, #0	; get character from register R0 and copy to R7

	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_VIDEO_COLOR Wrapper ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_video_color
	;; prologue
	STR R7, R6, #-2	; save caller’s return address
	STR R5, R6, #-3	; save caller’s frame pointer
	ADD R6, R6, #-3 ; update stack pointer
	ADD R5, R6, #0	; update frame pointer

	;; function body 
	
	ADD R6, R6, #-1 ; allocate space for saving R6
	LDR R0, R5, #3	; get color to be painted
	ADD R7, R5 #0	; copy R5 into R7
	STR R6, R5 #-1	; copy R6 on top of the stack
	LC R4, TEMPS	; Load Address into R4
	STR R7, R4, #0	; Store R7 into TEMPS[0]
	TRAP x03	; Call TRAP for Video_Color
	LC R4, TEMPS	; Load Address into R4
	LDR R7, R4, #0	; Restore R7 from TEMPS[0]
	ADD R5, R7 #0	; Restore R5 from R7
	LDR R6, R5 #-1	; Restore R6 from the stack

	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_VIDEO_BOX Wrapper ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_video_box
	;; prologue
	STR R7, R6, #-2	; save caller’s return address
	STR R5, R6, #-3	; save caller’s frame pointer
	ADD R6, R6, #-3 ; update stack pointer
	ADD R5, R6, #0	; update frame pointer

	;; function body 
	
	ADD R6, R6, #-1 ; allocate space for saving R6
	LDR R0, R5, #3	; get color to be painted
	LDR R1, R5, #4	; get total number of display columns
	LDR R2, R5, #5	; get total number of display rows
	ADD R7, R5 #0	; copy R5 into R7
	STR R6, R5 #-1	; copy R6 on top of the stack
	LC R4, TEMPS	; Load Address into R4
	STR R7, R4, #0	; Store R7 into TEMPS[0]
	TRAP x04	; Call TRAP for Video_Box
	LC R4, TEMPS	; Load Address into R4
	LDR R7, R4, #0	; Restore R7 from R4
	ADD R5, R7 #0	; Restore R5 from R7
	LDR R6, R5 #-1	; Restore R6 from the stack

	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTS Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_puts

	;; prologue
	STR R7, R6, #-2	; save caller’s return address
	STR R5, R6, #-3	; save caller’s frame pointer
	ADD R6, R6, #-3 ; update stack pointer
	ADD R5, R6, #0	; update frame pointer
	; no local variables, so no need to allocate for them

	;; function body 

	; setup arguments for TRAP_PUTS:
	LDR R0, R5, #3	; copy param (c) from stack, into register R0
	TRAP x06        ; R0 has been set, so we can call TRAP_PUTC
	
	; TRAP_PUTC has no return value, so nothing to copy back to stack

	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET