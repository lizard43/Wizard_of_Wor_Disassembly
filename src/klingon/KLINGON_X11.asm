; KLINGON_X11.asm
;==============================================================================
; Wizard of Wor - Klingon X11 foreign-language ROM
;==============================================================================
;
; Compact language-local speech records. Pointer and phrase tables stay at
; the standard X11 addresses $CD8D/$CE35.
;
; PA1 is inserted before M for MAME 0.289 SC-01 stability.
;==============================================================================

        NOLIST
        LIST
        ORG     $C000

K_HDR:
        DW      K_PTRS
        DW      K_PHR
        DB      $10,$20,$30,$40,$70,$50,$00
        DW      K_APOS

;==============================================================================
; KLINGON LOCALIZED DISPLAY TEXT - 23 records
;
; Display encoding:
;   $40 = space (resident WoW convention)
;   $62 = apostrophe via X11 alternate glyph 0
;   $63 = lowercase q via X11 alternate glyph 1
;
; The apostrophe is a Klingon consonant and q/Q are distinct letters. All other
; letters use the resident uppercase character shapes. Every character byte stays
; at or above $30, so the original length-record scanner remains valid.
;==============================================================================

; Text $01: INSERT COIN
; tlhIngan Hol: Huch yIlan
; The four blank cells on each side prevent the attract-screen eraser from
; leaving glyphs behind while preserving the original 18-byte record footprint.
K_T01:
        DB      $12,$40,$40,$40,$40,$48,$55,$43,$48,$40,$59,$49
        DB      $4C,$41,$4E,$40,$40,$40,$40

; Text $02: HIGH SCORES
; tlhIngan Hol: mIvwa'mey nIv
K_T02:
        DB      $0D,$4D,$49,$56,$57,$41,$62,$4D,$45,$59,$40,$4E
        DB      $49,$56

; Text $03: PRESS ONE PLAYER BUTTON
; tlhIngan Hol: wa' QujwI'vaD leQ yI'uy
K_T03:
        DB      $17,$57,$41,$62,$40,$51,$55,$4A,$57,$49,$62,$56
        DB      $41,$44,$40,$4C,$45,$51,$40,$59,$49,$62,$55,$59

; Text $04: PRESS TWO PLAYER BUTTON
; tlhIngan Hol: cha' QujwI'vaD leQ yI'uy
K_T04:
        DB      $18,$43,$48,$41,$62,$40,$51,$55,$4A,$57,$49,$62
        DB      $56,$41,$44,$40,$4C,$45,$51,$40,$59,$49,$62,$55
        DB      $59

; Text $05: OR
; tlhIngan Hol: ghap
K_T05:
        DB      $04,$47,$48,$41,$50

; Text $06: DEPOSIT ADDITIONAL COIN
; tlhIngan Hol: latlh Huch jengva' yIlan
K_T06:
        DB      $18,$4C,$41,$54,$4C,$48,$40,$48,$55,$43,$48,$40
        DB      $4A,$45,$4E,$47,$56,$41,$62,$40,$59,$49,$4C,$41
        DB      $4E

; Text $07: FOR TWO PLAYER GAME
; tlhIngan Hol: cha' QujwI' Quj
K_T07:
        DB      $0F,$43,$48,$41,$62,$40,$51,$55,$4A,$57,$49,$62
        DB      $40,$51,$55,$4A

; Text $08: POINTS
; tlhIngan Hol: mIvwa'mey
K_T08:
        DB      $09,$4D,$49,$56,$57,$41,$62,$4D,$45,$59

; Text $09: BONUS PLAYER
; tlhIngan Hol: latlh QujwI'
K_T09:
        DB      $0C,$4C,$41,$54,$4C,$48,$40,$51,$55,$4A,$57,$49
        DB      $62

; Text $0A: WAIT FOR INSTRUCTIONS
; tlhIngan Hol: ra'lu' 'e' yIloS
K_T0A:
        DB      $10,$52,$41,$62,$4C,$55,$62,$40,$62,$45,$62,$40
        DB      $59,$49,$4C,$4F,$53

; Text $0B: INVISIBLE MONSTERS IN THE MAZE
; tlhIngan Hol: chen'ongDaq tlhapraghmey So'lu'
K_T0B:
        DB      $1F,$43,$48,$45,$4E,$62,$4F,$4E,$47,$44,$41,$63
        DB      $40,$54,$4C,$48,$41,$50,$52,$41,$47,$48,$4D,$45
        DB      $59,$40,$53,$4F,$62,$4C,$55,$62

