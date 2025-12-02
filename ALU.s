        AREA   PROJECT, CODE, READONLY
        EXPORT main
        ENTRY

main
        ; Load 32-bit operand A: value -> R0
        LDR     R0, =value
        LDR     R0, [R0]

        ; Load 32-bit operand B: n -> R1
        LDR     R1, =n
        LDR     R1, [R1]

        ; Load opcode -> R2
        LDR     R2, =opcode
        LDR     R2, [R2]

        ; Default overflow_flag = 0 (R6)
        MOVS    R6, #0


; ------------ OPERATION SELECT ------------

        CMP     R2, #0
        BEQ     ADD

        CMP     R2, #1
        BEQ     SUB

        CMP     R2, #2
        BEQ     AND

        CMP     R2, #3
        BEQ     OR

        CMP     R2, #4
        BEQ     XOR

        CMP     R2, #5
        BEQ     NOT

        CMP     R2, #6
        BEQ     SHL

        CMP     R2, #7
        BEQ     SHR

        CMP     R2, #8
        BEQ     RSB

        CMP     R2, #9
        BEQ     MUL

        CMP     R2, #10
        BEQ     UDIV

        CMP     R2, #11
        BEQ     SDIV

        CMP     R2, #12
        BEQ     NEG

        CMP     R2, #13
        BEQ     EQ

        CMP     R2, #14
        BEQ     GT

        CMP     R2, #15
        BEQ     LT

        CMP     R2, #16
        BEQ     RBIT

        CMP     R2, #17
        BEQ     BOOTH_U      ; Booth unsigned 16x16

        CMP     R2, #18
        BEQ     BOOTH_S      ; Booth signed 16x16

        CMP     R2, #19
        BEQ     ROL

        CMP     R2, #20
        BEQ     ROR

        CMP     R2, #21
        BEQ     REV

        CMP     R2, #22
        BEQ     REV16

        CMP     R2, #23
        BEQ     REVSH

        CMP     R2, #24
        BEQ     NREST_U      ; Non-restoring unsigned 16x16

        CMP     R2, #25
        BEQ     NREST_S      ; Non-restoring signed 16x16

        CMP     R2, #26
        BEQ     SET_A_BIT

        CMP     R2, #27
        BEQ     CLEAR_A_BIT

        CMP     R2, #28
        BEQ     CHECK_A_BIT

        CMP     R2, #29
        BEQ     TOGGLE_A_BIT

        B       INVALID



; ------------ ARITHMETIC & LOGIC OPERATIONS ------------

ADD
        ADDS    R0, R0, R1
        BVC     OK_ADD
        MOVS    R6, #1
OK_ADD
        B       FINISH


SUB
        SUBS    R0, R0, R1
        BVC     OK_SUB
        MOVS    R6, #1
OK_SUB
        B       FINISH


AND
        ANDS    R0, R0, R1
        B       FINISH


OR
        ORRS    R0, R0, R1
        B       FINISH


XOR
        EORS    R0, R0, R1
        B       FINISH



; ------------ SPECIAL OPERATIONS ------------

NOT
        MVNS    R0, R0
        B       FINISH


SHL
        LSLS    R0, R0, R1
        B       FINISH


SHR
        LSRS    R0, R0, R1
        B       FINISH


RSB
        SUBS    R0, R1, R0
        BVC     OK_RSB
        MOVS    R6, #1
OK_RSB
        B       FINISH


MUL
        ; Normal hardware multiply (32x32 -> low 32 bits)
        MUL    R0, R0, R1
        B       FINISH


UDIV
        UDIV    R0, R0, R1
        B       FINISH


SDIV
        SDIV    R0, R0, R1
        B       FINISH


NEG
        RSBS    R0, R0, #0
        BVC     OK_NEG
        MOVS    R6, #1
OK_NEG
        B       FINISH



; ------------ COMPARISON OPERATIONS ------------

EQ
        CMP     R0, R1
        BNE     EQ_FALSE
        MOVS    R0, #1
        B       FINISH
