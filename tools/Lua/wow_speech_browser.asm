; wow_speech_browser.asm
; Wizard of Wor speech-browser foreground controller
;
; This is the Z80 program injected by wow_speech_browser.lua at $D400.
; Lua validates the loaded ROM and supplies formatted catalog pages.  After the
; one-time bootstrap, this program owns input, navigation, rendering, playback,
; Play All, and the periodic call into WoW's resident sound/speech service.
;
; Resident WoW entry points used:
;   $03B5  printstr entry with caller-supplied expand color
;   $8000  periodic sound/speech service
;   $8006  initialize the two sound-engine records
;   $8009  queue a language-independent phrase ID
;
; Fragment playback does not prime $D2CE/$D2D0 directly.  It appends the
; selected ROM record to WoW's circular speech queue and lets the resident
; Service_Speech_Queue path load and stream the fragment.

            ORG     $D400

; -----------------------------------------------------------------------------
; Resident ROM and hardware
; -----------------------------------------------------------------------------
PRINT_STRING_COLOR              EQU     $03B5
SOUND_SERVICE_ENTRY             EQU     $8000
SOUND_RESET_ENTRY               EQU     $8006
SPEECH_REQUEST_ENTRY            EQU     $8009

COINPORT                        EQU     $10
P2PORT                          EQU     $11
P1PORT                          EQU     $12
INFBK                           EQU     $0D
INMOD                           EQU     $0E
INLIN                           EQU     $0F

XPAND_BLUE                      EQU     $04
XPAND_YELLOW                    EQU     $08
XPAND_RED                       EQU     $0C

; -----------------------------------------------------------------------------
; Lua/Z80 shared page buffer.  Lua writes complete native-font rows here.
; -----------------------------------------------------------------------------
PAGE_HEADER                     EQU     $D050       ; 40 bytes
PAGE_ROWS                       EQU     $D078       ; 7 * 40 bytes
PAGE_FOOTER_1                   EQU     $D190       ; 40 bytes
PAGE_FOOTER_2                   EQU     $D1B8       ; 40 bytes
PAGE_FOOTER_3                   EQU     $D1E0       ; 40 bytes
PAGE_ENTRY_META                 EQU     $D208       ; 7 * {id, address lo, address hi}

; WoW sound/speech work area retained by the resident high-ROM engine.
SPEECH_ACTIVE                   EQU     $D245
SOUND_SERVICE_ENABLED           EQU     $D244
SPEECH_QUEUE_BUFFER             EQU     $D2BE
SPEECH_PHONEME_POINTER          EQU     $D2CE
SPEECH_PHONEMES_REMAINING       EQU     $D2D0
SPEECH_INFLECTION_STATE         EQU     $D2D1
SPEECH_QUEUE_WRITE              EQU     $D2D2
SPEECH_QUEUE_READ               EQU     $D2D4
GAME_MODE                       EQU     $D303
DUNGEON_CLASS                   EQU     $D350       ; keep phrase fragment IDs literal

