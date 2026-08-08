; KLINGON_X11.asm
;==============================================================================
; Wizard of Wor - Klingon X11 Foreign-Language ROM
;==============================================================================
;
; Experimental 4 KiB language ROM for the Wizard of Wor X11 socket.
; The layout follows the documented German X11 ABI: 23 localized display
; strings, language-local speech fragment and phrase tables, optional font
; storage, and a complete-ROM additive checksum.
;
; Speech translation and SC-01 synthesis are a first-pass engineering draft.
; Canonical tlhIngan Hol orthography is retained in comments and documentation.
; The arcade display strings use a restricted uppercase transliteration because
; the resident text scanner treats bytes below $30 as record boundaries.
;==============================================================================

        NOLIST
;                               ; no EQUates
        LIST
        ORG     $C000

X11_Speech_Fragment_Table_Ptr:
        DW      Klingon_Speech_Fragment_Pointers

X11_Speech_Phrase_Table_Ptr:
        DW      Klingon_Speech_Phrase_Table

X11_Coinage_Value_Table:
        DB      $10,$20,$30,$40,$70,$50

X11_ROM_Checksum_Expected:
        DB      $00

X11_Alternate_Font_Ptr:
        DW      Klingon_Alternate_Font

; Twenty-three localized display strings. The second comment line preserves the
; canonical tlhIngan Hol wording; emitted bytes are display-safe transliteration.
Klingon_Localized_Text_Table:
; Text $01: English source "INSERT COIN"
; tlhIngan Hol: Huch yIlan
        DB      $0A,"HUCH@YILAN"

; Text $02: English source "HIGH SCORES"
; tlhIngan Hol: mIvwa' nIv
        DB      $09,"MIVWA@NIV"

; Text $03: English source "PRESS ONE PLAYER BUTTON"
; tlhIngan Hol: wa' QujwI' DuQwI' yIyuv
        DB      $14,"WA@QUJWI@DUQWI@YIYUV"

; Text $04: English source "PRESS TWO PLAYER BUTTON"
; tlhIngan Hol: cha' QujwI' DuQwI' yIyuv
        DB      $15,"CHA@QUJWI@DUQWI@YIYUV"

; Text $05: English source "OR"
; tlhIngan Hol: ghap
        DB      $04,"GHAP"

; Text $06: English source "DEPOSIT ADDITIONAL COIN"
; tlhIngan Hol: latlh Huch yIlan
        DB      $10,"LATLH@HUCH@YILAN"

; Text $07: English source "FOR TWO PLAYER GAME"
; tlhIngan Hol: cha' QujwI' QujmeH
        DB      $10,"CHA@QUJWI@QUJMEH"

; Text $08: English source "POINTS"
; tlhIngan Hol: mIvwa'
        DB      $05,"MIVWA"

; Text $09: English source "BONUS PLAYER"
; tlhIngan Hol: latlh QujwI'
        DB      $0B,"LATLH@QUJWI"

; Text $0A: English source "WAIT FOR INSTRUCTIONS"
; tlhIngan Hol: ra'mey yIloS
        DB      $0B,"RAMEY@YILOS"

; Text $0B: English source "INVISIBLE MONSTERS IN THE MAZE"
; tlhIngan Hol: He QatlhDaq So' Ha'DIbaHmey
        DB      $19,"HE@QATLHDAQ@SO@HADIBAHMEY"

; Text $0C: English source "ARE LOCATED USING THE RADAR SCREEN"
; tlhIngan Hol: HotlhwI' lo'lu'; Samlu'
        DB      $12,"HOTLHWI@LOLU@SAMLU"

; Text $0D: English source "MONSTERS BECOME VISIBLE WHEN ENTERING"
; tlhIngan Hol: 'elDI' Ha'DIbaHmey leghlu'
        DB      $16,"ELDI@HADIBAHMEY@LEGHLU"

; Text $0E: English source "THE SAME MAZE CORRIDOR AS THE PLAYER"
; tlhIngan Hol: QujwI' He'egh lu'el
        DB      $10,"QUJWI@HEEGH@LUEL"

; Text $0F: English source "GET READY"
; tlhIngan Hol: yIghuH
        DB      $06,"YIGHUH"

; Text $10: English source "RADAR"
; tlhIngan Hol: HotlhwI'
        DB      $07,"HOTLHWI"

; Text $11: English source "ESCAPED"
; tlhIngan Hol: narghpu'
        DB      $07,"NARGHPU"

; Text $12: English source "CREDITS"
; tlhIngan Hol: Huch
        DB      $04,"HUCH"

; Text $13: English source "DUNGEON"
; tlhIngan Hol: bIghHa'
        DB      $06,"BIGHHA"

; Text $14: English source "WORLORD DUNGEON"
; tlhIngan Hol: SuvwI' joH bIghHa'
        DB      $10,"SUVWI@JOH@BIGHHA"

; Text $15: English source "THE ARENA"
; tlhIngan Hol: SuvmeH Daq
        DB      $0A,"SUVMEH@DAQ"

; Text $16: English source "THE PIT"
; tlhIngan Hol: QemjIq
        DB      $06,"QEMJIQ"

; Text $17: English source "OR FOR ADDITIONAL WORRIORS"
; tlhIngan Hol: qoj latlh SuvwI'
        DB      $0F,"QOJ@LATLH@SUVWI"

; No alternate glyphs are required by the display-safe transliteration.
Klingon_Alternate_Font:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF

;==============================================================================
; KLINGON SPEECH FRAGMENTS
;
; Each record is a length byte followed by direct SC-01 command bytes.
; Bits 6-7 are zero in this first pass, selecting the base inflection.
; The main program still performs its normal stateful speech decoding.
; Fragment $09/$37 and $40/$41 preserve the Worrior -> Worlord runtime ABI.
;==============================================================================

; Fragment $00: phrase $00
; tlhIngan Hol: Huch yIlan.
; SC-01: H U T CH PA0 Y I L AH1 N PA1
Klingon_Speech_Fragment_00:
        DB      $0B
        DB      $1B,$28,$2A,$10,$03,$29,$27,$18
        DB      $15,$0D,$3E

; Fragment $01: phrase $01
; tlhIngan Hol: HISam, Wor 'IDnar pIn.
; SC-01: H I SH AH1 M PA0 W O R PA0 I D N AH1 R PA0 P I N PA1
Klingon_Speech_Fragment_01:
        DB      $14
        DB      $1B,$27,$11,$15,$0C,$03,$2D,$26
        DB      $2B,$03,$27,$1E,$0D,$15,$2B,$03
        DB      $25,$27,$0D,$3E

; Fragment $02: phrase $03
; tlhIngan Hol: jISo'. Ha ha ha ha!
; SC-01: D J I SH O PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_02:
        DB      $12
        DB      $1E,$1A,$27,$11,$26,$3E,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$3E

; Fragment $03: phrase $08 prefix
; tlhIngan Hol: yIghuH
; SC-01: Y I G H U H PA1
Klingon_Speech_Fragment_03:
        DB      $07
        DB      $29,$27,$1C,$1B,$28,$1B,$3E

; Fragment $04: phrase $08 suffix
; tlhIngan Hol: .
; SC-01: PA1
Klingon_Speech_Fragment_04:
        DB      $01
        DB      $3E

; Fragment $05: phrase $09
; tlhIngan Hol: HISambe' 'e' yItul, Wor 'IDnar pIn.
; SC-01: H I SH AH1 M B EH PA0 EH PA0 Y I T U L PA0 W O R PA0 I D N AH1 R PA0 P I N PA1
Klingon_Speech_Fragment_05:
        DB      $1E
        DB      $1B,$27,$11,$15,$0C,$0E,$3B,$03
        DB      $3B,$03,$29,$27,$2A,$28,$18,$03
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$3E

