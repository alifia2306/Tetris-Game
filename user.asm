;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Description: 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This file has 2 big jobs: 
;;; 1) It partitions USER memory for C programs
;;; 2) It ensures a LABEL called: main
;;;    will be the first function PennSim should jump
;;;    to when PennSim starts executing code.
;;;    NOTE: not a coincidence that we call our 
;;;    1st function in C language is: main ()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; 1) Setup USER Memory ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Declaration of Constants ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

USER_STACK_ADDR .UCONST x7FFF
USER_STACK_SIZE .UCONST x1000
USER_HEAP_SIZE  .UCONST x3000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; Data ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA

;;; Reserve space for the heap and the stack so that the assembler will not try
;;; to place data in these regions.

.ADDR x4000
USER_HEAP .BLKW x3000

.ADDR x7000            
USER_STACK .BLKW x1000

;;; Reserve space to store the user stack pointer so that it can be retrieved
;;; after a trap call.

.ADDR x2000
TEMP_USER_STACK_ADDR .BLKW x1

;;; The following directive sets things up so that subsequent user globals will
;;; be stored in the right place.

.ADDR x2001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; Code ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
.CODE
.ADDR x0000    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; 2) JUMP to MAIN subroutine ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
USER_START
    LC R6, USER_STACK_ADDR    ; initialize the stack pointer
    LEA R7, main
    JSRR R7                   ; invoke the main routine
END
    TRAP x25                  ; call TRAP_HALT