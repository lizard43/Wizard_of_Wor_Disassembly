; KLINGON_X11.asm
;==============================================================================
; Wizard of Wor - Klingon X11 Foreign-Language ROM
;==============================================================================
;
; Runtime-stability revision.
;
; Design rules for this pass:
;   1. The Votrax JSON library remains direct six-bit SC-01 data.
;   2. ROM speech records are encoded separately for Play_Next_Phoneme.
;   3. Phrase IDs use the proven resident English 80-entry composition.
;   4. Klingon fragments $00-$4E parallel the resident English semantics.
;   5. Each ROM fragment explicitly returns Speech_Inflection_State to zero.
;   6. Text records use their natural lengths; no artificial padding is added.
;
; This intentionally removes the experimental variables that caused the first
; Klingon X11 runtime to speak continuously and remain in attract behavior.
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

;==============================================================================
; KLINGON LOCALIZED DISPLAY TEXT - 23 records
;
; Record format is DB length,"characters". Every emitted character is >= $30.
; '@' maps to the resident blank/space glyph. Canonical Klingon apostrophes are
; retained only in comments because byte $27 would be interpreted as a new
; record-length marker by Select_Localized_Text_Record.
;==============================================================================
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
        DB      $05,"RADAR"

; Text $11: English source "ESCAPED"
; tlhIngan Hol: nargh
        DB      $05,"NARGH"

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
        DB      $06,"SUVDAQ"

; Text $16: English source "THE PIT"
; tlhIngan Hol: QemjIq
        DB      $06,"QEMJIQ"

; Text $17: English source "OR FOR ADDITIONAL WORRIORS"
; tlhIngan Hol: qoj latlh SuvwI'
        DB      $0F,"QOJ@LATLH@SUVWI"

        ORG     $C1D1
        NOP                             ; preserved X11 alignment byte

Klingon_Alternate_Font:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF

        ORG     $C200

;==============================================================================
; KLINGON ENCODED SPEECH FRAGMENTS
;
; JSON/player bytes and ROM bytes are intentionally different representations.
; The Votrax library stores direct phoneme IDs ($00-$3F). The WoW playback
; routine XORs each stored ROM byte with Speech_Inflection_State.
;
; Each record below is framed so its decoded stream begins with a PA0 at
; inflection state 1 and ends with a PA0 that returns the state to zero.
; This makes every fragment self-contained and prevents inflection state from
; leaking from one Klingon fragment into the next.
;==============================================================================

; Fragment $00: Worluk yIHoH. cha'logh mIvwa' DaSuq.
; Direct player bytes: 2D 26 2B 18 28 19 03 29 27 1B 26 1B 3E 2A 10 15 03 18 26 1C 1B 03 0C 27 0F 2D 15 03 1E 15 11 28 19 3E
Klingon_Speech_Fragment_00:
        DB      $24                 ; encoded command count
        DB      $83,$2D,$26,$2B,$18,$28,$19,$03
        DB      $29,$27,$1B,$26,$1B,$3E,$2A,$10
        DB      $15,$03,$18,$26,$1C,$1B,$03,$0C
        DB      $27,$0F,$2D,$15,$03,$1E,$15,$11
        DB      $28,$19,$3E,$83

; Fragment $01: bIHoSghajqu'chugh, qamevmoH jIH.
; Direct player bytes: 0E 27 1B 26 11 1C 1B 15 1E 1A 19 28 03 2A 10 28 1C 1B 03 19 15 0C 3B 0F 0C 26 1B 03 1E 1A 27 1B 3E
Klingon_Speech_Fragment_01:
        DB      $23                 ; encoded command count
        DB      $83,$0E,$27,$1B,$26,$11,$1C,$1B
        DB      $15,$1E,$1A,$19,$28,$03,$2A,$10
        DB      $28,$1C,$1B,$03,$19,$15,$0C,$3B
        DB      $0F,$0C,$26,$1B,$03,$1E,$1A,$27
        DB      $1B,$3E,$83

; Fragment $02: Wor bIghHa'mey.
; Direct player bytes: 2D 26 2B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 3E
Klingon_Speech_Fragment_02:
        DB      $11                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$0E,$27,$1C
        DB      $1B,$1B,$15,$03,$0C,$3B,$29,$3E
        DB      $83

; Fragment $03: jIH.
; Direct player bytes: 1E 1A 27 1B 3E
Klingon_Speech_Fragment_03:
        DB      $07                 ; encoded command count
        DB      $83,$1E,$1A,$27,$1B,$3E,$83

; Fragment $04: Wor 'IDnar pIn.
; Direct player bytes: 2D 26 2B 03 27 1E 0D 15 2B 03 25 27 0D 3E
Klingon_Speech_Fragment_04:
        DB      $10                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$27,$1E,$0D
        DB      $15,$2B,$03,$25,$27,$0D,$3E,$83

; Fragment $05: DuchopDI' ghumeywIj, bIjor.
; Direct player bytes: 1E 28 2A 10 26 25 1E 27 03 1C 1B 28 0C 3B 29 2D 27 1E 1A 03 0E 27 1E 1A 26 2B 3E
Klingon_Speech_Fragment_05:
        DB      $1D                 ; encoded command count
        DB      $83,$1E,$28,$2A,$10,$26,$25,$1E
        DB      $27,$03,$1C,$1B,$28,$0C,$3B,$29
        DB      $2D,$27,$1E,$1A,$03,$0E,$27,$1E
        DB      $1A,$26,$2B,$3E,$83

; Fragment $06: Qob Ha'DIbaHmeywIj.
; Direct player bytes: 19 1B 26 0E 03 1B 15 03 1E 27 0E 15 1B 0C 3B 29 2D 27 1E 1A 3E
Klingon_Speech_Fragment_06:
        DB      $17                 ; encoded command count
        DB      $83,$19,$1B,$26,$0E,$03,$1B,$15
        DB      $03,$1E,$27,$0E,$15,$1B,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$3E,$83

