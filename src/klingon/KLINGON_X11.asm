; KLINGON_X11.asm
;==============================================================================
; Wizard of Wor - Klingon X11 foreign-language ROM
;==============================================================================
;
; This source is deliberately conservative:
;   - one ORG at $C000, then contiguous data through $CFFF;
;   - DB/DW-only payload: no quoted strings or assembler fill assumptions;
;   - 79 fragment IDs $00-$4E aligned with the resident English fragment map;
;   - exact resident English 80-entry phrase composition;
;   - direct SC-01 low-six-bit phoneme bytes in the ROM speech records;
;   - no synthetic prefix/suffix phonemes and no embedded STOP commands;
;   - slots $4F-$53 are null;
;   - build verifies the assembled checksum but never patches it.
;
; Play_Next_Phoneme XORs only the saved bit-7 inflection state. Stored bit 7 is
; zero in this baseline, so the prior state is preserved while bits 0-5 pass
; through unchanged. This avoids the incorrect $83 framing used by the broken
; prototype.
;==============================================================================

        NOLIST
        LIST
        ORG     $C000

XFPTR:
        DW      KPTRS
XPPTR:
        DW      KPHRASE
XCOIN:
        DB      $10,$20,$30,$40,$70,$50
XCSUM:
        DB      $00
XFONTP:
        DW      KFONT

; 23 length-prefixed localized display records.
KTEXT:
; Text $01: INSERT COIN
; tlhIngan Hol: Huch yIlan
        DB      $0A,$48,$55,$43,$48,$40,$59,$49,$4C,$41,$4E
; Text $02: HIGH SCORES
; tlhIngan Hol: mIvwa' nIv
        DB      $09,$4D,$49,$56,$57,$41,$40,$4E,$49,$56
; Text $03: PRESS ONE PLAYER BUTTON
; tlhIngan Hol: wa' QujwI' DuQwI' yIyuv
        DB      $14,$57,$41,$40,$51,$55,$4A,$57,$49,$40,$44,$55
        DB      $51,$57,$49,$40,$59,$49,$59,$55,$56
; Text $04: PRESS TWO PLAYER BUTTON
; tlhIngan Hol: cha' QujwI' DuQwI' yIyuv
        DB      $15,$43,$48,$41,$40,$51,$55,$4A,$57,$49,$40,$44
        DB      $55,$51,$57,$49,$40,$59,$49,$59,$55,$56
; Text $05: OR
; tlhIngan Hol: ghap
        DB      $04,$47,$48,$41,$50
; Text $06: DEPOSIT ADDITIONAL COIN
; tlhIngan Hol: latlh Huch yIlan
        DB      $10,$4C,$41,$54,$4C,$48,$40,$48,$55,$43,$48,$40
        DB      $59,$49,$4C,$41,$4E
; Text $07: FOR TWO PLAYER GAME
; tlhIngan Hol: cha' QujwI' QujmeH
        DB      $10,$43,$48,$41,$40,$51,$55,$4A,$57,$49,$40,$51
        DB      $55,$4A,$4D,$45,$48
; Text $08: POINTS
; tlhIngan Hol: mIvwa'
        DB      $05,$4D,$49,$56,$57,$41
; Text $09: BONUS PLAYER
; tlhIngan Hol: latlh QujwI'
        DB      $0B,$4C,$41,$54,$4C,$48,$40,$51,$55,$4A,$57,$49
; Text $0A: WAIT FOR INSTRUCTIONS
; tlhIngan Hol: ra'mey yIloS
        DB      $0B,$52,$41,$4D,$45,$59,$40,$59,$49,$4C,$4F,$53
; Text $0B: INVISIBLE MONSTERS IN THE MAZE
; tlhIngan Hol: He QatlhDaq So' Ha'DIbaHmey
        DB      $19,$48,$45,$40,$51,$41,$54,$4C,$48,$44,$41,$51
        DB      $40,$53,$4F,$40,$48,$41,$44,$49,$42,$41,$48,$4D
        DB      $45,$59
; Text $0C: ARE LOCATED USING THE RADAR SCREEN
; tlhIngan Hol: HotlhwI' lo'lu'; Samlu'
        DB      $12,$48,$4F,$54,$4C,$48,$57,$49,$40,$4C,$4F,$4C
        DB      $55,$40,$53,$41,$4D,$4C,$55
; Text $0D: MONSTERS BECOME VISIBLE WHEN ENTERING
; tlhIngan Hol: 'elDI' Ha'DIbaHmey leghlu'
        DB      $16,$45,$4C,$44,$49,$40,$48,$41,$44,$49,$42,$41
        DB      $48,$4D,$45,$59,$40,$4C,$45,$47,$48,$4C,$55
; Text $0E: THE SAME MAZE CORRIDOR AS THE PLAYER
; tlhIngan Hol: QujwI' He'egh lu'el
        DB      $10,$51,$55,$4A,$57,$49,$40,$48,$45,$45,$47,$48
        DB      $40,$4C,$55,$45,$4C
; Text $0F: GET READY
; tlhIngan Hol: yIghuH
        DB      $06,$59,$49,$47,$48,$55,$48
; Text $10: RADAR
; tlhIngan Hol: HotlhwI'
        DB      $05,$52,$41,$44,$41,$52