; Fragment $06: phrase $0A
; tlhIngan Hol: latlh Huch vIHev.
; SC-01: L AH1 T L H PA0 H U T CH PA0 V I H EH V PA1
Klingon_Speech_Fragment_06:
        DB      $11
        DB      $18,$15,$2A,$18,$1B,$03,$1B,$28
        DB      $2A,$10,$03,$0F,$27,$1B,$3B,$0F
        DB      $3E

; Fragment $07: phrase $0B
; tlhIngan Hol: maj! ghumeywIj ghungqu'. Ha ha ha ha!
; SC-01: M AH1 D J PA1 G H U M EH Y W I D J PA0 G H U NG K U PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_07:
        DB      $23
        DB      $0C,$15,$1E,$1A,$3E,$1C,$1B,$28
        DB      $0C,$3B,$29,$2D,$27,$1E,$1A,$03
        DB      $1C,$1B,$28,$14,$19,$28,$3E,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$3E

; Fragment $08: phrase $0C
; tlhIngan Hol: SuvwI'HommeywIj ghungqu'. Ha ha ha ha!
; SC-01: SH U V W I PA0 H O M M EH Y W I D J PA0 G H U NG K U PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_08:
        DB      $24
        DB      $11,$28,$0F,$2D,$27,$03,$1B,$26
        DB      $0C,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $03,$1C,$1B,$28,$14,$19,$28,$3E
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$3E

; Fragment $09: Worrior rank token
; tlhIngan Hol: SuvwI'
; SC-01: SH U V W I PA1
Klingon_Speech_Fragment_09:
        DB      $06
        DB      $11,$28,$0F,$2D,$27,$3E

; Fragment $0A: phrase $0D
; tlhIngan Hol: Wor qo'Daq yI'el.
; SC-01: W O R PA0 K O PA0 D AH1 K PA0 Y I PA0 EH L PA1
Klingon_Speech_Fragment_0A:
        DB      $11
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E
        DB      $15,$19,$03,$29,$27,$03,$3B,$18
        DB      $3E

; Fragment $0B: phrase $0E
; tlhIngan Hol: Wor qo'Daq mIvwa' DaSuq. Ha ha ha ha!
; SC-01: W O R PA0 K O PA0 D AH1 K PA0 M I V W AH1 PA0 D AH1 SH U K PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_0B:
        DB      $23
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E
        DB      $15,$19,$03,$0C,$27,$0F,$2D,$15
        DB      $03,$1E,$15,$11,$28,$19,$3E,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$3E

; Fragment $0C: phrase $0F
; tlhIngan Hol: Wor 'IDnar pIn Daghom. Ha ha ha ha!
; SC-01: W O R PA0 I D N AH1 R PA0 P I N PA0 D AH1 G H O M PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_0C:
        DB      $21
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$03,$1E,$15
        DB      $1C,$1B,$26,$0C,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $0D: phrase $10
; tlhIngan Hol: Worluk yIHoH. cha'logh mIvwa' DaSuq.
; SC-01: W O R L UH K PA0 Y I H O H PA1 T CH AH1 PA0 L O G H PA0 M I V W AH1 PA0 D AH1 SH U K PA1
Klingon_Speech_Fragment_0D:
        DB      $22
        DB      $2D,$26,$2B,$18,$33,$19,$03,$29
        DB      $27,$1B,$26,$1B,$3E,$2A,$10,$15
        DB      $03,$18,$26,$1C,$1B,$03,$0C,$27
        DB      $0F,$2D,$15,$03,$1E,$15,$11,$28
        DB      $19,$3E

; Fragment $0E: phrase $11
; tlhIngan Hol: Wor bIghHa'meyDaq SoH.
; SC-01: W O R PA0 B I G H H AH1 PA0 M EH Y D AH1 K PA0 SH O H PA1
Klingon_Speech_Fragment_0E:
        DB      $16
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B
        DB      $1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$11,$26,$1B,$3E

; Fragment $0F: phrase $12
; tlhIngan Hol: Wor 'IDnar pIn jIH.
; SC-01: W O R PA0 I D N AH1 R PA0 P I N PA0 D J I H PA1
Klingon_Speech_Fragment_0F:
        DB      $13
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$03,$1E,$1A
        DB      $27,$1B,$3E

; Fragment $10: phrase $13
; tlhIngan Hol: DuchopDI' ghumeywIj, bIjor. Ha ha ha ha!
; SC-01: D U T CH O P D I PA0 G H U M EH Y W I D J PA0 B I D J O R PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_10:
        DB      $27
        DB      $1E,$28,$2A,$10,$26,$25,$1E,$27
        DB      $03,$1C,$1B,$28,$0C,$3B,$29,$2D
        DB      $27,$1E,$1A,$03,$0E,$27,$1E,$1A
        DB      $26,$2B,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $11: phrase $14
; tlhIngan Hol: Qob Ha'DIbaHmeywIj.
; SC-01: K H O B PA0 H AH1 PA0 D I B AH1 H M EH Y W I D J PA1
Klingon_Speech_Fragment_11:
        DB      $15
        DB      $19,$1B,$26,$0E,$03,$1B,$15,$03
        DB      $1E,$27,$0E,$15,$1B,$0C,$3B,$29
        DB      $2D,$27,$1E,$1A,$3E

; Fragment $12: phrase $15
; tlhIngan Hol: lojmIt vegh Worluk 'ej nargh.
; SC-01: L O D J M I T PA0 V EH G H PA0 W O R L UH K PA0 EH D J PA0 N AH1 R G H PA1
Klingon_Speech_Fragment_12:
        DB      $1E
        DB      $18,$26,$1E,$1A,$0C,$27,$2A,$03
        DB      $0F,$3B,$1C,$1B,$03,$2D,$26,$2B
        DB      $18,$33,$19,$03,$3B,$1E,$1A,$03
        DB      $0D,$15,$2B,$1C,$1B,$3E

; Fragment $13: phrase $16 prefix
; tlhIngan Hol: HotlhwI' yIbej
; SC-01: H O T L H W I PA0 Y I B EH D J PA1
Klingon_Speech_Fragment_13:
        DB      $0F
        DB      $1B,$26,$2A,$18,$1B,$2D,$27,$03
        DB      $29,$27,$0E,$3B,$1E,$1A,$3E

; Fragment $14: phrase $17
; tlhIngan Hol: Doq Thorwor, QeH 'ej ghung. Ha ha ha ha!
; SC-01: D O K PA0 TH O R W O R PA0 K H EH H PA0 EH D J PA0 G H U NG PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_14:
        DB      $25
        DB      $1E,$26,$19,$03,$39,$26,$2B,$2D
        DB      $26,$2B,$03,$19,$1B,$3B,$1B,$03
        DB      $3B,$1E,$1A,$03,$1C,$1B,$28,$14
        DB      $3E,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E

; Fragment $15: phrase $18
; tlhIngan Hol: yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
; SC-01: Y I K AH1 W PA0 W O R PA0 I D N AH1 R PA0 P I N PA0 D J I H PA0 SH O H B EH PA1
Klingon_Speech_Fragment_15:
        DB      $1F
        DB      $29,$27,$19,$15,$2D,$03,$2D,$26
        DB      $2B,$03,$27,$1E,$0D,$15,$2B,$03
        DB      $25,$27,$0D,$03,$1E,$1A,$27,$1B
        DB      $03,$11,$26,$1B,$0E,$3B,$3E

; Fragment $16: phrase $19
; tlhIngan Hol: Hoch DanIvbe'chugh, bIluj. Ha ha ha ha!
; SC-01: H O T CH PA0 D AH1 N I V B EH PA0 T CH U G H PA0 B I L U D J PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_16:
        DB      $26
        DB      $1B,$26,$2A,$10,$03,$1E,$15,$0D
        DB      $27,$0F,$0E,$3B,$03,$2A,$10,$28
        DB      $1C,$1B,$03,$0E,$27,$18,$28,$1E
        DB      $1A,$3E,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E

