        *= $2860

; os memory map
rtclok = $12 ; rtclok+2 is incremented every vblank
vdslst = $200
color0 = $2c4
color1 = $2c5
color2 = $2c6
color3 = $2c7
color4 = $2c8
hposp0 = $d000
hposp1 = $d001
hposp2 = $d002
hposp3 = $d003
hposm0 = $d004
hposm1 = $d005
hposm2 = $d006
hposm3 = $d007
sizep0 = $d008
sizep1 = $d009
sizep2 = $d00a
sizep3 = $d00b
sizem0 = $d00c
colpm0 = $d012
colpm1 = $d013
colpm2 = $d014
colpm3 = $d015
colpf0 = $d016
colpf1 = $d017
colpf2 = $d018
colpf3 = $d019 ; also color of 5th player
colbak = $d01a
prior = $d01b
random = $d20a
wsync = $d40a
vcount = $d40b
nmien = $d40e

; jumpman level storage
ls_player2_color = $282c
ls_player3_color = $282d
ls_coin_remain = $283e
ls_jmp_out_of_lives = $283f
ls_out_of_lives_ptr = $2840
ls_level_complete_ptr = $2844


; jumpman memory map

gameplay_dl = $3c00
jm_pmbase = $6000
jm_pmbase_m = $6300
jm_pmbase_p0 = $6400
jm_pmbase_p1 = $6500
jm_pmbase_p2 = $6600
jm_pmbase_p3 = $6700

; jumpman constants
bot_vcount = 100

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

; collisions
jm_collide_m0pl = $3098
jm_collide_m1pl = $3099
jm_collide_m2pl = $309a
jm_collide_m3pl = $309b

; bullets
m0state = $30a2
m1state = $30a3
m2state = $30a4
m3state = $30a5
m0x = $30a6
m1x = $30a7
m2x = $30a8
m3x = $30a9
m0y = $30aa
m1y = $30ab
m2y = $30ac
m3y = $30ad

; status
jmalive = $30bd
jmstatus = $30be
lives_left = $30f0

; subroutines

getq2 = $41e0
bangsnd = $4974

; my vars
centerx = $80
centery = $70
gunstepinit = 6
mindelay = 3 * gunstepinit
gundata = $2e00

; my constants
roomba_height = roomba2 - roomba1


; gameloop is called for every new life, not just the first time the level
; scrolls into view.
gameloop
        jsr $49d0

        lda $2800       ; check DLI init flag to see if one-time level init
        cmp #$ff        ; stuff has already been run
        beq ?gl1
        jsr playerinit
        jsr dliinit
        lda #$ff        ; store flag indicating DLI is ready to go
        sta $2800

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
        bcs ?glcont     ; skip movement until next VBI

        jsr moveplayer
        inc roombamoveindex

?glcont lda jmstatus
?gl2    cmp #$08
        bcc ?gl1
        lda lives_left
        cmp #$ff
        bne gameloop
        jsr dlicleanup
        jmp ls_jmp_out_of_lives
?glexit jsr dlicleanup
        jmp (ls_level_complete_ptr)


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
        lda 0           ; initialize actual players offscreen
        sta p2x         ; multiplexed players will not be positioned until
        sta p3x         ; VBI starts
        lda roombay     ; actual players occupy top platform
        sta p2y         ; multiplexed players will be on lower platforms
        lda roombay+1
        sta p3y
        lda #1
        sta p2active
        sta p3active
        lda roombaframe
        sta p2frame
        lda roombaframe+1
        sta p2frame
        rts


; Set up new display list and DLI. Since we are doing this outside
; of the VBI, we have to wait until the vblank is just passed and make
; the changes while the DLIs are turned off.
dliinit
        lda rtclok+2
?1      cmp rtclok+2    ; wait till next tick, indicating VBI has just happened
        bne ?1
        lda #$40        ; disable DLI
        sta nmien
        ldx #<dli_line_list
        ldy #>dli_line_list
        jsr custom_dli
        lda #<dli
        sta vdslst
        lda #>dli
        sta vdslst+1

        ; don't know how long this has taken, so do the wait thing again
        lda rtclok+2