EQ_FALSE
        MOVS    R0, #0
        B       FINISH


GT
        CMP     R0, R1
        BGT     GT_TRUE
        MOVS    R0, #0
        B       FINISH
GT_TRUE
        MOVS    R0, #1
        B       FINISH


LT
        CMP     R0, R1
        BLT     LT_TRUE
        MOVS    R0, #0
        B       FINISH
LT_TRUE
        MOVS    R0, #1
        B       FINISH



; ------------ BIT MANIPULATION: RBIT / ROL / ROR / REV* ------------

RBIT
        RBIT    R0, R0
        B       FINISH


ROL
        ; Rotate left: (value << n) | (value >> (32 - n))
        LSLS    R3, R0, R1          ; R3 = value << n
        RSBS    R12, R1, #32        ; R12 = 32 - n
        LSRS    R4, R0, R12         ; R4 = value >> (32 - n)
        ORRS    R0, R3, R4          ; R0 = ROL
        B       FINISH


ROR
        ROR     R0, R0, R1          ; rotate right by n bits
        B       FINISH


REV
        REV     R0, R0              ; reverse byte order in word
        B       FINISH


REV16
        REV16   R0, R0              ; reverse bytes in each halfword
        B       FINISH


REVSH
        REVSH   R0, R0              ; reverse low halfword + sign-extend
        B       FINISH



; ------------ BIT SET / CLEAR / CHECK / TOGGLE ------------

SET_A_BIT
        MOVS    R3, #1
        LSLS    R3, R3, R1          ; R3 = (1 << bit)
        ORRS    R0, R0, R3          ; value |= bit
        B       FINISH


CLEAR_A_BIT
        MOVS    R3, #1
        LSLS    R3, R3, R1          ; R3 = (1 << bit)
        MVNS    R3, R3              ; R3 = ~(1 << bit)
        ANDS    R0, R0, R3          ; value &= ~bit
        B       FINISH


CHECK_A_BIT
        MOVS    R3, #1
        LSLS    R3, R3, R1          ; R3 = (1 << bit)
        ANDS    R3, R0, R3          ; isolate that bit
        CMP     R3, #0
        BEQ     BIT_IS_CLEAR
        MOVS    R0, #1              ; bit = 1
        B       FINISH
BIT_IS_CLEAR
        MOVS    R0, #0              ; bit = 0
        B       FINISH


TOGGLE_A_BIT
        MOVS    R3, #1
        LSLS    R3, R3, R1          ; R3 = (1 << bit)
        EORS    R0, R0, R3          ; value ^= bit
        B       FINISH



; ------------ BOOTH MODE SELECT (CALL FUNCTION) ------------

; Opcode 17: Booth unsigned 16x16
BOOTH_U
        MOVS    R2, #0              ; mode = 0 (unsigned)
        BL      BOOTH               ; product in R0
        B       FINISH

; Opcode 18: Booth signed 16x16
BOOTH_S
        MOVS    R2, #1              ; mode = 1 (signed)
        BL      BOOTH               ; product in R0
        B       FINISH



; ------------ NON-RESTORING DIVISION SELECT (CALL FUNCTION) ------------

; Opcode 24: Non-restoring unsigned 16x16
NREST_U
        MOVS    R2, #0              ; mode = 0 (unsigned)
        BL      NONREST             ; quotient in R0
        B       FINISH

; Opcode 25: Non-restoring signed 16x16
NREST_S
        MOVS    R2, #1              ; mode = 1 (signed)
        BL      NONREST             ; quotient in R0
        B       FINISH



INVALID
        MOVS    R0, R0              ; no-op
        B       FINISH



; ------------ STORE RESULT + OVERFLOW FLAG ------------

FINISH
        ; Store result
        LDR     R3, =result
        STR     R0, [R3]

        ; Store overflow flag
        LDR     R3, =overflow_flag
        STR     R6, [R3]

STOP
        B       STOP