; Text $11: ESCAPED
; tlhIngan Hol: nargh
        DB      $05,$4E,$41,$52,$47,$48
; Text $12: CREDITS
; tlhIngan Hol: Huch
        DB      $04,$48,$55,$43,$48
; Text $13: DUNGEON
; tlhIngan Hol: bIghHa'
        DB      $06,$42,$49,$47,$48,$48,$41
; Text $14: WORLORD DUNGEON
; tlhIngan Hol: SuvwI' joH bIghHa'
        DB      $10,$53,$55,$56,$57,$49,$40,$4A,$4F,$48,$40,$42
        DB      $49,$47,$48,$48,$41
; Text $15: THE ARENA
; tlhIngan Hol: SuvmeH Daq
        DB      $06,$53,$55,$56,$44,$41,$51
; Text $16: THE PIT
; tlhIngan Hol: QemjIq
        DB      $06,$51,$45,$4D,$4A,$49,$51
; Text $17: OR FOR ADDITIONAL WORRIORS
; tlhIngan Hol: qoj latlh SuvwI'
        DB      $0F,$51,$4F,$4A,$40,$4C,$41,$54,$4C,$48,$40,$53
        DB      $55,$56,$57,$49

; Erased text/font gap: $C135-$C1D0 (156 bytes)
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
KALIGN:
        DB      $00
KFONT:
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Klingon speech fragments. Count byte is not part of the SC-01 stream.

; $00 English semantic: Kill Worluk for double score
; tlhIngan Hol: Worluk yIHoH. cha'logh mIvwa' DaSuq.
KSP00:
        DB      $22
        DB      $2D,$26,$2B,$18,$28,$19,$03,$29,$27,$1B,$26,$1B,$3E,$2A,$10,$15
        DB      $03,$18,$26,$1C,$1B,$03,$0C,$27,$0F,$2D,$15,$03,$1E,$15,$11,$28
        DB      $19,$3E

; $01 English semantic: If you get too powerful, I'll take care of you myself
; tlhIngan Hol: bIHoSghajqu'chugh, qamevmoH jIH.
KSP01:
        DB      $21
        DB      $0E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19,$28,$03,$2A,$10,$28
        DB      $1C,$1B,$03,$19,$15,$0C,$3B,$0F,$0C,$26,$1B,$03,$1E,$1A,$27,$1B
        DB      $3E

; $02 English semantic: The dungeons of Wor
; tlhIngan Hol: Wor bIghHa'mey.
KSP02:
        DB      $0F
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$3E

; $03 English semantic: I am
; tlhIngan Hol: jIH.
KSP03:
        DB      $05
        DB      $1E,$1A,$27,$1B,$3E

; $04 English semantic: The Wizard of Wor
; tlhIngan Hol: Wor 'IDnar pIn.
KSP04:
        DB      $0E
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15,$2B,$03,$25,$27,$0D,$3E

; $05 English semantic: One bite from my pretties, and you'll explode
; tlhIngan Hol: DuchopDI' ghumeywIj, bIjor.
KSP05:
        DB      $1B
        DB      $1E,$28,$2A,$10,$26,$25,$1E,$27,$03,$1C,$1B,$28,$0C,$3B,$29,$2D
        DB      $27,$1E,$1A,$03,$0E,$27,$1E,$1A,$26,$2B,$3E

; $06 English semantic: My creatures are radioactive
; tlhIngan Hol: Qob Ha'DIbaHmeywIj.
KSP06:
        DB      $15
        DB      $19,$1B,$26,$0E,$03,$1B,$15,$03,$1E,$27,$0E,$15,$1B,$0C,$3B,$29
        DB      $2D,$27,$1E,$1A,$3E

; $07 English semantic: Worluk will escape through the door
; tlhIngan Hol: lojmIt vegh Worluk 'ej nargh.
KSP07:
        DB      $1E
        DB      $18,$26,$1E,$1A,$0C,$27,$2A,$03,$0F,$3B,$1C,$1B,$03,$2D,$26,$2B
        DB      $18,$28,$19,$03,$3B,$1E,$1A,$03,$0D,$15,$2B,$1C,$1B,$3E

; $08 English semantic: Watch the radar
; tlhIngan Hol: HotlhwI' yIbej.
KSP08:
        DB      $0F
        DB      $1B,$26,$2A,$18,$1B,$2D,$27,$03,$29,$27,$0E,$3B,$1E,$1A,$3E

; $09 English semantic: Worrior
; tlhIngan Hol: SuvwI'.
KSP09:
        DB      $07
        DB      $11,$28,$0F,$2D,$27,$03,$3E

; $0A English semantic: Hey, insert coin
; tlhIngan Hol: Huch yIlan.
KSP0A:
        DB      $0B
        DB      $1B,$28,$2A,$10,$03,$29,$27,$18,$15,$0D,$3E

; $0B English semantic: Find me
; tlhIngan Hol: HISam.
KSP0B:
        DB      $06
        DB      $1B,$27,$11,$15,$0C,$3E

; $0C English semantic: I'm out of spite
; tlhIngan Hol: jISo'.
KSP0C:
        DB      $07
        DB      $1E,$1A,$27,$11,$26,$03,$3E