?2      cmp rtclok+2
        bne ?2
        lda #$c0        ; reenable DLI
        sta nmien
        rts

; Alter the gameplay display list to add DLIs on the specified mode lines.
; Note that there are 87 lines of ANTIC mode D in the display list. Indexes
; start at zero for the first mode D line and go through 86 for the bottom
; line. Anything outside this range will end the processing.

custom_dli
        stx ?smc_loop+1
        sty ?smc_loop+2
        ldx #0
?smc_loop
        lda $ffff,x
        cmp #87
        bcs ?exit
        tay
        beq ?1          ; don't adjust for LMS bytes if first line
        iny
        iny
?1      lda gameplay_dl+3,y ; +3 to skip the 3x8 blank lines at the top
        ora #$80
        sta gameplay_dl+3,y
        inx
        bne ?smc_loop
?exit   rts


; restore original display list and DLI
dlicleanup
        lda rtclok+2
?1      cmp rtclok+2    ; wait till next tick, indicating VBI has just happened
        bne ?1
        lda #$40        ; disable DLI
        sta nmien

        lda #$4d        ; restore LMS instruction on first display list line
        sta gameplay_dl+3
        lda #$0d
        ldy #85
?11     sta gameplay_dl+3,y
        dey
        bpl ?11

        lda #$65        ; restore default gameplay DLI
        sta vdslst
        lda #$3c
        sta vdslst+1

        ; don't know how long this has taken, so do the wait thing again
        lda rtclok+2
?2      cmp rtclok+2
        bne ?2
        lda #$c0        ; reenable DLI
        sta nmien
        rts


dli
        pha
        lda vcount
        cmp #bot_vcount
        bcc ?1
        jmp $3c66       ; jump into normal DLI one instruction after PHA
?1      ;sta colbak
        txa
        pha

        ldx bandindex

        ; Move the players so they will be multiplexed to the correct
        ; location for this band
        lda bandroomba,x
        tax
        lda roombax,x
        sta hposp2
        inx
        lda roombax,x
        sta hposp3
        inc bandindex
        pla
        tax
        pla
        rti


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


; multiplexed copies of players must handle their own image updates rather
; than use the jumpman convenience functions.
copy_player_to_band
        lda #<roomba1
        sta src
        lda #>roomba1
        sta src+1
        lda roombadest,x
        sta ?loop_smc+2
        lda roombay,x
        sta ?loop_smc+1

        ; adjust src to point to correct frame number. Note that frame
        ; numbers start from 1 because the jumpman player/missile convenience
        ; functions start from 1.
        lda roombaframe,x
        tay
        lda #0
        dey
        beq ?start
?frame  clc
        adc p2height
        dey
        bne ?frame
        tay

        ; copy routine starts here
?start  lda p2height
        sta index1
?loop   lda (src),y
?loop_smc sta $ff00
        inc ?loop_smc+1  ; won't ever cross page
        iny
        dec index1
        bne ?loop
        rts


vbi1
        lda #<dli       ; point to our DLI again because it always gets
        sta vdslst      ; wiped out by Jumpman DLI #3 at $3c9a
        lda #>dli
        sta vdslst+1

        lda $2800       ; check to see if DLI has been enabled
        cmp #$ff        ; before placing players
        beq ?show
        ldx #0
        ldy #0
        beq ?store
?show   ldx p2x
        ldy p3x
?store  stx hposp2      ; restore original players for top of next frame
        sty hposp3

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

; x coord min and max values in color clock position
roombaminx .byte 60, 138, 60, 157, 60, 146, 60, 138, 60, 138, 60, 138,
roombamaxx .byte 115, 190, 92, 190, 100, 190, 111, 190, 115, 190, 115, 190,

; y positions in scan line number
roombay .byte 36, 36, 68, 68, 100, 100, 132, 132, 164, 164, 196, 196
roombaframe .byte 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1
roombagroup .byte 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2
roombadest .byte $ff, $ff, $66, $67, $66, $67, $66, $67, $66, $67, $66, $67

bandindex .byte 0
bandroomba .byte 2, 4, 6, 8, 10
dli_line_list .byte 8,$18,$28,$38,$48,$ff
