;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;   OS - TRAP VECTOR TABLE   ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.OS
.CODE
.ADDR x8000
	; TRAP vector table
	JMP TRAP_GETC			; x00
	JMP TRAP_PUTC			; x01
	JMP TRAP_DRAW_PIXEL		; x02
	JMP TRAP_VIDEO_COLOR	; x03
	JMP TRAP_VIDEO_BOX		; x04
	JMP TRAP_TIMER			; x05
	JMP TRAP_PUTS			; x06

	OS_KBSR_ADDR .UCONST xFE00  ; ‘alias’ for keyboard status reg
	OS_KBDR_ADDR .UCONST xFE02  ; ‘alias’ for keyboard data reg
	OS_ADSR_ADDR .UCONST xFE04  ; 'alias' for ASCII display status reg 
    OS_ADDR_ADDR .UCONST xFE06  ; 'alias' for ASCII display data reg
	OS_TIMER_TSR .UCONST xFE08  ; 'alias' for timer status reg
	OS_TIMER_TIR .UCONST xFE0A  ; 'alias' for timer interval register 
	
	OS_VIDEO_NUM_COLS .UCONST #128 ; 'alias' for total number of display columns
	OS_VIDEO_NUM_ROWS .UCONST #124 ; 'alias' for total number of display rows
	
	BOX_LEN .UCONST #10				; 'alias' for box length
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; OS VIDEO MEMORY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.DATA
	.ADDR xC000	
OS_VIDEO_MEM .BLKW x3E00


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;   OS - TRAP IMPLEMENTATION   ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
.ADDR x8200
.FALIGN
	;; by default, return to usercode: PC=x0000
	CONST R7, #0   ; R7 = 0
	RTI            ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - none
;;; Outputs          - R0 = ASCII character from keyboard

.CODE
TRAP_GETC
   	LC R0, OS_KBSR_ADDR  ; R0 = address of keyboard status reg
   	LDR R0, R0, #0       ; R0 = value of keyboard status reg
   	BRzp TRAP_GETC       ; if R0[15]=1, data is waiting!
                             ; else, loop and check again...

   	; reaching here, means data is waiting in keyboard data reg

   	LC R0, OS_KBDR_ADDR  ; R0 = address of keyboard data reg
   	LDR R0, R0, #0       ; R0 = value of keyboard data reg
	RTI                  ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a single character out to ASCII display
;;; Inputs           - R0 = ASCII character from keyboard
;;; Outputs          - none

.CODE
TRAP_PUTC
	LC R1, OS_ADSR_ADDR  ; R1 = address of ASCII display status reg
    LDR R1, R1, #0       ; R1 = value of ASCII display status reg
    BRzp TRAP_PUTC       ; if R0[15]=1, console is ready to display data
	                         ; else, loop and check again
    ; reaching here means console is ready to display data
	
	LC R1, OS_ADDR_ADDR  ; R1 = address of ASCII display data reg
    STR R0, R1, #0       ; R0 = value to be displayed on ASCII display console
	RTI					 ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_PIXEL   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw point on video display
;;; Inputs           - R0 = row to draw on (y)
;;;                  - R1 = column to draw on (x)
;;;                  - R2 = color to draw with
;;; Outputs          - none

.CODE
TRAP_DRAW_PIXEL
	LEA R3, OS_VIDEO_MEM	  ; R3=start address of video memory
	LC  R4, OS_VIDEO_NUM_COLS ; R4=number of columns

	MUL R4, R0, R4		  ; R4= (row * NUM_COLS)
	ADD R4, R4, R1	 	  ; R4= (row * NUM_COLS) + col
	ADD R4, R4, R3		  ; Add the offset to the start of video memory
	STR R2, R4, #0		  ; Fill in the pixel with color from user (R2)
	RTI			  ; PC = R7 ; PSR[15]=0
	
	;; question, why is this a poorly written TRAP?  Does it protect video memory?
	;; the TRAP does not check the values of the rows and columns in the register,
	;; if it exceeds the total number of rows and columns available or if the 
    ;; the number is negative, we might access incorrent memory address	
	

;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_VIDEO_COLOR   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Set all pixels of VIDEO display to a certain color
;;; Inputs           - R0 = color to set all pixels to
;;; Outputs          - none

.CODE
TRAP_VIDEO_COLOR
	LEA R1, OS_VIDEO_MEM	  ; R1=start address of video memory
	LC  R2, OS_VIDEO_NUM_COLS ; R2=number of columns
	LC  R3, OS_VIDEO_NUM_ROWS ; R3=number of rows
;; Start with the bottom most (OS_VIDEO_NUM_COLS - 1 , OS_VIDEO_NUM_ROWS -1) element 
;; and keep marking in reverse order till we reach the first location (0, 0)
	CONST R4, #0 			  ; R4 = Video memory address
	ADD R5, R3, #-1			  ; Row iterator, R5 = last row index
VID_COLOR_LOOP
	ADD R6, R2, #-1			  ; Column iterator, R6 = last column index