; Text $0C: ARE LOCATED USING THE RADAR SCREEN
; tlhIngan Hol: tlhapraghmey SammeH HotlhwI' lo'lu'
K_T0C:
        DB      $23,$54,$4C,$48,$41,$50,$52,$41,$47,$48,$4D,$45
        DB      $59,$40,$53,$41,$4D,$4D,$45,$48,$40,$48,$4F,$54
        DB      $4C,$48,$57,$49,$62,$40,$4C,$4F,$62,$4C,$55,$62

; Text $0D: MONSTERS BECOME VISIBLE WHEN ENTERING
; tlhIngan Hol: tlhapraghmey leghlu'choH
K_T0D:
        DB      $18,$54,$4C,$48,$41,$50,$52,$41,$47,$48,$4D,$45
        DB      $59,$40,$4C,$45,$47,$48,$4C,$55,$62,$43,$48,$4F
        DB      $48

; Text $0E: THE SAME MAZE CORRIDOR AS THE PLAYER
; tlhIngan Hol: QujwI' chob lu'elDI'
K_T0E:
        DB      $14,$51,$55,$4A,$57,$49,$62,$40,$43,$48,$4F,$42
        DB      $40,$4C,$55,$62,$45,$4C,$44,$49,$62

; Text $0F: GET READY
; tlhIngan Hol: yIghuH
K_T0F:
        DB      $06,$59,$49,$47,$48,$55,$48

; Text $10: RADAR
; tlhIngan Hol: HotlhwI'
K_T10:
        DB      $08,$48,$4F,$54,$4C,$48,$57,$49,$62

; Text $11: ESCAPED
; tlhIngan Hol: narghpu'
K_T11:
        DB      $08,$4E,$41,$52,$47,$48,$50,$55,$62

; Text $12: CREDITS
; tlhIngan Hol: Huch
K_T12:
        DB      $04,$48,$55,$43,$48

; Text $13: DUNGEON
; tlhIngan Hol: bIghHa'
K_T13:
        DB      $07,$42,$49,$47,$48,$48,$41,$62

; Text $14: WORLORD DUNGEON
; tlhIngan Hol: SuvwI' joH bIghHa'
K_T14:
        DB      $12,$53,$55,$56,$57,$49,$62,$40,$4A,$4F,$48,$40
        DB      $42,$49,$47,$48,$48,$41,$62

; Text $15: THE ARENA
; tlhIngan Hol: SuvmeH Daq
K_T15:
        DB      $0A,$53,$55,$56,$4D,$45,$48,$40,$44,$41,$63

; Text $16: THE PIT
; tlhIngan Hol: QemjIq
K_T16:
        DB      $06,$51,$45,$4D,$4A,$49,$63

; Text $17: OR FOR ADDITIONAL WORRIORS
; tlhIngan Hol: qoj latlh SuvwI'pu'vaD
K_T17:
        DB      $16,$63,$4F,$4A,$40,$4C,$41,$54,$4C,$48,$40,$53
        DB      $55,$56,$57,$49,$62,$50,$55,$62,$56,$41,$44

; Erased text-area remainder through $C1D0.
K_TFILL:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

K_ALIGN:
        DB      $00

; X11 alternate glyph 0 ($62): apostrophe
K_APOS:
        DB      $18,$18,$10,$20,$00,$00,$00,$00,$00,$00

; X11 alternate glyph 1 ($63): lowercase q
K_LQ:
        DB      $00,$00,$3C,$66,$66,$66,$3E,$06,$06,$04

; Remaining alternate-font bytes through $C1FF.
K_AFILL:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF

;==============================================================================
; KLINGON SPEECH FRAGMENTS
;
; Compact records; no fixed-slot padding. $00-$4E follow the resident WoW
; fragment boundary cadence. $50-$52 are helpers; $4F and $53 are null.
;==============================================================================

; $00 Worluk yIHoH. cha'logh mIvwa' DaSuq.
K_F00:
        DB      $24
        DB      $2D,$26,$2B,$18,$28,$19,$03,$29,$27,$1B,$26,$1B
        DB      $3E,$2A,$10,$15,$03,$18,$26,$1C,$1B,$03,$3E,$0C
        DB      $27,$0F,$2D,$15,$03,$1E,$15,$11,$28,$19,$3E,$03

; $01 bIHoSghajqu'chugh, qamevmoH jIH.
K_F01:
        DB      $24
        DB      $0E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19,$28
        DB      $03,$2A,$10,$28,$1C,$1B,$03,$19,$15,$3E,$0C,$3B
        DB      $0F,$3E,$0C,$26,$1B,$03,$1E,$1A,$27,$1B,$3E,$03