; Fragment $07: lojmIt vegh Worluk 'ej nargh.
; Direct player bytes: 18 26 1E 1A 0C 27 2A 03 0F 3B 1C 1B 03 2D 26 2B 18 28 19 03 3B 1E 1A 03 0D 15 2B 1C 1B 3E
Klingon_Speech_Fragment_07:
        DB      $20                 ; encoded command count
        DB      $83,$18,$26,$1E,$1A,$0C,$27,$2A
        DB      $03,$0F,$3B,$1C,$1B,$03,$2D,$26
        DB      $2B,$18,$28,$19,$03,$3B,$1E,$1A
        DB      $03,$0D,$15,$2B,$1C,$1B,$3E,$83

; Fragment $08: HotlhwI' yIbej.
; Direct player bytes: 1B 26 2A 18 1B 2D 27 03 29 27 0E 3B 1E 1A 3E
Klingon_Speech_Fragment_08:
        DB      $11                 ; encoded command count
        DB      $83,$1B,$26,$2A,$18,$1B,$2D,$27
        DB      $03,$29,$27,$0E,$3B,$1E,$1A,$3E
        DB      $83

; Fragment $09: SuvwI'.
; Direct player bytes: 11 28 0F 2D 27 03 3E
Klingon_Speech_Fragment_09:
        DB      $09                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$3E
        DB      $83

; Fragment $0A: Huch yIlan.
; Direct player bytes: 1B 28 2A 10 03 29 27 18 15 0D 3E
Klingon_Speech_Fragment_0A:
        DB      $0D                 ; encoded command count
        DB      $83,$1B,$28,$2A,$10,$03,$29,$27
        DB      $18,$15,$0D,$3E,$83

; Fragment $0B: HISam.
; Direct player bytes: 1B 27 11 15 0C 3E
Klingon_Speech_Fragment_0B:
        DB      $08                 ; encoded command count
        DB      $83,$1B,$27,$11,$15,$0C,$3E,$83

; Fragment $0C: jISo'.
; Direct player bytes: 1E 1A 27 11 26 03 3E
Klingon_Speech_Fragment_0C:
        DB      $09                 ; encoded command count
        DB      $83,$1E,$1A,$27,$11,$26,$03,$3E
        DB      $83

; Fragment $0D: yIghuH.
; Direct player bytes: 29 27 1C 1B 28 1B 3E
Klingon_Speech_Fragment_0D:
        DB      $09                 ; encoded command count
        DB      $83,$29,$27,$1C,$1B,$28,$1B,$3E
        DB      $83

; Fragment $0E: HISambe' 'e' yItul.
; Direct player bytes: 1B 27 11 15 0C 0E 3B 03 3B 03 29 27 2A 28 18 3E
Klingon_Speech_Fragment_0E:
        DB      $12                 ; encoded command count
        DB      $83,$1B,$27,$11,$15,$0C,$0E,$3B
        DB      $03,$3B,$03,$29,$27,$2A,$28,$18
        DB      $3E,$83

; Fragment $0F: latlh Huch vIHev.
; Direct player bytes: 18 15 2A 18 1B 03 1B 28 2A 10 03 0F 27 1B 3B 0F 3E
Klingon_Speech_Fragment_0F:
        DB      $13                 ; encoded command count
        DB      $83,$18,$15,$2A,$18,$1B,$03,$1B
        DB      $28,$2A,$10,$03,$0F,$27,$1B,$3B
        DB      $0F,$3E,$83

; Fragment $10: Ha ha ha ha!
; Direct player bytes: 1B 15 03 1B 15 03 1B 15 03 1B 15 3E
Klingon_Speech_Fragment_10:
        DB      $0E                 ; encoded command count
        DB      $83,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E,$83

; Fragment $11: maj! ghumeywIj ghungqu'.
; Direct player bytes: 0C 15 1E 1A 3E 1C 1B 28 0C 3B 29 2D 27 1E 1A 03 1C 1B 28 14 19 28 03 3E
Klingon_Speech_Fragment_11:
        DB      $1A                 ; encoded command count
        DB      $83,$0C,$15,$1E,$1A,$3E,$1C,$1B
        DB      $28,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $03,$1C,$1B,$28,$14,$19,$28,$03
        DB      $3E,$83

; Fragment $12: SuvmeH DaqDaq bIghoS.
; Direct player bytes: 11 28 0F 0C 3B 1B 03 1E 15 19 1E 15 19 03 0E 27 1C 1B 26 11 3E
Klingon_Speech_Fragment_12:
        DB      $17                 ; encoded command count
        DB      $83,$11,$28,$0F,$0C,$3B,$1B,$03
        DB      $1E,$15,$19,$1E,$15,$19,$03,$0E
        DB      $27,$1C,$1B,$26,$11,$3E,$83

; Fragment $13: latlh SuvwI' luSop ghumeywIj.
; Direct player bytes: 18 15 2A 18 1B 03 11 28 0F 2D 27 03 18 28 11 26 25 03 1C 1B 28 0C 3B 29 2D 27 1E 1A 3E
Klingon_Speech_Fragment_13:
        DB      $1F                 ; encoded command count
        DB      $83,$18,$15,$2A,$18,$1B,$03,$11
        DB      $28,$0F,$2D,$27,$03,$18,$28,$11
        DB      $26,$25,$03,$1C,$1B,$28,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$3E,$83

; Fragment $14: yItaH; HISam.
; Direct player bytes: 29 27 2A 15 1B 03 1B 27 11 15 0C 3E
Klingon_Speech_Fragment_14:
        DB      $0E                 ; encoded command count
        DB      $83,$29,$27,$2A,$15,$1B,$03,$1B
        DB      $27,$11,$15,$0C,$3E,$83