; -----------------------------------------------------------------------------
; Fixed shared state.  These addresses are the Lua/native ABI.
; -----------------------------------------------------------------------------
BROWSER_SIGNATURE               EQU     $D380       ; "WSN2"
PAGE_SEQUENCE                   EQU     $D384       ; Z80 request sequence
PAGE_ACK                        EQU     $D385       ; Lua completion sequence
PAGE_DRAWN                      EQU     $D386       ; last sequence rendered
PANE                            EQU     $D387       ; 0 fragments, 1 phrases
SELECTED_FRAGMENT               EQU     $D388       ; zero based, $FF none
SELECTED_PHRASE                 EQU     $D389
FIRST_FRAGMENT                  EQU     $D38A
FIRST_PHRASE                    EQU     $D38B
COUNT_FRAGMENT                  EQU     $D38C
COUNT_PHRASE                    EQU     $D38D
INPUT_LAST                      EQU     $D38E
START_LAST                      EQU     $D38F
PLAY_ALL                        EQU     $D390
AUTO_START                      EQU     $D391       ; play after requested page is drawn
EVENT_SEQUENCE                 EQU     $D392
EVENT_STATE                    EQU     $D393       ; 0 idle, 1 announced, 2 playing, 3 complete
EVENT_DELAY                    EQU     $D394       ; frames between announce and native start
EVENT_KIND                     EQU     $D395       ; 0 fragment, 1 phrase
EVENT_ID                       EQU     $D396
EVENT_ADDRESS                  EQU     $D397
HEARTBEAT                       EQU     $D399
EXIT_REQUEST                    EQU     $D39A
ROW_COUNTER                     EQU     $D39B
RENDER_COUNT                    EQU     $D39C
ERROR_CODE                      EQU     $D39D
COMMAND                         EQU     $D39E       ; Lua: 1 start all, 2 stop all
CAPTURE_FLAGS                   EQU     $D39F       ; Lua: bit 0 requests WAV pre-roll
HOLD_DIRECTION                  EQU     $D3A0       ; 1 up, 2 down, 0 released
HOLD_COUNTDOWN                  EQU     $D3A1
INPUT_CURRENT                   EQU     $D3A2
INPUT_PRESSED                   EQU     $D3A3
EXIT_COUNTDOWN                 EQU     $D3A4       ; native STOP settling time before Lua exits
WATCHDOG_POINTER               EQU     $D3A5       ; last resident phoneme pointer
WATCHDOG_COUNTDOWN             EQU     $D3A7       ; frames without pointer progress
STALL_RECOVERIES               EQU     $D3A8       ; read-only diagnostic counter for Lua

SPEECH_WATCHDOG_FRAMES         EQU     $78         ; two seconds at 60 Hz

; IM 2 vector selected by I=$D3 and hardware feedback byte $CA.
BROWSER_VECTOR                  EQU     $D3CA

; -----------------------------------------------------------------------------
; One-time takeover
; -----------------------------------------------------------------------------
Browser_Entry:
            di
            ld      sp,$8000            ; WoW's non-viewable video-RAM stack margin

            ; Clear the visible frame before any CALL pushes onto the stack.
            xor     a
            ld      hl,$4000
            ld      de,$4001
            ld      bc,$3FFF
            ld      (hl),a
            ldir

            ; Replace the game interrupt chain with one browser frame service.
            ld      hl,Browser_Interrupt
            ld      (BROWSER_VECTOR),hl
            ld      a,$D3
            ld      i,a
            im      2
            ld      a,$CA
            out     (INFBK),a
            ld      a,$A8
            out     (INLIN),a
            ld      a,$08
            out     (INMOD),a

            ; Deliberately make one queue pointer invalid, then use WoW's $8006
            ; reset/validation entry to reset both engines, empty the queue and
            ; issue the SC-01 STOP command through resident code.
            xor     a
            ld      (SPEECH_ACTIVE),a
            ld      (SPEECH_PHONEMES_REMAINING),a
            ld      (SPEECH_INFLECTION_STATE),a
            ld      h,a
            ld      l,a
            ld      (SPEECH_QUEUE_WRITE),hl
            ld      hl,SPEECH_QUEUE_BUFFER
            ld      (SPEECH_QUEUE_READ),hl
            call    SOUND_RESET_ENTRY
            ld      a,$01
            ld      (SOUND_SERVICE_ENABLED),a
            ld      (GAME_MODE),a

            xor     a
            ld      (INPUT_LAST),a
            ld      (START_LAST),a
            ld      (PLAY_ALL),a
            ld      (AUTO_START),a
            ld      (EVENT_STATE),a
            ld      (EXIT_REQUEST),a
            ld      (HEARTBEAT),a
            ld      (RENDER_COUNT),a
            ld      (COMMAND),a
            ld      (DUNGEON_CLASS),a
            ld      (HOLD_DIRECTION),a
            ld      (HOLD_COUNTDOWN),a
            ld      (INPUT_CURRENT),a
            ld      (INPUT_PRESSED),a
            ld      (EXIT_COUNTDOWN),a
            ld      (WATCHDOG_POINTER),a
            ld      (WATCHDOG_POINTER+1),a
            ld      (WATCHDOG_COUNTDOWN),a
            ld      (STALL_RECOVERIES),a
            dec     a
            ld      (PAGE_DRAWN),a       ; force initial page render