; $02 Wor bIghHa'mey.
K_F02:
        DB      $0E
        DB      $2D,$26,$2B,$0E,$27,$1C,$1B,$15,$3E,$0C,$3B,$29
        DB      $3E,$3E

; $03 jIH.
K_F03:
        DB      $05
        DB      $1E,$1A,$27,$1B,$3E

; $04 Wor 'IDnar pIn.
K_F04:
        DB      $0E
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15,$2B,$03,$25,$27
        DB      $0D,$3E

; $05 DuchopDI' ghumeywIj, bIjor.
K_F05:
        DB      $1C
        DB      $1E,$28,$2A,$10,$26,$25,$1E,$27,$03,$1C,$1B,$28
        DB      $3E,$0C,$3B,$29,$2D,$27,$1E,$1A,$03,$0E,$27,$1E
        DB      $1A,$26,$2B,$3E

; $06 Qob Ha'DIbaHmeywIj.
K_F06:
        DB      $16
        DB      $19,$1B,$26,$0E,$03,$1B,$15,$03,$1E,$27,$0E,$15
        DB      $1B,$3E,$0C,$3B,$29,$2D,$27,$1E,$1A,$3E

; $07 lojmIt vegh Worluk 'ej nargh.
K_F07:
        DB      $1F
        DB      $18,$26,$1E,$1A,$3E,$0C,$27,$2A,$03,$0F,$3B,$1C
        DB      $1B,$03,$2D,$26,$2B,$18,$28,$19,$03,$3B,$1E,$1A
        DB      $03,$0D,$15,$2B,$1C,$1B,$3E

; $08 HotlhwI' yIbej.
K_F08:
        DB      $10
        DB      $1B,$26,$2A,$18,$1B,$2D,$27,$03,$29,$27,$0E,$3B
        DB      $1E,$1A,$03,$03

; $09 SuvwI'.
K_F09:
        DB      $07
        DB      $11,$28,$0F,$2D,$27,$03,$3E

; $0A Huch yIlan.
K_F0A:
        DB      $0B
        DB      $1B,$28,$2A,$10,$03,$29,$27,$18,$15,$0D,$3E

; $0B HISam.
K_F0B:
        DB      $07
        DB      $1B,$27,$11,$15,$3E,$0C,$3E

; $0C jISo'.
K_F0C:
        DB      $07
        DB      $1E,$1A,$27,$11,$26,$03,$3E

; $0D yIghuH.
K_F0D:
        DB      $07
        DB      $29,$27,$1C,$1B,$28,$1B,$3E

; $0E HISambe' 'e' yItul.
K_F0E:
        DB      $13
        DB      $1B,$27,$11,$15,$3E,$0C,$0E,$3B,$03,$3B,$03,$29
        DB      $27,$2A,$28,$18,$3E,$3E,$3E

; $0F latlh Huch vIHev.
K_F0F:
        DB      $11
        DB      $18,$15,$2A,$18,$1B,$03,$1B,$28,$2A,$10,$03,$0F
        DB      $27,$1B,$3B,$0F,$3E

; $10 Ha ha ha ha!
K_F10:
        DB      $0A
        DB      $1B,$15,$1B,$15,$1B,$15,$03,$1B,$15,$3E

; $11 maj! ghumeywIj ghungqu'.
K_F11:
        DB      $1B
        DB      $3E,$0C,$15,$1E,$1A,$3E,$1C,$1B,$28,$3E,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$03,$1C,$1B,$28,$14,$19,$28
        DB      $03,$3E,$3E

; $12 SuvmeH DaqDaq bIghoS.
K_F12:
        DB      $17
        DB      $11,$28,$0F,$3E,$0C,$3B,$1B,$03,$1E,$15,$19,$1E
        DB      $15,$19,$03,$0E,$27,$1C,$1B,$26,$11,$3E,$3E

; $13 latlh SuvwI' luSop ghumeywIj.
K_F13:
        DB      $1E
        DB      $18,$15,$2A,$18,$1B,$03,$11,$28,$0F,$2D,$27,$03
        DB      $18,$28,$11,$26,$25,$03,$1C,$1B,$28,$3E,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$3E

; $14 yItaH; HISam.
K_F14:
        DB      $0D
        DB      $29,$27,$2A,$15,$1B,$03,$1B,$27,$11,$15,$3E,$0C
        DB      $3E

; $15 latlh bIghHa'mey puS Daju'DI',
K_F15:
        DB      $1F
        DB      $18,$15,$2A,$18,$1B,$03,$0E,$27,$1C,$1B,$1B,$15
        DB      $03,$3E,$0C,$3B,$29,$03,$25,$28,$11,$03,$1E,$15
        DB      $1E,$1A,$28,$03,$1E,$27,$03

