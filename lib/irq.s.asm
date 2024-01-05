.reentry 	EQUB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait for next frame
;
.wait_frame
    lda #%01000000              ; Timer 1 mask bit
    bit SHEILA_SYS_VIA_R13_IFR
    bne processSysViaT1

    lda #%00000010              ; V-Sync
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
    jsr updateProgressBar
ENDIF
    jmp wait_frame

.processSysViaT1
    sta SHEILA_SYS_VIA_R13_IFR

    lda reentry
	bne continue
	lda #1
	sta reentry

    jsr play_frame
IF SHOW_UI
    jsr incrementRowCounter
ENDIF

    lda #0
	sta reentry
    
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

.continue
    jmp wait_frame