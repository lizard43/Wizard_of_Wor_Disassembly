; KLINGON_X11.asm
;==============================================================================
; Wizard of Wor - Klingon X11 foreign-language ROM
;==============================================================================
;
; The runtime-sensitive X11 speech layout remains anchored to the known-good
; German ROM: speech record addresses/counts, stored control bits 7-6, fragment
; pointer table, header addresses, and checksum location are unchanged.
;
; Localized display records use their own natural lengths, as the game selects
; records dynamically. Two alternate-font glyphs preserve the Klingon apostrophe
; and the q/Q distinction without introducing bytes below $30 into text records.
;
; The phrase table is language-local. It uses the resident-English composition as
; the semantic baseline and changes seven phrase records where Klingon word order
; or a short grammar helper is required. Helpers occupy $50-$52; $4F remains null;
; $53 remains an unreferenced compatibility record.
;==============================================================================

        NOLIST
        LIST
        ORG     $C000

K_HDR:
        DB      $8D,$CD,$35,$CE,$10,$20,$30,$40,$70,$50,$00,$D2
        DB      $C1

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
; tlhIngan Hol: Huch jengva' yIlan
K_T01:
        DB      $12,$48,$55,$43,$48,$40,$4A,$45,$4E,$47,$56,$41
        DB      $62,$40,$59,$49,$4C,$41,$4E

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

; Fragment $00 at $C200; fixed German slot length $29.
; Working speech: Worluk yIHoH. cha'logh mIvwa' DaSuq.
K_F00:
        DB      $29,$AD,$26,$2B,$18,$28,$19,$03,$29,$27,$1B,$26
        DB      $1B,$3E,$2A,$10,$15,$03,$18,$26,$1C,$1B,$03,$0C
        DB      $27,$0F,$2D,$15,$03,$1E,$15,$11,$28,$19,$03,$03
        DB      $03,$03,$03,$03,$03,$BE

; Fragment $01 at $C22A; fixed German slot length $30.
; Working speech: bIHoSghajqu'chugh, qamevmoH jIH.
K_F01:
        DB      $30,$8E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19
        DB      $28,$03,$2A,$10,$28,$1C,$1B,$03,$19,$15,$0C,$3B
        DB      $0F,$0C,$26,$1B,$03,$1E,$1A,$27,$1B,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $BE

; Fragment $4E at $C25B; fixed German slot length $10.
; Working speech: SoH.
K_F4E:
        DB      $10,$91,$26,$1B,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $02 at $C26C; fixed German slot length $0C.
; Working speech: Wor bIghHa'mey.
K_F02:
        DB      $0C,$AD,$26,$2B,$0E,$27,$1C,$1B,$15,$0C,$3B,$29
        DB      $BE

; Fragment $50 at $C279; fixed German slot length $0A.
; Klingon grammar helper: SoH.
K_F50:
        DB      $0A,$91,$26,$1B,$03,$03,$03,$03,$03,$03,$BE

; Fragment $04 at $C284; fixed German slot length $0F.
; Working speech: Wor 'IDnar pIn.
K_F04:
        DB      $0F,$2D,$66,$2B,$03,$27,$1E,$0D,$15,$2B,$43,$25
        DB      $27,$0D,$03,$3E

; Fragment $05 at $C294; fixed German slot length $29.
; Working speech: DuchopDI' ghumeywIj, bIjor.
K_F05:
        DB      $29,$1E,$28,$2A,$10,$26,$25,$1E,$27,$03,$1C,$1B
        DB      $28,$0C,$3B,$29,$2D,$27,$1E,$1A,$03,$0E,$27,$1E
        DB      $1A,$26,$2B,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$3E

; Fragment $06 at $C2BE; fixed German slot length $24.
; Working speech: Qob Ha'DIbaHmeywIj.
K_F06:
        DB      $24,$19,$1B,$26,$0E,$03,$1B,$15,$03,$1E,$27,$0E
        DB      $15,$1B,$0C,$3B,$29,$2D,$27,$1E,$1A,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $3E