; $16 latlh Qu'vaD yIchegh.
K_F16:
        DB      $15
        DB      $18,$15,$2A,$18,$1B,$03,$19,$1B,$28,$03,$0F,$15
        DB      $1E,$03,$29,$27,$2A,$10,$3B,$1C,$1B

; $17 Wor bIghHa'meyDaq bIchegh.
K_F17:
        DB      $1C
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$3E
        DB      $0C,$3B,$29,$1E,$15,$19,$03,$0E,$27,$2A,$10,$3B
        DB      $1C,$1B,$3E,$03

; $18 Wor DISmeyDaq HISam.
K_F18:
        DB      $17
        DB      $2D,$26,$2B,$03,$1E,$27,$11,$3E,$0C,$3B,$29,$1E
        DB      $15,$19,$03,$1B,$27,$11,$15,$3E,$0C,$03,$03

; $19 Dutlho'.
K_F19:
        DB      $04
        DB      $1E,$28,$03,$3E

; $1A SuvwI'pu' HoSghaj DaSuv.
K_F1A:
        DB      $19
        DB      $11,$28,$0F,$2D,$27,$03,$25,$28,$03,$1B,$26,$11
        DB      $1C,$1B,$15,$1E,$1A,$03,$1E,$15,$11,$28,$0F,$3E
        DB      $03

; $1B Garwor, yIHIv!
K_F1B:
        DB      $0E
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$29,$27,$1B,$27,$0F
        DB      $3E,$03

; $1C latlh DanIDchugh, bIHegh.
K_F1C:
        DB      $19
        DB      $18,$15,$2A,$18,$1B,$03,$1E,$15,$0D,$27,$1E,$2A
        DB      $10,$28,$1C,$1B,$03,$0E,$27,$1B,$3B,$1C,$1B,$3E
        DB      $03

; $1D Burwor Garwor Thorwor je DuHoH.
K_F1D:
        DB      $21
        DB      $0E,$28,$2B,$2D,$26,$2B,$03,$1C,$15,$2B,$2D,$26
        DB      $2B,$03,$2A,$1B,$26,$2B,$2D,$26,$2B,$03,$1E,$1A
        DB      $3B,$03,$1E,$28,$1B,$26,$1B,$3E,$03

; $1E SuvwI'HommeywIj ghungqu'.
K_F1E:
        DB      $1C
        DB      $11,$28,$0F,$2D,$27,$03,$1B,$26,$3E,$0C,$3E,$0C
        DB      $3B,$29,$2D,$27,$1E,$1A,$03,$1C,$1B,$28,$14,$19
        DB      $28,$03,$3E,$03

; $1F 'IDnarwIj HoS law' nuHmeylIj HoS puS.
K_F1F:
        DB      $27
        DB      $03,$27,$1E,$0D,$15,$2B,$2D,$27,$1E,$1A,$03,$1B
        DB      $26,$11,$03,$18,$15,$2D,$03,$0D,$28,$1B,$3E,$0C
        DB      $3B,$29,$18,$27,$1E,$1A,$03,$1B,$26,$11,$03,$25
        DB      $28,$11,$3E

; $20 QeD Daghoj; 'IDnar wIghoj.
K_F20:
        DB      $1B
        DB      $19,$1B,$3B,$1E,$03,$1E,$15,$1C,$1B,$26,$1E,$1A
        DB      $03,$27,$1E,$0D,$15,$2B,$03,$2D,$27,$1C,$1B,$26
        DB      $1E,$1A,$3E

; $21 Wor bIghHa'meyDaq HomDu'lIj tu'lu'.
K_F21:
        DB      $1E
        DB      $2D,$26,$2B,$0E,$27,$1C,$1B,$15,$3E,$0C,$3B,$29
        DB      $1E,$15,$26,$3E,$0C,$1E,$28,$18,$27,$1E,$1A,$2A
        DB      $28,$18,$28,$03,$3E,$03

; $22 Qapla' Daghajbe'.
K_F22:
        DB      $12
        DB      $19,$1B,$15,$25,$18,$15,$03,$1E,$15,$1C,$1B,$15
        DB      $1E,$1A,$0E,$3B,$03,$3E

; $23 yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
K_F23:
        DB      $21
        DB      $29,$27,$19,$15,$2D,$03,$2D,$26,$2B,$03,$27,$1E
        DB      $0D,$15,$2B,$03,$25,$27,$0D,$03,$1E,$1A,$27,$1B
        DB      $03,$11,$26,$1B,$0E,$3B,$03,$3E,$03