; $0D English semantic: Get ready
; tlhIngan Hol: yIghuH.
KSP0D:
        DB      $07
        DB      $29,$27,$1C,$1B,$28,$1B,$3E

; $0E English semantic: You'd better hope you don't find me
; tlhIngan Hol: HISambe' 'e' yItul.
KSP0E:
        DB      $10
        DB      $1B,$27,$11,$15,$0C,$0E,$3B,$03,$3B,$03,$29,$27,$2A,$28,$18,$3E

; $0F English semantic: Another coin for my treasure chest
; tlhIngan Hol: latlh Huch vIHev.
KSP0F:
        DB      $11
        DB      $18,$15,$2A,$18,$1B,$03,$1B,$28,$2A,$10,$03,$0F,$27,$1B,$3B,$0F
        DB      $3E

; $10 English semantic: Ha ha ha ha
; tlhIngan Hol: Ha ha ha ha!
KSP10:
        DB      $0C
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15,$03,$1B,$15,$3E

; $11 English semantic: Ah good! My pets were getting hungry
; tlhIngan Hol: maj! ghumeywIj ghungqu'.
KSP11:
        DB      $18
        DB      $0C,$15,$1E,$1A,$3E,$1C,$1B,$28,$0C,$3B,$29,$2D,$27,$1E,$1A,$03
        DB      $1C,$1B,$28,$14,$19,$28,$03,$3E

; $12 English semantic: You'll get the Arena
; tlhIngan Hol: SuvmeH DaqDaq bIghoS.
KSP12:
        DB      $15
        DB      $11,$28,$0F,$0C,$3B,$1B,$03,$1E,$15,$19,$1E,$15,$19,$03,$0E,$27
        DB      $1C,$1B,$26,$11,$3E

; $13 English semantic: Another worrior for my babies to devour
; tlhIngan Hol: latlh SuvwI' luSop ghumeywIj.
KSP13:
        DB      $1D
        DB      $18,$15,$2A,$18,$1B,$03,$11,$28,$0F,$2D,$27,$03,$18,$28,$11,$26
        DB      $25,$03,$1C,$1B,$28,$0C,$3B,$29,$2D,$27,$1E,$1A,$3E

; $14 English semantic: Keep going and you will find me
; tlhIngan Hol: yItaH; HISam.
KSP14:
        DB      $0C
        DB      $29,$27,$2A,$15,$1B,$03,$1B,$27,$11,$15,$0C,$3E

; $15 English semantic: A few more dungeons and you'll be a
; tlhIngan Hol: latlh bIghHa'mey puS Daju'DI',
KSP15:
        DB      $1F
        DB      $18,$15,$2A,$18,$1B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29
        DB      $03,$25,$28,$11,$03,$1E,$15,$1E,$1A,$28,$03,$1E,$27,$03,$3E

; $16 English semantic: Come back for more with
; tlhIngan Hol: latlh Qu'vaD yIchegh.
KSP16:
        DB      $16
        DB      $18,$15,$2A,$18,$1B,$03,$19,$1B,$28,$03,$0F,$15,$1E,$03,$29,$27
        DB      $2A,$10,$3B,$1C,$1B,$3E

; $17 English semantic: The dungeons of Wor await your return
; tlhIngan Hol: Wor bIghHa'meyDaq bIchegh.
KSP17:
        DB      $1A
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$0E,$27,$2A,$10,$3B,$1C,$1B,$3E

; $18 English semantic: Deep in the caverns of Wor, you will meet me
; tlhIngan Hol: Wor DISmeyDaq HISam.
KSP18:
        DB      $14
        DB      $2D,$26,$2B,$03,$1E,$27,$11,$0C,$3B,$29,$1E,$15,$19,$03,$1B,$27
        DB      $11,$15,$0C,$3E

; $19 English semantic: thanks you
; tlhIngan Hol: Dutlho'.
KSP19:
        DB      $08
        DB      $1E,$28,$2A,$18,$1B,$26,$03,$3E

; $1A English semantic: Now you get the heavyweights
; tlhIngan Hol: SuvwI'pu' HoSghaj DaSuv.
KSP1A:
        DB      $18
        DB      $11,$28,$0F,$2D,$27,$03,$25,$28,$03,$1B,$26,$11,$1C,$1B,$15,$1E
        DB      $1A,$03,$1E,$15,$11,$28,$0F,$3E

; $1B English semantic: Garwor, go after them
; tlhIngan Hol: Garwor, yIHIv!
KSP1B:
        DB      $0D
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$29,$27,$1B,$27,$0F,$3E

; $1C English semantic: If you try any harder, you'll only meet with doom
; tlhIngan Hol: latlh DanIDchugh, bIHegh.
KSP1C:
        DB      $18
        DB      $18,$15,$2A,$18,$1B,$03,$1E,$15,$0D,$27,$1E,$2A,$10,$28,$1C,$1B
        DB      $03,$0E,$27,$1B,$3B,$1C,$1B,$3E

; $1D English semantic: Burwor, Garwor, and Thorwor will do you in
; tlhIngan Hol: Burwor Garwor Thorwor je DuHoH.
KSP1D:
        DB      $20
        DB      $0E,$28,$2B,$2D,$26,$2B,$03,$1C,$15,$2B,$2D,$26,$2B,$03,$2A,$1B
        DB      $26,$2B,$2D,$26,$2B,$03,$1E,$1A,$3B,$03,$1E,$28,$1B,$26,$1B,$3E