; ======================================================
;  BOOTH FUNCTION (16-bit x 16-bit Booth multiplication)
; ------------------------------------------------------
;  Inputs:
;    R0 = multiplicand (low 16 bits used)
;    R1 = multiplier  (low 16 bits used)
;    R2 = mode:
;         0 = unsigned 16x16
;         1 = signed 16x16
;  Output:
;    R0 = 32-bit product
; ======================================================

BOOTH
        ; Load MASK16 constant into R7
        LDR     R7, =MASK16
        LDR     R7, [R7]

        ; Mask to 16 bits
        ANDS    R0, R0, R7          ; multiplicand
        ANDS    R1, R1, R7          ; multiplier

        ; If signed mode, sign-extend both
        CMP     R2, #0
        BEQ     BOOTH_SETUP

        ; Signed: sign-extend 16->32 (for R0, R1)
        LSLS    R3, R0, #16
        ASRS    R0, R3, #16         ; R0 = signed 16

        LSLS    R3, R1, #16
        ASRS    R1, R3, #16         ; R1 = signed 16

BOOTH_SETUP
        ; A = 0, Q = R1 (multiplier), M = R0 (multiplicand)
        MOVS    R3, #0              ; A
        MOVS    R4, #0              ; Q_-1
        MOVS    R5, #16             ; count = 16

BOOTH_LOOP
        ; Q0 = LSB of Q (R1)
        MOVS    R12, R1
        ANDS    R12, R12, #1        ; R12 = Q0

        ; (Q0,Q_-1) = 0,1 -> A = A + M
        ; (Q0,Q_-1) = 1,0 -> A = A - M
        CMP     R12, #0
        BNE     B_Q0_IS_1

        ; Q0 == 0
        CMP     R4, #1
        BNE     B_NO_ADD_SUB
        ADDS    R3, R3, R0          ; A = A + M
        B       B_AFTER_ADD_SUB

B_Q0_IS_1
        ; Q0 == 1
        CMP     R4, #0
        BNE     B_NO_ADD_SUB
        SUBS    R3, R3, R0          ; A = A - M
        B       B_AFTER_ADD_SUB

B_NO_ADD_SUB
        ; No change to A
B_AFTER_ADD_SUB

        ; New Q_-1 = old Q0
        MOVS    R4, R12

        ; Take A0 before shifting
        MOVS    R7, R3
        ANDS    R7, R7, #1          ; A0

        ; Q = (Q >> 1) | (A0 << 31)
        LSRS    R1, R1, #1
        LSLS    R7, R7, #31
        ORRS    R1, R1, R7

        ; A = arithmetic right shift by 1
        ASRS    R3, R3, #1

        ; Next iteration
        SUBS    R5, R5, #1
        BNE     BOOTH_LOOP

        ; Combine A (high 16) and Q (low 16) as 32-bit result
        LSLS    R3, R3, #16         ; A_low16 -> bits 31..16

        LDR     R7, =MASK16
        LDR     R7, [R7]
        ANDS    R1, R1, R7          ; keep Q low 16 bits

        ORRS    R0, R3, R1          ; product in R0

        BX      LR



; ======================================================
;  NON-RESTORING DIVISION (16-bit x 16-bit)
; ------------------------------------------------------
;  Inputs:
;    R0 = dividend (low 16 bits used)
;    R1 = divisor  (low 16 bits used)
;    R2 = mode:
;         0 = unsigned 16x16
;         1 = signed 16x16
;  Output:
;    R0 = quotient (16-bit, sign-extended if signed)
; ======================================================