; $24 Hoch DanIvbe'chugh, bIluj.
K_F24:
        DB      $1B
        DB      $1B,$26,$2A,$10,$03,$1E,$15,$0D,$27,$0F,$0E,$3B
        DB      $03,$2A,$10,$28,$1C,$1B,$03,$0E,$27,$18,$28,$1E
        DB      $1A,$03,$03

; $25 ghumeywIj DaQaw'chugh, qulDaq qameQmoH.
K_F25:
        DB      $2D
        DB      $1C,$1B,$28,$3E,$0C,$3B,$29,$2D,$27,$1E,$1A,$03
        DB      $1E,$15,$19,$1B,$15,$2D,$03,$2A,$10,$28,$1C,$1B
        DB      $03,$19,$28,$18,$1E,$15,$19,$03,$19,$15,$3E,$0C
        DB      $3B,$19,$1B,$3E,$0C,$26,$1B,$3E,$03

; $26 jIQeHchoH.
K_F26:
        DB      $0D
        DB      $1E,$1A,$27,$19,$1B,$3B,$1B,$2A,$10,$26,$1B,$3E
        DB      $03

; $27 Worvo' bIyIntaHvIS bImejbe'.
K_F27:
        DB      $1E
        DB      $2D,$26,$2B,$0F,$26,$03,$0E,$27,$29,$27,$0D,$2A
        DB      $15,$1B,$0F,$27,$11,$03,$0E,$27,$3E,$0C,$3B,$1E
        DB      $1A,$0E,$3B,$03,$3E,$03

; $28 Garwor Thorwor je tISo'moH!
K_F28:
        DB      $1E
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$2A,$1B,$26,$2B,$2D
        DB      $26,$2B,$03,$1E,$1A,$3B,$03,$2A,$27,$11,$26,$03
        DB      $3E,$0C,$26,$1B,$3E,$03

; $29 bIHoSghajqu'laH.
K_F29:
        DB      $12
        DB      $0E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19,$28
        DB      $03,$18,$15,$1B,$3E,$03

; $2A nom yIchegh; qaloS.
K_F2A:
        DB      $13
        DB      $0D,$26,$3E,$0C,$03,$29,$27,$2A,$10,$3B,$1C,$1B
        DB      $03,$19,$15,$18,$26,$11,$3E

; $2B Qu' Dachuqa'laH; DaH bIluj.
K_F2B:
        DB      $1C
        DB      $19,$1B,$28,$03,$1E,$15,$2A,$10,$28,$19,$15,$03
        DB      $18,$15,$1B,$03,$1E,$15,$1B,$03,$0E,$27,$18,$28
        DB      $1E,$1A,$3E,$3E

; $2C He he he, ho ho ho, ha ha ha ha! maj.
K_F2C:
        DB      $23
        DB      $1B,$3B,$03,$1B,$3B,$03,$1B,$3B,$03,$1B,$26,$03
        DB      $1B,$26,$03,$1B,$26,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E,$0C,$15,$1E,$1A,$3E

; $2D Wor qo'Daq yI'el.
K_F2D:
        DB      $11
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E,$15,$19,$03,$29
        DB      $27,$03,$3B,$18,$3E

; $2E Wor qo'Daq mIvwa' DaSuq.
K_F2E:
        DB      $18
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E,$15,$19,$03,$3E
        DB      $0C,$27,$0F,$2D,$15,$03,$1E,$15,$11,$28,$19,$3E

; $2F Wor 'IDnar pIn Daghom.
K_F2F:
        DB      $17
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15,$2B,$03,$25,$27
        DB      $0D,$03,$1E,$15,$1C,$1B,$26,$3E,$0C,$3E,$3E

; $30 qaStaHvIS 'op jar pagh Sop Burwor.
K_F30:
        DB      $23
        DB      $19,$15,$11,$2A,$15,$1B,$0F,$27,$11,$03,$26,$25
        DB      $03,$1E,$1A,$15,$2B,$03,$25,$15,$1C,$1B,$03,$11
        DB      $26,$25,$03,$0E,$28,$2B,$2D,$26,$2B,$3E,$03

; $31 qul lutlhuH ghumeywIj.
K_F31:
        DB      $18
        DB      $19,$28,$18,$03,$18,$28,$2A,$18,$1B,$28,$1B,$03
        DB      $1C,$1B,$28,$3E,$0C,$3B,$29,$2D,$27,$1E,$1A,$3E