; $1E English semantic: My worlings are very very hungry
; tlhIngan Hol: SuvwI'HommeywIj ghungqu'.
KSP1E:
        DB      $19
        DB      $11,$28,$0F,$2D,$27,$03,$1B,$26,$0C,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $03,$1C,$1B,$28,$14,$19,$28,$03,$3E

; $1F English semantic: My magic is stronger than your weapons
; tlhIngan Hol: 'IDnarwIj HoS law' nuHmeylIj HoS puS.
KSP1F:
        DB      $26
        DB      $03,$27,$1E,$0D,$15,$2B,$2D,$27,$1E,$1A,$03,$1B,$26,$11,$03,$18
        DB      $15,$2D,$03,$0D,$28,$1B,$0C,$3B,$29,$18,$27,$1E,$1A,$03,$1B,$26
        DB      $11,$03,$25,$28,$11,$3E

; $20 English semantic: While you developed science, we developed magic
; tlhIngan Hol: QeD Daghoj; 'IDnar wIghoj.
KSP20:
        DB      $1B
        DB      $19,$1B,$3B,$1E,$03,$1E,$15,$1C,$1B,$26,$1E,$1A,$03,$27,$1E,$0D
        DB      $15,$2B,$03,$2D,$27,$1C,$1B,$26,$1E,$1A,$3E

; $21 English semantic: Your bones will lie in the dungeons of Wor
; tlhIngan Hol: Wor bIghHa'meyDaq HomDu'lIj tu'lu'.
KSP21:
        DB      $24
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$1E,$15
        DB      $19,$03,$1B,$26,$0C,$1E,$28,$03,$18,$27,$1E,$1A,$03,$2A,$28,$03
        DB      $18,$28,$03,$3E

; $22 English semantic: You won't have a chance for your dance
; tlhIngan Hol: Qapla' Daghajbe'.
KSP22:
        DB      $12
        DB      $19,$1B,$15,$25,$18,$15,$03,$1E,$15,$1C,$1B,$15,$1E,$1A,$0E,$3B
        DB      $03,$3E

; $23 English semantic: Remember, I'm the Wizard, not you
; tlhIngan Hol: yIqaw: Wor 'IDnar pIn jIH; SoHbe'.
KSP23:
        DB      $20
        DB      $29,$27,$19,$15,$2D,$03,$2D,$26,$2B,$03,$27,$1E,$0D,$15,$2B,$03
        DB      $25,$27,$0D,$03,$1E,$1A,$27,$1B,$03,$11,$26,$1B,$0E,$3B,$03,$3E

; $24 English semantic: If you can't beat the rest, then you'll never get the best
; tlhIngan Hol: Hoch DanIvbe'chugh, bIluj.
KSP24:
        DB      $1A
        DB      $1B,$26,$2A,$10,$03,$1E,$15,$0D,$27,$0F,$0E,$3B,$03,$2A,$10,$28
        DB      $1C,$1B,$03,$0E,$27,$18,$28,$1E,$1A,$3E

; $25 English semantic: If you destroy my babies, I'll pop you in the oven
; tlhIngan Hol: ghumeywIj DaQaw'chugh, qulDaq qameQmoH.
KSP25:
        DB      $29
        DB      $1C,$1B,$28,$0C,$3B,$29,$2D,$27,$1E,$1A,$03,$1E,$15,$19,$1B,$15
        DB      $2D,$03,$2A,$10,$28,$1C,$1B,$03,$19,$28,$18,$1E,$15,$19,$03,$19
        DB      $15,$0C,$3B,$19,$1B,$0C,$26,$1B,$3E

; $26 English semantic: Now I'm getting mad
; tlhIngan Hol: jIQeHchoH.
KSP26:
        DB      $0C
        DB      $1E,$1A,$27,$19,$1B,$3B,$1B,$2A,$10,$26,$1B,$3E

; $27 English semantic: You'll never leave Wor alive
; tlhIngan Hol: Worvo' bIyIntaHvIS bImejbe'.
KSP27:
        DB      $1C
        DB      $2D,$26,$2B,$0F,$26,$03,$0E,$27,$29,$27,$0D,$2A,$15,$1B,$0F,$27
        DB      $11,$03,$0E,$27,$0C,$3B,$1E,$1A,$0E,$3B,$03,$3E

; $28 English semantic: Garwor and Thorwor become invisible
; tlhIngan Hol: Garwor Thorwor je tISo'moH!
KSP28:
        DB      $1C
        DB      $1C,$15,$2B,$2D,$26,$2B,$03,$2A,$1B,$26,$2B,$2D,$26,$2B,$03,$1E
        DB      $1A,$3B,$03,$2A,$27,$11,$26,$03,$0C,$26,$1B,$3E

; $29 English semantic: You know you can do better
; tlhIngan Hol: bIHoSghajqu'laH.
KSP29:
        DB      $11
        DB      $0E,$27,$1B,$26,$11,$1C,$1B,$15,$1E,$1A,$19,$28,$03,$18,$15,$1B
        DB      $3E