Browser_Main_Loop:
            ei
            halt                        ; one native controller pass per frame
            call    Service_Exit
            call    Service_Completion
            call    Service_Command
            call    Read_Controls
            call    Service_Pending_Play
            call    Service_Page
            jr      Browser_Main_Loop

; -----------------------------------------------------------------------------
; Browser-owned IM 2 handler.  WoW's real periodic high-ROM service remains the
; only code that advances sound streams and clocks SC-01 phonemes.
; -----------------------------------------------------------------------------
Browser_Interrupt:
            push    af
            push    bc
            push    de
            push    hl
            push    ix
            push    iy
            ex      af,af'
            push    af
            exx
            push    bc
            push    de
            push    hl
            call    SOUND_SERVICE_ENTRY
            ld      hl,HEARTBEAT
            inc     (hl)
            pop     hl
            pop     de
            pop     bc
            exx
            pop     af
            ex      af,af'
            pop     iy
            pop     ix
            pop     hl
            pop     de
            pop     bc
            pop     af
            ei
            ret

; -----------------------------------------------------------------------------
; Input
; -----------------------------------------------------------------------------
Read_Controls:
            in      a,(P1PORT)
            cpl
            and     $3F
            ld      b,a
            in      a,(P2PORT)
            cpl
            and     $3F
            or      b
            ld      b,a                 ; B = current combined joystick state
            ld      (INPUT_CURRENT),a
            ld      a,(INPUT_LAST)
            cpl
            and     b
            ld      c,a                 ; C = newly pressed joystick bits
            ld      (INPUT_PRESSED),a
            ld      a,b
            ld      (INPUT_LAST),a

            in      a,(COINPORT)
            cpl
            and     $60
            ld      b,a
            ld      a,(START_LAST)
            cpl
            and     b
            ld      d,a                 ; D = newly pressed Start bits
            ld      a,b
            ld      (START_LAST),a

            bit     5,d                 ; 1P Start: native STOP, then delayed Lua exit
            call    nz,Begin_Exit
            ld      a,(EXIT_COUNTDOWN)
            or      a
            ret     nz

Input_Check_2P:
            bit     6,d
            call    nz,Toggle_Play_All
            ld      a,(PLAY_ALL)
            or      a
            ret     nz                  ; only 1P/2P are active during Play All

            ld      a,(INPUT_PRESSED)
            and     $0C
            call    nz,Toggle_Pane
            call    Service_Vertical_Input
            ld      a,(INPUT_PRESSED)
            and     $30
            call    nz,Request_Selected_Entry
            ret

; First movement is immediate.  A held direction repeats after 15 frames and
; then every four frames; opposing directions cancel until one is released.
Service_Vertical_Input:
            ld      a,(INPUT_CURRENT)
            and     $03
            jr      z,Vertical_Released
            cp      $03
            jr      z,Vertical_Released
            ld      b,a
            ld      a,(HOLD_DIRECTION)
            cp      b
            jr      nz,Vertical_New_Direction
            ld      hl,HOLD_COUNTDOWN
            dec     (hl)
            ret     nz
            ld      (hl),$04
            jr      Vertical_Move
Vertical_New_Direction:
            ld      a,b
            ld      (HOLD_DIRECTION),a
            ld      a,$0F
            ld      (HOLD_COUNTDOWN),a
Vertical_Move:
            bit     0,b
            jp      nz,Move_Up
            jp      Move_Down
Vertical_Released:
            xor     a
            ld      (HOLD_DIRECTION),a
            ld      (HOLD_COUNTDOWN),a
            ret

Toggle_Pane:
            ld      a,(PANE)
            xor     $01
            ld      (PANE),a
            jp      Request_Page