; Fragment $07 at $C2E3; fixed German slot length $23.
; Working speech: lojmIt vegh Worluk 'ej nargh.
K_F07:
        DB      $23,$18,$26,$1E,$1A,$0C,$27,$2A,$03,$0F,$3B,$1C
        DB      $1B,$03,$2D,$26,$2B,$18,$28,$19,$03,$3B,$1E,$1A
        DB      $03,$0D,$15,$2B,$1C,$1B,$03,$03,$03,$03,$03,$3E

; Fragment $03 at $C307; fixed German slot length $09.
; Working speech: jIH.
K_F03:
        DB      $09,$1E,$1A,$27,$1B,$03,$03,$03,$03,$3E

; Fragment $22 at $C311; fixed German slot length $2C.
; Working speech: Qapla' Daghajbe'.
K_F22:
        DB      $2C,$19,$1B,$15,$25,$18,$15,$03,$1E,$15,$1C,$1B
        DB      $15,$1E,$1A,$0E,$3B,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $23 at $C33E; fixed German slot length $25.
; Working speech: yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
K_F23:
        DB      $25,$A9,$27,$19,$15,$2D,$03,$2D,$26,$2B,$03,$27
        DB      $1E,$0D,$15,$2B,$03,$25,$27,$0D,$03,$1E,$1A,$27
        DB      $1B,$03,$11,$26,$1B,$0E,$3B,$03,$03,$03,$03,$03
        DB      $03,$BE

; Fragment $24 at $C364; fixed German slot length $40.
; Working speech: Hoch DanIvbe'chugh, bIluj.
K_F24:
        DB      $40,$1B,$26,$2A,$10,$03,$1E,$15,$0D,$27,$0F,$0E
        DB      $3B,$03,$2A,$10,$28,$1C,$1B,$03,$0E,$27,$18,$28
        DB      $1E,$1A,$03,$03,$03,$03,$03,$03,$83,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $25 at $C3A5; fixed German slot length $38.
; Working speech: ghumeywIj DaQaw'chugh, qulDaq qameQmoH.
K_F25:
        DB      $38,$9C,$1B,$28,$0C,$3B,$29,$2D,$27,$1E,$1A,$03
        DB      $1E,$15,$19,$1B,$15,$2D,$03,$2A,$10,$28,$1C,$1B
        DB      $03,$19,$28,$18,$1E,$15,$19,$03,$19,$15,$0C,$3B
        DB      $19,$1B,$0C,$26,$1B,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $26 at $C3DE; fixed German slot length $1C.
; Working speech: jIQeHchoH.
K_F26:
        DB      $1C,$9E,$1A,$27,$19,$1B,$3B,$1B,$2A,$10,$26,$1B
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $27 at $C3FB; fixed German slot length $32.
; Working speech: Worvo' bIyIntaHvIS bImejbe'.
K_F27:
        DB      $32,$AD,$26,$2B,$0F,$26,$03,$0E,$27,$29,$27,$0D
        DB      $2A,$15,$1B,$0F,$27,$11,$03,$0E,$27,$0C,$3B,$1E
        DB      $1A,$0E,$3B,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$BE

; Fragment $1B at $C42E; fixed German slot length $12.
; Working speech: Garwor, yIHIv!
K_F1B:
        DB      $12,$9C,$15,$6B,$2D,$26,$2B,$03,$29,$27,$1B,$27
        DB      $0F,$03,$03,$03,$03,$03,$BE

; Fragment $08 at $C441; fixed German slot length $20.
; Working speech: HotlhwI' yIbej.
K_F08:
        DB      $20,$9B,$26,$2A,$18,$1B,$2D,$27,$03,$29,$27,$0E
        DB      $3B,$1E,$1A,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$83,$03,$3E