; $32 nISwI' tIHmeywIjmo' bImeQ.
K_F32:
        DB      $1E
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$3E,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$3E,$0C,$26,$03,$0E,$27,$3E
        DB      $0C,$3B,$19,$1B,$3E,$03

; $33 Doq Thorwor, QeH 'ej ghung.
K_F33:
        DB      $1B
        DB      $1E,$26,$19,$03,$2A,$1B,$26,$2B,$2D,$26,$2B,$03
        DB      $19,$1B,$3B,$1B,$03,$3B,$1E,$1A,$03,$1C,$1B,$28
        DB      $14,$3E,$03

; $34 SuvwI', qaSumchoH.
K_F34:
        DB      $11
        DB      $11,$28,$0F,$2D,$27,$03,$19,$15,$11,$28,$3E,$0C
        DB      $2A,$10,$26,$1B,$3E

; $35 Seng DaneH.
K_F35:
        DB      $0B
        DB      $11,$3B,$14,$03,$1E,$15,$0D,$3B,$1B,$3E,$03

; $36 Ha ha ha ha! (padded)
K_F36:
        DB      $0B
        DB      $1B,$15,$1B,$15,$1B,$15,$03,$1B,$15,$3E,$03

; $37 SuvwI' (padded)
K_F37:
        DB      $07
        DB      $11,$28,$0F,$2D,$27,$3E,$03

; $38 DuQIHpu'.
K_F38:
        DB      $03
        DB      $1E,$28,$03

; $39 nISwI' yIchop.
K_F39:
        DB      $0E
        DB      $0D,$27,$11,$2D,$27,$03,$29,$27,$2A,$10,$26,$25
        DB      $3E,$03

; $3A nISwI' tIH DaparHa''a'?
K_F3A:
        DB      $15
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$03,$1E,$15
        DB      $25,$15,$2B,$1B,$15,$03,$15,$03,$3E

; $3B nom jolwI'wIj Qap.
K_F3B:
        DB      $17
        DB      $0D,$26,$3E,$0C,$03,$1E,$1A,$26,$18,$2D,$27,$03
        DB      $2D,$27,$1E,$1A,$03,$19,$1B,$15,$25,$3E,$03

; $3C DaH 'IDnarwIj DaSov.
K_F3C:
        DB      $15
        DB      $1E,$15,$1B,$03,$27,$1E,$0D,$15,$2B,$2D,$27,$1E
        DB      $1A,$03,$1E,$15,$11,$26,$0F,$03,$03

; $3D chaq maghomqa'.
K_F3D:
        DB      $11
        DB      $2A,$10,$15,$19,$03,$3E,$0C,$15,$1C,$1B,$26,$3E
        DB      $0C,$19,$15,$03,$3E

; $3E QoQ 'oH jorlIj'e'.
K_F3E:
        DB      $15
        DB      $19,$1B,$26,$19,$1B,$03,$26,$1B,$03,$1E,$1A,$26
        DB      $2B,$18,$27,$1E,$1A,$03,$3B,$03,$3E

; $3F vIjatlhqa'.
K_F3F:
        DB      $0C
        DB      $0F,$27,$1E,$1A,$15,$2A,$18,$1B,$19,$15,$03,$3E

; $40 SuvwI' joH
K_F40:
        DB      $08
        DB      $11,$28,$0F,$2D,$27,$1E,$1A,$3E

; $41 SuvwI' joH (padded)
K_F41:
        DB      $0B
        DB      $11,$28,$0F,$2D,$27,$1E,$1A,$26,$1B,$3E,$03

; $42 yIghuH! QemjIq DaghoS.
K_F42:
        DB      $19
        DB      $29,$27,$1C,$1B,$28,$1B,$3E,$19,$1B,$3B,$3E,$0C
        DB      $1E,$1A,$27,$19,$03,$1E,$15,$1C,$1B,$26,$11,$3E
        DB      $03

; $43 QemjIqDaq He'lIj ghoS.
K_F43:
        DB      $1B
        DB      $19,$1B,$3B,$3E,$0C,$1E,$1A,$27,$19,$1E,$15,$19
        DB      $03,$1B,$3B,$03,$18,$27,$1E,$1A,$03,$1C,$1B,$26
        DB      $11,$3E,$03

; $44 Wor bIghHa'mey qoDDaq yIghoS.
K_F44:
        DB      $1F
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$3E
        DB      $0C,$3B,$29,$03,$19,$26,$1E,$1E,$15,$19,$03,$29
        DB      $27,$1C,$1B,$26,$11,$3E,$03