; $2A English semantic: Hurry back, I can't wait to do it again
; tlhIngan Hol: nom yIchegh; qaloS.
KSP2A:
        DB      $12
        DB      $0D,$26,$0C,$03,$29,$27,$2A,$10,$3B,$1C,$1B,$03,$19,$15,$18,$26
        DB      $11,$3E

; $2B English semantic: You can start anew, but for now you're through
; tlhIngan Hol: Qu' Dachuqa'laH; DaH bIluj.
KSP2B:
        DB      $1B
        DB      $19,$1B,$28,$03,$1E,$15,$2A,$10,$28,$19,$15,$03,$18,$15,$1B,$03
        DB      $1E,$15,$1B,$03,$0E,$27,$18,$28,$1E,$1A,$3E

; $2C English semantic: He he he ho ho ho ha ha ha ha, that was fun
; tlhIngan Hol: He he he, ho ho ho, ha ha ha ha! maj.
KSP2C:
        DB      $23
        DB      $1B,$3B,$03,$1B,$3B,$03,$1B,$3B,$03,$1B,$26,$03,$1B,$26,$03,$1B
        DB      $26,$03,$1B,$15,$03,$1B,$15,$03,$1B,$15,$03,$1B,$15,$3E,$0C,$15
        DB      $1E,$1A,$3E

; $2D English semantic: Welcome to my world of Wor
; tlhIngan Hol: Wor qo'Daq yI'el.
KSP2D:
        DB      $11
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E,$15,$19,$03,$29,$27,$03,$3B,$18
        DB      $3E

; $2E English semantic: So you've come to score in the world of Wor
; tlhIngan Hol: Wor qo'Daq mIvwa' DaSuq.
KSP2E:
        DB      $17
        DB      $2D,$26,$2B,$03,$19,$26,$03,$1E,$15,$19,$03,$0C,$27,$0F,$2D,$15
        DB      $03,$1E,$15,$11,$28,$19,$3E

; $2F English semantic: You're off to see the Wizard, the magical Wizard of Wor
; tlhIngan Hol: Wor 'IDnar pIn Daghom.
KSP2F:
        DB      $15
        DB      $2D,$26,$2B,$03,$27,$1E,$0D,$15,$2B,$03,$25,$27,$0D,$03,$1E,$15
        DB      $1C,$1B,$26,$0C,$3E

; $30 English semantic: Burwor hasn't eaten anyone in months
; tlhIngan Hol: qaStaHvIS 'op jar pagh Sop Burwor.
KSP30:
        DB      $22
        DB      $19,$15,$11,$2A,$15,$1B,$0F,$27,$11,$03,$26,$25,$03,$1E,$1A,$15
        DB      $2B,$03,$25,$15,$1C,$1B,$03,$11,$26,$25,$03,$0E,$28,$2B,$2D,$26
        DB      $2B,$3E

; $31 English semantic: My babies breathe fire
; tlhIngan Hol: qul lutlhuH ghumeywIj.
KSP31:
        DB      $17
        DB      $19,$28,$18,$03,$18,$28,$2A,$18,$1B,$28,$1B,$03,$1C,$1B,$28,$0C
        DB      $3B,$29,$2D,$27,$1E,$1A,$3E

; $32 English semantic: I'll fry you with my lightning bolts
; tlhIngan Hol: nISwI' tIHmeywIjmo' bImeQ.
KSP32:
        DB      $1A
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$0C,$3B,$29,$2D,$27,$1E,$1A
        DB      $0C,$26,$03,$0E,$27,$0C,$3B,$19,$1B,$3E

; $33 English semantic: Thorwor is red, mean, and hungry for space food
; tlhIngan Hol: Doq Thorwor, QeH 'ej ghung.
KSP33:
        DB      $1A
        DB      $1E,$26,$19,$03,$2A,$1B,$26,$2B,$2D,$26,$2B,$03,$19,$1B,$3B,$1B
        DB      $03,$3B,$1E,$1A,$03,$1C,$1B,$28,$14,$3E

; $34 English semantic: Worrior fear, I draw near, each time I appear
; tlhIngan Hol: SuvwI', qaSumchoH.
KSP34:
        DB      $10
        DB      $11,$28,$0F,$2D,$27,$03,$19,$15,$11,$28,$0C,$2A,$10,$26,$1B,$3E

; $35 English semantic: You're asking for trouble
; tlhIngan Hol: Seng DaneH.
KSP35:
        DB      $0A
        DB      $11,$3B,$14,$03,$1E,$15,$0D,$3B,$1B,$3E

; $36 English semantic: Ha ha ha ha (padded)
; tlhIngan Hol: Ha ha ha ha! (padded)
KSP36:
        DB      $0D
        DB      $1B,$15,$03,$1B,$15,$03,$1B,$15,$03,$1B,$15,$3E,$03

; $37 English semantic: Worrior (padded)
; tlhIngan Hol: SuvwI' (padded)
KSP37:
        DB      $08
        DB      $11,$28,$0F,$2D,$27,$03,$3E,$03

; $38 English semantic: You've just been fried by
; tlhIngan Hol: DuQIHpu'.
KSP38:
        DB      $0A
        DB      $1E,$28,$19,$1B,$27,$1B,$25,$28,$03,$3E