; IX addresses the selected item.  +2 is first visible; +4 is item count.
Get_Pane_State:
            ld      ix,SELECTED_FRAGMENT
            ld      a,(PANE)
            or      a
            ret     z
            inc     ix
            ret

Move_Down:
            call    Get_Pane_State
            ld      a,(ix+$00)
            inc     a                   ; $FF becomes zero for the first DOWN
            cp      (ix+$04)
            jr      c,Store_Selection
            xor     a
            jr      Store_Selection

Move_Up:
            call    Get_Pane_State
            ld      a,(ix+$00)
            or      a
            jr      z,Select_Last
            cp      $FF
            jr      z,Select_Last
            dec     a
            jr      Store_Selection
Select_Last:
            ld      a,(ix+$04)
            dec     a

Store_Selection:
            ld      (ix+$00),a
            ld      c,a
            ld      a,(ix+$02)
            ld      b,a
            ld      a,c
            cp      b
            jr      c,Selection_Before_Window
            sub     b
            cp      $07
            jp      c,Draw_Page
            ld      a,c
            sub     $06
            ld      (ix+$02),a
            jp      Request_Page
Selection_Before_Window:
            ld      a,c
            ld      (ix+$02),a
            jp      Request_Page

; -----------------------------------------------------------------------------
; Page mailbox and native rendering
; -----------------------------------------------------------------------------
Request_Page:
            ld      hl,PAGE_SEQUENCE
            inc     (hl)
            ret

; Console commands are only mailbox requests.  Native code still performs the
; same Play All state transition used by the 2P Start control.
Service_Command:
            ld      a,(COMMAND)
            or      a
            ret     z
            ld      b,a
            xor     a
            ld      (COMMAND),a
            ld      a,b
            cp      $03
            jp      z,Begin_Exit
            dec     b
            jr      nz,Command_Stop_All
            ld      a,(PLAY_ALL)
            or      a
            ret     nz
            jp      Toggle_Play_All
Command_Stop_All:
            djnz    Command_Return
            ld      a,(PLAY_ALL)
            or      a
            ret     z
            jp      Toggle_Play_All
Command_Return:
            ret

Service_Page:
            ld      a,(PAGE_ACK)
            ld      b,a
            ld      a,(PAGE_SEQUENCE)
            cp      b
            ret     nz
            ld      a,(PAGE_DRAWN)
            cp      b
            ret     z
            ld      a,b
            ld      (PAGE_DRAWN),a
            call    Draw_Page
            ld      a,(AUTO_START)
            or      a
            ret     z
            xor     a
            ld      (AUTO_START),a
            jp      Request_Selected_Entry

Draw_Page:
            ; Never render a stale buffer while Lua is constructing a new page.
            ld      a,(PAGE_ACK)
            ld      b,a
            ld      a,(PAGE_SEQUENCE)
            cp      b
            ret     nz
            di
            ld      hl,PAGE_HEADER
            ld      de,$0000
            ld      b,$28
            ld      a,XPAND_BLUE
            call    PRINT_STRING_COLOR

            ld      hl,PAGE_ROWS
            ld      de,$0A00            ; screen row 2, column 0
            ld      a,$07
            ld      (ROW_COUNTER),a
Draw_Page_Row:
            ld      b,$28
            ld      a,XPAND_RED
            call    PRINT_STRING_COLOR
            ld      e,$00
            ld      a,d
            add     a,$05
            ld      d,a
            ld      a,(ROW_COUNTER)
            dec     a
            ld      (ROW_COUNTER),a
            jr      nz,Draw_Page_Row

            ld      hl,PAGE_FOOTER_1
            ld      de,$3200            ; row 10
            ld      b,$28
            ld      a,XPAND_YELLOW
            call    PRINT_STRING_COLOR
            ld      hl,PAGE_FOOTER_2
            ld      de,$3700            ; row 11
            ld      b,$28
            ld      a,XPAND_YELLOW
            call    PRINT_STRING_COLOR
            ld      hl,PAGE_FOOTER_3
            ld      de,$3C00            ; row 12
            ld      b,$28
            ld      a,XPAND_YELLOW
            call    PRINT_STRING_COLOR

            ld      hl,RENDER_COUNT
            inc     (hl)
            call    Get_Pane_State
            ld      a,(ix+$00)
            cp      $FF
            ret     z
            sub     (ix+$02)
            cp      $07
            ret     nc
            ld      c,a
            add     a,a
            add     a,a
            add     a,c
            add     a,$0A               ; native row 2 + relative row, times 5
            ld      d,a
            ld      e,$00
            ld      hl,Selector_Arrow
            ld      b,$01
            ld      a,XPAND_YELLOW
            jp      PRINT_STRING_COLOR

