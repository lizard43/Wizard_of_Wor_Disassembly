; GERMAN_X11.asm
;==============================================================================
; Wizard of Wor - German X11 Foreign-Language ROM
;==============================================================================
;
; Reverse source for the 4 KB language ROM installed at $C000-$CFFF.
; Original reverse engineering/disassembly attributed to Richard C. Degler.
;
; The main Wizard of Wor program treats X11 as a data-driven localization
; module. The six-field, 13-byte header area supplies speech tables, coinage data,
; the expected diagnostic checksum, an alternate-font pointer, and the base of
; the length-prefixed localized text records. No executable code is required.
;
;==============================================================================

        NOLIST
;                               ; no EQUates

        LIST
        ORG     $C000           ; German LANGUAGE data ROM start

X11_Speech_Fragment_Table_Ptr:
        DW      German_Speech_Fragment_Pointers ; $C000: fragment-index -> address table

X11_Speech_Phrase_Table_Ptr:
        DW      German_Speech_Phrase_Table      ; $C002: 80 phrase definitions ($00-$4F)

; Foreign-mode coinage values. The main program selects this six-byte table
; instead of its resident Coinage_Value_Table whenever language DIP bit 3 is 0.
X11_Coinage_Value_Table:
        DB      $10,$20,$30,$40,$70,$50

; The diagnostics calculate an 8-bit additive checksum across the complete
; $C000-$CFFF X11 image and compare it with this header byte.
X11_ROM_Checksum_Expected:
        DB      $00

; Pointer used by char2gfx for character codes routed to the alternate font.
X11_Alternate_Font_Ptr:
        DW      German_Alternate_Font

; Twenty-three 1-based localized text records. Each record is encoded as:
;     DB length,"characters"
; Character bytes are $30 or above; record lengths therefore occupy $00-$2F,
; making 47 characters the maximum representable length.
German_Localized_Text_Table:
; Text $01: English source "INSERT COIN"
        DB      $0F,"@MUENZEINWURF@@"

; Text $02: English source "HIGH SCORES"
        DB      $0F,"HOECHSTERGEBNIS"

; Text $03: English source "PRESS ONE PLAYER BUTTON"
        DB      $1C,"DRUECKEN@SIE@1@SPIELER@KNOPF"

; Text $04: English source "PRESS TWO PLAYER BUTTON"
        DB      $1E,"@DRUECKEN@SIE@2@SPIELER@KNOPF@"

; Text $05: English source "OR"
        DB      $04,"ODER"

; Text $06: English source "DEPOSIT ADDITIONAL COIN"
        DB      $1E,"WERFEN@SIE@ZUSAETZLICHE@MUENZE"

; Text $07: English source "FOR TWO PLAYER GAME"
        DB      $12,"FUER@2@SPIELER@EIN"

; Text $08: English source "POINTS"
        DB      $06,"PUNKTE"

; Text $09: English source "BONUS PLAYER"
        DB      $0D,"BONUS@SPIELER"

; Text $0A: English source "WAIT FOR INSTRUCTIONS"
        DB      $1A,"WARTEN@SIE@AUF@ANWEISUNGEN"

; Text $0B: English source "INVISIBLE MONSTERS IN THE MAZE"
        DB      $20,"UNSICHTBARE@MONSTER@IM@LABYRINTH"

; Text $0C: English source "ARE LOCATED USING THE RADAR SCREEN"
        DB      $26,"WERDEN@DURCH@RADARSTRAHLEN@LOKALISIERT"

; Text $0D: English source "MONSTERS BECOME VISIBLE WHEN ENTERING"
        DB      $24,"MONSTER@WERDEN@SICHTBAR@WENN@SIE@DEN"

; Text $0E: English source "THE SAME MAZE CORRIDOR AS THE PLAYER"
        DB      $1E,"KORRIDOR@DES@SPIELERS@BETRETEN"

; Text $0F: English source "GET READY"
        DB      $0F,"AUF@DIE@PLAETZE"

; Text $10: English source "RADAR"
        DB      $05,"RADAR"

; Text $11: English source "ESCAPED"
        DB      $06,"ENTKAM"

; Text $12: English source "CREDITS"
        DB      $06,"KREDIT"

; Text $13: English source "DUNGEON"
        DB      $0B,"LABYRINTH@@"

; Text $14: English source "WORLORD DUNGEON"
        DB      $11,"WORLORD@LABYRINTH"

; Text $15: English source "THE ARENA"
        DB      $09,"DIE@ARENA"

; Text $16: English source "THE PIT"
        DB      $0D,"@DIE@VERLIESS"

; Text $17: English source "OR FOR ADDITIONAL WORRIORS"
        DB      $1A,"ODER@FUER@WEITERE@WORRIORS"

        NOP                             ; $C1D1 alignment byte preserved from original ROM

; Alternate font storage. char2gfx uses the pointer at $C00B for character
; codes routed beyond the resident font range. The German ROM defines no custom
; glyphs here; the reserved bytes remain $FF.
German_Alternate_Font:  DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; reserved glyph slot 'b'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; reserved glyph slot 'c'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; reserved glyph slot 'd'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; reserved glyph slot 'e'
        DB      $FF,$FF,$FF,$FF,$FF,$FF   ; partial reserved glyph slot 'f'

; German speech fragment $00 @ $C200
; Data = ^PAuse0-F-A1-R-N-Y-H-H-T-E1-PAuse0-W-O-O1-R-L-UH-K ...
; ... -F-IU-IU-R-D-O2-P-A1-L-T-I-P-W-W-N-K-T-S-AW1-AW2-L-PAuse1-^PAuse0

;==============================================================================
; GERMAN SPEECH FRAGMENTS
;
; MAME 0.289: PAuse1 before M prevents SC-01 lockups.
; Phoneme comments retain the original German stream.
;

; Each fragment begins with a byte count followed by that many encoded SC-01
; bytes. Bit 7 participates in the game's stateful inflection encoding; the
; playback routine XORs each stored byte with the previous inflection state
; before sending the resulting phoneme command to the SC-01 interface.
;
; Phrase definitions do not point directly at these records. They contain
; fragment indexes, which are resolved through German_Speech_Fragment_Pointers.
; Full phrase composition and German phrase transcriptions are documented in
; doc/SPEECH_MAP.md.
;==============================================================================
German_Speech_Fragment_00:  DB      $29             ; encoded SC-01 byte count
        DB      $83,$1D,$06,$2B,$0D,$29,$1B,$1B
        DB      $2A,$3C,$03,$2D,$26,$35,$2B,$18
        DB      $33,$19,$1D,$36,$36,$2B,$1E,$34
        DB      $25,$06,$18,$2A,$27,$25,$2D,$2D
        DB      $0D,$19,$2A,$1F,$13,$30,$18,$3E
        DB      $83

; German speech fragment $01 @ $C22A
; Data = ^PAuse0-V-A1-N-N-D-U1-U1-PAuse0-S-U1-U1-M-A2-H-H-T-Y-G-PAuse0 ...
; ... -V-Y-R-S-T-PAuse1-G-EH-AH2-E1-F-E1-PAuse0-Y-H-H-S-A1-L-B-S-T-PAuse0 ...
; ... -AH2-E1-N-PAuse1-^PAuse0
German_Speech_Fragment_01:  DB      $31             ; encoded SC-01 byte count
        DB      $83,$0F,$06,$0D,$0D,$1E,$37,$37
        DB      $03,$1F,$37,$37,$3E,$0C,$05,$1B
        DB      $1B,$2A,$29,$1C,$03,$0F,$29,$2B
        DB      $1F,$2A,$3E,$1C,$3B,$08,$3C,$1D
        DB      $3C,$03,$29,$1B,$1B,$1F,$06,$18
        DB      $0E,$1F,$2A,$03,$08,$3C,$0D,$3E
        DB      $83

; German speech fragment $4E @ $C25B
; Data = ^PAuse0-D-U-U-B-Y-S-T-T-Y-N-N-D-A1-N-^PAuse0
German_Speech_Fragment_4E:  DB      $10             ; encoded SC-01 byte count
        DB      $83,$1E,$28,$28,$0E,$29,$1F,$2A
        DB      $2A,$29,$0D,$0D,$1E,$06,$0D,$83

; German speech fragment $02 @ $C26C
; Data = ^PAuse0-L-AH1-B-IU-IU-IU-R-I1-N-T-^PAuse0
German_Speech_Fragment_02:  DB      $0C             ; encoded SC-01 byte count
        DB      $83,$18,$15,$0E,$36,$36,$36,$2B
        DB      $0B,$0D,$2A,$83

; German speech fragment $50 @ $C279
; Data = ^PAuse0-F-O1-N-W-O-O1-R-PAuse1-^PAuse0
German_Speech_Fragment_50:  DB      $0A             ; encoded SC-01 byte count
        DB      $83,$1D,$35,$0D,$2D,$26,$35,$2B
        DB      $3E,$83

; German speech fragment $04 @ $C284
; Data = W-vI-Z-ER-D-F-O1-N-PAuse0-vW-O-O1-R-R-PAuse1
German_Speech_Fragment_04:  DB      $0F             ; encoded SC-01 byte count
        DB      $2D,$67,$12,$3A,$1E,$1D,$35,$0D
        DB      $03,$6D,$26,$35,$2B,$2B,$3E

; German speech fragment $05 @ $C294
; Data = AH2-E1-N-B-Y-S-S-F-O1-N-M-AH2-E1-N-E1-N-SH-OO1-A2-N-A1-N-PAuse0 ...
; ... -W-N-D-D-W-W-A1-G-S-P-L-O2-D-Y-R-S-T-PAuse1
German_Speech_Fragment_05:  DB      $2A             ; encoded SC-01 byte count
        DB      $08,$3C,$0D,$0E,$29,$1F,$1F,$1D
        DB      $35,$0D,$3E,$0C,$08,$3C,$0D,$3C
        DB      $0D,$11,$16,$05,$0D,$06,$0D,$03
        DB      $2D,$0D,$1E,$1E,$2D,$2D,$06,$1C
        DB      $1F,$25,$18,$34,$1E,$29,$2B,$1F
        DB      $2A,$3E

; German speech fragment $06 @ $C2BE
; Data = M-AH2-E1-N-A1-K-R-A1-UH-T-W-W-R-A1-N-Z-Y-N-D-PAuse0 ...
; ... -R-AH-D-Y-Y-O2-O1-UH-K-T-T-Y-Y-V-V-PAuse1
German_Speech_Fragment_06:  DB      $25             ; encoded SC-01 byte count
        DB      $3E,$0C,$08,$3C,$0D,$06,$19,$2B
        DB      $06,$33,$2A,$2D,$2D,$2B,$06,$0D
        DB      $12,$29,$0D,$1E,$03,$2B,$24,$1E
        DB      $29,$29,$34,$35,$33,$19,$2A,$2A
        DB      $29,$29,$0F,$0F,$3E