; Fragment $09 at $C462; fixed German slot length $06.
; Working speech: SuvwI'.
K_F09:
        DB      $06,$11,$28,$0F,$2D,$27,$3E

; Fragment $1A at $C469; fixed German slot length $1B.
; Working speech: SuvwI'pu' HoSghaj DaSuv.
K_F1A:
        DB      $1B,$91,$28,$0F,$2D,$27,$03,$25,$28,$03,$1B,$26
        DB      $11,$1C,$1B,$15,$1E,$1A,$03,$1E,$15,$11,$28,$0F
        DB      $03,$03,$03,$BE

; Fragment $35 at $C485; fixed German slot length $16.
; Working speech: Seng DaneH.
K_F35:
        DB      $16,$91,$3B,$14,$03,$1E,$15,$0D,$3B,$1B,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $1C at $C49C; fixed German slot length $36.
; Working speech: latlh DanIDchugh, bIHegh.
K_F1C:
        DB      $36,$98,$15,$2A,$18,$1B,$03,$1E,$15,$0D,$27,$1E
        DB      $2A,$10,$28,$1C,$1B,$03,$0E,$27,$1B,$3B,$1C,$1B
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$BE

; Fragment $1D at $C4D3; fixed German slot length $30.
; Working speech: Burwor Garwor Thorwor je DuHoH.
K_F1D:
        DB      $30,$8E,$28,$6B,$6D,$26,$2B,$03,$1C,$15,$6B,$6D
        DB      $26,$2B,$03,$2A,$1B,$26,$2B,$2D,$26,$6B,$43,$1E
        DB      $1A,$3B,$03,$1E,$28,$1B,$26,$1B,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $BE

; Fragment $1E at $C504; fixed German slot length $24.
; Working speech: SuvwI'HommeywIj ghungqu'.
K_F1E:
        DB      $24,$91,$28,$0F,$2D,$27,$03,$1B,$26,$0C,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$03,$1C,$1B,$28,$14,$19,$28
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $BE

; Fragment $1F at $C529; fixed German slot length $2F.
; Working speech: 'IDnarwIj HoS law' nuHmeylIj HoS puS.
K_F1F:
        DB      $2F,$03,$27,$1E,$0D,$15,$2B,$2D,$27,$1E,$1A,$03
        DB      $1B,$26,$11,$03,$18,$15,$2D,$03,$0D,$28,$1B,$0C
        DB      $3B,$29,$18,$27,$1E,$1A,$03,$1B,$26,$11,$03,$25
        DB      $28,$11,$03,$03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $21 at $C559; fixed German slot length $1A.
; Working speech: Wor bIghHa'meyDaq HomDu'lIj tu'lu'.
K_F21:
        DB      $1A,$AD,$26,$2B,$0E,$27,$1C,$1B,$15,$0C,$3B,$29
        DB      $1E,$15,$26,$0C,$1E,$28,$18,$27,$1E,$1A,$2A,$28
        DB      $18,$28,$3E

; Fragment $51 at $C574; fixed German slot length $13.
; Klingon grammar helper: Wor bIghHa'meyDaq.
K_F51:
        DB      $13,$2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03
        DB      $0C,$3B,$29,$1E,$15,$19,$03,$83

; Fragment $20 at $C588; fixed German slot length $31.
; Working speech: QeD Daghoj; 'IDnar wIghoj.
K_F20:
        DB      $31,$19,$1B,$3B,$1E,$03,$1E,$15,$1C,$1B,$26,$1E
        DB      $1A,$03,$27,$1E,$0D,$15,$2B,$03,$2D,$27,$1C,$1B
        DB      $26,$1E,$1A,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$3E

; Fragment $0A at $C5BA; fixed German slot length $15.
; Working speech: Huch yIlan.
K_F0A:
        DB      $15,$1B,$28,$6A,$50,$03,$29,$27,$18,$15,$0D,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $0B at $C5D0; fixed German slot length $0F.