; $39 English semantic: Bite the bolt
; tlhIngan Hol: nISwI' yIchop.
KSP39:
        DB      $0D
        DB      $0D,$27,$11,$2D,$27,$03,$29,$27,$2A,$10,$26,$25,$3E

; $3A English semantic: Wasn't that lightning bolt delicious
; tlhIngan Hol: nISwI' tIH DaparHa''a'?
KSP3A:
        DB      $15
        DB      $0D,$27,$11,$2D,$27,$03,$2A,$27,$1B,$03,$1E,$15,$25,$15,$2B,$1B
        DB      $15,$03,$15,$03,$3E

; $3B English semantic: And my teleporting spell can be even faster
; tlhIngan Hol: nom jolwI'wIj Qap.
KSP3B:
        DB      $15
        DB      $0D,$26,$0C,$03,$1E,$1A,$26,$18,$2D,$27,$03,$2D,$27,$1E,$1A,$03
        DB      $19,$1B,$15,$25,$3E

; $3C English semantic: Now you know the taste of my magic
; tlhIngan Hol: DaH 'IDnarwIj DaSov.
KSP3C:
        DB      $14
        DB      $1E,$15,$1B,$03,$27,$1E,$0D,$15,$2B,$2D,$27,$1E,$1A,$03,$1E,$15
        DB      $11,$26,$0F,$3E

; $3D English semantic: Maybe you'll see me again
; tlhIngan Hol: chaq maghomqa'.
KSP3D:
        DB      $0F
        DB      $2A,$10,$15,$19,$03,$0C,$15,$1C,$1B,$26,$0C,$19,$15,$03,$3E

; $3E English semantic: Your explosion was music to my ears
; tlhIngan Hol: QoQ 'oH jorlIj'e'.
KSP3E:
        DB      $15
        DB      $19,$1B,$26,$19,$1B,$03,$26,$1B,$03,$1E,$1A,$26,$2B,$18,$27,$1E
        DB      $1A,$03,$3B,$03,$3E

; $3F English semantic: I'll say it again
; tlhIngan Hol: vIjatlhqa'.
KSP3F:
        DB      $0C
        DB      $0F,$27,$1E,$1A,$15,$2A,$18,$1B,$19,$15,$03,$3E

; $40 English semantic: Worlord
; tlhIngan Hol: SuvwI' joH
KSP40:
        DB      $0B
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A,$26,$1B,$3E

; $41 English semantic: Worlord (padded)
; tlhIngan Hol: SuvwI' joH (padded)
KSP41:
        DB      $0C
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A,$26,$1B,$3E,$03

; $42 English semantic: Be forewarned! You approach the Pit
; tlhIngan Hol: yIghuH! QemjIq DaghoS.
KSP42:
        DB      $17
        DB      $29,$27,$1C,$1B,$28,$1B,$3E,$19,$1B,$3B,$0C,$1E,$1A,$27,$19,$03
        DB      $1E,$15,$1C,$1B,$26,$11,$3E

; $43 English semantic: Your path leads directly to the Pit
; tlhIngan Hol: QemjIqDaq He'lIj ghoS.
KSP43:
        DB      $19
        DB      $19,$1B,$3B,$0C,$1E,$1A,$27,$19,$1E,$15,$19,$03,$1B,$3B,$03,$18
        DB      $27,$1E,$1A,$03,$1C,$1B,$26,$11,$3E

; $44 English semantic: Deeper, ever deeper into
; tlhIngan Hol: Wor bIghHa'mey qoDDaq yIghoS.
KSP44:
        DB      $1D
        DB      $2D,$26,$2B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$03,$19
        DB      $26,$1E,$1E,$15,$19,$03,$29,$27,$1C,$1B,$26,$11,$3E

; $45 English semantic: Beware! You are in the Worlord dungeons
; tlhIngan Hol: yIghuH! SuvwI' joH bIghHa'meyDaq SoH.
KSP45:
        DB      $24
        DB      $29,$27,$1C,$1B,$28,$1B,$3E,$11,$28,$0F,$2D,$27,$03,$1E,$1A,$26
        DB      $1B,$03,$0E,$27,$1C,$1B,$1B,$15,$03,$0C,$3B,$29,$1E,$15,$19,$03
        DB      $11,$26,$1B,$3E

; $46 English semantic: Ah! You thought you could hide, but I'm the dungeon master
; tlhIngan Hol: DaSo' 'e' DaQub; bIghHa' pIn jIH.
KSP46:
        DB      $1E
        DB      $1E,$15,$11,$26,$03,$3B,$03,$1E,$15,$19,$1B,$28,$0E,$03,$0E,$27
        DB      $1C,$1B,$1B,$15,$03,$25,$27,$0D,$03,$1E,$1A,$27,$1B,$3E

; $47 English semantic: Thor, Bur, Gar! Dinner's ready
; tlhIngan Hol: Thor, Bur, Gar! SopmeH yIghuH.
KSP47:
        DB      $1B
        DB      $2A,$1B,$26,$2B,$03,$0E,$28,$2B,$03,$1C,$15,$2B,$3E,$11,$26,$25
        DB      $0C,$3B,$1B,$03,$29,$27,$1C,$1B,$28,$1B,$3E