; German speech fragment $07 @ $C2E3
; Data = W-O-R-L-UH-K-PAuse0-V-Y-R-D-PAuse0 ...
; ... -D-U1-R-H-H-D-Y-Y-T-T-IU-Y1-R-A1-N-T-K-O1-M-M-A1-N-PAuse1
German_Speech_Fragment_07:  DB      $25             ; encoded SC-01 byte count
        DB      $2D,$26,$2B,$18,$33,$19,$03,$0F
        DB      $29,$2B,$1E,$03,$1E,$37,$2B,$1B
        DB      $1B,$1E,$29,$29,$2A,$2A,$36,$22
        DB      $2B,$06,$0D,$2A,$19,$35,$3E,$0C
        DB      $3E,$0C,$06,$0D,$3E

; German speech fragment $03 @ $C307
; Data = Y-H-H-B-I3-N-D-A1-R
German_Speech_Fragment_03:  DB      $09             ; encoded SC-01 byte count
        DB      $29,$1B,$1B,$0E,$09,$0D,$1E,$06
        DB      $2B

; German speech fragment $22 @ $C311
; Data = D-U1-U1-B-L-AH2-E1-B-S-T-N-Y-H-H-T-G-AW1-N-S-PAuse1 ...
; ... -N-AW1-H-D-Y-Y-Z-A1-M-PAuse0-V-Y-Y-L-D-A1-N-PAuse0-T-AW1-N-N-S-PAuse1
German_Speech_Fragment_22:  DB      $2D             ; encoded SC-01 byte count
        DB      $1E,$37,$37,$0E,$18,$08,$3C,$0E
        DB      $1F,$2A,$0D,$29,$1B,$1B,$2A,$1C
        DB      $13,$0D,$1F,$3E,$0D,$13,$1B,$1E
        DB      $29,$29,$12,$06,$3E,$0C,$03,$0F
        DB      $29,$29,$18,$1E,$06,$0D,$03,$2A
        DB      $13,$0D,$0D,$1F,$3E

; German speech fragment $23 @ $C33E
; Data = ^PAuse0-D-A1-N-K-PAuse0-D-R-AW1-N-N-PAuse1 ...
; ... -Y-H-F-B-Y-N-D-E1-R-W-I-Z-ER-D-PAuse1-N-Y-H-H-T-D-U1-U1-PAuse1-^PAuse0
German_Speech_Fragment_23:  DB      $25             ; encoded SC-01 byte count
        DB      $83,$1E,$06,$0D,$19,$03,$1E,$2B
        DB      $13,$0D,$0D,$3E,$29,$1B,$1D,$0E
        DB      $29,$0D,$1E,$3C,$2B,$2D,$27,$12
        DB      $3A,$1E,$3E,$0D,$29,$1B,$1B,$2A
        DB      $1E,$37,$37,$3E,$83

; German speech fragment $24 @ $C364
; Data = V-A1-N-N-D-U1-U1-PAuse0-SH-L-A2-A2-G-S-S-T-UH-U1-H-H-PAuse0 ...
; ... -D-Y-Y-PAuse0-R-A1-S-T-A1-PAuse1-^PAuse0 ...
; ... -D-UH-N-N-K-UH-N-N-S-T-N-A1-N-N-A1-N-D-Y-H-H-D-A1-R-PAuse0 ...
; ... -B-A1-V-T-A1-PAuse0-PAuse1-^PAuse0
German_Speech_Fragment_24:  DB      $40             ; encoded SC-01 byte count
        DB      $0F,$06,$0D,$0D,$1E,$37,$37,$03
        DB      $11,$18,$05,$05,$1C,$1F,$1F,$2A
        DB      $33,$37,$1B,$1B,$03,$1E,$29,$29
        DB      $03,$2B,$06,$1F,$2A,$06,$3E,$83
        DB      $1E,$33,$0D,$0D,$19,$33,$0D,$0D
        DB      $1F,$2A,$0D,$06,$0D,$0D,$06,$0D
        DB      $1E,$29,$1B,$1B,$1E,$06,$2B,$03
        DB      $0E,$06,$0F,$2A,$06,$03,$3E,$83

; German speech fragment $25 @ $C3A5
; Data = ^PAuse0-V-I2-N-N-D-U1-U1-M-AH2-E1-N-E1-B-A2-AY-AY-B-Y-Y-S ...
; ... -AH2-N-F-AH1-S-T-PAuse1 ...
; ... -V-A1-R-D-E1-Y-H-H-D-Y-Y-H-H-Y-M-O1-O1-F-A1-N-B-R-AW-T-A1-N-PAuse1-^PAuse0
German_Speech_Fragment_25:  DB      $3A             ; encoded SC-01 byte count
        DB      $83,$0F,$0A,$0D,$0D,$1E,$37,$37
        DB      $3E,$0C,$08,$3C,$0D,$3C,$0E,$05
        DB      $21,$21,$0E,$29,$29,$1F,$08,$0D
        DB      $1D,$15,$1F,$2A,$3E,$0F,$06,$2B
        DB      $1E,$3C,$29,$1B,$1B,$1E,$29,$29
        DB      $1B,$1B,$29,$3E,$0C,$35,$35,$1D
        DB      $06,$0D,$0E,$2B,$3D,$2A,$06,$0D
        DB      $3E,$83

; German speech fragment $26 @ $C3DE
; Data = ^PAuse0-L-AH2-AH2-N-G-Z-AH2-AH2-M-V-A1-R-D-E1-PAuse0-Y-H-H-PAuse0 ...
; ... -B-OO1-Y-Y-Z-E1-PAuse1-^PAuse0
German_Speech_Fragment_26:  DB      $1D             ; encoded SC-01 byte count
        DB      $83,$18,$08,$08,$0D,$1C,$12,$08
        DB      $08,$3E,$0C,$0F,$06,$2B,$1E,$3C
        DB      $03,$29,$1B,$1B,$03,$0E,$16,$29
        DB      $29,$12,$3C,$3E,$83

; German speech fragment $27 @ $C3FB
; Data = ^PAuse0-D-U1-U1-V-Y-R-S-T-V-O1-O1-R-PAuse0-PAuse0 ...
; ... -N-Y-H-H-T-AW2-M-M-PAuse0-L-A1-B-E1-N-D-Y-G-A1-N-L-AH2-E1-B-E1-PAuse0 ...
; ... -F-A1-R-L-AH2-S-A1-N-PAuse1-^PAuse0
German_Speech_Fragment_27:  DB      $34             ; encoded SC-01 byte count
        DB      $83,$1E,$37,$37,$0F,$29,$2B,$1F
        DB      $2A,$0F,$35,$35,$2B,$03,$03,$0D
        DB      $29,$1B,$1B,$2A,$30,$3E,$0C,$3E
        DB      $0C,$03,$18,$06,$0E,$3C,$0D,$1E
        DB      $29,$1C,$06,$0D,$18,$08,$3C,$0E
        DB      $3C,$03,$1D,$06,$2B,$18,$08,$1F
        DB      $06,$0D,$3E,$83

; German speech fragment $1B @ $C42E
; Data = ^PAuse0-G-vAH1-R-W-O1-R-PAuse1-P-AH1-K-K-PAuse0-Z-Y-Y-PAuse1-^PAuse0
German_Speech_Fragment_1B:  DB      $12             ; encoded SC-01 byte count
        DB      $83,$1C,$55,$2B,$2D,$35,$2B,$3E
        DB      $25,$15,$19,$19,$03,$12,$29,$29
        DB      $3E,$83

; German speech fragment $08 @ $C441
; Data = ^PAuse0-B-E1-PAuse0-O2-O2-B-UH-H-H-T-T-A1-PAuse0 ...
; ... -D-A1-A2-N-ER-UH-D-D-UH-R-SH-Y-R-M-M-^PAuse0-PAuse0-PAuse1
German_Speech_Fragment_08:  DB      $22             ; encoded SC-01 byte count
        DB      $83,$0E,$3C,$03,$34,$34,$0E,$33
        DB      $1B,$1B,$2A,$2A,$06,$03,$1E,$06
        DB      $05,$0D,$3A,$33,$1E,$1E,$33,$2B
        DB      $11,$29,$2B,$3E,$0C,$3E,$0C,$83
        DB      $03,$3E

; German speech fragment $09 @ $C462; runtime substitutes $40 when Dungeon_Class ($D350) != 0
; Data = W-O-R-Y-ER-PAuse1
German_Speech_Fragment_09:  DB      $06             ; encoded SC-01 byte count
        DB      $2D,$26,$2B,$29,$3A,$3E

; German speech fragment $1A @ $C469
; Data = ^PAuse0-J-A1-T-S-T-K-O2-M-A1-N-D-Y-SH-V-A1-R-G-E1-V-Y-H-H-T-E1 ...
; ... -PAuse1-^PAuse0
German_Speech_Fragment_1A:  DB      $1C             ; encoded SC-01 byte count
        DB      $83,$1A,$06,$2A,$1F,$2A,$19,$34
        DB      $3E,$0C,$06,$0D,$1E,$29,$11,$0F
        DB      $06,$2B,$1C,$3C,$0F,$29,$1B,$1B
        DB      $2A,$3C,$3E,$83

; German speech fragment $35 @ $C485
; Data = ^PAuse0-D-U1-U1-PAuse0-V-Y-L-S-T-V-O-L-PAuse0-A2-A2-R-G-A2-R-PAuse1 ...
; ... -^PAuse0
German_Speech_Fragment_35:  DB      $16             ; encoded SC-01 byte count
        DB      $83,$1E,$37,$37,$03,$0F,$29,$18
        DB      $1F,$2A,$0F,$26,$18,$03,$05,$05
        DB      $2B,$1C,$05,$2B,$3E,$83