; Working speech: HISam.
K_F0B:
        DB      $0F,$1B,$27,$11,$15,$0C,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$3E

; Fragment $0C at $C5E0; fixed German slot length $13.
; Working speech: jISo'.
K_F0C:
        DB      $13,$1E,$1A,$27,$11,$26,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $0D at $C5F4; fixed German slot length $0B.
; Working speech: yIghuH.
K_F0D:
        DB      $0B,$29,$27,$1C,$1B,$28,$1B,$03,$03,$03,$03,$3E

; Fragment $0E at $C600; fixed German slot length $31.
; Working speech: HISambe' 'e' yItul.
K_F0E:
        DB      $31,$1B,$27,$11,$15,$0C,$0E,$3B,$03,$3B,$03,$29
        DB      $27,$2A,$28,$18,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$43,$03,$03,$03,$03,$03,$03,$03
        DB      $43,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$3E

; Fragment $0F at $C632; fixed German slot length $2B.
; Working speech: latlh Huch vIHev.
K_F0F:
        DB      $2B,$18,$15,$2A,$18,$1B,$03,$1B,$28,$2A,$10,$03
        DB      $0F,$27,$1B,$3B,$0F,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $10 at $C65E; fixed German slot length $0A.
; Working speech: Ha ha ha ha!
K_F10:
        DB      $0A,$1B,$15,$5B,$15,$5B,$15,$03,$1B,$15,$3E

; Fragment $11 at $C669; fixed German slot length $2A.
; Working speech: maj! ghumeywIj ghungqu'.
K_F11:
        DB      $2A,$0C,$15,$1E,$1A,$3E,$1C,$1B,$28,$0C,$3B,$29
        DB      $2D,$27,$1E,$1A,$03,$1C,$1B,$28,$14,$19,$28,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $12 at $C694; fixed German slot length $23.
; Working speech: SuvmeH DaqDaq bIghoS.
K_F12:
        DB      $23,$91,$28,$0F,$0C,$3B,$1B,$03,$1E,$15,$19,$1E
        DB      $15,$19,$03,$0E,$27,$1C,$1B,$26,$11,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $36 at $C6B8; fixed German slot length $0B.
; Working speech: Ha ha ha ha! (padded)
K_F36:
        DB      $0B,$9B,$15,$1B,$15,$1B,$15,$03,$1B,$15,$3E,$83

; Fragment $13 at $C6C4; fixed German slot length $31.
; Working speech: latlh SuvwI' luSop ghumeywIj.
K_F13:
        DB      $31,$18,$15,$2A,$18,$1B,$03,$11,$28,$0F,$2D,$27
        DB      $03,$18,$28,$11,$26,$25,$03,$1C,$1B,$28,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$3E

; Fragment $14 at $C6F6; fixed German slot length $1F.
; Working speech: yItaH; HISam.
K_F14:
        DB      $1F,$29,$27,$2A,$15,$1B,$03,$1B,$27,$11,$15,$0C
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $15 at $C716; fixed German slot length $28.
; Working speech: latlh bIghHa'mey puS Daju'DI',
K_F15:
        DB      $28,$18,$15,$2A,$18,$1B,$03,$0E,$27,$1C,$1B,$1B
        DB      $15,$03,$0C,$3B,$29,$03,$25,$28,$11,$03,$1E,$15
        DB      $1E,$1A,$28,$03,$1E,$27,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$3E

; Fragment $40 at $C73F; fixed German slot length $08.
; Working speech: SuvwI' joH
K_F40:
        DB      $08,$11,$68,$4F,$2D,$27,$1E,$1A,$3E

; Fragment $41 at $C748; fixed German slot length $0A.
; Working speech: SuvwI' joH (padded)
K_F41:
        DB      $0A,$91,$28,$4F,$6D,$27,$1E,$1A,$26,$1B,$83