; Fragment $17: phrase $1A
; tlhIngan Hol: Worvo' bIyIntaHvIS bImejbe'. Ha ha ha ha!
; SC-01: W O R V O PA0 B I Y I N T AH1 H V I SH PA0 B I M EH D J B EH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_17:
        DB      $27
        DB      $2D,$26,$2B,$0F,$26,$03,$0E,$27
        DB      $29,$27,$0D,$2A,$15,$1B,$0F,$27
        DB      $11,$03,$0E,$27,$0C,$3B,$1E,$1A
        DB      $0E,$3B,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $18: phrase $1B
; tlhIngan Hol: ghumeywIj DaQaw'chugh, qulDaq qameQmoH. Ha ha ha ha!
; SC-01: G H U M EH Y W I D J PA0 D AH1 K H AH1 W PA0 T CH U G H PA0 K U L D AH1 K PA0 K AH1 M EH K H M O H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_18:
        DB      $35
        DB      $1C,$1B,$28,$0C,$3B,$29,$2D,$27
        DB      $1E,$1A,$03,$1E,$15,$19,$1B,$15
        DB      $2D,$03,$2A,$10,$28,$1C,$1B,$03
        DB      $19,$28,$18,$1E,$15,$19,$03,$19
        DB      $15,$0C,$3B,$19,$1B,$0C,$26,$1B
        DB      $3E,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E

; Fragment $19: phrase $1C
; tlhIngan Hol: qaStaHvIS 'op jar pagh Sop Burwor. Ha ha ha ha!
; SC-01: K AH1 SH T AH1 H V I SH PA0 O P PA0 D J AH1 R PA0 P AH1 G H PA0 SH O P PA0 B ER R W O R PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_19:
        DB      $2E
        DB      $19,$15,$11,$2A,$15,$1B,$0F,$27
        DB      $11,$03,$26,$25,$03,$1E,$1A,$15
        DB      $2B,$03,$25,$15,$1C,$1B,$03,$11
        DB      $26,$25,$03,$0E,$3A,$2B,$2D,$26
        DB      $2B,$3E,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E

; Fragment $1A: phrase $1D prefix
; tlhIngan Hol: qul lutlhuH ghumeywIj
; SC-01: K U L PA0 L U T L H U H PA0 G H U M EH Y W I D J PA1
Klingon_Speech_Fragment_1A:
        DB      $17
        DB      $19,$28,$18,$03,$18,$28,$2A,$18
        DB      $1B,$28,$1B,$03,$1C,$1B,$28,$0C
        DB      $3B,$29,$2D,$27,$1E,$1A,$3E

; Fragment $1B: phrase $1E
; tlhIngan Hol: nISwI' tIHmeywIjmo' bImeQ.
; SC-01: N I SH W I PA0 T I H M EH Y W I D J M O PA0 B I M EH K H PA1
Klingon_Speech_Fragment_1B:
        DB      $1A
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27
        DB      $1B,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $0C,$26,$03,$0E,$27,$0C,$3B,$19
        DB      $1B,$3E

; Fragment $1C: phrase $1F
; tlhIngan Hol: Burwor Garwor Thorwor je DuHoH.
; SC-01: B ER R W O R PA0 G AH1 R W O R PA0 TH O R W O R PA0 D J EH PA0 D U H O H PA1
Klingon_Speech_Fragment_1C:
        DB      $1F
        DB      $0E,$3A,$2B,$2D,$26,$2B,$03,$1C
        DB      $15,$2B,$2D,$26,$2B,$03,$39,$26
        DB      $2B,$2D,$26,$2B,$03,$1E,$1A,$3B
        DB      $03,$1E,$28,$1B,$26,$1B,$3E

; Fragment $1D: phrase $20
; tlhIngan Hol: SuvmeH DaqDaq bIghoS. Ha ha ha ha!
; SC-01: SH U V M EH H PA0 D AH1 K D AH1 K PA0 B I G H O SH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_1D:
        DB      $21
        DB      $11,$28,$0F,$0C,$3B,$1B,$03,$1E
        DB      $15,$19,$1E,$15,$19,$03,$0E,$27
        DB      $1C,$1B,$26,$11,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $1E: phrase $21 prefix
; tlhIngan Hol: latlh
; SC-01: L AH1 T L H PA1
Klingon_Speech_Fragment_1E:
        DB      $06
        DB      $18,$15,$2A,$18,$1B,$3E

; Fragment $1F: phrase $21 suffix
; tlhIngan Hol: luSop ghumeywIj.
; SC-01: L U SH O P PA0 G H U M EH Y W I D J PA1
Klingon_Speech_Fragment_1F:
        DB      $11
        DB      $18,$28,$11,$26,$25,$03,$1C,$1B
        DB      $28,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $3E

; Fragment $20: phrase $22
; tlhIngan Hol: yItaH; HISam.
; SC-01: Y I T AH1 H PA0 H I SH AH1 M PA1
Klingon_Speech_Fragment_20:
        DB      $0C
        DB      $29,$27,$2A,$15,$1B,$03,$1B,$27
        DB      $11,$15,$0C,$3E

; Fragment $21: phrase $23
; tlhIngan Hol: SuvwI' joH SoH.
; SC-01: SH U V W I PA0 D J O H PA0 SH O H PA1
Klingon_Speech_Fragment_21:
        DB      $0F
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$03,$11,$26,$1B,$3E

; Fragment $22: phrase $24 suffix
; tlhIngan Hol: jIQeHchoH.
; SC-01: D J I K H EH H T CH O H PA1
Klingon_Speech_Fragment_22:
        DB      $0C
        DB      $1E,$1A,$27,$19,$1B,$3B,$1B,$2A
        DB      $10,$26,$1B,$3E

; Fragment $23: phrase $25
; tlhIngan Hol: qaSumchoH. Ha ha ha ha!
; SC-01: K AH1 SH U M T CH O H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_23:
        DB      $16
        DB      $19,$15,$11,$28,$0C,$2A,$10,$26
        DB      $1B,$3E,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E

; Fragment $24: phrase $26 suffix
; tlhIngan Hol: Qapla' Daghajbe'. Ha ha ha ha!
; SC-01: K H AH1 P L AH1 PA0 D AH1 G H AH1 D J B EH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_24:
        DB      $1D
        DB      $19,$1B,$15,$25,$18,$15,$03,$1E
        DB      $15,$1C,$1B,$15,$1E,$1A,$0E,$3B
        DB      $3E,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E

; Fragment $25: phrase $27 prefix
; tlhIngan Hol: Seng DaneH
; SC-01: SH EH NG PA0 D AH1 N EH H PA1
Klingon_Speech_Fragment_25:
        DB      $0A
        DB      $11,$3B,$14,$03,$1E,$15,$0D,$3B
        DB      $1B,$3E

; Fragment $26: phrase $28
; tlhIngan Hol: SuvwI'pu' HoSghaj DaSuv. Ha ha ha ha!
; SC-01: SH U V W I PA0 P U PA0 H O SH G H AH1 D J PA0 D AH1 SH U V PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_26:
        DB      $24
        DB      $11,$28,$0F,$2D,$27,$03,$25,$28
        DB      $03,$1B,$26,$11,$1C,$1B,$15,$1E
        DB      $1A,$03,$1E,$15,$11,$28,$0F,$3E
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$3E

; Fragment $27: phrase $29
; tlhIngan Hol: Garwor, yIHIv!
; SC-01: G AH1 R W O R PA0 Y I H I V PA1
Klingon_Speech_Fragment_27:
        DB      $0D
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$29
        DB      $27,$1B,$27,$0F,$3E

; Fragment $28: phrase $2A
; tlhIngan Hol: latlh DanIDchugh, bIHegh. Ha ha ha ha!
; SC-01: L AH1 T L H PA0 D AH1 N I D T CH U G H PA0 B I H EH G H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_28:
        DB      $24
        DB      $18,$15,$2A,$18,$1B,$03,$1E,$15
        DB      $0D,$27,$1E,$2A,$10,$28,$1C,$1B
        DB      $03,$0E,$27,$1B,$3B,$1C,$1B,$3E
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$3E