; Fragment $15: latlh bIghHa'mey puS Daju'DI',
; Direct player bytes: 18 15 2A 18 1B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 03 25 28 11 03 1E 15 1E 1A 28 03 1E 27 03 3E
Klingon_Speech_Fragment_15:
        DB      $21                 ; encoded command count
        DB      $83,$18,$15,$2A,$18,$1B,$03,$0E
        DB      $27,$1C,$1B,$1B,$15,$03,$0C,$3B
        DB      $29,$03,$25,$28,$11,$03,$1E,$15
        DB      $1E,$1A,$28,$03,$1E,$27,$03,$3E
        DB      $83

; Fragment $16: latlh Qu'vaD yIchegh.
; Direct player bytes: 18 15 2A 18 1B 03 19 1B 28 03 0F 15 1E 03 29 27 2A 10 3B 1C 1B 3E
Klingon_Speech_Fragment_16:
        DB      $18                 ; encoded command count
        DB      $83,$18,$15,$2A,$18,$1B,$03,$19
        DB      $1B,$28,$03,$0F,$15,$1E,$03,$29
        DB      $27,$2A,$10,$3B,$1C,$1B,$3E,$83

; Fragment $17: Wor bIghHa'meyDaq bIchegh.
; Direct player bytes: 2D 26 2B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 1E 15 19 03 0E 27 2A 10 3B 1C 1B 3E
Klingon_Speech_Fragment_17:
        DB      $1C                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$0E,$27,$1C
        DB      $1B,$1B,$15,$03,$0C,$3B,$29,$1E
        DB      $15,$19,$03,$0E,$27,$2A,$10,$3B
        DB      $1C,$1B,$3E,$83

; Fragment $18: Wor DISmeyDaq HISam.
; Direct player bytes: 2D 26 2B 03 1E 27 11 0C 3B 29 1E 15 19 03 1B 27 11 15 0C 3E
Klingon_Speech_Fragment_18:
        DB      $16                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$1E,$27,$11
        DB      $0C,$3B,$29,$1E,$15,$19,$03,$1B
        DB      $27,$11,$15,$0C,$3E,$83

; Fragment $19: Dutlho'.
; Direct player bytes: 1E 28 2A 18 1B 26 03 3E
Klingon_Speech_Fragment_19:
        DB      $0A                 ; encoded command count
        DB      $83,$1E,$28,$2A,$18,$1B,$26,$03
        DB      $3E,$83

; Fragment $1A: SuvwI'pu' HoSghaj DaSuv.
; Direct player bytes: 11 28 0F 2D 27 03 25 28 03 1B 26 11 1C 1B 15 1E 1A 03 1E 15 11 28 0F 3E
Klingon_Speech_Fragment_1A:
        DB      $1A                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$25
        DB      $28,$03,$1B,$26,$11,$1C,$1B,$15
        DB      $1E,$1A,$03,$1E,$15,$11,$28,$0F
        DB      $3E,$83

; Fragment $1B: Garwor, yIHIv!
; Direct player bytes: 1C 15 2B 2D 26 2B 03 29 27 1B 27 0F 3E
Klingon_Speech_Fragment_1B:
        DB      $0F                 ; encoded command count
        DB      $83,$1C,$15,$2B,$2D,$26,$2B,$03
        DB      $29,$27,$1B,$27,$0F,$3E,$83

; Fragment $1C: latlh DanIDchugh, bIHegh.
; Direct player bytes: 18 15 2A 18 1B 03 1E 15 0D 27 1E 2A 10 28 1C 1B 03 0E 27 1B 3B 1C 1B 3E
Klingon_Speech_Fragment_1C:
        DB      $1A                 ; encoded command count
        DB      $83,$18,$15,$2A,$18,$1B,$03,$1E
        DB      $15,$0D,$27,$1E,$2A,$10,$28,$1C
        DB      $1B,$03,$0E,$27,$1B,$3B,$1C,$1B
        DB      $3E,$83

; Fragment $1D: Burwor Garwor Thorwor je DuHoH.
; Direct player bytes: 0E 28 2B 2D 26 2B 03 1C 15 2B 2D 26 2B 03 2A 1B 26 2B 2D 26 2B 03 1E 1A 3B 03 1E 28 1B 26 1B 3E
Klingon_Speech_Fragment_1D:
        DB      $22                 ; encoded command count
        DB      $83,$0E,$28,$2B,$2D,$26,$2B,$03
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$2A
        DB      $1B,$26,$2B,$2D,$26,$2B,$03,$1E
        DB      $1A,$3B,$03,$1E,$28,$1B,$26,$1B
        DB      $3E,$83

; Fragment $1E: SuvwI'HommeywIj ghungqu'.
; Direct player bytes: 11 28 0F 2D 27 03 1B 26 0C 0C 3B 29 2D 27 1E 1A 03 1C 1B 28 14 19 28 03 3E
Klingon_Speech_Fragment_1E:
        DB      $1B                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$1B
        DB      $26,$0C,$0C,$3B,$29,$2D,$27,$1E
        DB      $1A,$03,$1C,$1B,$28,$14,$19,$28
        DB      $03,$3E,$83

; Fragment $1F: 'IDnarwIj HoS law' nuHmeylIj HoS puS.
; Direct player bytes: 03 27 1E 0D 15 2B 2D 27 1E 1A 03 1B 26 11 03 18 15 2D 03 0D 28 1B 0C 3B 29 18 27 1E 1A 03 1B 26 11 03 25 28 11 3E
Klingon_Speech_Fragment_1F:
        DB      $27                 ; encoded command count
        DB      $83,$27,$1E,$0D,$15,$2B,$2D,$27
        DB      $1E,$1A,$03,$1B,$26,$11,$03,$18
        DB      $15,$2D,$03,$0D,$28,$1B,$0C,$3B
        DB      $29,$18,$27,$1E,$1A,$03,$1B,$26
        DB      $11,$03,$25,$28,$11,$3E,$83