; Fragment $16 at $C753; fixed German slot length $35.
; Working speech: latlh Qu'vaD yIchegh.
K_F16:
        DB      $35,$18,$15,$2A,$18,$1B,$03,$19,$1B,$28,$03,$0F
        DB      $15,$1E,$03,$29,$27,$2A,$10,$3B,$1C,$1B,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$3E

; Fragment $17 at $C789; fixed German slot length $34.
; Working speech: Wor bIghHa'meyDaq bIchegh.
K_F17:
        DB      $34,$AD,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03
        DB      $0C,$3B,$29,$1E,$15,$19,$03,$0E,$27,$2A,$10,$3B
        DB      $1C,$1B,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $18 at $C7BE; fixed German slot length $33.
; Working speech: Wor DISmeyDaq HISam.
K_F18:
        DB      $33,$AD,$26,$2B,$03,$1E,$27,$11,$0C,$3B,$29,$1E
        DB      $15,$19,$03,$1B,$27,$11,$15,$0C,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$BE

; Fragment $19 at $C7F2; fixed German slot length $03.
; Working speech: Dutlho'.
K_F19:
        DB      $03,$1E,$28,$3E

; Fragment $53 at $C7F6; fixed German slot length $0D.
; Compatibility record; not referenced by Klingon phrase table.
K_F53:
        DB      $0D,$1E,$28,$2A,$18,$1B,$26,$03,$03,$03,$03,$03
        DB      $03,$3E

; Fragment $29 at $C804; fixed German slot length $29.
; Working speech: bIHoSghajqu'laH.
K_F29:
        DB      $29,$8E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19
        DB      $28,$03,$18,$15,$1B,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$BE

; Fragment $2A at $C82E; fixed German slot length $21.
; Working speech: nom yIchegh; qaloS.
K_F2A:
        DB      $21,$0D,$26,$0C,$03,$29,$27,$2A,$10,$3B,$1C,$1B
        DB      $03,$19,$15,$18,$26,$11,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $2B at $C850; fixed German slot length $3D.
; Working speech: Qu' Dachuqa'laH; DaH bIluj.
K_F2B:
        DB      $3D,$19,$1B,$28,$03,$1E,$15,$2A,$10,$28,$19,$15
        DB      $03,$18,$15,$1B,$03,$1E,$15,$1B,$03,$0E,$27,$18
        DB      $28,$1E,$1A,$03,$03,$03,$83,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$BE

; Fragment $2C at $C88E; fixed German slot length $28.
; Working speech: He he he, ho ho ho, ha ha ha ha! maj.
K_F2C:
        DB      $28,$1B,$3B,$03,$1B,$3B,$03,$1B,$3B,$03,$1B,$26
        DB      $03,$1B,$26,$03,$1B,$26,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E,$0C,$15,$1E,$1A,$03
        DB      $03,$03,$03,$03,$3E

; Fragment $2D at $C8B7; fixed German slot length $1D.
; Working speech: Wor qo'Daq yI'el.
K_F2D:
        DB      $1D,$2D,$26,$2B,$03,$59,$66,$43,$1E,$15,$19,$03
        DB      $29,$27,$03,$3B,$18,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$43,$43,$03,$03,$3E

; Fragment $2E at $C8D5; fixed German slot length $35.
; Working speech: Wor qo'Daq mIvwa' DaSuq.
K_F2E:
        DB      $35,$2D,$26,$2B,$03,$19,$26,$03,$1E,$55,$59,$03
        DB      $0C,$27,$0F,$2D,$15,$03,$1E,$15,$51,$28,$19,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$43,$43,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$43,$03,$03,$3E

; Fragment $2F at $C90B; fixed German slot length $2F.
; Working speech: Wor 'IDnar pIn Daghom.
K_F2F:
        DB      $2F,$2D,$66,$6B,$43,$27,$1E,$8D,$15,$2B,$03,$25
        DB      $27,$0D,$03,$1E,$15,$1C,$9B,$26,$0C,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$83,$03
        DB      $03,$03,$03,$83,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $30 at $C93B; fixed German slot length $29.