; German speech fragment $1C @ $C49C
; Data = ^PAuse0-V-A1-N-N-D-U1-U1-S-PAuse0 ...
; ... -N-O1-H-H-M-AW-L-F-A1-R-Z-U1-U1-H-H-S-T-PAuse1 ...
; ... -H-UH-U1-A1-N-V-Y-Y-R-D-Y-H-H-Y-N-D-Y-PAuse0-P-F-AH2-N-N-E1-PAuse1-^PAuse0
German_Speech_Fragment_1C:  DB      $37             ; encoded SC-01 byte count
        DB      $83,$0F,$06,$0D,$0D,$1E,$37,$37
        DB      $1F,$03,$0D,$35,$1B,$1B,$3E,$0C
        DB      $3D,$18,$1D,$06,$2B,$12,$37,$37
        DB      $1B,$1B,$1F,$2A,$3E,$1B,$33,$37
        DB      $06,$0D,$0F,$29,$29,$2B,$1E,$29
        DB      $1B,$1B,$29,$0D,$1E,$29,$03,$25
        DB      $1D,$08,$0D,$0D,$3C,$3E,$83

; German speech fragment $1D @ $C4D3
; Data = ^PAuse0-B-vER-vR-W-O-R-PAuse1-G-vAH1-vR-W-O-R-PAuse1 ...
; ... -U1-U1-N-D-TH-vR-vR-W-O-R-PAuse1-V-A1-R-D-A1-N-D-Y-H-H-PAuse0 ...
; ... -AH2-E1-N-M-AW1-H-H-A1-N-PAuse1-^PAuse0
German_Speech_Fragment_1D:  DB      $31             ; encoded SC-01 byte count
        DB      $83,$0E,$7A,$6B,$2D,$26,$2B,$3E
        DB      $1C,$55,$6B,$2D,$26,$2B,$3E,$37
        DB      $37,$0D,$1E,$39,$66,$6B,$2D,$26
        DB      $2B,$3E,$0F,$06,$2B,$1E,$06,$0D
        DB      $1E,$29,$1B,$1B,$03,$08,$3C,$0D
        DB      $3E,$0C,$13,$1B,$1B,$06,$0D,$3E
        DB      $83

; German speech fragment $1E @ $C504
; Data = ^PAuse0-M-AH2-E1-N-E1-SH-IU-IU-T-Z-L-I1-N-UH2-PAuse0 ...
; ... -Z-Y-N-D-Z-Z-E1-R-PAuse0-G-E1-F-R-A2-A2-S-Y-G-PAuse1-^PAuse0
German_Speech_Fragment_1E:  DB      $25             ; encoded SC-01 byte count
        DB      $83,$3E,$0C,$08,$3C,$0D,$3C,$11
        DB      $36,$36,$2A,$12,$18,$0B,$0D,$31
        DB      $03,$12,$29,$0D,$1E,$12,$12,$3C
        DB      $2B,$03,$1C,$3C,$1D,$2B,$05,$05
        DB      $1F,$29,$1C,$3E,$83

; German speech fragment $1F @ $C529
; Data = M-AH2-E1-N-E1-M-UH-PAuse0-G-Y-SH-E1-K-R-AW1-F-T-PAuse0-Y-S-T-PAuse0 ...
; ... -S-T-A1-A1-R-K-A1-R-AH1-L-S-PAuse0-D-AH2-E1-N-E1-PAuse0 ...
; ... -V-AH1-F-F-A1-N-PAuse1
German_Speech_Fragment_1F:  DB      $31             ; encoded SC-01 byte count
        DB      $3E,$0C,$08,$3C,$0D,$3C,$3E,$0C
        DB      $33,$03,$1C,$29,$11,$3C,$19,$2B
        DB      $13,$1D,$2A,$03,$29,$1F,$2A,$03
        DB      $1F,$2A,$06,$06,$2B,$19,$06,$2B
        DB      $15,$18,$1F,$03,$1E,$08,$3C,$0D
        DB      $3C,$03,$0F,$15,$1D,$1D,$06,$0D
        DB      $3E

; German speech fragment $21 @ $C559
; Data = ^PAuse0-D-AH2-E1-N-E1-K-N-O2-H-H-A1-N-PAuse0 ...
; ... -V-A1-R-D-A1-N-Y-N-D-A2-N-PAuse0
German_Speech_Fragment_21:  DB      $1A             ; encoded SC-01 byte count
        DB      $83,$1E,$08,$3C,$0D,$3C,$19,$0D
        DB      $34,$1B,$1B,$06,$0D,$03,$0F,$06
        DB      $2B,$1E,$06,$0D,$29,$0D,$1E,$05
        DB      $0D,$03

; German speech fragment $51 @ $C574
; Data = V-O1-N-W-O-O1-R-F-A1-R-Z-Z-UH-U1-A1-R-N-PAuse1-^PAuse0
German_Speech_Fragment_51:  DB      $13             ; encoded SC-01 byte count
        DB      $0F,$35,$0D,$2D,$26,$35,$2B,$1D
        DB      $06,$2B,$12,$12,$33,$37,$06,$2B
        DB      $0D,$3E,$83

; German speech fragment $20 @ $C588
; Data = D-U1-U1-PAuse0-S-T-E1-E1-S-T-UH-U1-F-F-PAuse0 ...
; ... -V-Y-S-S-A1-N-SH-AW1-F-F-T-PAuse1-PAuse1-Y-H-H-PAuse0 ...
; ... -G-L-UH-U1-B-E1-AW1-N-N-PAuse0-M-AH1-PAuse0-G-Y-Y-PAuse1
German_Speech_Fragment_20:  DB      $32             ; encoded SC-01 byte count
        DB      $1E,$37,$37,$03,$1F,$2A,$3C,$3C
        DB      $1F,$2A,$33,$37,$1D,$1D,$03,$0F
        DB      $29,$1F,$1F,$06,$0D,$11,$13,$1D
        DB      $1D,$2A,$3E,$3E,$29,$1B,$1B,$03
        DB      $1C,$18,$33,$37,$0E,$3C,$13,$0D
        DB      $0D,$03,$3E,$0C,$15,$03,$1C,$29
        DB      $29,$3E

; German speech fragment $0A @ $C5BA
; Data = H-A-vI1-vY1-PAuse1-V-Y-R-F-PAuse1-G-A2-L-L-T-PAuse0-AH2-I1-N-N-PAuse1
German_Speech_Fragment_0A:  DB      $15             ; encoded SC-01 byte count
        DB      $1B,$20,$4B,$62,$3E,$0F,$29,$2B
        DB      $1D,$3E,$1C,$05,$18,$18,$2A,$03
        DB      $08,$0B,$0D,$0D,$3E

; German speech fragment $0B @ $C5D0
; Data = Z-U-H-H-PAuse0-M-Y-H-H-PAuse0-D-AY-AY-N-PAuse0
German_Speech_Fragment_0B:  DB      $10             ; encoded SC-01 byte count
        DB      $12,$28,$1B,$1B,$03,$3E,$0C,$29
        DB      $1B,$1B,$03,$1E,$21,$21,$0D,$03

; German speech fragment $0C @ $C5E0
; Data = Y-H-H-PAuse0-B-Y-N-PAuse0-U1-N-Z-Y-H-H-T-B-AH1-R-PAuse1
German_Speech_Fragment_0C:  DB      $13             ; encoded SC-01 byte count
        DB      $29,$1B,$1B,$03,$0E,$29,$0D,$03
        DB      $37,$0D,$12,$29,$1B,$1B,$2A,$0E
        DB      $15,$2B,$3E

; German speech fragment $0D @ $C5F4
; Data = Z-AH2-E1-PAuse1-B-E1-ER-AH2-I2-T-T
German_Speech_Fragment_0D:  DB      $0B             ; encoded SC-01 byte count
        DB      $12,$08,$3C,$3E,$0E,$3C,$3A,$08
        DB      $0A,$2A,$2A

; German speech fragment $0E @ $C600
; Data = G-N-UH-UH-D-E1-D-Y-R-G-O1-T-T-T-PAuse0-V-A1-N-N-D-W-PAuse0 ...
; ... -D-A1-A2-N-W-vI-Z-ER-D-F-O1-N-PAuse0-vW-O-O1-R-R-F-Y-N-D-A1-S-S-T-PAuse1
German_Speech_Fragment_0E:  DB      $31             ; encoded SC-01 byte count
        DB      $1C,$0D,$33,$33,$1E,$3C,$1E,$29
        DB      $2B,$1C,$35,$2A,$2A,$2A,$03,$0F
        DB      $06,$0D,$0D,$1E,$2D,$03,$1E,$06
        DB      $05,$0D,$2D,$67,$12,$3A,$1E,$1D
        DB      $35,$0D,$03,$6D,$26,$35,$2B,$2B
        DB      $1D,$29,$0D,$1E,$06,$1F,$1F,$2A
        DB      $3E

; German speech fragment $0F @ $C632
; Data = AH2-E1-N-E1-PAuse0-V-AH2-E1-T-T-AY-ER-E1-PAuse0 ...
; ... -M-IU-IU-N-T-Z-E1-PAuse0-F-IU-IU-IU-R-PAuse0-M-AH2-E1-N-E1-PAuse0 ...
; ... -B-R-Y-F-T-AH2-SH-AY-PAuse1
German_Speech_Fragment_0F:  DB      $2D             ; encoded SC-01 byte count
        DB      $08,$3C,$0D,$3C,$03,$0F,$08,$3C
        DB      $2A,$2A,$21,$3A,$3C,$03,$3E,$0C
        DB      $36,$36,$0D,$2A,$12,$3C,$03,$1D
        DB      $36,$36,$36,$2B,$03,$3E,$0C,$08
        DB      $3C,$0D,$3C,$03,$0E,$2B,$29,$1D
        DB      $2A,$08,$11,$21,$3E

; German speech fragment $10 @ $C65E
; Data = PAuse1-H-vAH1-H-vAH1-H-AH1-H-AH1-PAuse1
German_Speech_Fragment_10:  DB      $0A             ; encoded SC-01 byte count
        DB      $3E,$1B,$55,$1B,$55,$1B,$15,$1B
        DB      $15,$3E

; German speech fragment $11 @ $C669
; Data = Z-Z-E1-R-PAuse0-G-G-U-T-T-PAuse1-M-AH2-E1-N-E1-PAuse0 ...
; ... -K-L-AH2-E1-N-E1-N-PAuse0-Z-I1-N-D-Z-Z-E1-R-PAuse0-H-U1-N-G-R-E1-G-PAuse1
German_Speech_Fragment_11:  DB      $2A             ; encoded SC-01 byte count
        DB      $12,$12,$3C,$2B,$03,$1C,$1C,$28
        DB      $2A,$2A,$3E,$0C,$08,$3C,$0D,$3C
        DB      $03,$19,$18,$08,$3C,$0D,$3C,$0D
        DB      $03,$12,$0B,$0D,$1E,$12,$12,$3C
        DB      $2B,$03,$1B,$37,$0D,$1C,$2B,$3C
        DB      $1C,$3E