; Fragment $20: QeD Daghoj; 'IDnar wIghoj.
; Direct player bytes: 19 1B 3B 1E 03 1E 15 1C 1B 26 1E 1A 03 27 1E 0D 15 2B 03 2D 27 1C 1B 26 1E 1A 3E
Klingon_Speech_Fragment_20:
        DB      $1D                 ; encoded command count
        DB      $83,$19,$1B,$3B,$1E,$03,$1E,$15
        DB      $1C,$1B,$26,$1E,$1A,$03,$27,$1E
        DB      $0D,$15,$2B,$03,$2D,$27,$1C,$1B
        DB      $26,$1E,$1A,$3E,$83

; Fragment $21: Wor bIghHa'meyDaq HomDu'lIj tu'lu'.
; Direct player bytes: 2D 26 2B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 1E 15 19 03 1B 26 0C 1E 28 03 18 27 1E 1A 03 2A 28 03 18 28 03 3E
Klingon_Speech_Fragment_21:
        DB      $26                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$0E,$27,$1C
        DB      $1B,$1B,$15,$03,$0C,$3B,$29,$1E
        DB      $15,$19,$03,$1B,$26,$0C,$1E,$28
        DB      $03,$18,$27,$1E,$1A,$03,$2A,$28
        DB      $03,$18,$28,$03,$3E,$83

; Fragment $22: Qapla' Daghajbe'.
; Direct player bytes: 19 1B 15 25 18 15 03 1E 15 1C 1B 15 1E 1A 0E 3B 03 3E
Klingon_Speech_Fragment_22:
        DB      $14                 ; encoded command count
        DB      $83,$19,$1B,$15,$25,$18,$15,$03
        DB      $1E,$15,$1C,$1B,$15,$1E,$1A,$0E
        DB      $3B,$03,$3E,$83

; Fragment $23: yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
; Direct player bytes: 29 27 19 15 2D 03 2D 26 2B 03 27 1E 0D 15 2B 03 25 27 0D 03 1E 1A 27 1B 03 11 26 1B 0E 3B 03 3E
Klingon_Speech_Fragment_23:
        DB      $22                 ; encoded command count
        DB      $83,$29,$27,$19,$15,$2D,$03,$2D
        DB      $26,$2B,$03,$27,$1E,$0D,$15,$2B
        DB      $03,$25,$27,$0D,$03,$1E,$1A,$27
        DB      $1B,$03,$11,$26,$1B,$0E,$3B,$03
        DB      $3E,$83

; Fragment $24: Hoch DanIvbe'chugh, bIluj.
; Direct player bytes: 1B 26 2A 10 03 1E 15 0D 27 0F 0E 3B 03 2A 10 28 1C 1B 03 0E 27 18 28 1E 1A 3E
Klingon_Speech_Fragment_24:
        DB      $1C                 ; encoded command count
        DB      $83,$1B,$26,$2A,$10,$03,$1E,$15
        DB      $0D,$27,$0F,$0E,$3B,$03,$2A,$10
        DB      $28,$1C,$1B,$03,$0E,$27,$18,$28
        DB      $1E,$1A,$3E,$83

; Fragment $25: ghumeywIj DaQaw'chugh, qulDaq qameQmoH.
; Direct player bytes: 1C 1B 28 0C 3B 29 2D 27 1E 1A 03 1E 15 19 1B 15 2D 03 2A 10 28 1C 1B 03 19 28 18 1E 15 19 03 19 15 0C 3B 19 1B 0C 26 1B 3E
Klingon_Speech_Fragment_25:
        DB      $2B                 ; encoded command count
        DB      $83,$1C,$1B,$28,$0C,$3B,$29,$2D
        DB      $27,$1E,$1A,$03,$1E,$15,$19,$1B
        DB      $15,$2D,$03,$2A,$10,$28,$1C,$1B
        DB      $03,$19,$28,$18,$1E,$15,$19,$03
        DB      $19,$15,$0C,$3B,$19,$1B,$0C,$26
        DB      $1B,$3E,$83

; Fragment $26: jIQeHchoH.
; Direct player bytes: 1E 1A 27 19 1B 3B 1B 2A 10 26 1B 3E
Klingon_Speech_Fragment_26:
        DB      $0E                 ; encoded command count
        DB      $83,$1E,$1A,$27,$19,$1B,$3B,$1B
        DB      $2A,$10,$26,$1B,$3E,$83

; Fragment $27: Worvo' bIyIntaHvIS bImejbe'.
; Direct player bytes: 2D 26 2B 0F 26 03 0E 27 29 27 0D 2A 15 1B 0F 27 11 03 0E 27 0C 3B 1E 1A 0E 3B 03 3E
Klingon_Speech_Fragment_27:
        DB      $1E                 ; encoded command count
        DB      $83,$2D,$26,$2B,$0F,$26,$03,$0E
        DB      $27,$29,$27,$0D,$2A,$15,$1B,$0F
        DB      $27,$11,$03,$0E,$27,$0C,$3B,$1E
        DB      $1A,$0E,$3B,$03,$3E,$83

; Fragment $28: Garwor Thorwor je tISo'moH!
; Direct player bytes: 1C 15 2B 2D 26 2B 03 2A 1B 26 2B 2D 26 2B 03 1E 1A 3B 03 2A 27 11 26 03 0C 26 1B 3E
Klingon_Speech_Fragment_28:
        DB      $1E                 ; encoded command count
        DB      $83,$1C,$15,$2B,$2D,$26,$2B,$03
        DB      $2A,$1B,$26,$2B,$2D,$26,$2B,$03
        DB      $1E,$1A,$3B,$03,$2A,$27,$11,$26
        DB      $03,$0C,$26,$1B,$3E,$83

; Fragment $29: bIHoSghajqu'laH.
; Direct player bytes: 0E 27 1B 26 11 1C 1B 15 1E 1A 19 28 03 18 15 1B 3E
Klingon_Speech_Fragment_29:
        DB      $13                 ; encoded command count
        DB      $83,$0E,$27,$1B,$26,$11,$1C,$1B
        DB      $15,$1E,$1A,$19,$28,$03,$18,$15
        DB      $1B,$3E,$83