; Working speech: qaStaHvIS 'op jar pagh Sop Burwor.
K_F30:
        DB      $29,$99,$15,$11,$2A,$15,$1B,$0F,$27,$11,$03,$26
        DB      $25,$03,$1E,$1A,$15,$2B,$03,$25,$15,$1C,$1B,$03
        DB      $11,$26,$25,$03,$0E,$28,$2B,$2D,$26,$2B,$03,$03
        DB      $03,$03,$03,$03,$03,$BE

; Fragment $31 at $C965; fixed German slot length $1E.
; Working speech: qul lutlhuH ghumeywIj.
K_F31:
        DB      $1E,$19,$28,$18,$03,$18,$28,$2A,$18,$1B,$28,$1B
        DB      $03,$1C,$1B,$28,$0C,$3B,$29,$2D,$27,$1E,$1A,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $32 at $C984; fixed German slot length $2F.
; Working speech: nISwI' tIHmeywIjmo' bImeQ.
K_F32:
        DB      $2F,$8D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$0C,$26,$03,$0E,$27,$0C,$3B
        DB      $19,$1B,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $28 at $C9B4; fixed German slot length $2B.
; Working speech: Garwor Thorwor je tISo'moH!
K_F28:
        DB      $2B,$9C,$15,$2B,$2D,$26,$2B,$03,$2A,$1B,$26,$2B
        DB      $2D,$26,$2B,$03,$1E,$1A,$3B,$03,$2A,$27,$11,$26
        DB      $03,$0C,$26,$1B,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $33 at $C9E0; fixed German slot length $38.
; Working speech: Doq Thorwor, QeH 'ej ghung.
K_F33:
        DB      $38,$9E,$26,$19,$03,$2A,$1B,$26,$2B,$2D,$26,$2B
        DB      $03,$19,$1B,$3B,$1B,$03,$3B,$1E,$1A,$03,$1C,$1B
        DB      $28,$14,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $34 at $CA19; fixed German slot length $36.
; Working speech: SuvwI', qaSumchoH.
K_F34:
        DB      $36,$11,$28,$0F,$2D,$27,$03,$19,$15,$11,$28,$0C
        DB      $2A,$10,$26,$1B,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $37 at $CA50; fixed German slot length $07.
; Working speech: SuvwI' (padded)
K_F37:
        DB      $07,$91,$28,$0F,$2D,$27,$3E,$83

; Fragment $38 at $CA58; fixed German slot length $03.
; Working speech: DuQIHpu'.
K_F38:
        DB      $03,$1E,$28,$3E

; Fragment $52 at $CA5C; fixed German slot length $12.
; Klingon grammar helper: yIghomqa'.
K_F52:
        DB      $12,$29,$27,$1C,$1B,$26,$0C,$19,$15,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $39 at $CA6F; fixed German slot length $1C.
; Working speech: nISwI' yIchop.
K_F39:
        DB      $1C,$8D,$27,$11,$2D,$27,$03,$29,$27,$2A,$10,$26
        DB      $25,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $3A at $CA8C; fixed German slot length $1E.
; Working speech: nISwI' tIH DaparHa''a'?
K_F3A:
        DB      $1E,$0D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$03,$1E
        DB      $15,$25,$15,$2B,$1B,$15,$03,$15,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $3B at $CAAB; fixed German slot length $27.
; Working speech: nom jolwI'wIj Qap.
K_F3B:
        DB      $27,$8D,$26,$0C,$03,$1E,$1A,$26,$18,$2D,$27,$03
        DB      $2D,$27,$1E,$1A,$03,$19,$1B,$15,$25,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$BE

; Fragment $3C at $CAD3; fixed German slot length $2D.
; Working speech: DaH 'IDnarwIj DaSov.
K_F3C:
        DB      $2D,$9E,$15,$1B,$03,$27,$1E,$0D,$15,$2B,$2D,$27
        DB      $1E,$1A,$03,$1E,$15,$11,$26,$0F,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $3D at $CB01; fixed German slot length $20.
