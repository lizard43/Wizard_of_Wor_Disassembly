; Reverse Source of the file "GERMAN.X11" for
; WIZARD OF WOR Socket x11.  Others would be ??
;
; CPU Type: Z80 for BALLY Commercial Arcade Game
;
; Re-created with dZ80 2.0 from scratch by RCD (Richard C. Degler
; on or after Friday, 26 of July 2013 at 08:09 PM
;
; Assembles, but of course it's just a Data ROM!
;

        NOLIST
;                               ; no EQUates

        LIST
        ORG     $C000           ; German LANGUAGE data ROM start

LC000:  DW      LCD8D           ; SPEECH String pointer table base

LC002:  DW      LCE35           ; address of GERMAN Phrase data table

; the GERMAN Funny table of ?? (limit of 6 entries)
LC004:  DB      $10             ; ASCII DELete
        DB      $20             ; SPACE character
        DB      $30             ; Number "0"
        DB      $40             ; Symbol "@" (commercial-AT sign)
        DB      $70             ; Letter "p" lower case !!
        DB      $50             ; Letter "P" ??

LC00A:  DB      $00             ; CHECKSUM Byte = 0

LC00B:  DW      LC1D2           ; ALTernate FoNT characters (for ASCII 98 up !!)

;
; GERMAN Text strings = "original English" translated (length need not match !!)
; Routine L078B: counts down B, returns HL = desired String, and B = Length byte
; note: _IF_ Alternate Character font WAS supplied, lowest one would show as 'b'
; ASCII $40 Symbol '@' will display on-screen as ASCII $20 'SPACE' instead, and
;
LC00D: ; String #1 = "INSERT COIN" (Length = 47 maximum) :;<=>? are unsupported!
        DB      $0F,"@MUENZEINWURF@@"

; LC01D: String #2  = "HIGH SCORES" not pointed at
        DB      $0F,"HOECHSTERGEBNIS"

; LC02D: String #3  = "PRESS ONE PLAYER BUTTON" see above
        DB      $1C,"DRUECKEN@SIE@1@SPIELER@KNOPF"

; LC04A: String #4 = "PRESS TWO PLAYER BUTTON"
        DB      $1E,"@DRUECKEN@SIE@2@SPIELER@KNOPF@"

; LC069: String #5 = "OR"
        DB      $04,"ODER"

; LC06E: String #6 = "DEPOSIT ADDITIONAL COIN"
        DB      $1E,"WERFEN@SIE@ZUSAETZLICHE@MUENZE"

; LC08D: String #7 = "FOR TWO PLAYER GAME"
        DB      $12,"FUER@2@SPIELER@EIN"

; LC0A0: String #8 = "POINTS"
        DB      $06,"PUNKTE"

; LC0A7: String #9 =  "BONUS PLAYER"
        DB      $0D,"BONUS@SPIELER"

; LC0B5: String #10 = "WAIT FOR INSTRUCTIONS"
        DB      $1A,"WARTEN@SIE@AUF@ANWEISUNGEN"

; LC0D0: String #11 = "INVISIBLE MONSTERS IN THE MAZE"
        DB      $20,"UNSICHTBARE@MONSTER@IM@LABYRINTH"

; LC0F1: String #12 = "ARE LOCATED USING THE RADAR SCREEN"
        DB      $26,"WERDEN@DURCH@RADARSTRAHLEN@LOKALISIERT"

; LC118: String #13 = "MONSTERS BECOME VISIBLE WHEN ENTERING"
        DB      $24,"MONSTER@WERDEN@SICHTBAR@WENN@SIE@DEN"

; LC13D: String #14 = "THE SAME MAZE CORRIDOR AS THE PLAYER"
        DB      $1E,"KORRIDOR@DES@SPIELERS@BETRETEN"

; L015C: String #15 = " GET READY "
        DB      $0F,"AUF@DIE@PLAETZE"

; LC16C: String #16 = "RADAR"
        DB      $05,"RADAR"

; LC172: String #17 = "ESCAPED"
        DB      $06,"ENTKAM"

; LC179: String #18 = "CREDITS"
        DB      $06,"KREDIT"

; LC180: String #19 = "DUNGEON  "
        DB      $0B,"LABYRINTH@@"

; LC18C: String #20 = "WORLORD DUNGEON"
        DB      $11,"WORLORD@LABYRINTH"

; LC19E: String #21 = "THE ARENA"
        DB      $09,"DIE@ARENA"

; LC1A8: String #22 = "THE PIT"
        DB      $0D,"@DIE@VERLIESS"

; LC1B6: String #23 = "OR FOR EXTRA WORRIORS"
        DB      $1A,"ODER@FUER@WEITERE@WORRIORS"
; end of Indexed TEXTs

; filler byte
        NOP

; ALTFNT: would be 10 bytes per character entered as 'b' and so forth ...
; Although German has plenty, uses NO Foreign Characters above ASCII 98 ...
LC1D2:  DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ASCII 'b'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ASCII 'c'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ASCII 'd'
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; ASCII 'e'
        DB      $FF,$FF,$FF,$FF,$FF,$FF   ; (Cut Off !!)  ASCII 'f'

;
;**********************************************************
; GERMAN's SPEECH String strings here (Byte=Length, in DATA bytes somehow...)
; note: Phoneme Data includes INFLECTION bits as v = bit 6 or ^ = bit 7
;**********************************************************
; Phoneme Data wrapped at 80-characters to avoid zMac "Line Buffer Overflows" !!
;
; GERMAN String $00 = "zzz-unk" (has l-o-o-o-n-g GERMAN words allruntogether !!)
; Data = ^PAuse0-F-A1-R-N-Y-H-H-T-E1-PAuse0-W-O-O1-R-L-UH-K ...
; ... -F-IU-IU-R-D-O2-P-A1-L-T-I-P-W-W-N-K-T-S-AW1-AW2-L-PAuse1-^PAuse0
LC200:  DB      $29             ; Lemgth of Data in bytes
        DB      $83,$1D,$06,$2B,$0D,$29,$1B,$1B
        DB      $2A,$3C,$03,$2D,$26,$35,$2B,$18
        DB      $33,$19,$1D,$36,$36,$2B,$1E,$34
        DB      $25,$06,$18,$2A,$27,$25,$2D,$2D
        DB      $0D,$19,$2A,$1F,$13,$30,$18,$3E
        DB      $83

; GERMAN String $01 = ""
; Data = ^PAuse0-V-A1-N-N-D-U1-U1-PAuse0-S-U1-U1-M-A2-H-H-T-Y-G-PAuse0 ...
; ... -V-Y-R-S-T-PAuse1-G-EH-AH2-E1-F-E1-PAuse0-Y-H-H-S-A1-L-B-S-T-PAuse0 ...
; ... -AH2-E1-N-PAuse1-^PAuse0
LC22A:  DB      $30             ; Lemgth (see above)
        DB      $83,$0F,$06,$0D,$0D,$1E,$37,$37
        DB      $03,$1F,$37,$37,$0C,$05,$1B,$1B
        DB      $2A,$29,$1C,$03,$0F,$29,$2B,$1F
        DB      $2A,$3E,$1C,$3B,$08,$3C,$1D,$3C
        DB      $03,$29,$1B,$1B,$1F,$06,$18,$0E
        DB      $1F,$2A,$03,$08,$3C,$0D,$3E,$83

; GERMAN String $4E = ""
; Data = ^PAuse0-D-U-U-B-Y-S-T-T-Y-N-N-D-A1-N-^PAuse0
LC25B:  DB      $10
        DB      $83,$1E,$28,$28,$0E,$29,$1F,$2A
        DB      $2A,$29,$0D,$0D,$1E,$06,$0D,$83

; GERMAN String $02 = ""
; Data = ^PAuse0-L-AH1-B-IU-IU-IU-R-I1-N-T-^PAuse0
LC26C:  DB      $0C
        DB      $83,$18,$15,$0E,$36,$36,$36,$2B
        DB      $0B,$0D,$2A,$83

; GERMAN String $50 = ""
; Data = ^PAuse0-F-O1-N-W-O-O1-R-PAuse1-^PAuse0
LC279:  DB      $0A
        DB      $83,$1D,$35,$0D,$2D,$26,$35,$2B
        DB      $3E,$83

; GERMAN String $04 = ""
; Data = W-vI-Z-ER-D-F-O1-N-PAuse0-vW-O-O1-R-R-PAuse1
LC284:  DB      $0F
        DB      $2D,$67,$12,$3A,$1E,$1D,$35,$0D
        DB      $03,$6D,$26,$35,$2B,$2B,$3E

; GERMAN String $05 = ""
; Data = AH2-E1-N-B-Y-S-S-F-O1-N-M-AH2-E1-N-E1-N-SH-OO1-A2-N-A1-N-PAuse0 ...
; ... -W-N-D-D-W-W-A1-G-S-P-L-O2-D-Y-R-S-T-PAuse1
LC294:  DB      $29
        DB      $08,$3C,$0D,$0E,$29,$1F,$1F,$1D
        DB      $35,$0D,$0C,$08,$3C,$0D,$3C,$0D
        DB      $11,$16,$05,$0D,$06,$0D,$03,$2D
        DB      $0D,$1E,$1E,$2D,$2D,$06,$1C,$1F
        DB      $25,$18,$34,$1E,$29,$2B,$1F,$2A
        DB      $3E

; GERMAN String $06 = ""
; Data = M-AH2-E1-N-A1-K-R-A1-UH-T-W-W-R-A1-N-Z-Y-N-D-PAuse0 ...
; ... -R-AH-D-Y-Y-O2-O1-UH-K-T-T-Y-Y-V-V-PAuse1
LC2BE:  DB      $24
        DB      $0C,$08,$3C,$0D,$06,$19,$2B,$06
        DB      $33,$2A,$2D,$2D,$2B,$06,$0D,$12
        DB      $29,$0D,$1E,$03,$2B,$24,$1E,$29
        DB      $29,$34,$35,$33,$19,$2A,$2A,$29
        DB      $29,$0F,$0F,$3E

; GERMAN String $07 = ""
; Data = W-O-R-L-UH-K-PAuse0-V-Y-R-D-PAuse0 ...
; ... -D-U1-R-H-H-D-Y-Y-T-T-IU-Y1-R-A1-N-T-K-O1-M-M-A1-N-PAuse1
LC2E3:  DB      $23
        DB      $2D,$26,$2B,$18,$33,$19,$03,$0F
        DB      $29,$2B,$1E,$03,$1E,$37,$2B,$1B
        DB      $1B,$1E,$29,$29,$2A,$2A,$36,$22
        DB      $2B,$06,$0D,$2A,$19,$35,$0C,$0C
        DB      $06,$0D,$3E

; GERMAN String $03 = ""
; Data = Y-H-H-B-I3-N-D-A1-R
LC307:  DB      $09
        DB      $29,$1B,$1B,$0E,$09,$0D,$1E,$06
        DB      $2B

; GERMAN String $22 = ""
; Data = D-U1-U1-B-L-AH2-E1-B-S-T-N-Y-H-H-T-G-AW1-N-S-PAuse1 ...
; ... -N-AW1-H-D-Y-Y-Z-A1-M-PAuse0-V-Y-Y-L-D-A1-N-PAuse0-T-AW1-N-N-S-PAuse1
LC311:  DB      $2C
        DB      $1E,$37,$37,$0E,$18,$08,$3C,$0E
        DB      $1F,$2A,$0D,$29,$1B,$1B,$2A,$1C
        DB      $13,$0D,$1F,$3E,$0D,$13,$1B,$1E
        DB      $29,$29,$12,$06,$0C,$03,$0F,$29
        DB      $29,$18,$1E,$06,$0D,$03,$2A,$13
        DB      $0D,$0D,$1F,$3E

; GERMAN String $23 = ""
; Data = ^PAuse0-D-A1-N-K-PAuse0-D-R-AW1-N-N-PAuse1 ...
; ... -Y-H-F-B-Y-N-D-E1-R-W-I-Z-ER-D-PAuse1-N-Y-H-H-T-D-U1-U1-PAuse1-^PAuse0
LC33E:  DB      $25
        DB      $83,$1E,$06,$0D,$19,$03,$1E,$2B
        DB      $13,$0D,$0D,$3E,$29,$1B,$1D,$0E
        DB      $29,$0D,$1E,$3C,$2B,$2D,$27,$12
        DB      $3A,$1E,$3E,$0D,$29,$1B,$1B,$2A
        DB      $1E,$37,$37,$3E,$83

; GERMAN String $24 = ""
; Data = V-A1-N-N-D-U1-U1-PAuse0-SH-L-A2-A2-G-S-S-T-UH-U1-H-H-PAuse0 ...
; ... -D-Y-Y-PAuse0-R-A1-S-T-A1-PAuse1-^PAuse0 ...
; ... -D-UH-N-N-K-UH-N-N-S-T-N-A1-N-N-A1-N-D-Y-H-H-D-A1-R-PAuse0 ...
; ... -B-A1-V-T-A1-PAuse0-PAuse1-^PAuse0
LC364:  DB      $40
        DB      $0F,$06,$0D,$0D,$1E,$37,$37,$03
        DB      $11,$18,$05,$05,$1C,$1F,$1F,$2A
        DB      $33,$37,$1B,$1B,$03,$1E,$29,$29
        DB      $03,$2B,$06,$1F,$2A,$06,$3E,$83
        DB      $1E,$33,$0D,$0D,$19,$33,$0D,$0D
        DB      $1F,$2A,$0D,$06,$0D,$0D,$06,$0D
        DB      $1E,$29,$1B,$1B,$1E,$06,$2B,$03
        DB      $0E,$06,$0F,$2A,$06,$03,$3E,$83

; GERMAN String $25 = ""
; Data = ^PAuse0-V-I2-N-N-D-U1-U1-M-AH2-E1-N-E1-B-A2-AY-AY-B-Y-Y-S ...
; ... -AH2-N-F-AH1-S-T-PAuse1 ...
; ... -V-A1-R-D-E1-Y-H-H-D-Y-Y-H-H-Y-M-O1-O1-F-A1-N-B-R-AW-T-A1-N-PAuse1-^PAuse0
LC3A5:  DB      $38
        DB      $83,$0F,$0A,$0D,$0D,$1E,$37,$37
        DB      $0C,$08,$3C,$0D,$3C,$0E,$05,$21
        DB      $21,$0E,$29,$29,$1F,$08,$0D,$1D
        DB      $15,$1F,$2A,$3E,$0F,$06,$2B,$1E
        DB      $3C,$29,$1B,$1B,$1E,$29,$29,$1B
        DB      $1B,$29,$0C,$35,$35,$1D,$06,$0D
        DB      $0E,$2B,$3D,$2A,$06,$0D,$3E,$83

; GERMAN String $26 = ""
; Data = ^PAuse0-L-AH2-AH2-N-G-Z-AH2-AH2-M-V-A1-R-D-E1-PAuse0-Y-H-H-PAuse0 ...
; ... -B-OO1-Y-Y-Z-E1-PAuse1-^PAuse0
LC3DE:  DB      $1C
        DB      $83,$18,$08,$08,$0D,$1C,$12,$08
        DB      $08,$0C,$0F,$06,$2B,$1E,$3C,$03
        DB      $29,$1B,$1B,$03,$0E,$16,$29,$29
        DB      $12,$3C,$3E,$83

; GERMAN String $27 = ""
; Data = ^PAuse0-D-U1-U1-V-Y-R-S-T-V-O1-O1-R-PAuse0-PAuse0 ...
; ... -N-Y-H-H-T-AW2-M-M-PAuse0-L-A1-B-E1-N-D-Y-G-A1-N-L-AH2-E1-B-E1-PAuse0 ...
; ... -F-A1-R-L-AH2-S-A1-N-PAuse1-^PAuse0
LC3FB:  DB      $32
        DB      $83,$1E,$37,$37,$0F,$29,$2B,$1F
        DB      $2A,$0F,$35,$35,$2B,$03,$03,$0D
        DB      $29,$1B,$1B,$2A,$30,$0C,$0C,$03
        DB      $18,$06,$0E,$3C,$0D,$1E,$29,$1C
        DB      $06,$0D,$18,$08,$3C,$0E,$3C,$03
        DB      $1D,$06,$2B,$18,$08,$1F,$06,$0D
        DB      $3E,$83

; GERMAN String $1B = ""
; Data = ^PAuse0-G-vAH1-R-W-O1-R-PAuse1-P-AH1-K-K-PAuse0-Z-Y-Y-PAuse1-^PAuse0
LC42E:  DB      $12
        DB      $83,$1C,$55,$2B,$2D,$35,$2B,$3E
        DB      $25,$15,$19,$19,$03,$12,$29,$29
        DB      $3E,$83

; GERMAN String $08 = ""
; Data = ^PAuse0-B-E1-PAuse0-O2-O2-B-UH-H-H-T-T-A1-PAuse0 ...
; ... -D-A1-A2-N-ER-UH-D-D-UH-R-SH-Y-R-M-M-^PAuse0-PAuse0-PAuse1
LC441:  DB      $20
        DB      $83,$0E,$3C,$03,$34,$34,$0E,$33
        DB      $1B,$1B,$2A,$2A,$06,$03,$1E,$06
        DB      $05,$0D,$3A,$33,$1E,$1E,$33,$2B
        DB      $11,$29,$2B,$0C,$0C,$83,$03,$3E

; GERMAN String $09 = "" (note: program substitutes Data $40 !!)
; Data = W-O-R-Y-ER-PAuse1
LC462:  DB      $06
        DB      $2D,$26,$2B,$29,$3A,$3E

; GERMAN String $1A = ""
; Data = ^PAuse0-J-A1-T-S-T-K-O2-M-A1-N-D-Y-SH-V-A1-R-G-E1-V-Y-H-H-T-E1 ...
; ... -PAuse1-^PAuse0
LC469:  DB      $1B
        DB      $83,$1A,$06,$2A,$1F,$2A,$19,$34
        DB      $0C,$06,$0D,$1E,$29,$11,$0F,$06
        DB      $2B,$1C,$3C,$0F,$29,$1B,$1B,$2A
        DB      $3C,$3E,$83

; GERMAN String $35 = ""
; Data = ^PAuse0-D-U1-U1-PAuse0-V-Y-L-S-T-V-O-L-PAuse0-A2-A2-R-G-A2-R-PAuse1 ...
; ... -^PAuse0
LC485:  DB      $16
        DB      $83,$1E,$37,$37,$03,$0F,$29,$18
        DB      $1F,$2A,$0F,$26,$18,$03,$05,$05
        DB      $2B,$1C,$05,$2B,$3E,$83

; GERMAN String $1C = ""
; Data = ^PAuse0-V-A1-N-N-D-U1-U1-S-PAuse0 ...
; ... -N-O1-H-H-M-AW-L-F-A1-R-Z-U1-U1-H-H-S-T-PAuse1 ...
; ... -H-UH-U1-A1-N-V-Y-Y-R-D-Y-H-H-Y-N-D-Y-PAuse0-P-F-AH2-N-N-E1-PAuse1-^PAuse0
LC49C:  DB      $36
        DB      $83,$0F,$06,$0D,$0D,$1E,$37,$37
        DB      $1F,$03,$0D,$35,$1B,$1B,$0C,$3D
        DB      $18,$1D,$06,$2B,$12,$37,$37,$1B
        DB      $1B,$1F,$2A,$3E,$1B,$33,$37,$06
        DB      $0D,$0F,$29,$29,$2B,$1E,$29,$1B
        DB      $1B,$29,$0D,$1E,$29,$03,$25,$1D
        DB      $08,$0D,$0D,$3C,$3E,$83

; GERMAN String $1D = ""
; Data = ^PAuse0-B-vER-vR-W-O-R-PAuse1-G-vAH1-vR-W-O-R-PAuse1 ...
; ... -U1-U1-N-D-TH-vR-vR-W-O-R-PAuse1-V-A1-R-D-A1-N-D-Y-H-H-PAuse0 ...
; ... -AH2-E1-N-M-AW1-H-H-A1-N-PAuse1-^PAuse0
LC4D3:  DB      $30
        DB      $83,$0E,$7A,$6B,$2D,$26,$2B,$3E
        DB      $1C,$55,$6B,$2D,$26,$2B,$3E,$37
        DB      $37,$0D,$1E,$39,$66,$6B,$2D,$26
        DB      $2B,$3E,$0F,$06,$2B,$1E,$06,$0D
        DB      $1E,$29,$1B,$1B,$03,$08,$3C,$0D
        DB      $0C,$13,$1B,$1B,$06,$0D,$3E,$83

; GERMAN String $1E = ""
; Data = ^PAuse0-M-AH2-E1-N-E1-SH-IU-IU-T-Z-L-I1-N-UH2-PAuse0 ...
; ... -Z-Y-N-D-Z-Z-E1-R-PAuse0-G-E1-F-R-A2-A2-S-Y-G-PAuse1-^PAuse0
LC504:  DB      $24
        DB      $83,$0C,$08,$3C,$0D,$3C,$11,$36
        DB      $36,$2A,$12,$18,$0B,$0D,$31,$03
        DB      $12,$29,$0D,$1E,$12,$12,$3C,$2B
        DB      $03,$1C,$3C,$1D,$2B,$05,$05,$1F
        DB      $29,$1C,$3E,$83

; GERMAN String $1F = ""
; Data = M-AH2-E1-N-E1-M-UH-PAuse0-G-Y-SH-E1-K-R-AW1-F-T-PAuse0-Y-S-T-PAuse0 ...
; ... -S-T-A1-A1-R-K-A1-R-AH1-L-S-PAuse0-D-AH2-E1-N-E1-PAuse0 ...
; ... -V-AH1-F-F-A1-N-PAuse1
LC529:  DB      $2F
        DB      $0C,$08,$3C,$0D,$3C,$0C,$33,$03
        DB      $1C,$29,$11,$3C,$19,$2B,$13,$1D
        DB      $2A,$03,$29,$1F,$2A,$03,$1F,$2A
        DB      $06,$06,$2B,$19,$06,$2B,$15,$18
        DB      $1F,$03,$1E,$08,$3C,$0D,$3C,$03
        DB      $0F,$15,$1D,$1D,$06,$0D,$3E

; GERMAN String $21 = ""
; Data = ^PAuse0-D-AH2-E1-N-E1-K-N-O2-H-H-A1-N-PAuse0 ...
; ... -V-A1-R-D-A1-N-Y-N-D-A2-N-PAuse0
LC559:  DB      $1A
        DB      $83,$1E,$08,$3C,$0D,$3C,$19,$0D
        DB      $34,$1B,$1B,$06,$0D,$03,$0F,$06
        DB      $2B,$1E,$06,$0D,$29,$0D,$1E,$05
        DB      $0D,$03

; GERMAN String $51 = ""
; Data = V-O1-N-W-O-O1-R-F-A1-R-Z-Z-UH-U1-A1-R-N-PAuse1-^PAuse0
LC574:  DB      $13
        DB      $0F,$35,$0D,$2D,$26,$35,$2B,$1D
        DB      $06,$2B,$12,$12,$33,$37,$06,$2B
        DB      $0D,$3E,$83

; GERMAN String $20 = ""
; Data = D-U1-U1-PAuse0-S-T-E1-E1-S-T-UH-U1-F-F-PAuse0 ...
; ... -V-Y-S-S-A1-N-SH-AW1-F-F-T-PAuse1-PAuse1-Y-H-H-PAuse0 ...
; ... -G-L-UH-U1-B-E1-AW1-N-N-PAuse0-M-AH1-PAuse0-G-Y-Y-PAuse1
LC588:  DB      $31
        DB      $1E,$37,$37,$03,$1F,$2A,$3C,$3C
        DB      $1F,$2A,$33,$37,$1D,$1D,$03,$0F
        DB      $29,$1F,$1F,$06,$0D,$11,$13,$1D
        DB      $1D,$2A,$3E,$3E,$29,$1B,$1B,$03
        DB      $1C,$18,$33,$37,$0E,$3C,$13,$0D
        DB      $0D,$03,$0C,$15,$03,$1C,$29,$29
        DB      $3E

; GERMAN String $0A = ""
; Data = H-A-vI1-vY1-PAuse1-V-Y-R-F-PAuse1-G-A2-L-L-T-PAuse0-AH2-I1-N-N-PAuse1
LC5BA:  DB      $15
        DB      $1B,$20,$4B,$62,$3E,$0F,$29,$2B
        DB      $1D,$3E,$1C,$05,$18,$18,$2A,$03
        DB      $08,$0B,$0D,$0D,$3E

; GERMAN String $0B = ""
; Data = Z-U-H-H-PAuse0-M-Y-H-H-PAuse0-D-AY-AY-N-PAuse0
LC5D0:  DB      $0F
        DB      $12,$28,$1B,$1B,$03,$0C,$29,$1B
        DB      $1B,$03,$1E,$21,$21,$0D,$03

; GERMAN String $0C = ""
; Data = Y-H-H-PAuse0-B-Y-N-PAuse0-U1-N-Z-Y-H-H-T-B-AH1-R-PAuse1
LC5E0:  DB      $13
        DB      $29,$1B,$1B,$03,$0E,$29,$0D,$03
        DB      $37,$0D,$12,$29,$1B,$1B,$2A,$0E
        DB      $15,$2B,$3E

; GERMAN String $0D = ""
; Data = Z-AH2-E1-PAuse1-B-E1-ER-AH2-I2-T-T
LC5F4:  DB      $0B
        DB      $12,$08,$3C,$3E,$0E,$3C,$3A,$08
        DB      $0A,$2A,$2A

; GERMAN String $0E = ""
; Data = G-N-UH-UH-D-E1-D-Y-R-G-O1-T-T-T-PAuse0-V-A1-N-N-D-W-PAuse0 ...
; ... -D-A1-A2-N-W-vI-Z-ER-D-F-O1-N-PAuse0-vW-O-O1-R-R-F-Y-N-D-A1-S-S-T-PAuse1
LC600:  DB      $31
        DB      $1C,$0D,$33,$33,$1E,$3C,$1E,$29
        DB      $2B,$1C,$35,$2A,$2A,$2A,$03,$0F
        DB      $06,$0D,$0D,$1E,$2D,$03,$1E,$06
        DB      $05,$0D,$2D,$67,$12,$3A,$1E,$1D
        DB      $35,$0D,$03,$6D,$26,$35,$2B,$2B
        DB      $1D,$29,$0D,$1E,$06,$1F,$1F,$2A
        DB      $3E

; GERMAN String $0F = ""
; Data = AH2-E1-N-E1-PAuse0-V-AH2-E1-T-T-AY-ER-E1-PAuse0 ...
; ... -M-IU-IU-N-T-Z-E1-PAuse0-F-IU-IU-IU-R-PAuse0-M-AH2-E1-N-E1-PAuse0 ...
; ... -B-R-Y-F-T-AH2-SH-AY-PAuse1
LC632:  DB      $2B
        DB      $08,$3C,$0D,$3C,$03,$0F,$08,$3C
        DB      $2A,$2A,$21,$3A,$3C,$03,$0C,$36
        DB      $36,$0D,$2A,$12,$3C,$03,$1D,$36
        DB      $36,$36,$2B,$03,$0C,$08,$3C,$0D
        DB      $3C,$03,$0E,$2B,$29,$1D,$2A,$08
        DB      $11,$21,$3E

; GERMAN String $10 = ""
; Data = PAuse1-H-vAH1-H-vAH1-H-AH1-H-AH1-PAuse1
LC65E:  DB      $0A
        DB      $3E,$1B,$55,$1B,$55,$1B,$15,$1B
        DB      $15,$3E

; GERMAN String $11 = ""
; Data = Z-Z-E1-R-PAuse0-G-G-U-T-T-PAuse1-M-AH2-E1-N-E1-PAuse0 ...
; ... -K-L-AH2-E1-N-E1-N-PAuse0-Z-I1-N-D-Z-Z-E1-R-PAuse0-H-U1-N-G-R-E1-G-PAuse1
LC669:  DB      $2A
        DB      $12,$12,$3C,$2B,$03,$1C,$1C,$28
        DB      $2A,$2A,$3E,$0C,$08,$3C,$0D,$3C
        DB      $03,$19,$18,$08,$3C,$0D,$3C,$0D
        DB      $03,$12,$0B,$0D,$1E,$12,$12,$3C
        DB      $2B,$03,$1B,$37,$0D,$1C,$2B,$3C
        DB      $1C,$3E

; GERMAN String $12 = ""
; Data = ^PAuse0-N-U1-U1-N-PAuse0-V-Y-R-S-T-D-U1-U1-Y-N-D-Y-PAuse1 ...
; ... -AW1-R-E1-N-AW1-PAuse0-G-E1-V-O1-R-F-A1-N-PAuse1-^PAuse1
LC694:  DB      $23
        DB      $83,$0D,$37,$37,$0D,$03,$0F,$29
        DB      $2B,$1F,$2A,$1E,$37,$37,$29,$0D
        DB      $1E,$29,$3E,$13,$2B,$3C,$0D,$13
        DB      $03,$1C,$3C,$0F,$35,$2B,$1D,$06
        DB      $0D,$3E,$BE

; GERMAN String $36 = ""
; Data = ^PAuse1-H-AH1-H-AH1-H-AH1-H-AH1-PAuse1-^PAuse0
LC6B8:  DB      $0B
        DB      $BE,$1B,$15,$1B,$15,$1B,$15,$1B
        DB      $15,$3E,$83

; GERMAN String $13 = ""
; Data = N-O2-H-H-PAuse0-AH2-E1-N-E1-N-W-O-R-Y-ER-PAuse0 ...
; ... -D-E1-N-M-AH2-E1-N-E1-PAuse0 ...
; ... -Z-U1-Y1-Y1-S-A1-N-F-A1-R-SH-L-Y-N-G-A1-N-V-A1-R-D-A1-N-PAuse1
LC6C4:  DB      $31
        DB      $0D,$34,$1B,$1B,$03,$08,$3C,$0D
        DB      $3C,$0D,$2D,$26,$2B,$29,$3A,$03
        DB      $1E,$3C,$0D,$0C,$08,$3C,$0D,$3C
        DB      $03,$12,$37,$22,$22,$1F,$06,$0D
        DB      $1D,$06,$2B,$11,$18,$29,$0D,$1C
        DB      $06,$0D,$0F,$06,$2B,$1E,$06,$0D
        DB      $3E

; GERMAN String $14 = ""
; Data = M-AW1-H-H-V-AH2-E1-T-A1-R-PAuse0-U1-U1-N-D-PAuse0 ...
; ... -D-U1-U1-F-Y-N-D-A1-S-T-M-Y-H-H-PAuse1
LC6F6:  DB      $1F
        DB      $0C,$13,$1B,$1B,$0F,$08,$3C,$2A
        DB      $06,$2B,$03,$37,$37,$0D,$1E,$03
        DB      $1E,$37,$37,$1D,$29,$0D,$1E,$06
        DB      $1F,$2A,$0C,$29,$1B,$1B,$3E

; GERMAN String $15 = ""
; Data = N-O2-O2-H-PAuse0-AH2-E1-N-P-AH1-R-PAuse0 ...
; ... -L-AH1-B-IU-IU-IU-I1-N-T-Y-Y-PAuse0-U1-U1-N-D-PAuse0 ...
; ... -D-U1-U1-B-Y-S-T-AH2-E1-N-PAuse0
LC716:  DB      $28
        DB      $0D,$34,$34,$1B,$03,$08,$3C,$0D
        DB      $25,$15,$2B,$03,$18,$15,$0E,$36
        DB      $36,$36,$0B,$0D,$2A,$29,$29,$03
        DB      $37,$37,$0D,$1E,$03,$1E,$37,$37
        DB      $0E,$29,$1F,$2A,$08,$3C,$0D,$03

; GERMAN String $40 = ""
; Data = W-vR-vR-L-O-R-D-PAuse1
LC73F:  DB      $08
        DB      $2D,$66,$6B,$18,$26,$2B,$1E,$3E

; GERMAN String $41 = ""
; Data = ^PAuse0-W-vR-vR-L-O-R-D-PAuse1-^PAuse0
LC748:  DB      $0A
        DB      $83,$2D,$66,$6B,$18,$26,$2B,$1E
        DB      $3E,$83

; GERMAN String $16 = ""
; Data = SH-P-Y-Y-L-D-AW2-S-PAuse0-SH-P-Y-Y-L-PAuse0 ...
; ... -N-O1-H-H-AH2-E1-N-M-AH-L-PAuse1-D-AW1-N-N-V-Y-R-S-T-PAuse0 ...
; ... -SH-Y-Y-S-A1-N-PAuse0-B-A2-S-R-AY-PAuse0-S-AH-L-PAuse1
LC753:  DB      $35
        DB      $11,$25,$29,$29,$18,$1E,$30,$1F
        DB      $03,$11,$25,$29,$29,$18,$03,$0D
        DB      $35,$1B,$1B,$08,$3C,$0D,$0C,$24
        DB      $18,$3E,$1E,$13,$0D,$0D,$0F,$29
        DB      $2B,$1F,$2A,$03,$11,$29,$29,$1F
        DB      $06,$0D,$03,$0E,$05,$1F,$2B,$21
        DB      $03,$1F,$24,$18,$3E

; GERMAN String $17 = ""
; Data = ^PAuse0-D-Y-Y-L-AH1-B-IU-IU-IU-R-I1-N-T-Y-Y-PAuse0 ...
; ... -F-O1-W-V-O1-O1-R-PAuse0-V-AW1-R-T-A1-N-UH-U1-F-F-PAuse0 ...
; ... -D-AH2-E1-N-E1-R-IU-Y1-K-PAuse0-K-A1-E1-R-PAuse1-^PAuse0
LC789:  DB      $34
        DB      $83,$1E,$29,$29,$18,$15,$0E,$36
        DB      $36,$36,$2B,$0B,$0D,$2A,$29,$29
        DB      $03,$1D,$35,$2D,$0F,$35,$35,$2B
        DB      $03,$0F,$13,$2B,$2A,$06,$0D,$33
        DB      $37,$1D,$1D,$03,$1E,$08,$3C,$0D
        DB      $3C,$2B,$36,$22,$19,$03,$19,$06
        DB      $3C,$2B,$3E,$83

; GERMAN String $18 = ""
; Data = ^PAuse0-D-R-U1-N-T-A1-N-PAuse1 ...
; ... -Y-N-D-E1-N-H-O2-I3-I3-L-AY-N-F-O1-N-V-O1-O1-R-PAuse0 ...
; ... -V-Y-R-S-T-D-U1-U1-M-Y-H-H-PAuse0-T-R-A1-F-F-A1-N-PAuse1-^PAuse0
LC7BE:  DB      $33
        DB      $83,$1E,$2B,$37,$0D,$2A,$06,$0D
        DB      $3E,$29,$0D,$1E,$3C,$0D,$1B,$34
        DB      $09,$09,$18,$21,$0D,$1D,$35,$0D
        DB      $0F,$35,$35,$2B,$03,$0F,$29,$2B
        DB      $1F,$2A,$1E,$37,$37,$0C,$29,$1B
        DB      $1B,$03,$2A,$2B,$06,$1D,$1D,$06
        DB      $0D,$3E,$83

; GERMAN String $19 = ""
; Data = D-A1-R
LC7F2:  DB      $03
        DB      $1E,$06,$2B

; GERMAN String $53 = ""
; Data = B-E1-D-AH2-N-K-T-PAuse0-S-Y-H-H-PAuse1
LC7F6:  DB      $0D
        DB      $0E,$3C,$1E,$08,$0D,$19,$2A,$03
        DB      $1F,$29,$1B,$1B,$3E

; GERMAN String $29 = ""
; Data = ^PAuse0-D-U1-U1-V-AH2-E1-S-T-PAuse0-G-E1-N-UH-U1-PAuse0 ...
; ... -D-AH2-S-PAuse0-D-U1-U1-PAuse0-A1-S-PAuse0-B-A1-S-A1-R-PAuse0 ...
; ... -K-AH2-AH2-N-S-T-PAuse1-^PAuse0
LC804:  DB      $29
        DB      $83,$1E,$37,$37,$0F,$08,$3C,$1F
        DB      $2A,$03,$1C,$3C,$0D,$33,$37,$03
        DB      $1E,$08,$1F,$03,$1E,$37,$37,$03
        DB      $06,$1F,$03,$0E,$06,$1F,$06,$2B
        DB      $03,$19,$08,$08,$0D,$1F,$2A,$3E
        DB      $83

; GERMAN String $2A = ""
; Data = K-O2-O2-M-M-PAuse0-S-U1-U1-R-IU-Y1-K-K-PAuse1 ...
; ... -R-AH2-AH2-H-H-AY-AY-PAuse0-Y-S-T-PAuse0-Z-U1-Y1-Y1-S-PAuse1
LC82E:  DB      $21
        DB      $19,$34,$34,$0C,$0C,$03,$1F,$37
        DB      $37,$2B,$36,$22,$19,$19,$3E,$2B
        DB      $08,$08,$1B,$1B,$21,$21,$03,$29
        DB      $1F,$2A,$03,$12,$37,$22,$22,$1F
        DB      $3E

; GERMAN String $2B = ""
; Data = Y-H-H-PAuse0-G-R-AH2-E1-F-F-AY-PAuse0-AH2-AH2-N-PAuse0 ...
; ... -M-Y-T-T-PAuse0-G-E1-B-R-IU-Y1-L-PAuse1-^SH-M-AH2-E1-S-S-AY-PAuse0 ...
; ... -D-Y-H-H-PAuse0-J-A1-T-S-T-PAuse0-UH-U1-F-F-D-AY-N-PAuse0 ...
; ... -IU-Y1-L-PAuse1-^PAuse1
LC850:  DB      $3D
        DB      $29,$1B,$1B,$03,$1C,$2B,$08,$3C
        DB      $1D,$1D,$21,$03,$08,$08,$0D,$03
        DB      $0C,$29,$2A,$2A,$03,$1C,$3C,$0E
        DB      $2B,$36,$22,$18,$3E,$91,$0C,$08
        DB      $3C,$1F,$1F,$21,$03,$1E,$29,$1B
        DB      $1B,$03,$1A,$06,$2A,$1F,$2A,$03
        DB      $33,$37,$1D,$1D,$1E,$21,$0D,$03
        DB      $36,$22,$18,$3E,$BE

; GERMAN String $2C = ""
; Data = H-Y-PAuse0-H-Y-PAuse0-H-O2-O2-PAuse0-H-O2-O2-PAuse0 ...
; ... -H-AH1-AH1-PAuse0-H-AH1-AH1-PAuse0-PAuse1 ...
; ... -D-AH2-AH2-S-M-AH2-AH2-H-H-T-PAuse0-SH-P-AH1-AH1-S-PAuse1
LC88E:  DB      $28
        DB      $1B,$29,$03,$1B,$29,$03,$1B,$34
        DB      $34,$03,$1B,$34,$34,$03,$1B,$15
        DB      $15,$03,$1B,$15,$15,$03,$3E,$1E
        DB      $08,$08,$1F,$0C,$08,$08,$1B,$1B
        DB      $2A,$03,$11,$25,$15,$15,$1F,$3E

; GERMAN String $2D = ""
; Data = V-Y-L-K-vO2-vM-vM-A2-N-PAuse0 ...
; ... -Y-N-D-A1-R-V-A1-A2-L-T-T-F-O1-N-vW-vO1-O-R-PAuse1
LC8B7:  DB      $1D
        DB      $0F,$29,$18,$19,$74,$4C,$4C,$05
        DB      $0D,$03,$29,$0D,$1E,$06,$2B,$0F
        DB      $06,$05,$18,$2A,$2A,$1D,$35,$0D
        DB      $6D,$75,$26,$2B,$3E

; GERMAN String $2E = ""
; Data = M-AH2-H-H-D-E1-M-W-vI-vZ-ER-D-M-AH2-AH2-L-V-AH2-S-vV-O1-O1-R-PAuse1 ...
; ... -Z-AH2-M-L-E1-P-vU1-vNG-K-T-E1-PAuse0 ...
; ... -Y-N-D-A1-R-V-A1-L-T-F-O1-N-W-vR-O1-R-PAuse1
LC8D5:  DB      $35
        DB      $0C,$08,$1B,$1B,$1E,$3C,$0C,$2D
        DB      $67,$52,$3A,$1E,$0C,$08,$08,$18
        DB      $0F,$08,$1F,$4F,$35,$35,$2B,$3E
        DB      $12,$08,$0C,$18,$3C,$25,$77,$54
        DB      $19,$2A,$3C,$03,$29,$0D,$1E,$06
        DB      $2B,$0F,$06,$18,$2A,$1D,$35,$0D
        DB      $2D,$66,$35,$2B,$3E

; GERMAN String $2F = ""
; Data = G-vL-vAH2-vE1-H-H-^Z-Y-Y-S-T-T-D-W-D-A1-N-^W-I-Z-ER-D-PAuse1 ...
; ... -D-A1-N-M-UH-G-Y-SH-A1-N-^W-I-Z-ER-D-^F-O1-N-W-O1-O-R-PAuse1-PAuse1
LC90B:  DB      $2F
        DB      $1C,$58,$48,$7C,$1B,$1B,$92,$29
        DB      $29,$1F,$2A,$2A,$1E,$2D,$1E,$06
        DB      $0D,$AD,$27,$12,$3A,$1E,$3E,$1E
        DB      $06,$0D,$0C,$33,$1C,$29,$11,$06
        DB      $0D,$AD,$27,$12,$3A,$1E,$9D,$35
        DB      $0D,$2D,$35,$26,$2B,$3E,$3E

; GERMAN String $30 = ""
; Data = ^PAuse0-Z-AH2-E1-T-M-O2-O2-N-AW2-T-A1-N-PAuse0 ...
; ... -H-AW2-T-T-B-ER-R-W-O-R-N-Y-M-AW2-N-D-A1-N-F-A1-R-N-AH1-SH-T-PAuse1 ...
; ... -^PAuse0
LC93B:  DB      $29
        DB      $83,$12,$08,$3C,$2A,$0C,$34,$34
        DB      $0D,$30,$2A,$06,$0D,$03,$1B,$30
        DB      $2A,$2A,$0E,$3A,$2B,$2D,$26,$2B
        DB      $0D,$29,$0C,$30,$0D,$1E,$06,$0D
        DB      $1D,$06,$2B,$0D,$15,$11,$2A,$3E
        DB      $83

; GERMAN String $31 = ""
; Data = M-AH2-E1-N-E1-K-Y-N-D-E1-R-PAuse1-SH-P-AH2-E1-PAuse0-A1-N-PAuse0 ...
; ... -F-F-O2-O2-I3-I3-PAuse0-A1-R-PAuse1
LC965:  DB      $1E
        DB      $0C,$08,$3C,$0D,$3C,$19,$29,$0D
        DB      $1E,$3C,$2B,$3E,$11,$25,$08,$3C
        DB      $03,$06,$0D,$03,$1D,$1D,$34,$34
        DB      $09,$09,$03,$06,$2B,$3E

; GERMAN String $32 = ""
; Data = ^PAuse0-M-Y-T-M-AH2-E1-N-A1-R-L-Y-H-H-T-K-AW1-N-O2-O2-O2-N-E1 ...
; ... -PAuse0-F-A1-R-B-R-I2-I2-N-N-PAuse0-N-E1-PAuse0 ...
; ... -Y-H-H-PAuse0-D-Y-H-H-PAuse1-^PAuse0
LC984:  DB      $2F
        DB      $83,$0C,$29,$2A,$0C,$08,$3C,$0D
        DB      $06,$2B,$18,$29,$1B,$1B,$2A,$19
        DB      $13,$0D,$34,$34,$34,$0D,$3C,$03
        DB      $1D,$06,$2B,$0E,$2B,$0A,$0A,$0D
        DB      $0D,$03,$0D,$3C,$03,$29,$1B,$1B
        DB      $03,$1E,$29,$1B,$1B,$3E,$83

; GERMAN String $28 = ""
; Data = ^PAuse0-G-AH1-R-W-O-R-U1-U1-N-D-TH-O-R-W-O-R-PAuse1-M-AW1-H-H-T ...
; ... -PAuse0-O2-O2-I3-I3-H-H-PAuse0-U1-U1-N-Z-Y-H-T-B-AW1-R-PAuse1-^PAuse0
LC9B4:  DB      $2B
        DB      $83,$1C,$15,$2B,$2D,$26,$2B,$37
        DB      $37,$0D,$1E,$39,$26,$2B,$2D,$26
        DB      $2B,$3E,$0C,$13,$1B,$1B,$2A,$03
        DB      $34,$34,$09,$09,$1B,$1B,$03,$37
        DB      $37,$0D,$12,$29,$1B,$2A,$0E,$13
        DB      $2B,$3E,$83

; GERMAN String $33 = ""
; Data = ^PAuse0-TH-O-R-W-O-R-PAuse1-Y-S-T-B-L-U1-U1-T-R-O-O-T-PAuse0 ...
; ... -G-A1-M-M-AH2-E1-N-N-U1-U1-N-D-H-U1-U1-NG-G-R-Y-G-AW1-U1-F ...
; ... -K-R-AW1-F-T-N-AW1-R-W-NG-PAuse1-^PAuse0
LC9E0:  DB      $38
        DB      $83,$39,$26,$2B,$2D,$26,$2B,$3E
        DB      $29,$1F,$2A,$0E,$18,$37,$37,$2A
        DB      $2B,$26,$26,$2A,$03,$1C,$06,$0C
        DB      $0C,$08,$3C,$0D,$0D,$37,$37,$0D
        DB      $1E,$1B,$37,$37,$14,$1C,$2B,$29
        DB      $1C,$13,$37,$1D,$19,$2B,$13,$1D
        DB      $2A,$0D,$13,$2B,$2D,$14,$3E,$83

; GERMAN String $34 = ""
; Data = Z-Y-Y-PAuse0-G-E1-N-UH-U1-H-A1-R-PAuse0 ...
; ... -AW1-L-T-A1-R-SH-P-A2-A1-PAuse0-H-A1-R-PAuse0-D-A1-N-N-Y ...
; ... -H-H-K-O2-O2-M-M-E1-PAuse0-Y-M-M-E1-R-N-A2-A2-PAuse0-H-A1-R-PAuse1
LCA19:  DB      $36
        DB      $12,$29,$29,$03,$1C,$3C,$0D,$33
        DB      $37,$1B,$06,$2B,$03,$13,$18,$2A
        DB      $06,$2B,$11,$25,$05,$06,$03,$1B
        DB      $06,$2B,$03,$1E,$06,$0D,$0D,$29
        DB      $1B,$1B,$19,$34,$34,$0C,$0C,$3C
        DB      $03,$29,$0C,$0C,$3C,$2B,$0D,$05
        DB      $05,$03,$1B,$06,$2B,$3E

; GERMAN String $37 = "" (note: program uses Data $41 instead !!)
; Data = ^W-O-R-Y-ER-PAuse1-^PAuse0
LCA50:  DB      $07
        DB      $AD,$26,$2B,$29,$3A,$3E,$83

; GERMAN String $38 = ""
; Data = D-A1-R
LCA58:  DB      $03
        DB      $1E,$06,$2B

; GERMAN String $52 = ""
; Data = H-AH1-T-PAuse0-D-Y-H-H-PAuse0-G-E1-G-R-Y-L-T-T-PAuse1
LCA5C:  DB      $12
        DB      $1B,$15,$2A,$03,$1E,$29,$1B,$1B
        DB      $03,$1C,$3C,$1C,$2B,$29,$18,$2A
        DB      $2A,$3E

; GERMAN String $39 = ""
; Data = ^PAuse0-D-AW1-S-S-PAuse0-V-T-R-UH-L-A1-N-SH-V-A1-R-T-PAuse0 ...
; ... -K-Y-T-S-A1-L-T-PAuse1-^PAuse0
LCA6F:  DB      $1C
        DB      $83,$1E,$13,$1F,$1F,$03,$0F,$2A
        DB      $2B,$33,$18,$06,$0D,$11,$0F,$06
        DB      $2B,$2A,$03,$19,$29,$2A,$1F,$06
        DB      $18,$2A,$3E,$83

; GERMAN String $3A = ""
; Data = V-Y-Y-PAuse0-SH-M-AE1-K-T-PAuse0-D-Y-Y-PAuse0 ...
; ... -S-T-R-AW1-L-M-N-K-AW1-N-O2-O2-O2-N-E1-PAuse1
LCA8C:  DB      $1E
        DB      $0F,$29,$29,$03,$11,$0C,$2F,$19
        DB      $2A,$03,$1E,$29,$29,$03,$1F,$2A
        DB      $2B,$13,$18,$0C,$0D,$19,$13,$0D
        DB      $34,$34,$34,$0D,$3C,$3E

; GERMAN String $3B = ""
; Data = ^PAuse0-M-AH2-E1-N-PAuse0-T-E1-L-E1-PAuse0 ...
; ... -T-R-AH2-N-S-P-O1-O1-R-T-PAuse0-V-Y-R-D-N-O1-H-H-PAuse0 ...
; ... -SH-N-A1-L-A1-R-PAuse1-^PAuse0
LCAAB:  DB      $27
        DB      $83,$0C,$08,$3C,$0D,$03,$2A,$3C
        DB      $18,$3C,$03,$2A,$2B,$08,$0D,$1F
        DB      $25,$35,$35,$2B,$2A,$03,$0F,$29
        DB      $2B,$1E,$0D,$35,$1B,$1B,$03,$11
        DB      $0D,$06,$18,$06,$2B,$3E,$83

; GERMAN String $3C = ""
; Data = ^PAuse0-N-U1-U1-N-PAuse0-K-AY-AY-N-S-T-PAuse0 ...
; ... -D-U1-U1-D-AY-AY-N-PAuse0-G-E1-SH-M-AH2-K-K-PAuse1 ...
; ... -M-AH2-E1-N-E1-S-PAuse0-S-UH-U1-B-AY-R-S-PAuse1-^PAuse0
LCAD3:  DB      $2D
        DB      $83,$0D,$37,$37,$0D,$03,$19,$21
        DB      $21,$0D,$1F,$2A,$03,$1E,$37,$37
        DB      $1E,$21,$21,$0D,$03,$1C,$3C,$11
        DB      $0C,$08,$19,$19,$3E,$0C,$08,$3C
        DB      $0D,$3C,$1F,$03,$1F,$33,$37,$0E
        DB      $21,$2B,$1F,$3E,$83

; GERMAN String $3D = ""
; Data = AH2-E1-N-AY-S-T-AW1-G-AY-S-PAuse0 ...
; ... -T-R-A2-F-F-A1-N-V-Y-R-U1-N-S-PAuse0-V-Y-Y-D-A1-R-PAuse1
LCB01:  DB      $20
        DB      $08,$3C,$0D,$21,$1F,$2A,$13,$1C
        DB      $21,$1F,$03,$2A,$2B,$05,$1D,$1D
        DB      $06,$0D,$0F,$29,$2B,$37,$0D,$1F
        DB      $03,$0F,$29,$29,$1E,$06,$2B,$3E

; GERMAN String $3E = ""
; Data = D-AH2-E1-N-E1-PAuse0-I2-K-S-P-L-O2-O2-Z-Y-O2-O2-N-PAuse0 ...
; ... -Y-S-T-M-U1-U1-Z-Y-Y-K-PAuse0-F-IU-IU-IU-R-M-AH2-E1-N-E1-PAuse0 ...
; ... -O-O-R-AY-N-PAuse1
LCB22:  DB      $2F
        DB      $1E,$08,$3C,$0D,$3C,$03,$0A,$19
        DB      $1F,$25,$18,$34,$34,$12,$29,$34
        DB      $34,$0D,$03,$29,$1F,$2A,$0C,$37
        DB      $37,$12,$29,$29,$19,$03,$1D,$36
        DB      $36,$36,$2B,$0C,$08,$3C,$0D,$3C
        DB      $03,$26,$26,$2B,$21,$0D,$3E

; GERMAN String $3F = ""
; Data = Y-Y-H-H-PAuse0-Z-AW1-G-S-PAuse0-N-O1-H-H-M-AW1-L-PAuse1
LCB52:  DB      $12
        DB      $29,$29,$1B,$1B,$03,$12,$13,$1C
        DB      $1F,$03,$0D,$35,$1B,$1B,$0C,$13
        DB      $18,$3E

; GERMAN String $42 = ""
; Data = ^PAuse0-Z-AH2-E1-PAuse0-G-A1-V-AW1-R-N-T-T-PAuse0 ...
; ... -V-O1-O1-R-L-O2-O2-ER-D-PAuse1-D-U1-U1-N-A2-A2-PAuse0 ...
; ... -H-AE1-R-S-T-D-Y-H-H-D-E1-M-F-A1-R-L-Y-Y-S-PAuse1-^PAuse0
LCB65:  DB      $34
        DB      $83,$12,$08,$3C,$03,$1C,$06,$0F
        DB      $13,$2B,$0D,$2A,$2A,$03,$0F,$35
        DB      $35,$2B,$18,$34,$34,$3A,$1E,$3E
        DB      $1E,$37,$37,$0D,$05,$05,$03,$1B
        DB      $2F,$2B,$1F,$2A,$1E,$29,$1B,$1B
        DB      $1E,$3C,$0C,$1D,$06,$2B,$18,$29
        DB      $29,$1F,$3E,$83

; GERMAN String $43 = ""
; Data = ^PAuse0-D-AH2-E1-N-V-AY-AY-G-F-IU-Y1-R-T-PAuse0 ...
; ... -D-Y-R-A1-K-T-Y-N-S-F-A1-R-L-Y-Y-S-PAuse1-^PAuse0
LCB9A:  DB      $21
        DB      $83,$1E,$08,$3C,$0D,$0F,$21,$21
        DB      $1C,$1D,$36,$22,$2B,$2A,$03,$1E
        DB      $29,$2B,$06,$19,$2A,$29,$0D,$1F
        DB      $1D,$06,$2B,$18,$29,$29,$1F,$3E
        DB      $83

; GERMAN String $44 = ""
; Data = ^PAuse0-T-Y-Y-F-A1-R-PAuse0-Y-M-M-A1-R-T-Y-Y-F-A1-R-PAuse0 ...
; ... -Y-N-D-Y-Y-PAuse0-L-AH1-B-IU-IU-IU-I1-N-T-F-O1-N-W-O-R-PAuse1-^PAuse0
LCBBC:  DB      $2B
        DB      $83,$2A,$29,$29,$1D,$06,$2B,$03
        DB      $29,$0C,$0C,$06,$2B,$2A,$29,$29
        DB      $1D,$06,$2B,$03,$29,$0D,$1E,$29
        DB      $29,$03,$18,$15,$0E,$36,$36,$36
        DB      $0B,$0D,$2A,$1D,$35,$0D,$2D,$26
        DB      $2B,$3E,$83

; GERMAN String $45 = ""
; Data = ^PAuse0-P-AH1-S-S-PAuse0-UH-U1-U1-F-F-PAuse1 ...
; ... -D-U1-U1-B-Y-S-T-Y-N-D-A1-N-PAuse0 ...
; ... -H-O2-I3-I3-L-A1-N-F-O1-N-V-O1-O1-R-PAuse1-^PAuse0
LCBE8:  DB      $29
        DB      $83,$25,$15,$1F,$1F,$03,$33,$37
        DB      $37,$1D,$1D,$3E,$1E,$37,$37,$0E
        DB      $29,$1F,$2A,$29,$0D,$1E,$06,$0D
        DB      $03,$1B,$34,$09,$09,$18,$06,$0D
        DB      $1D,$35,$0D,$0F,$35,$35,$2B,$3E
        DB      $83

; GERMAN String $46 = ""
; Data = ^PAuse0-AH-H-PAuse1-D-U1-U1-V-Y-L-L-S-T-D-Y-H-H-V-O2-O2-L-PAuse0 ...
; ... -F-A1-R-S-T-AE1-K-K-A1-N-PAuse1-AH-B-A1-R-PAuse0 ...
; ... -Y-H-H-B-Y-N-D-A1-R-PAuse0 ...
; ... -H-O2-I3-I3-L-A1-N-M-AH2-E1-S-T-A1-R-PAuse1-^PAuse0
LCC12:  DB      $40
        DB      $83,$24,$1B,$3E,$1E,$37,$37,$0F
        DB      $29,$18,$18,$1F,$2A,$1E,$29,$1B
        DB      $1B,$0F,$34,$34,$18,$03,$1D,$06
        DB      $2B,$1F,$2A,$2F,$19,$19,$06,$0D
        DB      $3E,$24,$0E,$06,$2B,$03,$29,$1B
        DB      $1B,$0E,$29,$0D,$1E,$06,$2B,$03
        DB      $1B,$34,$09,$09,$18,$06,$0D,$0C
        DB      $08,$3C,$1F,$2A,$06,$2B,$3E,$83

; GERMAN String $47 = ""
; Data = ^PAuse0-TH-O-O1-R-PAuse0-B-ER-R-PAuse0-G-AH-R-PAuse1 ...
; ... -A2-S-S-A1-N-Y-S-T-F-A1-R-T-Y-G-PAuse1-^PAuse0
LCC53:  DB      $1E
        DB      $83,$39,$26,$35,$2B,$03,$0E,$3A
        DB      $2B,$03,$1C,$24,$2B,$3E,$05,$1F
        DB      $1F,$06,$0D,$29,$1F,$2A,$1D,$06
        DB      $2B,$2A,$29,$1C,$3E,$83

; GERMAN String $48 = ""
; Data = H-vA-vI1-vY1-PAuse1-PAuse1 ...
; ... -S-Y-Y-T-D-Y-Y-Z-Y-Y-B-A1-N-M-AH2-E1-L-A1-N-PAuse0 ...
; ... -SH-T-Y-Y-F-AY-L-PAuse0-AW1-N-N-PAuse1
LCC72:  DB      $26
        DB      $1B,$60,$4B,$62,$3E,$3E,$1F,$29
        DB      $29,$2A,$1E,$29,$29,$12,$29,$29
        DB      $0E,$06,$0D,$0C,$08,$3C,$18,$06
        DB      $0D,$03,$11,$2A,$29,$29,$1D,$21
        DB      $18,$03,$13,$0D,$0D,$3E

; GERMAN String $49 = ""
; Data = ^PAuse0-M-AH2-E1-N-E1-B-Y-Y-S-T-A1-R-PAuse0 ...
; ... -R-A1-N-N-A1-N-V-Y-Y-V-Y-L-D-PAuse0 ...
; ... -D-U1-U1-R-H-D-Y-Y-H-O2-I3-I3-L-AY-N-D-A1-S ...
; ... -V-O2-O1-O1-R-L-O1-R-D-S-PAuse1-^PAuse0
LCC99:  DB      $3A
        DB      $83,$0C,$08,$3C,$0D,$3C,$0E,$29
        DB      $29,$1F,$2A,$06,$2B,$03,$2B,$06
        DB      $0D,$0D,$06,$0D,$0F,$29,$29,$0F
        DB      $29,$18,$1E,$03,$1E,$37,$37,$2B
        DB      $1B,$1E,$29,$29,$1B,$34,$09,$09
        DB      $18,$21,$0D,$1E,$06,$1F,$0F,$34
        DB      $35,$35,$2B,$18,$35,$2B,$1E,$1F
        DB      $3E,$83

; GERMAN String $4A = ""
; Data = D-Y-Y-R-B-L-AH2-E1-B-T-T-PAuse0 ...
; ... -K-AH2-E1-N-E1-AH2-AH2-N-D-R-AY-PAuse0-V-AH-L-PAuse1 ...
; ... -^T-AH2-AH2-N-S-AY-PAuse0-O-D-A1-R-PAuse0-L-AH2-E1-D-AY-PAuse0 ...
; ... -K-V-V-AH-L-PAuse1-^PAuse0
LCCD4:  DB      $35
        DB      $1E,$29,$29,$2B,$0E,$18,$08,$3C
        DB      $0E,$2A,$2A,$03,$19,$08,$3C,$0D
        DB      $3C,$08,$08,$0D,$1E,$2B,$21,$03
        DB      $0F,$24,$18,$3E,$AA,$08,$08,$0D
        DB      $1F,$21,$03,$26,$1E,$06,$2B,$03
        DB      $18,$08,$3C,$1E,$21,$03,$19,$0F
        DB      $0F,$24,$18,$3E,$83

; GERMAN String $4B = "" (longest line here??)
; Data = ^PAuse0-N-U1-N-M-U1-U1-S-^T-D-U1-U1-D-AH2-E1-N-PAuse0 ...
; ... -B-A2-S-T-AY-S-^PAuse0-G-AY-AY-B-A1-N-PAuse1-Z-O1-N-S-T-PAuse0 ...
; ... -V-Y-R-S-T-^D-U1-U1-N-Y-H-H-T-PAuse0 ...
; ... -IU-Y1-B-A1-R-^L-AY-AY-B-A1-N-PAuse1-PAuse0
LCD0A:  DB      $40
        DB      $83,$0D,$37,$0D,$0C,$37,$37,$1F
        DB      $AA,$1E,$37,$37,$1E,$08,$3C,$0D
        DB      $03,$0E,$05,$1F,$2A,$21,$1F,$83
        DB      $1C,$21,$21,$0E,$06,$0D,$3E,$12
        DB      $35,$0D,$1F,$2A,$03,$0F,$29,$2B
        DB      $1F,$2A,$9E,$37,$37,$0D,$29,$1B
        DB      $1B,$2A,$03,$36,$22,$0E,$06,$2B
        DB      $98,$21,$21,$0E,$06,$0D,$3E,$03

; GERMAN String $4C = ""
; Data = H-O1-P-L-AW1-PAuse1-PAuse1-Y-H-H-PAuse0 ...
; ... -H-AW1-B-AY-D-Y-V-AE1-N-D-AY-PAuse0-F-A1-R-G-AY-S-A1-N-PAuse1
LCD4B:  DB      $20
        DB      $1B,$35,$25,$18,$13,$3E,$3E,$29
        DB      $1B,$1B,$03,$1B,$13,$0E,$21,$1E
        DB      $29,$0F,$2F,$0D,$1E,$21,$03,$1D
        DB      $06,$2B,$1C,$21,$1F,$06,$0D,$3E

; GERMAN String $4D = ""
; Data = ^PAuse0-V-O-O-PAuse0-S-Y-L-S-T-PAuse0-D-U1-U1-D-Y-H-H-PAuse0 ...
; ... -F-A1-R-S-T-T-AE1-K-K-A1-N-PAuse1-^PAuse0
LCD6C:  DB      $20
        DB      $83,$0F,$26,$26,$03,$1F,$29,$18
        DB      $1F,$2A,$03,$1E,$37,$37,$1E,$29
        DB      $1B,$1B,$03,$1D,$06,$2B,$1F,$2A
        DB      $2A,$2F,$19,$19,$06,$0D,$3E,$83
; end of GERMAN Speech strings

; 84 GERMAN's Speech String pointers !!
; as pointed to by LC000:
; and Indexed by GERMAN Phrase Data below
LCD8D:  DW      LC200           ; GERMAN Speech String $00 = ""
        DW      LC22A           ; GERMAN Speech String $01 = ""
        DW      LC26C           ; GERMAN Speech String $02 = ""
        DW      LC307           ; GERMAN Speech String $03 = ""
        DW      LC284           ; GERMAN Speech String $04 = ""
        DW      LC294           ; GERMAN Speech String $05 = ""
        DW      LC2BE           ; GERMAN Speech String $06 = ""
        DW      LC2E3           ; GERMAN Speech String $07 = ""
        DW      LC441           ; GERMAN Speech String $08 = ""
        DW      LC462           ; GERMAN Speech String $09 = "" (substitute $40)
        DW      LC5BA           ; GERMAN Speech String $0A = ""
        DW      LC5D0           ; GERMAN Speech String $0B = ""
        DW      LC5E0           ; GERMAN Speech String $0C = ""
        DW      LC5F4           ; GERMAN Speech String $0D = ""
        DW      LC600           ; GERMAN Speech String $0E = ""
        DW      LC632           ; GERMAN Speech String $0F = ""
        DW      LC65E           ; GERMAN Speech String $10 = ""
        DW      LC669           ; GERMAN Speech String $11 = ""
        DW      LC694           ; GERMAN Speech String $12 = ""
        DW      LC6C4           ; GERMAN Speech String $13 = ""
        DW      LC6F6           ; GERMAN Speech String $14 = ""
        DW      LC716           ; GERMAN Speech String $15 = ""
        DW      LC753           ; GERMAN Speech String $16 = ""
        DW      LC789           ; GERMAN Speech String $17 = ""
        DW      LC7BE           ; GERMAN Speech String $18 = ""
        DW      LC7F2           ; GERMAN Speech String $19 = ""
        DW      LC469           ; GERMAN Speech String $1A = ""
        DW      LC42E           ; GERMAN Speech String $1B = ""
        DW      LC49C           ; GERMAN Speech String $1C = ""
        DW      LC4D3           ; GERMAN Speech String $1D = ""
        DW      LC504           ; GERMAN Speech String $1E = ""
        DW      LC529           ; GERMAN Speech String $1F = ""
        DW      LC588           ; GERMAN Speech String $20 = ""
        DW      LC559           ; GERMAN Speech String $21 = ""
        DW      LC311           ; GERMAN Speech String $22 = ""
        DW      LC33E           ; GERMAN Speech String $23 = ""
        DW      LC364           ; GERMAN Speech String $24 = ""
        DW      LC3A5           ; GERMAN Speech String $25 = ""
        DW      LC3DE           ; GERMAN Speech String $26 = ""
        DW      LC3FB           ; GERMAN Speech String $27 = ""
        DW      LC9B4           ; GERMAN Speech String $28 = ""
        DW      LC804           ; GERMAN Speech String $29 = ""
        DW      LC82E           ; GERMAN Speech String $2A = ""
        DW      LC850           ; GERMAN Speech String $2B = ""
        DW      LC88E           ; GERMAN Speech String $2C = ""
        DW      LC8B7           ; GERMAN Speech String $2D = ""
        DW      LC8D5           ; GERMAN Speech String $2E = ""
        DW      LC90B           ; GERMAN Speech String $2F = ""
        DW      LC93B           ; GERMAN Speech String $30 = ""
        DW      LC965           ; GERMAN Speech String $31 = ""
        DW      LC984           ; GERMAN Speech String $32 = ""
        DW      LC9E0           ; GERMAN Speech String $33 = ""
        DW      LCA19           ; GERMAN Speech String $34 = ""
        DW      LC485           ; GERMAN Speech String $35 = ""
        DW      LC6B8           ; GERMAN Speech String $36 = ""
        DW      LCA50           ; GERMAN Speech String $37 = "" (use $41 below)
        DW      LCA58           ; GERMAN Speech String $38 = ""
        DW      LCA6F           ; GERMAN Speech String $39 = ""
        DW      LCA8C           ; GERMAN Speech String $3A = ""
        DW      LCAAB           ; GERMAN Speech String $3B = ""
        DW      LCAD3           ; GERMAN Speech String $3C = ""
        DW      LCB01           ; GERMAN Speech String $3D = ""
        DW      LCB22           ; GERMAN Speech String $3E = ""
        DW      LCB52           ; GERMAN Speech String $3F = ""
        DW      LC73F           ; GERMAN Speech String $40 = ""
        DW      LC748           ; GERMAN Speech String $41 = ""
        DW      LCB65           ; GERMAN Speech String $42 = ""
        DW      LCB9A           ; GERMAN Speech String $43 = ""
        DW      LCBBC           ; GERMAN Speech String $44 = ""
        DW      LCBE8           ; GERMAN Speech String $45 = ""
        DW      LCC12           ; GERMAN Speech String $46 = ""
        DW      LCC53           ; GERMAN Speech String $47 = ""
        DW      LCC72           ; GERMAN Speech String $48 = ""
        DW      LCC99           ; GERMAN Speech String $49 = ""
        DW      LCCD4           ; GERMAN Speech String $4A = ""
        DW      LCD0A           ; GERMAN Speech String $4B = ""
        DW      LCD4B           ; GERMAN Speech String $4C = ""
        DW      LCD6C           ; GERMAN Speech String $4D = ""
        DW      LC25B           ; GERMAN Speech String $4E = ""
        DW      $0000           ; entry $4F not used !!
        DW      LC279           ; GERMAN Speech String $50 = ""
        DW      LC574           ; GERMAN Speech String $51 = ""
        DW      LCA5C           ; GERMAN Speech String $52 = ""
        DW      LC7F6           ; GERMAN Speech String $53 = ""
; end of GERMAN Speech String pointers

;**********************************************************
; 80-entry GERMAN Phrase Data table here
; as pointed to by LC002:
; Index(s) to one or more Speech String pointers above
; matches the Original English mostly, extra or less!
; **********************************************************
; Length bytes have bit 7 Flagged as start
;
LCE35:  DB      $81,$0A         ; GERMAN Phrase $00 = ""
        DB      $82,$0B,$04     ; GERMAN Phrase $01 = ""
        DB      $81,$0A         ; GERMAN Phrase $02 = ""
        DB      $82,$0C,$10     ; GERMAN Phrase $03 = ""
        DB      $81,$0A         ; GERMAN Phrase $04 = ""
        DB      $82,$0B,$04     ; GERMAN Phrase $05 = ""
        DB      $81,$0A         ; GERMAN Phrase $06 = ""
        DB      $82,$0C,$10     ; GERMAN Phrase $07 = ""
        DB      $82,$0D,$09     ; GERMAN Phrase $08 = ""
        DB      $81,$0E         ; GERMAN Phrase $09 = "" (less phrases!)
        DB      $81,$0F         ; GERMAN Phrase $0A = ""
        DB      $82,$11,$10     ; GERMAN Phrase $0B = ""
        DB      $82,$1E,$36     ; GERMAN Phrase $0C = ""
        DB      $81,$2D         ; GERMAN Phrase $0D = ""
        DB      $82,$2E,$10     ; GERMAN Phrase $0E = ""
        DB      $82,$2F,$10     ; GERMAN Phrase $0F = ""
        DB      $81,$00         ; GERMAN Phrase $10 = "" NOT empty !!
        DB      $83,$4E,$02,$50 ; GERMAN Phrase $11 = "" (extra phrase)
        DB      $82,$03,$04     ; GERMAN Phrase $12 = ""
        DB      $82,$05,$10     ; GERMAN Phrase $13 = ""
        DB      $81,$06         ; GERMAN Phrase $14 = ""
        DB      $81,$07         ; GERMAN Phrase $15 = ""
        DB      $82,$08,$37     ; GERMAN Phrase $16 = ""
        DB      $82,$33,$36     ; GERMAN Phrase $17 = ""
        DB      $81,$23         ; GERMAN Phrase $18 = ""
        DB      $82,$24,$36     ; GERMAN Phrase $19 = ""
        DB      $82,$27,$36     ; GERMAN Phrase $1A = ""
        DB      $82,$25,$36     ; GERMAN Phrase $1B = ""
        DB      $82,$30,$36     ; GERMAN Phrase $1C = ""
        DB      $82,$31,$09     ; GERMAN Phrase $1D = ""
        DB      $81,$32         ; GERMAN Phrase $1E = ""
        DB      $81,$1D         ; GERMAN Phrase $1F = ""
        DB      $82,$12,$36     ; GERMAN Phrase $20 = ""
        DB      $81,$13         ; GERMAN Phrase $21 = ""
        DB      $81,$14         ; GERMAN Phrase $22 = ""
        DB      $82,$15,$40     ; GERMAN Phrase $23 = ""
        DB      $82,$37,$26     ; GERMAN Phrase $24 = ""
        DB      $82,$34,$10     ; GERMAN Phrase $25 = ""
        DB      $83,$09,$22,$10 ; GERMAN Phrase $26 = ""
        DB      $82,$35,$37     ; GERMAN Phrase $27 = ""
        DB      $82,$1A,$36     ; GERMAN Phrase $28 = ""
        DB      $81,$1B         ; GERMAN Phrase $29 = ""
        DB      $82,$1C,$36     ; GERMAN Phrase $2A = ""
        DB      $82,$01,$36     ; GERMAN Phrase $2B = ""
        DB      $82,$1F,$09     ; GERMAN Phrase $2C = ""
        DB      $82,$09,$20     ; GERMAN Phrase $2D = ""
        DB  $84,$21,$02,$51,$36 ; GERMAN Phrase $2E = "" (extra phrases)
        DB      $82,$28,$36     ; GERMAN Phrase $2F = ""
        DB      $82,$16,$10     ; GERMAN Phrase $30 = "" (less phrase!)
        DB      $82,$17,$37     ; GERMAN Phrase $31 = ""
        DB      $82,$18,$37     ; GERMAN Phrase $32 = ""
        DB      $83,$19,$04,$53 ; GERMAN Phrase $33 = "" (extra)
        DB      $82,$29,$37     ; GERMAN Phrase $34 = ""
        DB      $81,$2A         ; GERMAN Phrase $35 = ""
        DB      $82,$2B,$36     ; GERMAN Phrase $36 = ""
        DB      $81,$2C         ; GERMAN Phrase $37 = ""
        DB  $84,$38,$04,$52,$10 ; GERMAN Phrase $38 = "" (extra)
        DB      $83,$39,$37,$36 ; GERMAN Phrase $39 = ""
        DB      $82,$3A,$10     ; GERMAN Phrase $3A = ""
        DB      $82,$3B,$36     ; GERMAN Phrase $3B = ""
        DB      $82,$3C,$37     ; GERMAN Phrase $3C = ""
        DB      $81,$3D         ; GERMAN Phrase $3D = "" (less!)
        DB      $82,$3E,$10     ; GERMAN Phrase $3E = ""
        DB      $83,$3F,$34,$10 ; GERMAN Phrase $3F = ""
        DB      $82,$42,$36     ; GERMAN Phrase $40 = "" (less!)
        DB      $83,$41,$43,$36 ; GERMAN Phrase $41 = ""
        DB      $82,$44,$36     ; GERMAN Phrase $42 = "" (less!)
        DB      $81,$45         ; GERMAN Phrase $43 = ""
        DB      $82,$46,$36     ; GERMAN Phrase $44 = ""
        DB      $82,$47,$36     ; GERMAN Phrase $45 = ""
        DB      $82,$48,$10     ; GERMAN Phrase $46 = ""
        DB      $82,$49,$36     ; GERMAN Phrase $47 = ""
        DB      $82,$4A,$36     ; GERMAN Phrase $48 = ""
        DB      $82,$4B,$10     ; GERMAN Phrase $49 = ""
        DB      $82,$4C,$10     ; GERMAN Phrase $4A = ""
        DB      $83,$41,$4D,$36 ; GERMAN Phrase $4B = "" (extra)
        DB      $82,$4A,$36     ; GERMAN Phrase $4C = ""
        DB      $82,$4B,$10     ; GERMAN Phrase $4D = ""
        DB      $82,$4C,$10     ; GERMAN Phrase $4E = ""
        DB      $83,$41,$4D,$36 ; GERMAN Phrase $4F = "" (extra)
        DB      $B6             ; ?? junk ??
; end of GERMAN Phrase Data table

; crap: ÿ 0FP? something illegal even in a comment ??

; LCF1E: filler
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
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF

; LCFEB: for ROM Identification only
        DB      "GERMAN WIZARD",$00
; LCFF9:
        DB      "DNA",$00       ; Copyright: Dave Nutting Associates
; LCFFD:
        DB      $04,$30,$81     ; could be the Date 4/30/1981

; LD000:
        END

