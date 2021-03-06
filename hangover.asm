!include "lib/macros.asm"
!use "lib/sid" as sid
!use "lib/koala" as koala
!use "lib/spritepad" as spritepad
!use "lib/bytes" as bytes
!use "lib/debug" as debug
!use "lib/sines" as sines

!let music = sid("hangover.sid")
!let pic = koala("hangover.kla")
!let spriteFile = spritepad.loadV1("titles.spd")

!let sineMask = %01111111
!let titleY = [174, 200, 226] ; y locations for title lines
!let initD010 = $ff
!let initX = 250

!let zp = { ; zero page adresses to use as local variables
  a: $fb,
  b: $fc
}

* = $0801

+basicStart(setup)

setup: {
    sei             ; Turn off interrupts
    lda #%00110101
    sta $01         ; Turn off Kernal ROM

    lda #$7f
    sta $dc0d      ; no timer IRQs
    lda $dc0d      ; acknowledge CIA interrupts

    lda #<irq::nmi
    sta $fffa
    lda #>irq::nmi
    sta $fffb      ; dummy NMI (Non Maskable Interupt) to avoid crashing due to RESTORE

    +vic::selectBank(vicBase / $4000)
    +vic::setMemoryPointers(vicBase::bitmap - vicBase, vicBase::screenRam - vicBase)
    +vic::setScreenControl1(0, 1, TRUE, TRUE, FALSE, 0) 
    +vic::setScreenControl2(0, 1, TRUE)

    lda #0
    sta $d020
    sta $d021
    jsr music.init
    ldx #0

loop:
    !for i in range(4) { ; move color ram
        lda i * $100 + colorRam,x
        sta i * $100 + $d800,x
    }
    inx
    bne loop

; sprites

    lda #$ff
    sta $d015
    lda #initD010
    sta $d010

    ldx #1
    lda #initX
    !for i in range(8) { ; setup sprites
        sta $d000 + 2 * i
        stx $d027 + i
    }
    lda #titleY[0] - 16
    sta $d012

    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff   ; Setup the raster interrupt pointer to point to our own code.

    lda #$01
    sta $d01a   ; Enable raster interrupts and turn interrupts back on
    cli

    jmp *       ; Do nothing and let the interrupt do all the work.
}

irq: {

!macro setupSprites(lineNr) { ; apply calculated sprite properties
    lda #titleY[lineNr] - 5

wait:
    cmp $d012
    bne wait

    ldy #titleY[lineNr]
    !for i in range(8) {
        lda #vicBase::spritesData / 64 + lineNr * 8 + i
        sta vicBase::screenRam + $03f8 + i
        sty $d001 + 2 *i
        lda spriteCalc::xCoordinates + 8 * lineNr + i
        sta $d000 + 2 * i
    }
    lda spriteCalc::D010 + lineNr
    sta $d010
}

!macro moveSprites(lineNr) { ; calculate sprite properties

!let x_offset = zp.a
!let hi_bit = zp.b

    ldx sine::index + lineNr
    ldy #0
    sty x_offset
    sty hi_bit

set_sprite_x:
    lsr hi_bit
    lda sine::lowBytes,x
    clc
    adc x_offset
    sta spriteCalc::xCoordinates + 8 * lineNr,y
    lda sine::hiBytes,x
    adc #0
    beq no_overflow
    lda hi_bit
    ora #%10000000
    sta hi_bit

no_overflow:
    lda x_offset
    clc
    adc #24
    sta x_offset
    iny
    cpy #8
    bmi set_sprite_x
    lda sine::index + lineNr
    clc

!let sine_speed = * + 1
    adc #0
    and #sineMask
    sta sine::index + lineNr
    cmp #sineMask / 2
    bne no_stop
    lda #0
    sta sine_speed
    sta after_delay + 1

no_stop:
    lda hi_bit
    sta spriteCalc::D010 + lineNr
    dec sine::delay + lineNr
    bne done

after_delay:
    lda #1
    sta sine_speed

done:
}

    +setupSprites(0);
    jsr fuzz
    +setupSprites(1);
    +setupSprites(2);
    +moveSprites(0);
    +moveSprites(1);
    +moveSprites(2);
    jsr music.play
    asl $d019

nmi:
    rti
}

fuzz: { ; distort The Hangover title sprites

height:
    ldx #0
    cpx #0
    beq skip

offset:
    ldy #0

loop:
    !for i in range(8) {
        lda music.location,y
        and #3
        adc $d000 + 2 * i
        sta $d000 + 2 * i
    }
    iny
    dex
    bne loop
    inc offset+1
    lda offset+1

random:
    cmp #$40
    bne exit
    lda #0
    sta height + 1
    sta offset + 1

random2:
    lda setup
    sta random + 1
    inc random2 + 1
    jmp exit

skip:
    dec wait
    bne exit
    lda #7
    sta height + 1

exit:
    rts

wait:
    !byte $c0,0

}

spriteCalc: { ; calculated sprite properties
xCoordinates:
    !fill 3 * 8, initX

D010:
    !fill 3, initD010
}

sine: { ; sine movement data

index:
    !fill 3, 0
delay:
    !byte $40+1, $40+$10, $40+$40

!let sine = sines.sine01(341, 200, sineMask + 1)

!align $0100

lowBytes:
    !byte bytes.loBytes(sine)

hiBytes:
    !byte bytes.hiBytes(sine)

; +logRange("Sine", lowBytes)

}

* = music.location

    !byte music.data
    ; +logRange("Music", music.location)

!align $0100

colorRam:
    !byte pic.colorRam
    ; +logRange("Color RAM", colorRam)

* = $4000

vicBase: {

bitmap:
    !byte pic.bitmap

!align $0400
screenRam:
    !byte pic.screenRam

!align 64
spritesData:
    !byte spriteFile.data
    ; +logRange("VIC data", spritesData)

; !! debug.log(($8000 - *) /64, " sprites left")
}
