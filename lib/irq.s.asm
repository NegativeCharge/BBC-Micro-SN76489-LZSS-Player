.irq_initialized    EQUB 0

.irq_init
{
	php
	sei

    lda irq_initialized
    bne skip

    lda #0
    sta irq_initialized

    lda IRQ_VECTOR_LO
    sta old_irq_vector+1
    lda IRQ_VECTOR_HI
    sta old_irq_vector+2

    lda #<new_irq_vector
    sta IRQ_VECTOR_LO
    lda #>new_irq_vector
    sta IRQ_VECTOR_HI

	lda #%01111111                                  ; All interrupts off
	sta SHEILA_USER_VIA_R14_IER
	sta SHEILA_SYS_VIA_R14_IER
	lda #%01000000                                  ; Enable continuous interrupts for USER_VIA t1
    sta SHEILA_USER_VIA_R11_ACR
    sta SHEILA_SYS_VIA_R11_ACR
	lda #%00000001
	sta SHEILA_USER_VIA_R4_T1C_L
    sta SHEILA_USER_VIA_R5_T1C_H

	lda SHEILA_USER_VIA_R4_T2C_L                    ; Clear User VIA T2
	lda SHEILA_SYS_VIA_R4_T2C_L                     ; Clear Sys VIA T2

.skip
	cli
	plp
	rts
}

.irq_deinit
{
    ; Restore old interrupt vector
    lda old_irq_vector+1
    sta IRQ_VECTOR_LO
    lda old_irq_vector+2
    sta IRQ_VECTOR_HI            

    cli
    rts
}

.new_irq_vector
	lda SHEILA_USER_VIA_R13_IFR
	bmi USER_VIA

.NOT_USER_VIA
    lda SHEILA_SYS_VIA_R13_IFR
	bpl old_irq_vector
    
    and SHEILA_SYS_VIA_R14_IER
    and #%00100000                                  ; Changes A and V flag, but is ok in this case
	bne SYS_VIA_T2

.old_irq_vector
    jmp $ffff                                       ; Self-modified

.SYS_VIA_T2
s2latchlo=*+1
	lda #0
	sta SHEILA_SYS_VIA_R4_T2C_L
s2latchhi=*+1
	lda #0
	sta SHEILA_SYS_VIA_R5_T2C_H
	lda #%11111111
	sta SHEILA_SYS_VIA_R3_DDRA
s2writeval=*+1
	lda #%11011111
{
.invert
	beq irq_silent
	ora #%00001111
.irq_silent
	sta SHEILA_SYS_VIA_PORT_A
    lda #0
    sta SHEILA_SYS_VIA_PORT_B
	lda invert
	eor #%00100000
	sta invert
	lda #%00001000
	sta SHEILA_SYS_VIA_PORT_B

    lda %11111100
	rti
}

.USER_VIA
	and SHEILA_USER_VIA_R14_IER
    and #%01000000 
	bne USER_VIA_T1

.USER_VIA_T2
u2latchlo=*+1
	lda #0
	sta SHEILA_USER_VIA_R4_T2C_L
u2latchhi=*+1
	lda #0
	sta SHEILA_USER_VIA_R5_T2C_H
	lda #%11111111
	sta SHEILA_SYS_VIA_R3_DDRA
u2writeval=*+1
	lda #0
{
.invert
	beq irq_silent
	ora #%00001111
.irq_silent
	sta SHEILA_SYS_VIA_PORT_A
    lda #0
    sta SHEILA_SYS_VIA_PORT_B
	lda invert
	eor #%00100000
	sta invert
	lda #%00001000
	sta SHEILA_SYS_VIA_PORT_B

	lda %11111100
	rti
}

.USER_VIA_T1
	lda SHEILA_USER_VIA_R4_T1C_L                    ; Clear
	lda #%11111111
	sta SHEILA_SYS_VIA_R3_DDRA

u1writeval=*+1
{
	lda #%10011111
.invert
	beq irq_silent
	ora #%00001111
.irq_silent
	sta SHEILA_SYS_VIA_PORT_A
    lda #0
    sta SHEILA_SYS_VIA_PORT_B
	lda invert
	eor #%00100000
	sta invert
	lda #%00001000
	sta SHEILA_SYS_VIA_PORT_B
	
    lda %11111100
	rti
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait for next frame
;
.wait_frame
    lda #%01000000              					; Timer 1 mask bit
    bit SHEILA_SYS_VIA_R13_IFR
    bne processSysViaT1
    bne wait_frame

    lda #%00000010              					; V-Sync
    bit SHEILA_SYS_VIA_R13_IFR
    bne processVsync

    jmp wait_frame

.processVsync
    sta SHEILA_SYS_VIA_R13_IFR

IF SHOW_UI
IF SHOW_FX
    jsr update_fx_array
    jsr poll_fx
ENDIF
    jsr updateRowData
    jsr updateTicks
ENDIF
    jmp wait_frame

.processSysViaT1
    sta SHEILA_SYS_VIA_R13_IFR
    jsr play_frame

IF SHOW_UI
    jsr incrementRowCounter
    jsr updateProgressBar
ENDIF

IF CHECK_EOF
    lda eof_flag
    beq wait_frame
ELSE
    lda song_ptr + 1
    cmp #>song_end
    bne wait_frame
    lda song_ptr + 0
    cmp #<song_end
    bne wait_frame
ENDIF

	jmp reset