; Working speech: chaq maghomqa'.
K_F3D:
        DB      $20,$2A,$10,$15,$19,$03,$0C,$15,$1C,$1B,$26,$0C
        DB      $19,$15,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $3E at $CB22; fixed German slot length $2F.
; Working speech: QoQ 'oH jorlIj'e'.
K_F3E:
        DB      $2F,$19,$1B,$26,$19,$1B,$03,$26,$1B,$03,$1E,$1A
        DB      $26,$2B,$18,$27,$1E,$1A,$03,$3B,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $3F at $CB52; fixed German slot length $12.
; Working speech: vIjatlhqa'.
K_F3F:
        DB      $12,$0F,$27,$1E,$1A,$15,$2A,$18,$1B,$19,$15,$03
        DB      $03,$03,$03,$03,$03,$03,$3E

; Fragment $42 at $CB65; fixed German slot length $34.
; Working speech: yIghuH! QemjIq DaghoS.
K_F42:
        DB      $34,$A9,$27,$1C,$1B,$28,$1B,$3E,$19,$1B,$3B,$0C
        DB      $1E,$1A,$27,$19,$03,$1E,$15,$1C,$1B,$26,$11,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $43 at $CB9A; fixed German slot length $21.
; Working speech: QemjIqDaq He'lIj ghoS.
K_F43:
        DB      $21,$99,$1B,$3B,$0C,$1E,$1A,$27,$19,$1E,$15,$19
        DB      $03,$1B,$3B,$03,$18,$27,$1E,$1A,$03,$1C,$1B,$26
        DB      $11,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $44 at $CBBC; fixed German slot length $2B.
; Working speech: Wor bIghHa'mey qoDDaq yIghoS.
K_F44:
        DB      $2B,$AD,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03
        DB      $0C,$3B,$29,$03,$19,$26,$1E,$1E,$15,$19,$03,$29
        DB      $27,$1C,$1B,$26,$11,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $45 at $CBE8; fixed German slot length $29.
; Working speech: yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
K_F45:
        DB      $29,$A9,$27,$1C,$1B,$28,$1B,$3E,$11,$28,$0F,$2D
        DB      $27,$03,$1E,$1A,$26,$1B,$03,$0E,$27,$1C,$1B,$1B
        DB      $15,$03,$0C,$3B,$29,$1E,$15,$19,$03,$11,$26,$1B
        DB      $03,$03,$03,$03,$03,$BE

; Fragment $46 at $CC12; fixed German slot length $40.
; Working speech: DaSo' 'e' DaQub; bIghHa' pIn jIH.
K_F46:
        DB      $40,$9E,$15,$11,$26,$03,$3B,$03,$1E,$15,$19,$1B
        DB      $28,$0E,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$25,$27
        DB      $0D,$03,$1E,$1A,$27,$1B,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$BE

; Fragment $47 at $CC53; fixed German slot length $1E.
; Working speech: Thor, Bur, Gar! SopmeH yIghuH.
K_F47:
        DB      $1E,$AA,$1B,$26,$2B,$03,$0E,$28,$2B,$03,$1C,$15
        DB      $2B,$3E,$11,$26,$25,$0C,$3B,$1B,$03,$29,$27,$1C
        DB      $1B,$28,$1B,$03,$03,$03,$BE

; Fragment $48 at $CC72; fixed German slot length $26.
; Working speech: DaSlIj yIrar!
K_F48:
        DB      $26,$1E,$55,$51,$58,$27,$1E,$1A,$03,$29,$27,$2B
        DB      $15,$2B,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$3E

; Fragment $49 at $CC99; fixed German slot length $3A.
; Working speech: SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.
K_F49:
        DB      $3A,$91,$28,$0F,$2D,$27,$03,$1E,$1A,$26,$1B,$03
        DB      $0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$19,$3B,$2A,$03,$1B,$15,$03,$1E,$27,$0E
        DB      $15,$1B,$0C,$3B,$29,$2D,$27,$1E,$1A,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$BE