NONREST
        ; Load MASK16 into R12
        LDR     R12, =MASK16
        LDR     R12, [R12]

        ; Mask inputs to 16 bits
        ANDS    R0, R0, R12        ; dividend
        ANDS    R1, R1, R12        ; divisor

        ; If divisor is 0, just return (undefined, but safe)
        CMP     R1, #0
        BEQ     NR_EXIT

        ; Check mode: 0=unsigned, 1=signed
        CMP     R2, #0
        BEQ     NR_DO_UNSIGNED

        ; ---------- SIGNED MODE: take magnitudes ----------
        MOVS    R8, #0             ; signDividend
        MOVS    R9, #0             ; signDivisor

        ; Dividend sign (bit 15)
        TST     R0, #0x8000
        BEQ     NR_SD_OK
        MOVS    R8, #1
        MVNS    R0, R0
        ADDS    R0, R0, #1
        ANDS    R0, R0, R12
NR_SD_OK
        ; Divisor sign (bit 15)
        TST     R1, #0x8000
        BEQ     NR_SV_OK
        MOVS    R9, #1
        MVNS    R1, R1
        ADDS    R1, R1, #1
        ANDS    R1, R1, R12
NR_SV_OK

NR_DO_UNSIGNED
        ; ---------- CORE NON-RESTORING ALGORITHM ----------
        MOVS    R3, #0             ; A = 0
        MOVS    R4, #16            ; iterations

NR_LOOP
        ; msbQ = (Q >> 15) & 1
        MOVS    R7, R0
        LSLS    R7, R7, #16
        LSRS    R7, R7, #31        ; R7 = msb(Q)

        ; A = (A << 1) | msbQ
        LSLS    R3, R3, #1
        ORRS    R3, R3, R7

        ; Q = (Q << 1) & 0xFFFF
        LSLS    R0, R0, #1
        ANDS    R0, R0, R12

        ; if A >= 0 => A = A - M
        ; else      => A = A + M
        CMP     R3, #0
        BLT     NR_A_NEG
        SUBS    R3, R3, R1
        B       NR_AFTER_AS
NR_A_NEG
        ADDS    R3, R3, R1
NR_AFTER_AS

        ; if A >= 0 => Q |= 1
        ; else      => Q &= ~1
        CMP     R3, #0
        BLT     NR_A_NEG2
        ORRS    R0, R0, #1
        B       NR_AFTER_QBIT
NR_A_NEG2
        BICS    R0, R0, #1
NR_AFTER_QBIT

        SUBS    R4, R4, #1
        BNE     NR_LOOP

        ; Final correction: if A < 0 then A = A + M
        CMP     R3, #0
        BGE     NR_NO_CORR
        ADDS    R3, R3, R1
NR_NO_CORR

        ; Quotient now in R0 (positive magnitude)
        ; If unsigned mode, just return
        CMP     R2, #0
        BEQ     NR_UNSIGNED_EXIT

        ; ---------- SIGNED POST-PROCESSING ----------
        ; Quotient sign = signDividend XOR signDivisor
        EORS    R10, R8, R9
        CMP     R10, #0
        BEQ     NR_SIGN_OK

        ; Negative quotient: two's complement in 16 bits
        MVNS    R0, R0
        ADDS    R0, R0, #1
        ANDS    R0, R0, R12

NR_SIGN_OK
        ; Sign-extend 16->32
        LSLS    R11, R0, #16
        ASRS    R0, R11, #16
        BX      LR

NR_UNSIGNED_EXIT
NR_EXIT
        BX      LR



        AREA   data, DATA, READWRITE

value
        DCD     5           ; operand A

n
        DCD     3           ; operand B / shift / multiplier / divisor

; Example:
;  0  -> ADD
;  9  -> MUL
; 17  -> Booth unsigned 16x16
; 18  -> Booth signed 16x16
; 19  -> ROL
; 20  -> ROR
; 21  -> REV
; 22  -> REV16
; 23  -> REVSH
; 24  -> Non-restoring unsigned 16x16
; 25  -> Non-restoring signed 16x16
; 26  -> SET_A_BIT
; 27  -> CLEAR_A_BIT
; 28  -> CHECK_A_BIT
; 29  -> TOGGLE_A_BIT
opcode
        DCD     0           ; change to test different operations

result
        DCD     0

overflow_flag
        DCD     0

MASK16
        DCD     0x0000FFFF

        END