; Fragment $29: phrase $2B
; tlhIngan Hol: bIHoSghajqu'chugh, qamevmoH jIH. Ha ha ha ha!
; SC-01: B I H O SH G H AH1 D J K U PA0 T CH U G H PA0 K AH1 M EH V M O H PA0 D J I H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_29:
        DB      $2D
        DB      $0E,$27,$1B,$26,$11,$1C,$1B,$15
        DB      $1E,$1A,$19,$28,$03,$2A,$10,$28
        DB      $1C,$1B,$03,$19,$15,$0C,$3B,$0F
        DB      $0C,$26,$1B,$03,$1E,$1A,$27,$1B
        DB      $3E,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E

; Fragment $2A: phrase $2C prefix
; tlhIngan Hol: 'IDnarwIj HoS law' nuHmeylIj HoS puS
; SC-01: PA0 I D N AH1 R W I D J PA0 H O SH PA0 L AH1 W PA0 N U H M EH Y L I D J PA0 H O SH PA0 P U SH PA1
Klingon_Speech_Fragment_2A:
        DB      $26
        DB      $03,$27,$1E,$0D,$15,$2B,$2D,$27
        DB      $1E,$1A,$03,$1B,$26,$11,$03,$18
        DB      $15,$2D,$03,$0D,$28,$1B,$0C,$3B
        DB      $29,$18,$27,$1E,$1A,$03,$1B,$26
        DB      $11,$03,$25,$28,$11,$3E

; Fragment $2B: phrase $2D suffix
; tlhIngan Hol: QeD Daghoj; 'IDnar wIghoj.
; SC-01: K H EH D PA0 D AH1 G H O D J PA0 I D N AH1 R PA0 W I G H O D J PA1
Klingon_Speech_Fragment_2B:
        DB      $1B
        DB      $19,$1B,$3B,$1E,$03,$1E,$15,$1C
        DB      $1B,$26,$1E,$1A,$03,$27,$1E,$0D
        DB      $15,$2B,$03,$2D,$27,$1C,$1B,$26
        DB      $1E,$1A,$3E

; Fragment $2C: phrase $2E
; tlhIngan Hol: Wor bIghHa'meyDaq HomDu'lIj tu'lu'. Ha ha ha ha!
; SC-01: W O R PA0 B I G H H AH1 PA0 M EH Y D AH1 K PA0 H O M D U PA0 L I D J PA0 T U PA0 L U PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_2C:
        DB      $2F
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B
        DB      $1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$1B,$26,$0C,$1E,$28,$03
        DB      $18,$27,$1E,$1A,$03,$2A,$28,$03
        DB      $18,$28,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $2D: phrase $2F
; tlhIngan Hol: Garwor Thorwor je tISo'moH! Ha ha ha ha!
; SC-01: G AH1 R W O R PA0 TH O R W O R PA0 D J EH PA0 T I SH O PA0 M O H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_2D:
        DB      $27
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$39
        DB      $26,$2B,$2D,$26,$2B,$03,$1E,$1A
        DB      $3B,$03,$2A,$27,$11,$26,$03,$0C
        DB      $26,$1B,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $2E: phrase $30
; tlhIngan Hol: Wor 'IDnar pIn yIghomqa'. Ha ha ha ha!
; SC-01: W O R PA0 I D N AH1 R PA0 P I N PA0 Y I G H O M K AH1 PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_2E:
        DB      $23
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$03,$29,$27
        DB      $1C,$1B,$26,$0C,$19,$15,$3E,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$3E

; Fragment $2F: phrase $31 prefix
; tlhIngan Hol: Wor bIghHa'meyDaq bIchegh
; SC-01: W O R PA0 B I G H H AH1 PA0 M EH Y D AH1 K PA0 B I T CH EH G H PA1
Klingon_Speech_Fragment_2F:
        DB      $1A
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B
        DB      $1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$0E,$27,$2A,$10,$3B,$1C
        DB      $1B,$3E

; Fragment $30: phrase $32 prefix
; tlhIngan Hol: Wor DISmeyDaq HISam
; SC-01: W O R PA0 D I SH M EH Y D AH1 K PA0 H I SH AH1 M PA1
Klingon_Speech_Fragment_30:
        DB      $14
        DB      $2D,$26,$2B,$03,$1E,$27,$11,$0C
        DB      $3B,$29,$1E,$15,$19,$03,$1B,$27
        DB      $11,$15,$0C,$3E

; Fragment $31: phrase $33
; tlhIngan Hol: Wor 'IDnar pIn Dutlho'.
; SC-01: W O R PA0 I D N AH1 R PA0 P I N PA0 D U T L H O PA1
Klingon_Speech_Fragment_31:
        DB      $15
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$03,$1E,$28
        DB      $2A,$18,$1B,$26,$3E

; Fragment $32: phrase $34 prefix
; tlhIngan Hol: bIQapla'laH
; SC-01: B I K H AH1 P L AH1 PA0 L AH1 H PA1
Klingon_Speech_Fragment_32:
        DB      $0D
        DB      $0E,$27,$19,$1B,$15,$25,$18,$15
        DB      $03,$18,$15,$1B,$3E

; Fragment $33: phrase $35
; tlhIngan Hol: nom yIchegh; qaloS.
; SC-01: N O M PA0 Y I T CH EH G H PA0 K AH1 L O SH PA1
Klingon_Speech_Fragment_33:
        DB      $12
        DB      $0D,$26,$0C,$03,$29,$27,$2A,$10
        DB      $3B,$1C,$1B,$03,$19,$15,$18,$26
        DB      $11,$3E

; Fragment $34: phrase $36
; tlhIngan Hol: Qu' Dachuqa'laH; DaH bIluj. Ha ha ha ha!
; SC-01: K H U PA0 D AH1 T CH U K AH1 PA0 L AH1 H PA0 D AH1 H PA0 B I L U D J PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_34:
        DB      $27
        DB      $19,$1B,$28,$03,$1E,$15,$2A,$10
        DB      $28,$19,$15,$03,$18,$15,$1B,$03
        DB      $1E,$15,$1B,$03,$0E,$27,$18,$28
        DB      $1E,$1A,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $35: phrase $37
; tlhIngan Hol: He he he, ho ho ho, ha ha ha ha! maj.
; SC-01: H EH PA0 H EH PA0 H EH PA0 H O PA0 H O PA0 H O PA0 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1 M AH1 D J PA1
Klingon_Speech_Fragment_35:
        DB      $23
        DB      $1B,$3B,$03,$1B,$3B,$03,$1B,$3B
        DB      $03,$1B,$26,$03,$1B,$26,$03,$1B
        DB      $26,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E,$0C,$15
        DB      $1E,$1A,$3E

; Fragment $36: phrase $38
; tlhIngan Hol: Wor 'IDnar pIn DuQIHpu'. Ha ha ha ha!
; SC-01: W O R PA0 I D N AH1 R PA0 P I N PA0 D U K H I H P U PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_36:
        DB      $23
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15
        DB      $2B,$03,$25,$27,$0D,$03,$1E,$28
        DB      $19,$1B,$27,$1B,$25,$28,$3E,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$3E

; Fragment $37: Worrior rank token, padded
; tlhIngan Hol: SuvwI'
; SC-01: PA0 SH U V W I PA1 PA0
Klingon_Speech_Fragment_37:
        DB      $08
        DB      $03,$11,$28,$0F,$2D,$27,$3E,$03

; Fragment $38: phrase $39 prefix
; tlhIngan Hol: nISwI' yIchop
; SC-01: N I SH W I PA0 Y I T CH O P PA1
Klingon_Speech_Fragment_38:
        DB      $0D
        DB      $0D,$27,$11,$2D,$27,$03,$29,$27
        DB      $2A,$10,$26,$25,$3E