; Fragment $2A: nom yIchegh; qaloS.
; Direct player bytes: 0D 26 0C 03 29 27 2A 10 3B 1C 1B 03 19 15 18 26 11 3E
Klingon_Speech_Fragment_2A:
        DB      $14                 ; encoded command count
        DB      $83,$0D,$26,$0C,$03,$29,$27,$2A
        DB      $10,$3B,$1C,$1B,$03,$19,$15,$18
        DB      $26,$11,$3E,$83

; Fragment $2B: Qu' Dachuqa'laH; DaH bIluj.
; Direct player bytes: 19 1B 28 03 1E 15 2A 10 28 19 15 03 18 15 1B 03 1E 15 1B 03 0E 27 18 28 1E 1A 3E
Klingon_Speech_Fragment_2B:
        DB      $1D                 ; encoded command count
        DB      $83,$19,$1B,$28,$03,$1E,$15,$2A
        DB      $10,$28,$19,$15,$03,$18,$15,$1B
        DB      $03,$1E,$15,$1B,$03,$0E,$27,$18
        DB      $28,$1E,$1A,$3E,$83

; Fragment $2C: He he he, ho ho ho, ha ha ha ha! maj.
; Direct player bytes: 1B 3B 03 1B 3B 03 1B 3B 03 1B 26 03 1B 26 03 1B 26 03 1B 15 03 1B 15 03 1B 15 03 1B 15 3E 0C 15 1E 1A 3E
Klingon_Speech_Fragment_2C:
        DB      $25                 ; encoded command count
        DB      $83,$1B,$3B,$03,$1B,$3B,$03,$1B
        DB      $3B,$03,$1B,$26,$03,$1B,$26,$03
        DB      $1B,$26,$03,$1B,$15,$03,$1B,$15
        DB      $03,$1B,$15,$03,$1B,$15,$3E,$0C
        DB      $15,$1E,$1A,$3E,$83

; Fragment $2D: Wor qo'Daq yI'el.
; Direct player bytes: 2D 26 2B 03 19 26 03 1E 15 19 03 29 27 03 3B 18 3E
Klingon_Speech_Fragment_2D:
        DB      $13                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$19,$26,$03
        DB      $1E,$15,$19,$03,$29,$27,$03,$3B
        DB      $18,$3E,$83

; Fragment $2E: Wor qo'Daq mIvwa' DaSuq.
; Direct player bytes: 2D 26 2B 03 19 26 03 1E 15 19 03 0C 27 0F 2D 15 03 1E 15 11 28 19 3E
Klingon_Speech_Fragment_2E:
        DB      $19                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$19,$26,$03
        DB      $1E,$15,$19,$03,$0C,$27,$0F,$2D
        DB      $15,$03,$1E,$15,$11,$28,$19,$3E
        DB      $83

; Fragment $2F: Wor 'IDnar pIn Daghom.
; Direct player bytes: 2D 26 2B 03 27 1E 0D 15 2B 03 25 27 0D 03 1E 15 1C 1B 26 0C 3E
Klingon_Speech_Fragment_2F:
        DB      $17                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$27,$1E,$0D
        DB      $15,$2B,$03,$25,$27,$0D,$03,$1E
        DB      $15,$1C,$1B,$26,$0C,$3E,$83

; Fragment $30: qaStaHvIS 'op jar pagh Sop Burwor.
; Direct player bytes: 19 15 11 2A 15 1B 0F 27 11 03 26 25 03 1E 1A 15 2B 03 25 15 1C 1B 03 11 26 25 03 0E 28 2B 2D 26 2B 3E
Klingon_Speech_Fragment_30:
        DB      $24                 ; encoded command count
        DB      $83,$19,$15,$11,$2A,$15,$1B,$0F
        DB      $27,$11,$03,$26,$25,$03,$1E,$1A
        DB      $15,$2B,$03,$25,$15,$1C,$1B,$03
        DB      $11,$26,$25,$03,$0E,$28,$2B,$2D
        DB      $26,$2B,$3E,$83

; Fragment $31: qul lutlhuH ghumeywIj.
; Direct player bytes: 19 28 18 03 18 28 2A 18 1B 28 1B 03 1C 1B 28 0C 3B 29 2D 27 1E 1A 3E
Klingon_Speech_Fragment_31:
        DB      $19                 ; encoded command count
        DB      $83,$19,$28,$18,$03,$18,$28,$2A
        DB      $18,$1B,$28,$1B,$03,$1C,$1B,$28
        DB      $0C,$3B,$29,$2D,$27,$1E,$1A,$3E
        DB      $83

; Fragment $32: nISwI' tIHmeywIjmo' bImeQ.
; Direct player bytes: 0D 27 11 2D 27 03 2A 27 1B 0C 3B 29 2D 27 1E 1A 0C 26 03 0E 27 0C 3B 19 1B 3E
Klingon_Speech_Fragment_32:
        DB      $1C                 ; encoded command count
        DB      $83,$0D,$27,$11,$2D,$27,$03,$2A
        DB      $27,$1B,$0C,$3B,$29,$2D,$27,$1E
        DB      $1A,$0C,$26,$03,$0E,$27,$0C,$3B
        DB      $19,$1B,$3E,$83

; Fragment $33: Doq Thorwor, QeH 'ej ghung.
; Direct player bytes: 1E 26 19 03 2A 1B 26 2B 2D 26 2B 03 19 1B 3B 1B 03 3B 1E 1A 03 1C 1B 28 14 3E
Klingon_Speech_Fragment_33:
        DB      $1C                 ; encoded command count
        DB      $83,$1E,$26,$19,$03,$2A,$1B,$26
        DB      $2B,$2D,$26,$2B,$03,$19,$1B,$3B
        DB      $1B,$03,$3B,$1E,$1A,$03,$1C,$1B
        DB      $28,$14,$3E,$83

; Fragment $34: SuvwI', qaSumchoH.
; Direct player bytes: 11 28 0F 2D 27 03 19 15 11 28 0C 2A 10 26 1B 3E
Klingon_Speech_Fragment_34:
        DB      $12                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$19
        DB      $15,$11,$28,$0C,$2A,$10,$26,$1B
        DB      $3E,$83