Selector_Arrow:
            DB      "a"                 ; WoW CHRTBL right-arrow glyph

; -----------------------------------------------------------------------------
; Playback
; -----------------------------------------------------------------------------
Speech_Idle:
            ld      a,(SPEECH_ACTIVE)
            or      a
            ret     nz
            ld      hl,(SPEECH_QUEUE_WRITE)
            ld      de,(SPEECH_QUEUE_READ)
            or      a
            sbc     hl,de
            ret

Request_Selected_Entry:
            ld      a,(EVENT_STATE)
            cp      $01
            ret     z
            cp      $02
            ret     z
            call    Speech_Idle
            ret     nz
            call    Get_Pane_State
            ld      a,(ix+$00)
            cp      $FF
            ret     z
            sub     (ix+$02)
            cp      $07
            ret     nc

            ; Locate the Lua-supplied {id,address} record for the selected row.
            ld      e,a
            ld      d,$00
            ld      l,a
            ld      h,$00
            add     hl,hl
            add     hl,de
            ld      de,PAGE_ENTRY_META
            add     hl,de
            ld      a,(hl)
            ld      (EVENT_ID),a
            inc     hl
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            ld      (EVENT_ADDRESS),de
            ld      a,(PANE)
            ld      (EVENT_KIND),a
            ld      hl,EVENT_SEQUENCE
            inc     (hl)
            ld      a,(CAPTURE_FLAGS)
            and     $01
            ld      a,$02               ; normal diagnostics get one full Lua frame
            jr      z,Store_Event_Delay
            ld      a,$0C               ; WAV: allow prior post-roll and new pre-roll
Store_Event_Delay:
            ld      (EVENT_DELAY),a
            ld      a,$01
            ld      (EVENT_STATE),a
            ret

Service_Pending_Play:
            ld      a,(EVENT_STATE)
            cp      $01
            ret     nz
            ld      hl,EVENT_DELAY
            ld      a,(hl)
            or      a
            jr      z,Pending_Delay_Done
            dec     (hl)
            ret
Pending_Delay_Done:
            call    Speech_Idle
            ret     nz
            ld      a,(EVENT_KIND)
            or      a
            jr      z,Play_Fragment
            ld      a,(EVENT_ID)
            call    SPEECH_REQUEST_ENTRY
            jr      Mark_Event_Playing

Play_Fragment:
            ; Queue exactly one fragment record.  The resident queue loader will
            ; fetch its length and phoneme pointer on the next $8000 service.
            ld      hl,(EVENT_ADDRESS)
            ld      de,SPEECH_QUEUE_BUFFER
            ld      a,l
            ld      (de),a
            inc     de
            ld      a,h
            ld      (de),a
            inc     de                  ; next write record = $D2C0
            ld      (SPEECH_QUEUE_WRITE),de
            ld      de,SPEECH_QUEUE_BUFFER
            ld      (SPEECH_QUEUE_READ),de
            ld      a,$01
            ld      (SPEECH_ACTIVE),a

Mark_Event_Playing:
            ld      hl,(SPEECH_PHONEME_POINTER)
            ld      (WATCHDOG_POINTER),hl
            ld      a,SPEECH_WATCHDOG_FRAMES
            ld      (WATCHDOG_COUNTDOWN),a
            ld      a,$02
            ld      (EVENT_STATE),a
            ret