; $45 yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
K_F45:
        DB      $26
        DB      $29,$27,$1C,$1B,$28,$1B,$3E,$11,$28,$0F,$2D,$27
        DB      $03,$1E,$1A,$26,$1B,$03,$0E,$27,$1C,$1B,$1B,$15
        DB      $03,$3E,$0C,$3B,$29,$1E,$15,$19,$03,$11,$26,$1B
        DB      $3E,$03

; $46 DaSo' 'e' DaQub; bIghHa' pIn jIH.
K_F46:
        DB      $1F
        DB      $1E,$15,$11,$26,$03,$3B,$03,$1E,$15,$19,$1B,$28
        DB      $0E,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$25,$27,$0D
        DB      $03,$1E,$1A,$27,$1B,$3E,$03

; $47 Thor, Bur, Gar! SopmeH yIghuH.
K_F47:
        DB      $1D
        DB      $2A,$1B,$26,$2B,$03,$0E,$28,$2B,$03,$1C,$15,$2B
        DB      $3E,$11,$26,$25,$3E,$0C,$3B,$1B,$03,$29,$27,$1C
        DB      $1B,$28,$1B,$3E,$03

; $48 DaSlIj yIrar!
K_F48:
        DB      $0E
        DB      $1E,$15,$11,$18,$27,$1E,$1A,$03,$29,$27,$2B,$15
        DB      $2B,$3E

; $49 SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.
K_F49:
        DB      $30
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A,$26,$1B,$03,$0E
        DB      $27,$1C,$1B,$1B,$15,$03,$3E,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$19,$3B,$2A,$03,$1B,$15,$03,$1E,$27,$0E
        DB      $15,$1B,$3E,$0C,$3B,$29,$2D,$27,$1E,$1A,$3E,$03

; $4A DaH yImI'; latlh DuH Daghajbe'.
K_F4A:
        DB      $1F
        DB      $1E,$15,$1B,$03,$29,$27,$3E,$0C,$27,$03,$18,$15
        DB      $2A,$18,$1B,$03,$1E,$28,$1B,$03,$1E,$15,$1C,$1B
        DB      $15,$1E,$1A,$0E,$3B,$03,$3E

; $4B QemjIqDaq bIyInlaH'a'?
K_F4B:
        DB      $19
        DB      $19,$1B,$3B,$3E,$0C,$1E,$1A,$27,$19,$1E,$15,$19
        DB      $03,$0E,$27,$29,$27,$0D,$18,$15,$1B,$03,$15,$03
        DB      $3E

; $4C toH! reDmey vIlIjpu'.
K_F4C:
        DB      $16
        DB      $2A,$26,$1B,$3E,$2B,$3B,$1E,$3E,$0C,$3B,$29,$03
        DB      $0F,$27,$18,$27,$1E,$1A,$25,$28,$03,$3E

; $4D nuqDaq DaSo'?
K_F4D:
        DB      $0E
        DB      $0D,$28,$19,$1E,$15,$19,$03,$1E,$15,$11,$26,$03
        DB      $3E,$03

; $4E SoH.
K_F4E:
        DB      $05
        DB      $11,$26,$1B,$3E,$03

; $50 SoH.
K_F50:
        DB      $04
        DB      $11,$26,$1B,$3E

; $51 Wor bIghHa'meyDaq.
K_F51:
        DB      $13
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$3E
        DB      $0C,$3B,$29,$1E,$15,$19,$03

; $52 yIghomqa'.
K_F52:
        DB      $0B
        DB      $29,$27,$1C,$1B,$26,$3E,$0C,$19,$15,$03,$3E

; Erased space $C92D-$CD8C.
K_SFILL:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF

