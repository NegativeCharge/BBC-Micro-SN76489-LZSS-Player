.binary
{
   php
   sec
   rol a            ;shift the msb out into carry while shifting in an extra index bit
.loop   
   pha              ;save the value on stack
   lda #'0'>>1
   rol a
   jsr OSWRCH       ;print character on screen
   pla              ;restore value
   asl a            ;shift msb out into carry
   bne loop         ;if msb was the extra index bit, a is now zero, otherwise continue loop
                    ;by this way all 8 bits of a are processed even if a=0
   plp
   rts
}

.move
{
    lda #31
    jsr OSWRCH
    txa
    jsr OSWRCH 
    tya
    jmp OSWRCH
}

.raster_on {
    pha
    lda     #$00+(3EOR7)
    sta     $FE21
    pla
    rts
}

.raster_off {
    pha
    lda     #$00+(0EOR7)
    sta     $FE21
    pla
    rts
}

.wait_for_vsync
{
    lda #19
    jmp OSBYTE
}