Service_Completion:
            ld      a,(EVENT_STATE)
            cp      $02
            ret     nz
            call    Speech_Idle
            jr      z,Completion_Finished
            call    Service_Speech_Watchdog
            ret     nz
Completion_Finished:
            ld      a,$03
            ld      (EVENT_STATE),a
            ld      a,(PLAY_ALL)
            or      a
            ret     z

            call    Get_Pane_State
            ld      a,(ix+$00)
            inc     a
            cp      (ix+$04)
            jr      nc,Play_All_Complete
            ld      (ix+$00),a
            ld      c,a
            ld      a,(ix+$02)
            ld      b,a
            ld      a,c
            sub     b
            cp      $07
            jr      c,Play_All_Same_Page
            ld      a,c
            sub     $06
            ld      (ix+$02),a
            ld      a,$01
            ld      (AUTO_START),a
            jp      Request_Page
Play_All_Same_Page:
            call    Draw_Page
            jp      Request_Selected_Entry

Play_All_Complete:
            xor     a
            ld      (PLAY_ALL),a
            jp      Request_Page

Toggle_Play_All:
            ld      a,(PLAY_ALL)
            or      a
            jr      nz,Stop_Play_All
            inc     a
            ld      (PLAY_ALL),a
            call    Get_Pane_State
            xor     a
            ld      (ix+$00),a
            ld      (ix+$02),a
            ld      a,$01
            ld      (AUTO_START),a
            jp      Request_Page
Stop_Play_All:
            xor     a
            ld      (PLAY_ALL),a
            ld      (AUTO_START),a
            jp      Request_Page

; A normal command advances well inside two seconds. If A/R remains low,
; recover through WoW's own $8006 queue validator and STOP path so the browser
; returns to an idle, usable speech state.
Service_Speech_Watchdog:
            ld      hl,(SPEECH_PHONEME_POINTER)
            ld      de,(WATCHDOG_POINTER)
            or      a
            sbc     hl,de
            jr      z,Speech_Watchdog_No_Progress
            ld      hl,(SPEECH_PHONEME_POINTER)
            ld      (WATCHDOG_POINTER),hl
            ld      a,SPEECH_WATCHDOG_FRAMES
            ld      (WATCHDOG_COUNTDOWN),a
            or      a                   ; nonzero: speech still running
            ret
Speech_Watchdog_No_Progress:
            ld      hl,WATCHDOG_COUNTDOWN
            dec     (hl)
            ld      a,(hl)
            or      a
            ret     nz
            call    Stop_All_Sound
            ld      hl,STALL_RECOVERIES
            inc     (hl)
            xor     a                   ; zero: recovered and now idle
            ret

; Force queue validation via resident WoW code.  Making the write pointer
; invalid causes $8006 -> Validate_Speech_Queue_State to empty the queue and
; issue the SC-01 STOP strobe; the browser never writes the Votrax port here.
Stop_All_Sound:
            xor     a
            ld      (SPEECH_ACTIVE),a
            ld      (SPEECH_PHONEMES_REMAINING),a
            ld      h,a
            ld      l,a
            ld      (SPEECH_QUEUE_WRITE),hl
            call    SOUND_RESET_ENTRY
            ld      a,$01
            ld      (SOUND_SERVICE_ENABLED),a
            ret

Begin_Exit:
            call    Stop_All_Sound
            xor     a
            ld      (PLAY_ALL),a
            ld      (AUTO_START),a
            ld      (EVENT_STATE),a
            ld      a,$06               ; let STOP commit before process exit
            ld      (EXIT_COUNTDOWN),a
            ret

Service_Exit:
            ld      hl,EXIT_COUNTDOWN
            ld      a,(hl)
            or      a
            ret     z
            dec     (hl)
            ret     nz
            ld      a,$01
            ld      (EXIT_REQUEST),a
            ret

Browser_Code_End:
            IF      Browser_Code_End > $D800
            ERROR   "native speech browser exceeds $D400-$D7FF"
            ENDIF

            END     Browser_Entry