; Fragment $39: phrase $39 suffix
; tlhIngan Hol: . Ha ha ha ha!
; SC-01: H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_39:
        DB      $0C
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$3E

; Fragment $3A: phrase $3A
; tlhIngan Hol: nISwI' tIH DaparHa''a'? Ha ha ha ha!
; SC-01: N I SH W I PA0 T I H PA0 D AH1 P AH1 R H AH1 PA0 AH1 PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_3A:
        DB      $20
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27
        DB      $1B,$03,$1E,$15,$25,$15,$2B,$1B
        DB      $15,$03,$15,$3E,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$3E

; Fragment $3B: phrase $3B
; tlhIngan Hol: nom jolwI'wIj Qap. Ha ha ha ha!
; SC-01: N O M PA0 D J O L W I PA0 W I D J PA0 K H AH1 P PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_3B:
        DB      $21
        DB      $0D,$26,$0C,$03,$1E,$1A,$26,$18
        DB      $2D,$27,$03,$2D,$27,$1E,$1A,$03
        DB      $19,$1B,$15,$25,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $3C: phrase $3C prefix
; tlhIngan Hol: DaH 'IDnarwIj DaSov
; SC-01: D AH1 H PA0 I D N AH1 R W I D J PA0 D AH1 SH O V PA1
Klingon_Speech_Fragment_3C:
        DB      $14
        DB      $1E,$15,$1B,$03,$27,$1E,$0D,$15
        DB      $2B,$2D,$27,$1E,$1A,$03,$1E,$15
        DB      $11,$26,$0F,$3E

; Fragment $3D: phrase $3D suffix
; tlhIngan Hol: chaq maghomqa'.
; SC-01: T CH AH1 K PA0 M AH1 G H O M K AH1 PA1
Klingon_Speech_Fragment_3D:
        DB      $0E
        DB      $2A,$10,$15,$19,$03,$0C,$15,$1C
        DB      $1B,$26,$0C,$19,$15,$3E

; Fragment $3E: phrase $3E
; tlhIngan Hol: QoQ 'oH jorlIj'e'. Ha ha ha ha!
; SC-01: K H O K H PA0 O H PA0 D J O R L I D J PA0 EH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_3E:
        DB      $20
        DB      $19,$1B,$26,$19,$1B,$03,$26,$1B
        DB      $03,$1E,$1A,$26,$2B,$18,$27,$1E
        DB      $1A,$03,$3B,$3E,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$3E

; Fragment $3F: phrase $3F prefix
; tlhIngan Hol: vIjatlhqa'
; SC-01: V I D J AH1 T L H K AH1 PA1
Klingon_Speech_Fragment_3F:
        DB      $0B
        DB      $0F,$27,$1E,$1A,$15,$2A,$18,$1B
        DB      $19,$15,$3E

; Fragment $40: Worlord rank token
; tlhIngan Hol: SuvwI' joH
; SC-01: SH U V W I PA0 D J O H PA1
Klingon_Speech_Fragment_40:
        DB      $0B
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$3E

; Fragment $41: Worlord rank token, padded
; tlhIngan Hol: SuvwI' joH
; SC-01: PA0 SH U V W I PA0 D J O H PA1 PA0
Klingon_Speech_Fragment_41:
        DB      $0D
        DB      $03,$11,$28,$0F,$2D,$27,$03,$1E
        DB      $1A,$26,$1B,$3E,$03

; Fragment $42: phrase $40
; tlhIngan Hol: SuvwI' joH, yIghuH! QemjIq DaghoS. Ha ha ha ha!
; SC-01: SH U V W I PA0 D J O H PA0 Y I G H U H PA1 K H EH M D J I K PA0 D AH1 G H O SH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_42:
        DB      $2E
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$03,$29,$27,$1C,$1B,$28
        DB      $1B,$3E,$19,$1B,$3B,$0C,$1E,$1A
        DB      $27,$19,$03,$1E,$15,$1C,$1B,$26
        DB      $11,$3E,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$3E

; Fragment $43: phrase $41
; tlhIngan Hol: SuvwI' joH, QemjIqDaq He'lIj ghoS. Ha ha ha ha!
; SC-01: SH U V W I PA0 D J O H PA0 K H EH M D J I K D AH1 K PA0 H EH PA0 L I D J PA0 G H O SH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_43:
        DB      $30
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$03,$19,$1B,$3B,$0C,$1E
        DB      $1A,$27,$19,$1E,$15,$19,$03,$1B
        DB      $3B,$03,$18,$27,$1E,$1A,$03,$1C
        DB      $1B,$26,$11,$3E,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$3E

; Fragment $44: phrase $42
; tlhIngan Hol: Wor bIghHa'mey qoDDaq yIghoS. Ha ha ha ha!
; SC-01: W O R PA0 B I G H H AH1 PA0 M EH Y PA0 K O D D AH1 K PA0 Y I G H O SH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_44:
        DB      $29
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B
        DB      $1B,$15,$03,$0C,$3B,$29,$03,$19
        DB      $26,$1E,$1E,$15,$19,$03,$29,$27
        DB      $1C,$1B,$26,$11,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $45: phrase $43
; tlhIngan Hol: yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
; SC-01: Y I G H U H PA1 SH U V W I PA0 D J O H PA0 B I G H H AH1 PA0 M EH Y D AH1 K PA0 SH O H PA1
Klingon_Speech_Fragment_45:
        DB      $24
        DB      $29,$27,$1C,$1B,$28,$1B,$3E,$11
        DB      $28,$0F,$2D,$27,$03,$1E,$1A,$26
        DB      $1B,$03,$0E,$27,$1C,$1B,$1B,$15
        DB      $03,$0C,$3B,$29,$1E,$15,$19,$03
        DB      $11,$26,$1B,$3E

; Fragment $46: phrase $44
; tlhIngan Hol: DaSo' 'e' DaQub; bIghHa' pIn jIH. Ha ha ha ha!
; SC-01: D AH1 SH O PA0 EH PA0 D AH1 K H U B PA0 B I G H H AH1 PA0 P I N PA0 D J I H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_46:
        DB      $2A
        DB      $1E,$15,$11,$26,$03,$3B,$03,$1E
        DB      $15,$19,$1B,$28,$0E,$03,$0E,$27
        DB      $1C,$1B,$1B,$15,$03,$25,$27,$0D
        DB      $03,$1E,$1A,$27,$1B,$3E,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$3E

; Fragment $47: phrase $45
; tlhIngan Hol: Thor, Bur, Gar! SopmeH yIghuH. Ha ha ha ha!
; SC-01: T H O R PA0 B U R PA0 G AH1 R PA1 SH O P M EH H PA0 Y I G H U H PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_47:
        DB      $27
        DB      $2A,$1B,$26,$2B,$03,$0E,$28,$2B
        DB      $03,$1C,$15,$2B,$3E,$11,$26,$25
        DB      $0C,$3B,$1B,$03,$29,$27,$1C,$1B
        DB      $28,$1B,$3E,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E

; Fragment $48: phrase $46
; tlhIngan Hol: DaSlIj yIrar! Ha ha ha ha!
; SC-01: D AH1 SH L I D J PA0 Y I R AH1 R PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_48:
        DB      $1A
        DB      $1E,$15,$11,$18,$27,$1E,$1A,$03
        DB      $29,$27,$2B,$15,$2B,$3E,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$3E

; Fragment $49: phrase $47
; tlhIngan Hol: SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. Ha ha ha ha!
; SC-01: SH U V W I PA0 D J O H PA0 B I G H H AH1 PA0 M EH Y D AH1 K PA0 K EH T PA0 H AH1 PA0 D I B AH1 H M EH Y W I D J PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_49:
        DB      $39
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$03,$0E,$27,$1C,$1B,$1B
        DB      $15,$03,$0C,$3B,$29,$1E,$15,$19
        DB      $03,$19,$3B,$2A,$03,$1B,$15,$03
        DB      $1E,$27,$0E,$15,$1B,$0C,$3B,$29
        DB      $2D,$27,$1E,$1A,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $4A: phrase $48
