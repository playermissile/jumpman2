; weathervane.s, a jumpman level
; Copyright (c) 2019, Rob McMullen
; Licensed under the GPLv3

; OS variables

RANDOM = $d20a

; Jumpman variables

p4active = $3055 ; Combined missile-player active  — 0 is off, 1 is on
; p0 is jumpman, p1 is shadow
p2active = $3058 ; P2 active — 0 is off, 1 is on
p3active = $3059 

; addresses for image data tables. Players 0 and 1 are jumpman and shadow so they aren't used in normal levels
p4datal = $305a ; image data LB for the Combined Missile Player
p2datal = $305d ; image data LB for Player 2
p3datal = $305e ; image data LB for Player 3
p4datah = $305f ; image data HB for the Combined Missile Player
p2datah = $3062 ; image data HB for Player 2
p3datah = $3063 ; image data HB for Player 3

; 3064-3068 image data bytes per image. E.g. a typical PM graphic might be 8
; bytes tall. See 3073-7 for details.
p4height = $3064 ; image data bytes per image for the Combined Missile Player
p2height = $3067 ; image data bytes per image for Player 2
p3height = $3068 ; image data bytes per image for Player 3

; Horizontal positions in player coordinates, which is 32 color clocks greater
; than the pixel location
p4x = $3069 ; Horizontal position of combined-Missile Player
p0x = $306a ; Horizontal position of player 0 (always Jumpman) hosp0 -> D000 (X location of Jumpman; p/m coords)
p1x = $306b ; Horizontal position of player 1 hosp1 -> D001
p2x = $306c ; Horizontal position of player 2 hosp2 -> D002
p3x = $306d ; Horizontal position of player 3 hosp3 -> D003

; Vertical positions are in player coordinates, which are 16 
p4y = $306e;  Y position of the combined-Missile Player
p0y = $306f;  Y position of Jumpman; p/m coords. C6 = dead, c0 is value on lowest possible girder,
p1y = $3070;  Y position of the shadow, you don’t need to mess with this
p2y = $3071;  Y position of Player 2
p3y = $3072;  Y position of Player 3

; 3073-7 Set Player to a particular graphic from image data.

p4index = $3073 ; Set image data for the Combined-Missile Player
p0index = $3074 ; Set image data for Player 0 (Jumpman) — don’t do this!
p1index = $3075 ; Set image data for Player 1 (Shadow) — don’t do this!
p2index = $3076 ; Set image data for Player 2
p3index = $3077 ; Set image data for Player 3

m0active = $30a2 ; Missile 0 activated 1=enabled; 0=disabled
m1active = $30a3 ; Missile 1 activated
m2active = $30a4 ; Missile 2 activated
m3active = $30a5 ; Missile 3 activated
m0x = $30a6 ; Missile 0 X
m1x = $30a7 ; Missile 1 X
m2x = $30a8 ; Missile 2 X
m3x = $30a9 ; Missile 3 X
m0y = $30aa ; Missile 0 Y
m1y = $30ab ; Missile 1 Y
m2y = $30ac ; Missile 2 Y
m3y = $30ad ; Missile 3 Y
mheight = $30b6 ; missile height


jm_alive = $30bd ; 0 = alive, 1 = falling, 2 = dead


; useful routines
jm_exit_vbi = $311b


; variables

MISSILE_L = $20
MISSILE_R = $b0


*=$2900
; aou $eu



vbi1
        lda jm_alive
        cmp #2
        beq ?exit ; if dead, exit
        lda wind_dir
        cmp #$00
        bne ?cont ; already set up
        lda #$00
        sta m0xl
        sta m0xl+1
        sta m0xl+2
        sta m0xl+3
        sta mdelay
        sta mdelay+1
        sta mdelay+2
        sta mdelay+3
        lda #$0a
        sta wind_dir
?exit   jmp jm_exit_vbi


?cont
        ldx #$03

?loop
        lda mdelay,x
        beq ?movemissile ; zero delay means missile is moving
        dec mdelay,x
        bne ?nextmissile

        lda #MISSILE_R ; initialize missile X position to right side
        sta m0x,x
        lda #$0
        sta m0xl,x

        lda p0y ; initialize missile Y position to almost the player position
        and #$f0
        sta m0y,x

?movemissile
        lda wind_dir
        clc
        adc m0xl,x
        sta m0xl,x
        lda m0x,x
        adc #$0
        sta m0x,x

        lda wind_dir
        bmi ?checkleft
        lda m0x,x
        cmp #MISSILE_R
        bcc ?nextmissile
        bcs ?startdelay

?checkleft
        lda m0x,x
        cmp #MISSILE_L
        bcs ?nextmissile

?startdelay
        lda RANDOM
        and #$5f
        ora #$40
        sta mdelay,x

?nextmissile
        dex
        bpl ?loop
        bmi ?exit




wind_dir .byte $00  ; 1 - 7f right; 80 - ff left
m0xl   .byte $00, $00, $00, $00
mdelay .byte $00, $00, $00, $00