; Fragment $4A at $CCD4; fixed German slot length $35.
; Working speech: DaH yImI'; latlh DuH Daghajbe'.
K_F4A:
        DB      $35,$1E,$15,$1B,$03,$29,$27,$0C,$27,$03,$18,$15
        DB      $2A,$18,$1B,$03,$1E,$28,$1B,$03,$1E,$15,$1C,$1B
        DB      $15,$1E,$1A,$0E,$3B,$83,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$BE

; Fragment $4B at $CD0A; fixed German slot length $40.
; Working speech: QemjIqDaq bIyInlaH'a'?
K_F4B:
        DB      $40,$99,$1B,$3B,$0C,$1E,$1A,$27,$19,$9E,$15,$19
        DB      $03,$0E,$27,$29,$27,$0D,$18,$15,$1B,$03,$15,$03
        DB      $83,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$83,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$83,$03,$03
        DB      $03,$03,$03,$03,$3E

; Fragment $4C at $CD4B; fixed German slot length $20.
; Working speech: toH! reDmey vIlIjpu'.
K_F4C:
        DB      $20,$2A,$26,$1B,$3E,$2B,$3B,$1E,$0C,$3B,$29,$03
        DB      $0F,$27,$18,$27,$1E,$1A,$25,$28,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$3E

; Fragment $4D at $CD6C; fixed German slot length $20.
; Working speech: nuqDaq DaSo'?
K_F4D:
        DB      $20,$8D,$28,$19,$1E,$15,$19,$03,$1E,$15,$11,$26
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        DB      $03,$03,$03,$03,$03,$03,$03,$03,$BE

; 84-entry fragment pointer table at $CD8D. $4F is the only null slot.
K_PTRS:
        DB      $00,$C2,$2A,$C2,$6C,$C2,$07,$C3,$84,$C2,$94,$C2
        DB      $BE,$C2,$E3,$C2,$41,$C4,$62,$C4,$BA,$C5,$D0,$C5
        DB      $E0,$C5,$F4,$C5,$00,$C6,$32,$C6,$5E,$C6,$69,$C6
        DB      $94,$C6,$C4,$C6,$F6,$C6,$16,$C7,$53,$C7,$89,$C7
        DB      $BE,$C7,$F2,$C7,$69,$C4,$2E,$C4,$9C,$C4,$D3,$C4
        DB      $04,$C5,$29,$C5,$88,$C5,$59,$C5,$11,$C3,$3E,$C3
        DB      $64,$C3,$A5,$C3,$DE,$C3,$FB,$C3,$B4,$C9,$04,$C8
        DB      $2E,$C8,$50,$C8,$8E,$C8,$B7,$C8,$D5,$C8,$0B,$C9
        DB      $3B,$C9,$65,$C9,$84,$C9,$E0,$C9,$19,$CA,$85,$C4
        DB      $B8,$C6,$50,$CA,$58,$CA,$6F,$CA,$8C,$CA,$AB,$CA
        DB      $D3,$CA,$01,$CB,$22,$CB,$52,$CB,$3F,$C7,$48,$C7
        DB      $65,$CB,$9A,$CB,$BC,$CB,$E8,$CB,$12,$CC,$53,$CC
        DB      $72,$CC,$99,$CC,$D4,$CC,$0A,$CD,$4B,$CD,$6C,$CD
        DB      $5B,$C2,$00,$00,$79,$C2,$74,$C5,$5C,$CA,$F6,$C7

; Klingon language-local phrase table at $CE35: 80 phrase IDs, 230 bytes.
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

; Two erased bytes preserve the checksum-compensation address at $CF1D.
K_PFILL:
        DB      $FF,$FF

K_CSUM:
        DB      $DC

; Erased ROM area through $CFEA.
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
