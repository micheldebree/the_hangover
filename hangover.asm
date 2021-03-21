!let startline = $32      ; raster interrupt occurs at this rasterline
; .const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
; .var picture = LoadBinary("arnie.kla", KOALA_TEMPLATE)
; .var music = LoadSid("terminator.sid")

!include "lib/macros.asm"
!use "lib/sid" as sid
!use "lib/koala" as koala
!use "lib/spd" as spd
!use "lib/bytes" as bytes
!use "lib/debug" as debug

!let music = sid("hangover.sid")
!let pic = koala("hangover.kla")
!let sprites = spd("mysprites.spd")

* = $0801

+basicStart(start)

start:
        sei             ; Turn off interrupts
        jsr $ff81       ; ROM Kernal function to clear the screen
        lda #%00110101
        sta $01         ; Turn off Kernal ROM

        lda #$7f
        sta $dc0d      ; no timer IRQs
        lda $dc0d      ; acknowledge CIA interrupts

        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb      ; dummy NMI (Non Maskable Interupt) to avoid crashing due to RESTORE

        lda #$38
        sta $d018
        lda #$d8
        sta $d016
        lda #$3b
        sta $d011
        lda #0
        sta $d020
        jsr music.init
        ; lda pic.backgroundColor
        lda #0
        sta $d021
        ldx #0
loop:
        !for i in range(4) {
          lda i * $100 + colorRam,x
          sta i * $100 + $d800,x
        }
        inx
        bne loop

; sprites

        lda #$ff
        sta $d015
        lda #%11100000
        sta $d010
        !for i in range(8) {
          lda #spriteData/64 + i
          sta screenRam + $03f8 + i
          lda #152-8 + (i * 24)
          sta $d000 + 2 * i
          lda #190
          sta $d001 + 2 * i
          lda #1
          sta $d027 + i
        }

 ; configure the rasterline at which the raster interrupt request should occur
        lda #startline
        sta $d012       ; set the lowest 8 bits of the irq rasterline

        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff   ; Setup the raster interrupt pointer to point to our own code.

        lda #$01
        sta $d01a   ; Enable raster interrupts and turn interrupts back on
        cli

        jmp *       ; Do nothing and let the interrupt do all the work.

irq:
        lda #$ff
        sta $d019 ; acknowledge interrupt
        jsr music.play
nmi:
        rti

!align 64

spriteData:
!for i in range(sprites.numSprites) {
  !byte sprites.data[i]
}
!! debug.log("Sprites end at ", bytes.hex(*)) 
!! debug.log(($0c00 - *) /64, " sprites left")

* = $0c00 ;- $1000
screenRam:
!byte pic.screenRam

* = $1c00 ;- $2000
colorRam:
!byte pic.colorRam

* = $2000 ;- $4000
!byte pic.bitmap

* = music.location
!byte music.data