; Fragment $35: Seng DaneH.
; Direct player bytes: 11 3B 14 03 1E 15 0D 3B 1B 3E
Klingon_Speech_Fragment_35:
        DB      $0C                 ; encoded command count
        DB      $83,$11,$3B,$14,$03,$1E,$15,$0D
        DB      $3B,$1B,$3E,$83

; Fragment $36: Ha ha ha ha! (padded)
; Direct player bytes: 1B 15 03 1B 15 03 1B 15 03 1B 15 3E 03
Klingon_Speech_Fragment_36:
        DB      $0E                 ; encoded command count
        DB      $83,$1B,$15,$03,$1B,$15,$03,$1B
        DB      $15,$03,$1B,$15,$3E,$83

; Fragment $37: SuvwI' (padded)
; Direct player bytes: 11 28 0F 2D 27 03 3E 03
Klingon_Speech_Fragment_37:
        DB      $09                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$3E
        DB      $83

; Fragment $38: DuQIHpu'.
; Direct player bytes: 1E 28 19 1B 27 1B 25 28 03 3E
Klingon_Speech_Fragment_38:
        DB      $0C                 ; encoded command count
        DB      $83,$1E,$28,$19,$1B,$27,$1B,$25
        DB      $28,$03,$3E,$83

; Fragment $39: nISwI' yIchop.
; Direct player bytes: 0D 27 11 2D 27 03 29 27 2A 10 26 25 3E
Klingon_Speech_Fragment_39:
        DB      $0F                 ; encoded command count
        DB      $83,$0D,$27,$11,$2D,$27,$03,$29
        DB      $27,$2A,$10,$26,$25,$3E,$83

; Fragment $3A: nISwI' tIH DaparHa''a'?
; Direct player bytes: 0D 27 11 2D 27 03 2A 27 1B 03 1E 15 25 15 2B 1B 15 03 15 03 3E
Klingon_Speech_Fragment_3A:
        DB      $17                 ; encoded command count
        DB      $83,$0D,$27,$11,$2D,$27,$03,$2A
        DB      $27,$1B,$03,$1E,$15,$25,$15,$2B
        DB      $1B,$15,$03,$15,$03,$3E,$83

; Fragment $3B: nom jolwI'wIj Qap.
; Direct player bytes: 0D 26 0C 03 1E 1A 26 18 2D 27 03 2D 27 1E 1A 03 19 1B 15 25 3E
Klingon_Speech_Fragment_3B:
        DB      $17                 ; encoded command count
        DB      $83,$0D,$26,$0C,$03,$1E,$1A,$26
        DB      $18,$2D,$27,$03,$2D,$27,$1E,$1A
        DB      $03,$19,$1B,$15,$25,$3E,$83

; Fragment $3C: DaH 'IDnarwIj DaSov.
; Direct player bytes: 1E 15 1B 03 27 1E 0D 15 2B 2D 27 1E 1A 03 1E 15 11 26 0F 3E
Klingon_Speech_Fragment_3C:
        DB      $16                 ; encoded command count
        DB      $83,$1E,$15,$1B,$03,$27,$1E,$0D
        DB      $15,$2B,$2D,$27,$1E,$1A,$03,$1E
        DB      $15,$11,$26,$0F,$3E,$83

; Fragment $3D: chaq maghomqa'.
; Direct player bytes: 2A 10 15 19 03 0C 15 1C 1B 26 0C 19 15 03 3E
Klingon_Speech_Fragment_3D:
        DB      $11                 ; encoded command count
        DB      $83,$2A,$10,$15,$19,$03,$0C,$15
        DB      $1C,$1B,$26,$0C,$19,$15,$03,$3E
        DB      $83

; Fragment $3E: QoQ 'oH jorlIj'e'.
; Direct player bytes: 19 1B 26 19 1B 03 26 1B 03 1E 1A 26 2B 18 27 1E 1A 03 3B 03 3E
Klingon_Speech_Fragment_3E:
        DB      $17                 ; encoded command count
        DB      $83,$19,$1B,$26,$19,$1B,$03,$26
        DB      $1B,$03,$1E,$1A,$26,$2B,$18,$27
        DB      $1E,$1A,$03,$3B,$03,$3E,$83

; Fragment $3F: vIjatlhqa'.
; Direct player bytes: 0F 27 1E 1A 15 2A 18 1B 19 15 03 3E
Klingon_Speech_Fragment_3F:
        DB      $0E                 ; encoded command count
        DB      $83,$0F,$27,$1E,$1A,$15,$2A,$18
        DB      $1B,$19,$15,$03,$3E,$83

; Fragment $40: SuvwI' joH
; Direct player bytes: 11 28 0F 2D 27 03 1E 1A 26 1B 3E
Klingon_Speech_Fragment_40:
        DB      $0D                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$1E
        DB      $1A,$26,$1B,$3E,$83

; Fragment $41: SuvwI' joH (padded)
; Direct player bytes: 11 28 0F 2D 27 03 1E 1A 26 1B 3E 03
Klingon_Speech_Fragment_41:
        DB      $0D                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$1E
        DB      $1A,$26,$1B,$3E,$83

; Fragment $42: yIghuH! QemjIq DaghoS.
; Direct player bytes: 29 27 1C 1B 28 1B 3E 19 1B 3B 0C 1E 1A 27 19 03 1E 15 1C 1B 26 11 3E
Klingon_Speech_Fragment_42:
        DB      $19                 ; encoded command count
        DB      $83,$29,$27,$1C,$1B,$28,$1B,$3E
        DB      $19,$1B,$3B,$0C,$1E,$1A,$27,$19
        DB      $03,$1E,$15,$1C,$1B,$26,$11,$3E
        DB      $83

