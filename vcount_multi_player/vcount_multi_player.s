        *= $2860

; os memory map
color0 = $2c4
color1 = $2c5
color2 = $2c6
color3 = $2c7
color4 = $2c8
hposp0 = $d000
hposp1 = $d001
hposp2 = $d002
hposp3 = $d003
colpf0 = $d016
colpf1 = $d017
colpf2 = $d018
colpf3 = $d019
colbak = $d01a
random = $d20a
wsync = $d40a
vcount = $d40b

; jumpman level storage
ls_coin_remain = $283e
ls_jmp_out_of_lives = $283f
ls_out_of_lives_ptr = $2840
ls_level_complete_ptr = $2844


; jumpman memory map

; scratch

src = $b4
index1 = $ce

; players 0 and 1 are reserved for jumpman and shadow, respectively

; player 2
p2active = $3058
p2datal = $305d
p2datah = $3062
p2height = $3067
p2x = $306c
p2y = $3071
p2frame = $3076

; player 3
p3active = $3059
p3datal = $305e
p3datah = $3063
p3height = $3068
p3x = $306d
p3y = $3072
p3frame = $3077

; combined missile player
p4active = $3055
p4datal = $305a
p4datah = $305f
p4height = $3064
p4x = $3069
p4y = $306e
p4frame = $3073

; bullets
m0state = $30a2
m0x = $30a6
m0y = $30aa

; status
jmalive = $30bd
jmstatus = $30be
lives_left = $30f0
getq2 = $41e0
bangsnd = $4974

; my vars
centerx = $80
centery = $70
gunstepinit = 6
mindelay = 3 * gunstepinit
gundata = $2e00

; actual players are on the top level, copies are below
vcount1 = 21
vcount2 = 38
vcount3 = 55
vcount4 = 72
vcount5 = 88
vcount6 = 104

; for 6 pixel height
roomba_height = roomba2 - roomba1
band1 = (2*vcount2) - 8
band2 = (2*vcount3) - 10
band3 = (2*vcount4) - 12
band4 = (2*vcount5) - 12
band5 = (2*vcount6) - 12

gameloop
        jsr $49d0
?gl1    jsr $4b00
        lda ls_coin_remain
        cmp #$00
        beq ?glexit
        lda vcount

        ; check if vcount is in layer 1 (between vcount1 and vcount2)
        cmp #vcount1
        bne ?v2

        ; do some housekeeping the first time through every frame
        lda #14
        sta colbak
        inc roombacounter

        ; set player location for band 1
        ldx #0
        jsr moveplayers
        jmp ?glcont

        ; check in layer 2 (between vcount2 and vcount3)
?v2     cmp #vcount2
        bne ?v3
        ; set player location for band 2
        ldx #2
        stx colbak
        jsr moveplayers
        jmp ?glcont

        ; check in layer 3 (between vcount3 and vcount4)
?v3     cmp #vcount3
        bne ?v4
        ; set player location for band 3
        ldx #4
        stx colbak
        jsr moveplayers
        jmp ?glcont

        ; check in layer 4 (between vcount4 and vcount5)
?v4     cmp #vcount4
        bne ?v5
        ; set player location for band 4
        ldx #6
        stx colbak
        jsr moveplayers
        jmp ?glcont

        ; check in layer 5 (between vcount5 and vcount6)
?v5     cmp #vcount5
        bne ?glcont
        ; set player location for band 5
        ldx #8
        stx colbak
        jsr moveplayers

?glcont lda jmstatus
?gl2    cmp #$08
        bcc ?gl1
        lda lives_left
        cmp #$ff
        bne gameloop
        jmp ls_jmp_out_of_lives
?glexit jmp (ls_level_complete_ptr)

playerinit
        lda #<roomba1
        sta p2datal
        sta p3datal
        lda #>roomba1
        sta p2datah
        sta p3datah
        lda #(roomba2 - roomba1)
        sta p2height
        sta p3height
        lda #56
        sta p2x
        lda #180
        sta p3x
        lda #36
        sta p2y
        sta p3y
        lda #1
        sta p2active
        sta p3active
        sta p3frame
        lda #2
        sta p2frame
        ;jsr testplayers_vertical
        lda #<roomba1
        sta src
        lda #>roomba1
        sta src+1
        ldx #9
?copyloop
        jsr copy_player_to_band
        dex
        bpl ?copyloop
        rts

; only move half the players every frame so it doesn't clog up the cycles
; and cause the next vcount test to be missed
moveplayers
        lda roombacounter
        and #1
        bne ?p3
        jsr moveplayer ; move p2, leave p3 where it is
        lda roombax,x
        sta hposp2
        inx
        lda roombax,x
        sta hposp3
        rts
?p3     lda roombax,x ; move p3, leave p2 where it is
        sta hposp2
        inx
        jsr moveplayer
        lda roombax,x
        sta hposp3
        rts
moveplayer ; player number in x
        clc
        lda roombax,x
        adc roombadx,x
        sta roombax,x
        cmp roombaminx,x
        bcs ?max
        lda #1
        sta roombadx,x
        bne ?cont
?max    cmp roombamaxx,x
        bcc ?cont
        lda #$ff
        sta roombadx,x
?cont   inc roombaframe,x
        lda roombaframe,x
        cmp #3
        bcc ?done
        lda #1
        sta roombaframe,x
?done   
;        rts

        lda #<roomba1
        sta src
        lda #>roomba1
        sta src+1

copy_player_to_band
        lda roombadest,x
        sta ?loop_smc+2
        lda roombay,x
        sta ?loop_smc+1
        lda roombaframe,x
        tay
        lda #0
        dey ; frame numbers start at 1
        beq ?start
?frame  clc
        adc p2height
        dey
        bne ?frame
        tay
?start  lda p2height
        sta index1
?loop   lda (src),y
?loop_smc sta $ff00
        inc ?loop_smc+1  ; won't ever cross page
        iny
        dec index1
        bne ?loop
        rts

testplayers_vertical
        lda #$ff
        sta $2800
        tay
        iny
?loop   sta $6600,y
        sta $6700,y
        iny
        bne ?loop
        rts

vbi1
        lda jmalive     ; check jumpman alive state
        cmp #$02        ; dead with birdies?
        bne alive       ; nope, continue
exit1   jmp $311b
alive   lda $2800       ; yep, dead
        cmp #$ff        ; is timer already reset?
        beq move        ; yep, move
        jsr playerinit
        lda #$ff
        sta $2800
move    lda p2x         ; restore original players for top of next frame
        sta hposp2
        lda p3x
        sta hposp3
        jmp $311b

roomba1 .byte $3c, $7e, $ff, $ff, $ff, $55
roomba2 .byte $3c, $7e, $ff, $ff, $ff, $aa
roombacounter .byte 0

; band data, 2 roombas per band
roombax .byte 100, 120, 80, 140, 60, 160, 70, 170, 60, 180
roombadx .byte 1, $ff, 1, $ff, 1, $ff, 1, $ff, 1, $ff
roombaminx .byte 50, 140, 50, 140, 50, 140, 50, 140, 50, 140,
roombamaxx .byte 110, 210, 110, 210, 110, 210, 110, 210, 110, 210, 
roombay .byte band1, band1, band2, band2, band3, band3, band4, band4, band5, band5
roombaframe .byte 2, 1, 1, 2, 2, 1, 1, 2, 2, 1
roombadest .byte $66, $67, $66, $67, $66, $67, $66, $67, $66, $67
