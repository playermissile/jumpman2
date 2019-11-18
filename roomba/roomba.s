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
colpm0 = $d012
colpm1 = $d013
colpm2 = $d014
colpm3 = $d015
colpf0 = $d016
colpf1 = $d017
colpf2 = $d018
colpf3 = $d019
colbak = $d01a
random = $d20a
wsync = $d40a
vcount = $d40b

; jumpman level storage
ls_player2_color = $282c
ls_player3_color = $282d
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
vcount1 = 24
vcount2 = 40
vcount3 = 56
vcount4 = 72
vcount5 = 88
vcount6 = 104

; for 6 pixel height
roomba_height = roomba2 - roomba1
band1 = (2*vcount2) - 12
band2 = (2*vcount3) - 12
band3 = (2*vcount4) - 12
band4 = (2*vcount5) - 12
band5 = (2*vcount6) - 12

gameloop
        jsr $49d0
?gl1    jsr $4b00
        lda ls_coin_remain
        cmp #$00
        beq ?glexit

        ; till I find a better way to deal with the gameloop not running
        ; during the jumpman respawn sequence at $49d0, just don't run
        ; the vcount routine during that time. This causes players to be
        ; duplicated at their x pos all the way down the screen, so the
        ; vbi will set the players off screen during this time
        lda jmalive     ; Till I find a better way to 
        cmp #$02        ; dead with birdies?
        beq ?glcont

        ; roombamoveindex will get set to zero at the vertical blank which will
        ; trigger the player moving logic. One player is moved every time
        ; through the game loop, and because moving a single player only takes
        ; a few scan lines we will stay ahead of the vcount bands.
        ldx roombamoveindex
        cpx #(roombadx - roombax) ; number of roombas
        bcs ?glvcount   ; skip movement until next VBI

        jsr moveplayer
        inc roombamoveindex

?glvcount
        ; check the band index first before checking vcount, because VBI
        ; can occur between instructions and if bandindex is reset during
        ; VBI but the check happens like this:
        ;   lda vcount
        ;   cmp bandvcount,x
        ; the VCOUNT may still be a large number from last frame but the
        ; trigger vcount may have been reset
        ldx bandindex
        cpx #5
        bcs ?glcont

        ; check if we have passed the next vcount trigger line
        lda vcount
        cmp bandvcount,x
        bcc ?glcont

        ; yep, the vcount we are interested in has occurred, so move the
        ; players so they will be multiplexed to the correct location for
        ; this band
        lda bandroomba,x
        tax
        jsr show_players_in_band
        inc bandindex

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
        lda roombax
        sta p2x
        lda roombax+1
        sta p3x
        lda roombay
        sta p2y
        lda roombay+1
        sta p3y
        lda #1
        sta p2active
        sta p3active
        lda roombaframe
        sta p2frame
        lda roombaframe+1
        sta p2frame
        ;jsr testplayers_vertical
        lda #<roomba1
        sta src
        lda #>roomba1
        sta src+1
        ldx #9
?copyloop
        jsr fast_copy_player_to_band
        dex
        bpl ?copyloop
        rts

show_players_in_band
        ;stx colbak  ; debug: set background color to see DLI scan line
        lda roombax,x
        sta hposp2
        inx
        lda roombax,x
        sta hposp3
        rts

; move a third of the players every frame to reduce speed of roombas
moveplayer ; player number in x
        lda roombagroupindex ; only move when counter matches
        cmp roombagroup,x
        bne ?exit
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
        cpx #2          ; first 2 players are the actual players
        bcs copy_player_to_band
        lda roombax,x
        tay
        lda roombaframe,x
        cpx #1
        beq ?change_real_p3
?change_real_p2
        sta p2frame
        sty p2x
        rts
?change_real_p3
        sta p3frame
        sty p3x
?exit
        rts

copy_player_to_band
        lda #<roomba1
        sta src
        lda #>roomba1
        sta src+1

fast_copy_player_to_band
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
        lda #0          ; the DLI won't run during jumpman respawn, so move
        sta hposp2      ;  the real players off screen so they won't be
        sta hposp3      ;  shown repeated at same xpos all down the screen
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

        lda #0
        sta bandindex   ; reset vcount pointer to first DLI
        sta roombamoveindex ; start next frame with first roomba
        inc roombagroupindex ; check and reset roomba group to 0, 1, or 2
        lda roombagroupindex
        cmp #3
        bcc ?1
        lda #0
        sta roombagroupindex
?1      jmp $311b

roomba1 .byte $3c, $7e, $ff, $ff, $ff, $55
roomba2 .byte $3c, $7e, $ff, $ff, $ff, $aa
roombagroupindex .byte 0
roombamoveindex .byte 0

; band data, 2 roombas per band, 3 groups
roombax .byte 80, 135, 100, 160, 60, 146, 75, 160, 100, 140, 60, 180
roombadx .byte 1, $ff, 1, $ff, 1, $ff, 1, $ff, 1, $ff, 1, $ff
roombaminx .byte 60, 138, 60, 157, 60, 146, 60, 138, 60, 138, 60, 138,
roombamaxx .byte 115, 190, 92, 190, 100, 190, 111, 190, 115, 190, 115, 190,
roombay .byte 36, 36, band1, band1, band2, band2, band3, band3, band4, band4, band5, band5
roombaframe .byte 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1
roombagroup .byte 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2
roombadest .byte $ff, $ff, $66, $67, $66, $67, $66, $67, $66, $67, $66, $67

bandindex .byte 0
bandroomba .byte 2, 4, 6, 8, 10
bandvcount .byte vcount1, vcount2, vcount3, vcount4, vcount5, $ff