; $48 English semantic: Hey! Your space boots untied
; tlhIngan Hol: DaSlIj yIrar!
KSP48:
        DB      $0E
        DB      $1E,$15,$11,$18,$27,$1E,$1A,$03,$29,$27,$2B,$15,$2B,$3E

; $49 English semantic: My beasts run wild in the Worlord dungeons
; tlhIngan Hol: SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.
KSP49:
        DB      $2D
        DB      $11,$28,$0F,$2D,$27,$03,$1E,$1A,$26,$1B,$03,$0E,$27,$1C,$1B,$1B
        DB      $15,$03,$0C,$3B,$29,$1E,$15,$19,$03,$19,$3B,$2A,$03,$1B,$15,$03
        DB      $1E,$27,$0E,$15,$1B,$0C,$3B,$29,$2D,$27,$1E,$1A,$3E

; $4A English semantic: Now your only chance is your dance
; tlhIngan Hol: DaH yImI'; latlh DuH Daghajbe'.
KSP4A:
        DB      $1E
        DB      $1E,$15,$1B,$03,$29,$27,$0C,$27,$03,$18,$15,$2A,$18,$1B,$03,$1E
        DB      $28,$1B,$03,$1E,$15,$1C,$1B,$15,$1E,$1A,$0E,$3B,$03,$3E

; $4B English semantic: Are you fit to survive the Pit
; tlhIngan Hol: QemjIqDaq bIyInlaH'a'?
KSP4B:
        DB      $18
        DB      $19,$1B,$3B,$0C,$1E,$1A,$27,$19,$1E,$15,$19,$03,$0E,$27,$29,$27
        DB      $0D,$18,$15,$1B,$03,$15,$03,$3E

; $4C English semantic: Oops! I must have forgotten the walls
; tlhIngan Hol: toH! reDmey vIlIjpu'.
KSP4C:
        DB      $15
        DB      $2A,$26,$1B,$3E,$2B,$3B,$1E,$0C,$3B,$29,$03,$0F,$27,$18,$27,$1E
        DB      $1A,$25,$28,$03,$3E

; $4D English semantic: Where are you going to hide now
; tlhIngan Hol: nuqDaq DaSo'?
KSP4D:
        DB      $0D
        DB      $0D,$28,$19,$1E,$15,$19,$03,$1E,$15,$11,$26,$03,$3E

; $4E English semantic: You're in
; tlhIngan Hol: SoH.
KSP4E:
        DB      $04
        DB      $11,$26,$1B,$3E

; Erased speech/pointer gap: $C8D0-$CD8C (1213 bytes)
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
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        DB      $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
KPTRS:
        DW      KSP00          ; $00
        DW      KSP01          ; $01
        DW      KSP02          ; $02
        DW      KSP03          ; $03
        DW      KSP04          ; $04
        DW      KSP05          ; $05
        DW      KSP06          ; $06
        DW      KSP07          ; $07
        DW      KSP08          ; $08
        DW      KSP09          ; $09
        DW      KSP0A          ; $0A
        DW      KSP0B          ; $0B
        DW      KSP0C          ; $0C
        DW      KSP0D          ; $0D
        DW      KSP0E          ; $0E
        DW      KSP0F          ; $0F
        DW      KSP10          ; $10
        DW      KSP11          ; $11
        DW      KSP12          ; $12
        DW      KSP13          ; $13
        DW      KSP14          ; $14
        DW      KSP15          ; $15
        DW      KSP16          ; $16
        DW      KSP17          ; $17
        DW      KSP18          ; $18
        DW      KSP19          ; $19
        DW      KSP1A          ; $1A
        DW      KSP1B          ; $1B
        DW      KSP1C          ; $1C
        DW      KSP1D          ; $1D
        DW      KSP1E          ; $1E
        DW      KSP1F          ; $1F
        DW      KSP20          ; $20
        DW      KSP21          ; $21
        DW      KSP22          ; $22
        DW      KSP23          ; $23
        DW      KSP24          ; $24
        DW      KSP25          ; $25
        DW      KSP26          ; $26
        DW      KSP27          ; $27
        DW      KSP28          ; $28
        DW      KSP29          ; $29
        DW      KSP2A          ; $2A
        DW      KSP2B          ; $2B
        DW      KSP2C          ; $2C
        DW      KSP2D          ; $2D
        DW      KSP2E          ; $2E
        DW      KSP2F          ; $2F
        DW      KSP30          ; $30
        DW      KSP31          ; $31
        DW      KSP32          ; $32
        DW      KSP33          ; $33
        DW      KSP34          ; $34
        DW      KSP35          ; $35
        DW      KSP36          ; $36
        DW      KSP37          ; $37
        DW      KSP38          ; $38
        DW      KSP39          ; $39
        DW      KSP3A          ; $3A
        DW      KSP3B          ; $3B
        DW      KSP3C          ; $3C
        DW      KSP3D          ; $3D
        DW      KSP3E          ; $3E
        DW      KSP3F          ; $3F
        DW      KSP40          ; $40
        DW      KSP41          ; $41
        DW      KSP42          ; $42
        DW      KSP43          ; $43
        DW      KSP44          ; $44
        DW      KSP45          ; $45
        DW      KSP46          ; $46
        DW      KSP47          ; $47
        DW      KSP48          ; $48
        DW      KSP49          ; $49
        DW      KSP4A          ; $4A
        DW      KSP4B          ; $4B
        DW      KSP4C          ; $4C
        DW      KSP4D          ; $4D
        DW      KSP4E          ; $4E
        DW      $0000          ; $4F null
        DW      $0000          ; $50 null
        DW      $0000          ; $51 null
        DW      $0000          ; $52 null
        DW      $0000          ; $53 null