; tlhIngan Hol: DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha!
; SC-01: D AH1 H PA0 Y I M I PA0 L AH1 T L H PA0 D U H PA0 D AH1 G H AH1 D J B EH PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_4A:
        DB      $29
        DB      $1E,$15,$1B,$03,$29,$27,$0C,$27
        DB      $03,$18,$15,$2A,$18,$1B,$03,$1E
        DB      $28,$1B,$03,$1E,$15,$1C,$1B,$15
        DB      $1E,$1A,$0E,$3B,$3E,$1B,$15,$03
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15
        DB      $3E

; Fragment $4B: phrase $49
; tlhIngan Hol: QemjIqDaq bIyInlaH'a'? Ha ha ha ha!
; SC-01: K H EH M D J I K D AH1 K PA0 B I Y I N L AH1 H PA0 AH1 PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_4B:
        DB      $23
        DB      $19,$1B,$3B,$0C,$1E,$1A,$27,$19
        DB      $1E,$15,$19,$03,$0E,$27,$29,$27
        DB      $0D,$18,$15,$1B,$03,$15,$3E,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$03
        DB      $1B,$15,$3E

; Fragment $4C: phrase $4A
; tlhIngan Hol: toH! reDmey vIlIjpu'. Ha ha ha ha!
; SC-01: T O H PA1 R EH D M EH Y PA0 V I L I D J P U PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_4C:
        DB      $20
        DB      $2A,$26,$1B,$3E,$2B,$3B,$1E,$0C
        DB      $3B,$29,$03,$0F,$27,$18,$27,$1E
        DB      $1A,$25,$28,$3E,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$3E

; Fragment $4D: phrase $4B
; tlhIngan Hol: nuqDaq DaSo'? Ha ha ha ha!
; SC-01: N U K D AH1 K PA0 D AH1 SH O PA1 H AH1 PA0 H AH1 PA0 H AH1 PA0 H AH1 PA1
Klingon_Speech_Fragment_4D:
        DB      $18
        DB      $0D,$28,$19,$1E,$15,$19,$03,$1E
        DB      $15,$11,$26,$3E,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$03,$1B,$15,$3E

;==============================================================================
; KLINGON SPEECH FRAGMENT POINTER TABLE
;==============================================================================
Klingon_Speech_Fragment_Pointers:
        DW      Klingon_Speech_Fragment_00      ; fragment $00
        DW      Klingon_Speech_Fragment_01      ; fragment $01
        DW      Klingon_Speech_Fragment_02      ; fragment $02
        DW      Klingon_Speech_Fragment_03      ; fragment $03
        DW      Klingon_Speech_Fragment_04      ; fragment $04
        DW      Klingon_Speech_Fragment_05      ; fragment $05
        DW      Klingon_Speech_Fragment_06      ; fragment $06
        DW      Klingon_Speech_Fragment_07      ; fragment $07
        DW      Klingon_Speech_Fragment_08      ; fragment $08
        DW      Klingon_Speech_Fragment_09      ; fragment $09
        DW      Klingon_Speech_Fragment_0A      ; fragment $0A
        DW      Klingon_Speech_Fragment_0B      ; fragment $0B
        DW      Klingon_Speech_Fragment_0C      ; fragment $0C
        DW      Klingon_Speech_Fragment_0D      ; fragment $0D
        DW      Klingon_Speech_Fragment_0E      ; fragment $0E
        DW      Klingon_Speech_Fragment_0F      ; fragment $0F
        DW      Klingon_Speech_Fragment_10      ; fragment $10
        DW      Klingon_Speech_Fragment_11      ; fragment $11
        DW      Klingon_Speech_Fragment_12      ; fragment $12
        DW      Klingon_Speech_Fragment_13      ; fragment $13
        DW      Klingon_Speech_Fragment_14      ; fragment $14
        DW      Klingon_Speech_Fragment_15      ; fragment $15
        DW      Klingon_Speech_Fragment_16      ; fragment $16
        DW      Klingon_Speech_Fragment_17      ; fragment $17
        DW      Klingon_Speech_Fragment_18      ; fragment $18
        DW      Klingon_Speech_Fragment_19      ; fragment $19
        DW      Klingon_Speech_Fragment_1A      ; fragment $1A
        DW      Klingon_Speech_Fragment_1B      ; fragment $1B
        DW      Klingon_Speech_Fragment_1C      ; fragment $1C
        DW      Klingon_Speech_Fragment_1D      ; fragment $1D
        DW      Klingon_Speech_Fragment_1E      ; fragment $1E
        DW      Klingon_Speech_Fragment_1F      ; fragment $1F
        DW      Klingon_Speech_Fragment_20      ; fragment $20
        DW      Klingon_Speech_Fragment_21      ; fragment $21
        DW      Klingon_Speech_Fragment_22      ; fragment $22
        DW      Klingon_Speech_Fragment_23      ; fragment $23
        DW      Klingon_Speech_Fragment_24      ; fragment $24
        DW      Klingon_Speech_Fragment_25      ; fragment $25
        DW      Klingon_Speech_Fragment_26      ; fragment $26
        DW      Klingon_Speech_Fragment_27      ; fragment $27
        DW      Klingon_Speech_Fragment_28      ; fragment $28
        DW      Klingon_Speech_Fragment_29      ; fragment $29
        DW      Klingon_Speech_Fragment_2A      ; fragment $2A
        DW      Klingon_Speech_Fragment_2B      ; fragment $2B
        DW      Klingon_Speech_Fragment_2C      ; fragment $2C
        DW      Klingon_Speech_Fragment_2D      ; fragment $2D
        DW      Klingon_Speech_Fragment_2E      ; fragment $2E
        DW      Klingon_Speech_Fragment_2F      ; fragment $2F
        DW      Klingon_Speech_Fragment_30      ; fragment $30
        DW      Klingon_Speech_Fragment_31      ; fragment $31
        DW      Klingon_Speech_Fragment_32      ; fragment $32
        DW      Klingon_Speech_Fragment_33      ; fragment $33
        DW      Klingon_Speech_Fragment_34      ; fragment $34
        DW      Klingon_Speech_Fragment_35      ; fragment $35
        DW      Klingon_Speech_Fragment_36      ; fragment $36
        DW      Klingon_Speech_Fragment_37      ; fragment $37
        DW      Klingon_Speech_Fragment_38      ; fragment $38
        DW      Klingon_Speech_Fragment_39      ; fragment $39
        DW      Klingon_Speech_Fragment_3A      ; fragment $3A
        DW      Klingon_Speech_Fragment_3B      ; fragment $3B
        DW      Klingon_Speech_Fragment_3C      ; fragment $3C
        DW      Klingon_Speech_Fragment_3D      ; fragment $3D
        DW      Klingon_Speech_Fragment_3E      ; fragment $3E
        DW      Klingon_Speech_Fragment_3F      ; fragment $3F
        DW      Klingon_Speech_Fragment_40      ; fragment $40
        DW      Klingon_Speech_Fragment_41      ; fragment $41
        DW      Klingon_Speech_Fragment_42      ; fragment $42
        DW      Klingon_Speech_Fragment_43      ; fragment $43
        DW      Klingon_Speech_Fragment_44      ; fragment $44
        DW      Klingon_Speech_Fragment_45      ; fragment $45
        DW      Klingon_Speech_Fragment_46      ; fragment $46
        DW      Klingon_Speech_Fragment_47      ; fragment $47
        DW      Klingon_Speech_Fragment_48      ; fragment $48
        DW      Klingon_Speech_Fragment_49      ; fragment $49
        DW      Klingon_Speech_Fragment_4A      ; fragment $4A
        DW      Klingon_Speech_Fragment_4B      ; fragment $4B
        DW      Klingon_Speech_Fragment_4C      ; fragment $4C
        DW      Klingon_Speech_Fragment_4D      ; fragment $4D

