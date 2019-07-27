        *= $2900

; os memory map
random = $d20a

; jumpman memory map
p2state = $3058
p2datal = $305d
p2datah = $3062
p2height = $3067
p2x = $306c
p2y = $3071
p2num = $3076

m0state = $30a2
m0x = $30a6
m0y = $30aa
jmalive = $30bd
jmstatus = $30be
getq2 = $41e0
bangsnd = $4974

; my vars
centerx = $80
centery = $70
gunstepinit = 6
mindelay = 3 * gunstepinit
gundata = $2e00

vbi1
        lda jmalive     ; check jumpman alive state
        cmp #$02        ; dead with birdies?
        bne cont1       ; nope, continue
        lda gunstep     ; yep, dead
        cmp #$ff        ; is timer already reset?
        beq exit1       ; yep, exit
        lda #$ff        ; init timer
        sta gunstep
        lda #0          ; move all missiles off screen
        sta active
        sta active+1
        sta active+2
        sta active+3
        sta m0x
        sta m0x+1
        sta m0x+2
        sta m0x+3
exit1   jmp $311b
cont1   lda gundir      ; check for first time init
        cmp #$ff
        bne cont2

        jsr timerini    ; do first time init
        lda #gunheight
        sta p2height    ; set gun sprite height
        lda #1
        sta p2state     ; activate gun sprite
        lda #<gundata   ; set pointer to gun data
        sta p2datal
        lda #>gundata
        sta p2datah
        lda #centerx    ; set gun x/y coords using offset
        sec             ; data for each animation frame
        sbc gunxoff
        sta p2x
        lda #centery
        sec
        sbc gunyoff
        sta p2y

cont2   dec timer       ; shot timer
        dec gunstep     ; only rotate gun every N frames
        bpl startloop
        lda #gunstepinit ; reset gun counter
        sta gunstep
        inc gundir      ; increment gun animation frame
        lda gundir
        cmp numlist
        bcc ?1
        lda #0
        sta gundir
?1      tay             ; y is direction of rotation, used as index into lists
        clc
        adc #1          ; set frame number of gun; note jumpman expects image list starting from #1
        sta p2num       
        lda #centerx    ; set gun x/y coords using offset
        sec             ; data for each animation frame. As above
        sbc gunxoff,y
        sta p2x
        lda #centery
        sec
        sbc gunyoff,y
        sta p2y

startloop
        ldx #$ff

loop    inx             ; x is shot number
        cpx numshot     ; check number of shots
        beq exit1
        lda active,x    ; is already active?
        bne moveshot    ; yes, jump to the routine to move the bullet
        lda timer       ; no, only allow a new shot when the timer reaches $ff
        bpl loop

        jsr timerini    ; new shot allowed! reset timer

        lda #$01        ; activate missile
        sta active,x
        sta m0state,x

        ; set up direction of shot by using current direction of gun to find dx
        ; and dy values. also set initial position of shot
        ldy gundir      ; reload y register because it's clobbered by the sound routine
        lda dxlolist,y
        sta dxlo,x
        sta posxlo,x
        lda dxhilist,y
        sta dxhi,x
        clc
        adc #centerx
        sta posxhi,x
        lda dylolist,y
        sta dylo,x
        sta posylo,x
        lda dyhilist,y
        sta dyhi,x
        clc
        adc #centery
        sta posyhi,x

        ; sound the gun
        stx scratch     ; save the X register because it's also clobbered
        lda #<bangsnd   ; by the sound routine
        sta $3040
        lda #>bangsnd
        sta $3041
        lda #$04
        jsr $32b0
        ldx scratch

        ; use 16 bit addition to move shots to get smooth movement for
        ; all angles. Only the high byte is used for the screen coordinate
moveshot
        clc
        lda posxlo,x
        adc dxlo,x
        sta posxlo,x
        lda posxhi,x
        adc dxhi,x
        sta posxhi,x
        sta m0x,x
        cmp #$10        ; check if off left or right edge of screen
        bcc recycle
        cmp #$e0
        bcs recycle

        clc
        lda posylo,x
        adc dylo,x
        sta posylo,x
        lda posyhi,x
        adc dyhi,x
        sta posyhi,x
        sta m0y,x
        cmp #$ce        ; check if off bottom (or top via wraparound)
        bcs recycle

        jmp loop        ; end of main bullet loop

recycle 
        lda #$00        ; mark bullet as inactive
        sta active,x
        sta m0x,x
        jmp loop

timerini
        lda random      ; delay between bullets is random value + a minimum value
        and #$0f
        adc #mindelay
        sta timer
        rts