; Fragment $43: QemjIqDaq He'lIj ghoS.
; Direct player bytes: 19 1B 3B 0C 1E 1A 27 19 1E 15 19 03 1B 3B 03 18 27 1E 1A 03 1C 1B 26 11 3E
Klingon_Speech_Fragment_43:
        DB      $1B                 ; encoded command count
        DB      $83,$19,$1B,$3B,$0C,$1E,$1A,$27
        DB      $19,$1E,$15,$19,$03,$1B,$3B,$03
        DB      $18,$27,$1E,$1A,$03,$1C,$1B,$26
        DB      $11,$3E,$83

; Fragment $44: Wor bIghHa'mey qoDDaq yIghoS.
; Direct player bytes: 2D 26 2B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 03 19 26 1E 1E 15 19 03 29 27 1C 1B 26 11 3E
Klingon_Speech_Fragment_44:
        DB      $1F                 ; encoded command count
        DB      $83,$2D,$26,$2B,$03,$0E,$27,$1C
        DB      $1B,$1B,$15,$03,$0C,$3B,$29,$03
        DB      $19,$26,$1E,$1E,$15,$19,$03,$29
        DB      $27,$1C,$1B,$26,$11,$3E,$83

; Fragment $45: yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
; Direct player bytes: 29 27 1C 1B 28 1B 3E 11 28 0F 2D 27 03 1E 1A 26 1B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 1E 15 19 03 11 26 1B 3E
Klingon_Speech_Fragment_45:
        DB      $26                 ; encoded command count
        DB      $83,$29,$27,$1C,$1B,$28,$1B,$3E
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A
        DB      $26,$1B,$03,$0E,$27,$1C,$1B,$1B
        DB      $15,$03,$0C,$3B,$29,$1E,$15,$19
        DB      $03,$11,$26,$1B,$3E,$83

; Fragment $46: DaSo' 'e' DaQub; bIghHa' pIn jIH.
; Direct player bytes: 1E 15 11 26 03 3B 03 1E 15 19 1B 28 0E 03 0E 27 1C 1B 1B 15 03 25 27 0D 03 1E 1A 27 1B 3E
Klingon_Speech_Fragment_46:
        DB      $20                 ; encoded command count
        DB      $83,$1E,$15,$11,$26,$03,$3B,$03
        DB      $1E,$15,$19,$1B,$28,$0E,$03,$0E
        DB      $27,$1C,$1B,$1B,$15,$03,$25,$27
        DB      $0D,$03,$1E,$1A,$27,$1B,$3E,$83

; Fragment $47: Thor, Bur, Gar! SopmeH yIghuH.
; Direct player bytes: 2A 1B 26 2B 03 0E 28 2B 03 1C 15 2B 3E 11 26 25 0C 3B 1B 03 29 27 1C 1B 28 1B 3E
Klingon_Speech_Fragment_47:
        DB      $1D                 ; encoded command count
        DB      $83,$2A,$1B,$26,$2B,$03,$0E,$28
        DB      $2B,$03,$1C,$15,$2B,$3E,$11,$26
        DB      $25,$0C,$3B,$1B,$03,$29,$27,$1C
        DB      $1B,$28,$1B,$3E,$83

; Fragment $48: DaSlIj yIrar!
; Direct player bytes: 1E 15 11 18 27 1E 1A 03 29 27 2B 15 2B 3E
Klingon_Speech_Fragment_48:
        DB      $10                 ; encoded command count
        DB      $83,$1E,$15,$11,$18,$27,$1E,$1A
        DB      $03,$29,$27,$2B,$15,$2B,$3E,$83

; Fragment $49: SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.
; Direct player bytes: 11 28 0F 2D 27 03 1E 1A 26 1B 03 0E 27 1C 1B 1B 15 03 0C 3B 29 1E 15 19 03 19 3B 2A 03 1B 15 03 1E 27 0E 15 1B 0C 3B 29 2D 27 1E 1A 3E
Klingon_Speech_Fragment_49:
        DB      $2F                 ; encoded command count
        DB      $83,$11,$28,$0F,$2D,$27,$03,$1E
        DB      $1A,$26,$1B,$03,$0E,$27,$1C,$1B
        DB      $1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$19,$3B,$2A,$03,$1B,$15
        DB      $03,$1E,$27,$0E,$15,$1B,$0C,$3B
        DB      $29,$2D,$27,$1E,$1A,$3E,$83

; Fragment $4A: DaH yImI'; latlh DuH Daghajbe'.
; Direct player bytes: 1E 15 1B 03 29 27 0C 27 03 18 15 2A 18 1B 03 1E 28 1B 03 1E 15 1C 1B 15 1E 1A 0E 3B 03 3E
Klingon_Speech_Fragment_4A:
        DB      $20                 ; encoded command count
        DB      $83,$1E,$15,$1B,$03,$29,$27,$0C
        DB      $27,$03,$18,$15,$2A,$18,$1B,$03
        DB      $1E,$28,$1B,$03,$1E,$15,$1C,$1B
        DB      $15,$1E,$1A,$0E,$3B,$03,$3E,$83

; Fragment $4B: QemjIqDaq bIyInlaH'a'?
; Direct player bytes: 19 1B 3B 0C 1E 1A 27 19 1E 15 19 03 0E 27 29 27 0D 18 15 1B 03 15 03 3E
Klingon_Speech_Fragment_4B:
        DB      $1A                 ; encoded command count
        DB      $83,$19,$1B,$3B,$0C,$1E,$1A,$27
        DB      $19,$1E,$15,$19,$03,$0E,$27,$29
        DB      $27,$0D,$18,$15,$1B,$03,$15,$03
        DB      $3E,$83

; Fragment $4C: toH! reDmey vIlIjpu'.
; Direct player bytes: 2A 26 1B 3E 2B 3B 1E 0C 3B 29 03 0F 27 18 27 1E 1A 25 28 03 3E
Klingon_Speech_Fragment_4C:
        DB      $17                 ; encoded command count
        DB      $83,$2A,$26,$1B,$3E,$2B,$3B,$1E
        DB      $0C,$3B,$29,$03,$0F,$27,$18,$27
        DB      $1E,$1A,$25,$28,$03,$3E,$83