;==============================================================================
; KLINGON SPEECH PHRASE TABLE - 80 game phrase IDs ($00-$4F)
;
; A record begins with $81-$84; the low seven bits are the fragment count.
; The following bytes are fragment indexes. Phrase IDs containing the player rank
; use fragment $37 so Dungeon_Class can substitute $41 for Worlord/Pit play.
;==============================================================================
Klingon_Speech_Phrase_Table:
; Phrase $00: Hey, insert coin
; tlhIngan Hol: Huch yIlan.
        DB      $81,$00
; Phrase $01: Find me, the Wizard of Wor
; tlhIngan Hol: HISam, Wor 'IDnar pIn.
        DB      $81,$01
; Phrase $02: Hey, insert coin
; tlhIngan Hol: Huch yIlan.
        DB      $81,$00
; Phrase $03: I'm out of spite. Ha ha ha ha!
; tlhIngan Hol: jISo'. Ha ha ha ha!
        DB      $81,$02
; Phrase $04: Hey, insert coin
; tlhIngan Hol: Huch yIlan.
        DB      $81,$00
; Phrase $05: Find me, the Wizard of Wor
; tlhIngan Hol: HISam, Wor 'IDnar pIn.
        DB      $81,$01
; Phrase $06: Hey, insert coin
; tlhIngan Hol: Huch yIlan.
        DB      $81,$00
; Phrase $07: I'm out of spite. Ha ha ha ha!
; tlhIngan Hol: jISo'. Ha ha ha ha!
        DB      $81,$02
; Phrase $08: Get ready, Worrior
; tlhIngan Hol: yIghuH, SuvwI' / SuvwI' joH.
        DB      $83,$03,$37,$04
; Phrase $09: You'd better hope you don't find me, the Wizard of Wor
; tlhIngan Hol: HISambe' 'e' yItul, Wor 'IDnar pIn.
        DB      $81,$05
; Phrase $0A: Another coin for my treasure chest
; tlhIngan Hol: latlh Huch vIHev.
        DB      $81,$06
; Phrase $0B: Ah good! My pets were getting hungry. Ha ha ha ha!
; tlhIngan Hol: maj! ghumeywIj ghungqu'. Ha ha ha ha!
        DB      $81,$07
; Phrase $0C: My worlings are very very hungry. Ha ha ha ha!
; tlhIngan Hol: SuvwI'HommeywIj ghungqu'. Ha ha ha ha!
        DB      $81,$08
; Phrase $0D: Welcome to my world of Wor
; tlhIngan Hol: Wor qo'Daq yI'el.
        DB      $81,$0A
; Phrase $0E: So you've come to score in the world of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor qo'Daq mIvwa' DaSuq. Ha ha ha ha!
        DB      $81,$0B
; Phrase $0F: You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor 'IDnar pIn Daghom. Ha ha ha ha!
        DB      $81,$0C
; Phrase $10: Kill Worluk for double score
; tlhIngan Hol: Worluk yIHoH. cha'logh mIvwa' DaSuq.
        DB      $81,$0D
; Phrase $11: You're in the dungeons of Wor
; tlhIngan Hol: Wor bIghHa'meyDaq SoH.
        DB      $81,$0E
; Phrase $12: I am the Wizard of Wor
; tlhIngan Hol: Wor 'IDnar pIn jIH.
        DB      $81,$0F
; Phrase $13: One bite from my pretties, and you'll explode. Ha ha ha ha!
; tlhIngan Hol: DuchopDI' ghumeywIj, bIjor. Ha ha ha ha!
        DB      $81,$10
; Phrase $14: My creatures are radioactive
; tlhIngan Hol: Qob Ha'DIbaHmeywIj.
        DB      $81,$11
; Phrase $15: Worluk will escape through the door
; tlhIngan Hol: lojmIt vegh Worluk 'ej nargh.
        DB      $81,$12
; Phrase $16: Watch the radar, Worrior
; tlhIngan Hol: HotlhwI' yIbej, SuvwI' / SuvwI' joH.
        DB      $83,$13,$37,$04
; Phrase $17: Thorwor is red, mean, and hungry for space food. Ha ha ha ha!
; tlhIngan Hol: Doq Thorwor, QeH 'ej ghung. Ha ha ha ha!
        DB      $81,$14
; Phrase $18: Remember, I'm the Wizard, not you
; tlhIngan Hol: yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
        DB      $81,$15
; Phrase $19: If you can't beat the rest, then you'll never get the best. Ha ha ha ha!
; tlhIngan Hol: Hoch DanIvbe'chugh, bIluj. Ha ha ha ha!
        DB      $81,$16
; Phrase $1A: You'll never leave Wor alive. Ha ha ha ha!
; tlhIngan Hol: Worvo' bIyIntaHvIS bImejbe'. Ha ha ha ha!
        DB      $81,$17
; Phrase $1B: If you destroy my babies, I'll pop you in the oven. Ha ha ha ha!
; tlhIngan Hol: ghumeywIj DaQaw'chugh, qulDaq qameQmoH. Ha ha ha ha!
        DB      $81,$18
; Phrase $1C: Burwor hasn't eaten anyone in months. Ha ha ha ha!
; tlhIngan Hol: qaStaHvIS 'op jar pagh Sop Burwor. Ha ha ha ha!
        DB      $81,$19
; Phrase $1D: My babies breathe fire, Worrior
; tlhIngan Hol: qul lutlhuH ghumeywIj, SuvwI' / SuvwI' joH.
        DB      $83,$1A,$37,$04
; Phrase $1E: I'll fry you with my lightning bolts
; tlhIngan Hol: nISwI' tIHmeywIjmo' bImeQ.
        DB      $81,$1B
; Phrase $1F: Burwor, Garwor, and Thorwor will do you in
; tlhIngan Hol: Burwor Garwor Thorwor je DuHoH.
        DB      $81,$1C
; Phrase $20: You'll get the Arena. Ha ha ha ha!
; tlhIngan Hol: SuvmeH DaqDaq bIghoS. Ha ha ha ha!
        DB      $81,$1D
; Phrase $21: Another Worrior for my babies to devour
; tlhIngan Hol: latlh SuvwI' / SuvwI' joH luSop ghumeywIj.
        DB      $83,$1E,$37,$1F
; Phrase $22: Keep going and you will find me
; tlhIngan Hol: yItaH; HISam.
        DB      $81,$20
; Phrase $23: A few more dungeons and you'll be a Worlord
; tlhIngan Hol: SuvwI' joH SoH.
        DB      $81,$21
; Phrase $24: Worrior, now I'm getting mad
; tlhIngan Hol: SuvwI' / SuvwI' joH, jIQeHchoH.
        DB      $82,$37,$22
; Phrase $25: Worrior fear, I draw near, each time I appear. Ha ha ha ha!
; tlhIngan Hol: qaSumchoH. Ha ha ha ha!
        DB      $81,$23
; Phrase $26: Worrior, you won't have a chance for your dance. Ha ha ha ha!
; tlhIngan Hol: SuvwI' / SuvwI' joH, Qapla' Daghajbe'. Ha ha ha ha!
        DB      $82,$37,$24
; Phrase $27: You're asking for trouble, Worrior
; tlhIngan Hol: Seng DaneH, SuvwI' / SuvwI' joH.
        DB      $83,$25,$37,$04
; Phrase $28: Now you get the heavyweights. Ha ha ha ha!
; tlhIngan Hol: SuvwI'pu' HoSghaj DaSuv. Ha ha ha ha!
        DB      $81,$26
; Phrase $29: Garwor, go after them!
; tlhIngan Hol: Garwor, yIHIv!
        DB      $81,$27