VID_COLOR_NESTED_LOOP
	MUL R4, R5, R2		  ; R4= (row * NUM_COLS)
	ADD R4, R4, R6	 	  ; R4= (row * NUM_COLS) + col
	ADD R4, R4, R1		  ; Add the offset to the start of video memory
	STR R0, R4, #0		  ; Fill in the pixel with color from user (R0)
	
	ADD R6, R6, #-1		  ; Decrement column iterator R6
	BRzp VID_COLOR_NESTED_LOOP ; Continue while R6 >= 0 
	
	ADD R5, R5, #-1       ; Decrement row iterator R5
	BRzp VID_COLOR_LOOP   ; Continue while R5 >= 0
	RTI			  ; PC = R7 ; PSR[15]=0
	
;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_VIDEO_BOX   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Set a 10x10 box of pixels of VIDEO display to a certain color
;;; at input location
;;; Inputs           - R0 = color to set all pixels to
;;;                  - R1 = starting col location
;;;                  - R2 = starting row location
;;; Outputs          - none

.CODE
TRAP_VIDEO_BOX
	LEA R3, OS_VIDEO_MEM	  ; R3 = start address of video memory

	ADD R1, R1, #0			 ; Check if col number is zero or postive 
	BRn VID_BOX_OUT			 ; Return if col number is negative
	
	ADD R2, R2, #0			 ; Check if row number is zero or postive
	BRn VID_BOX_OUT			 ; Return if row number is negative
	
	LC  R4, OS_VIDEO_NUM_COLS ; R4 = Total number of cols
	ADD R5, R1, #9			  ; R5 = Last col location
	SUB R4, R4, R5			  ; Check if R5 < R4
	BRnz VID_BOX_OUT		  ; Return if R5 is out of bounds
	
	LC  R4, OS_VIDEO_NUM_ROWS ; R4 = Total number of rows
	ADD R5, R2, #9			  ; R5 = Last row location
	SUB R4, R4, R5			  ; Check if R5 < R4
	BRnz VID_BOX_OUT		  ; Return if R5 is out of bounds
	
	CONST R4, #0 			  ; R4 = Video memory address
	LC R5, BOX_LEN			  ; Row iterator, R5 = Length of box
	ADD R5, R5, #-1			  ; R5 = Last row offset
;; Start with the bottommost (x + 9, y + 9) location and keep marking 
;; in reverse order till we reach the starting location (x, y)
	
VID_BOX_OUTER_LOOP
	LC R6, BOX_LEN			 ; Column iterator, R6 = Length of box
	ADD R6, R6, -1			 ; R6 = Last column offset
	ADD R5, R5, R2			 ; Set row location, R5 = (y + row)
	
VID_BOX_NESTED_LOOP
	ADD R6, R6, R1		  ; Set col location, R6 = (x + col)
	
	LC  R4, OS_VIDEO_NUM_COLS ; Load total number of columns
	MUL R4, R4, R5		  ; R4 = (row * NUM_COLS)
	ADD R4, R4, R6	 	  ; R4 = (row * NUM_COLS) + col
	ADD R4, R4, R3		  ; Add the offset to the start of video memory
	STR R0, R4, #0		  ; Fill in the pixel with color from user (R0)
	
	ADD R6, R6, #-1       ; Next column location
	SUB R6, R6, R1        ; Number of columns left to mark in this row,
						  ; R6 = col - x
	BRzp VID_BOX_NESTED_LOOP ; Loop if columns are left
	
	ADD R5, R5, #-1		  ; Next row location
	SUB R5, R5, R2		  ; Number of rows left to mark, R5 = row - y
	BRzp VID_BOX_OUTER_LOOP ; Loop if rows are left
VID_BOX_OUT
	RTI			  			; PC = R7 ; PSR[15]=0

;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Use timer to wait for R0 ms
;;; Inputs           - R0 = time interval in milliseconds
;;; Outputs          - none
.CODE
TRAP_TIMER
  	LC R1, OS_TIMER_TIR  ; R1 = timer interval register
   	STR R0, R1, #0       ; R0 = time interval
	
CHECK_TIMER_STATUS
	LC R1, OS_TIMER_TSR 	; R1 = address of timer status reg
   	LDR R1, R1, #0       	; R1 = value of timer status reg
	BRzp CHECK_TIMER_STATUS ; if R1[15] = 1, timer has gone off
	
	LC R1, OS_TIMER_TSR 	; R1 = address of timer status reg
	CONST R2, #0
	STR R2, R1, #0 			; Clear timer status register
	RTI			  			; PC = R7 ; PSR[15]=0
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a single string out to ASCII display
;;; Inputs           - R0 = Address of String to display
;;; Outputs          - none

.CODE
TRAP_PUTS
    LC R1, OS_ADSR_ADDR  	; R1 = address of ASCII display status reg
    LDR R1, R1, #0       	; R1 = value of ASCII display status reg
    BRzp TRAP_PUTC       	; if R0[15]=1, console is ready to display data
	                        ; else, loop and check again

    ; reaching here means console is ready to display data
	LC R1, OS_ADDR_ADDR  	; R1 = address of ASCII display data reg
	ADD R2, R0, #0		; R2 = R0, address of string

DISPLAY_STR
	LDR R3, R2, #0		; R3 = value stored in R2;
	ADD R3, R3, #0		; Check if R3 is zero
	BRz TRAP_PUTS_OUT	; Return on hitting NULL charactar;
    STR R3, R1, #0       	; R0 = value to be displayed on ASCII display console
	ADD R2, R2, #1
	BRnzp DISPLAY_STR	; Continue until we hit NULL charactar;
TRAP_PUTS_OUT
	RTI					 ; PC = R7 ; PSR[15]=0