; Fragment $4D: nuqDaq DaSo'?
; Direct player bytes: 0D 28 19 1E 15 19 03 1E 15 11 26 03 3E
Klingon_Speech_Fragment_4D:
        DB      $0F                 ; encoded command count
        DB      $83,$0D,$28,$19,$1E,$15,$19,$03
        DB      $1E,$15,$11,$26,$03,$3E,$83

; Fragment $4E: SoH.
; Direct player bytes: 11 26 1B 3E
Klingon_Speech_Fragment_4E:
        DB      $06                 ; encoded command count
        DB      $83,$11,$26,$1B,$3E,$83

        ORG     $CD8D

; 84 pointer slots ($00-$53). $00-$4E are populated; $4F-$53 are null.
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
        DW      Klingon_Speech_Fragment_4E      ; fragment $4E
        DW      $0000                              ; fragment $4F null/unused
        DW      $0000                              ; fragment $50 null/unused
        DW      $0000                              ; fragment $51 null/unused
        DW      $0000                              ; fragment $52 null/unused
        DW      $0000                              ; fragment $53 null/unused

; Exact 80-entry resident English phrase composition, used as the compatibility
; baseline because Klingon fragments $00-$4E now parallel English semantics.
Klingon_Speech_Phrase_Table:
        DB      $81,$0A              ; phrase $00
        DB      $82,$0B,$04              ; phrase $01
        DB      $81,$0A              ; phrase $02
        DB      $82,$0C,$10              ; phrase $03
        DB      $81,$0A              ; phrase $04
        DB      $82,$0B,$04              ; phrase $05
        DB      $81,$0A              ; phrase $06
        DB      $82,$0C,$10              ; phrase $07
        DB      $82,$0D,$09              ; phrase $08
        DB      $82,$0E,$04              ; phrase $09
        DB      $81,$0F              ; phrase $0A
        DB      $82,$11,$10              ; phrase $0B
        DB      $82,$1E,$36              ; phrase $0C
        DB      $81,$2D              ; phrase $0D
        DB      $82,$2E,$10              ; phrase $0E
        DB      $82,$2F,$10              ; phrase $0F
        DB      $81,$00              ; phrase $10
        DB      $82,$4E,$02              ; phrase $11
        DB      $82,$03,$04              ; phrase $12
        DB      $82,$05,$10              ; phrase $13
        DB      $81,$06              ; phrase $14
        DB      $81,$07              ; phrase $15
        DB      $82,$08,$37              ; phrase $16
        DB      $82,$33,$36              ; phrase $17
        DB      $81,$23              ; phrase $18
        DB      $82,$24,$36              ; phrase $19
        DB      $82,$27,$36              ; phrase $1A
        DB      $82,$25,$36              ; phrase $1B
        DB      $82,$30,$36              ; phrase $1C
        DB      $82,$31,$09              ; phrase $1D
        DB      $81,$32              ; phrase $1E
        DB      $81,$1D              ; phrase $1F
        DB      $82,$12,$36              ; phrase $20
        DB      $81,$13              ; phrase $21
        DB      $81,$14              ; phrase $22
        DB      $82,$15,$40              ; phrase $23
        DB      $82,$37,$26              ; phrase $24
        DB      $82,$34,$10              ; phrase $25
        DB      $83,$09,$22,$10              ; phrase $26
        DB      $82,$35,$37              ; phrase $27
        DB      $82,$1A,$36              ; phrase $28
        DB      $81,$1B              ; phrase $29
        DB      $82,$1C,$36              ; phrase $2A
        DB      $82,$01,$36              ; phrase $2B
        DB      $82,$1F,$09              ; phrase $2C
        DB      $82,$09,$20              ; phrase $2D
        DB      $82,$21,$36              ; phrase $2E
        DB      $82,$28,$36              ; phrase $2F
        DB      $83,$16,$04,$10              ; phrase $30
        DB      $82,$17,$37              ; phrase $31
        DB      $82,$18,$37              ; phrase $32
        DB      $82,$04,$19              ; phrase $33
        DB      $82,$29,$37              ; phrase $34
        DB      $81,$2A              ; phrase $35
        DB      $82,$2B,$36              ; phrase $36
        DB      $81,$2C              ; phrase $37
        DB      $83,$38,$04,$10              ; phrase $38
        DB      $83,$39,$37,$36              ; phrase $39
        DB      $82,$3A,$10              ; phrase $3A
        DB      $82,$3B,$36              ; phrase $3B
        DB      $82,$3C,$37              ; phrase $3C
        DB      $82,$09,$3D              ; phrase $3D
        DB      $82,$3E,$10              ; phrase $3E
        DB      $83,$3F,$34,$10              ; phrase $3F
        DB      $83,$41,$42,$36              ; phrase $40
        DB      $83,$41,$43,$36              ; phrase $41
        DB      $83,$44,$02,$36              ; phrase $42
        DB      $81,$45              ; phrase $43
        DB      $82,$46,$36              ; phrase $44
        DB      $82,$47,$36              ; phrase $45
        DB      $82,$48,$10              ; phrase $46
        DB      $82,$49,$36              ; phrase $47
        DB      $82,$4A,$10              ; phrase $48
        DB      $82,$4B,$10              ; phrase $49
        DB      $82,$4C,$10              ; phrase $4A
        DB      $82,$4D,$36              ; phrase $4B
        DB      $82,$4A,$10              ; phrase $4C
        DB      $82,$4B,$36              ; phrase $4D
        DB      $82,$4C,$10              ; phrase $4E
        DB      $82,$4D,$36              ; phrase $4F

        DB      $FF,$FF              ; alignment to German checksum address
Klingon_Checksum_Compensation:
        DB      $78                 ; complete 4 KiB sum = $00

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
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

Klingon_ROM_Identification:
        DB      "KLINGONWIZARD",$00
Klingon_ROM_Manufacturer:
        DB      "DNA",$00
Klingon_ROM_Date:
        DB      $08,$08,$26

        END