; Phrase $2A: If you try any harder, you'll only meet with doom. Ha ha ha ha!
; tlhIngan Hol: latlh DanIDchugh, bIHegh. Ha ha ha ha!
        DB      $81,$28
; Phrase $2B: If you get too powerful, I'll take care of you myself. Ha ha ha ha!
; tlhIngan Hol: bIHoSghajqu'chugh, qamevmoH jIH. Ha ha ha ha!
        DB      $81,$29
; Phrase $2C: My magic is stronger than your weapons, Worrior
; tlhIngan Hol: 'IDnarwIj HoS law' nuHmeylIj HoS puS, SuvwI' / SuvwI' joH.
        DB      $83,$2A,$37,$04
; Phrase $2D: Worrior, while you developed science, we developed magic
; tlhIngan Hol: SuvwI' / SuvwI' joH, QeD Daghoj; 'IDnar wIghoj.
        DB      $82,$37,$2B
; Phrase $2E: Your bones will lie in the dungeons of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor bIghHa'meyDaq HomDu'lIj tu'lu'. Ha ha ha ha!
        DB      $81,$2C
; Phrase $2F: Garwor and Thorwor become invisible. Ha ha ha ha!
; tlhIngan Hol: Garwor Thorwor je tISo'moH! Ha ha ha ha!
        DB      $81,$2D
; Phrase $30: Come back for more with the Wizard of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor 'IDnar pIn yIghomqa'. Ha ha ha ha!
        DB      $81,$2E
; Phrase $31: The dungeons of Wor await your return, Worrior
; tlhIngan Hol: Wor bIghHa'meyDaq bIchegh, SuvwI' / SuvwI' joH.
        DB      $83,$2F,$37,$04
; Phrase $32: Deep in the caverns of Wor, you will meet me, Worrior
; tlhIngan Hol: Wor DISmeyDaq HISam, SuvwI' / SuvwI' joH.
        DB      $83,$30,$37,$04
; Phrase $33: The Wizard of Wor thanks you
; tlhIngan Hol: Wor 'IDnar pIn Dutlho'.
        DB      $81,$31
; Phrase $34: You know you can do better, Worrior
; tlhIngan Hol: bIQapla'laH, SuvwI' / SuvwI' joH.
        DB      $83,$32,$37,$04
; Phrase $35: Hurry back, I can't wait to do it again
; tlhIngan Hol: nom yIchegh; qaloS.
        DB      $81,$33
; Phrase $36: You can start anew, but for now you're through. Ha ha ha ha!
; tlhIngan Hol: Qu' Dachuqa'laH; DaH bIluj. Ha ha ha ha!
        DB      $81,$34
; Phrase $37: He he he, ho ho ho, ha ha ha ha! That was fun
; tlhIngan Hol: He he he, ho ho ho, ha ha ha ha! maj.
        DB      $81,$35
; Phrase $38: You've just been fried by the Wizard of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor 'IDnar pIn DuQIHpu'. Ha ha ha ha!
        DB      $81,$36
; Phrase $39: Bite the bolt, Worrior. Ha ha ha ha!
; tlhIngan Hol: nISwI' yIchop, SuvwI' / SuvwI' joH. Ha ha ha ha!
        DB      $83,$38,$37,$39
; Phrase $3A: Wasn't that lightning bolt delicious? Ha ha ha ha!
; tlhIngan Hol: nISwI' tIH DaparHa''a'? Ha ha ha ha!
        DB      $81,$3A
; Phrase $3B: And my teleporting spell can be even faster. Ha ha ha ha!
; tlhIngan Hol: nom jolwI'wIj Qap. Ha ha ha ha!
        DB      $81,$3B
; Phrase $3C: Now you know the taste of my magic, Worrior
; tlhIngan Hol: DaH 'IDnarwIj DaSov, SuvwI' / SuvwI' joH.
        DB      $83,$3C,$37,$04
; Phrase $3D: Worrior, maybe you'll see me again
; tlhIngan Hol: SuvwI' / SuvwI' joH, chaq maghomqa'.
        DB      $82,$37,$3D
; Phrase $3E: Your explosion was music to my ears. Ha ha ha ha!
; tlhIngan Hol: QoQ 'oH jorlIj'e'. Ha ha ha ha!
        DB      $81,$3E
; Phrase $3F: I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha!
; tlhIngan Hol: vIjatlhqa': SuvwI' / SuvwI' joH, qaSumchoH. Ha ha ha ha!
        DB      $83,$3F,$37,$23
; Phrase $40: Worlord, be forewarned! You approach the Pit. Ha ha ha ha!
; tlhIngan Hol: SuvwI' joH, yIghuH! QemjIq DaghoS. Ha ha ha ha!
        DB      $81,$42
; Phrase $41: Worlord, your path leads directly to the Pit. Ha ha ha ha!
; tlhIngan Hol: SuvwI' joH, QemjIqDaq He'lIj ghoS. Ha ha ha ha!
        DB      $81,$43
; Phrase $42: Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha!
; tlhIngan Hol: Wor bIghHa'mey qoDDaq yIghoS. Ha ha ha ha!
        DB      $81,$44
; Phrase $43: Beware! You are in the Worlord dungeons
; tlhIngan Hol: yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
        DB      $81,$45
; Phrase $44: Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha!
; tlhIngan Hol: DaSo' 'e' DaQub; bIghHa' pIn jIH. Ha ha ha ha!
        DB      $81,$46
; Phrase $45: Thor, Bur, Gar! Dinner's ready. Ha ha ha ha!
; tlhIngan Hol: Thor, Bur, Gar! SopmeH yIghuH. Ha ha ha ha!
        DB      $81,$47
; Phrase $46: Hey! Your space boot's untied. Ha ha ha ha!
; tlhIngan Hol: DaSlIj yIrar! Ha ha ha ha!
        DB      $81,$48
; Phrase $47: My beasts run wild in the Worlord dungeons. Ha ha ha ha!
; tlhIngan Hol: SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. Ha ha ha ha!
        DB      $81,$49
; Phrase $48: Now your only chance is your dance. Ha ha ha ha!
; tlhIngan Hol: DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha!
        DB      $81,$4A
; Phrase $49: Are you fit to survive the Pit? Ha ha ha ha!
; tlhIngan Hol: QemjIqDaq bIyInlaH'a'? Ha ha ha ha!
        DB      $81,$4B
; Phrase $4A: Oops! I must have forgotten the walls. Ha ha ha ha!
; tlhIngan Hol: toH! reDmey vIlIjpu'. Ha ha ha ha!
        DB      $81,$4C
; Phrase $4B: Where are you going to hide now? Ha ha ha ha!
; tlhIngan Hol: nuqDaq DaSo'? Ha ha ha ha!
        DB      $81,$4D
; Phrase $4C: Now your only chance is your dance. Ha ha ha ha!
; tlhIngan Hol: DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha!
        DB      $81,$4A
; Phrase $4D: Are you fit to survive the Pit? Ha ha ha ha!
; tlhIngan Hol: QemjIqDaq bIyInlaH'a'? Ha ha ha ha!
        DB      $81,$4B
; Phrase $4E: Oops! I must have forgotten the walls. Ha ha ha ha!
; tlhIngan Hol: toH! reDmey vIlIjpu'. Ha ha ha ha!
        DB      $81,$4C
; Phrase $4F: Where are you going to hide now? Ha ha ha ha!
; tlhIngan Hol: nuqDaq DaSo'? Ha ha ha ha!
        DB      $81,$4D

; Pad the unused body of the 4 KiB X11 image with $FF.
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Complete-ROM checksum compensation. X11_ROM_Checksum_Expected is $00.
Klingon_Checksum_Compensation:
        DB      $C0

Klingon_ROM_Identification:
        DB      "KLINGON WIZARD"
Klingon_ROM_Author_Tag:
        DB      "FAN"
Klingon_ROM_Date:
        DB      "08/08/2026"
        DB      $FF,$FF,$FF,$FF

; End of X11 image: $CFFF
