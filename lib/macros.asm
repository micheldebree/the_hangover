!let FIRST_VISIBLE_RASTERLINE = $33
!let LAST_VISIBLE_RASTERLINE = $fa
!let LAST_RASTERLINE = $137
!let DUMMY_WRITE_ADDR = $d02f
!let TRUE = 1
!let FALSE = 0

!macro basicStart(addr) {
* = $801

    !byte $0c,$08,$00,$00,$9e

!if (addr >= 10000) { !byte $30 + (addr/10000)%10 }
!if (addr >= 1000) { !byte $30 + (addr/1000)%10 }
!if (addr >= 100) { !byte $30 + (addr/100)%10 }
!if (addr >= 10) { !byte $30 + (addr/10)%10 }

    !byte $30 + addr % 10, 0, 0, 0
}

!macro setInterrupt(rasterline, address) {
  lda #<address
  sta $fffe
  lda #>address
  sta $ffff
  lda #(rasterline & $ff)
  sta $d012
  lda $d011
  !if (rasterline > $ff) {
    ora #%10000000
    sta $d011
  } else {
    and #%01111111
    sta $d011
  }
}

; waste a number of cycles
!macro wasteCycles(nrCycles) {

  !let left = nrCycles
  !let nrInc = Math.floor(nrCycles / 6)
  !if (nrCycles % 6 == 1) { !let nrInc = nrInc - 1 }
  !for i in range(nrInc) { inc DUMMY_WRITE_ADDR }
  !! left = left - nrInc * 6

  !let nrBit = Math.floor(left / 3)
  !if (left % 3 == 1) { !! nrBit = nrBit - 1 }
  !for i in range(nrBit) { bit $ea }
  !! left = left - nrBit * 3

  !let nrNop = Math.floor(left / 2)
  !for i in range(nrNop) { nop }
}

!macro stabilize() {
    lda #<stabilizerIrq
    sta $fffe
    lda #>stabilizerIrq
    sta $ffff
    inc $d012 ; next irq on next line
    asl $d019 ; ack interrupt
    tsx ; save stack pointer (return address for this irq)
    cli ; enable interrupts to stabelizerIrq can occur
    ; somewhere along these nops, the stabilizerIrq will
    ; take over, leaving 1 cycle jitter
    !for i in range(17) { nop }

  stabilizerIrq:
    txs ; restore stack pointer
    ldx #8
  waste:
    dex
    bne waste
    bit $ea ; waste 3 cycles
    lda $d012
    cmp $d012
    beq done ; waste one more cycle if no raster change yet
done:
}


!macro selectVicBank(bank) {
  ; 0 = $0000-$3fff
  ; 1 = $4000-$7fff (no rom chars)
  ; 2 = $8000-$bfff
  ; 3 = $c000=$ffff (no rom chars)
  lda $dd00
  and #%11111100
  ora #(bank ^ %11)
  sta $dd00
}