KPHRASE:
        DB      $81,$0A      ; phrase $00
        DB      $82,$0B,$04      ; phrase $01
        DB      $81,$0A      ; phrase $02
        DB      $82,$0C,$10      ; phrase $03
        DB      $81,$0A      ; phrase $04
        DB      $82,$0B,$04      ; phrase $05
        DB      $81,$0A      ; phrase $06
        DB      $82,$0C,$10      ; phrase $07
        DB      $82,$0D,$09      ; phrase $08
        DB      $82,$0E,$04      ; phrase $09
        DB      $81,$0F      ; phrase $0A
        DB      $82,$11,$10      ; phrase $0B
        DB      $82,$1E,$36      ; phrase $0C
        DB      $81,$2D      ; phrase $0D
        DB      $82,$2E,$10      ; phrase $0E
        DB      $82,$2F,$10      ; phrase $0F
        DB      $81,$00      ; phrase $10
        DB      $82,$4E,$02      ; phrase $11
        DB      $82,$03,$04      ; phrase $12
        DB      $82,$05,$10      ; phrase $13
        DB      $81,$06      ; phrase $14
        DB      $81,$07      ; phrase $15
        DB      $82,$08,$37      ; phrase $16
        DB      $82,$33,$36      ; phrase $17
        DB      $81,$23      ; phrase $18
        DB      $82,$24,$36      ; phrase $19
        DB      $82,$27,$36      ; phrase $1A
        DB      $82,$25,$36      ; phrase $1B
        DB      $82,$30,$36      ; phrase $1C
        DB      $82,$31,$09      ; phrase $1D
        DB      $81,$32      ; phrase $1E
        DB      $81,$1D      ; phrase $1F
        DB      $82,$12,$36      ; phrase $20
        DB      $81,$13      ; phrase $21
        DB      $81,$14      ; phrase $22
        DB      $82,$15,$40      ; phrase $23
        DB      $82,$37,$26      ; phrase $24
        DB      $82,$34,$10      ; phrase $25
        DB      $83,$09,$22,$10      ; phrase $26
        DB      $82,$35,$37      ; phrase $27
        DB      $82,$1A,$36      ; phrase $28
        DB      $81,$1B      ; phrase $29
        DB      $82,$1C,$36      ; phrase $2A
        DB      $82,$01,$36      ; phrase $2B
        DB      $82,$1F,$09      ; phrase $2C
        DB      $82,$09,$20      ; phrase $2D
        DB      $82,$21,$36      ; phrase $2E
        DB      $82,$28,$36      ; phrase $2F
        DB      $83,$16,$04,$10      ; phrase $30
        DB      $82,$17,$37      ; phrase $31
        DB      $82,$18,$37      ; phrase $32
        DB      $82,$04,$19      ; phrase $33
        DB      $82,$29,$37      ; phrase $34
        DB      $81,$2A      ; phrase $35
        DB      $82,$2B,$36      ; phrase $36
        DB      $81,$2C      ; phrase $37
        DB      $83,$38,$04,$10      ; phrase $38
        DB      $83,$39,$37,$36      ; phrase $39
        DB      $82,$3A,$10      ; phrase $3A
        DB      $82,$3B,$36      ; phrase $3B
        DB      $82,$3C,$37      ; phrase $3C
        DB      $82,$09,$3D      ; phrase $3D
        DB      $82,$3E,$10      ; phrase $3E
        DB      $83,$3F,$34,$10      ; phrase $3F
        DB      $83,$41,$42,$36      ; phrase $40
        DB      $83,$41,$43,$36      ; phrase $41
        DB      $83,$44,$02,$36      ; phrase $42
        DB      $81,$45      ; phrase $43
        DB      $82,$46,$36      ; phrase $44
        DB      $82,$47,$36      ; phrase $45
        DB      $82,$48,$10      ; phrase $46
        DB      $82,$49,$36      ; phrase $47
        DB      $82,$4A,$10      ; phrase $48
        DB      $82,$4B,$10      ; phrase $49
        DB      $82,$4C,$10      ; phrase $4A
        DB      $82,$4D,$36      ; phrase $4B
        DB      $82,$4A,$10      ; phrase $4C
        DB      $82,$4B,$36      ; phrase $4D
        DB      $82,$4C,$10      ; phrase $4E
        DB      $82,$4D,$36      ; phrase $4F

; Preserve fixed checksum position used by the known X11 layout.
        DB      $FF,$FF
KCHKSUM:
        DB      $3B

; Erased tail gap: $CF1E-$CFEA (205 bytes)
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
KIDENT:
        DB      $4B,$4C,$49,$4E,$47,$4F,$4E,$57,$49,$5A,$41,$52
        DB      $44,$00
        DB      $44,$4E,$41,$00
        DB      $08,$08,$26

        END