; German speech fragment $12 @ $C694
; Data = ^PAuse0-N-U1-U1-N-PAuse0-V-Y-R-S-T-D-U1-U1-Y-N-D-Y-PAuse1 ...
; ... -AW1-R-E1-N-AW1-PAuse0-G-E1-V-O1-R-F-A1-N-PAuse1-^PAuse1
German_Speech_Fragment_12:  DB      $23             ; encoded SC-01 byte count
        DB      $83,$0D,$37,$37,$0D,$03,$0F,$29
        DB      $2B,$1F,$2A,$1E,$37,$37,$29,$0D
        DB      $1E,$29,$3E,$13,$2B,$3C,$0D,$13
        DB      $03,$1C,$3C,$0F,$35,$2B,$1D,$06
        DB      $0D,$3E,$BE

; German speech fragment $36 @ $C6B8
; Data = ^PAuse1-H-AH1-H-AH1-H-AH1-H-AH1-PAuse1-^PAuse0
German_Speech_Fragment_36:  DB      $0B             ; encoded SC-01 byte count
        DB      $BE,$1B,$15,$1B,$15,$1B,$15,$1B
        DB      $15,$3E,$83

; German speech fragment $13 @ $C6C4
; Data = N-O2-H-H-PAuse0-AH2-E1-N-E1-N-W-O-R-Y-ER-PAuse0 ...
; ... -D-E1-N-M-AH2-E1-N-E1-PAuse0 ...
; ... -Z-U1-Y1-Y1-S-A1-N-F-A1-R-SH-L-Y-N-G-A1-N-V-A1-R-D-A1-N-PAuse1
German_Speech_Fragment_13:  DB      $32             ; encoded SC-01 byte count
        DB      $0D,$34,$1B,$1B,$03,$08,$3C,$0D
        DB      $3C,$0D,$2D,$26,$2B,$29,$3A,$03
        DB      $1E,$3C,$0D,$3E,$0C,$08,$3C,$0D
        DB      $3C,$03,$12,$37,$22,$22,$1F,$06
        DB      $0D,$1D,$06,$2B,$11,$18,$29,$0D
        DB      $1C,$06,$0D,$0F,$06,$2B,$1E,$06
        DB      $0D,$3E

; German speech fragment $14 @ $C6F6
; Data = M-AW1-H-H-V-AH2-E1-T-A1-R-PAuse0-U1-U1-N-D-PAuse0 ...
; ... -D-U1-U1-F-Y-N-D-A1-S-T-M-Y-H-H-PAuse1
German_Speech_Fragment_14:  DB      $21             ; encoded SC-01 byte count
        DB      $3E,$0C,$13,$1B,$1B,$0F,$08,$3C
        DB      $2A,$06,$2B,$03,$37,$37,$0D,$1E
        DB      $03,$1E,$37,$37,$1D,$29,$0D,$1E
        DB      $06,$1F,$2A,$3E,$0C,$29,$1B,$1B
        DB      $3E

; German speech fragment $15 @ $C716
; Data = N-O2-O2-H-PAuse0-AH2-E1-N-P-AH1-R-PAuse0 ...
; ... -L-AH1-B-IU-IU-IU-I1-N-T-Y-Y-PAuse0-U1-U1-N-D-PAuse0 ...
; ... -D-U1-U1-B-Y-S-T-AH2-E1-N-PAuse0
German_Speech_Fragment_15:  DB      $28             ; encoded SC-01 byte count
        DB      $0D,$34,$34,$1B,$03,$08,$3C,$0D
        DB      $25,$15,$2B,$03,$18,$15,$0E,$36
        DB      $36,$36,$0B,$0D,$2A,$29,$29,$03
        DB      $37,$37,$0D,$1E,$03,$1E,$37,$37
        DB      $0E,$29,$1F,$2A,$08,$3C,$0D,$03

; German speech fragment $40 @ $C73F
; Data = W-vR-vR-L-O-R-D-PAuse1
German_Speech_Fragment_40:  DB      $08             ; encoded SC-01 byte count
        DB      $2D,$66,$6B,$18,$26,$2B,$1E,$3E

; German speech fragment $41 @ $C748
; Data = ^PAuse0-W-vR-vR-L-O-R-D-PAuse1-^PAuse0
German_Speech_Fragment_41:  DB      $0A             ; encoded SC-01 byte count
        DB      $83,$2D,$66,$6B,$18,$26,$2B,$1E
        DB      $3E,$83

; German speech fragment $16 @ $C753
; Data = SH-P-Y-Y-L-D-AW2-S-PAuse0-SH-P-Y-Y-L-PAuse0 ...
; ... -N-O1-H-H-AH2-E1-N-M-AH-L-PAuse1-D-AW1-N-N-V-Y-R-S-T-PAuse0 ...
; ... -SH-Y-Y-S-A1-N-PAuse0-B-A2-S-R-AY-PAuse0-S-AH-L-PAuse1
German_Speech_Fragment_16:  DB      $36             ; encoded SC-01 byte count
        DB      $11,$25,$29,$29,$18,$1E,$30,$1F
        DB      $03,$11,$25,$29,$29,$18,$03,$0D
        DB      $35,$1B,$1B,$08,$3C,$0D,$3E,$0C
        DB      $24,$18,$3E,$1E,$13,$0D,$0D,$0F
        DB      $29,$2B,$1F,$2A,$03,$11,$29,$29
        DB      $1F,$06,$0D,$03,$0E,$05,$1F,$2B
        DB      $21,$03,$1F,$24,$18,$3E

; German speech fragment $17 @ $C789
; Data = ^PAuse0-D-Y-Y-L-AH1-B-IU-IU-IU-R-I1-N-T-Y-Y-PAuse0 ...
; ... -F-O1-W-V-O1-O1-R-PAuse0-V-AW1-R-T-A1-N-UH-U1-F-F-PAuse0 ...
; ... -D-AH2-E1-N-E1-R-IU-Y1-K-PAuse0-K-A1-E1-R-PAuse1-^PAuse0
German_Speech_Fragment_17:  DB      $34             ; encoded SC-01 byte count
        DB      $83,$1E,$29,$29,$18,$15,$0E,$36
        DB      $36,$36,$2B,$0B,$0D,$2A,$29,$29
        DB      $03,$1D,$35,$2D,$0F,$35,$35,$2B
        DB      $03,$0F,$13,$2B,$2A,$06,$0D,$33
        DB      $37,$1D,$1D,$03,$1E,$08,$3C,$0D
        DB      $3C,$2B,$36,$22,$19,$03,$19,$06
        DB      $3C,$2B,$3E,$83

; German speech fragment $18 @ $C7BE
; Data = ^PAuse0-D-R-U1-N-T-A1-N-PAuse1 ...
; ... -Y-N-D-E1-N-H-O2-I3-I3-L-AY-N-F-O1-N-V-O1-O1-R-PAuse0 ...
; ... -V-Y-R-S-T-D-U1-U1-M-Y-H-H-PAuse0-T-R-A1-F-F-A1-N-PAuse1-^PAuse0
German_Speech_Fragment_18:  DB      $34             ; encoded SC-01 byte count
        DB      $83,$1E,$2B,$37,$0D,$2A,$06,$0D
        DB      $3E,$29,$0D,$1E,$3C,$0D,$1B,$34
        DB      $09,$09,$18,$21,$0D,$1D,$35,$0D
        DB      $0F,$35,$35,$2B,$03,$0F,$29,$2B
        DB      $1F,$2A,$1E,$37,$37,$3E,$0C,$29
        DB      $1B,$1B,$03,$2A,$2B,$06,$1D,$1D
        DB      $06,$0D,$3E,$83

; German speech fragment $19 @ $C7F2
; Data = D-A1-R
German_Speech_Fragment_19:  DB      $03             ; encoded SC-01 byte count
        DB      $1E,$06,$2B

; German speech fragment $53 @ $C7F6
; Data = B-E1-D-AH2-N-K-T-PAuse0-S-Y-H-H-PAuse1
German_Speech_Fragment_53:  DB      $0D             ; encoded SC-01 byte count
        DB      $0E,$3C,$1E,$08,$0D,$19,$2A,$03
        DB      $1F,$29,$1B,$1B,$3E

; German speech fragment $29 @ $C804
; Data = ^PAuse0-D-U1-U1-V-AH2-E1-S-T-PAuse0-G-E1-N-UH-U1-PAuse0 ...
; ... -D-AH2-S-PAuse0-D-U1-U1-PAuse0-A1-S-PAuse0-B-A1-S-A1-R-PAuse0 ...
; ... -K-AH2-AH2-N-S-T-PAuse1-^PAuse0
German_Speech_Fragment_29:  DB      $29             ; encoded SC-01 byte count
        DB      $83,$1E,$37,$37,$0F,$08,$3C,$1F
        DB      $2A,$03,$1C,$3C,$0D,$33,$37,$03
        DB      $1E,$08,$1F,$03,$1E,$37,$37,$03
        DB      $06,$1F,$03,$0E,$06,$1F,$06,$2B
        DB      $03,$19,$08,$08,$0D,$1F,$2A,$3E
        DB      $83

; German speech fragment $2A @ $C82E
; Data = K-O2-O2-M-M-PAuse0-S-U1-U1-R-IU-Y1-K-K-PAuse1 ...
; ... -R-AH2-AH2-H-H-AY-AY-PAuse0-Y-S-T-PAuse0-Z-U1-Y1-Y1-S-PAuse1
German_Speech_Fragment_2A:  DB      $23             ; encoded SC-01 byte count
        DB      $19,$34,$34,$3E,$0C,$3E,$0C,$03
        DB      $1F,$37,$37,$2B,$36,$22,$19,$19
        DB      $3E,$2B,$08,$08,$1B,$1B,$21,$21
        DB      $03,$29,$1F,$2A,$03,$12,$37,$22
        DB      $22,$1F,$3E