; 84 fragment slots ($00-$53).
K_PTRS:
        DW      K_F00      ; $00
        DW      K_F01      ; $01
        DW      K_F02      ; $02
        DW      K_F03      ; $03
        DW      K_F04      ; $04
        DW      K_F05      ; $05
        DW      K_F06      ; $06
        DW      K_F07      ; $07
        DW      K_F08      ; $08
        DW      K_F09      ; $09
        DW      K_F0A      ; $0A
        DW      K_F0B      ; $0B
        DW      K_F0C      ; $0C
        DW      K_F0D      ; $0D
        DW      K_F0E      ; $0E
        DW      K_F0F      ; $0F
        DW      K_F10      ; $10
        DW      K_F11      ; $11
        DW      K_F12      ; $12
        DW      K_F13      ; $13
        DW      K_F14      ; $14
        DW      K_F15      ; $15
        DW      K_F16      ; $16
        DW      K_F17      ; $17
        DW      K_F18      ; $18
        DW      K_F19      ; $19
        DW      K_F1A      ; $1A
        DW      K_F1B      ; $1B
        DW      K_F1C      ; $1C
        DW      K_F1D      ; $1D
        DW      K_F1E      ; $1E
        DW      K_F1F      ; $1F
        DW      K_F20      ; $20
        DW      K_F21      ; $21
        DW      K_F22      ; $22
        DW      K_F23      ; $23
        DW      K_F24      ; $24
        DW      K_F25      ; $25
        DW      K_F26      ; $26
        DW      K_F27      ; $27
        DW      K_F28      ; $28
        DW      K_F29      ; $29
        DW      K_F2A      ; $2A
        DW      K_F2B      ; $2B
        DW      K_F2C      ; $2C
        DW      K_F2D      ; $2D
        DW      K_F2E      ; $2E
        DW      K_F2F      ; $2F
        DW      K_F30      ; $30
        DW      K_F31      ; $31
        DW      K_F32      ; $32
        DW      K_F33      ; $33
        DW      K_F34      ; $34
        DW      K_F35      ; $35
        DW      K_F36      ; $36
        DW      K_F37      ; $37
        DW      K_F38      ; $38
        DW      K_F39      ; $39
        DW      K_F3A      ; $3A
        DW      K_F3B      ; $3B
        DW      K_F3C      ; $3C
        DW      K_F3D      ; $3D
        DW      K_F3E      ; $3E
        DW      K_F3F      ; $3F
        DW      K_F40      ; $40
        DW      K_F41      ; $41
        DW      K_F42      ; $42
        DW      K_F43      ; $43
        DW      K_F44      ; $44
        DW      K_F45      ; $45
        DW      K_F46      ; $46
        DW      K_F47      ; $47
        DW      K_F48      ; $48
        DW      K_F49      ; $49
        DW      K_F4A      ; $4A
        DW      K_F4B      ; $4B
        DW      K_F4C      ; $4C
        DW      K_F4D      ; $4D
        DW      K_F4E      ; $4E
        DW      $0000      ; $4F
        DW      K_F50      ; $50
        DW      K_F51      ; $51
        DW      K_F52      ; $52
        DW      $0000      ; $53

; 80 language-local phrase records ($00-$4F).
K_PHR:
        DB      $81,$0A,$82,$0B,$04,$81,$0A,$82,$0C,$10,$81,$0A
        DB      $82,$0B,$04,$81,$0A,$82,$0C,$10,$82,$0D,$37,$82
        DB      $0E,$04,$81,$0F,$82,$11,$10,$82,$1E,$36,$81,$2D
        DB      $82,$2E,$10,$82,$2F,$10,$81,$00,$82,$51,$4E,$82
        DB      $04,$03,$82,$05,$10,$81,$06,$81,$07,$82,$08,$37
        DB      $82,$33,$36,$81,$23,$82,$24,$36,$82,$27,$36,$82
        DB      $25,$36,$82,$30,$36,$82,$31,$09,$81,$32,$81,$1D
        DB      $82,$12,$36,$81,$13,$81,$14,$83,$15,$40,$50,$82
        DB      $37,$26,$82,$34,$10,$83,$09,$22,$10,$82,$35,$37
        DB      $82,$1A,$36,$81,$1B,$82,$1C,$36,$82,$01,$36,$82
        DB      $1F,$09,$82,$09,$20,$82,$21,$36,$82,$28,$36,$83
        DB      $04,$52,$10,$82,$17,$37,$82,$18,$37,$82,$19,$04
        DB      $82,$29,$37,$81,$2A,$82,$2B,$36,$81,$2C,$83,$38
        DB      $04,$10,$83,$39,$37,$36,$82,$3A,$10,$82,$3B,$36
        DB      $82,$3C,$37,$82,$09,$3D,$82,$3E,$10,$83,$3F,$34
        DB      $10,$83,$41,$42,$36,$83,$41,$43,$36,$82,$44,$36
        DB      $81,$45,$82,$46,$36,$82,$47,$36,$82,$48,$10,$82
        DB      $49,$36,$82,$4A,$10,$82,$4B,$10,$82,$4C,$10,$82
        DB      $4D,$36,$82,$4A,$10,$82,$4B,$36,$82,$4C,$10,$82
        DB      $4D,$36

K_PFILL:
        DB      $FF,$FF

; Additive checksum compensation.
K_CSUM:
        DB      $DE

; Erased ROM area $CF1E-$CFEA.
K_FILL:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF

K_ID:
        DB      $4B,$4C,$49,$4E,$47,$4F,$4E,$57,$49,$5A,$41,$52
        DB      $44,$00,$44,$4E,$08,$09,$26,$08,$26

        END