scratch .byte 0
numshot .byte 4
timer   .byte 0
active  .byte 0, 0, 0, 0
gundir  .byte $ff
gunstep .byte gunstepinit
posxlo  .byte 0, 0, 0, 0
posxhi  .byte 0, 0, 0, 0
posylo  .byte 0, 0, 0, 0
posyhi  .byte 0, 0, 0, 0
dxlo    .byte 0, 0, 0, 0
dxhi    .byte 0, 0, 0, 0
dylo    .byte 0, 0, 0, 0
dyhi    .byte 0, 0, 0, 0

trigger_1pt                ; add 1 point
        LDA $30F5
        CLC
        ADC #1
        STA $30F5
        LDA $30F6
        ADC #$00
        STA $30F6
        LDA $30F7
        ADC #$00
        STA $30F7
        STX $2fff
        JSR $46E9
        LDX $2fff
        rts

trigger_10pt                ; add 10 points
        LDA $30F5
        CLC
        ADC #10
        STA $30F5
        LDA $30F6
        ADC #$00
        STA $30F6
        LDA $30F7
        ADC #$00
        STA $30F7
        STX $2fff
        JSR $46E9
        LDX $2fff
        rts

numlist .byte 32
dxlolist .byte 0,39,76,111,141,166,184,196,200,196,184,166,141,111,76,39,0,217,180,145,115,90,72,60,56,60,72,90,115,145,180,217
dxhilist .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
dylolist .byte 112,120,143,180,230,34,103,178,0,78,153,222,26,76,113,136,144,136,113,76,26,222,153,78,0,178,103,34,230,180,143,120
dyhilist .byte 254,254,254,254,254,255,255,255,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,255,255,255,254,254,254,254
gunxoff .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
gunyoff .byte 9,9,9,9,9,9,9,9,9,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,9,9,9,9,9,9,9,9


    *= $2e00
; generated player/missile data
gunheight = 16
rot00 .byte 136,136,136,136,216,216,80,80,80,80,112,32,0,0,0,0
rot01 .byte 64,68,68,76,72,72,72,88,88,80,112,96,0,0,0,0
rot02 .byte 0,48,50,38,36,108,72,72,88,80,112,32,0,0,0,0
rot03 .byte 0,8,24,16,48,32,98,102,92,88,112,32,0,0,0,0
rot04 .byte 0,8,12,24,48,48,98,103,94,92,112,32,0,0,0,0
rot05 .byte 0,0,12,28,24,48,32,97,67,78,124,48,0,0,0,0
rot06 .byte 0,0,2,14,28,56,48,96,67,79,126,56,0,0,0,0
rot07 .byte 0,0,0,2,6,30,56,112,64,64,127,63,0,0,0,0
rot08 .byte 0,0,0,0,3,15,62,120,64,64,120,62,15,3,0,0
rot09 .byte 0,0,0,0,63,127,64,64,112,56,30,6,2,0,0,0
rot10 .byte 0,0,0,0,56,126,79,67,96,48,56,28,14,2,0,0
rot11 .byte 0,0,0,0,48,124,78,67,97,32,48,24,28,12,0,0
rot12 .byte 0,0,0,0,32,112,92,94,103,98,48,48,24,12,8,0
rot13 .byte 0,0,0,0,32,112,88,92,102,98,32,48,16,24,8,0
rot14 .byte 0,0,0,0,32,112,80,88,72,72,108,36,38,50,48,0
rot15 .byte 0,0,0,0,96,112,80,88,88,72,72,72,76,68,68,64
rot16 .byte 0,0,0,0,32,112,80,80,80,80,216,216,136,136,136,136
rot17 .byte 0,0,0,0,6,14,10,26,26,18,18,18,50,34,34,2
rot18 .byte 0,0,0,0,4,14,10,26,18,18,54,36,100,76,12,0
rot19 .byte 0,0,0,0,4,14,26,58,102,70,4,12,8,24,16,0
rot20 .byte 0,0,0,0,4,14,58,122,230,70,12,12,24,48,16,0
rot21 .byte 0,0,0,0,12,62,114,194,134,4,12,24,56,48,0,0
rot22 .byte 0,0,0,0,28,126,242,194,6,12,28,56,112,64,0,0
rot23 .byte 0,0,0,0,252,254,2,2,14,28,120,96,64,0,0,0
rot24 .byte 0,0,0,0,192,240,124,30,2,2,30,124,240,192,0,0
rot25 .byte 0,0,0,64,96,120,28,14,2,2,254,252,0,0,0,0
rot26 .byte 0,0,64,112,56,28,12,6,194,242,126,28,0,0,0,0
rot27 .byte 0,0,48,56,24,12,4,134,194,114,62,12,0,0,0,0
rot28 .byte 0,16,48,24,12,12,70,230,122,58,14,4,0,0,0,0
rot29 .byte 0,16,24,8,12,4,70,102,58,26,14,4,0,0,0,0
rot30 .byte 0,12,76,100,36,54,18,18,26,10,14,4,0,0,0,0
rot31 .byte 2,34,34,50,18,18,18,26,26,10,14,6,0,0,0,0