; German speech fragment $2B @ $C850
; Data = Y-H-H-PAuse0-G-R-AH2-E1-F-F-AY-PAuse0-AH2-AH2-N-PAuse0 ...
; ... -M-Y-T-T-PAuse0-G-E1-B-R-IU-Y1-L-PAuse1-^SH-M-AH2-E1-S-S-AY-PAuse0 ...
; ... -D-Y-H-H-PAuse0-J-A1-T-S-T-PAuse0-UH-U1-F-F-D-AY-N-PAuse0 ...
; ... -IU-Y1-L-PAuse1-^PAuse1
German_Speech_Fragment_2B:  DB      $3F             ; encoded SC-01 byte count
        DB      $29,$1B,$1B,$03,$1C,$2B,$08,$3C
        DB      $1D,$1D,$21,$03,$08,$08,$0D,$03
        DB      $3E,$0C,$29,$2A,$2A,$03,$1C,$3C
        DB      $0E,$2B,$36,$22,$18,$3E,$91,$3E
        DB      $0C,$08,$3C,$1F,$1F,$21,$03,$1E
        DB      $29,$1B,$1B,$03,$1A,$06,$2A,$1F
        DB      $2A,$03,$33,$37,$1D,$1D,$1E,$21
        DB      $0D,$03,$36,$22,$18,$3E,$BE

; German speech fragment $2C @ $C88E
; Data = H-Y-PAuse0-H-Y-PAuse0-H-O2-O2-PAuse0-H-O2-O2-PAuse0 ...
; ... -H-AH1-AH1-PAuse0-H-AH1-AH1-PAuse0-PAuse1 ...
; ... -D-AH2-AH2-S-M-AH2-AH2-H-H-T-PAuse0-SH-P-AH1-AH1-S-PAuse1
German_Speech_Fragment_2C:  DB      $29             ; encoded SC-01 byte count
        DB      $1B,$29,$03,$1B,$29,$03,$1B,$34
        DB      $34,$03,$1B,$34,$34,$03,$1B,$15
        DB      $15,$03,$1B,$15,$15,$03,$3E,$1E
        DB      $08,$08,$1F,$3E,$0C,$08,$08,$1B
        DB      $1B,$2A,$03,$11,$25,$15,$15,$1F
        DB      $3E

; German speech fragment $2D @ $C8B7
; Data = V-Y-L-K-vO2-vM-vM-A2-N-PAuse0 ...
; ... -Y-N-D-A1-R-V-A1-A2-L-T-T-F-O1-N-vW-vO1-O-R-PAuse1
German_Speech_Fragment_2D:  DB      $1F             ; encoded SC-01 byte count
        DB      $0F,$29,$18,$19,$74,$7E,$4C,$7E
        DB      $4C,$05,$0D,$03,$29,$0D,$1E,$06
        DB      $2B,$0F,$06,$05,$18,$2A,$2A,$1D
        DB      $35,$0D,$6D,$75,$26,$2B,$3E

; German speech fragment $2E @ $C8D5
; Data = M-AH2-H-H-D-E1-M-W-vI-vZ-ER-D-M-AH2-AH2-L-V-AH2-S-vV-O1-O1-R-PAuse1 ...
; ... -Z-AH2-M-L-E1-P-vU1-vNG-K-T-E1-PAuse0 ...
; ... -Y-N-D-A1-R-V-A1-L-T-F-O1-N-W-vR-O1-R-PAuse1
German_Speech_Fragment_2E:  DB      $39             ; encoded SC-01 byte count
        DB      $3E,$0C,$08,$1B,$1B,$1E,$3C,$3E
        DB      $0C,$2D,$67,$52,$3A,$1E,$3E,$0C
        DB      $08,$08,$18,$0F,$08,$1F,$4F,$35
        DB      $35,$2B,$3E,$12,$08,$3E,$0C,$18
        DB      $3C,$25,$77,$54,$19,$2A,$3C,$03
        DB      $29,$0D,$1E,$06,$2B,$0F,$06,$18
        DB      $2A,$1D,$35,$0D,$2D,$66,$35,$2B
        DB      $3E

; German speech fragment $2F @ $C90B
; Data = G-vL-vAH2-vE1-H-H-^Z-Y-Y-S-T-T-D-W-D-A1-N-^W-I-Z-ER-D-PAuse1 ...
; ... -D-A1-N-M-UH-G-Y-SH-A1-N-^W-I-Z-ER-D-^F-O1-N-W-O1-O-R-PAuse1-PAuse1
German_Speech_Fragment_2F:  DB      $30             ; encoded SC-01 byte count
        DB      $1C,$58,$48,$7C,$1B,$1B,$92,$29
        DB      $29,$1F,$2A,$2A,$1E,$2D,$1E,$06
        DB      $0D,$AD,$27,$12,$3A,$1E,$3E,$1E
        DB      $06,$0D,$3E,$0C,$33,$1C,$29,$11
        DB      $06,$0D,$AD,$27,$12,$3A,$1E,$9D
        DB      $35,$0D,$2D,$35,$26,$2B,$3E,$3E

; German speech fragment $30 @ $C93B
; Data = ^PAuse0-Z-AH2-E1-T-M-O2-O2-N-AW2-T-A1-N-PAuse0 ...
; ... -H-AW2-T-T-B-ER-R-W-O-R-N-Y-M-AW2-N-D-A1-N-F-A1-R-N-AH1-SH-T-PAuse1 ...
; ... -^PAuse0
German_Speech_Fragment_30:  DB      $2B             ; encoded SC-01 byte count
        DB      $83,$12,$08,$3C,$2A,$3E,$0C,$34
        DB      $34,$0D,$30,$2A,$06,$0D,$03,$1B
        DB      $30,$2A,$2A,$0E,$3A,$2B,$2D,$26
        DB      $2B,$0D,$29,$3E,$0C,$30,$0D,$1E
        DB      $06,$0D,$1D,$06,$2B,$0D,$15,$11
        DB      $2A,$3E,$83

; German speech fragment $31 @ $C965
; Data = M-AH2-E1-N-E1-K-Y-N-D-E1-R-PAuse1-SH-P-AH2-E1-PAuse0-A1-N-PAuse0 ...
; ... -F-F-O2-O2-I3-I3-PAuse0-A1-R-PAuse1
German_Speech_Fragment_31:  DB      $1F             ; encoded SC-01 byte count
        DB      $3E,$0C,$08,$3C,$0D,$3C,$19,$29
        DB      $0D,$1E,$3C,$2B,$3E,$11,$25,$08
        DB      $3C,$03,$06,$0D,$03,$1D,$1D,$34
        DB      $34,$09,$09,$03,$06,$2B,$3E

; German speech fragment $32 @ $C984
; Data = ^PAuse0-M-Y-T-M-AH2-E1-N-A1-R-L-Y-H-H-T-K-AW1-N-O2-O2-O2-N-E1 ...
; ... -PAuse0-F-A1-R-B-R-I2-I2-N-N-PAuse0-N-E1-PAuse0 ...
; ... -Y-H-H-PAuse0-D-Y-H-H-PAuse1-^PAuse0
German_Speech_Fragment_32:  DB      $31             ; encoded SC-01 byte count
        DB      $83,$3E,$0C,$29,$2A,$3E,$0C,$08
        DB      $3C,$0D,$06,$2B,$18,$29,$1B,$1B
        DB      $2A,$19,$13,$0D,$34,$34,$34,$0D
        DB      $3C,$03,$1D,$06,$2B,$0E,$2B,$0A
        DB      $0A,$0D,$0D,$03,$0D,$3C,$03,$29
        DB      $1B,$1B,$03,$1E,$29,$1B,$1B,$3E
        DB      $83

; German speech fragment $28 @ $C9B4
; Data = ^PAuse0-G-AH1-R-W-O-R-U1-U1-N-D-TH-O-R-W-O-R-PAuse1-M-AW1-H-H-T ...
; ... -PAuse0-O2-O2-I3-I3-H-H-PAuse0-U1-U1-N-Z-Y-H-T-B-AW1-R-PAuse1-^PAuse0
German_Speech_Fragment_28:  DB      $2B             ; encoded SC-01 byte count
        DB      $83,$1C,$15,$2B,$2D,$26,$2B,$37
        DB      $37,$0D,$1E,$39,$26,$2B,$2D,$26
        DB      $2B,$3E,$0C,$13,$1B,$1B,$2A,$03
        DB      $34,$34,$09,$09,$1B,$1B,$03,$37
        DB      $37,$0D,$12,$29,$1B,$2A,$0E,$13
        DB      $2B,$3E,$83

; German speech fragment $33 @ $C9E0
; Data = ^PAuse0-TH-O-R-W-O-R-PAuse1-Y-S-T-B-L-U1-U1-T-R-O-O-T-PAuse0 ...
; ... -G-A1-M-M-AH2-E1-N-N-U1-U1-N-D-H-U1-U1-NG-G-R-Y-G-AW1-U1-F ...
; ... -K-R-AW1-F-T-N-AW1-R-W-NG-PAuse1-^PAuse0
German_Speech_Fragment_33:  DB      $3A             ; encoded SC-01 byte count
        DB      $83,$39,$26,$2B,$2D,$26,$2B,$3E
        DB      $29,$1F,$2A,$0E,$18,$37,$37,$2A
        DB      $2B,$26,$26,$2A,$03,$1C,$06,$3E
        DB      $0C,$3E,$0C,$08,$3C,$0D,$0D,$37
        DB      $37,$0D,$1E,$1B,$37,$37,$14,$1C
        DB      $2B,$29,$1C,$13,$37,$1D,$19,$2B
        DB      $13,$1D,$2A,$0D,$13,$2B,$2D,$14
        DB      $3E,$83

; German speech fragment $34 @ $CA19
; Data = Z-Y-Y-PAuse0-G-E1-N-UH-U1-H-A1-R-PAuse0 ...
; ... -AW1-L-T-A1-R-SH-P-A2-A1-PAuse0-H-A1-R-PAuse0-D-A1-N-N-Y ...
; ... -H-H-K-O2-O2-M-M-E1-PAuse0-Y-M-M-E1-R-N-A2-A2-PAuse0-H-A1-R-PAuse1
German_Speech_Fragment_34:  DB      $3A             ; encoded SC-01 byte count
        DB      $12,$29,$29,$03,$1C,$3C,$0D,$33
        DB      $37,$1B,$06,$2B,$03,$13,$18,$2A
        DB      $06,$2B,$11,$25,$05,$06,$03,$1B
        DB      $06,$2B,$03,$1E,$06,$0D,$0D,$29
        DB      $1B,$1B,$19,$34,$34,$3E,$0C,$3E
        DB      $0C,$3C,$03,$29,$3E,$0C,$3E,$0C
        DB      $3C,$2B,$0D,$05,$05,$03,$1B,$06
        DB      $2B,$3E

; German speech fragment $37 @ $CA50; runtime substitutes $41 when Dungeon_Class ($D350) != 0
; Data = ^W-O-R-Y-ER-PAuse1-^PAuse0
German_Speech_Fragment_37:  DB      $07             ; encoded SC-01 byte count
        DB      $AD,$26,$2B,$29,$3A,$3E,$83

