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

; jumpman level storage
ls_player2_color = $282c
ls_player3_color = $282d
ls_coin_remain = $283e
ls_jmp_out_of_lives = $283f
ls_out_of_lives_ptr = $2840
ls_level_complete_ptr = $2844


; jumpman memory map

jm_pmbase = $6000
jm_mmem = $6300
jm_p0mem = $6400
jm_p1mem = $6500
jm_p2mem = $6600
jm_p3mem = $6700

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
getq2 = $41e0
bangsnd = $4974

; local constants
top_vcount = 12
bot_vcount = 80
top_mmem = 20
bot_mmem = 200

; local vars



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
        beq ?gldone


        ; main game loop logic goes here


?gldone lda jmstatus
?gl2    cmp #$08
        bcc ?gl1
        lda lives_left
        cmp #$ff
        bne gameloop
        jmp ls_jmp_out_of_lives
?glexit jmp (ls_level_complete_ptr)


playerinit
        ldx #7         ; 10 copies
        ldy #top_mmem   ; start at top of visible playfield
?1      jsr copy_snowflakes
        dex
        bpl ?1
        rts


copy_snowflakes
        lda #$80
        sta jm_mmem,y
        lda #$20
        sta jm_mmem+2,y
        lda #$08
        sta jm_mmem+4,y
        lda #$02
        sta jm_mmem+6,y
        lda #0
        sta jm_mmem+1,y
        sta jm_mmem+3,y
        sta jm_mmem+5,y
        sta jm_mmem+7,y
        clc
        tya
        adc #20
        tay
        rts


; move snow down one line
snow_fall
        ldy #bot_mmem
?1      lda jm_mmem,y
        sta jm_mmem+1,y
        dey
        cpy #top_mmem-1
        bcs ?1
        rts

vbi1
        lda jmalive     ; check jumpman alive state
        cmp #$02        ; dead with birdies?
        bne alive       ; nope, continue
        lda #0          ; the DLI won't run during jumpman respawn, so move
        sta hposm0      ;  the real players off screen so they won't be
        sta hposm1      ;  shown repeated at same xpos all down the screen
        sta hposm2
        sta hposm3
exit1   jmp $311b
alive   lda $2800       ; check if already initialized
        cmp #$ff        ; already initialized = $ff
        beq ?step       ; yep, move
        jsr playerinit
        lda #$ff        ; store already initialized flag
        sta $2800

?step
        jsr snow_fall
        lda snow0x      ; restore positions for top of next frame
        sta hposm0
        lda snow1x
        sta hposm1
        lda snow2x
        sta hposm2
        lda snow3x
        sta hposm3

?1      jmp $311b


; replace normal vbi4 with this one that ignores missile collisions,
; since missiles are abused as snowflakes now.
vbi4
        lda $309e
        ora $309f
        and #$01
        cmp #$00
        beq ?1
        lda #$01
        sta $30bd
?1      jmp $311b


snow0x .byte $a8+4
snow1x .byte $80+4
snow2x .byte $58+4
snow3x .byte $30+4