; German speech fragment $38 @ $CA58
; Data = D-A1-R
German_Speech_Fragment_38:  DB      $03             ; encoded SC-01 byte count
        DB      $1E,$06,$2B

; German speech fragment $52 @ $CA5C
; Data = H-AH1-T-PAuse0-D-Y-H-H-PAuse0-G-E1-G-R-Y-L-T-T-PAuse1
German_Speech_Fragment_52:  DB      $12             ; encoded SC-01 byte count
        DB      $1B,$15,$2A,$03,$1E,$29,$1B,$1B
        DB      $03,$1C,$3C,$1C,$2B,$29,$18,$2A
        DB      $2A,$3E

; German speech fragment $39 @ $CA6F
; Data = ^PAuse0-D-AW1-S-S-PAuse0-V-T-R-UH-L-A1-N-SH-V-A1-R-T-PAuse0 ...
; ... -K-Y-T-S-A1-L-T-PAuse1-^PAuse0
German_Speech_Fragment_39:  DB      $1C             ; encoded SC-01 byte count
        DB      $83,$1E,$13,$1F,$1F,$03,$0F,$2A
        DB      $2B,$33,$18,$06,$0D,$11,$0F,$06
        DB      $2B,$2A,$03,$19,$29,$2A,$1F,$06
        DB      $18,$2A,$3E,$83

; German speech fragment $3A @ $CA8C
; Data = V-Y-Y-PAuse0-SH-M-AE1-K-T-PAuse0-D-Y-Y-PAuse0 ...
; ... -S-T-R-AW1-L-M-N-K-AW1-N-O2-O2-O2-N-E1-PAuse1
German_Speech_Fragment_3A:  DB      $20             ; encoded SC-01 byte count
        DB      $0F,$29,$29,$03,$11,$3E,$0C,$2F
        DB      $19,$2A,$03,$1E,$29,$29,$03,$1F
        DB      $2A,$2B,$13,$18,$3E,$0C,$0D,$19
        DB      $13,$0D,$34,$34,$34,$0D,$3C,$3E

; German speech fragment $3B @ $CAAB
; Data = ^PAuse0-M-AH2-E1-N-PAuse0-T-E1-L-E1-PAuse0 ...
; ... -T-R-AH2-N-S-P-O1-O1-R-T-PAuse0-V-Y-R-D-N-O1-H-H-PAuse0 ...
; ... -SH-N-A1-L-A1-R-PAuse1-^PAuse0
German_Speech_Fragment_3B:  DB      $28             ; encoded SC-01 byte count
        DB      $83,$3E,$0C,$08,$3C,$0D,$03,$2A
        DB      $3C,$18,$3C,$03,$2A,$2B,$08,$0D
        DB      $1F,$25,$35,$35,$2B,$2A,$03,$0F
        DB      $29,$2B,$1E,$0D,$35,$1B,$1B,$03
        DB      $11,$0D,$06,$18,$06,$2B,$3E,$83

; German speech fragment $3C @ $CAD3
; Data = ^PAuse0-N-U1-U1-N-PAuse0-K-AY-AY-N-S-T-PAuse0 ...
; ... -D-U1-U1-D-AY-AY-N-PAuse0-G-E1-SH-M-AH2-K-K-PAuse1 ...
; ... -M-AH2-E1-N-E1-S-PAuse0-S-UH-U1-B-AY-R-S-PAuse1-^PAuse0
German_Speech_Fragment_3C:  DB      $2E             ; encoded SC-01 byte count
        DB      $83,$0D,$37,$37,$0D,$03,$19,$21
        DB      $21,$0D,$1F,$2A,$03,$1E,$37,$37
        DB      $1E,$21,$21,$0D,$03,$1C,$3C,$11
        DB      $3E,$0C,$08,$19,$19,$3E,$0C,$08
        DB      $3C,$0D,$3C,$1F,$03,$1F,$33,$37
        DB      $0E,$21,$2B,$1F,$3E,$83

; German speech fragment $3D @ $CB01
; Data = AH2-E1-N-AY-S-T-AW1-G-AY-S-PAuse0 ...
; ... -T-R-A2-F-F-A1-N-V-Y-R-U1-N-S-PAuse0-V-Y-Y-D-A1-R-PAuse1
German_Speech_Fragment_3D:  DB      $20             ; encoded SC-01 byte count
        DB      $08,$3C,$0D,$21,$1F,$2A,$13,$1C
        DB      $21,$1F,$03,$2A,$2B,$05,$1D,$1D
        DB      $06,$0D,$0F,$29,$2B,$37,$0D,$1F
        DB      $03,$0F,$29,$29,$1E,$06,$2B,$3E

; German speech fragment $3E @ $CB22
; Data = D-AH2-E1-N-E1-PAuse0-I2-K-S-P-L-O2-O2-Z-Y-O2-O2-N-PAuse0 ...
; ... -Y-S-T-M-U1-U1-Z-Y-Y-K-PAuse0-F-IU-IU-IU-R-M-AH2-E1-N-E1-PAuse0 ...
; ... -O-O-R-AY-N-PAuse1
German_Speech_Fragment_3E:  DB      $31             ; encoded SC-01 byte count
        DB      $1E,$08,$3C,$0D,$3C,$03,$0A,$19
        DB      $1F,$25,$18,$34,$34,$12,$29,$34
        DB      $34,$0D,$03,$29,$1F,$2A,$3E,$0C
        DB      $37,$37,$12,$29,$29,$19,$03,$1D
        DB      $36,$36,$36,$2B,$3E,$0C,$08,$3C
        DB      $0D,$3C,$03,$26,$26,$2B,$21,$0D
        DB      $3E

; German speech fragment $3F @ $CB52
; Data = Y-Y-H-H-PAuse0-Z-AW1-G-S-PAuse0-N-O1-H-H-M-AW1-L-PAuse1
German_Speech_Fragment_3F:  DB      $13             ; encoded SC-01 byte count
        DB      $29,$29,$1B,$1B,$03,$12,$13,$1C
        DB      $1F,$03,$0D,$35,$1B,$1B,$3E,$0C
        DB      $13,$18,$3E

; German speech fragment $42 @ $CB65
; Data = ^PAuse0-Z-AH2-E1-PAuse0-G-A1-V-AW1-R-N-T-T-PAuse0 ...
; ... -V-O1-O1-R-L-O2-O2-ER-D-PAuse1-D-U1-U1-N-A2-A2-PAuse0 ...
; ... -H-AE1-R-S-T-D-Y-H-H-D-E1-M-F-A1-R-L-Y-Y-S-PAuse1-^PAuse0
German_Speech_Fragment_42:  DB      $35             ; encoded SC-01 byte count
        DB      $83,$12,$08,$3C,$03,$1C,$06,$0F
        DB      $13,$2B,$0D,$2A,$2A,$03,$0F,$35
        DB      $35,$2B,$18,$34,$34,$3A,$1E,$3E
        DB      $1E,$37,$37,$0D,$05,$05,$03,$1B
        DB      $2F,$2B,$1F,$2A,$1E,$29,$1B,$1B
        DB      $1E,$3C,$3E,$0C,$1D,$06,$2B,$18
        DB      $29,$29,$1F,$3E,$83

; German speech fragment $43 @ $CB9A
; Data = ^PAuse0-D-AH2-E1-N-V-AY-AY-G-F-IU-Y1-R-T-PAuse0 ...
; ... -D-Y-R-A1-K-T-Y-N-S-F-A1-R-L-Y-Y-S-PAuse1-^PAuse0
German_Speech_Fragment_43:  DB      $21             ; encoded SC-01 byte count
        DB      $83,$1E,$08,$3C,$0D,$0F,$21,$21
        DB      $1C,$1D,$36,$22,$2B,$2A,$03,$1E
        DB      $29,$2B,$06,$19,$2A,$29,$0D,$1F
        DB      $1D,$06,$2B,$18,$29,$29,$1F,$3E
        DB      $83

; German speech fragment $44 @ $CBBC
; Data = ^PAuse0-T-Y-Y-F-A1-R-PAuse0-Y-M-M-A1-R-T-Y-Y-F-A1-R-PAuse0 ...
; ... -Y-N-D-Y-Y-PAuse0-L-AH1-B-IU-IU-IU-I1-N-T-F-O1-N-W-O-R-PAuse1-^PAuse0
German_Speech_Fragment_44:  DB      $2D             ; encoded SC-01 byte count
        DB      $83,$2A,$29,$29,$1D,$06,$2B,$03
        DB      $29,$3E,$0C,$3E,$0C,$06,$2B,$2A
        DB      $29,$29,$1D,$06,$2B,$03,$29,$0D
        DB      $1E,$29,$29,$03,$18,$15,$0E,$36
        DB      $36,$36,$0B,$0D,$2A,$1D,$35,$0D
        DB      $2D,$26,$2B,$3E,$83

; German speech fragment $45 @ $CBE8
; Data = ^PAuse0-P-AH1-S-S-PAuse0-UH-U1-U1-F-F-PAuse1 ...
; ... -D-U1-U1-B-Y-S-T-Y-N-D-A1-N-PAuse0 ...
; ... -H-O2-I3-I3-L-A1-N-F-O1-N-V-O1-O1-R-PAuse1-^PAuse0
German_Speech_Fragment_45:  DB      $29             ; encoded SC-01 byte count
        DB      $83,$25,$15,$1F,$1F,$03,$33,$37
        DB      $37,$1D,$1D,$3E,$1E,$37,$37,$0E
        DB      $29,$1F,$2A,$29,$0D,$1E,$06,$0D
        DB      $03,$1B,$34,$09,$09,$18,$06,$0D
        DB      $1D,$35,$0D,$0F,$35,$35,$2B,$3E
        DB      $83

; German speech fragment $46 @ $CC12
; Data = ^PAuse0-AH-H-PAuse1-D-U1-U1-V-Y-L-L-S-T-D-Y-H-H-V-O2-O2-L-PAuse0 ...
; ... -F-A1-R-S-T-AE1-K-K-A1-N-PAuse1-AH-B-A1-R-PAuse0 ...
; ... -Y-H-H-B-Y-N-D-A1-R-PAuse0 ...
; ... -H-O2-I3-I3-L-A1-N-M-AH2-E1-S-T-A1-R-PAuse1-^PAuse0
German_Speech_Fragment_46:  DB      $41             ; encoded SC-01 byte count
        DB      $83,$24,$1B,$3E,$1E,$37,$37,$0F
        DB      $29,$18,$18,$1F,$2A,$1E,$29,$1B
        DB      $1B,$0F,$34,$34,$18,$03,$1D,$06
        DB      $2B,$1F,$2A,$2F,$19,$19,$06,$0D
        DB      $3E,$24,$0E,$06,$2B,$03,$29,$1B
        DB      $1B,$0E,$29,$0D,$1E,$06,$2B,$03
        DB      $1B,$34,$09,$09,$18,$06,$0D,$3E
        DB      $0C,$08,$3C,$1F,$2A,$06,$2B,$3E
        DB      $83

; German speech fragment $47 @ $CC53
; Data = ^PAuse0-TH-O-O1-R-PAuse0-B-ER-R-PAuse0-G-AH-R-PAuse1 ...
; ... -A2-S-S-A1-N-Y-S-T-F-A1-R-T-Y-G-PAuse1-^PAuse0
German_Speech_Fragment_47:  DB      $1E             ; encoded SC-01 byte count
        DB      $83,$39,$26,$35,$2B,$03,$0E,$3A
        DB      $2B,$03,$1C,$24,$2B,$3E,$05,$1F
        DB      $1F,$06,$0D,$29,$1F,$2A,$1D,$06
        DB      $2B,$2A,$29,$1C,$3E,$83

; German speech fragment $48 @ $CC72
; Data = H-vA-vI1-vY1-PAuse1-PAuse1 ...
; ... -S-Y-Y-T-D-Y-Y-Z-Y-Y-B-A1-N-M-AH2-E1-L-A1-N-PAuse0 ...
; ... -SH-T-Y-Y-F-AY-L-PAuse0-AW1-N-N-PAuse1
German_Speech_Fragment_48:  DB      $27             ; encoded SC-01 byte count
        DB      $1B,$60,$4B,$62,$3E,$3E,$1F,$29
        DB      $29,$2A,$1E,$29,$29,$12,$29,$29
        DB      $0E,$06,$0D,$3E,$0C,$08,$3C,$18
        DB      $06,$0D,$03,$11,$2A,$29,$29,$1D
        DB      $21,$18,$03,$13,$0D,$0D,$3E

; German speech fragment $49 @ $CC99
; Data = ^PAuse0-M-AH2-E1-N-E1-B-Y-Y-S-T-A1-R-PAuse0 ...
; ... -R-A1-N-N-A1-N-V-Y-Y-V-Y-L-D-PAuse0 ...
; ... -D-U1-U1-R-H-D-Y-Y-H-O2-I3-I3-L-AY-N-D-A1-S ...
; ... -V-O2-O1-O1-R-L-O1-R-D-S-PAuse1-^PAuse0
German_Speech_Fragment_49:  DB      $3B             ; encoded SC-01 byte count
        DB      $83,$3E,$0C,$08,$3C,$0D,$3C,$0E
        DB      $29,$29,$1F,$2A,$06,$2B,$03,$2B
        DB      $06,$0D,$0D,$06,$0D,$0F,$29,$29
        DB      $0F,$29,$18,$1E,$03,$1E,$37,$37
        DB      $2B,$1B,$1E,$29,$29,$1B,$34,$09
        DB      $09,$18,$21,$0D,$1E,$06,$1F,$0F
        DB      $34,$35,$35,$2B,$18,$35,$2B,$1E
        DB      $1F,$3E,$83

; German speech fragment $4A @ $CCD4
; Data = D-Y-Y-R-B-L-AH2-E1-B-T-T-PAuse0 ...
; ... -K-AH2-E1-N-E1-AH2-AH2-N-D-R-AY-PAuse0-V-AH-L-PAuse1 ...
; ... -^T-AH2-AH2-N-S-AY-PAuse0-O-D-A1-R-PAuse0-L-AH2-E1-D-AY-PAuse0 ...
; ... -K-V-V-AH-L-PAuse1-^PAuse0
German_Speech_Fragment_4A:  DB      $35             ; encoded SC-01 byte count
        DB      $1E,$29,$29,$2B,$0E,$18,$08,$3C
        DB      $0E,$2A,$2A,$03,$19,$08,$3C,$0D
        DB      $3C,$08,$08,$0D,$1E,$2B,$21,$03
        DB      $0F,$24,$18,$3E,$AA,$08,$08,$0D
        DB      $1F,$21,$03,$26,$1E,$06,$2B,$03
        DB      $18,$08,$3C,$1E,$21,$03,$19,$0F
        DB      $0F,$24,$18,$3E,$83

; German speech fragment $4B @ $CD0A
; Data = ^PAuse0-N-U1-N-M-U1-U1-S-^T-D-U1-U1-D-AH2-E1-N-PAuse0 ...
; ... -B-A2-S-T-AY-S-^PAuse0-G-AY-AY-B-A1-N-PAuse1-Z-O1-N-S-T-PAuse0 ...
; ... -V-Y-R-S-T-^D-U1-U1-N-Y-H-H-T-PAuse0 ...
; ... -IU-Y1-B-A1-R-^L-AY-AY-B-A1-N-PAuse1-PAuse0
German_Speech_Fragment_4B:  DB      $41             ; encoded SC-01 byte count
        DB      $83,$0D,$37,$0D,$3E,$0C,$37,$37
        DB      $1F,$AA,$1E,$37,$37,$1E,$08,$3C
        DB      $0D,$03,$0E,$05,$1F,$2A,$21,$1F
        DB      $83,$1C,$21,$21,$0E,$06,$0D,$3E
        DB      $12,$35,$0D,$1F,$2A,$03,$0F,$29
        DB      $2B,$1F,$2A,$9E,$37,$37,$0D,$29
        DB      $1B,$1B,$2A,$03,$36,$22,$0E,$06
        DB      $2B,$98,$21,$21,$0E,$06,$0D,$3E
        DB      $03

; German speech fragment $4C @ $CD4B
; Data = H-O1-P-L-AW1-PAuse1-PAuse1-Y-H-H-PAuse0 ...
; ... -H-AW1-B-AY-D-Y-V-AE1-N-D-AY-PAuse0-F-A1-R-G-AY-S-A1-N-PAuse1
German_Speech_Fragment_4C:  DB      $20             ; encoded SC-01 byte count
        DB      $1B,$35,$25,$18,$13,$3E,$3E,$29
        DB      $1B,$1B,$03,$1B,$13,$0E,$21,$1E
        DB      $29,$0F,$2F,$0D,$1E,$21,$03,$1D
        DB      $06,$2B,$1C,$21,$1F,$06,$0D,$3E

; German speech fragment $4D @ $CD6C
; Data = ^PAuse0-V-O-O-PAuse0-S-Y-L-S-T-PAuse0-D-U1-U1-D-Y-H-H-PAuse0 ...
; ... -F-A1-R-S-T-T-AE1-K-K-A1-N-PAuse1-^PAuse0
German_Speech_Fragment_4D:  DB      $20             ; encoded SC-01 byte count
        DB      $83,$0F,$26,$26,$03,$1F,$29,$18
        DB      $1F,$2A,$03,$1E,$37,$37,$1E,$29
        DB      $1B,$1B,$03,$1D,$06,$2B,$1F,$2A
        DB      $2A,$2F,$19,$19,$06,$0D,$3E,$83
; End of German speech fragment records.


;==============================================================================
; GERMAN SPEECH FRAGMENT POINTER TABLE - 84 entries ($00-$53)
;
; Queue_Speech_Request doubles a fragment index and uses it to read one
; little-endian pointer from this table. German exposes 84 addressable slots
; ($00-$53); slot $4F is null, leaving 83 populated fragment records. English
; exposes 79 populated slots ($00-$4E). Phrase records remain compatible because
; they carry language-local fragment indexes.
;==============================================================================
German_Speech_Fragment_Pointers:
        DW      German_Speech_Fragment_00            ; fragment $00
        DW      German_Speech_Fragment_01            ; fragment $01
        DW      German_Speech_Fragment_02            ; fragment $02
        DW      German_Speech_Fragment_03            ; fragment $03
        DW      German_Speech_Fragment_04            ; fragment $04
        DW      German_Speech_Fragment_05            ; fragment $05
        DW      German_Speech_Fragment_06            ; fragment $06
        DW      German_Speech_Fragment_07            ; fragment $07
        DW      German_Speech_Fragment_08            ; fragment $08
        DW      German_Speech_Fragment_09            ; fragment $09
        DW      German_Speech_Fragment_0A            ; fragment $0A
        DW      German_Speech_Fragment_0B            ; fragment $0B
        DW      German_Speech_Fragment_0C            ; fragment $0C
        DW      German_Speech_Fragment_0D            ; fragment $0D
        DW      German_Speech_Fragment_0E            ; fragment $0E
        DW      German_Speech_Fragment_0F            ; fragment $0F
        DW      German_Speech_Fragment_10            ; fragment $10
        DW      German_Speech_Fragment_11            ; fragment $11
        DW      German_Speech_Fragment_12            ; fragment $12
        DW      German_Speech_Fragment_13            ; fragment $13
        DW      German_Speech_Fragment_14            ; fragment $14
        DW      German_Speech_Fragment_15            ; fragment $15
        DW      German_Speech_Fragment_16            ; fragment $16
        DW      German_Speech_Fragment_17            ; fragment $17
        DW      German_Speech_Fragment_18            ; fragment $18
        DW      German_Speech_Fragment_19            ; fragment $19
        DW      German_Speech_Fragment_1A            ; fragment $1A
        DW      German_Speech_Fragment_1B            ; fragment $1B
        DW      German_Speech_Fragment_1C            ; fragment $1C
        DW      German_Speech_Fragment_1D            ; fragment $1D
        DW      German_Speech_Fragment_1E            ; fragment $1E
        DW      German_Speech_Fragment_1F            ; fragment $1F
        DW      German_Speech_Fragment_20            ; fragment $20
        DW      German_Speech_Fragment_21            ; fragment $21
        DW      German_Speech_Fragment_22            ; fragment $22
        DW      German_Speech_Fragment_23            ; fragment $23
        DW      German_Speech_Fragment_24            ; fragment $24
        DW      German_Speech_Fragment_25            ; fragment $25
        DW      German_Speech_Fragment_26            ; fragment $26
        DW      German_Speech_Fragment_27            ; fragment $27
        DW      German_Speech_Fragment_28            ; fragment $28
        DW      German_Speech_Fragment_29            ; fragment $29
        DW      German_Speech_Fragment_2A            ; fragment $2A
        DW      German_Speech_Fragment_2B            ; fragment $2B
        DW      German_Speech_Fragment_2C            ; fragment $2C
        DW      German_Speech_Fragment_2D            ; fragment $2D
        DW      German_Speech_Fragment_2E            ; fragment $2E
        DW      German_Speech_Fragment_2F            ; fragment $2F
        DW      German_Speech_Fragment_30            ; fragment $30
        DW      German_Speech_Fragment_31            ; fragment $31
        DW      German_Speech_Fragment_32            ; fragment $32
        DW      German_Speech_Fragment_33            ; fragment $33
        DW      German_Speech_Fragment_34            ; fragment $34
        DW      German_Speech_Fragment_35            ; fragment $35
        DW      German_Speech_Fragment_36            ; fragment $36
        DW      German_Speech_Fragment_37            ; fragment $37
        DW      German_Speech_Fragment_38            ; fragment $38
        DW      German_Speech_Fragment_39            ; fragment $39
        DW      German_Speech_Fragment_3A            ; fragment $3A
        DW      German_Speech_Fragment_3B            ; fragment $3B
        DW      German_Speech_Fragment_3C            ; fragment $3C
        DW      German_Speech_Fragment_3D            ; fragment $3D
        DW      German_Speech_Fragment_3E            ; fragment $3E
        DW      German_Speech_Fragment_3F            ; fragment $3F
        DW      German_Speech_Fragment_40            ; fragment $40
        DW      German_Speech_Fragment_41            ; fragment $41
        DW      German_Speech_Fragment_42            ; fragment $42
        DW      German_Speech_Fragment_43            ; fragment $43
        DW      German_Speech_Fragment_44            ; fragment $44
        DW      German_Speech_Fragment_45            ; fragment $45
        DW      German_Speech_Fragment_46            ; fragment $46
        DW      German_Speech_Fragment_47            ; fragment $47
        DW      German_Speech_Fragment_48            ; fragment $48
        DW      German_Speech_Fragment_49            ; fragment $49
        DW      German_Speech_Fragment_4A            ; fragment $4A
        DW      German_Speech_Fragment_4B            ; fragment $4B
        DW      German_Speech_Fragment_4C            ; fragment $4C
        DW      German_Speech_Fragment_4D            ; fragment $4D
        DW      German_Speech_Fragment_4E            ; fragment $4E
        DW      $0000            ; fragment $4F ; null/unused pointer
        DW      German_Speech_Fragment_50            ; fragment $50
        DW      German_Speech_Fragment_51            ; fragment $51
        DW      German_Speech_Fragment_52            ; fragment $52
        DW      German_Speech_Fragment_53            ; fragment $53

;==============================================================================
; GERMAN SPEECH PHRASE TABLE - 80 phrase IDs ($00-$4F)
;
; Record format:
;     DB $80 + fragment_count, fragment_index[, fragment_index ...]
;
; The main program scans marker bytes $81-$84 to locate the requested phrase,
; masks bit 7, then queues the listed fragments in order. German may use a
; different fragment count and different fragment indexes than English while
; preserving the same language-independent phrase ID. See doc/SPEECH_MAP.md
; for the complete English/German phrase map and reconstructed phrase text.
;==============================================================================
German_Speech_Phrase_Table:
        DB      $81,$0A              ; phrase $00: 1 fragment ($0A)
        DB      $82,$0B,$04          ; phrase $01: 2 fragments ($0B $04)
        DB      $81,$0A              ; phrase $02: 1 fragment ($0A)
        DB      $82,$0C,$10          ; phrase $03: 2 fragments ($0C $10)
        DB      $81,$0A              ; phrase $04: 1 fragment ($0A)
        DB      $82,$0B,$04          ; phrase $05: 2 fragments ($0B $04)
        DB      $81,$0A              ; phrase $06: 1 fragment ($0A)
        DB      $82,$0C,$10          ; phrase $07: 2 fragments ($0C $10)
        DB      $82,$0D,$09          ; phrase $08: 2 fragments ($0D $09)
        DB      $81,$0E              ; phrase $09: 1 fragment ($0E)
        DB      $81,$0F              ; phrase $0A: 1 fragment ($0F)
        DB      $82,$11,$10          ; phrase $0B: 2 fragments ($11 $10)
        DB      $82,$1E,$36          ; phrase $0C: 2 fragments ($1E $36)
        DB      $81,$2D              ; phrase $0D: 1 fragment ($2D)
        DB      $82,$2E,$10          ; phrase $0E: 2 fragments ($2E $10)
        DB      $82,$2F,$10          ; phrase $0F: 2 fragments ($2F $10)
        DB      $81,$00              ; phrase $10: 1 fragment ($00)
        DB      $83,$4E,$02,$50      ; phrase $11: 3 fragments ($4E $02 $50)
        DB      $82,$03,$04          ; phrase $12: 2 fragments ($03 $04)
        DB      $82,$05,$10          ; phrase $13: 2 fragments ($05 $10)
        DB      $81,$06              ; phrase $14: 1 fragment ($06)
        DB      $81,$07              ; phrase $15: 1 fragment ($07)
        DB      $82,$08,$37          ; phrase $16: 2 fragments ($08 $37)
        DB      $82,$33,$36          ; phrase $17: 2 fragments ($33 $36)
        DB      $81,$23              ; phrase $18: 1 fragment ($23)
        DB      $82,$24,$36          ; phrase $19: 2 fragments ($24 $36)
        DB      $82,$27,$36          ; phrase $1A: 2 fragments ($27 $36)
        DB      $82,$25,$36          ; phrase $1B: 2 fragments ($25 $36)
        DB      $82,$30,$36          ; phrase $1C: 2 fragments ($30 $36)
        DB      $82,$31,$09          ; phrase $1D: 2 fragments ($31 $09)
        DB      $81,$32              ; phrase $1E: 1 fragment ($32)
        DB      $81,$1D              ; phrase $1F: 1 fragment ($1D)
        DB      $82,$12,$36          ; phrase $20: 2 fragments ($12 $36)
        DB      $81,$13              ; phrase $21: 1 fragment ($13)
        DB      $81,$14              ; phrase $22: 1 fragment ($14)
        DB      $82,$15,$40          ; phrase $23: 2 fragments ($15 $40)
        DB      $82,$37,$26          ; phrase $24: 2 fragments ($37 $26)
        DB      $82,$34,$10          ; phrase $25: 2 fragments ($34 $10)
        DB      $83,$09,$22,$10      ; phrase $26: 3 fragments ($09 $22 $10)
        DB      $82,$35,$37          ; phrase $27: 2 fragments ($35 $37)
        DB      $82,$1A,$36          ; phrase $28: 2 fragments ($1A $36)
        DB      $81,$1B              ; phrase $29: 1 fragment ($1B)
        DB      $82,$1C,$36          ; phrase $2A: 2 fragments ($1C $36)
        DB      $82,$01,$36          ; phrase $2B: 2 fragments ($01 $36)
        DB      $82,$1F,$09          ; phrase $2C: 2 fragments ($1F $09)
        DB      $82,$09,$20          ; phrase $2D: 2 fragments ($09 $20)
        DB      $84,$21,$02,$51,$36  ; phrase $2E: 4 fragments ($21 $02 $51 $36)
        DB      $82,$28,$36          ; phrase $2F: 2 fragments ($28 $36)
        DB      $82,$16,$10          ; phrase $30: 2 fragments ($16 $10)
        DB      $82,$17,$37          ; phrase $31: 2 fragments ($17 $37)
        DB      $82,$18,$37          ; phrase $32: 2 fragments ($18 $37)
        DB      $83,$19,$04,$53      ; phrase $33: 3 fragments ($19 $04 $53)
        DB      $82,$29,$37          ; phrase $34: 2 fragments ($29 $37)
        DB      $81,$2A              ; phrase $35: 1 fragment ($2A)
        DB      $82,$2B,$36          ; phrase $36: 2 fragments ($2B $36)
        DB      $81,$2C              ; phrase $37: 1 fragment ($2C)
        DB      $84,$38,$04,$52,$10  ; phrase $38: 4 fragments ($38 $04 $52 $10)
        DB      $83,$39,$37,$36      ; phrase $39: 3 fragments ($39 $37 $36)
        DB      $82,$3A,$10          ; phrase $3A: 2 fragments ($3A $10)
        DB      $82,$3B,$36          ; phrase $3B: 2 fragments ($3B $36)
        DB      $82,$3C,$37          ; phrase $3C: 2 fragments ($3C $37)
        DB      $81,$3D              ; phrase $3D: 1 fragment ($3D)
        DB      $82,$3E,$10          ; phrase $3E: 2 fragments ($3E $10)
        DB      $83,$3F,$34,$10      ; phrase $3F: 3 fragments ($3F $34 $10)
        DB      $82,$42,$36          ; phrase $40: 2 fragments ($42 $36)
        DB      $83,$41,$43,$36      ; phrase $41: 3 fragments ($41 $43 $36)
        DB      $82,$44,$36          ; phrase $42: 2 fragments ($44 $36)
        DB      $81,$45              ; phrase $43: 1 fragment ($45)
        DB      $82,$46,$36          ; phrase $44: 2 fragments ($46 $36)
        DB      $82,$47,$36          ; phrase $45: 2 fragments ($47 $36)
        DB      $82,$48,$10          ; phrase $46: 2 fragments ($48 $10)
        DB      $82,$49,$36          ; phrase $47: 2 fragments ($49 $36)
        DB      $82,$4A,$36          ; phrase $48: 2 fragments ($4A $36)
        DB      $82,$4B,$10          ; phrase $49: 2 fragments ($4B $10)
        DB      $82,$4C,$10          ; phrase $4A: 2 fragments ($4C $10)
        DB      $83,$41,$4D,$36      ; phrase $4B: 3 fragments ($41 $4D $36)
        DB      $82,$4A,$36          ; phrase $4C: 2 fragments ($4A $36)
        DB      $82,$4B,$10          ; phrase $4D: 2 fragments ($4B $10)
        DB      $82,$4C,$10          ; phrase $4E: 2 fragments ($4C $10)
        DB      $83,$41,$4D,$36      ; phrase $4F: 3 fragments ($41 $4D $36)
German_Checksum_Compensation:
        DB      $C3             ; Balances the complete 4 KB additive checksum to $00
; End of German speech phrase data.

; $CF5F-$CFEA: unused ROM space filled with $FF.
; FF fill shortened by the 65 added PA1 bytes.
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF

German_ROM_Identification:
        DB      "GERMAN WIZARD",$00
German_ROM_Manufacturer:
        DB      "DNA",$00       ; Dave Nutting Associates identification
German_ROM_Date:
        DB      $04,$30,$81     ; Date field: 04/30/1981

        END

