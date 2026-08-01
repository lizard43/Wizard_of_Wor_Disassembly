; wow_disassembly.asm
            INCLUDE src/wow_equates.include ; EQU for the code

;*****************************************************************************
; SYSTEM BOOT & HARDWARE INITIALIZATION
;*****************************************************************************
            ORG     $0000               ; ROM Start / Magic RAM start

            di                          ; Disable interrupts during boot
            ld      sp,BOOT_STACK_TOP   ; Initialize temporary boot stack
                                                ; (Pushes pre-decrement to $D3FF, top of Work RAM)

            ld      a, $01
L0006:      out     (CONCM), a          ; Video Mode: 1 = High Res (320x204)

L0008:      ld      a, $2C              ; 00101100b
L000A:      out     (HORCB), a          ; Set palette switch position and background color

L000C:      ld      a, $CC              ; $CC = 204
            out     (VERBL), a          ; Vertical Blank: Set screen height to 204 scanlines

            call    Initialize_Interrupt_Vector_And_Palette               ; Set interrupt vector to $CA & map color palette

            ld      a, $08              ; 00001000b (Bit 3 = 1)
            out     (INMOD), a          ; Interrupt Enable: Turn on Line Interrupts

;******************************************************************************************
; ----> SPECIAL CONTROL REGISTER 1 ($15)
;
; Note: Writes to this port are performed using IN instructions!
; Format: 0000 xxx y (xxx = function 0-7, y = 0 activate / 1 deactivate)
;******************************************************************************************
L0017:      ld      a, $00              ; 0000 000 0 (Function 0: Coin Counter 3)
            in      a, (CCMISC)         ; Activate Coin Counter 3 latch

            ld      a, $02              ; 0000 001 0 (Function 1: Coin Counter 2)
            in      a, (CCMISC)         ; Activate Coin Counter 2 latch

            ld      a, $0E              ; 0000 111 0 (Function 7: Unused/Light Transistor)
            in      a, (CCMISC)         ; Activate unused latch

            call     Set_Scanline_Int               ; Set scan line interrupt & enable sparkle colors

;******************************************************************************************
; ----> SET INTERRUPT MODE
;******************************************************************************************
L0026:      ld      a, $00              ; High byte for Interrupt Vector Table
            ld      i, a                ; Interrupts will be triggered from $0000-$00FF
            im      2                   ; Set Interrupt Mode 2

;******************************************************************************************
; GAME INITIALIZATION & MEMORY SETUP
;
; Prepares the TERSE script environment, clears buffers, and seeds RNG
;******************************************************************************************
            xor     a
            ld      (LD2D3), a          ; Initialize unknown variable to zero

;******************************************************************************************
; ----> EXPANSION ROM CHECK
;******************************************************************************************
L0030:      ld      a, (EXPHOOK)          ; Check High ROM extension socket
            cp      $C3                 ; Is the byte a 'JP' ($C3) instruction?
            call    z, EXPHOOK            ; If yes, execute external ROM initialization

;******************************************************************************************
; ----> HARDWARE VARIABLE SETUP
;******************************************************************************************
            ld      hl, LD03A           ; Point to Protected RAM variable ($D03A)
            ld      c, (hl)             ; Read current value into C
L003C:      inc     c                   ; Increment the value
            call    Protected_RAM_Write               ; Safely write C back through hardware latch

L0040:      ld      hl, (LD038)         ; Load word from Protected RAM $D038
            call    memcheck            ; Execute Nybble parity/complement check

            ld      hl, (LD03E)         ; Load word from Protected RAM $D03E
            call    memcheck            ; Execute Nybble parity/complement check

;******************************************************************************************
; ----> CREDIT LIMIT CHECK
;******************************************************************************************
            ld      a, (Credits)          ; Load Number of Credits
L004F:      cp      $1F                 ; Compare with 31 ($1F)
            call    nc, wiperam         ; If >= 31, zero out bottom of Static RAM

;******************************************************************************************
; ----> BUFFER CLEARING
;******************************************************************************************
L0054:      ld      hl, Is_Speech_Active ; Point to Speech Active flag ($D245)
            call    L00BA               ; Zero out 256 bytes (Sound/Speech buffers)
            call    wpfill              ; Zero out next 64 bytes

;******************************************************************************************
; ----> RNG SEED & PROTECTED RAM MIRRORING
;******************************************************************************************
            ld      a, r                ; Read Z80 Refresh Register for RNG entropy
            ld      (Random_Seed), a          ; Store as random number seed in Work RAM

            ld      hl, WPRAMSTART      ; Source = $D000 (Protected RAM)
            ld      de, P1_Lives           ; Dest   = $D300 (Work RAM)
L0068:      ld      bc, L0020           ; Length = $0020 (32 bytes)
            ldir                        ; Mirror Protected RAM to fast Work RAM

            call     Sys_Init               ; Clear screen, init video, clear Work RAM

;******************************************************************************************
; ----> TERSE SCRIPT DISPATCHER (THE GAME LOOP)
;
;       IY acts as the Instruction Pointer for TERSE script tokens.
;******************************************************************************************
            ld      a,(Game_Mode)       ; Check Game Mode variable
            and     a                   ; Is it 0 (Demo Mode)?
            ld      iy,ATTRACT_COMMAND_STREAM ; Default IY to attract-mode TERSE script
L0078:      jr      z,dispatch          ; If Demo Mode, jump to dispatcher loop
            ld      iy,GAME_COMMAND_STREAM ; Else, set IY to game-mode TERSE script

dispatch:   ld      hl,dispatch         ; Load address of this dispatcher loop
            push    hl                  ; Push it to stack (Tasks will 'ret' back here)

            call    Stream_Fetch_Word_HL               ; Fetch next TERSE token address into HL (IY++)
            push    hl                  ; Push TERSE subroutine address to stack

;******************************************************************************************
; ----> DIAGNOSTIC SWITCH ESCAPE HATCH
;******************************************************************************************
            in      a, (COINPORT)       ; Read hardware switches (Coin/Service)
L0088:      bit     3,a                 ; Check Service/Diagnostic Switch
            ret     nz                  ; If switch is OFF, 'ret' executes the TERSE task!

            ld      a,(Game_Mode)       ; If switch is ON, check if game in progress
            and     a                   ;
            ret     nz                  ; If game in progress, ignore switch and execute task

            jp      diags               ; Else, jump out of TERSE to native Z80 diagnostics!

;******************************************************************************************
; ----> INTERRUPT VECTOR & COLOR PALETTE MAPPING
;******************************************************************************************
Initialize_Interrupt_Vector_And_Palette:
            ld      a,$CA               ; Interrupt vector at $CA
            out     (INFBK),a           ; Set interrupt vector upper byte

            ld      hl,DEFPALETTE       ; Source: Color mapping table
            ld      bc,$080B            ; B = 8 (count), C = $0B (Color Block Transfer port)
            otir                        ; Rapidly blast 8 bytes from HL to port $0B
            ret

;******************************************************************************************
; ----> SET INTERRUPT VECTOR $CC
;******************************************************************************************
Select_Interrupt_Vector_CC:
            ld      a,$CC
            out     (INFBK),a           ; Set interrupt vector upper byte
L00A4:      ret

;******************************************************************************************
; ----> SET INTERRUPT VECTOR $CE
;******************************************************************************************
Select_Interrupt_Vector_CE:
            ld      a,$CE
            out     (INFBK),a           ; Set interrupt vector upper byte
            ret

;******************************************************************************************
; ----> MEMORY INTEGRITY / ANTI-TAMPER CHECK
;       Checks if L's nybbles are identical, and if H is the exact complement of L.
;******************************************************************************************
memcheck:   ld      a,l                 ; Copy L to A
L00AB:      rlca                        ; \
            rlca                        ; |
            rlca                        ; | Swap upper and lower nybbles of A
            rlca                        ; /
            cp      l                   ; Compare swapped nybbles to original L
            jr      nz,wiperam          ; IF different: Fail check! (Jumps to RAM wipe)
            cpl                         ; Complement A
            cp      h                   ; Compare to H
            ret     z                   ; IF match: Check passed! Return safely.

;******************************************************************************************
; ----> PROTECTED RAM WIPE ROUTINE
;       Zeros out the 64 bytes of Protected Static RAM ($D000 - $D03F).
;       Triggered by anti-tamper failure or >31 credits.
;******************************************************************************************
wiperam:    ld      hl,WPRAMSTART       ; Point HL to bottom of Static RAM ($D000)

;******************************************************************************************
; ----> PROTECTED MEMORY FILL ROUTINE
;       Fills B bytes of Protected RAM with the value in C.
;******************************************************************************************
wpfill:     ld      b,$40               ; B = 64 (bytes to write)

L00BA:      ld      c,$00               ; C = 0 (Fill value)
            ld      a,$A5               ; A = $A5 (Hardware NVRAM unlock byte)

L00BE:      out     (RIGHTPORT),a       ; Output $A5 to port $5B to unlock memory
L00C0:      ld      (hl),c              ; Write byte to protected RAM
            inc     hl                  ; Advance memory pointer
            djnz    L00BE               ; Loop until B = 0
            ret

;******************************************************************************************
; ----> DEFAULT COLOR PALETTE MAPPING TABLE
;
;       These bytes are sent to the Color Block Transfer port ($0B) during boot.
;******************************************************************************************
DEFPALETTE: DB      $51, $7C, $F3
L00C8:      DB      $C7, $00, $56, $09, $9E, $09, $B4, $09

;******************************************************************************************
; ----> VIDEO RAM FAILURE / CRASH HANDLER
;            Causes the screen to flash wildly by spamming random values to the palette port.
;******************************************************************************************
vramerr:    ld      a,r                 ; Get random value from Z80 Refresh Register
            out     (HORCB),a           ; Output to background color / palette port

;******************************************************************************************
; ----> VIDEO RAM TEST / FILL ROUTINE
;            Stackless memory test. Propagates a test byte across VRAM ($4000-$7FFF),
;            checks it, then propagates the inverted byte backwards.
;            Expects return address in HL (uses EXX to preserve it without the stack).
;******************************************************************************************
vramtest:   exx                         ; Swap registers (saves return address into HL')
            ld      hl,$4000            ; Point HL to start of Video RAM
            ld      (hl),a              ; Write the test pattern to $4000

            ld      de,$4001            ; Point DE to the next byte ($4001)
            ld      bc,$3FFF            ; Count = 16KB minus 1 byte
            ldir                        ; Rapidly copy (HL) to (DE), filling VRAM upward

            cp      (hl)                ; Does the last written byte still match the pattern?
            jr      nz, vramerr         ; IF NOT: Memory failed! Jump to crash handler

            ex      af,af'              ; Save Accumulator and Flags
            in      a, (COINPORT)       ; Read hardware switches (Hardware Watchdog kick)
            ex      af,af'              ; Restore Accumulator and Flags

            dec     de                  ; \ Adjust DE from $8000 down to $7FFE
            dec     de                  ; / for the reverse fill operation

            cpl                         ; Invert the test pattern in A (e.g. $80 becomes $7F)
            ld      (hl),a              ; HL is now $7FFF. Write inverted pattern to top of VRAM
            ld      bc,$3FFF            ; Count = 16KB minus 1 byte
            lddr                        ; Rapidly copy (HL) to (DE) backwards, filling VRAM downward

            cp      (hl)                ; Does the last written byte still match inverted pattern?
            jr      nz, vramerr         ; IF NOT: Memory failed! Jump to crash handler

            ex      af,af'              ; Save Accumulator and Flags
            in      a, (COINPORT)       ; Read hardware switches (Hardware Watchdog kick)
            ex      af,af'              ; Restore Accumulator and Flags

            cpl                         ; Invert the pattern back to its original state
            exx                         ; Swap registers back (restores return address into HL)
            jp      (hl)                ; Stackless return! Jump to address in HL

;******************************************************************************************
; ----> HARDWARE DIAGNOSTICS & MEMORY TEST ENTRY
;            Disables interrupts, checks for an expansion ROM, resets hardware state,
;            and seeds the Video RAM worm test with the initial pattern ($80).
;******************************************************************************************
diags:      di                          ; Disable interrupts during diagnostics
            ld      a,(EXPHOOK)           ; Check High ROM extension socket
L00FF:      cp      $C3                 ; Is the byte a 'JP' ($C3) instruction?
L0101:      call    z,EXPHOOK             ; If yes, execute external diagnostic ROM

            call    Enable_Sparkle_Colors               ; Reset hardware state / sparkle colors

            ld      a,$80               ; A = $80 (10000000b) initial VRAM test pattern
                                        ; Falls through into the Video RAM worm test...
;
;******************************************************************************************
; ----> VIDEO RAM WORM TEST LOOP
;            Sets the stackless return address to L010E and executes the VRAM fill/check.
;******************************************************************************************
L0109:      ld      hl,L010E            ; Set return address for stackless memory test
            jr      vramtest            ; Execute VRAM test (vramtest)

;******************************************************************************************
; ----> TEST PATTERN SHIFTER
;            Shifts the walking bit right. If 0, the test is complete.
;******************************************************************************************
L010E:      and     a                   ; Check if the walking bit has shifted out (A=0)
            jr      z,Game_Entry        ; IF 0: VRAM test passed! Jump to game start
L0111:      rra                         ; Rotate the test bit right (e.g., $80 -> $40)
            jr      L0109               ; Loop back to test VRAM with the new pattern

;******************************************************************************************
; ----> MAIN GAME ENTRY & STACK SETUP
;            Moves the temporary boot stack to its permanent home in the non-viewable
;            Video RAM margin ($7FC0 - $7FFF) and prints the success message.
;******************************************************************************************
Game_Entry:
            ld      sp,PERMANENT_STACK_TOP ; Set permanent stack (pre-decrements to $7FFF)

L0117:      call     Sys_Init               ; Clear screen, init video, and clear Work RAM

            ld      hl,L042E            ; Source string: "SCREEN RAM OK"
            ld      de,$001A            ; String formatting and color attributes
            ld      b,$0D               ; String length (13 characters)
            call    L03B3               ; Execute string print routine
;
;******************************************************************************************
; ----> STATIC RAM TEST
;
;            Three-pass memory test for the 1KB NVRAM ($D000 - $D3FF).
;            Pass 1: Fills upward with $FF. Pass 2: Fills downward with $00.
;            Pass 3: Scans upward to verify all bytes remain $00.
;******************************************************************************************
            ld      hl,WPRAMSTART       ; HL = $D000 (Start of Static RAM)
            ld      bc,$0004            ; B = 0 (256 loops), C = 4 (1KB total)
            ld      d,$FF               ; D = $FF (Initial test pattern)
            ld      a,$A5               ; A = $A5 (Hardware NVRAM unlock byte)

L012F:      out     (RIGHTPORT),a       ; Unlock NVRAM for writing
            ld      (hl),d              ; Write $FF pattern to memory
            ld      d,(hl)              ; Read it back into D to test data bus
            inc     hl                  ; Advance memory pointer upward
            djnz    L012F               ; Inner loop: write 256 bytes
            dec     c                   ; Outer loop: 4 blocks (1024 bytes)
            jr      nz,L012F

            ld      a,d                 ; Check the last byte read
            cp      $FF                 ; Did the data bus hold the $FF?
            jr      nz,L016C            ; IF NOT: Memory failed! Jump to error handler

            ld      c,$04               ; Reset outer loop counter for 1KB
L0140:      inc     d                   ; Bump test pattern: $FF + 1 = $00
            ld      a,$A5               ; A = $A5 (NVRAM unlock byte)

L0143:      out     (RIGHTPORT),a       ; Unlock NVRAM for writing
            dec     hl                  ; Advance memory pointer downward (Starts at $D400 -> $D3FF)
            ld      (hl),d              ; Write $00 pattern to memory
            ld      d,(hl)              ; Read it back into D
            djnz    L0143               ; Inner loop: write 256 bytes
            dec     c                   ; Outer loop: 4 blocks (1024 bytes)
            jr      nz,L0143

            ld      a,d                 ; Check the last byte read
            and     a                   ; Did the data bus hold the $00?
            jr      nz,L016C            ; IF NOT: Memory failed! Jump to error handler

            ld      c,$04               ; Reset outer loop counter for 1KB
L0153:      or      (hl)                ; Accumulate any non-zero bits into A
L0154:      inc     hl                  ; Advance memory pointer upward
L0155:      djnz    L0153               ; Inner loop: scan 256 bytes
            dec     c                   ; Outer loop: 4 blocks
            jr      nz,L0153

            and     a                   ; Are there ANY non-zero bits left in the entire 1KB?
            jr      nz,L016C            ; IF YES: Memory failed! Jump to error handler

;******************************************************************************************
; ----> STATIC RAM TEST PASS / FAIL HANDLER
;
;            Performs one final checkerboard byte check, then prints the RAM status.
;******************************************************************************************
            ld      a,$55               ; A = $55 (01010101b checkerboard pattern)
            ld      (LD045),a           ; Write $55 to $D045 (Static RAM)
            ld      a,(LD045)           ; Read it back
            cp      $55                 ; Did it hold the $55 without shorting adjacent bits?

            ld      hl,$043B            ; Source string: "STATIC RAM OK "
L016A:      jr      z,L016F             ; IF PASSED: Jump to print string

L016C:      ld      hl,L0449            ; Source string: "STATIC RAM BAD"

L016F:      ld      de,$051A            ; String formatting and color attributes
            ld      b,$0E               ; String length (14 characters)
            call    L03B3               ; Execute string print routine
;
;******************************************************************************************
; ----> ROM INTEGRITY TEST
;
;            Sums the bytes of each 4KB ROM chip and compares against a checksum table.
;            Uses EXX to juggle two sets of pointers (ROM/Checksums vs Name Strings).
;******************************************************************************************
            ld      hl,L0457            ; Source string: "ROM "
            ld      de,$0A28            ; DE = Color and screen formatting
            call    L03B1               ; Print "ROM "

            ld      hl,L03D5            ; HL = String "ABCDEFGX" (ROM labels)
            exx                         ; Swap to Alternate Registers (HL' now holds labels)

            ld      de,L03E0            ; DE = Expected ROM Checksums Table
            ld      hl,$0000            ; HL = $0000 (Start of ROM memory)

;******************************************************************************************
; ----> CHECK DIP SWITCH FOR FOREIGN ROM
;******************************************************************************************
            ld      a,($D347)           ; (Dummy read)
            in      a, (SETTINGS)       ; Read Dip Switches (Port $13)
            bit     3,a                 ; Check Language Switch (On = English)
            ld      b,$07               ; Default to 7 ROMs (A through G)
            jr      nz,romcheck         ; IF English: Jump to test
            inc     b                   ; IF Foreign: Set count to 8 ROMs (A through X)

;******************************************************************************************
; ----> BEGIN ROM CHECK LOOP
;******************************************************************************************
romcheck:   push    bc                  ; Save ROM loop counter

;******************************************************************************************
; ----> MEMORY GAP SKIPS (VRAM & EMPTY SOCKETS)
;******************************************************************************************
            ld      a,h                 ; Check current ROM high byte
            cp      $40                 ; Is pointer at $4000 (Start of Video RAM)?
            jr      nz,L019E            ; IF NOT: Skip to next check
            ld      h,$80               ; IF YES: Jump over VRAM directly to High ROMs ($8000)

L019E:      cp      $B0                 ; Is pointer at $B000 (Empty socket)?
            jr      nz,L01A7            ; IF NOT: Skip ahead
            ld      de,$C00A            ; IF YES: Redirect expected checksum pointer
            ld      h,$C0               ; And jump pointer to Alternate ROM space ($C000)
;******************************************************************************************
; ----> 4KB CHECKSUM CALCULATION (modulo-256 checksum)
;******************************************************************************************
L01A7:      ld      bc,$0010            ; B = 0 (256 loops), C = 16 (16 * 256 = 4096 bytes)
            xor     a                   ; A = 0 (Clear accumulator for checksum)
L01AB:      add     a,(hl)              ; Accumulate byte into A
            inc     hl                  ; Advance to next ROM byte
            djnz    L01AB               ; Inner loop: 256 bytes
            dec     c                   ; Outer loop: 16 blocks (4KB total)
            jr      nz,L01AB

;******************************************************************************************
; ----> COMPARE AND PRINT RESULTS
;******************************************************************************************
            ex      de,hl               ; Swap ROM pointer and Checksum Table pointer
            cp      (hl)                ; Compare calculated sum (A) with expected sum (HL)
            inc     hl                  ; Advance Checksum Table pointer for next pass
            ex      de,hl               ; Swap pointers back

            exx                         ; Swap to Alternate Registers (HL' = "ABCDEFGX")
            jr      z,L01C1             ; IF CHECKSUM MATCHES: Jump ahead to next letter

            ld      a,d                 ; IF CHECKSUM FAILS: Save color formatting from D'
            ld      (ROMFAIL),a         ; Store it in RAM
            call    Write_1_Char               ; Print the failing ROM's letter (pointed to by HL')
            dec     hl                  ; Adjust string pointer backwards so it stays aligned

L01C1:      inc     hl                  ; Advance string pointer to next ROM letter ("A" -> "B")
            exx                         ; Swap back to Main Registers
            pop     bc                  ; Restore ROM loop counter
            djnz    romcheck            ; Loop until all 7 (or 8) ROMs are checked

;******************************************************************************************
; ----> HARDWARE DIAGNOSTICS & SWITCH TEST SCREEN (UI SETUP)
;
;            Draws the text labels for the diagnostic screen.
;******************************************************************************************
            exx                         ; Restore registers after ROM test
            ld      hl,$0446            ; Source string: "OK"
            ld      a,(ROMFAIL)         ; Read ROM failure flag ($D1D4)
            and     a                   ; Is it zero? (No failures)
            call    z,Write_2_Chars             ; IF 0: Print "OK"

            ld      a,$01
            ld      (DIAGFLAG),a        ; Set diagnostic screen active flag

;******************************************************************************************
; ----> DRAW INPUT LABELS
;******************************************************************************************
            ld      de,$1403            ; Screen formatting attributes
            call    L03A7               ; Print "MOVE" (Player 1 side)
            ld      e,$30
            call    L03A7               ; Print "MOVE" (Player 2 side)

L01E1:      ld      de,$1E0B
            call    L03AE               ; Print "FIRE" (Player 1 side)
            ld      e,$38
            call    L03AE               ; Print "FIRE" (Player 2 side)

            ld      hl,L0408            ; Source string: "PL1"
            ld      de,$230B
            call    Print_3_Chars               ; Print "PL1"
            ld      hl,L040B            ; Source string: "PL2"
            ld      e,$38
            call    Print_3_Chars               ; Print "PL2"

L01FD:      ld      de,$280B
L0200:      ld      hl,L03DD            ; Source string: "123" (Coin inputs)
L0203:      call    L03BA               ; Print "123"
L0206:      ld      e,$38
            call    L03BA               ; Print "123" again
L020B:      ld      e,$22
            call    L03BA               ; Print "123" again

            ld      de,$2D0B
            ld      hl,L0412            ; Source string: "SLAM"
            call    L03B1               ; Print "SLAM"

            ld      hl,L0416            ; Source string: "SW1SW2..." (Dip switches)
            ld      de,$2D22
            call    L03C4               ; Print dip switch labels
            ld      de,$2D38
            call    L03C4               ; Print more dip switch labels

;******************************************************************************************
; ----> HARDWARE DIAGNOSTICS INPUT LOOP
;
;       Reads ports, complements them (active-low to active-high), isolates bits,
;       and uses Print_YesNo to selectively print "YES" or "NO" if the state changed.
;******************************************************************************************
diagloop:   ei                          ; Enable interrupts to allow screen refresh

            ld      de,LD1D6            ; Point to Player 2 / Cocktail controls buffer
            in      a, (P2PORT)         ; Read Port $11 (Player 2 joystick/buttons)
            cpl                         ; Invert (Active-low to active-high)
            ld      (de),a              ; Save Player 2 state to $D1D6

L0230:      ld      de,LD1D7            ; Point to Player 1 controls buffer
            in      a, (P1PORT)         ; Read Port $12 (Player 1 joystick/buttons)
            cpl
            ld      (de),a              ; Save Player 1 state to $D1D7

;******************************************************************************************
; ----> CHECK JOYSTICK DIRECTIONS (Port $11 / $12)
;******************************************************************************************
            ; Player 2 Joystick Check
            ld      de,$190B            ; DE = Screen formatting and position attributes for P2
            ld      hl,LD1CE            ; HL = Pointer to P2 joystick state tracking variable ($D1CE)
            ld      a,(LD1D6)           ; A = Load Player 2 controls state (Read from Port $11)
            call    L0317               ; Call L0317 to evaluate the direction status (lower nybble)

            ; Player 1 Joystick Check
            ld      de,$1939            ; DE = Screen formatting and position attributes for P1
            ld      hl,LD1CF            ; HL = Pointer to P1 joystick state tracking variable ($D1CF)
            ld      a,(LD1D7)           ; A = Load Player 1 controls state (Read from Port $12)
            call    L0317               ; Call L0317 to evaluate the direction status (lower nybble)

;*****************************************************************************************
; ----> CHECK RIGHT FIRE BUTTONS (Port $11 / $12, Bit 4)
;
; Secondary fire buttons located on the right side of the joystick.
;*****************************************************************************************
            ld      de,$1903            ; DE = Screen formatting/position for P2 Right Fire
            ld      hl,LD1D0            ; HL = Pointer to P2 Right Fire tracking var ($D1D0)
            ld      a,(LD1D6)           ; A = Load Player 2 controls state again
            and     $10                 ; Isolate Bit 4 (00010000b) to check Button 2 (Right)
            call    Print_YesNo               ; Call Print_YesNo to test bit and print "YES" or " NO"

            ld      e,$30               ; E = Update column coordinate for P1 (DE = $1930)
            ld      hl,LD1D1            ; HL = Pointer to P1 Right Fire tracking var ($D1D1)
            ld      a,(LD1D7)           ; A = Load Player 1 controls state again
            and     $10                 ; Isolate Bit 4 (00010000b) to check Button 2 (Right)
            call    Print_YesNo               ; Call Print_YesNo to test bit and print "YES" or " NO"

;*****************************************************************************************
; ----> CHECK LEFT FIRE BUTTONS (Port $11 / $12, Bit 5)
;
; Primary fire buttons located on the left side of the joystick.
;*****************************************************************************************
            ld      de,$1E03            ; DE = Screen formatting/position for P2 Left Fire
            ld      hl,LD1CC            ; HL = Pointer to P2 Left Fire tracking var ($D1CC)
            ld      a,(LD1D6)           ; A = Load Player 2 controls state (Port $11)
            and     $20                 ; Isolate Bit 5 (00100000b) to check Button 1 (Left)
            call    Print_YesNo               ; Test bit and print "YES" or " NO" if state changed

            ld      e,$30               ; E = Update column coordinate for P1 (DE = $1E30)
            ld      hl,LD1CD            ; HL = Pointer to P1 Left Fire tracking var ($D1CD)
            ld      a,(LD1D7)           ; A = Load Player 1 controls state (Port $12)
            and     $20                 ; Isolate Bit 5 (00100000b) to check Button 1 (Left)
            call    Print_YesNo               ; Test bit and print "YES" or " NO" if state changed

;*****************************************************************************************
; ----> CHECK START BUTTONS (Port $10, Bits 5 & 6)
;
; Evaluates the 1-Player and 2-Player Start buttons.
;*****************************************************************************************
            ld      de,$2303            ; DE = Screen formatting/position for PL1 Start
            ld      hl,LD1D2            ; HL = Pointer to PL1 Start tracking var ($D1D2)
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
            cpl                         ; Invert (Active-LOW hardware to Active-HIGH)
            and     $20                 ; Isolate Bit 5 (00100000b) to check PL1 Start
            call    Print_YesNo               ; Test bit and print "YES" or " NO" if changed

            ld      e,$30               ; E = Update column coordinate for PL2 (DE = $2330)
            ld      hl,LD1D3            ; HL = Pointer to PL2 Start tracking var ($D1D3)
            in      a, (COINPORT)       ; Read System Inputs again
            cpl                         ; Invert (Active-LOW hardware to Active-HIGH)
            and     $40                 ; Isolate Bit 6 (01000000b) to check PL2 Start
            call    Print_YesNo               ; Test bit and print "YES" or " NO" if changed

;*****************************************************************************************
; ----> CHECK COIN SWITCHES (Port $10, Bits 0, 1, 2)
;
;       Polls the three coin slot microswitches.
;*****************************************************************************************
L02A0:      ld      de,$2803            ; DE = Screen formatting/position for Coin 1 ($2803)
            ld      hl,LD1C9            ; HL = Pointer to Coin 1 tracking var ($D1C9)
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
L02A8:      cpl                         ; Invert (Active-LOW hardware to Active-HIGH)
            and     $01                 ; Isolate Bit 0 (00000001b) to check Coin 1
            call    Print_YesNo               ; Test bit and print "YES" or " NO" if changed

            ld      e,$30               ; E = Update column coordinate for Coin 2 ($2830)
            ld      hl,LD1CA            ; HL = Pointer to Coin 2 tracking var ($D1CA)
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
            cpl                         ; Invert (Active-LOW to Active-HIGH)
            and     $02                 ; Isolate Bit 1 (00000010b) to check Coin 2
            call    Print_YesNo               ; Test bit and print "YES" or " NO"

            ld      e,$1A               ; E = Update column coordinate for Coin 3 ($281A)
            ld      hl,LD1CB            ; HL = Pointer to Coin 3 tracking var ($D1CB)
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
            cpl                         ; Invert (Active-LOW to Active-HIGH)
            and     $04                 ; Isolate Bit 2 (00000100b) to check Coin 3
            call    Print_YesNo               ; Test bit and print "YES" or " NO"

;*****************************************************************************************
; ----> CHECK SLAM SWITCH (Port $10, Bit 4)
;
;       Polls the anti-cheat slam tilt switch inside the coin door.
;*****************************************************************************************
            ld      de,$2D03            ; DE = Screen formatting/position for SLAM ($2D03)
            ld      hl,LD1D5            ; HL = Pointer to SLAM tracking var ($D1D5)
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
            cpl                         ; Invert (Active-LOW to Active-HIGH)
L02D1:      and     $10                 ; Isolate Bit 4 (00010000b) to check SLAM
            call    Print_YesNo         ; Test bit and print "YES" or " NO"

;*****************************************************************************************
; ----> DIP SWITCH TEST LOOP (Initialization)
;
;       Reads the hardware DIP switches (Settings port) and sets up the loop to test all 8.
;*****************************************************************************************
            ld      a,($D347)           ; MACRO ARTIFACT: Useless read of orphaned RAM
            in      a, (SETTINGS)       ; PATCH: Read DIP Switches (Port $13) over A
L02DB:      cpl                         ; Invert (Active-LOW to Active-HIGH)
            ld      b,a                 ; Store the inverted DIP switch state in B
            ld      de,$2D1A            ; DE = Screen position for SW1 ($2D1A)
                                        ;      NOTE: Disassembler artifact 'L2D1A'
            ld      hl,LD1D8            ; HL = Pointer to SW1 tracking var ($D1D8)
            ld      c,$01               ; C = Initialize shifting bitmask to Bit 0 ($01)
L02E5:      push    hl                  ; Save state variable pointer
            push    bc                  ; Save port state (B) and bitmask (C)
            ld      a,b                 ; Load DIP switch state into A
            and     c                   ; Isolate the current bit using the mask in C
            push    de                  ; Save screen coordinates
            call    Print_YesNo         ; Test bit and print "YES" or " NO"

;*****************************************************************************************
; ----> DIP SWITCH TEST LOOP (Continuation)
;
;       Iterates through the 8 hardware dip switches, moving the cursor down the screen
;       for each switch. Once SW4 is reached, it jumps to a new column for SW5-SW8.
;*****************************************************************************************
            pop     de                  ; Restore DE (Screen formatting/coordinates)
            pop     bc                  ; Restore B (Settings port state) and C (Bitmask)
            ld      hl,$0500            ; HL = $0500 (Used to add 5 to the Row byte 'D')
            add     hl,de               ; Add $0500 to DE (Drops the cursor down 5 rows)
            ex      de,hl               ; DE now holds the updated screen coordinates
            pop     hl                  ; Restore HL (State tracking variable pointer)
            inc     hl                  ; Advance pointer to the next switch's memory state
            ld      a,c                 ; Load current bitmask into A
            cp      $08                 ; Have we just finished checking SW4 (Bitmask $08)?
            jr      nz,L02FE            ; If not, skip the column reset
            ld      de,$2D30            ; If yes, move cursor to the next column (Row $2D, Col $30)
                                        ; NOTE: Disassembler artifact mistakenly labeled this 'L2D30'.
L02FE:      sla     c                   ; Shift bitmask left (e.g., $01 -> $02 -> $04)
L0300:      jr      nz,L02E5            ; If mask is not 0 (8 bits not done), loop back to L02E5

;*****************************************************************************************
; ----> EVALUATE DIAGNOSTIC SCREEN ADVANCE OR EXIT
;
; Checks input port $10 to see if the operator is advancing the test or exiting.
;*****************************************************************************************
L0302:      in      a, (COINPORT)       ; Read System Inputs (Port $10)
            and     $60                 ; Isolate Bits 5 & 6 (likely Coin or Start inputs)
L0306:      jr      z,L0310             ; If both are pressed (0), advance to next diagnostic phase

            in      a, (COINPORT)       ; Read System Inputs again
            bit     3,a                 ; Check Bit 3 (Service/Diagnostic Switch inside coin door)
            jp      z,diagloop          ; Active-LOW: If 0 (Switch ON), loop back and keep diagnosing
L030F:      rst     00H                 ; Active-HIGH: If 1 (Switch OFF), soft reset back to the game!
;
;*****************************************************************************************
; ----> ADVANCE TO CROSSHATCH / BURN-IN TEST
;
; Triggered by pressing both Start buttons. Clears the screen and jumps to the grid draw.
;*****************************************************************************************
L0310:      di                  ; Disable interrupts
            call     Sys_Init       ; Call video initialization and screen clear routine
L0314:      jp      $AF80       ; Jump to EOF routine to draw alignment grid and halt

;*****************************************************************************************
; ----> JOYSTICK DIRECTION EVALUATOR
;
; Isolates the lower nybble (joystick directions) and checks for state changes.
;*****************************************************************************************
L0317:      and     $0F         ; Isolate bits 0-3 (Up, Down, Left, Right)
            cp      (hl)        ; Compare current joystick state against previous state
            ret     z           ; Return immediately if the joystick hasn't moved

;*****************************************************************************************
; ----> Disp_Joy_Str
;       Called to print the state of the joystick in diagnostics mode.
;       First clears the string area, then uses a jump table to print
;       directional combinations ("UP", "LF_DN", "ERROR", etc.).
;*****************************************************************************************
            ld      (hl),a
            ld      c,a
            ld      b,$00
Disp_Joy_Str:
            push    bc
Clear_Joy_Str:
            push    de
            ld      b,$05               ; Print 5 spaces to clear old string
            xor     a
            call    L03B5
            pop     de
Do_Joy_Jump:
            pop     bc
            ld      hl,Joy_String_Table
            add     hl,bc
            add     hl,bc               ; Calculate table offset (BC * 2)
            ld      a,(hl)
            inc     hl
            ld      h,(hl)
Exec_Joy_Jump:
            ld      l,a
            jp      (hl)                ; Jump to specific string routine

;*****************************************************************************************
; ----> Joy_String_Table
;       16-entry jump table for joystick switch combinations.
;*****************************************************************************************
Joy_String_Table:
            DW      Write_NO            ; 00: "NO" (No direction pressed)
            DW      Write_UP            ; 01: "UP"
            DW      Write_DN            ; 02: "DN"
            DW      Write_ERROR         ; 03: UP+DN (Invalid)
            DW      Write_LF            ; 04: "LF"
            DW      Write_LF_UP         ; 05: "LF_UP"
            DW      Write_LF_DN         ; 06: "LF_DN"
            DW      Write_ERROR         ; 07: UP+DN+LF (Invalid)
            DW      Write_RT            ; 08: "RT"
            DW      Write_RT_UP         ; 09: "RT_UP"
            DW      Write_RT_DN         ; 10: "RT_DN"
            DW      Write_ERROR         ; 11: UP+DN+RT (Invalid)
            DW      Write_ERROR         ; 12: LF+RT (Invalid)
            DW      Write_ERROR         ; 13: LF+RT+UP (Invalid)
            DW      Write_ERROR         ; 14: LF+RT+DN (Invalid)
            DW      Write_ERROR         ; 15: LF+RT+UP+DN (Invalid)

Write_NO:
            ld      hl,L03EC            ; String "NO"
Write_2_Chars:
            ld      b,$02
            jr      L03B3               ; Write String
Write_UP:
            ld      hl,L03EE            ; String "UP"
            jr      Write_2_Chars
Write_DN:
            ld      hl,L03F0            ; String "DN"
            jr      Write_2_Chars
Write_ERROR:
            ld      hl,L03F7            ; String "ERROR"
            ld      b,$05
            jp      L03B3               ; Write String

Write_LF:
            ld      hl,L03F2            ; String "LF"
            jr      Write_2_Chars
Write_UScore:
            ld      hl,L03F6            ; String "_" (Used to link diagonals)
Write_1_Char:
            ld      b,$01
            jr      L03B3               ; Write string

Write_LF_UP:
            call    Write_LF
Write__UP:
            call    Write_UScore
            jr      Write_UP
Write_LF_DN:
            call    Write_LF
Write__DN:
            call    Write_UScore
            jr      Write_DN
Write_RT:
            ld      hl,L03F4            ; String "RT"
            jr      Write_2_Chars
Write_RT_UP:
            call    Write_RT
            jr      Write__UP
Write_RT_DN:
            call    Write_RT
            jr      Write__DN
;*****************************************************************************************
; ----> Print_YesNo (Evaluate Switch State & Update Screen)
; Compares the current bit (A) against the previous state (HL). If the state has
; changed, it updates the state and prints "YES" or " NO" on the diagnostic screen.
;*****************************************************************************************
Print_YesNo:
            cp      (hl)                ; Compare current bit (A) against previous state
            ret     z                   ; Return immediately if the state hasn't changed
            ld      (hl),a              ; State changed! Overwrite old state with new
            and     a                   ; Is the new state 0 (Unpressed) or >0 (Pressed)?
            ld      hl,$03EB            ; Pre-load HL with pointer to string " NO"
            jr      z,Print_3_Chars     ; If state is 0, jump ahead to print
            ld      hl,L03E8            ; If state > 0, overwrite HL with pointer to "YES"

Print_3_Chars:
            ld      b,$03               ; Length of string is 3 characters
            jr      L03B3               ; Jump to the string printing engine
;
;*****************************************************
; Write "MOVE"
;*****************************************************
;
L03A7:      ld      hl,L0400            ; String "MOVE"
            ld      b,$08               ; Length
            jr      L03B3               ; Write string
;
;*****************************************************
; Write "FIRE"
;*****************************************************
;
L03AE:      ld      hl,L03FC            ; String "FIRE"
L03B1:      ld      b,$04               ; Length
;
;*****************************************************
; Entry Point to "write string" command?
; Parameters:
;    HL=<start address of string (ASCII)
;    DE=<color> ???
;    B=<Length of string (ASCII Character count)
; Other:
;    A= Expand mode color ???
;    C=???
;*****************************************************
;
L03B3:      ld      a,$0C               ; Expand mode color ???
L03B5:      ld      c,$FF               ; ???
            jp      printstr            ; Go write the string...
;
;*****************************************************
; ???
;
;*****************************************************
L03BA:      push    hl
            ld      hl,L040E
            call    L03B1
            pop     hl
            jr      Write_1_Char
;
;*****************************************************
; ??? Write string of some kind... strange stuff going on.
;
;*****************************************************
L03C4:      ld      b,$04               ; ???
L03C6:      push    bc                  ; Save ???
            call    Print_3_Chars               ; B=3 and drop to write string
            push    hl                  ; save ???
            ld      hl,$04FA            ; HL is in graphic characters area ???
            add     hl,de               ; ???
            ex      de,hl               ; DE now has ???
            pop     hl                  ; Restore ???
            pop     bc                  ; Restore count
            djnz    L03C6               ; Loop until ???
            ret                         ; Go back

;*****************************************************
; Begin Data area for "Words" in diagnostics
; Note: "@" is used as a space. ??? Verify
;    "_" is used as ??? Verify
;*****************************************************

L03D5:      DB      "ABCDEFGX"
L03DD:      DB      "123"
L03E0:      DB      $00, $6d, $f4, $2e, $62, $9d, $d4, '*' ;Could this be ROM checksums???
L03E8:      DB      "YES@"
L03EC:      DB      "NO"
L03EE:      DB      "UP"
L03F0:      DB      "DN"
L03F2:      DB      "LF"
L03F4:      DB      "RT"
L03F6:      DB      "_"
L03F7:      DB      "ERROR"
L03FC:      DB      "FIRE"
L0400:      DB      "MOVE@DI"
            DB      'R'
L0408:      DB      "PL1PL2CO"
L0410:      DB      "IN"
L0412:      DB      "SLAM"
L0416:      DB      "SW1SW2SW3S"
L0420:      DB      "W4SW5SW6SW7SW8"
            DB      "SCREEN@RAM@O"
L043A:      DB      "KSTATIC@RAM@OK@"
L0449:      DB      "STATIC@RAM@BAD"
L0457:      DB      "ROM@"
            DB      $00                 ; ???
;
;*****************************************************
; ???
;*****************************************************
;
L045C:      ld      c,$10
            in      c,(c)
;
;*****************************************************
; Write string to screen.
; Set up "expand mode color in A
; and "???" in C
;*****************************************************
;
printstr:   di                          ; No interruptions
            out     (XPAND),a           ; Expand mode color ???
            bit     7,c                 ; Check for???
            ld      a,$08               ; Setup for expand mode only... !!! change this to binary
            jr      nz,L046B            ;   and skip ahead.
            set     6,a                 ; Otherwise, set ??? bit
L046B:      out     (MAGIC),a           ; Out to "Magic RAM control"
L046D:      ld      a,(hl)              ; Get the character of the string
            inc     hl                  ; Set up for next character
            push    hl                  ; Save next character location
            push    de                  ; Save the color of character
            call    char2gfx            ; Translate ASCII into graphic location
            pop     de                  ; Restore color of character
            bit     7,c                 ; Check for cocktail again??? unless char2gfx changed c... check it. ???
            ld      a,$26               ; Set normal line offset value
            jr      nz,L047D            ; ... skip the modification for ???
            xor     $30                 ; Modification to ???
L047D:      out     (PBSTAT),a          ; Set up line offset value???
            ld      a,l                 ;
            out     (PBLINADRL),a       ; LSB of source
            ld      a,h
            out     (PBLINADRH),a       ; MSB of source
            ld      a,e
            out     (PBXMOD),a          ; LSB of destination
            ld      a,d
            out     (PBAREADRH),a       ; MSB of destination
            bit     7,c                 ; Check for cocktail... ???
            ld      a,$4F               ; Set up for normal ???
            jr      nz,L0493            ; Skip the mod for ??? if not cocktail
            ld      a,$B1               ; Otherwise, set up for ???
L0493:      out     (PBXMOD),a          ; ??? what is this ???
            ld      a,$01
            out     (PBXWIDE),a         ; Set width of pattern
            ld      a,$09
            out     (PBYHIGH),a         ; Height of pattern and start transfer!
            pop     hl                  ; Restore the next character to HL
            inc     de                  ;
            inc     de                  ; Why did we double DE???
            bit     7,c                 ; cocktail???
            jr      nz,L04A8            ; ... yes, skip mod of DE for ???
            dec     de
            dec     de
            dec     de
            dec     de                  ; Mod for ???
L04A8:      djnz    L046D               ; Character finished, go back and do
                ; next character until all of string is finished.
            ret                         ; String is done, return to sender...
;
;********************************************************************
; Name:            char2gfx
;
; Title:        ASCII to GRAPHICS Table lookup
;
; Function:        Take an ASCII character and translate it into
;            a graphic entry in a character table. It is not
;            true ASCII, but a subset with some modifications.
;            See character table at CHRTBL for details.
;            It also handles translation to alternate ROM set.
;
; Entry:        A  = ASCII character
;
; Exit:            HL = Address entry in table which corrosponds
;                 with the ASCII character.
;
; Registers used:    A, DE, HL  ???verify
;
;********************************************************************
;
char2gfx:   sub     $30                 ; Turn ASCII into table entry
            cp      $0A                 ; Check for number 0-9
            jr      c,L04B3             ; Jump if not a number...
            sub     $06                 ; Adjust to take out unsupported characters
                ; ... between "9" and "A" (":;<=>?")
L04B3:      ld      l,a                 ; L = table entry
            sub     $2C                 ; Check for alternate characters???
            ld      de,CHRTBL           ; Entry to character table
            jr      c,L04C2             ; Skip alternate ROM set
            ld      hl,LC00B            ; Entry of table to alternate ROM character set
            ld      e,(hl)              ; \
            inc     hl                  ;  Manipulations for Alternate ROM set.
            ld      d,(hl)              ;  Need to figure out what it does later... ???
            ld      l,a                 ; /
L04C2:      ld      h,$00               ;
            add     hl,hl               ; Begin multiplying HL * $0A
            push    de                  ; Push beginning of table address
            ld      d,h                 ;
            ld      e,l                 ;
            add     hl,hl               ;
            add     hl,hl               ;
            add     hl,de               ; Multiply HL * $0A complete. This is table offset.
            pop     de                  ; Restore beginning of table address
            add     hl,de               ; Add start of table address with offset to give table entry.
            ret                         ; Thou are done with thy translation!

;******************************************************************************
; Name:        Graphic_Character_Table
; Games:    Wizard of Wor (horizontal monitor)
; Purpose:    This is the Wizard of Wor character set in graphical format.
; Description:    This is the data area for alphabetic and a few special
;        characters in graphic format. It has the following charastics:
;
;           1. Character patterns are stored in a bitmap 1 by 5 bytes
;           2. Every bit is doubled by theMagic Expand mode.
;           3. The pixel color it is converted to is based on the ???
;              register, which tells what to expand each set bit
;              or reset bit into.
;           4. Each character is $0A apart.
;
;Example:    Character "A"
;
;        Data    Expanded    Expanded two
;            one bit        bits per byte
;            per byte
;
;        $18    ---XX---    ------XXXX------
;        $3C    --XXXX--    ----XXXXXXXX----
;        $7E    -XXXXXX-    --XXXXXXXXXXXX--
;        $66    -XX--XX-    --XXXX----XXXX--
;        $66    -XX--XX-    --XXXX----XXXX--
;        $66    -XX--XX-    --XXXX----XXXX--
;        $7E    -XXXXXX-    --XXXXXXXXXXXX--
;        $7E    -XXXXXX-    --XXXXXXXXXXXX--
;        $66    -XX--XX-    --XXXX----XXXX--
;        $66    -XX--XX-    --XXXX----XXXX--
;
;
;
;******************************************************************************
;
CHRTBL:

            DB      $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C ; "0"
            DB      $18,$38,$18,$18,$18,$18,$18,$18,$3C,$3C ; "1"
            DB      $3C,$7E,$66,$06,$3E,$7C,$60,$60,$7E,$7E ; "2"
            DB      $3C,$7E,$66,$06,$1C,$1E,$06,$66,$7E,$3C ; "3"
            DB      $66,$66,$66,$66,$7E,$7E,$06,$06,$06,$06 ; "4"
            DB      $7C,$7C,$60,$60,$7C,$7E,$06,$66,$7E,$3C ; "5"
            DB      $3C,$7C,$60,$60,$7C,$7E,$66,$66,$7E,$3C ; "6"
            DB      $7E,$7E,$06,$0E,$0C,$1C,$18,$38,$30,$30 ; "7"
            DB      $3C,$7E,$66,$66,$3C,$7E,$66,$66,$7E,$3C ; "8"
            DB      $3C,$7E,$66,$66,$7E,$3E,$06,$06,$3E,$3C ; "9"
            DB      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; "space"
            DB      $18,$3C,$7E,$66,$66,$66,$7E,$7E,$66,$66 ; "A"
            DB      $7C,$7E,$66,$66,$7C,$7E,$66,$66,$7E,$7C ; "B"
            DB      $3C,$7E,$66,$60,$60,$60,$60,$66,$7E,$3C ; "C"
            DB      $7C,$7E,$66,$66,$66,$66,$66,$66,$7E,$7C ; "D"
            DB      $7E,$7E,$60,$60,$7C,$7C,$60,$60,$7E,$7E ; "E"
            DB      $7E,$7E,$60,$60,$7C,$7C,$60,$60,$60,$60 ; "F"
            DB      $3C,$7E,$60,$60,$60,$6E,$6E,$66,$7E,$3C ; "G"
            DB      $66,$66,$66,$66,$7E,$7E,$66,$66,$66,$66 ; "H"
            DB      $3C,$3C,$18,$18,$18,$18,$18,$18,$3C,$3C ; "I"
            DB      $06,$06,$06,$06,$06,$06,$66,$66,$7E,$3C ; "J"
            DB      $66,$66,$6E,$7C,$78,$78,$6C,$6E,$66,$66 ; "K"
            DB      $60,$60,$60,$60,$60,$60,$60,$60,$7E,$7E ; "L"
            DB      $C3,$E7,$E7,$DB,$DB,$C3,$C3,$C3,$C3,$C3 ; "M"
            DB      $66,$66,$76,$7E,$7E,$6E,$66,$66,$66,$66 ; "N"
            DB      $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C ; "O"
            DB      $7C,$7E,$66,$66,$7E,$7C,$60,$60,$60,$60 ; "P"
            DB      $3C,$7E,$66,$66,$66,$66,$66,$6E,$64,$3A ; "Q"
            DB      $7C,$7E,$66,$66,$7E,$7C,$6E,$66,$66,$66 ; "R"
            DB      $3C,$7E,$66,$60,$7C,$3E,$06,$66,$7E,$3C ; "S"
            DB      $7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18 ; "T"
            DB      $66,$66,$66,$66,$66,$66,$66,$66,$7E,$3C ; "U"
            DB      $66,$66,$66,$66,$66,$7E,$3C,$3C,$18,$18 ; "V"
            DB      $C3,$C3,$C3,$DB,$DB,$DB,$FF,$E7,$C3,$C3 ; "W"
            DB      $66,$66,$7E,$3C,$18,$18,$3C,$7E,$66,$66 ; "X"
            DB      $66,$66,$7E,$3C,$18,$18,$18,$18,$18,$18 ; "Y"
            DB      $7E,$7E,$06,$0E,$1C,$38,$70,$60,$7E,$7E ; "Z"
            DB      $3C,$42,$99,$A5,$A1,$A1,$A5,$99,$42,$3C ; "Copyright Symbol"
            DB      $38,$20,$60,$40,$FF,$FF,$40,$60,$20,$38 ; "Left arrow"
            DB      $18,$18,$3C,$3C,$7E,$5A,$DB,$99,$18,$18 ; "Up arrow"
            DB      $18,$18,$99,$DB,$5A,$7E,$3C,$3C,$18,$18 ; "Down arrow"
            DB      $00,$00,$00,$00,$7E,$7E,$00,$00,$00,$00 ; "Dash"
            DB      $1C,$1C,$1C,$08,$08,$00,$00,$00,$00,$00 ; "Apostrophe"
            DB      $1C,$04,$06,$02,$FF,$FF,$02,$06,$04,$1C ; "Right arrow"

            nop                         ; Not sure why there is a NOP here... left in just in case.
;*****************************************************************************************
; ----> Update_Color_Fade_1
;       Processes fading/cycling timers and triggers new palette loads.
;*****************************************************************************************
Update_Color_Fade_1:
            call    Update_Color_Fade_2
            ld      hl, LD1BF
            ld      a, (hl)
            and     a
            ret     z
            inc     hl
            dec     (hl)
            ret     nz
            ld      (hl), $02               ; Reset sub-timer
            dec     hl
            dec     (hl)                    ; Decrement main fade index
            ld      a, (hl)
            sub     $09
            cpl
            ld      e, a                    ; E = Complemented index offset
            call    Load_Palette_Colors
            ld      a, e
            cp      $08
            ret     c
            ld      a, (L00C8)              ; Load default background color
            out     (COL0L), a
            xor     a
            ld      (LD1BA), a
            ld      (LD050), a
            inc     a
            ld      (LD048), a
            jr      Set_Scanline_Int

;*****************************************************************************************
; ----> Update_Color_Fade_2
;*****************************************************************************************
Update_Color_Fade_2:
            ld      hl, LD1C1
            ld      a, (hl)
            and     a
            ret     z
            inc     hl
            dec     (hl)
            ret     nz
            ld      (hl), $04
            dec     hl
            dec     (hl)
            ld      e, (hl)
            call    Load_Palette_Colors
            dec     e
            ret     p

;*****************************************************************************************
; ----> Set_Scanline_Int & Enable_Sparkle_Colors
;
;       Sets the vertical scanline interrupt trigger position and enables the
;       hardware "sparkle" (shimmer) effect on colors 1, 2, and 3 via the CCMISC latch.
;*****************************************************************************************
Set_Scanline_Int:
            ld      a, $A8              ; A = 168 ($A8). NOTE: Original comment '162' was off!
            out     (INLIN), a          ; Set the scanline interrupt trigger position

Enable_Sparkle_Colors:
            ld      a, 00000111b        ; 0000 011 1 (Function 3, State 1)
            in      a, (CCMISC)         ; Trigger latch to enable Sparkle Color 1

            ld      a, 00001001b        ; 0000 100 1 (Function 4, State 1)
            in      a, (CCMISC)         ; Trigger latch to enable Sparkle Color 2

            ld      a, 00001011b        ; 0000 101 1 (Function 5, State 1)
            in      a, (CCMISC)         ; Trigger latch to enable Sparkle Color 3
            ret                         ; Return to caller

;*****************************************************************************************
; ----> Load_Palette_Colors
;       Calculates the offset into the Fade_Palette_Data table (E * 3) and sends
;       the 3 bytes to the Astrocade's Left Color registers.
;*****************************************************************************************
Load_Palette_Colors:
            ld      d, $00
            ld      hl, Fade_Palette_Data
            add     hl, de
            add     hl, de
Load_Palette_Colors_Loop:
            add     hl, de
            ld      a, (LD1BA)
            and     a
            jr      nz, Write_Color_3
Load_Color_3:
            ld      a, (hl)
Write_Color_3:
            out     (COL3L), a
            inc     hl
            ld      a, (hl)
            out     (COL2L), a
            inc     hl
            ld      a, (hl)
            out     (COL1L), a
            ret

;*****************************************************************************************
; ----> Fade_Palette_Data
;       9 sets of 3-byte color palettes for screen fading effects.
;*****************************************************************************************
Fade_Palette_Data:
            DB      $51, $7C, $F3
            DB      $51, $7B, $F3
            DB      $51, $7B, $F3
            DB      $51, $7A, $F2
            DB      $51, $7A, $F2
            DB      $50, $79, $F1
            DB      $50, $79, $F1
            DB      $50, $78, $F0
            DB      $50, $78, $F0

;*****************************************************************************************
; ----> Trigger_CCMISC_4
;*****************************************************************************************
Trigger_CCMISC_4:
            ld      a, $04
            in      a, (CCMISC)
            jr      Set_Scanline_Int

;*****************************************************************************************
; ----> Process_Scanline_Timer
;*****************************************************************************************
Process_Scanline_Timer:
            ld      hl, LD1BB
            ld      a, (hl)
            and     a
            ret     z
            ld      a, $CC
            out     (INLIN), a
            inc     hl
            ld      a, (hl)
            and     a
            jr      z, Proc_BG_Fade
            dec     (hl)
            ret
;*****************************************************************************************
; ----> Proc_BG_Fade
;       Decrements a timer, triggers hardware latch, and updates the background color.
;*****************************************************************************************
Proc_BG_Fade:
            ld      (hl), $01
            dec     hl
            ld      a, $05
            in      a, (CCMISC)             ; Trigger hardware latch
            dec     (hl)
            call    z, Trigger_CCMISC_4
            ld      a, (hl)
Calc_Color_Idx:
            sub     $10                     ; Modulo 16 loop
            jr      nc, Calc_Color_Idx
            add     a, $10
            ld      c, a
            ld      b, $00
            ld      hl, BG_Color_Data
            add     hl, bc                  ; Calculate offset into the color table
Write_BG_Color:
            ld      a, (hl)
            out     (COL0L), a              ; Output to Background Color Register
            ret

;*****************************************************************************************
; ----> BG_Color_Data
;       16 bytes of background colors.
;*****************************************************************************************
BG_Color_Data:
            DB      $C7, $78, $4B, $18, $BB, $68, $DB, $58
            DB      $2B, $08, $AB, $88, $3B, $98, $CB, $FB

;*****************************************************************************************
; ----> Load_Fade_Col_3
;*****************************************************************************************
Load_Fade_Col_3:
            ld      hl, Fade_Palette_Data
            call    Load_Color_3
            jp      Set_Scanline_Int        ; Jump to scanline interrupt routine

;*****************************************************************************************
; ----> Proc_Scan_Tmr_2
;*****************************************************************************************
Proc_Scan_Tmr_2:
            ld      hl, LD1BD
            ld      a, (hl)
            and     a
            ret     z
            ld      a, $CC
            out     (INLIN), a
            inc     hl
            ld      a, (hl)
            and     a
            jr      z, L076C
            dec     (hl)
            ret
;
;*********************************************************
;
L076C:      ld      (hl),$03
            dec     hl
            dec     (hl)
            jr      z, Load_Fade_Col_3
            bit     0,(hl)
            ld      a,$07
            jr      z,L0779
            xor     a
L0779:      out     (COL3L),a
            out     (COL2L),a
            out     (COL1L),a
            ret
;
;*********************************************************
;
            nop
L0781:      call    Stream_Fetch_Byte_B
            call    L07A8
            xor     a
            jp      L045C
;
;*********************************************************
;
L078B:      ld      a,($D347)
            in      a, (SETTINGS)       ; Check for language...
            bit     3,a                 ; Off=Foreign, On=English (active HIGH)
            ld      hl,Text_Insert_Coin
            jr      nz,L079A
            ld      hl,LC00D
L079A:      ld      a,(hl)
            inc     hl
            cp      $30
            jr      nc,L079A
            djnz    L079A
            ld      b,a
            ld      a,(LD1E2)
            add     a,b
            ret
;
;*********************************************************
;
L07A8:      call    Stream_Fetch_Word_HL
            push    hl
            call    Stream_Fetch_Word_HL
            in      a, (COINPORT)       ; Unknown what bit 7 does...
            bit     7,a
            jr      nz,L07B6
            ex      (sp),hl
L07B6:      pop     hl
            ex      de,hl
            ret
;
;*********************************************************
;
            call    Stream_Fetch_Word_HL
            call    Stream_Fetch_Byte_B
            call    Stream_Fetch_Word_DE
            call    Stream_Fetch_Byte_A
            ld      c,$FF
            jp      printstr
;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;L07CA:
            call    Stream_Fetch_Word_DE
            call    Stream_Fetch_Byte_B
            call    L07A8
L07D3:      call    Stream_Fetch_Byte_A
            jp      L045C
;
            call    Stream_Fetch_Byte_B
            call    L07A8
            call    L078B
            jr      L07D3
;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
            call    Stream_Fetch_Byte_B
            call    L078B
            sub     $29
            cpl
            ld      e,a
            call    L088B
            in      a, (COINPORT)
            bit     7,a                 ;Unknown what bit 7 does on port $10
            call    Stream_Fetch_Byte_A
            jr      nz,L07FF
            ld      d,a
            ld      a,$4F
            sub     e
            ld      e,a
L07FF:      push    hl
L0800:      call    L0947
            ex      de,hl
            pop     hl
            jr      L07D3
;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
            call    L0872
            ld      (hl),a
            ret

;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
L080C:      call    Stream_Fetch_Word_DE
L080F:      call    Stream_Fetch_Word_HL
            ld      (hl),e
            inc     hl
            ld      (hl),d
            ret
;
            call    L0872
            call    Stream_Fetch_Word_DE
            cp      (hl)
            ret     z
            jr      L083E
            call    Stream_Fetch_Word_DE
L0823:      call    Stream_Fetch_Word_HL
            ld      a,(de)
            and     a
            ret     nz
            jr      L086E
            call    Stream_Fetch_Word_DE
            call    Stream_Fetch_Word_HL
            ld      a,(de)
            and     a
            ret     z
            jr      L086E
            call    L0872
            call    Stream_Fetch_Word_DE
            cp      (hl)
            ret     c
L083E:      push    de
            pop     iy
            ret
            in      a, (COINPORT)
            and     (iy+$00)
            inc     iy
            call    Stream_Fetch_Word_HL
            ret     z
            jr      L086E
            xor     a
            ld      (LD050),a
            call    Stream_Fetch_Byte_A
            ld      (LD048),a
            ret
            xor     a
            ld      (LD053),a
            call    L0872
            ld      (LD051),hl
            ld      (LD042),a
            ret
            ld      l,(iy+$00)
            ld      h,(iy+$01)
L086E:      push    hl
            pop     iy
            ret
;
;*********************************************************
; Sub to A=(IY), IY=IY+1
;*********************************************************
;
L0872:      call    Stream_Fetch_Byte_A
;
;*********************************************************
;
;  Load H=(IY+1), L=(IY), IY=IY+2
;  Why are we loading up HL with these values?
;
;*********************************************************
;
Stream_Fetch_Word_HL:
            ld      l,(iy+$00)
            inc     iy
            ld      h,(iy+$00)
            inc     iy
            ret
;
;*********************************************************
;
; Load A=(IY), IY=IY+1
;
;*********************************************************
;
Stream_Fetch_Byte_A:
            ld      a,(iy+$00)
            inc     iy
            ret
;
;*********************************************************
;
; Load E=(IY+1), D=(IY), IY=IY+2
;
;*********************************************************
;
Stream_Fetch_Word_DE:
            ld      e,(iy+$00)
            inc     iy
L088B:      ld      d,(iy+$00)
            inc     iy
            ret
;
;*********************************************************
;
; Load C=(IY), B=(IY+1)
;
;*********************************************************
;
            call    Stream_Fetch_Byte_C
Stream_Fetch_Byte_B:
            ld      b,(iy+$00)
            inc     iy
            ret
;
;*********************************************************
;
; Load C=(IY)
;
;*********************************************************
;
Stream_Fetch_Byte_C:
            ld      c,(iy+$00)
            inc     iy
            ret
;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
L08A0:      pop     hl                  ; Return address in HL
            call    Stream_Fetch_Word_DE               ; Load E=(IY+1), D=(IY), IY=IY+2
            push    iy                  ; Save old subroutine pointer ???
            push    de
            pop     iy                  ; Setup subroutine pointer to new area ???
            jp      (hl)                ; Return...
;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
            pop     hl
            pop     iy
            jp      (hl)

;*****************************************************************************************
; ---->  Sys_Init
;
; Sets up Magic RAM and the Pattern Board (DMA) to rapidly clear the screen,
; zeroes out $0203 bytes of Work RAM, and checks for an expansion ROM.
;*****************************************************************************************
 Sys_Init:
            di                          ; Disable interrupts during the wipe
            xor     a                   ; A = 0
            out     (XPAND),a           ; Set Expand Color to 0 (Black Paintbrush)
            ld      a,$08               ; 00001000b (MRXPND = bit 3)
            out     (MAGIC),a           ; Enable Magic RAM Expand Mode
            ld      a,$22               ; 00100010b (PBFLOP = bit 5, PBEXP = bit 1)
            out     (PBSTAT),a          ; Set DMA to Expand Mode & Horizontal Flop
            xor     a                   ; A = 0
            out     (PBXMOD),a          ; Destination Address LSB = $00
            out     (PBAREADRH),a       ; Destination Address MSB = $00
            inc     a                   ; A = 1
            out     (PBXMOD),a          ; Dest Skip/Modulo = 1 (Advances to next line)
            ld      a,$4F               ; Width = $4F (79 bytes wide)
            out     (PBXWIDE),a         ; Set Pattern Width
            ld      a,$CB               ; Height = $CB (203 scanlines)
            out     (PBYHIGH),a         ; Set Pattern Height and START DMA TRANSFER!

;*****************************************************************************************
; ----> CLEAR WORK RAM ($D040 - $D243)
; Clears 515 bytes of game state memory. Skips the first 64 bytes ($D000 - $D03F)
; which are battery-backed protected RAM.
;*****************************************************************************************
            ld      hl,LD040            ; HL = Start of unprotected Work RAM ($D040)
            ld      (hl),$00            ; Seed the first byte with $00
            ld      de,LD041            ; DE = Dest pointer (one byte ahead)
            ld      bc,$0203            ; BC = Count (515 bytes). NOTE: Artifact 'L0203'
            ldir                        ; Rapidly copy the zero through the RAM block

;*****************************************************************************************
; ----> EXPANSION ROM HOOK
;*****************************************************************************************
            ld      a,(EXPHOOK)         ; Read byte at expansion hook address ($8006)
            cp      $C3                 ; Is it a Z80 'JP' ($C3) instruction?
            call    z,EXPHOOK           ; If yes, execute the expansion ROM
            ret                         ; Return to caller
;
;************************************************************************
;
            call    Stream_Fetch_Byte_C
            call    Stream_Fetch_Byte_A
            ex      af,af'
            call    Stream_Fetch_Word_HL
            exx
            call    L07A8
            ex      de,hl
            exx
L08F0:      ld      a,(hl)
            inc     hl
            exx
            push    hl
            call    char2gfx
            ex      de,hl
            pop     hl
            exx
            ld      b,$0A
L08FC:      exx
            ld      b,$08
            ex      af,af'
            ld      c,a
            ex      af,af'
            ld      a,(de)
            inc     de
L0904:      rla
            jr      nc,L0908
            ld      (hl),c
L0908:      inc     hl
            push    af
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L0912
            dec     hl
            dec     hl
L0912:      pop     af
            djnz    L0904
            in      a, (COINPORT)
            bit     7,a
            ld      c,$E8
            jr      nz,L0920
            ld      bc,LFF18
L0920:      add     hl,bc
            exx
            djnz    L08FC
            exx
            ld      bc,LF6A8
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L0931
            ld      bc,L0958
L0931:      add     hl,bc
            exx
            dec     c
            jr      nz,L08F0
            ret
            nop
XY_To_Video_Address:
            push    hl
            srl     e
            srl     e
            call    L0947
            ld      de,L0007
            add     hl,de
            ex      de,hl
            pop     hl
            ret
L0947:      ld      l,d
            ld      h,$00
            ld      d,h
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl
            push    hl
            add     hl,hl
            add     hl,hl
            add     hl,de
            pop     de
            add     hl,de
            ret
            push    af
L0957:      push    bc
L0958:      push    de
            push    hl
            ex      af,af'
            push    af
            exx
            push    bc
            push    de
            push    hl
L0960:      push    ix
            call    L0E2B
            call    L09D1
            call    L0979
            pop     ix
            pop     hl
            pop     de
            pop     bc
            exx
            pop     af
            ex      af,af'
            pop     hl
            pop     de
            pop     bc
            pop     af
            ei
            ret
L0979:      ld      a,(DIAGFLAG)
            and     a
            ret     nz
            ld      hl,LD038
            ld      a,(hl)
            inc     a
            call    L098B
            ld      hl,LD03E
            ld      a,r
L098B:      and     $0F
            ld      c,a
            rlca
            rlca
            rlca
            rlca
            or      c
            ld      c,a
            cpl
            ld      b,a
            call    Protected_RAM_Write
            inc     hl
            ld      c,b
            jp      Protected_RAM_Write
            push    af
            ld      a,(LD1C4)
            add     a,$2C
            out     (INLIN),a
            call    Select_Interrupt_Vector_CE
            ld      a,$0A
            in      a, (CCMISC)
            ld      a,$52
            out     (COL3L),a
            pop     af
            ei
            ret

;
;************************************************************************
;
            push    af
            ld      a,(LD1C4)
            out     (INLIN),a
            call    Select_Interrupt_Vector_CC
            ld      a,$0B
            in      a, (CCMISC)
            ld      a,$51
            out     (COL3L),a
            jr      L0957
            nop
L09C8:      ld      hl,LD003
            ld      c,$00
            call    Protected_RAM_Write
            rst     00H
L09D1:      ld      a,(DIAGFLAG)
            and     a
            jp      nz,L0A68
            in      a, (COINPORT)       ; Check for TILT
            and     $10                 ; Bit 4, active LOW
            jr      z,L09C8             ; Jump to TILT routine
            ld      a,(LD03A)
            cp      $05
            jr      nc,L09C8
            ld      a,(LD34E)
            rra
            jr      c,L0A25
            ld      hl,LD05C
            call    L0B62
            ld      hl,LD09C
            call    L0B62
            ld      hl,LD0E8
            call    L0B62
            ld      hl,LD134
L0A00:      call    L0B62
            ld      hl,LD067
L0A06:      call    L0AA6
            ld      hl,LD0A7
            call    L0AA6
            ld      hl,LD0F3
            call    L0AA6
L0A15:      ld      hl,LD13F
            call    L0AA6
            call    L0BD7
            call    Proc_Scan_Tmr_2
            ld      a,$05
            jr      L0A5D
L0A25:      ld      hl,LD07C
            call    L0B62
            ld      hl,LD0C2
            call    L0B62
            ld      hl,LD10E
            call    L0B62
            ld      hl,LD15A
            call    L0B62
            ld      hl,LD087
            call    L0AA6
            ld      hl,LD0CD
            call    L0AA6
            ld      hl,LD119
            call    L0AA6
            ld      hl,LD165
            call    L0AA6
            call    L0BE7
            call    Process_Scanline_Timer
            ld      a,$0A
L0A5D:      ld      hl,LD1C3
            or      (hl)
            ld      (hl),a
            call    L0A72
            call    Update_Color_Fade_1
L0A68:      ld      a,(L8000)
            cp      $C3
            call    z,L8000
            ret
            nop
L0A72:      call    L0A82
            ld      hl,LD048
            inc     de
            ld      a,(de)
            and     a
            ret     nz
            ld      b,$08
            call    L0A95
            ret
L0A82:      ld      de,LD040
            ld      a,(de)
            and     a
            ret     nz
            ld      hl,LD34E
            dec     (hl)
            ret     nz
            ld      (hl),$3C
            ld      bc,L0601
            ld      hl,LD042
L0A95:      ld      a,(hl)
            and     a
            jr      z,L0A9D
            dec     (hl)
            jr      nz,L0A9D
            scf
L0A9D:      rl      c
            inc     hl
L0AA0:      djnz    L0A95
            ld      a,c
            ld      (de),a
            ret
            nop
L0AA6:      bit     7,(hl)
L0AA8:      ret     z
            ld      a,$0C
            out     (XPAND),a
            ld      a,$28
            out     (MAGIC),a
            bit     3,(hl)
            jr      z,L0AB9
            res     7,(hl)
            jr      L0AE8
L0AB9:      push    hl
            call    L0AE8
            pop     hl
            bit     5,(hl)
            ret     nz
            push    hl
            inc     hl
            ld      a,(hl)
            inc     hl
            add     a,(hl)
            jr      z,L0AC9
            ld      (hl),a
L0AC9:      ld      e,a
            inc     hl
            ld      a,(hl)
            inc     hl
            add     a,(hl)
            ld      (hl),a
            ld      d,a
            call    XY_To_Video_Address
            inc     hl
            ld      (hl),e
            inc     hl
            ld      (hl),d
            in      a, (INTST)
            pop     hl
            ld      a,(hl)
            push    hl
            call    L0AF5
            pop     hl
            set     6,(hl)
            in      a, (INTST)
            and     a
            ret     z
            set     5,(hl)
L0AE8:      bit     6,(hl)
            ret     z
            res     6,(hl)
            ld      a,(hl)
            ld      de,L0005
            add     hl,de
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
L0AF5:      ex      de,hl
            ld      de,L004F
            bit     1,a
            jr      nz,L0B2E
            bit     2,a
            jr      nz,L0B17
            ld      a,$18
            call    L0B06
L0B06:      ld      (hl),a
            inc     hl
            ld      (hl),a
            add     hl,de
            ld      (hl),a
            inc     hl
            ld      (hl),a
            add     hl,de
            ld      (hl),a
            inc     hl
            ld      (hl),a
            add     hl,de
            ld      (hl),a
            inc     hl
            ld      (hl),a
            add     hl,de
            ret
L0B17:      inc     de
            ld      bc,L2244
            ld      a,(LD1C6)
            and     a
            call    z,L0B25
            call    L0B25
L0B25:      ld      (hl),b
            add     hl,de
            ld      (hl),b
            add     hl,de
            ld      (hl),c
            add     hl,de
            ld      (hl),c
            add     hl,de
            ret
L0B2E:      bit     2,a
            jr      nz,L0B3C
            ld      a,$FF
            ld      (hl),a
            inc     hl
            ld      (hl),a
            add     hl,de
            ld      (hl),a
            inc     hl
            ld      (hl),a
            ret
L0B3C:      ld      a,(LD1C6)
            and     a
            jr      nz,L0B55
            dec     de
            ld      (hl),$99
            inc     hl
            ld      (hl),$99
            inc     hl
            ld      (hl),$9E
            add     hl,de
            ld      (hl),$9E
            inc     hl
            ld      (hl),$67
            inc     hl
            ld      (hl),$67
            ret
L0B55:      ld      (hl),$99
            inc     hl
            ld      (hl),$99
            add     hl,de
            ld      (hl),$E7
            inc     hl
            ld      (hl),$E7
            ret
            nop
L0B62:      bit     7,(hl)
            ret     z
            res     7,(hl)
            push    hl
            bit     6,(hl)
            res     6,(hl)
            call    nz,L0B89
            pop     hl
            bit     5,(hl)
            ret     z
            push    hl
            pop     ix
            ld      a,(ix-$04)
            ld      (ix+$16),a
            ld      a,(ix-$02)
            ld      (ix+$17),a
            push    ix
            pop     hl
            ld      a,(hl)
            xor     $70
            ld      (hl),a
L0B89:      bit     4,(hl)
            ld      de,L0005
            jr      z,L0B91
            add     hl,de
L0B91:      inc     hl
Draw_Actor_Record:
            di
            ld      a,(hl)
            out     (MAGIC),a
            ld      de,L0005
            bit     7,a
            jr      z,L0B9F
            set     4,d
L0B9F:      bit     6,a
            jr      nz,L0BA5
            set     5,d
L0BA5:      ld      a,d
            or      $0C
            out     (PBSTAT),a
L0BAA:      bit     5,a
            jr      z,L0BB0
            ld      e,$FB
L0BB0:      bit     4,a
            ld      a,$50
            jr      z,L0BB8
            ld      a,$B0
;
;*****************************************************************************
; First seen drawing the monsters on the demo screen! ???
;*****************************************************************************
;

L0BB8:      add     a,e
            ld      e,a
            inc     hl
            ld      a,(hl)
            out     (PBLINADRL),a
            inc     hl
            ld      a,(hl)
            out     (PBLINADRH),a
            inc     hl
            ld      a,(hl)
            out     (PBXMOD),a
            inc     hl
            ld      a,(hl)
            out     (PBAREADRH),a
            ld      a,e
            out     (PBXMOD),a
            ld      a,$05
            out     (PBXWIDE),a
            ld      a,$11
            out     (PBYHIGH),a
            ret
            nop
L0BD7:      push    iy
            ld      iy,P1_Actor_Record
            ld      ix,P2_Actor_Record
            call    L0C2B
            pop     iy
            ret
L0BE7:      push    iy
            ld      iy,P2_Actor_Record
            ld      ix,P1_Actor_Record
            call    L0C2B
            pop     iy
            ret
L0BF7:      push    iy
            ld      a,$06
L0BFB:      push    af
            call    Select_Enemy_Record_IY
            call    L0C09
            pop     af
L0C03:      dec     a
            jr      nz,L0BFB
            pop     iy
            ret
L0C09:      ld      a,(iy+$13)
L0C0C:      bit     5,a
            ret     z
            ld      ix,P2_Actor_Record
            call    L0C49
L0C16:      ld      ix,P1_Actor_Record
            call    L0C49
            ld      (iy+$13),$00
            ld      a,(LD1C6)
            and     a
            ret     nz
            ld      (iy+$1c),$0F
            ret
L0C2B:      ld      a,(iy+$13)
            bit     5,a
            ret     z
            call    L0C49
            call    L0E0B
            ld      a,$06
L0C39:      push    af
            call    Select_Enemy_Record_IX
            call    L0C49
            pop     af
            dec     a
            jr      nz,L0C39
            ld      (iy+$13),$00
            ret
L0C49:      ld      a,(ix+$00)
            and     $9A
            cp      $80
            ret     nz
            bit     1,(iy+$13)
L0C55:      jr      z,L0C6F
            ld      hl,L0D2C
            call    L0D18
            bit     2,(iy+$13)
            jr      z,L0C85
            ld      a,(LD1C6)
            and     a
            jr      nz,L0C85
            inc     b
            inc     b
            inc     b
            inc     b
            jr      L0C85
L0C6F:      ld      hl,L0D3C
            call    L0D18
            bit     2,(iy+$13)
            jr      z,L0C85
            ld      a,(LD1C6)
            and     a
            jr      nz,L0C85
            inc     d
            inc     d
L0C83:      inc     d
            inc     d
L0C85:      push    bc
            xor     a
            ld      h,a
            ld      b,a
            ld      l,(ix+$1e)
            ld      c,(iy+$15)
            sbc     hl,bc
            pop     bc
            ld      a,l
            jr      c,L0C98
            cp      $EA
            ret     nc
L0C98:      add     a,c
            cp      b
            ret     nc
            ld      a,(ix+$1f)
            sub     (iy+$17)
            add     a,e
            cp      d
            ret     nc
            call    L0D4C
            bit     2,(iy+$07)
            ret     nz
            ld      a,(LD1C6)
            and     a
            jr      nz,L0CB6
            set     3,(ix+$13)
L0CB6:      bit     2,(iy+$08)
            ld      hl,LD1E1
            ld      a,$04
            jr      nz,L0CC2
            rlca
L0CC2:      or      (hl)
            ld      (hl),a
            bit     3,(iy+$08)
            ld      hl,LD31B
            jr      z,L0CCF
            inc     hl
            inc     hl
L0CCF:      ld      d,$00
            ld      a,$10
            bit     2,(ix+$07)
            jr      z,L0CF3
            ld      e,$05
            ld      a,(ix+$08)
            and     $0C
            jp      pe,L0CFC
            ld      e,$01
            bit     2,a
            jr      nz,L0CEA
            inc     e
L0CEA:      ld      a,(LD351)
            and     a
            ld      a,e
            jr      z,L0CF3
            add     a,a
            daa
L0CF3:      add     a,(hl)
            daa
            ld      (hl),a
            inc     hl
            ld      a,d
            adc     a,(hl)
            daa
            ld      (hl),a
            ret
L0CFC:      ld      a,(LD1EB)
            and     a
            jr      z,L0CEA
L0D02:      ld      (LD352),a
            ld      a,(LD1C6)
            and     a
            ld      e,$10
            jr      z,L0CEA
            ld      (LD1C8),a
            xor     a
            ld      (LD1D8),a
            ld      e,$25
            jr      L0CEA
L0D18:      ld      a,(ix+$07)
            and     $03
            ld      c,a
            ld      b,$00
            add     hl,bc
            add     hl,bc
            add     hl,bc
            add     hl,bc
            ld      c,(hl)
            inc     hl
            ld      b,(hl)
            inc     hl
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            ret
L0D2C:      inc     d
            add     hl,de
            ld      d,$15
            inc     d
            add     hl,de
            inc     d
            dec     d
            ld      d,$1B
            inc     d
            inc     de
            inc     d
            dec     de
            inc     d
L0D3B:      inc     de
L0D3C:      ld      de,$1613
            dec     de
            ld      de,L1413
            dec     de
            inc     de
            dec     d
            inc     d
            add     hl,de
            ld      de,$1415
            add     hl,de
L0D4C:      res     7,(ix+$08)
            set     3,(ix+$00)
            ld      (ix+$1d),$01
            ret
L0D59:      ld      (ix+$1d),$00
            call    L0DD6
            ld      (ix+$03),$01
            ld      (ix+$05),$06
            ld      b,(ix+$07)
            ld      a,b
            rrca
            rrca
            rrca
            and     $80
            ld      (ix+$07),a
            ld      c,$00
            ld      a,b
            and     $03
            cp      $02
            jr      c,L0D87
            ex      af,af'
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L0D86
            set     7,c
L0D86:      ex      af,af'
L0D87:      cp      $01
            jr      nz,L0D8D
            set     7,c
L0D8D:      cp      $02
            jr      z,L0D9D
            cp      $03
            jr      z,L0D9B
            ld      a,(LD1DA)
            and     a
            jr      z,L0D9D
L0D9B:      set     6,c
L0D9D:      ld      (ix+$01),c
            ld      c,(ix+$08)
            bit     2,b
            ld      a,(LD1C6)
            jr      nz,L0DCF
            and     a
            jr      z,L0DB0
            ld      (LD1C8),a
L0DB0:      ld      a,c
            rlca
            rlca
            rlca
            and     $20
            ld      h,a
            ld      a,b
            rlca
            rlca
            rlca
            and     $10
            or      h
            ld      (ix+$07),a
            ld      (ix+$05),$0F
            bit     3,c
            ld      hl,P2_Lives
            jr      nz,L0DCD
            dec     hl
L0DCD:      dec     (hl)
            ret
L0DCF:      and     a
            ret     z
            ld      (ix+$05),$01
            ret
L0DD6:      bit     2,(ix+$07)
            ld      hl,Sound_Request_2
            jr      z,L0DFA
            inc     hl
            ld      a,(LD1EB)
            and     a
            ld      a,$02
            jr      z,L0DF7
            rra
            ld      b,a
            ld      a,(LD1C6)
            and     a
            ld      a,b
            jr      z,L0DF7
            ld      hl,Sound_Request_4
            set     0,(hl)
            ret
L0DF7:      or      (hl)
            ld      (hl),a
            ret
L0DFA:      set     0,(hl)
            ld      a,(LD1C6)
            and     a
            ret     z
            call    Random_Byte
            and     $07
            or      $38
            jp      L8009
L0E0B:      ld      a,(ix+$15)
            sub     (iy+$15)
            add     a,$08
            cp      $11
            ret     nc
            ld      a,(ix+$17)
            sub     (iy+$17)
            add     a,$08
            cp      $11
            ret     nc
            set     3,(ix+$13)
            ld      (ix+$1c),$0F
            ret
            nop
L0E2B:      ld      hl,LD341
            ld      d,$00
            call    L0F00
            ld      hl,LD343
            ld      d,$02
            call    L0F00
            ld      hl,LD345
L0E3E:      ld      d,$0E
            call    L0F00
            ld      a,($D347)
            in      a, (SETTINGS)
            ld      b,a
            exx
            ld      de,L0F1A
            bit     3,a
            jr      nz,L0E54
            ld      de,LC004
L0E54:      exx
            xor     a
            ex      af,af'
            ld      c,$01
            ld      e,$00
            call    L0EBB
            call    L0EC0
            ld      hl,LD342
            call    c,L0EF4
            ld      c,$02
            ld      e,c
            call    L0EBB
            bit     3,b
            jr      z,L0E77
            ld      a,b
            cpl
            and     $06
            rra
            ld      e,a
L0E77:      call    L0EC0
            ld      hl,LD344
            call    c,L0EE3
            ld      a,(DIAGFLAG)
L0E83:      and     a
            jr      nz,L0E8A
            bit     3,b
            jr      nz,L0E99
L0E8A:      ld      c,$04
            ld      e,c
            call    L0EBB
            call    L0EC0
            ld      hl,LD346
            call    c,L0EF4
L0E99:      ex      af,af'
            ld      hl,LD03D
            add     a,(hl)
            push    af
            and     $0F
            ld      c,a
L0EA2:      call    Protected_RAM_Write
            pop     af
            rrca
            rrca
            rrca
            rrca
            and     $0F
            ret     z
            dec     hl
            add     a,(hl)
            cp      $1F
            ret     nc
            ld      c,a
            call    Protected_RAM_Write
            ld      hl,LD340
            inc     (hl)
            ret
L0EBB:      ld      a,b
            and     c
            ret     nz
            inc     e
            ret
L0EC0:      ld      hl,LD03B
            in      a, (COINPORT)
            and     c
            ld      d,(hl)
            ld      a,$A5
            out     (RIGHTPORT),a
            jr      nz,L0ED1
            ld      a,d
            or      c
            ld      (hl),a
            ret
L0ED1:      ld      a,d
            and     c
            ret     z
            ld      a,d
            xor     c
            ld      (hl),a
            ld      a,e
            exx
            ld      l,a
            ld      h,$00
            add     hl,de
            ex      af,af'
            add     a,(hl)
            ex      af,af'
            exx
            scf
            ret
L0EE3:      bit     3,b
            jr      z,L0EF4
            bit     2,b
            jr      z,L0EF4
            ld      a,b
            and     $03
            jp      po,L0EF4
            ld      hl,LD342
L0EF4:      inc     (hl)
            ld      hl,Sound_Request_1
            set     5,(hl)
            ld      a,$01
            ld      (Attract_Sound_Enabled),a           ; Turn on sounds in attract mode variable
            ret
L0F00:      ld      a,(hl)
L0F01:      and     a
            jr      z,L0F0C
            dec     (hl)
            cp      $0F
L0F07:      ret     nz
            ld      a,d
            in      a, (CCMISC)
L0F0B:      ret
L0F0C:      inc     hl
            ld      a,(hl)
            and     a
            ret     z
            dec     (hl)
            dec     hl
            ld      (hl),$1E
            ld      a,d
            set     0,a
            in      a, (CCMISC)
            ret
L0F1A:      djnz    L0F24
            jr      nc,L0F6E
            nop
Select_Enemy_Record_IX:
            ld      ix,LD06E
            ld      bc,L0026
L0F26:      add     ix,bc
            dec     a
            jr      nz,L0F26
            ret
Select_Enemy_Record_IY:
            ld      iy,LD06E
            ld      bc,L0026
L0F33:      add     iy,bc
            dec     a
            jr      nz,L0F33
            ret
Random_Byte:
            exx
            ld      bc,(Random_Seed)
            ld      hl,$1321
            add     hl,bc
            push    hl
L0F43:      ld      hl,L2776
            adc     hl,bc
            ld      de,(LD34C)
            add     hl,de
            ex      (sp),hl
            add     hl,bc
            ex      (sp),hl
L0F50:      adc     hl,de
            ex      (sp),hl
            add     hl,bc
            ex      (sp),hl
            adc     hl,de
L0F57:      ex      (sp),hl
            ld      d,e
            ld      e,b
            ld      b,c
            ld      c,$00
            add     hl,bc
            ld      (Random_Seed),hl
            pop     hl
            adc     hl,de
            ld      (LD34C),hl
            ld      a,h
            exx
            ret
;
;************************************************************
;
; Write protected memory byte
; HL=<location to be written>
; C =<byte to be written>
;
;
;************************************************************
;
Protected_RAM_Write:
            ld      a,$A5
            out     (RIGHTPORT),a       ; Protected memory port
L0F6E:      ld      (hl),c
            ret
;
;************************************************************
;
;
;
;
;************************************************************
;
;

; Command stream data begins at $0F70. The game stream begins at $10FD.
ATTRACT_COMMAND_STREAM:
            DB      $07,$08,$00,$49,$D3,$81,$17,$92
            DB      $17,$84,$16,$A0,$08,$FE,$15,$0C
            DB      $08,$00,$00,$00,$D3,$D5,$18,$07
            DB      $08,$0C,$E1,$D1,$CA,$07,$DA,$32
            DB      $14,$14,$00,$0B,$08,$04,$CA,$07
            DB      $23,$33,$13,$15,$05,$0A,$03,$04
            DB      $E4,$07,$02,$28,$A1,$0C,$97,$16
            DB      $07,$08,$32,$CB,$D1,$20,$08,$4F
            DB      $D3,$B8,$0F,$07,$08,$33,$CB,$D1
            DB      $CA,$07,$CB,$D1,$0A,$89,$11,$6E
            DB      $2D,$0C,$07,$08,$35,$CB,$D1,$20
            DB      $08,$4F,$D3,$D2,$0F,$07,$08,$37
            DB      $CB,$D1,$CA,$07,$CB,$D1,$0A,$B1
            DB      $11,$96,$2D,$0C,$D4,$19,$5A,$08
            DB      $08,$3E,$10,$20,$08,$3C,$D0,$F3
            DB      $0F,$07,$08,$01,$44,$D2,$5A,$08
            DB      $03,$3E,$10,$84,$16,$2B,$08,$3C
            DB      $D0,$34,$10,$2B,$08,$48,$D3,$34
            DB      $10,$E4,$07,$01,$B0,$B9,$0C,$8F
            DB      $19,$A0,$08,$23,$15,$2B,$08,$03
            DB      $D3,$E6,$10,$4F,$08,$1E,$61,$1F
            DB      $81,$07,$0F,$19,$37,$06,$3A,$94
            DB      $19,$A0,$08,$23,$15,$2B,$08,$03
            DB      $D3,$E6,$10,$4F,$08,$1E,$61,$1F
            DB      $68,$08,$F3,$0F,$E4,$07,$0F,$B0
            DB      $B9,$0C,$68,$08,$07,$10,$2B,$08
            DB      $3C,$D0,$52,$10,$A0,$08,$7B,$13
            DB      $2B,$08,$03,$D3,$E6,$10,$68,$08
            DB      $70,$0F,$73,$17,$93,$00,$84,$16
            DB      $BC,$16,$61,$1F,$AE,$08,$0C,$08
            DB      $00,$00,$1B,$D3,$0C,$08,$00,$00
            DB      $1D,$D3,$07,$08,$00,$02,$D3,$52
            DB      $17,$08,$07,$E4,$07,$0A,$20,$A2
            DB      $0C,$E4,$07,$05,$38,$8A,$0C,$5A
            DB      $08,$0F,$68,$13,$03,$17,$CA,$07
            DB      $CB,$D1,$02,$22,$00,$CD,$3C,$08
            DB      $D9,$07,$12,$28,$00,$C7,$3C,$0C
            DB      $E4,$07,$03,$50,$72,$08,$E4,$07
            DB      $05,$78,$4A,$0C,$36,$08,$01,$3C
            DB      $D0,$B5,$10,$E4,$07,$04,$90,$32
            DB      $04,$68,$08,$C7,$10,$E4,$07,$06
            DB      $90,$32,$04,$E4,$07,$07,$A0,$22
            DB      $04,$E4,$07,$17,$B0,$12,$04,$C7
            DB      $16,$2F,$1E,$EC,$16,$20,$20,$08
            DB      $53,$D3,$D7,$10,$EC,$16,$08,$A0
            DB      $08,$23,$15,$4F,$08,$02,$61,$1F
            DB      $20,$08,$03,$D3,$D7,$10,$07,$08
            DB      $01,$44,$D2,$93,$00,$A0,$08,$FE
            DB      $15,$0C,$08,$00,$00,$1B,$D3,$0C
            DB      $08,$00,$00,$1D,$D3
GAME_COMMAND_STREAM:
            DB      $2B,$08,$D9
            DB      $D1,$CD,$12,$75,$16,$84,$16,$A3
            DB      $16,$E0,$08,$09,$AA,$61,$32,$C4
            DB      $52,$FB,$6C,$07,$08,$01,$49,$D3
            DB      $20,$08,$50,$D3,$2B,$11,$81,$07
            DB      $14,$64,$2D,$5B,$30,$E4,$07,$14
            DB      $91,$9A,$08,$EC,$16,$01,$4F,$08
            DB      $78,$61,$1F,$E0,$08,$02,$AA,$C3
            DB      $32,$80,$62,$3F,$5D,$4F,$08,$3C
            DB      $61,$1F,$BC,$16,$61,$1F,$AE,$08
            DB      $20,$08,$51,$D3,$74,$11,$07,$08
            DB      $01,$EC,$D1,$EC,$16,$02,$E0,$08
            DB      $06,$55,$C5,$32,$10,$40,$AF,$7F
            DB      $E0,$08,$05,$AA,$43,$31,$14,$4F
            DB      $AB,$70,$E0,$08,$07,$FF,$F1,$32
            DB      $0C,$5E,$B3,$61,$42,$16,$20,$08
            DB      $CA,$D1,$87,$11,$E4,$07,$09,$90
            DB      $32,$0C,$07,$08,$01,$EC,$D1,$20
            DB      $08,$EC,$D1,$AE,$11,$C7,$16,$2B
            DB      $08,$18,$D3,$A3,$11,$4F,$08,$3C
            DB      $61,$1F,$52,$17,$20,$07,$4F,$08
            DB      $B4,$61,$1F,$4F,$08,$78,$61,$1F
            DB      $BC,$16,$61,$1F,$AE,$08,$79,$1A
            DB      $2F,$18,$A0,$08,$3D,$13,$07,$08
            DB      $80,$41,$D2,$07,$08,$07,$45,$D0
            DB      $36,$08,$00,$50,$D3,$E4,$11,$36
            DB      $08,$01,$50,$D3,$DC,$11,$52,$17
            DB      $48,$07,$E4,$07,$16,$91,$9A,$0C
            DB      $68,$08,$12,$12,$52,$17,$40,$07
            DB      $68,$08,$F8,$11,$52,$17,$10,$0F
            DB      $2B,$08,$18,$D3,$F8,$11,$E4,$07
            DB      $15,$91,$9A,$0C,$68,$08,$12,$12
            DB      $A0,$08,$0F,$16,$1F,$17,$16,$08
            DB      $01,$02,$D3,$12,$12,$81,$07,$14
            DB      $64,$2D,$5B,$30,$E4,$07,$10,$91
            DB      $9A,$0C,$61,$1F,$4F,$08,$1E,$61
            DB      $1F,$68,$08,$FD,$10,$2B,$08,$F1
            DB      $D1,$25,$12,$50,$1F,$2B,$08,$F2
            DB      $D1,$2D,$12,$24,$1F,$C5,$17,$2B
            DB      $08,$F1,$D1,$37,$12,$50,$1F,$2B
            DB      $08,$F2,$D1,$3F,$12,$24,$1F,$81
            DB      $07,$14,$64,$2D,$5B,$30,$CA,$07
            DB      $0B,$33,$06,$72,$2D,$4D,$30,$08
            DB      $61,$1F,$20,$08,$D8,$D1,$9D,$12
            DB      $81,$07,$14,$64,$2D,$5B,$30,$E4
            DB      $07,$11,$91,$9A,$08,$4F,$08,$0A
            DB      $61,$1F,$2B,$08,$C6,$D1,$79,$12
            DB      $4F,$08,$78,$61,$1F,$68,$08,$FD
            DB      $10,$CA,$07,$11,$33,$0D,$6C,$2D
            DB      $53,$30,$0C,$20,$08,$03,$D3,$FD
            DB      $10,$61,$1F,$2B,$08,$D8,$D1,$B0
            DB      $12,$07,$08,$20,$BD,$D1,$5A,$08
            DB      $05,$FD,$10,$61,$1F,$CA,$07,$C5
            DB      $32,$0C,$6D,$2D,$53,$30,$08,$07
            DB      $08,$20,$BB,$D1,$68,$08,$65,$12
            DB      $07,$08,$20,$BB,$D1,$81,$07,$14
            DB      $64,$2D,$5B,$30,$E4,$07,$11,$91
            DB      $9A,$08,$8C,$17,$4F,$08,$B4,$61
            DB      $1F,$68,$08,$FD,$10,$84,$16,$07
            DB      $08,$0C,$E1,$D1,$E0,$08,$09,$FA
            DB      $D1,$32,$A4,$59,$1B,$66,$81,$07
            DB      $14,$64,$2D,$5B,$30,$A0,$08,$0F
            DB      $16,$1F,$17,$52,$17,$30,$07,$4F
            DB      $08,$01,$61,$1F,$2B,$08,$45,$D2
            DB      $EF,$12,$5A,$08,$07,$70,$0F,$EC
            DB      $16,$10,$20,$08,$3C,$D0,$0E,$13
            DB      $E4,$07,$0F,$B0,$B9,$0C,$A0,$08
            DB      $23,$15,$2B,$08,$03,$D3,$E6,$10
            DB      $4F,$08,$1E,$61,$1F,$20,$08,$3C
            DB      $D0,$02,$13,$81,$07,$0F,$19,$37
            DB      $06,$3A,$A0,$08,$23,$15,$2B,$08
            DB      $03,$D3,$E6,$10,$4F,$08,$1E,$61
            DB      $1F,$68,$08,$02,$13,$AA,$17,$CE
            DB      $1C,$D5,$18,$07,$08,$0C,$E1,$D1
            DB      $07,$08,$01,$47,$D0,$C7,$16,$4F
            DB      $08,$03,$61,$1F,$2B,$08,$C1,$D1
            DB      $4F,$13,$B3,$29,$07,$08,$01,$DB
            DB      $D1,$07,$08,$01,$D7,$D1,$AA,$08
            DB      $A0,$08,$7B,$13,$BC,$16,$61,$1F
            DB      $AE,$08,$07,$08,$01,$53,$D3,$68
            DB      $08,$84,$10,$93,$00,$42,$2D,$AE
            DB      $08,$C7,$16,$ED,$1C,$CA,$07,$F8
            DB      $32,$06,$56,$01,$69,$3E,$04,$CA
            DB      $07,$36,$33,$03,$6E,$01,$51,$3E
            DB      $04,$D9,$07,$08,$78,$01,$47,$3E
            DB      $04,$CA,$07,$FE,$32,$06,$16,$0A
            DB      $A9,$35,$08,$CA,$07,$39,$33,$03
            DB      $2E,$0A,$91,$35,$08,$D9,$07,$08
            DB      $38,$0A,$87,$35,$08,$CA,$07,$04
            DB      $33,$07,$D4,$12,$EB,$2C,$0C,$CA
            DB      $07,$3C,$33,$03,$EE,$12,$D1,$2C
            DB      $0C,$D9,$07,$08,$F8,$12,$C7,$2C
            DB      $0C,$CA,$07,$1B,$33,$07,$94,$1B
            DB      $2B,$24,$04,$CA,$07,$3F,$33,$04
            DB      $AC,$1B,$13,$24,$04,$D9,$07,$08
            DB      $B8,$1B,$07,$24,$04,$CA,$07,$1B
            DB      $33,$07,$54,$24,$6B,$1B,$08,$CA
            DB      $07,$3F,$33,$04,$6C,$24,$53,$1B
            DB      $08,$D9,$07,$08,$78,$24,$47,$1B
            DB      $08,$CA,$07,$0B,$33,$06,$16,$2D
            DB      $A9,$12,$0C,$CA,$07,$3F,$33,$04
            DB      $2C,$2D,$93,$12,$0C,$D9,$07,$08
            DB      $38,$2D,$87,$12,$0C,$CA,$07,$C5
            DB      $32,$0C,$2C,$32,$93,$0D,$0C,$CA
            DB      $07,$11,$33,$0D,$C8,$3A,$F7,$04
            DB      $08,$CA,$07,$43,$33,$04,$EC,$3A
            DB      $D3,$04,$08,$D9,$07,$08,$F8,$3A
            DB      $C7,$04,$08,$63,$17,$5A,$08,$0A
            DB      $5E,$14,$68,$08,$08,$15,$93,$00
            DB      $AE,$08,$E4,$07,$0B,$40,$59,$0C
            DB      $E4,$07,$0C,$50,$49,$0C,$B9,$07
            DB      $F0,$32,$01,$27,$1E,$0C,$2F,$18
            DB      $C7,$16,$5A,$08,$07,$83,$14,$68
            DB      $08,$08,$15,$BC,$16,$61,$1F,$AE
            DB      $08,$79,$1A,$B9,$07,$EF,$32,$01
            DB      $27,$32,$0C,$E4,$07,$0D,$B0,$C9
            DB      $0C,$E4,$07,$0E,$C0,$B9,$0C,$AA
            DB      $17,$07,$08,$01,$47,$D0,$C7,$16
            DB      $4F,$08,$03,$61,$1F,$2B,$08,$C1
            DB      $D1,$A8,$14,$0C,$08,$04,$04,$00
            DB      $D3,$20,$08,$4F,$D3,$C5,$14,$0C
            DB      $08,$06,$06,$00,$D3,$CE,$1C,$1E
            DB      $16,$B3,$29,$07,$08,$01,$DB,$D1
            DB      $07,$08,$01,$D7,$D1,$07,$08,$01
            DB      $C9,$D1,$07,$08,$01,$46,$D0,$5A
            DB      $08,$0A,$E8,$14,$68,$08,$08,$15
            DB      $BC,$16,$61,$1F,$AE,$08,$79,$1A
            DB      $1E,$16,$2F,$18,$A0,$08,$3D,$13
            DB      $E4,$07,$10,$91,$9A,$0C,$07,$08
            DB      $01,$46,$D0,$5A,$08,$0A,$21,$15
            DB      $07,$08,$04,$40,$D2,$A0,$08,$23
            DB      $15,$4F,$08,$02,$61,$1F,$20,$08
            DB      $03,$D3,$0D,$15,$07,$08,$01,$53
            DB      $D0,$AA,$08,$42,$08,$40,$81,$15
            DB      $2B,$08,$48,$D3,$35,$15,$36,$08
            DB      $01,$3C,$D0,$DA,$15,$07,$08,$02
            DB      $03,$D3,$0C,$08,$10,$10,$19,$D3
            DB      $0C,$08,$02,$02,$00,$D3,$20,$08
            DB      $4F,$D3,$52,$15,$0C,$08,$03,$03
            DB      $00,$D3,$2B,$08,$48,$D3,$5F,$15
            DB      $36,$08,$03,$3C,$D0,$7B,$15,$0C
            DB      $08,$20,$20,$19,$D3,$0C,$08,$05
            DB      $05,$00,$D3,$20,$08,$4F,$D3,$77
            DB      $15,$0C,$08,$07,$07,$00,$D3,$AC
            DB      $16,$AC,$16,$AC,$16,$AC,$16,$AA
            DB      $08,$42,$08,$20,$DA,$15,$2B,$08
            DB      $48,$D3,$93,$15,$36,$08,$00,$3C
            DB      $D0,$DA,$15,$07,$08,$01,$03,$D3
            DB      $0C,$08,$02,$02,$00,$D3,$20,$08
            DB      $4F,$D3,$AA,$15,$0C,$08,$03,$03
            DB      $00,$D3,$0C,$08,$00,$10,$19,$D3
            DB      $2B,$08,$48,$D3,$BD,$15,$36,$08
            DB      $01,$3C,$D0,$D6,$15,$07,$08,$20
            DB      $1A,$D3,$0C,$08,$05,$05,$00,$D3
            DB      $20,$08,$4F,$D3,$D4,$15,$0C,$08
            DB      $07,$07,$00,$D3,$AC,$16,$AC,$16
            DB      $AA,$08,$2B,$08,$3C,$D0,$FC,$15
            DB      $DE,$16,$20,$08,$DE,$D1,$FC,$15
            DB      $2B,$08,$E4,$D1,$FC,$15,$07,$08
            DB      $01,$44,$D2,$07,$08,$01,$E4,$D1
            DB      $52,$17,$00,$07,$AA,$08,$9E,$17
            DB      $D2,$16,$AE,$08,$79,$17,$07,$08
            DB      $00,$02,$D3,$42,$2D,$AA,$08,$F8
            DB      $16,$E4,$07,$13,$91,$9A,$0C,$07
            DB      $08,$00,$E2,$D1,$AA,$08
;
; End of command-stream data; native Z80 routines resume here.
;
Initialize_Dungeon_Actors:
            xor     a
Clear_Dungeon_Number:
            ld      (Dungeon_Number),a
            ld      a,$06
            ld      de,L0C0C
            call    L162E
            ld      a,$04
            ld      e,$08
L162E:      push    af
            call    Select_Enemy_Record_IX
            call    L26EB
            pop     af
            dec     a
            jr      nz,L162E
            ret
;
Check_Final_Dungeon_Bonus:
            ld      a,(Dungeon_Number)
            cp      $0C
            jr      z,Award_Bonus_Lives
            ret

Check_Bonus_Life_Threshold:
            ld      a,($D347)
            in      a, (SETTINGS)
            ld      b,$03
            bit     5,a                 ; Dipswitch: Bonus Lives active HIGH
                    ; Off = 4th Level,  On  = 3rd Level
            jr      nz,Check_Bonus_Life_Interval
            inc     b
;
Check_Bonus_Life_Interval:
            ld      a,(Dungeon_Number)
            sub     b
            jr      nz,Check_Final_Dungeon_Bonus
            ld      (Maze_Index),a
;
Award_Bonus_Lives:
            ld      hl,P1_Lives
            ld      a,(Game_Mode)
            ld      (LD1CA),a
            dec     a
            jr      z,Award_P2_Bonus_Life
            ld      a,(hl)
            and     a
            jr      z,Award_P2_Bonus_Life
            inc     (hl)
            exx
            call    Draw_P1_Extra_Life_Marker
            exx
;
Award_P2_Bonus_Life:
            inc     hl
            ld      a,(hl)
            and     a
            ret     z
            inc     (hl)
            jp      Draw_P2_Extra_Life_Marker
            ld      hl,LD354
            ld      a,$FF
            ld      b,$0C
L167C:      and     (hl)
            inc     hl
L167E:      djnz    L167C
            jp      nz,Clear_Extended_Game_State
            ret
;
;*****************************************************************************
; Copies the 36-byte persistent game-state mirror from Work RAM back to
; protected RAM.
;*****************************************************************************
Save_Persistent_Game_State:
            di
            ld      hl,WPRAMSTART
            ld      de,P1_Lives
            ld      b,$24               ; 36 decimal
L168D:      ld      a,(de)
            inc     de
            ld      c,a
            call    Protected_RAM_Write               ; Write protected memory byte (HL)=C
            inc     hl
            djnz    L168D
            ret

;
;*****************************************************************************
; Loads the nine-character "@WORRIORS" text fragment into the display buffer.
;*****************************************************************************
Load_Worriors_Text_Buffer:
            ld      hl,Text_Worriors_Suffix
            ld      de,LD1CC
            ld      bc,L0009
            ldir
            ret
;
            ld      hl,LD352
            ld      a,(hl)
            ld      (hl),$00
            dec     hl
            ld      (hl),a
            ret
Adjust_Credit_From_Settings:
            ld      a,($D347)
            in      a, (SETTINGS)       ; Check for Free Play - Active HIGH ???
                    ; Bit 6: Free Play
                    ; Off=No Free Play, On=Free Play
            bit     6,a
            ret     z
            ld      hl,Credits
            ld      c,(hl)
            dec     c
            jp      Protected_RAM_Write ; Write protected credit byte
            ld      a,$CC
            out     (INLIN),a
            ld      hl,L0109
            ld      (LD1BF),hl
            ret
            ld      a,$CC
L16C9:      out     (INLIN),a
            ld      hl,L0109
            ld      (LD1C1),hl
            ret

;
;*****************************************************************************
; Captures the free-play DIP state for the game-state dispatcher.
;*****************************************************************************
Read_Free_Play_DIP:
            ld      a,($D347)
            in      a, (SETTINGS)
            cpl
            and     DIP_FREE_PLAY
            ld      (Free_Play_Enabled),a
            ret
;
;*****************************************************************************
; Combines active-low P1 and P2 controls into one active-high activity byte.
;
;*****************************************************************************
Poll_Combined_Player_Inputs:
            in      a, (P2PORT)         ; Check P2 controls - all active LOW
            cpl                         ; Convert to active HIGH
            ld      b,a                 ;
            in      a, (P1PORT)         ; Now check P1 Controls - all active LOW
            cpl                         ; Make active HIGH
            or      b                   ; Combine with P2 controls
            and     00111111b           ; Mask unused input bits (see port description)
            ld      (Combined_Player_Inputs),a           ; Save it ..
            ret
;
;*****************************************************************************
;
;
;*****************************************************************************
Fetch_Sound_Request_From_Stream:
            ld      a,(iy+$00)
            inc     iy
            ld      (Sound_Request_1),a
            ld      (Attract_Sound_Enabled),a           ; Dip switch - Bit 7 - "Sounds in Attract Mode"
            ret
            in      a, (COINPORT)
            bit     7,a                 ; Check to see if <function> is active
            ret     nz
;
            ld      a,$02
            ld      (LD1E2),a
            ret
;
;*****************************************************************************
;
;
;*****************************************************************************
;
Format_Credits_For_Display:
            ld      a,(Credits)
            ld      e,$FF
L1708:      inc     e
            sub     $0A
            jr      nc,L1708
            add     a,$3A
            ld      hl,LD1CC
L1712:      ld      (hl),a
            ld      a,e
            or      $30
            cp      $30
            jr      nz,L171C
            add     a,$10
L171C:      dec     hl
            ld      (hl),a
            ret
Format_Dungeon_For_Display:
            ld      a,(Dungeon_Number)
            ld      b,a
            xor     a
L1724:      inc     a
            daa
            djnz    L1724
            push    af
            and     $0F
            or      $30
            ld      hl,LD1CC
            ld      (hl),a
            pop     af
            rrca
            rrca
            rrca
            rrca
            and     $0F
            ld      b,$01
            jr      z,L1741
            dec     hl
            inc     b
            or      $30
            ld      (hl),a
L1741:      dec     de
            dec     de
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L174D
            inc     de
            inc     de
            inc     de
            inc     de
L174D:      ld      a,$0C
            jp      L045C
            ld      b,(iy+$00)
            inc     iy
            call    Random_Byte
            and     (iy+$00)
            inc     iy
            or      b
            jp      L8009
            in      a, (COINPORT)
            bit     7,a
            ld      a,$88
            jr      nz,L176D
            ld      a,$18
L176D:      ld      (LD1C4),a
            jp      Select_Interrupt_Vector_CC
Restart_Dispatcher:
            ld      sp,BOOT_STACK_TOP
            jp      dispatch

;
;*****************************************************************************
; Clears the protected initialization counter through the write latch.
;*****************************************************************************
Clear_Protected_Init_Counter:
            ld      hl,LD03A
            ld      c,$00
            jp      Protected_RAM_Write               ;Write protected memory byte
;
;*****************************************************************************
; Captures the attract-mode sound DIP state.
;*****************************************************************************
Read_Attract_Sound_DIP:
            ld      a,($D347)           ; Why load this? The next command wipes it out ???
            in      a, (SETTINGS)
            and     DIP_ATTRACT_SOUND
            ld      (Attract_Sound_Enabled),a           ; Save demo sound status, A=$80 if active, $00 if not
            ret
;
;*****************************************************************************
; ROUTINE: High-Priority Sound Trigger (Override)
; Found at $18D5 (Immediately following the Maze Wall bitmasks).
; Purpose: Writes directly to sound request byte Sound_Request_4, requesting sound bit 3.
;          ($08 = 00001000b). By using LD instead of SET, it intentionally
;          clears/aborts any other pending sounds in this queue to force
;          this specific high-priority sound (e.g., Coin Drop, Player Death)
;          to play immediately.
;*****************************************************************************
Trigger_High_Priority_Sound:
High_Priority_Sound_Request_Byte EQU Trigger_High_Priority_Sound + 1
            ld      a,$08               ; $08 = Bit 3 (High-priority sound ID)
            ld      (Sound_Request_4),a           ; Overwrite Sound Queue 4, clearing other bits
            ret

;
;*****************************************************************************
; ROUTINE: Check Starting Lives (Dip Switch)
; Called from dispatch routine. Evaluates Bit 4 of the settings port.
;*****************************************************************************
Read_Starting_Lives_DIP:
            ld      a,($D347)           ; MACRO ARTIFACT: Useless read of orphaned RAM cache
            in      a,(SETTINGS)        ; PATCH: Read hardware directly, overwriting A
            cpl                         ; Invert bits (Active-LOW hardware to Active-HIGH logic)
            and     DIP_STARTING_LIVES
            ld      (Starting_Lives_Dip),a           ; Save status: $10 = 3/7 lives, $00 = 2/5 lives
            ret
;
;*****************************************************************************
; ROUTINE: Zero Memory Block ($D350 to $D36D)
; Called from dispatch routine. Clears 30 ($1E) bytes of static RAM.
;*****************************************************************************
Clear_Extended_Game_State:
            ld      hl,LD350            ; Start address to clear
            ld      bc,$1E00            ; OPTIMIZATION: B = $1E (Loop count 30), C = $00 (Zero value)
L17A4:      ld      (hl),c              ; Write $00 to memory
            inc     hl                  ; Advance pointer
            djnz    L17A4               ; Decrement B and loop until 30 bytes are cleared
            ret
;

            nop
            call    L17C5
            ld      a,$0C
            out     (XPAND),a
            ld      a,$18
            out     (MAGIC),a
            ld      hl,L0F07
            ld      a,$0B
            call    L185F
            ld      hl,L0F43
            ld      a,$07
            jp      L185F
L17C5:      call    L181D
            ld      hl,L0781
            call    L1855
            ld      hl,L07C9
            call    L1855
            ld      hl,L0F01
            call    L1859
            ld      hl,L0F49
            call    L1859
            ld      hl,L1681
            call    L185D
            ld      hl,L16C9
            call    L185D
            ld      c,$17
            ld      hl,L0007
            exx
            ld      hl,LD178
            ld      c,$06
L17F7:      ld      b,$0B
L17F9:      ld      a,(hl)
            inc     hl
            exx
            call    L1813
            exx
            djnz    L17F9
            exx
            ld      de,Write_BG_Color
            add     hl,de
            exx
            dec     c
            jr      nz,L17F7
            exx
            call    L1812
            ld      hl,L2D43
L1812:      xor     a
L1813:      push    hl
            call    L185F
            pop     hl
            ld      de,L0006
            add     hl,de
            ret
;
L181D:      di
            ld      a,(LD1EB)
            and     a
            ld      a,$0C
            jr      nz,L1828
            ld      a,$04
L1828:      out     (XPAND),a
            ld      a,$18
            out     (MAGIC),a
            ret
            call    L181D
            ld      hl,L30DD
            ld      de,L18D0
            ld      c,$2F
            call    L18A8
            ld      hl,L30F4
            call    L18A8
            ld      hl,L30DD
            call    L184C
            ld      hl,$3F8D
L184C:      ld      a,$FF
            ld      b,$17
L1850:      ld      (hl),a
            inc     hl
            djnz    L1850
            ret
L1855:      ld      a,$0D
            jr      L185F
L1859:      ld      a,$0C
            jr      L185F
L185D:      ld      a,$0E
L185F:      bit     2,a
            jr      nz,L186B
            ex      af,af'
            ld      de,L18D2
            call    L18A8
            ex      af,af'
L186B:      bit     3,a
            jr      nz,L187D
            ex      af,af'
            push    hl
            ld      de,L0005
            add     hl,de
            ld      de,L18D3
            call    L18A8
            pop     hl
            ex      af,af'
L187D:      bit     0,a
            call    z,L1889
            bit     1,a
            ret     nz
            ld      de,Load_Palette_Colors_Loop
            add     hl,de
L1889:      push    hl
            call    L1896
            ld      de,L004B
            add     hl,de
            call    L1896
            pop     hl
            ret
L1896:      ld      (hl),$FF
            inc     hl
            ld      (hl),$FF
            inc     hl
            ld      (hl),$FF
            inc     hl
            ld      (hl),$FF
            inc     hl
            ld      (hl),$FF
            inc     hl
            ld      (hl),$FF
            ret
;
;*****************************************************************************
; ROUTINE: Draw Vertical Line via Pattern Board (DMA)
; Purpose: Uses the Astrocade Pattern Board to rapidly blit a 1-byte wide
;          (4 pixel) vertical line or box edge to the screen. First used
;          in drawing the radar box in the demo screens.
; Inputs:
;    DE = Source Address (Pattern data to expand)
;    HL = Destination Address (Screen/Magic RAM)
;    C  = Height of the line (in scanlines)
;*****************************************************************************
;

L18A8:      ld      a,$22               ; %00100010 = Set PBEXP (Expand Mode) and PBFLOP (Horizontal Flop)
            out     (PBSTAT),a          ; Output to Pattern Board Status port
            ld      a,e
            out     (PBLINADRL),a       ; Set Source Address LSB
            ld      a,d
            out     (PBLINADRH),a       ; Set Source Address MSB
            ld      a,l
            out     (PBXMOD),a          ; Set Destination Address LSB
            ld      a,h
            out     (PBAREADRH),a       ; Set Destination Address MSB
            ld      a,$4F               ; Screen Width ($50) minus Pattern Width ($01) = $4F Skip Value
            out     (PBXMOD),a          ; Set Dest Skip/Modulo (Advances Y coordinate cleanly to the next row)
            ld      a,$01               ; Width = 1 byte (4 pixels wide)
            out     (PBXWIDE),a         ; Set Pattern Width
            ld      a,c
            out     (PBYHIGH),a         ; Set Pattern Height (Writing this port triggers the DMA transfer!)
            ret

;
;*****************************************************************************
; SCREEN Y-COORDINATE LOOKUP TABLE (16 Scanline Spacing)
; Found at $18C4. Accessed by L2776.
; Note: Each word jumps exactly $0280 (640 bytes), which equals 16 scanlines
; on the Astrocade 40-byte wide screen.
;*****************************************************************************
L18C4:      DW      $717C
            DW      $73FC
            DW      $767C
            DW      $78FC
            DW      $7B7C
            DW      $7DFC

;*****************************************************************************
; VERTICAL WALL PIXEL MASKS (Astrocade 2BPP)
; Found at $18D0. Passed to the Pattern Board DMA (L18A8) via DE register
; to draw vertical lines at specific pixel offsets.
;*****************************************************************************
L18D0:      DB      $80                 ; Binary 10000000 (Color 2, Pixel 0)
            DB      $10                 ; Binary 00010000 (Color 1, Pixel 2)
L18D2:      DB      $C0                 ; Binary 11000000 (Color 3, Pixel 0)
L18D3:      DB      $30                 ; Binary 00110000 (Color 3, Pixel 1)
            DB      $00                 ; Blank

;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
            di
            ld      a,$08
            out     (MAGIC),a
            ld      de,Vertical_Line_Source_Pattern
            ld      a,$04
            out     (XPAND),a
            ld      bc,L1107
            ld      hl,L3522
            call    L191B
            ld      hl,$3D42
            call    L191B
            ld      bc,L0111
            ld      hl,Radar_Line_Pattern_A
            call    L191B
            ld      hl,Radar_Line_Pattern_B
            call    L191B
            ld      a,$08
            out     (XPAND),a
L1903:      ld      hl,Radar_Line_Pattern_C
            call    L191B
            ld      hl,Radar_Line_Pattern_D
            call    L191B
            ld      bc,L1107
            ld      hl,L355C
            call    L191B
            ld      hl,$3D7C
L191B:      ld      a,$22
            out     (PBSTAT),a
            ld      a,e
            out     (PBLINADRL),a
            ld      a,d
            out     (PBLINADRH),a
            ld      a,l
            out     (PBXMOD),a
            ld      a,h
            out     (PBAREADRH),a
            ld      a,$50
            sub     b
            out     (PBXMOD),a
            ld      a,b
            out     (PBXWIDE),a
            ld      a,c
            out     (PBYHIGH),a
            ret
;******************************************************************************************
Vertical_Line_Source_Pattern:
            DB      $FF,$00        ; Solid source byte followed by blank padding
L1939:      ld      hl,(LD31B)
            push    hl
            ld      de,LD319
            push    de
            ld      de,(LD31D)
            xor     a
            sbc     hl,de
            ld      hl,LD31A
            ex      de,hl
            jr      c,L1953
            pop     bc
            ex      (sp),hl
            push    de
            ld      d,b
            ld      e,c
L1953:      ld      b,h
            ld      c,l
            call    L195A
            pop     de
            pop     bc
L195A:      ld      a,(de)
            and     a
            ret     z
            sub     $10
            ld      hl,LD304
            jr      z,L1967
            ld      hl,LD30E
L1967:      push    de
            exx
            ld      bc,$0500
L196C:      exx
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            ex      de,hl
            xor     a
            sbc     hl,bc
            ex      de,hl
            jr      nc,L1986
            ld      a,(hl)
            ld      (hl),b
            ld      b,a
            dec     hl
            ld      a,(hl)
            ld      (hl),c
            ld      c,a
            inc     hl
            exx
            ld      a,c
            and     a
            jr      nz,L1985
            ld      c,b
L1985:      exx
L1986:      inc     hl
            exx
            djnz    L196C
            pop     hl
            ld      a,c
            or      (hl)
            ld      (hl),a
            ret
            ld      de,Text_Copyright_Glyphs
            jr      L1997
            ld      de,Text_Coin_Prompt_Suffix
L1997:      ld      a,(LD319)
            ld      b,$04
            push    de
            call    L19A6
            pop     de
            ld      a,(LD31A)
            ld      b,$08
L19A6:      and     a
            ret     z
            bit     4,a
            ld      hl,L2F9C
            jr      nz,L19B1
            ld      l,$C4
L19B1:      and     $07
            ret     z
            push    bc
            ld      bc,LFB00
            ex      af,af'
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L19C8
            ld      h,$0A
            ld      a,l
            sub     $92
            ld      l,a
            ld      bc,$0500
L19C8:      ex      af,af'
L19C9:      add     hl,bc
            dec     a
            jr      nz,L19C9
            ex      de,hl
            pop     af
            ld      b,$01
            jp      L045C
            ld      hl,L168D
            ld      de,LD304
            call    L19E3
            ld      hl,L16B5
            ld      de,LD30E
L19E3:      in      a, (COINPORT)
            bit     7,a
            jr      nz,L19EB
            ld      h,$20
L19EB:      ld      b,$05
L19ED:      push    bc
            push    de
            push    hl
            ld      a,$0C
            call    L1A2D
            pop     hl
            pop     de
            inc     de
            inc     de
            in      a, (COINPORT)
            bit     7,a
            ld      bc,$0500
            jr      nz,L1A05
            ld      bc,LFB00
L1A05:      add     hl,bc
            pop     bc
            djnz    L19ED
            ret
            nop
L1A0B:      ld      hl,LD1E1
            bit     2,(hl)
            res     2,(hl)
            ld      hl,L38E5
            ld      de,LD31B
            ld      a,$04
            call    L1A2C
            ld      hl,LD1E1
            bit     3,(hl)
            res     3,(hl)
            ld      hl,L391F
            ld      de,LD31D
            ld      a,$08
L1A2C:      ret     z
L1A2D:      ex      af,af'
            in      a, (COINPORT)
            bit     7,a
            jr      nz,L1A38
            ld      bc,L02DB
            add     hl,bc
L1A38:      push    hl
            ld      hl,LD1D0
            ld      (hl),$30
            dec     hl
            ld      (hl),$30
            dec     hl
            ld      a,(de)
            call    L1A6D
            ld      a,(de)
            call    L1A69
            inc     de
            ld      a,(de)
            call    L1A6D
            ld      a,(de)
            call    L1A69
            inc     hl
            push    hl
            ld      b,$05
L1A57:      ld      a,(hl)
            cp      $30
            jr      nz,L1A61
            ld      (hl),$40
            inc     hl
            djnz    L1A57
L1A61:      pop     hl
            ex      af,af'
            ld      b,$06
            pop     de
            jp      L045C
L1A69:      rrca
            rrca
            rrca
            rrca
L1A6D:      and     $0F
            add     a,$90
            daa
            adc     a,$40
            daa
            ld      (hl),a
            dec     hl
            ret
            nop
            ld      hl,Dungeon_Number
            inc     (hl)
            ld      a,(Maze_Index)
            ld      c,a
            ld      b,$00
            ld      hl,Maze_Pointer_Table
            add     hl,bc
            add     hl,bc
            ld      c,(hl)
            inc     hl
            ld      b,(hl)
            ld      hl,LD172
            ld      a,$06
L1A90:      ex      af,af'
            ld      de,L0006
            add     hl,de
            push    hl
            add     hl,de
            add     hl,de
            ex      de,hl
            dec     de
            pop     hl
            call    L1AB4
            call    L1ABB
            call    L1AB4
            call    L1ABB
            call    L1AB4
            ld      a,(bc)
            inc     bc
            and     $0F
            ld      (hl),a
            ex      af,af'
            dec     a
            jr      nz,L1A90
            ret
L1AB4:      ld      a,(bc)
            rrca
            rrca
            rrca
            rrca
            jr      L1ABD
L1ABB:      ld      a,(bc)
            inc     bc
L1ABD:      and     $0F
            ld      (hl),a
            and     $0C
            ld      a,(hl)
            inc     hl
            jp      pe,L1AC9
            xor     $0C
L1AC9:      dec     de
            ld      (de),a
            ret
Maze_Cell_Address_From_XY:
            ld      a,e
            ld      e,$FF
L1ACF:      inc     e
            sub     $18
            jr      nc,L1ACF
            ld      a,d
            ld      d,$00
L1AD7:      inc     d
            sub     $18
            jr      nc,L1AD7
            ld      l,$0B
            ld      a,$F5
L1AE0:      add     a,l
            dec     d
            jr      nz,L1AE0
            add     a,e
            ld      e,a
            ld      d,$00
            ld      hl,LD178
            add     hl,de
            ret
;*****************************************************************************
; PACKED MAZE LIBRARY
;
; Maze_Index selects one of 24 pointers. Each maze record contains 18 packed
; bytes: six rows of six four-bit cell values.
;*****************************************************************************
Maze_Pointer_Table:
            DW      Maze_01_Data, Maze_15_Data, Maze_02_Data, Maze_03_Data, Maze_04_Data, Maze_05_Data
            DW      Maze_06_Data, Maze_07_Data, Maze_08_Data, Maze_09_Data, Maze_10_Data, Maze_11_Data
            DW      Maze_12_Data, Maze_13_Data, Maze_14_Data, Maze_16_Data, Maze_17_Data, Maze_18_Data
            DW      Maze_19_Data, Maze_20_Data, Maze_21_Data, Maze_22_Data, Maze_23_Data, Maze_24_Data
Maze_01_Data:
            DB      $AC,$EC,$CE,$BC,$5A,$EF,$BC,$EF,$FF
            DB      $B6,$9F
Maze_01_Data_Byte_11:
            DB      $DD,$3B,$EF,$EC,$95,$95,$9C
Maze_02_Data:
            DB      $AC,$EE,$CE,$3A,$D7,$AD,$97,$AF,$FC
            DB      $AD,$73,$9E,$BC,$7B,$ED,$9C,$D5,$9C
Maze_03_Data:
            DB      $AC,$6A,$CE,$BC,$D7,$AD,$9E,$EF,$FE
            DB      $A5,$33,$33,$BC,$F7,$9F,$9C,$59,$CD
Maze_04_Data:
            DB      $AC,$6A,$CE,$3A,$DF,$CF,$97,$AF,$63
            DB      $AD,$73,$33,$BC,$F5,$BF,$9C,$DC,$51
Maze_05_Data:
            DB      $AC,$C6,$AE,$3A,$CD,$73,$97,$AE,$DF
            DB      $A7,$3B,$CD,$3B,$FF,$CE,$9D,$59,$CD
Maze_06_Data:
            DB      $AC,$6A,$CE,$BC,$DF,$63,$9E,$C7,$BF
            DB      $AD,$6B,$53,$BC,$7B,$ED,$9C,$D5,$9C
Maze_07_Data:
            DB      $A6,$AC,$EC,$3B,$5A,$FC,$9F,$E7,$BC
            DB      $A7,$33,$BE,$33,$BF,$53,$9D,$59,$CD
Maze_08_Data:
            DB      $AE,$EE,$EE,$33,$33,$33,$9F,$79,$73
            DB      $A7,$9E,$FF,$3B,$6B,$53,$95,$9D,$CD
Maze_09_Data:
            DB      $AC,$CE,$EC,$BC,$E5,$BC,$9E,$7A,$DE
            DB      $A5,$B7,$AF,$3A,$5B,$73,$9D,$C5,$9D
Maze_10_Data:
            DB      $AC,$6A,$CE,$BC,$FF,$EF,$9E,$53,$33
            DB      $A5,$A5,$BF,$BC,$5A,$73,$9C,$C5,$9D
Maze_11_Data:
            DB      $AC,$6A,$EC,$BC,$73,$9E,$96,$BF,$ED
            DB      $AD,$53,$BC,$BC,$EF,$FC,$9C,$D5,$9C
Maze_12_Data:
            DB      $A6,$AC,$EC,$3B,$FC,$FC,$97,$B6,$9E
            DB      $A7,$97,$AD,$3B,$EF,$DE,$9D,$59,$CD
Maze_13_Data:
            DB      $AC,$6A,$CE,$3A,$FD,$CF,$B7,$BC,$63
            DB      $B5,$3A,$DF,$3A,$DF,$63,$9D,$C5,$9D
Maze_14_Data:
            DB      $A6,$AC,$EC,$3B,$7A,$DE,$95,$39,$63
            DB      $AE,$DC,$73,$3B
Maze_14_Data_Byte_13:
            DB      $EE,$FD,$95,$95,$9C
Maze_15_Data:
            DB      $AE,$EE,$EE,$BF,$FF,$FF,$BF,$FF,$FF
            DB      $BF,$FF,$FF,$BF,$FF,$FF,$9D,$DD,$DD
Maze_16_Data:
            DB      $AC,$EE,$EE,$B6,$BD,$53,$B5
Maze_16_Data_Byte_07:
            DB      $3A,$EF
            DB      $BE,$D5,$BF,$B7,$AE,$FF,$9D,$DD,$DD
Maze_17_Data:
            DB      $AE
Maze_17_Data_Byte_01:
            DB      $EE,$CE,$BF,$F5,$AF,$BF,$5A,$FF
            DB      $B5,$AF,$53,$BE,$F5,$AF,$9D,$DC,$DD
Maze_18_Data:
            DB      $AE,$EE,$EE,$3B,$73,$BF,$33,$B7,$33
            DB      $B7,$3B,$73,$BF,$73,$BF,$9D,$DD,$DD
Maze_19_Data:
            DB      $AE,$EE,$EE,$39,$F5,$BF,$B6,$BE,$73
            DB      $BD,$79,$73,$3A,$F6,$BF,$9D,$DD,$DD
Maze_20_Data:
            DB      $AE,$EE,$CE,$39,$F5,$AF,$B6,$9E,$FF
            DB      $BF,$6B,$DF,$BF,$F5,$AF,$9D,$DC,$DD
Maze_21_Data:
            DB      $AE,$EE,$CE,$B5,$9F,$63,$B6,$A5,$9F
            DB      $39,$F6,$AF,$B6,$9D,$FF,$9D,$CC,$DD
Maze_22_Data:
            DB      $AC,$EE,$EE,$B6,$9F,$53,$BF,$63,$AF
            DB      $BF,$53,$9F,$B5,$AF,$63,$9C,$DD,$DD
Maze_23_Data:
            DB      $AC,$EE,$CE,$B6,$9F,$ED,$BF,$69,$FE
            DB      $BF,$F6,$9F,$B7,$BF,$63,$9D,$DD,$DD
Maze_24_Data:
            DB      $AC,$EE,$EC,$BE,$D7,$BC,$3B,$ED,$FE
            DB      $3B,$DE,$FD,$BD,$E7,$BC,$9C,$DD,$DC
Draw_Player_Lives:
            nop
            call    Select_P1_Life_Icon
            ld      a,(P1_Lives)
            call    Draw_Life_Icons
            call    Select_P2_Life_Icon
            ld      a,(P2_Lives)
Draw_Life_Icons:
            and     a
            ret     z
            cp      $08
            jr      c,Clamp_Life_Count
            ld      a,$07
Clamp_Life_Count:
            ld      b,a
Draw_Life_Icon_Loop:
            call    Draw_Actor_Record
            inc     hl
            djnz    Draw_Life_Icon_Loop
            ret
Draw_Reserve_Life_Icons:
            ld      hl,Reserve_Life_Icon_Primary
            ld      de,Reserve_Life_Icon_Alternate
            call    Select_Cabinet_Graphics_Variant
            ld      b,$07
            jr      Draw_Life_Icon_Loop
Draw_P1_Extra_Life_Marker:
            ld      hl,P1_Life_Marker_Primary
            ld      de,P1_Life_Marker_Alternate
            call    Select_Cabinet_Graphics_Variant
            jp      Draw_Actor_Record
Draw_P2_Extra_Life_Marker:
            ld      hl,P2_Life_Marker_Primary
            ld      de,P2_Life_Marker_Alternate
            call    Select_Cabinet_Graphics_Variant
            jp      Draw_Actor_Record
Select_P1_Life_Icon:
            ld      hl,P1_Life_Icon_Primary
            ld      de,P1_Life_Icon_Alternate
            jr      Select_Cabinet_Graphics_Variant
Select_P2_Life_Icon:
            ld      hl,P2_Life_Icon_Primary
            ld      de,P2_Life_Icon_Alternate
Select_Cabinet_Graphics_Variant:
            in      a, (COINPORT)
            bit     7,a
            ret     nz
            ex      de,hl
L1D26:      ret
;*****************************************************************************
; LIFE-DISPLAY GRAPHICS
;
; Fixed actor-display records selected by player and cabinet orientation.
;*****************************************************************************
P1_Life_Icon_Primary:
            DB      $62,$9C,$38,$FC,$2D,$62,$9C,$38,$F6,$2D
            DB      $62,$9C,$38,$76,$26,$62,$9C,$38,$F6,$1E
            DB      $62,$9C,$38,$76,$17,$62,$9C,$38,$76,$08
            DB      $62,$9C,$38,$F6,$00
P1_Life_Icon_Alternate:
            DB      $E2,$9C,$38,$4C,$33,$E2,$9C,$38,$46,$33
            DB      $E2,$9C,$38,$C6,$2B,$E2,$9C,$38,$46,$24
            DB      $E2,$9C,$38,$C6,$1C,$E2,$9C,$38,$C6,$0D
            DB      $E2,$9C,$38,$46,$06
P2_Life_Icon_Primary:
            DB      $22,$F6,$38,$33,$2E,$22,$F6,$38,$39,$2E
            DB      $22,$F6,$38,$B9,$26,$22,$F6,$38,$39,$1F
P2_Life_Icon_Primary_Byte_20:
            DB      $22,$F6,$38,$B9,$17,$22,$F6,$38,$B9,$08
            DB      $22,$F6,$38,$39,$01
P2_Life_Icon_Alternate:
            DB      $A2,$F6,$38,$83,$33,$A2,$F6,$38,$89,$33
            DB      $A2,$F6,$38,$09,$2C,$A2,$F6,$38,$89,$24
            DB      $A2,$F6,$38,$09,$1D,$A2,$F6,$38,$09,$0E
            DB      $A2,$F6,$38,$89,$06
Reserve_Life_Icon_Primary:
            DB      $22,$AE,$9E,$24,$00,$22,$00,$96,$E4,$08
            DB      $22,$2F,$3D,$A4,$11,$22,$9C,$38,$64,$1A
            DB      $22,$F6,$38,$24,$23,$22,$9A,$A3,$E4,$2B
            DB      $22,$10,$A6,$A4,$39
Reserve_Life_Icon_Alternate:
            DB      $E2,$AE,$9E,$9B,$3F,$E2,$00,$96,$DB,$36
            DB      $E2,$2F,$3D,$1B,$2E,$E2,$9C,$38,$5B,$25
            DB      $E2,$F6,$38,$9B,$1C,$E2,$9A,$A3,$DB,$13
            DB      $E2,$10,$A6,$1B,$06
P1_Life_Marker_Primary:
            DB      $60,$9C,$38,$D7,$2B
P1_Life_Marker_Alternate:
            DB      $E0,$9C,$38,$F7,$10
P2_Life_Marker_Primary:
            DB      $22,$F6,$38,$F8,$2B
P2_Life_Marker_Alternate:
            DB      $A2,$F6,$38,$18,$11
Initialize_Player_Life_Displays:
            ld      a,(Credits)
            dec     a
            jr      z,L1E2F
            ld      hl,Life_Display_Record_1B
            ld      de,Life_Display_Record_3A
            call    Select_Cabinet_Graphics_Variant
            ld      b,$04
L1E1E:      call    Draw_Initial_Life_Display
            ld      hl,Life_Display_Record_2A
            ld      de,Life_Display_Record_3B
            call    Select_Cabinet_Graphics_Variant
L1E2A:      ld      b,$04
            call    Draw_Initial_Life_Display
L1E2F:      ld      a,$78
            ld      (LD04C),a
            ld      hl,Life_Display_Record_1A
            ld      de,Life_Display_Record_2B
            call    Select_Cabinet_Graphics_Variant
            ld      b,$02
Draw_Initial_Life_Display:
            ld      a,(Credits)
            cp      b
            ld      b,$02
            jr      c,L1E49
            ld      b,$05
L1E49:      ld      a,(Starting_Lives_Dip)
            and     a
            ld      a,b
            jr      z,L1E52
            or      $03
L1E52:      ld      c,a
            ld      b,$05
            ld      de,LD1CB
L1E58:      ld      a,(hl)
            inc     hl
            ld      (de),a
            inc     de
            djnz    L1E58
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            ld      b,c
L1E62:      push    de
            ld      hl,LD1CB
            call    Draw_Actor_Record
            pop     de
            ld      hl,(LD1CE)
            add     hl,de
            ld      (LD1CE),hl
            djnz    L1E62
            ret
; Life-display templates: five display bytes followed by a 16-bit stride.
Life_Display_Record_1A:
            DB      $22,$F6,$38,$4A,$1E,$FB,$FF
Life_Display_Record_1B:
            DB      $62,$9C,$38,$06,$32,$05,$00
Life_Display_Record_2A:
            DB      $22,$F6,$38,$4A,$32,$FB,$FF
Life_Display_Record_2B:
            DB      $A2,$F6,$38,$EA,$1E,$FB,$FF
Life_Display_Record_3A:
            DB      $E2,$9C,$38,$A6,$0A,$05,$00
Life_Display_Record_3B:
            DB      $A2,$F6,$38,$EA,$0A,$FB,$FF,$00
L1E9F:      ld      a,(LD1D7)
            and     a
            ret     z
            ld      hl,P1_Actor_Record
            bit     7,(hl)
            jr      nz,L1ED6
            ld      a,(P1_Lives)
            and     a
            jr      z,L1ED6
            ld      b,$00
            ld      de,$0344
            call    L1F55
            dec     c
            jr      nz,L1EBE
            ld      a,$03
L1EBE:      ld      (LD1EF),a
            ld      a,$02
            ld      (LD043),a
            xor     a
            ld      (LD1ED),a
            ld      (P2_Input_State),a
            ld      a,$10
            jr      z,L1ED3
            ld      a,$20
L1ED3:      call    L1EF3
L1ED6:      ld      hl,P2_Actor_Record
            bit     7,(hl)
            ret     nz
            ld      a,(P2_Lives)
            and     a
            ret     z
            ld      b,$F0
            ld      de,L0248
            call    L1F55
            ld      (LD1F0),a
            ld      a,$02
            ld      (LD044),a
            ld      a,$20
L1EF3:      ld      c,$00
            push    hl
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),a
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),b
            inc     hl
            ld      (hl),c
L1F00:      inc     hl
            ld      (hl),$90
            inc     hl
            ld      (hl),d
            inc     hl
            ld      (hl),e
            push    bc
            push    hl
            call    Select_P1_Life_Icon
            ld      a,b
L1F0D:      and     a
            call    nz,Select_P2_Life_Icon
            ex      de,hl
            pop     hl
            ld      b,$05
L1F15:      ld      a,(de)
            inc     de
            inc     hl
            ld      (hl),a
            djnz    L1F15
            pop     bc
            pop     hl
            ld      (hl),$94
L1F1F:      ld      a,b
            cp      $78
            jr      c,L1F50
            ld      hl,L2CA3
L1F27:      ld      de,L004B
L1F2A:      ld      b,$04
            di
            ld      a,$20
            out     (MAGIC),a
            ld      a,(LD1EB)
            and     a
            ld      c,$55
L1F37:      jr      z,L1F3B
            ld      c,$FF
L1F3B:      ld      a,c
            and     $0F
L1F3E:      ld      (hl),a
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),c
            inc     hl
            ld      a,c
            and     $F0
            ld      (hl),a
            add     hl,de
            djnz    L1F3B
            ret
L1F50:      ld      hl,L2C67
            jr      L1F27
L1F55:      ld      a,(Game_Mode)
            ld      c,a
            and     a
            ld      a,$01
            ret     z
            ld      a,$0A
            ret
            nop
            dec     iy
            dec     iy
            ei
            call    L2081
            call    L2BFD
            call    L203B
            ld      hl,LD1C3
            bit     0,(hl)
            jr      z,L1F94
            res     0,(hl)
            push    hl
            ld      ix,P1_Actor_Record
            call    L21B8
            call    L2259
            call    L2132
            call    L2633
            call    L2D9A
            ld      a,(LD1DF)
            and     a
L1F90:      call    z,L231F
            pop     hl
L1F94:      bit     1,(hl)
            jr      z,L1FBC
            res     1,(hl)
            push    hl
            ld      ix,P2_Actor_Record
            call    L2274
            ld      a,$01
            ld      (LD1DA),a
            call    L2132
            call    L2633
            call    L2D9A
            xor     a
            ld      (LD1DA),a
            ld      a,(LD1DF)
            and     a
            call    z,L2327
            pop     hl
L1FBC:      push    hl
            call    L0BF7
L1FC0:      ld      hl,LD1E0
            dec     (hl)
            pop     hl
            jr      z,L2014
            ld      a,(hl)
            and     $03
            ret     nz
            bit     2,(hl)
            jr      z,L1FEE
            res     2,(hl)
            push    hl
            ld      a,$05
L1FD4:      push    af
            ld      hl,P1_Actor_Record
            ld      de,P2_Actor_Record
            call    Select_Enemy_Record_IX
            call    L256E
            call    L2633
            call    L2D9A
            pop     af
            dec     a
            dec     a
            jp      p,L1FD4
            pop     hl
L1FEE:      bit     3,(hl)
L1FF0:      jr      z,L2010
            res     3,(hl)
            push    hl
            ld      a,$06
L1FF7:      push    af
            ld      hl,P2_Actor_Record
            ld      de,P1_Actor_Record
            call    Select_Enemy_Record_IX
L2001:      call    L256E
L2004:      call    L2633
            call    L2D9A
            pop     af
            dec     a
L200C:      dec     a
            jr      nz,L1FF7
            pop     hl
L2010:      ld      a,(hl)
            and     $03
            ret     nz
L2014:      ld      a,$04
            ld      (LD1E0),a
            call    Random_Byte
            call    L2B8B
            call    L2A38
            call    L22FD
            call    L2740
            call    L1E9F
            call    L8003
            call    L2D6B
            call    L2C15
            call    L1A0B
            jp      L22A8
            nop
L203B:      ld      a,(LD1DB)
            and     a
            ret     z
            ld      ix,P1_Actor_Record
            ld      a,(P2_Input_State)
            call    L2051
            ld      ix,P2_Actor_Record
            ld      a,(P1_Input_State)
L2051:      and     $0F
            ld      c,a
            ld      b,(ix+$00)
            bit     7,b
            ret     z
            bit     3,b
            ret     nz
            bit     4,b
            jr      nz,L2070
            bit     5,(ix+$08)
            jr      nz,L2070
            ld      a,(ix+$01)
            and     $F0
            or      c
            ld      (ix+$01),a
L2070:      bit     0,c
            ret     z
            bit     2,b
            ret     z
            res     2,(ix+$00)
            ld      hl,Sound_Request_2
            set     6,(hl)
            ret
L2080:      nop
L2081:      ld      hl,LD040
            ld      a,(hl)
            and     a
            jr      z,L20AE
            ld      (hl),$00
            rra
            push    af
            call    c,L283D
            pop     af
            rra
            push    af
            call    c,L27C0
            pop     af
            rra
            push    af
            call    c,L284D
            pop     af
            rra
            push    af
            call    c,L27F3
            pop     af
            rra
            push    af
            call    c,L27DF
            pop     af
            rra
            push    af
            call    c,L20E8
            pop     af
L20AE:      ld      hl,LD041
            ld      a,(hl)
            and     a
            jr      z,L20E7
            ld      (hl),$00
            rra
            push    af
            call    c,L2113
            pop     af
            rra
            push    af
            call    c,L28CD
            pop     af
            rra
            push    af
            call    c,L2100
            pop     af
            rra
            push    af
            call    c,Initialize_Player_Life_Displays
            pop     af
            rra
            push    af
            call    c,L20E7
            pop     af
            rra
            push    af
            call    c,L20E7
            pop     af
            rra
            push    af
            call    c,L20E7
            pop     af
            rra
            push    af
            call    c,L20F6
            pop     af
L20E7:      ret
L20E8:      ld      a,(LD053)
            and     a
            ret     nz
            inc     a
            ld      (LD050),a
            ld      iy,(LD051)
            ret
L20F6:      ld      a,(LD050)
            and     a
            ret     nz
            inc     iy
            inc     iy
            ret


L2100:      xor     a
            ld      (LD1E8),a
            ld      hl,LD096
            ld      (hl),$40
            call    L210C
L210C:      inc     hl
            inc     hl
            ld      a,(hl)
            and     $FC
            ld      (hl),a
            ret
L2113:      ld      ix,Enemy_1_Actor_Record
            ld      hl,LD04F
            bit     7,(ix+$13)
            jr      z,L2123
L2120:      ld      (hl),$01
            ret
L2123:      ld      a,(ix+$00)
            and     $88
            cp      $80
            jr      nz,L2120
            ld      (hl),$14
            jp      L2342
            nop
L2132:      push    iy
            ld      a,$06
L2136:      push    af
            call    Select_Enemy_Record_IY
            call    L2144
            pop     af
            dec     a
            jr      nz,L2136
            pop     iy
            ret
L2144:      ld      a,(ix+$00)
            and     $98
            cp      $80
            ret     nz
            ld      a,(iy+$00)
            and     $9A
            cp      $80
            ret     nz
            ld      a,(iy+$04)
            sub     (ix+$04)
            ld      h,a
            add     a,$0E
            cp      $1C
            ret     nc
            ld      a,(iy+$06)
            sub     (ix+$06)
            ld      d,a
            add     a,$0E
            cp      $1C
            ret     nc
            ld      b,(iy+$07)
            bit     1,b
            jr      z,L2174
            ex      de,hl
L2174:      ld      a,h
            and     a
            jr      nz,L2189
            ld      a,d
            bit     0,b
            ld      h,$FF
            jr      z,L2181
            inc     h
            cpl
L2181:      cp      $0E
            jp      c,L0D4C
            ld      a,b
            cpl
            ld      b,a
L2189:      ld      a,h
            and     a
            ld      d,$00
            ld      h,d
            jp      p,L2198
            ld      d,$18
            bit     1,b
            jr      z,L2198
            ex      de,hl
L2198:      ld      a,(ix+$04)
            call    L244D
            add     a,d
            jr      c,L21A4
            ld      (ix+$04),a
L21A4:      ld      a,(ix+$06)
            call    L244D
            add     a,h
            cp      $79
            jr      nc,L21B2
            ld      (ix+$06),a
L21B2:      set     5,(ix+$00)
            ret
            nop
L21B8:      ld      a,(Game_Mode)
            dec     a
            ret     nz
            ld      a,(P2_Actor_Record)
            ld      b,a
            rla
            jr      c,L21D0
            ld      a,(P2_Lives)
            and     a
            jr      nz,L21D0
            ld      (ix+$00),a
            ld      (P1_Lives),a
L21D0:      ld      a,(ix+$00)
            and     $9C
            cp      $80
            ret     nz
            ld      a,(ix+$01)
            and     $F0
            jr      nz,L21EB
            ld      a,r
            bit     3,a
            ld      a,$09
            jr      z,L2237
            ld      a,$06
            jr      L2237
L21EB:      ld      hl,LD049
            ld      a,(hl)
            and     a
            jr      nz,L223A
            ld      (hl),$90
            push    iy
            ld      de,L00FF
            ld      a,$06
L21FB:      push    af
            call    Select_Enemy_Record_IY
            bit     7,(iy+$00)
            jr      z,L2230
            ld      a,(ix+$04)
L2208:      sub     (iy+$04)
            ld      l,$04
            jr      nc,L2213
L220F:      ld      l,$08
            neg
L2213:      rra
            and     $7F
            ld      b,a
            ld      a,(ix+$06)
            sub     (iy+$06)
            ld      h,$01
            jr      nc,L2225
            ld      h,$02
            neg
L2225:      rra
            and     $7F
            add     a,b
L2229:      cp      e
            jr      nc,L2230
            ld      e,a
            ld      a,h
            or      l
            ld      d,a
L2230:      pop     af
            dec     a
            jr      nz,L21FB
            pop     iy
            ld      a,d
L2237:      ld      (LD1ED),a
L223A:      bit     7,(ix+$13)
            ret     nz
            push    iy
            ld      a,$06
L2243:      push    af
L2244:      call    Select_Enemy_Record_IY
            ld      a,(iy+$00)
            and     $8A
            cp      $80
            call    z,L24B8
            pop     af
            dec     a
            jr      nz,L2243
            pop     iy
            ret
            nop
L2259:      ld      a,(LD1ED)
            ld      d,a
            ld      a,(Game_Mode)
            cp      GAME_MODE_TWO_PLAYER
            jr      nz,L226F
            in      a, (P2PORT)
            ld      hl,LD04A
            call    L228E
            call    c,L289D
L226F:      ld      a,d
            ld      (P2_Input_State),a
            ret
L2274:      ld      a,(LD1EE)
            ld      d,a
            ld      a,(Game_Mode)
            and     a
            jr      z,L2289
            in      a, (P1PORT)
            ld      hl,LD04B
            call    L228E
            call    c,L289D
L2289:      ld      a,d
            ld      (P1_Input_State),a
            ret
L228E:      cpl
            and     $3F
            ld      d,a
            bit     3,(ix+$00)
            ret     nz
            ld      a,$20
            bit     4,d
            jr      nz,L22A3
            ld      a,(hl)
            and     a
            jr      z,L22A5
            dec     (hl)
            ret
L22A3:      ld      (hl),$02
L22A5:      scf
            ret
            nop
L22A8:      ld      hl,LD1E5
            bit     1,(hl)
            res     1,(hl)
            ld      a,$0C
            push    hl
            call    nz,L22C0
            pop     hl
            bit     0,(hl)
            res     0,(hl)
            ld      a,$00
            call    nz,L22C0
            ret
L22C0:      ld      hl,Status_Glyph_Data
            ld      de,$1132
            push    af
            call    L22F4
            pop     af
            ld      de,L117C
            call    L22F4
            ld      c,$F0
            ld      de,L0050
            di
            ld      a,$20
            out     (MAGIC),a
            ld      hl,L0F57
            call    L22E4
            ld      hl,L0F98
L22E4:      ld      b,$08
L22E6:      ld      (hl),c
            add     hl,de
            ld      (hl),c
            add     hl,de
            add     hl,de
            djnz    L22E6
            ld      a,c
            rrca
            rrca
            rrca
            rrca
            ld      c,a
            ret
L22F4:      ld      bc,L01FF
            jp      printstr
Status_Glyph_Data:
            DB      $5C,$61,$00    ; Two custom display glyphs and terminator
L22FD:      ld      a,(LD1C6)
L2300:      and     a
            ret     nz
            ld      a,$06
            push    iy
L2306:      push    af
            call    Select_Enemy_Record_IX
            ld      iy,P1_Actor_Record
            call    L2498
            ld      iy,P2_Actor_Record
            call    L2498
L2318:      pop     af
            dec     a
            jr      nz,L2306
            pop     iy
            ret
L231F:      ld      a,(P2_Input_State)
            ld      hl,LD1E6
            jr      L232D
L2327:      ld      a,(P1_Input_State)
            ld      hl,LD1E7
L232D:      bit     5,(hl)
            ld      (hl),a
            ret     nz
            bit     5,a
            ret     z
            ld      a,(ix+$00)
            bit     7,a
            ret     z
            and     $18
            ret     nz
            bit     7,(ix+$13)
            ret     nz
L2342:      ld      e,(ix+$04)
            ld      d,(ix+$06)
            ld      bc,$0000
            ld      a,(ix+$07)
            bit     1,a
            rra
            jp      z,L239B
            jr      nc,L236D
            call    L254C
L2359:      call    L2463
L235C:      ret     m
            cp      b
            ret     c
            call    L2422
            ld      a,(ix+$04)
            add     a,$16
            jr      nc,L2382
            ld      a,$FF
            jr      L2382
L236D:      call    L2547
L2370:      call    L246D
            ret     m
            cp      b
            ret     c
            call    L240E
            ld      a,(ix+$04)
            bit     2,c
            jr      z,L2382
            sub     $06
L2382:      and     $F8
            jr      nz,L2388
            ld      a,$08
L2388:      ld      b,a
            ld      a,(ix+$06)
            add     a,$0B
            bit     2,(ix+$07)
            jr      z,L2396
            add     a,$03
L2396:      ld      h,a
            ld      l,$00
            jr      L23D2
L239B:      jr      nc,L23B1
            call    L2542
L23A0:      call    L2477
            ret     m
            cp      b
            ret     c
            call    L2422
            ld      a,(ix+$06)
            ld      l,c
            add     a,$16
            jr      L23C7
L23B1:      call    L253D
L23B4:      call    L2481
            ret     m
            cp      b
            ret     c
            call    L240E
            ld      a,(ix+$06)
            ld      l,c
            bit     2,c
            jr      z,L23C7
            sub     $06
L23C7:      and     $F8
            ld      h,a
            ld      a,(ix+$04)
            add     a,$08
            ld      b,a
            ld      c,$00
L23D2:      ld      (ix+$14),c
            ld      (ix+$16),l
            ld      (ix+$15),b
            ld      (ix+$17),h
            ld      a,(ix+$07)
            and     $07
            or      d
            ld      (ix+$13),a
            bit     2,(ix+$07)
            ld      hl,Sound_Request_2
            jr      nz,L23F3
            set     1,(hl)
            ret
L23F3:      inc     hl
            ld      a,(LD1EB)
            and     a
            ld      a,$08
            jr      z,L240A
            ld      b,a
L23FD:      ld      a,(LD1C6)
            and     a
            ld      a,b
            jr      z,L240A
            ld      hl,Sound_Request_4
            set     2,(hl)
            ret
L240A:      rrca
            or      (hl)
            ld      (hl),a
            ret
L240E:      ld      c,$F8
            ld      a,(LD1C6)
            and     a
            jr      nz,L2418
            ld      c,$FC
L2418:      bit     2,(ix+$07)
            jr      nz,L2434
            ld      c,$F8
            jr      L2434
L2422:      ld      c,$08
            ld      a,(LD1C6)
            and     a
            jr      nz,L242C
            ld      c,$04
L242C:      bit     2,(ix+$07)
            jr      nz,L2434
            ld      c,$08
L2434:      set     1,(ix+$08)
            ld      (ix+$1a),$03
            ld      (ix+$1b),$01
            set     5,(ix+$00)
            ret
L2445:      ld      hl,Coordinate_Thresholds
L2448:      cp      (hl)
            inc     hl
            jr      c,L2448
            ret
L244D:      exx
            ld      hl,Coordinate_Thresholds-1
L2451:      inc     hl
            cp      (hl)
            jr      c,L2451
            ld      a,(hl)
            exx
L2457:      ret
Coordinate_Thresholds:
            DB      $F0,$D8,$C0,$A8,$90,$78,$60,$48,$30,$18,$00
L2463:      call    Maze_Cell_Address_From_XY
            ld      de,$0001
            ld      a,$08
            jr      L2489
L246D:      call    Maze_Cell_Address_From_XY
            ld      de,LFFFF
            ld      a,$04
            jr      L2489
L2477:      call    Maze_Cell_Address_From_XY
L247A:      ld      de,L000B
            ld      a,$02
            jr      L2489
L2481:      call    Maze_Cell_Address_From_XY
            ld      de,LFFF5
            ld      a,$01
L2489:      and     (hl)
            jr      z,L2490
            add     hl,de
            inc     c
            jr      L2489
L2490:      ld      a,c
            and     a
            ld      d,$80
            ret     nz
            ld      d,$A0
            ret
L2498:      ld      a,(ix+$00)
            and     $8A
            cp      $80
            ret     nz
            bit     7,(ix+$13)
            ret     nz
            ld      a,(ix+$02)
            cp      $40
            ret     z
            ld      a,(LD1E8)
            and     a
            ret     nz
            ld      a,(iy+$00)
            and     $98
            cp      $80
            ret     nz
L24B8:      ld      a,(ix+$1c)
            and     a
            ret     nz
            ld      d,(ix+$06)
            ld      e,(ix+$04)
            ld      h,(iy+$06)
            ld      l,(iy+$04)
            ld      a,(ix+$07)
            bit     1,a
            rra
            jr      z,L24FD
            jr      nc,L24E8
            ld      a,h
            sub     d
            add     a,$0E
            cp      $1C
            ret     nc
            ld      a,l
            sub     e
            ret     c
            call    L254C
            ld      c,e
            ld      b,l
            call    L2529
            jp      L2359
L24E8:      ld      a,d
            sub     h
            add     a,$0E
            cp      $1C
            ret     nc
            ld      a,e
            sub     l
            ret     c
            ld      c,l
            call    L2547
            ld      b,e
            call    L2529
            jp      L2370
L24FD:      jr      nc,L2514
            ld      a,l
            sub     e
            add     a,$0E
            cp      $1C
            ret     nc
            ld      a,h
            sub     d
            ret     c
            call    L2542
            ld      c,d
            ld      b,h
            call    L2529
            jp      L23A0
L2514:      ld      a,e
            sub     l
            add     a,$0E
L2518:      cp      $1C
            ret     nc
            ld      a,d
            sub     h
            ret     c
            call    L253D
            ld      c,h
            ld      b,d
            call    L2529
            jp      L23B4
L2529:      ld      a,c
            call    L244D
            ld      c,a
            ld      a,b
            call    L244D
            sub     c
            ld      b,$FF
L2535:      inc     b
            sub     $18
            jr      nc,L2535
            ld      c,$00
            ret
L253D:      ld      a,d
            add     a,$02
            ld      d,a
            ret
L2542:      ld      a,d
            add     a,$14
            ld      d,a
            ret
L2547:      ld      a,e
            add     a,$02
            ld      e,a
            ret
L254C:      ld      a,e
            add     a,$14
            jr      nc,L2553
            ld      a,$FF
L2553:      ld      e,a
            ret
            nop
L2556:      ld      a,(ix+$06)
            cp      $30
            ld      b,$01
            jr      nc,L2561
            ld      b,$02
L2561:      ld      a,(LD1EA)
            and     a
            ld      a,$04
            jr      z,L256B
            ld      a,$08
L256B:      jp      L2609
L256E:      ld      a,(ix+$00)
            ld      b,a
            and     $88
            cp      $80
            ret     nz
            ld      a,(ix+$24)
            and     a
            jr      z,L2580
            dec     (ix+$24)
L2580:      ld      a,(ix+$23)
            and     a
            jr      z,L258A
            dec     (ix+$23)
            ex      af,af'
L258A:      bit     6,b
            jr      z,L2598
            res     6,(ix+$00)
            ld      a,(ix+$25)
            ld      (ix+$02),a
L2598:      ld      a,(ix+$01)
            and     a
            jr      z,L25A4
            and     $F0
            jr      z,L25C9
            ex      af,af'
            ret     nz
L25A4:      ld      a,(LD1C6)
            and     a
            jr      nz,L25B2
            ld      a,(LD1EB)
            and     a
            jr      nz,L2556
            jr      L25B9
L25B2:      ld      a,(LD1EA)
            and     a
            jr      z,L25B9
            ex      de,hl
L25B9:      ld      a,(hl)
            and     $98
            cp      $80
            jr      z,L25ED
            ex      de,hl
            ld      a,(hl)
            ex      de,hl
            and     $98
            cp      $80
            jr      z,L25E7
L25C9:      ld      a,(ix+$06)
            cp      $30
            ld      c,$02
            jr      c,L25D4
            ld      c,$01
L25D4:      ld      a,r
            bit     4,a
            ld      b,$01
            jr      z,L25DD
            ld      b,c
L25DD:      bit     2,a
            ld      a,$04
            jr      z,L25E5
            ld      a,$08
L25E5:      jr      L2609
L25E7:      ex      de,hl
            call    L25ED
            ex      de,hl
            ret
L25ED:      push    hl
            ld      bc,$0004
            add     hl,bc
            ld      a,(hl)
            sub     (ix+$04)
            ld      b,$08
            jr      nc,L25FC
            ld      b,$04
L25FC:      inc     hl
            inc     hl
            ld      a,(hl)
            sub     (ix+$06)
            ld      a,$02
            jr      nc,L2608
            ld      a,$01
L2608:      pop     hl
L2609:      or      b
            ld      b,a
            ld      a,(ix+$01)
            and     $F0
            or      b
            ld      (ix+$01),a
L2614:      ld      a,(ix+$02)
            ld      b,$FF
            cp      $10
            jr      c,L262B
            ld      b,$7F
            cp      $20
            jr      c,L262B
            ld      b,$3F
            cp      $40
            jr      c,L262B
            ld      b,$1F
L262B:      ld      a,r
            and     b
            ld      (ix+$23),a
            ret
            nop
L2633:      bit     3,(ix+$00)
            ret     z
            bit     7,(ix+$08)
            ret     nz
            ld      a,(ix+$1d)
            and     a
            jp      nz,L0D59
            dec     (ix+$03)
            ret     nz
            ld      a,(ix+$05)
            and     a
            jr      z,L26AC
            ld      (ix+$03),$04
            dec     (ix+$05)
            jr      z,L26A7
            ld      a,(ix+$07)
            inc     (ix+$07)
            bit     7,a
            ld      hl,Actor_Frame_Pointer_Table_A
            jr      nz,L2667
            ld      hl,Actor_Frame_Pointer_Table_B
L2667:      and     $3F
            ld      c,a
            ld      b,$00
            add     hl,bc
            add     hl,bc
            ld      c,(hl)
            inc     hl
            ld      b,(hl)
            call    L30C7
            ld      a,(ix+$01)
            or      $23
            ld      (hl),a
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),b
            inc     d
            inc     d
            inc     d
            inc     e
            inc     e
            call    XY_To_Video_Address
            ld      bc,$0000
            bit     7,(ix+$01)
            jr      z,L2692
            ld      bc,$0550
L2692:      bit     6,(ix+$01)
            jr      z,L269C
            ld      a,c
            add     a,$05
            ld      c,a
L269C:      ex      de,hl
            add     hl,bc
            ex      de,hl
            inc     hl
            ld      (hl),e
            inc     hl
            ld      (hl),d
            set     5,(ix+$08)
L26A7:      set     7,(ix+$08)
            ret
L26AC:      ld      (ix+$00),$00
            bit     7,(ix+$07)
            ret     z
            ld      a,(ix+$08)
            and     $0C
            cp      $0C
            ret     z
            ld      e,$0C
            cp      $08
            jr      z,L26E8
            ld      e,$08
            ld      a,(Dungeon_Number)
            cp      $07
            jr      c,L26CE
            ld      a,$06
L26CE:      sub     $07
            ld      hl,LD1D6
            inc     (hl)
            add     a,(hl)
            ret     m
            ld      hl,LD1E3
            ld      a,(hl)
            and     a
            jr      nz,L26E8
            call    Random_Byte
            and     $07
            or      $28
            ld      (hl),a
            call    L8009
L26E8:      ld      d,(ix+$02)
L26EB:      call    Random_Byte
            and     $07
            inc     a
            ld      b,a
            xor     a
L26F3:      add     a,$18
            djnz    L26F3
            ld      c,a
            ld      a,(LD058)
            sub     c
            add     a,$18
            cp      $30
            jr      c,L26EB
            ld      a,(LD078)
            sub     c
            add     a,$18
            cp      $30
            jr      c,L26EB
L270C:      call    Random_Byte
            and     $03
            inc     a
            ld      b,a
L2713:      xor     a
L2714:      add     a,$18
            djnz    L2714
            ld      b,a
            ld      a,(LD05A)
            sub     b
            add     a,$0C
            cp      $18
            jr      c,L270C
            ld      a,(LD07A)
            sub     b
            add     a,$0C
            cp      $18
            jr      c,L270C
L272D:      ld      a,c
            cp      $78
            ld      a,$01
            jr      c,L2735
            xor     a
L2735:      ld      (LD1EA),a
            ld      (ix+$24),$1E
            jp      L2A0B
            nop
L2740:      ld      a,(LD1C9)
            and     a
            ret     nz
            ld      a,$06
L2747:      push    af
            call    Select_Enemy_Record_IX
            call    L2754
            pop     af
            dec     a
            jr      nz,L2747
            ei
            ret
L2754:      bit     7,(ix+$20)
            res     7,(ix+$20)
            ld      l,(ix+$21)
            ld      h,(ix+$22)
            ld      c,$00
            call    nz,L27B5
            ld      a,(ix+$00)
            and     $88
            cp      $80
            ret     nz
            set     7,(ix+$20)
            ld      a,(ix+$06)
L2776:      add     a,$0C
            ld      c,$FF
L277A:      inc     c
            sub     $18
            jr      nc,L277A
            ld      b,$00
            ld      hl,L18C4
            add     hl,bc
            add     hl,bc
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            ld      a,(ix+$04)
            add     a,$0C
            ld      b,$00
            ld      h,b
L2791:      inc     b
            sub     $18
            jr      nc,L2791
            xor     a
L2797:      add     a,$02
            djnz    L2797
            ld      l,a
            add     hl,de
            ld      (ix+$21),l
            ld      (ix+$22),h
            ld      a,(ix+$08)
            and     $0C
            ld      c,$FF
            jp      pe,L27B5
            ld      c,$AA
            bit     3,a
            jr      nz,L27B5
            ld      c,$55
L27B5:      ld      de,L0050
            ld      b,$04
L27BA:      ld      (hl),c
            add     hl,de
            djnz    L27BA
            ret
            nop
L27C0:      ld      a,$02
            ld      (LD046),a
            call    L27D0
            ld      l,h
            call    L27D0
            ld      (LD1ED),hl
            ret
L27D0:      ld      a,r
            bit     2,a
            ld      h,$05
            jr      nz,L27DA
            ld      h,$09
L27DA:      bit     3,a
            ret     z
            inc     h
            ret
L27DF:      ld      hl,LD043
            ld      de,L2F90
            exx
            ld      hl,P1_Actor_Record
            ld      de,LD1EF
            ld      bc,P2_Input_State
            ld      a,$04
            jr      L2805
L27F3:      ld      hl,LD044
            ld      de,L2FBE
            exx
            ld      hl,P2_Actor_Record
            ld      de,LD1F0
            ld      bc,P1_Input_State
L2803:      ld      a,$08
L2805:      ex      af,af'
            ld      a,(LD1DB)
            and     a
            ret     z
            bit     7,(hl)
            ld      a,$40
            jr      z,L2825
            bit     2,(hl)
            jr      z,L2825
            ex      de,hl
            dec     (hl)
            jr      nz,L281F
            ld      h,b
            ld      l,c
            ld      (hl),$01
            jr      L2825
L281F:      exx
            inc     (hl)
            exx
            ld      a,(hl)
            or      $30
L2825:      exx
            ld      hl,LD1CB
            ld      (hl),a
L282A:      in      a, (COINPORT)
            bit     7,a
            jr      nz,L2837
            push    hl
            ld      hl,L02D1
            add     hl,de
            ex      de,hl
L2836:      pop     hl
L2837:      ld      b,$01
            ex      af,af'
            jp      L045C
L283D:      ld      hl,LD18E
            set     2,(hl)
            ld      hl,LD198
            set     3,(hl)
            ld      hl,LD1E5
            set     1,(hl)
            ret
L284D:      ld      a,$07
            ld      (LD045),a           ;
            ld      a,(Dungeon_Number)
            dec     a
            ld      d,$21
            jr      nz,L285C
            ld      d,$01
L285C:      cp      $05
            ld      e,$01
            jr      nc,L286A
            ld      c,a
            ld      b,$00
            ld      hl,L2882
            add     hl,bc
            ld      e,(hl)
L286A:      ld      hl,LD1E9
            inc     (hl)
            ld      a,(hl)
            cp      e
            jr      c,L2874
            ld      d,$41
L2874:      ld      a,$06
L2876:      push    af
            call    Select_Enemy_Record_IX
            call    L2887
            pop     af
            dec     a
            jr      nz,L2876
            ret
L2882:      dec     b
            ld      b,$04
            inc     bc
            ld      (bc),a
L2887:      ld      a,(ix+$00)
            and     $88
            cp      $80
            ret     nz
L288F:      ld      a,(ix+$02)
            add     a,a
            cp      d
            ret     nc
            res     6,(ix+$00)
            cp      $10
            jr      c,L289F
L289D:      and     $F0
L289F:      ld      (ix+$02),a
            cp      $20
            ret     c
            ld      b,$FE
            jr      z,L28AB
            ld      b,$FC
L28AB:      ld      a,(ix+$04)
            and     b
            ld      (ix+$04),a
            ld      a,(ix+$06)
            and     b
            ld      (ix+$06),a
            ret
L28BA:      ld      a,$2D
            ld      (hl),a
            ld      (LD04E),a
L28C0:      ld      ix,Enemy_1_Actor_Record
            ld      (ix+$00),$00
            set     7,(ix+$08)
            ret
L28CD:      ld      hl,LD1C7
            ld      a,(hl)
            and     a
            jr      z,L28BA
            ld      (hl),$00
            ld      a,(LD1C8)
            and     a
            ret     nz
            ld      hl,Sound_Request_4
            set     1,(hl)
            ld      a,(Dungeon_Number)
            ld      b,a
            ld      a,$B0
L28E6:      sub     $0A
            djnz    L28E6
            cp      $3C
            jr      nc,L28F0
            ld      a,$3C
L28F0:      ld      (LD04E),a
            inc     a
            ld      (LD045),a           ; ???
            ld      hl,P1_Actor_Record
            ld      de,P2_Actor_Record
            call    Random_Byte
            bit     3,a
            jr      z,L2905
            ex      de,hl
L2905:      ld      a,(hl)
            and     $98
            cp      $80
            jr      z,L2918
            ex      de,hl
            ld      a,(hl)
            and     $98
            cp      $80
            ld      bc,L0078
            jp      nz,L2998
L2918:      ld      a,l
            ld      de,P1_Actor_Record
            sub     e
            ld      (LD1EA),a
            push    hl
            pop     ix
            ld      hl,LD1F3
            call    L29AB
            ld      c,a
            inc     hl
            call    L29AB
            ld      h,a
            ld      l,c
            ld      a,(ix+$04)
            add     a,$0C
            call    L244D
            ld      c,a
            ld      a,(ix+$06)
            add     a,$0C
            call    L244D
            ld      b,a
            ld      de,LD1F3
L2945:      call    Random_Byte
            bit     2,a
            jr      nz,L2971
            bit     4,a
            ld      a,(ix+$07)
            jr      nz,L295E
            and     $03
            cp      $03
            call    z,L29A2
            ld      a,c
            add     a,h
            jr      L2967
L295E:      and     $03
            cp      $02
            call    z,L29A2
            ld      a,c
            sub     h
L2967:      jr      c,L2945
            cp      $F1
            jr      nc,L2945
            ld      c,a
            inc     de
            jr      L2991
L2971:      bit     4,a
            ld      a,(ix+$07)
            jr      nz,L2983
            and     $03
            cp      $01
            call    z,L29A2
            ld      a,b
            add     a,l
            jr      L298A
L2983:      and     $03
            call    z,L29A2
            ld      a,b
            sub     l
L298A:      jr      c,L2945
            cp      $79
            jr      nc,L2945
            ld      b,a
L2991:      ex      de,hl
            ld      a,(hl)
            cp      $02
            jr      c,L2998
            dec     (hl)
L2998:      ld      de,L200C
            ld      ix,Enemy_1_Actor_Record
            jp      L2A0B
L29A2:      call    Random_Byte
            and     $03
            ret     z
            pop     af
            jr      L2945
L29AB:      ld      b,(hl)
            xor     a
L29AD:      add     a,$18
            djnz    L29AD
            ret
            nop
            ld      a,(Dungeon_Number)
            and     a
            jr      z,L29C5
            cp      $04
            jr      nc,L29D3
            add     a,a
            add     a,$03
            ld      d,a
            ld      a,$06
            jr      L29C9
L29C5:      ld      d,$06
            ld      a,$02
L29C9:      push    af
            call    L29E6
            pop     af
            inc     d
            dec     a
            jr      nz,L29C9
            ret
L29D3:      ld      d,$20
            cp      $07
            jr      c,L29DB
            ld      d,$40
L29DB:      ld      a,$06
L29DD:      push    af
            call    L29E6
            pop     af
            dec     a
            jr      nz,L29DD
            ret
L29E6:      ld      e,$04
            ld      h,a
            call    Select_Enemy_Record_IX
            ld      c,h
            ld      hl,L2A29
            add     hl,bc
            add     hl,bc
            call    Random_Byte
            bit     4,a
            ld      a,$18
            jr      z,L29FC
            xor     a
L29FC:      add     a,(hl)
            ld      c,a
            call    Random_Byte
            bit     2,a
            ld      a,$18
            jr      z,L2A08
            xor     a
L2A08:      inc     hl
            add     a,(hl)
            ld      b,a
L2A0B:      push    ix
            pop     hl
            inc     hl
            ld      (hl),$00
            inc     hl
            ld      (hl),d
            inc     hl
            ld      (hl),$00
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),$00
            inc     hl
            ld      (hl),b
            inc     hl
            ld      (hl),$04
            inc     hl
            ld      (hl),e
            ld      (ix+$1f),$E0
            ld      (ix+$00),$80
            ret
            jr      L2A2D
L2A2D:      ld      c,b
            nop
            sub     b
            nop
            ret     nz
            nop
            ld      c,b
            jr      nc,L29C6
            jr      nc,L2A38
L2A38:      push    iy
            ld      a,$06
L2A3C:      push    af
            call    Select_Enemy_Record_IX
            ld      c,$FF
            ld      iy,P1_Actor_Record
            call    L2AF6
            ld      a,c
            and     a
            jp      p,L2A90
            ld      iy,P2_Actor_Record
            call    L2AF6
            ld      a,c
            and     a
            jp      p,L2A90
            ld      a,(ix+$02)
            cp      $10
            jr      nc,L2A63
            ld      a,$10
L2A63:      ld      b,$1E
            sub     $10
            jr      z,L2A6B
            ld      b,$0F
L2A6B:      ld      a,(LD1C6)
            and     a
            jr      z,L2A73
            ld      b,$00
L2A73:      ld      (ix+$1c),b
            ld      a,(ix+$24)
            and     a
            jr      nz,L2AE3
            bit     5,(ix+$00)
            jr      nz,L2AE3
            set     1,(ix+$00)
            set     7,(ix+$08)
            ld      (ix+$1f),$E0
            jr      L2AE3
L2A90:      ld      a,(LD1C6)
            and     a
            jr      nz,L2AE3
            res     1,(ix+$00)
            ld      a,(ix+$24)
            and     a
            ld      (ix+$24),$1E
            jr      nz,L2AE3
            ld      hl,Sound_Request_2
            ld      a,(ix+$08)
            and     $0C
            jp      pe,L2AEB
            bit     2,a
            ld      a,$10
            jr      nz,L2AB7
L2AB5:      or      (hl)
            ld      (hl),a
L2AB7:      call    L2614
            ld      a,r
            ld      b,a
            ld      a,(LD1E9)
            cp      $04
            jr      nc,L2AD0
            bit     3,b
            jr      z,L2AD0
            ld      a,(ix+$01)
            xor     $0F
            ld      (ix+$01),a
L2AD0:      bit     4,b
            jr      z,L2AE3
            ld      a,(ix+$02)
            ld      (ix+$25),a
            ld      d,$20
            call    L288F
            set     6,(ix+$00)
L2AE3:      pop     af
            dec     a
            jp      nz,L2A3C
            pop     iy
            ret
L2AEB:      ld      a,(LD1EB)
            and     a
            ld      a,$08
            jr      z,L2AB5
            rrca
            jr      L2AB5
L2AF6:      ld      a,(ix+$00)
            and     $88
            cp      $80
            ret     nz
            ld      a,(iy+$00)
            and     $98
            cp      $80
            ret     nz
            call    L2B7D
            ld      a,e
L2B0A:      sub     l
            cp      $F1
            jr      nc,L2B14
            cp      $0F
            jr      nc,L2B48
            ex      de,hl
L2B14:      ld      a,h
L2B15:      call    L244D
            ld      h,a
            ld      a,d
            call    L244D
L2B1D:      sub     h
            jr      nc,L2B23
            ld      h,d
            neg
L2B23:      ld      c,$02
L2B25:      dec     c
            sub     $18
            jr      nc,L2B25
            ld      d,h
            push    hl
            ld      a,c
            push    af
            ld      a,e
            add     a,$11
            jr      nc,L2B35
            ld      a,$FF
L2B35:      ld      e,a
            call    L2477
            pop     af
            pop     de
            dec     c
            ret     p
            ld      c,a
            call    L2477
            dec     c
            ret     p
            ld      c,$FF
            call    L2B7D
L2B48:      ld      a,d
            sub     h
            cp      $EF
            jr      nc,L2B52
            cp      $11
            ret     nc
            ex      de,hl
L2B52:      ld      a,l
            call    L244D
            ld      l,a
            ld      a,e
            call    L244D
            sub     l
            jr      nc,L2B61
            ld      l,e
            neg
L2B61:      ld      c,$02
L2B63:      dec     c
            sub     $18
            jr      nc,L2B63
            ld      e,l
            push    hl
            ld      a,c
            push    af
            ld      a,d
            add     a,$11
            ld      d,a
            call    L2463
            pop     af
            pop     de
            dec     c
            ret     p
            ld      c,a
            call    L2463
            dec     c
            ret
L2B7D:      ld      d,(ix+$06)
            ld      e,(ix+$04)
            ld      h,(iy+$06)
            ld      l,(iy+$04)
            ret
            nop
L2B8B:      ld      d,$00
            ld      ix,P1_Actor_Record
            bit     4,(ix+$00)
            jr      z,L2B99
            set     0,d
L2B99:      ld      ix,P2_Actor_Record
            bit     4,(ix+$00)
            jr      z,L2BA5
            set     1,d
L2BA5:      ld      a,(LD1EB)
            and     a
            jr      z,L2BAD
            ld      d,$03
L2BAD:      ld      a,$06
L2BAF:      push    af
            call    Select_Enemy_Record_IX
            ld      a,(ix+$00)
            and     $88
            cp      $80
            jr      nz,L2BF7
            res     5,(ix+$00)
            ld      a,(ix+$04)
            cp      $78
            ld      a,$01
            jr      c,L2BCB
            ld      a,$02
L2BCB:      and     d
            jr      nz,L2BE5
            ld      a,(ix+$08)
            and     $0C
            cp      $04
            jr      z,L2BE5
            ld      a,(ix+$02)
            cp      $40
            jr      nz,L2BF7
            ld      a,(Dungeon_Number)
            cp      $05
            jr      nc,L2BF7
L2BE5:      set     5,(ix+$00)
            bit     1,(ix+$00)
            jr      z,L2BF3
            ld      (ix+$1f),$E0
L2BF3:      res     1,(ix+$00)
L2BF7:      pop     af
            dec     a
            jr      nz,L2BAF
            ret
            nop
L2BFD:      ld      hl,LD340
            ld      a,(hl)
            and     a
            ret     z
            dec     (hl)
            ld      a,(LD349)
            and     a
            ret     nz
            ld      iy,$1052
            inc     a
L2C0E:      ld      (LD050),a
            ld      (LD053),a
            ret
L2C15:      ld      a,(Game_Mode)
            and     a
            ret     z
            ld      a,(LD1DB)
            and     a
            ret     z
            in      a, (COINPORT)
            and     $28
            jp      z,L2D12
            ld      a,$06
L2C28:      push    af
            call    Select_Enemy_Record_IX
            pop     af
            bit     7,(ix+$00)
            ret     nz
            dec     a
            jr      nz,L2C28
            ld      a,(LD1BB)
            and     a
            ret     nz
            ld      hl,LD1EB
            ld      a,(hl)
            and     a
            jr      nz,L2C78
            ld      a,(Dungeon_Number)
            dec     a
            jp      z,L2CF9
            call    L2CF0
            ld      (hl),a
            call    L3125
            ld      a,(L6C68)
            ld      (LD1F1),a
            ld      a,(L6CA4)
            ld      (LD1F2),a
            ld      a,$03
            ld      (LD047),a
            ld      hl,Sound_Request_3
            set     7,(hl)
            ld      iy,$121D
            ld      a,$20
            ld      (LD04D),a
            ld      hl,LD1E8
            inc     (hl)
            ld      de,$010C
            jp      L26EB
L2C78:      ld      a,(P1_Actor_Record)
            ld      hl,P2_Actor_Record
            or      (hl)
            bit     3,a
            ret     nz
            ld      a,(LD1DF)
            and     a
            jr      nz,L2CF9
            ld      hl,LD1C7
            ld      a,(hl)
            and     a
            ret     nz
            dec     hl
            ld      a,(hl)
            and     a
            jr      nz,L2CF9
            ld      a,(Dungeon_Number)
            cp      $07
            jr      c,L2CA3
            call    Random_Byte
            and     $03
            jr      z,L2CF9
            jr      L2CD6
L2CA3:      ld      d,$FF
            ld      a,(P1_Lives)
            ld      b,a
            ld      a,(P2_Lives)
            ld      c,a
            ld      a,(Game_Mode)
            dec     a
            jr      nz,L2CB7
            ld      b,$00
            sla     c
L2CB7:      ld      a,c
            add     a,b
            rrca
            rrca
            and     $3F
            jr      z,L2CC4
L2CBF:      srl     d
            dec     a
            jr      nz,L2CBF
L2CC4:      ld      a,(Dungeon_Number)
            cp      $03
            jr      c,L2CF9
L2CCB:      srl     d
            dec     a
            jr      nz,L2CCB
            call    Random_Byte
            and     d
            jr      nz,L2CF9
L2CD6:      ld      a,$03
            ld      (LD04E),a
            ld      (LD04F),a
            ld      (hl),a
            inc     hl
            ld      (hl),a
            ld      (LD1D8),a
            ld      (LD1C9),a
            ld      (LD048),a
            ld      hl,$0403
            ld      (LD1F3),hl
L2CF0:      ld      a,$0A
            in      a, (CCMISC)
            ld      a,$52
            out     (COL3L),a
            ret
L2CF9:      ld      a,$01
            ld      (LD1DF),a
            ld      hl,LD067
            ld      a,(LD087)
            or      (hl)
            and     $80
            ret     nz
            ld      hl,P1_Actor_Record
            ld      a,(P2_Actor_Record)
            or      (hl)
            and     $08
            ret     nz
L2D12:      ld      (LD1DB),a
            inc     a
            ld      (LD048),a
            ld      a,(Dungeon_Number)
            sub     $07
            jr      c,L2D42
L2D20:      sub     $06
            jr      nc,L2D20
            add     a,$06
            cp      $05
            jr      nz,L2D3D
            ld      a,$02
            ld      (LD350),a
            ld      hl,LD354
            ld      bc,L1700
L2D35:      ld      (hl),c
            inc     hl
            djnz    L2D35
            ld      a,$01
            jr      L2D67
L2D3D:      ld      a,$01
            ld      (LD350),a

;
;*****************************************************************************
; Called this routine from dispatch routine
; ???
;*****************************************************************************
;
L2D42:      ld      a,(Dungeon_Number)
            cp      $07
            ld      de,L000D
            jr      c,L2D4F
            ld      d,e
            ld      e,$09
L2D4F:      call    Random_Byte
            and     $0F
            cp      e
            jr      nc,L2D4F
            add     a,d
            ld      hl,LD354
            ld      c,a
            ld      b,$00
            add     hl,bc
            ld      a,(hl)
            and     a
            jr      nz,L2D4F
            inc     (hl)
            ld      a,c
            inc     a
            inc     a
L2D67:      ld      (Maze_Index),a
            ret
;
L2D6B:      ld      a,(Game_Mode)
            and     a
            ret     z
            ld      a,(LD1D7)
            and     a
            ret     z
            ld      a,(P1_Actor_Record)
            ld      hl,P2_Actor_Record
            or      (hl)
            ret     m
            ld      hl,P1_Lives
            ld      a,(hl)
            inc     hl
            or      (hl)
            ret     nz
            call    L1939
            xor     a
            ld      (Game_Mode),a
            ld      (LD1D7),a
            ld      (LD1DB),a
            inc     a
            ld      (LD048),a
            ld      (LD1D9),a
            ret
            nop
L2D9A:      ld      a,(LD1DB)
            and     a
            ret     z
            ld      a,(ix+$00)
            ld      b,a
            and     $8C
            cp      $80
            ret     nz
            bit     7,(ix+$08)
            ret     nz
            bit     4,b
            jp      nz,L30DD
            ld      a,(ix+$1c)
            and     a
            jr      z,L2DBB
            dec     (ix+$1c)
L2DBB:      ld      a,(ix+$01)
            and     $0F
            ld      (ix+$01),a
            call    L2E4F
            ld      a,(ix+$01)
            and     $F0
            ret     nz
            call    L2E4F
            bit     2,(ix+$07)
            ret     nz
            ld      a,(ix+$01)
            ld      b,a
            and     $F0
            ret     nz
            ld      a,b
            and     $0F
            jp      po,L2DF6
            bit     5,(ix+$00)
            ret     z
            res     5,(ix+$00)
            ld      a,(ix+$07)
            inc     c
            exx
            jp      L2FE2
L2DF2:      ld      bc,$0402
            ex      af,af'
L2DF6:      call    L30D6
            cp      $04
            jr      c,L2E14
            ld      a,d
            add     a,$18
L2E00:      sub     $18
            jr      z,L2E34
            jr      nc,L2E00
            cp      $F4
            ld      c,$01
            jr      c,L2E2D
            ld      c,$02
            ld      a,d
            add     a,$0C
            ld      d,a
            jr      L2E2D
L2E14:      ld      a,e
            add     a,$18
            jr      nc,L2E1B
            ld      a,$FF
L2E1B:      sub     $18
            jr      z,L2E34
            jr      nc,L2E1B
            cp      $F4
            ld      c,$04
            jr      c,L2E2D
            ld      c,$08
            ld      a,e
            add     a,$0C
            ld      e,a
L2E2D:      call    Maze_Cell_Address_From_XY
            ld      a,b
            and     (hl)
            jr      nz,L2E41
L2E34:      ld      a,(ix+$07)
            and     $03
            ld      c,a
            ld      b,$00
            ld      hl,L2DF2
            add     hl,bc
            ld      c,(hl)
L2E41:      call    L2E4C
            ld      a,(ix+$01)
            and     $F0
            ret     nz
            jr      L2E4F
L2E4C:      ld      (ix+$01),c
L2E4F:      ld      c,$00
            exx
            call    L30D6
            ld      a,(ix+$01)
            ld      b,a
            and     $0F
            ret     z
            ld      c,a
            ld      (ix+$01),a
            ld      a,b
            rrca
            rrca
            rrca
            rrca
            and     $0F
            ld      b,a
            and     c
            jr      z,L2E75
            ld      a,b
            xor     c
            jr      z,L2E75
            cp      $03
            jr      c,L2E7B
            jr      L2EA7
L2E75:      bit     0,(ix+$00)
            jr      z,L2EA7
L2E7B:      res     0,(ix+$00)
            ld      a,e
            call    L2445
            ret     nz
            bit     1,c
            jr      z,L2E94
            call    Maze_Cell_Address_From_XY
            bit     1,(hl)
            ret     z
            ld      b,$01
            set     5,c
            jr      L2ED5
L2E94:      bit     0,c
            ret     z
            ld      a,$17
            add     a,d
            ld      d,a
            call    Maze_Cell_Address_From_XY
            bit     0,(hl)
            ret     z
            ld      b,$00
            set     4,c
            jr      L2ED5
L2EA7:      set     0,(ix+$00)
            ld      a,d
            call    L2445
            ret     nz
            bit     3,c
            jr      z,L2EC0
            call    Maze_Cell_Address_From_XY
            bit     3,(hl)
            ret     z
            ld      b,$03
            set     7,c
            jr      L2ED5
L2EC0:      bit     2,c
            ret     z
            ld      a,$17
            add     a,e
            jr      nc,L2ECA
            ld      a,$FF
L2ECA:      ld      e,a
            call    Maze_Cell_Address_From_XY
            bit     2,(hl)
            ret     z
            ld      b,$02
            set     6,c
L2ED5:      ld      (ix+$01),c
            ld      a,c
            and     $50
            ld      a,(ix+$02)
            jr      z,L2EE2
            neg
L2EE2:      and     a
            jr      nz,L2EE9
            exx
            set     0,c
            exx
L2EE9:      ld      l,a
            rla
            ld      h,$00
            jr      nc,L2EF0
            dec     h
L2EF0:      add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl
            ld      a,c
            cp      $40
            jr      c,L2F58
            ld      e,(ix+$03)
            ld      d,(ix+$04)
            add     hl,de
            ld      (ix+$03),l
            ld      (ix+$04),h
            ld      a,h
            cp      $F1
            jr      c,L2F65
            ld      a,h
L2F0C:      cp      $F8
            ld      h,$00
            jr      c,L2F14
            ld      h,$F0
L2F14:      ld      (ix+$04),h
            ld      a,(LD1EB)
            and     a
L2F1B:      jr      z,L2F42
            ld      a,(LD1C6)
            and     a
            jr      nz,L2F42
            bit     2,(ix+$07)
            jr      z,L2F65
            xor     a
            ld      (ix+$00),a
            ld      a,$F3
            out     (COL3L),a
            ld      (LD1BA),a
            ld      (LD1D8),a
            ld      hl,Sound_Request_3
            set     5,(hl)
            call    Enable_Sparkle_Colors
            jp      L30BA
L2F42:      ld      a,$0A
            ld      (LD047),a
            exx
            ld      hl,LD1E5
            set     0,(hl)
            call    L3125
            ld      hl,Sound_Request_3
            set     4,(hl)
            exx
            jr      L2F65
L2F58:      ld      e,(ix+$05)
            ld      d,(ix+$06)
            add     hl,de
            ld      (ix+$05),l
            ld      (ix+$06),h
L2F65:      ld      a,h
            cp      d
            ld      c,$FF
            jr      z,L2F70
            inc     c
            exx
            set     0,c
            exx
L2F70:      bit     2,(ix+$07)
            jr      z,L2F82
            ld      hl,LD1E8
            ld      a,(hl)
            dec     a
            jr      nz,L2F82
            inc     (hl)
            exx
            set     0,c
            exx
L2F82:      ld      a,(ix+$02)
            and     a
            jr      z,L2F89
            inc     c
L2F89:      ld      d,(ix+$07)
            ld      a,d
            and     $03
            xor     b
L2F90:      cp      $01
            jr      nz,L2FA2
            bit     2,d
            jr      z,L2F9E
            ld      a,(LD1E8)
            and     a
L2F9C:      jr      nz,L2FA2
L2F9E:      exx
            set     0,c
            exx
L2FA2:      ld      a,(ix+$08)
            and     $0C
            bit     2,d
            jr      z,L2FC8
            ld      hl,L30BF
            sub     $04
            jr      z,L2FD7
            inc     hl
            sub     $04
            jr      z,L2FD7
            inc     hl
            ld      a,(LD1EB)
            and     a
            jr      z,L2FD7
L2FBE:      inc     hl
            ld      a,(LD1C6)
            and     a
            jr      z,L2FD7
            inc     hl
            jr      L2FD7
L2FC8:      ld      hl,L30C4
            sub     $04
            jr      nz,L2FD7
            inc     hl
            ld      a,(Game_Mode)
            dec     a
            jr      nz,L2FD7
            inc     hl
L2FD7:      ld      a,d
            dec     c
            jr      nz,L2FDC
            add     a,(hl)
L2FDC:      and     $FC
            or      b
            ld      (ix+$07),a
L2FE2:      ld      de,L0008
            bit     2,a
            ld      hl,L385C
            jr      z,L2FEF
            ld      hl,$3F4C
L2FEF:      bit     1,(ix+$08)
            jr      z,L2FF6
            add     hl,de
L2FF6:      bit     1,a
            ld      bc,$0550
            jr      z,L3002
            add     hl,de
            add     hl,de
            ld      bc,L0005
L3002:      bit     0,a
            jr      nz,L3009
            ld      bc,$0000
L3009:      ld      e,a
            bit     1,a
L300C:      jr      nz,L301A
            ld      a,(LD1DA)
            and     a
            jr      z,L3026
            ld      a,c
            add     a,$05
            ld      c,a
            jr      L3026
L301A:      in      a, (COINPORT)
            bit     7,a
            jr      nz,L3026
            ld      b,$05
            ld      a,c
            add     a,$50
            ld      c,a
L3026:      ld      a,e
            push    bc
            rlca
            rlca
            bit     1,(ix+$08)
            jr      z,L3033
L3030:      ld      a,(ix+$1a)
L3033:      and     $03
            ld      e,a
            add     hl,de
            add     hl,de
            ld      e,$20
            ld      a,(ix+$08)
            and     $0C
            sub     $04
            jr      z,L3057
            add     hl,de
            sub     $04
            jr      z,L3057
            add     hl,de
            ld      a,(LD1EB)
            and     a
            jr      z,L3057
            add     hl,de
            ld      a,(LD1C6)
            and     a
            jr      z,L3057
            add     hl,de
L3057:      ld      c,(hl)
            inc     hl
            ld      b,(hl)
            call    L30C7
            ex      (sp),hl
            bit     2,l
            jr      nz,L3063
            inc     e
L3063:      inc     e
            inc     d
            inc     d
            inc     d
            ld      a,e
            and     $03
            or      $20
            bit     4,l
            jr      z,L3072
            or      $80
L3072:      bit     2,l
            jr      z,L3078
            xor     $43
L3078:      ex      (sp),hl
            ld      (hl),a
            inc     hl
            ld      (hl),c
            inc     hl
            ld      (hl),b
            call    XY_To_Video_Address
            ex      de,hl
            pop     bc
            add     hl,bc
            ex      de,hl
            inc     hl
            ld      (hl),e
            inc     hl
            ld      (hl),d
            bit     1,(ix+$00)
            ret     nz
            exx
            bit     0,c
            ret     z
            bit     1,(ix+$08)
            jr      z,L30B6
            set     5,(ix+$00)
            dec     (ix+$1b)
            ret     nz
            ld      a,$01
            bit     2,(ix+$07)
            jr      z,L30AA
            ld      a,$02
L30AA:      ld      (ix+$1b),a
            dec     (ix+$1a)
            jr      nz,L30B6
            res     1,(ix+$08)
L30B6:      set     5,(ix+$08)
L30BA:      set     7,(ix+$08)
            ret
L30BF:      jr      nz,L30E1
            jr      nz,L30D3
            jr      nz,L30E5
            jr      nz,L30E7
L30C7:      push    ix
            pop     hl
            ld      de,L0008
            add     hl,de
            bit     4,(hl)
            ld      e,$05
            jr      nz,L30D5
            add     hl,de
L30D5:      inc     hl
L30D6:      ld      e,(ix+$04)
            ld      d,(ix+$06)
            ret
L30DD:      ld      c,$01
            exx
            ld      a,(ix+$06)
            cp      $79
L30E5:      jr      c,L30F5
L30E7:      ld      a,(ix+$06)
            sub     $08
            ld      (ix+$06),a
            ld      a,(ix+$07)
            jp      L2FE2
L30F5:      res     4,(ix+$00)
            ld      b,(ix+$04)
            call    L1F1F
            ld      bc,P1_Lives
            call    Select_P1_Life_Icon
            bit     2,(ix+$08)
            jr      nz,L310F
            call    Select_P2_Life_Icon
            inc     bc
L310F:      ld      a,(bc)
            dec     a
            ret     z
            cp      $07
            jr      nc,L3122
            push    hl
            ld      de,L0005
L311A:      add     hl,de
            dec     a
            jr      nz,L311A
            call    Draw_Actor_Record
            pop     hl
L3122:      jp      Draw_Actor_Record
L3125:      ld      hl,LD18E
            res     2,(hl)
            ld      hl,LD198
            res     3,(hl)
            ret

;
; Strings here. Definatly starting at $3132 to $3335 or so...
;
;*****************************************************************************
; ATTRACT, INSTRUCTION, AND STATUS TEXT
;
; Length-prefixed text records use @ as the on-screen space glyph.  Fixed-size
; names and score strings follow the prefixed records.
;*****************************************************************************
Attract_Text_Pool:
            DB      $00                  ; Leading pad/terminator
Text_Insert_Coin:
            DB      $0B,"INSERT"
Text_Coin_Prompt_Suffix:
            DB      "@COIN"
Text_High_Scores:
            DB      $0B,"HIGH@SCORES"
Text_Press_One_Player:
            DB      $17,"PRESS@ONE@PLAYER@BUTTON"
Text_Press_Two_Player:
            DB      $17,"PRESS@TWO@PLAYER@BUTTON"
Text_Or:
            DB      $02,"OR"
Text_Deposit_Additional_Coin:
            DB      $17,"DEPOSIT@ADDITIONAL@COIN"
Text_For_Two_Player_Game:
            DB      $13,"FOR@TWO@PLAYER@GAME"
Text_Points:
            DB      $06,"POINTS"
Text_Bonus_Player:
            DB      $0C,"BONUS@PLAYER"
Text_Wait_For_Instructions:
            DB      $15,"WAIT@FOR@INSTRUCTIONS"
Text_Invisible_Monsters:
            DB      $1E,"INVISIBLE@MONSTERS@IN@THE@MAZE"
Text_Radar_Location:
            DB      $22,"ARE@LOCATED@USING"
Text_Radar_Location_Byte_18:
            DB      "@THE@RADAR@SCREEN"
Text_Monsters_Become_Visible:
            DB      $25,"MONSTERS"
Text_Monsters_Visible_Byte_09:
            DB      "@BECOME@VISIBLE@WHEN@ENTERI"
Text_Monsters_Visible_Byte_36:
            DB      "NG"
Text_Same_Maze_Corridor:
            DB      $24,"THE@SAME@MAZE@CORRIDOR@AS@THE@PLAYER"
Text_Get_Ready:
            DB      $0B,"@GET@READY@"
Text_Radar:
            DB      $05,"RADAR"
Text_Escaped:
            DB      $07,"ESCAPED"
Text_Credits:
            DB      $07,"CREDITS"
Text_Dungeon_Label:
            DB      $09,"DUNGEON@@"
Text_Worlord_Dungeon:
            DB      $0F,"WORLORD@DUNGEON"
Text_The_Arena:
            DB      $09,"THE@ARENA"
Text_The_Pit:
            DB      $07,"THE@PIT"
Text_Extra_Worriors:
            DB      $15,"OR@FOR@EXTRA@WORRIORS"
Text_Go:
            DB      "GO"
Text_Double_Score:
            DB      "DOUBLE@SCORE"
Text_Game_Over:
            DB      "GAME@OVER"
Text_Copyright:
            DB      "[@1980@MIDWAY@MFG@CO"
Text_Copyright_Glyphs:
            DB      $5C,$5D,$5E
Text_Dungeon:
            DB      "DUNGEON"
Text_Burwor:
            DB      "BURWOR"
Text_Garwor:
            DB      "GARWOR"
Text_Thorwor:
            DB      "THORWOR"
Text_Worluk:
            DB      "WORLUK"
Text_Wizard_Of:
            DB      "WIZARD@OF"
Text_Worriors_Suffix:
            DB      "@WORRIORS"
Text_Rights_Reserved:
            DB      "ALL@RIGHTS@RESERVED"
Text_Score_Values:
            DB      "10020050010002500",$00
; Actor animation and frame-pointer tables.
Actor_Frame_Pointer_Table_A:
            DW      $33CE,$3428,$3482,$34DC,$3536
Actor_Frame_Pointer_Table_B:
            DW      $3B12,$374D,$3B12,$374D,$3B12,$374D
            DW      $3B12,$374D,$3B12,$374D,$3801
Actor_Frame_Metadata:
            DB      $01,$38,$DC
            inc     (hl)
L336C:      ld      (hl),$35
            nop
L336F:      nop
L3370:      nop
            nop
            sbc     a,h
            jr      c,L3368
            ld      (hl),$9C
L3377:      jr      c,L336C
            ld      (hl),$9C
            jr      c,L3370
            ld      (hl),$9C
            jr      c,L3374
            ld      (hl),$9C
            jr      c,L3378
            ld      (hl),$A7
            scf
            and     a
            scf
            call    c,L3634
            dec     (hl)
            nop
            nop
            nop
            nop
            cp      b
            ld      a,(L35EA)
            cp      b
            ld      a,(L35EA)
            cp      b
            ld      a,(L35EA)
            cp      b
            ld      a,(L35EA)
            cp      b
            ld      a,(L35EA)
            sbc     a,c
            ld      (hl),$99
            ld      (hl),$DC
            inc     (hl)
            ld      (hl),$35
            nop
            nop
            nop
            nop
            or      $38
            sub     b
            dec     (hl)
            or      $38
            sub     b
            dec     (hl)
            or      $38
            sub     b
            dec     (hl)
            or      $38
            sub     b
            dec     (hl)
            or      $38
            sub     b
            dec     (hl)
            ld      b,h
            ld      (hl),$44
            ld      (hl),$DC
            inc     (hl)
            ld      (hl),$35
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            ret     nz
            inc     b
            nop
            nop
            ret     nz
            di
            nop
            nop
            nop
            ccf
            rst     38H
            inc     c
            nop
            nop
            rrca
            rst     38H
            call    m,$0000
            rrca
            rst     18H
            ld      a,a
            nop
            nop
            rst     38H
            ld      d,l
            ld      a,h
            nop
            nop
            DB      $fd,$55
            ld      a,h
            nop
            nop
            ccf
L3401:      push    af
            ld      a,h
            nop
            nop
            rrca
            ccf
            ret     p
            nop
            nop
            ld      c,h
            rrca
            pop     bc
            nop
            nop
            nop
            rrca
            ret     nz
            nop
            nop
            nop
            inc     bc
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            ld      bc,$0000
            nop
            nop
            nop
            ld      b,b
            nop
            nop
            nop
            nop
            ld      d,h
L3434:      nop
            nop
            nop
            nop
            inc     d
            inc     b
            nop
            nop
            nop
            dec     d
            ld      d,h
            nop
            ret     nz
            nop
            dec     e
            ld      d,h
            inc     d
            nop
            nop
            ld      e,a
            push    de
            ld      d,l
            nop
            nop
            ld      e,a
            rst     38H
            push    af
            nop
            pop     bc
            ld      a,a
            rst     38H
            call    p,$1500
            ld      a,a
            rst     38H
            call    nc,$1500
            rst     38H
            rst     38H
            call    nc,$0500
            rst     38H
            rst     38H
            push    af
            nop
            dec     b
            push    af
            DB      $fd,$f4
            nop
            nop
            ld      d,l
            ld      d,l
            ld      d,h
            nop
            dec     b
            inc     d
            inc     d
            ld      b,l
            ld      b,b
            inc     b
            nop
            nop
            ld      b,b
            ld      b,b
            ld      d,b
            nop
L347A:      nop
            ld      b,b
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            jr      nz,L3486
L3486:      nop
            add     a,b
            nop
            add     a,b
            nop
            add     a,b
            jr      nz,L3490
            nop
            ld      (bc),a
L3490:      nop
            ex      af,af'
L3492:      ld      (bc),a
            nop
            ex      af,af'
            nop
            ld      (bc),a
            adc     a,d
            adc     a,d
            ex      af,af'
            nop
            nop
            xor     a
            jp      m,L0088
            ld      (bc),a
            cp      a
            cp      $A0
            nop
            ld      (bc),a
            cp      a
            rst     38H
            and     b
            jr      nz,L34B5
            rst     38H
            rst     38H
            and     b
            nop
            ld      a,(bc)
            rst     38H
            rst     38H
            and     b
            nop
            ld      a,(bc)
L34B5:      rst     38H
            rst     38H
            and     b
            nop
            ld      a,(bc)
            cp      a
            rst     38H
            ret     pe
            nop
            jr      nz,L347A
            cp      a
            ret     po
            nop
            add     a,b
            and     b
            xor     a
            xor     b
            nop
            nop
            nop
            ld      hl,(L808A)
            nop
            nop
            jr      nz,L34D1
L34D1:      add     a,b
            nop
            nop
            add     a,b
            nop
            nop
            nop
            ld      (bc),a
            nop
            nop
            nop
            nop
            ex      af,af'
            djnz    L34E0
L34E0:      nop
            inc     de
            ld      (bc),a
            ld      (bc),a
            djnz    L34E6
L34E6:      nop
            add     a,h
            ret     nz
            jr      nc,L34EB
L34EB:      nop
            pop     bc
            inc     b
            nop
            nop
            ex      af,af'
            nop
            nop
            inc     c
            nop
            nop
            ld      b,b
            ld      b,$00
            nop
            ret     nz
            ld      c,$03
            inc     de
            nop
            inc     bc
            nop
            ld      c,b
L3502:      nop
            nop
            ld      (bc),a
            ld      bc,L2001
            nop
            ld      b,b
            inc     b
            djnz    L350E
            nop
L350E:      nop
            nop
            jr      nz,L3492
            nop
            jr      nc,L3538
            nop
            inc     c
            nop
            ld      bc,L2004
            call    nz,L2300
            ld      (bc),a
            inc     bc
            ld      bc,L0100
            jr      nz,L3555
            ld      sp,$0000
            jr      nc,L34AA
            ld      b,h
L352B:      nop
            nop
            inc     b
            ex      af,af'
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
L3538:      jr      nc,L355A
            nop
            nop
            jr      nz,L353E
L353E:      ld      b,b
            nop
            jr      nz,L3502
            djnz    L354C
            nop
            nop
            inc     b
            nop
            add     a,b
            ld      b,b
            nop
            ld      b,b
L354C:      nop
            jr      nz,L354F
L354F:      jr      nc,L3551
L3551:      djnz    L3583
            nop
            nop
L3555:      add     a,b
            ld      (bc),a
            nop
            djnz    L359A
L355A:      inc     b
            jr      nc,L3560
            nop
            inc     bc
            nop
L3560:      nop
            ld      (bc),a
            nop
            nop
            nop
            add     a,b
            nop
            nop
            jr      nc,L358A
            jr      nc,L356D
            nop
L356D:      ld      bc,$0002
            inc     c
            djnz    L3574
            nop
L3574:      add     a,c
            nop
            add     a,b
            ld      b,b
            inc     c
            nop
            inc     c
            nop
            ld      (bc),a
            djnz    L358F
            inc     bc
            nop
            nop
            inc     bc
L3583:      nop
            ex      af,af'
            nop
            nop
            ld      b,b
            ld      bc,$0000
            nop
            inc     bc
            nop
            nop
L358F:      nop
            nop
            nop
            dec     a
            ld      e,a
            nop
            nop
            nop
            dec     sp
            ld      d,a
            nop
L359A:      nop
            nop
            rst     38H
            ld      d,a
            nop
            nop
            nop
            push    de
            ld      e,a
            ret     p
            nop
            nop
            DB      $fd,$5d
            ld      (hl),b
            nop
            nop
            dec     c
            ld      d,l
            ld      d,b
            inc     sp
            nop
            dec     (hl)
            and     (hl)
            ld      d,b
            DB      $dd,$ff
            push    de
            and     (hl)
            ld      (hl),b
            sbc     a,c
            xor     d
            xor     d
            and     l
            ld      (hl),b
            DB      $dd,$fe
            xor     d
            sub     l
            ld      (hl),b
            inc     sp
            rrca
            push    de
            ld      e,l
            ld      (hl),b
            nop
            nop
            dec     (hl)
            ld      e,a
            ret     p
            nop
            nop
            dec     (hl)
            ld      d,a
            nop
            nop
            nop
            push    de
            ld      d,a
            nop
            nop
            inc     bc
            ld      d,a
            rst     10H
            nop
            nop
            dec     c
            ld      e,h
            push    de
            ret     nz
            nop
            ld      (iy-$0b),b
            ret     nz
            nop
            push    de
            ld      (hl),e
            ld      d,l
            ret     nz
L35EA:      nop
            nop
            call    pe,$0000
            nop
            inc     bc
            ld      d,a
            nop
            nop
            nop
            nop
            call    pe,$0000
            nop
            inc     bc
            ld      d,a
            nop
            nop
            ret     p
            nop
            call    pe,$0000
            ld      (hl),b
            nop
            call    pe,$0000
            ld      a,h
L3609:      inc     bc
            call    pe,$0000
            ld      d,a
            inc     bc
            xor     h
            nop
            nop
            ld      d,l
            jp      $3FAC
            nop
            push    af
            ld      a,l
            and     a
            scf
            ret     p
            dec     c
            ld      d,l
            and     l
            rst     30H
            or      b
            jp      $A555
            ld      d,a
            ret     nc
            ld      a,a
            ld      d,l
            xor     d
L3629:      ld      d,l
L362A:      ld      d,b
            ld      (hl),l
            ld      d,l
            ld      l,d
            ld      d,l
            ld      d,b
            ld      d,l
            ld      e,a
            ld      d,l
            ld      a,l
L3634:      ld      (hl),b
            ld      d,a
            DB      $fd,$5a
            ld      e,a
            ret     p
            call    m,L550D
            ld      e,h
            nop
            nop
            rrca
            DB      $fd,$7c
            nop
            nop
            nop
            nop
            inc     b
            nop
            ld      b,h
            nop
            nop
            inc     d
            nop
            ld      h,(hl)
            xor     d
            add     a,b
            inc     d
            add     a,b
            ld      b,h
            ld      a,(bc)
            add     a,b
            dec     d
            ld      d,b
            nop
            nop
            ld      bc,L4001
            nop
            nop
            add     a,b
            add     a,e
            nop
            nop
            inc     bc
            ld      d,d
            ld      bc,$0000
            nop
            nop
            ld      ($0000),a
            nop
            ld      de,L4004
            nop
            nop
            ld      c,(hl)
            ld      (bc),a
            nop
            nop
            inc     d
            jr      nz,L369E
            ret     nz
            nop
            ld      d,h
            ld      bc,$0000
            ld      bc,L0050
            ld      bc,L0150
            ld      b,b
            nop
            dec     b
            ld      d,b
            dec     d
            ld      b,b
            nop
            dec     b
            djnz    L3690
L3690:      nop
            nop
            nop
            djnz    L3695
L3695:      nop
            nop
            nop
            nop
            nop
            nop
            nop
            dec     b
            ld      b,b
L369E:      inc     b
            nop
            nop
            ld      (bc),a
            nop
            inc     b
            nop
            nop
            dec     b
            ld      b,b
            dec     b
            ld      b,b
            nop
            ld      (bc),a
            nop
            dec     b
            ld      d,b
            nop
            ld      (bc),a
            nop
            nop
            ld      d,h
            nop
            ld      (bc),a
            nop
            nop
            inc     d
            nop
            ld      a,(bc)
            nop
            nop
            nop
            inc     c
            ld      a,(bc)
            nop
            nop
            ld      bc,L0A06
            nop
            nop
            ex      af,af'
            ld      b,h
            djnz    L36CB
L36CB:      nop
            inc     bc
            nop
            nop
            nop
            nop
            ld      (de),a
            ld      c,b
            ld      b,b
            nop
            nop
            nop
            ld      (bc),a
            nop
            nop
            nop
            ex      af,af'
            jr      nc,L36E3
            ld      b,b
            dec     b
            inc     b
            ld      b,b
            dec     d
L36E3:      ld      d,b
            dec     b
            ld      b,d
            daa
            ld      d,h
            nop
            ld      bc,L404C
            ld      d,(hl)
            nop
            dec     d
            ld      b,b
            nop
            inc     d
            nop
            nop
            nop
            ld      a,$AF
            nop
            nop
            nop
            scf
            xor     e
            nop
            nop
            nop
            rst     38H
            xor     e
            nop
            nop
            nop
            jp      pe,LF0AF
            nop
            nop
L3709:      cp      $AE
            or      b
            nop
            nop
            ld      c,$AA
            and     b
            inc     sp
            nop
            ld      a,($A059)
            xor     $FF
            jp      pe,LB059
            ld      h,(hl)
            ld      d,l
            ld      d,l
            ld      e,d
            or      b
            xor     $FD
            ld      d,l
            ld      l,d
            or      b
            inc     sp
            rrca
            jp      pe,LB0AE
            nop
            nop
            ld      a,(LF0AF)
            nop
            nop
            ld      a,(L00AB)
            nop
            nop
L3736:      jp      pe,L00AB
            nop
            inc     bc
            xor     e
            ex      de,hl
            nop
            nop
            ld      c,$AC
            jp      pe,L00C0
            cp      $B0
            jp      m,L00C0
            jp      pe,$AAB3
            ret     nz
            nop
            nop
            call    c,$0000
            nop
            inc     bc
            xor     e
            nop
            nop
            nop
            nop
            call    c,$0000
            nop
            inc     bc
            xor     e
            nop
            nop
            ret     p
            nop
            call    c,$0000
            or      b
            nop
            call    c,$0000
            cp      h
            inc     bc
            call    c,$0000
            xor     e
            inc     bc
            ld      e,h
            nop
            nop
            xor     d
            jp      $3F5C
            nop
            jp      m,L5BBE
            dec     sp
            ret     p
            ld      c,$AA
            ld      e,d
            ei
            ld      (hl),b
            jp      L5AAA
            xor     e
            ret     po
            cp      a
            xor     d
            ld      d,l
            xor     d
            and     b
            cp      d
            xor     d
            sub     l
            xor     d
            and     b
            xor     d
            xor     a
            xor     d
            cp      (hl)
            or      b
            xor     e
            cp      $A5
            xor     a
            ret     p
            call    m,$AA0E
            xor     h
            nop
Radar_Line_Pattern_A:
            DB      $00,$0F,$FE,$BC,$00,$00,$00,$00,$08,$00,$88,$00,$00,$28,$00,$99
Radar_Line_Pattern_B:
            DB      $55,$40,$28,$40,$88,$05,$40,$2A,$A0,$00,$00,$20,$0A,$A0,$00,$00
Radar_Line_Pattern_Extra:
            DB      $02,$02,$80,$00,$00,$40,$43,$00,$00,$03,$A1,$02,$00,$00,$00,$00
            DB      $31,$00,$00,$00,$22,$08,$80,$00,$00,$8D
Radar_Line_Pattern_C:
            DB      $01,$00,$00,$28,$10,$18,$C0,$00,$A8,$02,$00,$00,$02,$A0,$00,$02
Radar_Line_Pattern_D:
            DB      $A0,$02,$80,$00,$0A,$A0,$2A,$80,$00,$0A,$20,$00,$00,$00,$00,$20
Radar_Line_Pattern_Padding:
            DB      $00
L37FD:      nop
            nop
            nop
            nop
            nop
            nop
            nop
            ld      a,(bc)
            add     a,b
            ex      af,af'
            nop
            nop
            ld      bc,L0800
            nop
            nop
            ld      a,(bc)
            add     a,b
L3810:      ld      a,(bc)
            add     a,b
            nop
            ld      bc,L0A00
            and     b
            nop
            ld      bc,$0000
            xor     b
            nop
            ld      bc,$0000
            jr      z,L3822
L3822:      dec     b
            nop
            nop
            nop
            inc     c
            dec     b
            nop
            nop
            ld      (bc),a
            add     hl,bc
            dec     b
            nop
            nop
            inc     b
            adc     a,b
            jr      nz,L3833
L3833:      nop
            inc     bc
            nop
            nop
            nop
            nop
L3839:      ld      hl,L8084
            nop
            nop
            nop
            ld      bc,$0000
            nop
            inc     b
            jr      nc,L3850
            add     a,b
            ld      a,(bc)
            ex      af,af'
            add     a,b
            ld      hl,(L0AA0)
            add     a,c
            dec     de
            xor     b
L3850:      nop
            ld      (bc),a
            adc     a,h
            add     a,b
            xor     c
            nop
            ld      hl,(L0080)
            jr      z,L385B
L385B:      nop
L385C:      ld      (de),a
            dec     sp
            add     a,$3B
            ld      a,d
            inc     a
            add     a,$3B
            nop
            sbc     a,b
            ld      e,d
            sbc     a,b
            or      h
            sbc     a,b
            ld      c,$99
            sbc     a,h
            jr      c,L38BF
            add     hl,sp
            inc     b
            ld      a,(L3950)
            ld      l,b
            sbc     a,c
            jp      nz,L1C99
            sbc     a,d
            halt
            sbc     a,d
            cp      b
            ld      a,(L3B6C)
            jr      nz,L38BE
            ld      l,h
            dec     sp
            ret     nc
            sbc     a,d
            ld      hl,(L849B)
            sbc     a,e
            sbc     a,$9B
            or      $38
            xor     d
            add     hl,sp
            ld      e,(hl)
            ld      a,(L39AA)
            jr      c,L3832
            sub     d
            sbc     a,h
            call    pe,L469C
            sbc     a,l
;*******************************************************************************
; WORRIOR_BLUE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_1:
        .DB      $00,$00,$00,$54,$00 ; . . . . . . . . . . . . 1 1 1 . . . . .
        .DB      $00,$00,$03,$15,$00 ; . . . . . . . . . . . 3 . 1 1 1 . . . .
        .DB      $00,$00,$00,$15,$04 ; . . . . . . . . . . . . . 1 1 1 . . 1 .
        .DB      $00,$00,$05,$54,$00 ; . . . . . . . . . . 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$54,$50 ; . . . . . . . . . . . . 1 1 1 . 1 1 . .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$01,$7D,$D4 ; . . . . . . . . . . . 1 1 3 3 1 3 1 1 .
        .DB      $04,$40,$05,$7D,$D0 ; . . 1 . 1 . . . . . 1 1 1 3 3 1 3 1 . .
        .DB      $37,$7F,$FF,$FD,$D0 ; . 3 1 3 1 3 3 3 3 3 3 3 3 3 3 1 3 1 . .
        .DB      $04,$40,$FF,$F5,$50 ; . . 1 . 1 . . . 3 3 3 3 3 3 1 1 1 1 . .
        .DB      $00,$00,$05,$54,$50 ; . . . . . . . . . . 1 1 1 1 1 . 1 1 . .
        .DB      $00,$00,$00,$55,$00 ; . . . . . . . . . . . . 1 1 1 1 . . . .
        .DB      $00,$00,$01,$55,$00 ; . . . . . . . . . . . 1 1 1 1 1 . . . .
        .DB      $00,$00,$05,$55,$00 ; . . . . . . . . . . 1 1 1 1 1 1 . . . .
        .DB      $00,$00,$15,$05,$00 ; . . . . . . . . . 1 1 1 . . 1 1 . . . .
        .DB      $00,$00,$54,$05,$40 ; . . . . . . . . 1 1 1 . . . 1 1 1 . . .
        .DB      $00,$00,$50,$01,$40 ; . . . . . . . . 1 1 . . . . . 1 1 . . .
        .DB      $00,$05,$50,$15,$40 ; . . . . . . 1 1 1 1 . . . 1 1 1 1 . . .

; Legacy labels referenced elsewhere in the disassembly.
L389C                    EQU     WORRIOR_BLUE_1
L38BF                    EQU     WORRIOR_BLUE_1 + $23
L38E5                    EQU     WORRIOR_BLUE_1 + $49

;*******************************************************************************
; WORRIOR_YELLOW_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_1:
        .DB      $00,$00,$00,$A8,$00 ; . . . . . . . . . . . . 2 2 2 . . . . .
        .DB      $00,$00,$03,$2A,$00 ; . . . . . . . . . . . 3 . 2 2 2 . . . .
        .DB      $00,$00,$00,$2A,$08 ; . . . . . . . . . . . . . 2 2 2 . . 2 .
        .DB      $00,$00,$0A,$A8,$00 ; . . . . . . . . . . 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A8,$A0 ; . . . . . . . . . . . . 2 2 2 . 2 2 . .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$02,$BE,$E8 ; . . . . . . . . . . . 2 2 3 3 2 3 2 2 .
        .DB      $08,$80,$0A,$BE,$E0 ; . . 2 . 2 . . . . . 2 2 2 3 3 2 3 2 . .
        .DB      $3B,$BF,$FF,$FE,$E0 ; . 3 2 3 2 3 3 3 3 3 3 3 3 3 3 2 3 2 . .
        .DB      $08,$80,$FF,$FA,$A0 ; . . 2 . 2 . . . 3 3 3 3 3 3 2 2 2 2 . .
        .DB      $00,$00,$0A,$A8,$A0 ; . . . . . . . . . . 2 2 2 2 2 . 2 2 . .
        .DB      $00,$00,$00,$AA,$00 ; . . . . . . . . . . . . 2 2 2 2 . . . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $00,$00,$0A,$AA,$00 ; . . . . . . . . . . 2 2 2 2 2 2 . . . .
        .DB      $00,$00,$2A,$0A,$00 ; . . . . . . . . . 2 2 2 . . 2 2 . . . .
        .DB      $00,$00,$A8,$0A,$80 ; . . . . . . . . 2 2 2 . . . 2 2 2 . . .
        .DB      $00,$00,$A0,$02,$80 ; . . . . . . . . 2 2 . . . . . 2 2 . . .
        .DB      $00,$0A,$A0,$2A,$80 ; . . . . . . 2 2 2 2 . . . 2 2 2 2 . . .

;*******************************************************************************
; WORRIOR_BLUE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_2:
        .DB      $00,$00,$00,$54,$00 ; . . . . . . . . . . . . 1 1 1 . . . . .
        .DB      $00,$00,$03,$15,$00 ; . . . . . . . . . . . 3 . 1 1 1 . . . .
        .DB      $00,$00,$00,$15,$04 ; . . . . . . . . . . . . . 1 1 1 . . 1 .
        .DB      $00,$00,$05,$54,$00 ; . . . . . . . . . . 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$54,$50 ; . . . . . . . . . . . . 1 1 1 . 1 1 . .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$01,$7D,$D4 ; . . . . . . . . . . . 1 1 3 3 1 3 1 1 .
        .DB      $04,$40,$05,$7D,$D0 ; . . 1 . 1 . . . . . 1 1 1 3 3 1 3 1 . .
        .DB      $37,$7F,$FF,$FD,$D0 ; . 3 1 3 1 3 3 3 3 3 3 3 3 3 3 1 3 1 . .
        .DB      $04,$40,$FF,$F5,$50 ; . . 1 . 1 . . . 3 3 3 3 3 3 1 1 1 1 . .
        .DB      $00,$00,$05,$54,$50 ; . . . . . . . . . . 1 1 1 1 1 . 1 1 . .
        .DB      $00,$00,$01,$54,$00 ; . . . . . . . . . . . 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$05,$50,$00 ; . . . . . . . . . . 1 1 1 1 . . . . . .

; Legacy labels referenced elsewhere in the disassembly.
L38F6                    EQU     WORRIOR_YELLOW_1
L3903                    EQU     WORRIOR_YELLOW_1 + $0D
L391F                    EQU     WORRIOR_YELLOW_1 + $29

;*******************************************************************************
; WORRIOR_YELLOW_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_2:
        .DB      $00,$00,$00,$A8,$00 ; . . . . . . . . . . . . 2 2 2 . . . . .
        .DB      $00,$00,$03,$2A,$00 ; . . . . . . . . . . . 3 . 2 2 2 . . . .
        .DB      $00,$00,$00,$2A,$08 ; . . . . . . . . . . . . . 2 2 2 . . 2 .
        .DB      $00,$00,$0A,$A8,$00 ; . . . . . . . . . . 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A8,$A0 ; . . . . . . . . . . . . 2 2 2 . 2 2 . .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$02,$BE,$E8 ; . . . . . . . . . . . 2 2 3 3 2 3 2 2 .
        .DB      $08,$80,$0A,$BE,$E0 ; . . 2 . 2 . . . . . 2 2 2 3 3 2 3 2 . .
        .DB      $3B,$BF,$FF,$FE,$E0 ; . 3 2 3 2 3 3 3 3 3 3 3 3 3 3 2 3 2 . .
        .DB      $08,$80,$FF,$FA,$A0 ; . . 2 . 2 . . . 3 3 3 3 3 3 2 2 2 2 . .
        .DB      $00,$00,$0A,$A8,$A0 ; . . . . . . . . . . 2 2 2 2 2 . 2 2 . .
        .DB      $00,$00,$02,$A8,$00 ; . . . . . . . . . . . 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .
        .DB      $00,$00,$0A,$A0,$00 ; . . . . . . . . . . 2 2 2 2 . . . . . .

; Legacy labels referenced elsewhere in the disassembly.
L39AA                    EQU     WORRIOR_YELLOW_2

;*******************************************************************************
; WORRIOR_BLUE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_3:
        .DB      $00,$00,$00,$54,$00 ; . . . . . . . . . . . . 1 1 1 . . . . .
        .DB      $00,$00,$03,$15,$00 ; . . . . . . . . . . . 3 . 1 1 1 . . . .
        .DB      $00,$00,$00,$15,$04 ; . . . . . . . . . . . . . 1 1 1 . . 1 .
        .DB      $00,$00,$05,$54,$00 ; . . . . . . . . . . 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$54,$50 ; . . . . . . . . . . . . 1 1 1 . 1 1 . .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$01,$7D,$D4 ; . . . . . . . . . . . 1 1 3 3 1 3 1 1 .
        .DB      $04,$40,$05,$7D,$D0 ; . . 1 . 1 . . . . . 1 1 1 3 3 1 3 1 . .
        .DB      $37,$7F,$FF,$FD,$D0 ; . 3 1 3 1 3 3 3 3 3 3 3 3 3 3 1 3 1 . .
        .DB      $04,$40,$FF,$F5,$50 ; . . 1 . 1 . . . 3 3 3 3 3 3 1 1 1 1 . .
        .DB      $00,$00,$05,$54,$50 ; . . . . . . . . . . 1 1 1 1 1 . 1 1 . .
        .DB      $00,$00,$01,$54,$00 ; . . . . . . . . . . . 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$55,$00 ; . . . . . . . . . . . . 1 1 1 1 . . . .
        .DB      $00,$00,$00,$55,$40 ; . . . . . . . . . . . . 1 1 1 1 1 . . .
        .DB      $00,$00,$01,$45,$40 ; . . . . . . . . . . . 1 1 . 1 1 1 . . .
        .DB      $00,$00,$01,$41,$50 ; . . . . . . . . . . . 1 1 . . 1 1 1 . .
        .DB      $00,$00,$01,$40,$10 ; . . . . . . . . . . . 1 1 . . . . 1 . .
        .DB      $00,$00,$15,$41,$50 ; . . . . . . . . . 1 1 1 1 . . 1 1 1 . .

; Legacy labels referenced elsewhere in the disassembly.
L3A10                    EQU     WORRIOR_BLUE_3 + $0C
L3A38                    EQU     WORRIOR_BLUE_3 + $34

;*******************************************************************************
; WORRIOR_YELLOW_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_3:
        .DB      $00,$00,$00,$A8,$00 ; . . . . . . . . . . . . 2 2 2 . . . . .
        .DB      $00,$00,$03,$2A,$00 ; . . . . . . . . . . . 3 . 2 2 2 . . . .
        .DB      $00,$00,$00,$2A,$08 ; . . . . . . . . . . . . . 2 2 2 . . 2 .
        .DB      $00,$00,$0A,$A8,$00 ; . . . . . . . . . . 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A8,$A0 ; . . . . . . . . . . . . 2 2 2 . 2 2 . .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$02,$BE,$E8 ; . . . . . . . . . . . 2 2 3 3 2 3 2 2 .
        .DB      $08,$80,$0A,$BE,$E0 ; . . 2 . 2 . . . . . 2 2 2 3 3 2 3 2 . .
        .DB      $3B,$BF,$FF,$FE,$E0 ; . 3 2 3 2 3 3 3 3 3 3 3 3 3 3 2 3 2 . .
        .DB      $08,$80,$FF,$FA,$A0 ; . . 2 . 2 . . . 3 3 3 3 3 3 2 2 2 2 . .
        .DB      $00,$00,$0A,$A8,$A0 ; . . . . . . . . . . 2 2 2 2 2 . 2 2 . .
        .DB      $00,$00,$02,$A8,$00 ; . . . . . . . . . . . 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$AA,$00 ; . . . . . . . . . . . . 2 2 2 2 . . . .
        .DB      $00,$00,$00,$AA,$80 ; . . . . . . . . . . . . 2 2 2 2 2 . . .
        .DB      $00,$00,$02,$8A,$80 ; . . . . . . . . . . . 2 2 . 2 2 2 . . .
        .DB      $00,$00,$02,$82,$A0 ; . . . . . . . . . . . 2 2 . . 2 2 2 . .
        .DB      $00,$00,$02,$80,$20 ; . . . . . . . . . . . 2 2 . . . . 2 . .
        .DB      $00,$00,$2A,$82,$A0 ; . . . . . . . . . 2 2 2 2 . . 2 2 2 . .

;*******************************************************************************
; WORRIOR_YELLOW_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_1_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $20,$00,$0C,$00,$00 ; . 2 . . . . . . . . 3 . . . . . . . . .
        .DB      $20,$00,$0C,$00,$00 ; . 2 . . . . . . . . 3 . . . . . . . . .
        .DB      $2A,$00,$3C,$00,$00 ; . 2 2 2 . . . . . 3 3 . . . . . . . . .
        .DB      $2A,$80,$3C,$00,$00 ; . 2 2 2 2 . . . . 3 3 . . . . . . . . .
        .DB      $02,$A0,$BE,$02,$00 ; . . . 2 2 2 . . 2 3 3 2 . . . 2 . . . .
        .DB      $00,$AA,$BE,$82,$30 ; . . . . 2 2 2 2 2 3 3 2 2 . . 2 . 3 . .
        .DB      $00,$2A,$AA,$AA,$08 ; . . . . . 2 2 2 2 2 2 2 2 2 2 2 . . 2 .
        .DB      $20,$2A,$BF,$EA,$A8 ; . 2 . . . 2 2 2 2 3 3 3 3 2 2 2 2 2 2 .
        .DB      $22,$AA,$AF,$EA,$A8 ; . 2 . 2 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 .
        .DB      $2A,$A8,$2A,$A0,$A0 ; . 2 2 2 2 2 2 . . 2 2 2 2 2 . . 2 2 . .
        .DB      $2A,$00,$AF,$E8,$00 ; . 2 2 2 . . . . 2 2 3 3 3 2 2 . . . . .
        .DB      $00,$00,$AA,$A8,$00 ; . . . . . . . . 2 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A0,$80 ; . . . . . . . . . . . . 2 2 . . 2 . . .

; Legacy labels referenced elsewhere in the disassembly.
L3ADF                    EQU     WORRIOR_YELLOW_1_UP + $27
L3B0E                    EQU     WORRIOR_YELLOW_1_UP + $56

;*******************************************************************************
; WORRIOR_BLUE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_1_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $10,$00,$0C,$00,$00 ; . 1 . . . . . . . . 3 . . . . . . . . .
        .DB      $10,$00,$0C,$00,$00 ; . 1 . . . . . . . . 3 . . . . . . . . .
        .DB      $15,$00,$3C,$00,$00 ; . 1 1 1 . . . . . 3 3 . . . . . . . . .
        .DB      $15,$40,$3C,$00,$00 ; . 1 1 1 1 . . . . 3 3 . . . . . . . . .
        .DB      $01,$50,$7D,$01,$00 ; . . . 1 1 1 . . 1 3 3 1 . . . 1 . . . .
        .DB      $00,$55,$7D,$41,$30 ; . . . . 1 1 1 1 1 3 3 1 1 . . 1 . 3 . .
        .DB      $00,$15,$7D,$55,$04 ; . . . . . 1 1 1 1 3 3 1 1 1 1 1 . . 1 .
        .DB      $10,$15,$7F,$D5,$54 ; . 1 . . . 1 1 1 1 3 3 3 3 1 1 1 1 1 1 .
        .DB      $11,$55,$5F,$D5,$54 ; . 1 . 1 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 .
        .DB      $15,$54,$15,$50,$50 ; . 1 1 1 1 1 1 . . 1 1 1 1 1 . . 1 1 . .
        .DB      $15,$00,$5F,$D4,$00 ; . 1 1 1 . . . . 1 1 3 3 3 1 1 . . . . .
        .DB      $00,$00,$55,$54,$00 ; . . . . . . . . 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$50,$40 ; . . . . . . . . . . . . 1 1 . . 1 . . .

; Legacy labels referenced elsewhere in the disassembly.
L3B3E                    EQU     WORRIOR_BLUE_1_UP + $2C

;*******************************************************************************
; WORRIOR_YELLOW_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_2_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $20,$00,$BE,$02,$00 ; . 2 . . . . . . 2 3 3 2 . . . 2 . . . .
        .DB      $20,$02,$BE,$82,$30 ; . 2 . . . . . 2 2 3 3 2 2 . . 2 . 3 . .
        .DB      $2A,$AA,$BE,$AA,$08 ; . 2 2 2 2 2 2 2 2 3 3 2 2 2 2 2 . . 2 .
        .DB      $2A,$AA,$BF,$EA,$A8 ; . 2 2 2 2 2 2 2 2 3 3 3 3 2 2 2 2 2 2 .
        .DB      $00,$02,$AF,$EA,$A8 ; . . . . . . . 2 2 2 3 3 3 2 2 2 2 2 2 .
        .DB      $00,$00,$2A,$A0,$A0 ; . . . . . . . . . 2 2 2 2 2 . . 2 2 . .
        .DB      $00,$00,$AF,$E8,$00 ; . . . . . . . . 2 2 3 3 3 2 2 . . . . .
        .DB      $00,$00,$AA,$A8,$00 ; . . . . . . . . 2 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A0,$00 ; . . . . . . . . . . . . 2 2 . . . . . .

; Legacy labels referenced elsewhere in the disassembly.
L3B6C                    EQU     WORRIOR_YELLOW_2_UP
L3B73                    EQU     WORRIOR_YELLOW_2_UP + $07

;*******************************************************************************
; WORRIOR_BLUE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_2_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $10,$00,$7D,$01,$00 ; . 1 . . . . . . 1 3 3 1 . . . 1 . . . .
        .DB      $10,$01,$7D,$41,$30 ; . 1 . . . . . 1 1 3 3 1 1 . . 1 . 3 . .
        .DB      $15,$55,$7D,$55,$04 ; . 1 1 1 1 1 1 1 1 3 3 1 1 1 1 1 . . 1 .
        .DB      $15,$55,$7F,$D5,$54 ; . 1 1 1 1 1 1 1 1 3 3 3 3 1 1 1 1 1 1 .
        .DB      $00,$01,$5F,$D5,$54 ; . . . . . . . 1 1 1 3 3 3 1 1 1 1 1 1 .
        .DB      $00,$00,$15,$50,$50 ; . . . . . . . . . 1 1 1 1 1 . . 1 1 . .
        .DB      $00,$00,$5F,$D4,$00 ; . . . . . . . . 1 1 3 3 3 1 1 . . . . .
        .DB      $00,$00,$55,$54,$00 ; . . . . . . . . 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .

; Legacy labels referenced elsewhere in the disassembly.
L3C03                    EQU     WORRIOR_BLUE_2_UP + $3D
L3C18                    EQU     WORRIOR_BLUE_2_UP + $52
L3C1E                    EQU     WORRIOR_BLUE_2_UP + $58

;*******************************************************************************
; WORRIOR_YELLOW_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_3_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $20,$00,$3C,$00,$00 ; . 2 . . . . . . . 3 3 . . . . . . . . .
        .DB      $20,$00,$BE,$02,$00 ; . 2 . . . . . . 2 3 3 2 . . . 2 . . . .
        .DB      $2A,$82,$BE,$82,$30 ; . 2 2 2 2 . . 2 2 3 3 2 2 . . 2 . 3 . .
        .DB      $2A,$AA,$BE,$AA,$08 ; . 2 2 2 2 2 2 2 2 3 3 2 2 2 2 2 . . 2 .
        .DB      $00,$2A,$BF,$EA,$A8 ; . . . . . 2 2 2 2 3 3 3 3 2 2 2 2 2 2 .
        .DB      $00,$AA,$AF,$EA,$A8 ; . . . . 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 .
        .DB      $22,$A8,$2A,$A0,$A0 ; . 2 . 2 2 2 2 . . 2 2 2 2 2 . . 2 2 . .
        .DB      $22,$A0,$AF,$E8,$00 ; . 2 . 2 2 2 . . 2 2 3 3 3 2 2 . . . . .
        .DB      $2A,$00,$AA,$A8,$00 ; . 2 2 2 . . . . 2 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$00,$A0,$80 ; . . . . . . . . . . . . 2 2 . . 2 . . .

;*******************************************************************************
; WORRIOR_BLUE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_3_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .
        .DB      $10,$00,$3C,$00,$00 ; . 1 . . . . . . . 3 3 . . . . . . . . .
        .DB      $10,$00,$7D,$01,$00 ; . 1 . . . . . . 1 3 3 1 . . . 1 . . . .
        .DB      $15,$41,$7D,$41,$30 ; . 1 1 1 1 . . 1 1 3 3 1 1 . . 1 . 3 . .
        .DB      $15,$55,$7D,$55,$04 ; . 1 1 1 1 1 1 1 1 3 3 1 1 1 1 1 . . 1 .
        .DB      $00,$15,$7F,$D5,$54 ; . . . . . 1 1 1 1 3 3 3 3 1 1 1 1 1 1 .
        .DB      $00,$55,$5F,$D5,$54 ; . . . . 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 .
        .DB      $11,$54,$15,$50,$50 ; . 1 . 1 1 1 1 . . 1 1 1 1 1 . . 1 1 . .
        .DB      $11,$50,$5F,$D4,$00 ; . 1 . 1 1 1 . . 1 1 3 3 3 1 1 . . . . .
        .DB      $15,$00,$55,$54,$00 ; . 1 1 1 . . . . 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$00,$00,$50,$40 ; . . . . . . . . . . . . 1 1 . . 1 . . .

            nop
;*******************************************************************************
; GARWOR_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_3_UP:
        .DB      $00,$00,$03,$00,$00 ; . . . . . . . . . . . 3 . . . . . . . .
        .DB      $00,$00,$00,$CA,$00 ; . . . . . . . . . . . . 3 . 2 2 . . . .
        .DB      $00,$00,$02,$CA,$00 ; . . . . . . . . . . . 2 3 . 2 2 . . . .
        .DB      $00,$00,$0B,$EA,$80 ; . . . . . . . . . . 2 3 3 2 2 2 2 . . .
        .DB      $00,$00,$0A,$FA,$80 ; . . . . . . . . . . 2 2 3 3 2 2 2 . . .
        .DB      $00,$00,$0B,$EA,$A0 ; . . . . . . . . . . 2 3 3 2 2 2 2 2 . .
        .DB      $00,$02,$0A,$FA,$A8 ; . . . . . . . 2 . . 2 2 3 3 2 2 2 2 2 .
        .DB      $02,$02,$AB,$E9,$28 ; . . . 2 . . . 2 2 2 2 3 3 2 2 1 . 2 2 .
        .DB      $0A,$8A,$AA,$F8,$28 ; . . 2 2 2 . 2 2 2 2 2 2 3 3 2 . . 2 2 .
        .DB      $28,$AA,$AA,$AA,$A8 ; . 2 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$AA,$AA,$AA,$A8 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $22,$AA,$AA,$AA,$80 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $2A,$AA,$AA,$AA,$00 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$AA,$AA,$A0,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 . . . . . .
        .DB      $00,$2A,$AA,$00,$F0 ; . . . . . 2 2 2 2 2 2 2 . . . . 3 3 . .
        .DB      $00,$2A,$A0,$0A,$FC ; . . . . . 2 2 2 2 2 . . . . 2 2 3 3 3 .
        .DB      $00,$0A,$80,$08,$FC ; . . . . . . 2 2 2 . . . . . 2 . 3 3 3 .
        .DB      $00,$02,$AA,$A8,$0C ; . . . . . . . 2 2 2 2 2 2 2 2 . . . 3 .

;*******************************************************************************
; THORWOR_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_1:
        .DB      $00,$00,$00,$00,$F0 ; . . . . . . . . . . . . . . . . 3 3 . .
        .DB      $00,$0A,$00,$03,$C0 ; . . . . . . 2 2 . . . . . . . 3 3 . . .
        .DB      $00,$20,$C0,$0F,$C0 ; . . . . . 2 . . 3 . . . . . 3 3 3 . . .
        .DB      $00,$83,$F0,$0C,$00 ; . . . . 2 . . 3 3 3 . . . . 3 . . . . .
        .DB      $00,$0F,$FC,$0F,$00 ; . . . . . . 3 3 3 3 3 . . . 3 3 . . . .
        .DB      $00,$3C,$FF,$03,$00 ; . . . . . 3 3 . 3 3 3 3 . . . 3 . . . .
        .DB      $00,$F0,$FF,$03,$F0 ; . . . . 3 3 . . 3 3 3 3 . . . 3 3 3 . .
        .DB      $00,$F1,$FF,$C0,$30 ; . . . . 3 3 . 1 3 3 3 3 3 . . . . 3 . .
        .DB      $0F,$FF,$FF,$F0,$3C ; . . 3 3 3 3 3 3 3 3 3 3 3 3 . . . 3 3 .
        .DB      $3F,$FF,$FF,$FF,$FC ; . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $00,$FF,$FF,$FF,$F0 ; . . . . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $3C,$03,$FF,$FF,$F0 ; . 3 3 . . . . 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $3F,$FF,$FF,$FF,$C0 ; . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $00,$FF,$0C,$30,$C0 ; . . . . 3 3 3 3 . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$0C,$30,$C0 ; . . . . . . . . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$3C,$F3,$C0 ; . . . . . . . . . 3 3 . 3 3 . 3 3 . . .
        .DB      $00,$00,$30,$C3,$00 ; . . . . . . . . . 3 . . 3 . . 3 . . . .
        .DB      $00,$00,$51,$45,$00 ; . . . . . . . . 1 1 . 1 1 . 1 1 . . . .

;*******************************************************************************
; THORWOR_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_2:
        .DB      $00,$00,$00,$00,$F0 ; . . . . . . . . . . . . . . . . 3 3 . .
        .DB      $00,$0A,$00,$00,$C0 ; . . . . . . 2 2 . . . . . . . . 3 . . .
        .DB      $00,$20,$C0,$00,$C0 ; . . . . . 2 . . 3 . . . . . . . 3 . . .
        .DB      $00,$83,$F0,$00,$F0 ; . . . . 2 . . 3 3 3 . . . . . . 3 3 . .
        .DB      $00,$0F,$FC,$00,$30 ; . . . . . . 3 3 3 3 3 . . . . . . 3 . .
        .DB      $00,$3C,$FF,$00,$30 ; . . . . . 3 3 . 3 3 3 3 . . . . . 3 . .
        .DB      $00,$F0,$FF,$00,$30 ; . . . . 3 3 . . 3 3 3 3 . . . . . 3 . .
        .DB      $03,$F1,$FF,$C0,$3C ; . . . 3 3 3 . 1 3 3 3 3 3 . . . . 3 3 .
        .DB      $3F,$FF,$FF,$F0,$3C ; . 3 3 3 3 3 3 3 3 3 3 3 3 3 . . . 3 3 .
        .DB      $3C,$3F,$FF,$FF,$FC ; . 3 3 . . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $01,$0F,$FF,$FF,$F0 ; . . . 1 . . 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$03,$FF,$FF,$F0 ; . . . . . . . 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $31,$3F,$FF,$FF,$C0 ; . 3 . 1 . 3 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $3F,$FF,$CC,$30,$C0 ; . 3 3 3 3 3 3 3 3 . 3 . . 3 . . 3 . . .
        .DB      $03,$FC,$0C,$30,$C0 ; . . . 3 3 3 3 . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$0C,$30,$C0 ; . . . . . . . . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$0C,$30,$C0 ; . . . . . . . . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$14,$51,$40 ; . . . . . . . . . 1 1 . 1 1 . 1 1 . . .

;*******************************************************************************
; THORWOR_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_3:
        .DB      $00,$88,$03,$FC,$00 ; . . . . 2 . 2 . . . . 3 3 3 3 . . . . .
        .DB      $00,$02,$00,$0F,$C0 ; . . . . . . . 2 . . . . . . 3 3 3 . . .
        .DB      $00,$00,$C0,$00,$C0 ; . . . . . . . . 3 . . . . . . . 3 . . .
        .DB      $00,$03,$F0,$00,$C0 ; . . . . . . . 3 3 3 . . . . . . 3 . . .
        .DB      $00,$FF,$FC,$00,$C0 ; . . . . 3 3 3 3 3 3 3 . . . . . 3 . . .
        .DB      $00,$3C,$FF,$00,$F0 ; . . . . . 3 3 . 3 3 3 3 . . . . 3 3 . .
        .DB      $00,$F0,$FF,$00,$30 ; . . . . 3 3 . . 3 3 3 3 . . . . . 3 . .
        .DB      $0F,$F1,$FF,$C0,$3C ; . . 3 3 3 3 . 1 3 3 3 3 3 . . . . 3 3 .
        .DB      $3C,$3F,$FF,$F0,$3C ; . 3 3 . . 3 3 3 3 3 3 3 3 3 . . . 3 3 .
        .DB      $31,$0F,$FF,$FF,$FC ; . 3 . 1 . . 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $01,$03,$FF,$FF,$F0 ; . . . 1 . . . 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$03,$FF,$FF,$F0 ; . . . . . . . 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$0F,$FF,$FF,$C0 ; . . . . . . 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $31,$0F,$CC,$30,$C0 ; . 3 . 1 . . 3 3 3 . 3 . . 3 . . 3 . . .
        .DB      $3C,$3F,$0C,$30,$C0 ; . 3 3 . . 3 3 3 . . 3 . . 3 . . 3 . . .
        .DB      $0F,$FC,$0F,$3C,$F0 ; . . 3 3 3 3 3 . . . 3 3 . 3 3 . 3 3 . .
        .DB      $00,$00,$03,$0C,$30 ; . . . . . . . . . . . 3 . . 3 . . 3 . .
        .DB      $00,$00,$05,$14,$50 ; . . . . . . . . . . 1 1 . 1 1 . 1 1 . .

;*******************************************************************************
; THORWOR_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_1_UP:
        .DB      $00,$0F,$30,$00,$00 ; . . . . . . 3 3 . 3 . . . . . . . . . .
        .DB      $00,$0F,$3C,$00,$00 ; . . . . . . 3 3 . 3 3 . . . . . . . . .
        .DB      $00,$0C,$3C,$00,$00 ; . . . . . . 3 . . 3 3 . . . . . . . . .
        .DB      $00,$3C,$FF,$C2,$00 ; . . . . . 3 3 . 3 3 3 3 3 . . 2 . . . .
        .DB      $00,$3C,$FF,$F0,$80 ; . . . . . 3 3 . 3 3 3 3 3 3 . . 2 . . .
        .DB      $00,$3C,$FC,$3C,$20 ; . . . . . 3 3 . 3 3 3 . . 3 3 . . 2 . .
        .DB      $00,$3F,$FD,$0F,$20 ; . . . . . 3 3 3 3 3 3 1 . . 3 3 . 2 . .
        .DB      $10,$0F,$FF,$FF,$C0 ; . 1 . . . . 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $1F,$0F,$FF,$FF,$00 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 3 3 . . . .
        .DB      $03,$FF,$FF,$FC,$00 ; . . . 3 3 3 3 3 3 3 3 3 3 3 3 . . . . .
        .DB      $10,$0F,$FF,$F0,$00 ; . 1 . . . . 3 3 3 3 3 3 3 3 . . . . . .
        .DB      $1F,$0F,$FF,$00,$00 ; . 1 3 3 . . 3 3 3 3 3 3 . . . . . . . .
        .DB      $03,$FF,$FC,$00,$00 ; . . . 3 3 3 3 3 3 3 3 . . . . . . . . .
        .DB      $10,$0F,$F0,$0F,$C0 ; . 1 . . . . 3 3 3 3 . . . . 3 3 3 . . .
        .DB      $1F,$0F,$F0,$FC,$F0 ; . 1 3 3 . . 3 3 3 3 . . 3 3 3 . 3 3 . .
        .DB      $03,$FF,$F0,$C0,$FC ; . . . 3 3 3 3 3 3 3 . . 3 . . . 3 3 3 .
        .DB      $00,$03,$FF,$C0,$0C ; . . . . . . . 3 3 3 3 3 3 . . . . . 3 .
        .DB      $00,$00,$3C,$00,$00 ; . . . . . . . . . 3 3 . . . . . . . . .

;*******************************************************************************
; THORWOR_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_2_UP:
        .DB      $00,$3C,$3C,$00,$00 ; . . . . . 3 3 . . 3 3 . . . . . . . . .
        .DB      $00,$30,$3C,$00,$00 ; . . . . . 3 . . . 3 3 . . . . . . . . .
        .DB      $00,$F4,$4F,$00,$00 ; . . . . 3 3 1 . 1 . 3 3 . . . . . . . .
        .DB      $00,$F0,$0F,$C2,$00 ; . . . . 3 3 . . . . 3 3 3 . . 2 . . . .
        .DB      $00,$FC,$3F,$F0,$80 ; . . . . 3 3 3 . . 3 3 3 3 3 . . 2 . . .
        .DB      $00,$FC,$FC,$3C,$20 ; . . . . 3 3 3 . 3 3 3 . . 3 3 . . 2 . .
        .DB      $00,$3F,$FD,$0F,$20 ; . . . . . 3 3 3 3 3 3 1 . . 3 3 . 2 . .
        .DB      $00,$3F,$FF,$FF,$C0 ; . . . . . 3 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $10,$0F,$FF,$FF,$00 ; . 1 . . . . 3 3 3 3 3 3 3 3 3 3 . . . .
        .DB      $1F,$FF,$FF,$FC,$00 ; . 1 3 3 3 3 3 3 3 3 3 3 3 3 3 . . . . .
        .DB      $00,$0F,$FF,$F0,$00 ; . . . . . . 3 3 3 3 3 3 3 3 . . . . . .
        .DB      $00,$0F,$FF,$F0,$00 ; . . . . . . 3 3 3 3 3 3 3 3 . . . . . .
        .DB      $1F,$FF,$FC,$00,$00 ; . 1 3 3 3 3 3 3 3 3 3 . . . . . . . . .
        .DB      $00,$0F,$F0,$00,$00 ; . . . . . . 3 3 3 3 . . . . . . . . . .
        .DB      $10,$0F,$F0,$00,$00 ; . 1 . . . . 3 3 3 3 . . . . . . . . . .
        .DB      $1F,$FF,$F0,$03,$FC ; . 1 3 3 3 3 3 3 3 3 . . . . . 3 3 3 3 .
        .DB      $00,$03,$FF,$FF,$0C ; . . . . . . . 3 3 3 3 3 3 3 3 3 . . 3 .
        .DB      $00,$00,$3F,$00,$00 ; . . . . . . . . . 3 3 3 . . . . . . . .

;*******************************************************************************
; THORWOR_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_3_UP:
        .DB      $00,$F0,$3C,$00,$00 ; . . . . 3 3 . . . 3 3 . . . . . . . . .
        .DB      $03,$C0,$0F,$00,$00 ; . . . 3 3 . . . . . 3 3 . . . . . . . .
        .DB      $03,$10,$53,$00,$00 ; . . . 3 . 1 . . 1 1 . 3 . . . . . . . .
        .DB      $03,$00,$03,$C0,$08 ; . . . 3 . . . . . . . 3 3 . . . . . 2 .
        .DB      $03,$C0,$0F,$F0,$00 ; . . . 3 3 . . . . . 3 3 3 3 . . . . . .
        .DB      $03,$FC,$3C,$3C,$08 ; . . . 3 3 3 3 . . 3 3 . . 3 3 . . . 2 .
        .DB      $00,$FF,$FD,$0F,$20 ; . . . . 3 3 3 3 3 3 3 1 . . 3 3 . 2 . .
        .DB      $00,$3F,$FF,$FF,$C0 ; . . . . . 3 3 3 3 3 3 3 3 3 3 3 3 . . .
        .DB      $00,$0F,$FF,$FF,$00 ; . . . . . . 3 3 3 3 3 3 3 3 3 3 . . . .
        .DB      $13,$FF,$FF,$FC,$00 ; . 1 . 3 3 3 3 3 3 3 3 3 3 3 3 . . . . .
        .DB      $1F,$0F,$FF,$F0,$0C ; . 1 3 3 . . 3 3 3 3 3 3 3 3 . . . . 3 .
        .DB      $00,$0F,$FF,$00,$0C ; . . . . . . 3 3 3 3 3 3 . . . . . . 3 .
        .DB      $13,$FF,$FC,$00,$0C ; . 1 . 3 3 3 3 3 3 3 3 . . . . . . . 3 .
        .DB      $1F,$0F,$F0,$00,$3C ; . 1 3 3 . . 3 3 3 3 . . . . . . . 3 3 .
        .DB      $00,$0F,$F0,$00,$30 ; . . . . . . 3 3 3 3 . . . . . . . 3 . .
        .DB      $13,$FF,$F0,$3F,$F0 ; . 1 . 3 3 3 3 3 3 3 . . . 3 3 3 3 3 . .
        .DB      $1F,$03,$FF,$F0,$00 ; . 1 3 3 . . . 3 3 3 3 3 3 3 . . . . . .
        .DB      $00,$00,$3F,$00,$00 ; . . . . . . . . . 3 3 3 . . . . . . . .

            nop
            and     b
            sbc     a,l
            and     b
            sbc     a,l
            jp      m,L549D
            sbc     a,(hl)
            cp      h
            sbc     a,a
            ld      d,$A0
            ld      (hl),b
            and     b
            jp      z,$AEA0
            sbc     a,(hl)
            xor     (hl)
            sbc     a,(hl)
            ex      af,af'
            sbc     a,a
            ld      h,d
            sbc     a,a
            inc     h
            and     c
            ld      a,(hl)
            and     c
            ret     c
            and     c
            ld      (L0EA2),a
            sub     a
            ld      l,b
            sub     a
            ld      l,b
            sub     a
            push    de
            inc     a
            sub     h
            xor     c
            xor     $A9
            ld      c,b
            xor     d
            and     d
            xor     d
            nop
            sub     (hl)
            ld      e,d
            sub     (hl)
            ld      e,d
            sub     (hl)
            or      h
            sub     (hl)
            call    m,L56AA
            xor     e
            or      b
            xor     e
            ld      a,(bc)
            xor     h
            dec     a
            ld      a,$97
            ld      a,$F1
            ld      a,$97
            ld      a,$64
            xor     h
            cp      (hl)
            xor     h
            jr      $3F47
            ld      (hl),d
            xor     l
            cpl
            dec     a
            adc     a,c
            dec     a
            ex      (sp),hl
            dec     a
            adc     a,c
            dec     a
            call    z,L26AD
            xor     (hl)
            add     a,b
            xor     (hl)
            jp      c,L8CAE
            and     d
            adc     a,h
            and     d
            and     $A2
            ld      b,b
            and     e
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            sbc     a,d
            and     e
            sbc     a,d
            and     e
            call    p,L4EA3
            and     h
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            nop
            xor     b
            and     h
            ld      (bc),a
            and     l
            ld      e,h
            and     l
            or      (hl)
            and     l
            ld      a,b
            and     a
            jp      nc,L2CA7
            xor     b
            jp      nc,L10A7
            and     (hl)
            ld      l,d
            and     (hl)
            call    nz,L1EA6
            and     a
            add     a,(hl)
            xor     b
            ret     po
            xor     b
            ld      a,(LE0A9)
            xor     b
            nop
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
            rst     38H
;
;
;
            ORG     $8000

L8000:      jp      L84F2
L8003:      jp      L86C1
            jp      $8316               ; Entry point from startup code
L8009:      jp      L827D
            jp      L8253
L800F:      bit     7,a
            jp      p,L8018
            neg
            res     7,a
L8018:      ret
;
;*****************************************************************************************
; Purpose:    ???
;        Set up 8 music ports
;
; Input:    DE
;
; Output:    (DE+17)=1
;        (DE+3) to (DE+16) = 0 (14 bytes)
;        out (DE) <- (DE+3) to (DE+11) (8 bytes)
;        (DE-1) to (DE-42) = 0 (42 bytes)
;        Switch main registers
;
;*****************************************************************************************
;
L8019:      ld      hl,L0011
            add     hl,de
            ld      (hl),$01            ; (DE+17) = 1

            push    de
            ld      hl,$0000
            add     hl,de
            ld      c,(hl)              ; c=(DE)

            ld      b,$08
            push    bc

            ld      hl,L0003
            add     hl,de

            ld      bc,L000D
            push    hl
            push    hl
            pop     de

            ld      (hl),$00
            inc     de
            ldir                        ; (DE+3) to (DE+16) = 0 (14 bytes)


    ;Output 8 bytes to music ports
            pop     hl
            pop     bc
            otir                        ; out (DE) <- (DE+3) to (DE+11) (8 bytes)


            pop     hl
            dec     hl
            push    hl
            pop     de
            dec     de
            ld      bc,L0029
            ld      (hl),$00
            lddr                        ; (DE-1) to (DE-42) = 0 (42 bytes)


            exx                         ; Switch registers

            ret

;
;*****************************************************************************************
;



L8049:      push    iy
            pop     hl
            add     hl,de
            dec     (hl)
            jp      nz,L80E1
            inc     hl
            ld      a,(hl)
            dec     hl
            ld      (hl),a
            inc     hl
            inc     hl
            bit     0,(hl)
            ret     z
            ld      c,(hl)
            inc     hl
            bit     2,c
            jp      nz,L80CF
            bit     3,c
            jp      z,L80A5
            inc     hl
            inc     hl
            inc     hl
            xor     a
            cp      (hl)
            jp      z,L8089
            dec     (hl)
            jp      nz,L8089
            res     0,c
            ld      de,L0006
            or      a
            sbc     hl,de
            ld      (hl),$00
            bit     5,c
            jp      z,L8085
            ld      (iy+$11),$01
L8085:      inc     hl
            inc     hl
            ld      (hl),c
            ret
L8089:      dec     hl
L808A:      dec     hl
            dec     hl
            res     3,c
            bit     1,c
            jp      nz,L8099
            xor     a
            sub     (hl)
            ld      (hl),a
            jp      L80A5
L8099:      dec     hl
            ld      (hl),c
            bit     4,c
            inc     hl
            inc     hl
            jp      z,L80A3
            inc     hl
L80A3:      ld      b,(hl)
            ret
L80A5:      ld      a,b
            add     a,(hl)
            ld      b,a
            inc     hl
            cp      (hl)
            jp      nc,L80B4
            set     4,c
            set     3,c
            jp      L80C8
L80B4:      jp      nz,L80BE
            set     4,c
            set     3,c
            jp      L80C8
L80BE:      inc     hl
            cp      (hl)
            jp      c,L80C7
            res     4,c
            set     3,c
L80C7:      dec     hl
L80C8:      dec     hl
            dec     hl
            ld      (hl),c
            ret
            jp      L80DE
L80CF:      inc     hl
            push    hl
            ld      a,(hl)
            inc     hl
            sub     (hl)
            neg
            ld      e,a
            ld      d,$00
            ld      a,r
            pop     hl
            add     a,(hl)
            ld      b,a
L80DE:      jp      L80E4
L80E1:      inc     hl
            inc     hl
            ld      c,(hl)
L80E4:      ret
            nop
L80E6:      xor     a
            cp      (iy+$11)
            jp      nz,L81C5
            cp      (iy+$10)
            jp      nz,L81C5
            inc     (iy+$10)
            cp      (iy+$0d)
            jr      z,L8104
            dec     (iy+$0d)
            jr      nz,L8104
            ld      (iy+$11),$01
L8104:      cp      (iy-$2a)
            jr      z,L8116
L8109:      ld      b,(iy-$06)
            ld      de,LFFD6
            call    L8049
            ld      (iy-$06),b
            xor     a
L8116:      cp      (iy-$1c)
            jr      z,L8136
            ld      a,(iy-$04)
            call    L800F
            ld      b,a
            ld      de,LFFE4
            call    L8049
            ld      a,b
            ld      b,(iy-$04)
            bit     7,b
            jr      z,L8132
            neg
L8132:      ld      (iy-$04),a
            xor     a
L8136:      cp      (iy-$23)
            jr      z,L8148
            ld      b,(iy+$04)
            ld      de,LFFDD
            call    L8049
            ld      (iy+$04),b
            xor     a
L8148:      cp      (iy-$07)
            jr      z,L818B
            inc     a
            cp      (iy-$07)
            jr      nz,L817E
            ld      a,(iy+$0c)
            or      a
            jr      z,L817E
            ld      a,(iy-$06)
            rlca
            rlca
            rlca
            rlca
            and     $0F
            inc     a
            ld      (iy-$0d),a
            ld      a,(iy-$09)
            ld      e,a
            rrca
            rrca
            rrca
            rrca
            or      e
            ld      (iy+$05),a
            ld      (iy-$08),$01
            ld      (iy-$0e),$01
            ld      (iy-$0c),$03
L817E:      ld      b,(iy+$0b)
            ld      de,LFFF9
            call    L8049
            ld      (iy+$0b),b
            xor     a
L818B:      cp      (iy-$0e)
            jr      z,L81AF
            ld      a,(iy+$05)
            and     $0F
            ld      b,a
            ld      de,LFFF2
            call    L8049
            ld      a,b
            rrca
            rrca
            rrca
            rrca
            or      b
            ld      (iy+$05),a
            ld      a,(iy+$06)
            and     $F0
            or      b
            ld      (iy+$06),a
            xor     a
L81AF:      cp      (iy-$15)
            jr      z,L81C1
            ld      b,(iy+$07)
            ld      de,LFFEB
            call    L8049
            ld      (iy+$07),b
            xor     a
L81C1:      xor     a
            ld      (iy+$10),a
L81C5:      ld      c,(iy+$00)
            ld      a,$17
            cp      c
            jr      nc,L81D8
            push    iy
            pop     hl
            ld      de,$0004
            add     hl,de
            ld      b,$08
            otir
L81D8:      ret
;*****************************************************************************************
; ----> Play_Next_Phoneme
;
;       Checks if the Votrax SC-01A is ready, processes the next phoneme from the string,
;       updates the delta-encoded pitch/inflection bit, and sends it to the speech chip.
;*****************************************************************************************
Play_Next_Phoneme:
            in      a, (P1PORT)             ; Read Port $12 (Player 1 / Votrax Status)
            bit     7,a                     ; Check bit 7 (Votrax A/R pin: 1 = Ready)
            jr      z,Play1                 ; If 0 (Busy speaking), return immediately
            ld      hl,Num_Phonemes_Left    ; HL = Pointer to remaining phoneme count ($D2D0)
            dec     (hl)                    ; Decrement the phonemes remaining counter
            inc     hl                      ; Advance HL to point to $D2D1 (Inflection state)
            ld      a,(hl)                  ; Load the previous phoneme's inflection bit
            ld      hl,(LD2CE)              ; Load the ROM address of the current phoneme
            xor     (hl)                    ; XOR previous inflection with current ROM byte
            inc     hl                      ; Advance pointer to the next phoneme in ROM
            ld      (LD2CE),hl              ; Store the updated ROM pointer back in RAM
            ld      b,a                     ; B = The decoded phoneme + new inflection bit
            and     $80                     ; Isolate just the new inflection bit (Bit 7)
            ld      (LD2D1),a               ; Store the new inflection state in RAM
            ld      c,$17                   ; C = Speech Chip Port ($17)
            in      a,(c)                   ; HARDWARE TRICK: Sends B over address lines!
Play1:      ret                             ; Return to caller

;*****************************************************************************************
;
;
;*****************************************************************************************
L81F8:      ld      a,(Num_Phonemes_Left) ; Load A with length of phoneme left to go
            or      a                   ; if no more phonemes...
            jr      z,L8201             ; ... then skip the phoneme output routine
            jp      Play_Next_Phoneme   ; Otherwise, call speech phoneme output routine
L8201:      xor     a                   ; Zero A
            ld      hl,(LD2D2)          ; HL = ???
            ld      de,(LD2D4)          ; DE = ???
            sbc     hl,de               ; HL = HL - DE
            jr      z,L8234             ; If HL = 0, then skip to STOP phoneme
            ex      de,hl
            ld      e,(hl)
            inc     hl
L8210:      ld      d,(hl)
            ex      de,hl
            ld      a,(hl)
            ld      (Num_Phonemes_Left),a
            inc     hl
            ld      (LD2CE),hl
            ld      hl,(LD2D4)
            ld      de,$0002
            add     hl,de
            ex      de,hl
            ld      hl,LD2CC
            or      a
            sbc     hl,de
            jr      nc,L822D
            ld      de,LD2BE
L822D:      ld      (LD2D4),de
            jp      Play_Next_Phoneme
L8234:      xor     a
            ld      (Is_Speech_Active),a ; Mark speech inactive
            ld      bc,$3F17            ; Write a STOP phoneme... (end of string?)
            in      a,(c)               ;
            ret
;
;******************************************************************************
;
;******************************************************************************
;

L823E:      ld      hl,LD2BD
            or      a                   ; a = 0? or is it clear C flag?
                    ; It seems to serve no purpose ???
            sbc     hl,de
            jr      c,L8248             ; Jump if HL - DE is negative
            ld      a,$01
L8248:      ld      hl,LD2CC
            or      a                   ; a = 0? or is it clear C flag?
                    ; It seems to serve no purpose ???
            sbc     hl,de
            jr      nc,L8252            ; Jump if HL - DE is positive
            ld      a,$01
L8252:      ret

;
;******************************************************************************
;
;******************************************************************************
;

L8253:      exx
            ld      de,(LD2D2)
            xor     a
            call    L823E
            ld      de,(LD2D4)
            call    L823E
            or      a
            jr      z,L827B
            xor     a
            ld      (Is_Speech_Active),a ; Set speech to inactive
            ld      hl,LD2BE
            ld      (LD2D2),hl
            ld      (LD2D4),hl
            ld      (Num_Phonemes_Left),a ; Set number of phonemes left to zero
            ld      bc,$3F17            ; Write a STOP phoneme (stop speech)
            in      a,(c)
L827B:      exx
            ret

;
;******************************************************************************
;
;******************************************************************************
;

L827D:      cp      $50
            jr      nc,L82F4
            ld      hl,L9514
            inc     a
            ld      c,a
            ld      a,($D347)
            in      a, (SETTINGS)
            bit     3,a
            jr      nz,L8292
            ld      hl,(LC002)
L8292:      ld      a,$7F
L8294:      cp      (hl)
            jr      nc,L8298
            dec     c
L8298:      inc     hl
            jr      nz,L8294
            dec     hl
            ld      a,(hl)
            and     $7F
            jr      z,L82F4
            ld      c,a
            di
L82A3:      inc     hl
            ld      a,(LD350)
            or      a
            ld      a,(hl)
            jr      z,L82B7
            cp      $09
            jr      nz,L82B1
            ld      a,$40
L82B1:      cp      $37
            jr      nz,L82B7
            ld      a,$41
L82B7:      exx
            rlca
            ld      hl,L9476
            ld      e,a
            ld      a,($D347)
            in      a, (SETTINGS)
            bit     3,a
            jr      nz,L82C9
            ld      hl,(LC000)
L82C9:      ld      d,$00
            add     hl,de
            ld      e,(hl)
            ld      a,e
            inc     hl
            or      (hl)
            jr      z,L82EA
            ld      d,(hl)
            ld      hl,(LD2D2)
            ld      (hl),e
            inc     hl
            ld      (hl),d
            inc     hl
            ex      de,hl
            ld      hl,LD2CC
            and     a
            sbc     hl,de
            jr      nc,L82E6
            ld      de,LD2BE
L82E6:      ld      (LD2D2),de
L82EA:      exx
            dec     c
            jr      nz,L82A3
            ld      a,$01
            ld      (Is_Speech_Active),a ; Mark speech as active
            ei
L82F4:      ret

;*****************************************************************************************
; ----> Init_Sound_Block
;
;       Seeds the first three bytes of a sound/music configuration block in RAM,
;       then jumps to the main setup routine to finish the initialization.
;*****************************************************************************************
Init_Sound_Block:
            ld      hl,$0000            ; Clunky compiler math: HL = 0
            add     hl,de               ; HL = DE + 0

            ld      (hl),a              ; Byte 0: (DE) = A
            ld      hl,$0001            ; Clunky compiler math: HL = 1
            add     hl,de               ; HL = DE + 1

            ld      (hl),$40            ; Byte 1: (DE+1) = $40
            inc     hl                  ; HL = DE + 2 (Finally uses INC!)
            ld      (hl),$87            ; Byte 2: (DE+2) = $87

Init_Sound_Exec:
            jp      L8019               ; Jump to the main music port initialization

;*****************************************************************************************
; ----> Init_Sound_Queue_1
;       Initializes the first sound queue/block in static RAM.
;*****************************************************************************************
Init_Sound_Queue_1:
            ld      a, $18
Init_Sound_Queue_1_Alt:
            exx                         ; Swap to alternate register set
            ld      de, Sound_Queue_1_Record           ; DE' = $D270 (Sound Queue 1 RAM)
            jr      Init_Sound_Block    ; Call initialization routine

;*****************************************************************************************
; ----> Init_Sound_Queue_2
;       Initializes the second sound queue/block in static RAM.
;*****************************************************************************************
Init_Sound_Queue_2:
            ld      a, $58
            exx                         ; Swap to alternate register set
            ld      de, Sound_Queue_2_Record           ; DE' = $D2AC (Sound Queue 2 RAM)
            jr      Init_Sound_Block    ; Call initialization routine

;*****************************************************************************************
; ----> Init_All_Sound_Queues
;       Master sound initialization, executed during ROM startup (via $8006).
;*****************************************************************************************
Init_All_Sound_Queues:
            call    Init_Sound_Queue_1  ; Initialize Queue 1
            call    Init_Sound_Queue_2  ; Initialize Queue 2
            jp      L8253               ; Jump to sound execution/exit

;*****************************************************************************************
; ----> Dereference_HL
;       Reads the 16-bit address at (HL) and returns it in HL. Clears A.
;*****************************************************************************************
Dereference_HL:
            ld      e, (hl)             ; Load lower byte into E
            inc     hl
            ld      d, (hl)             ; Load upper byte into D
            ex      de, hl              ; HL = DE (HL now contains the dereferenced pointer)
            xor     a                   ; Clear A (A = 0)
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;*****************************************************************************************
;
L8325:      push    iy
            pop     de
            push    hl
            ld      c,a
            ld      hl,$0000
            add     hl,de
            ld      a,(hl)
            sub     b
            ld      b,c
            ld      c,a
            out     (c),b
            pop     hl
            add     hl,de
            ld      (hl),b
            exx
            xor     a
            ret
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$08
            ld      hl,L000B
            jr      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$01
            ld      hl,$0004
            jr      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$02
            ld      hl,L0005
            jp      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$03
            ld      hl,L0006
            jp      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$04
            ld      hl,L0007
            jp      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$07
            ld      hl,L000A
            jp      L8325
;
            ld      a,(hl)
            inc     hl
            exx
            ld      b,$06
            ld      hl,L0009
            jp      L8325
;
;*****************************************************************************************
; Purpose: Port Output Routine
;
;           Input:    HL
;           Output:   Triggers a hardware port write
;*****************************************************************************************
L8385:      ld      a,(hl)                  ; Read input byte into A
            inc     hl                      ; Increment pointer
            exx                             ; Swap to alternate registers
            ld      b,$05                   ; Load port parameter
            ld      hl,L0008                ; Load port parameter
            jp      L8325                   ; Jump to port output routine

;*****************************************************************************************
; Purpose: Music Port Initialization Wrapper
;
;           Input:    IY (implicit)
;           Output:   Initializes music hardware
;*****************************************************************************************
L8390:      exx                             ; Swap registers
            push    iy                      ; Save IY
            pop     de                      ; Copy IY into DE
            jp      L8019                   ; Jump to "Set up 8 music ports"

;*****************************************************************************************
; Purpose: Simple Return
;
;           Input:    None
;           Output:   A = $01
;*****************************************************************************************
L8397:      ld      a,$01                   ; Set success flag
            ret                             ; Return
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;*****************************************************************************************
;
            ld      a,(hl)
            inc     hl
            ld      (iy+$0d),a
            ld      a,$01
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;
;
;
;*****************************************************************************************
;
            ld      (iy+$03),$01
            xor     a
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;*****************************************************************************************
;
            ld      (iy+$03),$00
            xor     a
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;*****************************************************************************************
;

            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            inc     hl
            push    hl
            push    iy
            pop     hl
            add     hl,de
            ld      (hl),$00
            inc     hl
            inc     hl
            res     0,(hl)
            pop     hl
            xor     a
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;*****************************************************************************************
;
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            inc     hl
            ld      a,(hl)
            inc     hl
            push    hl
            push    iy
            pop     hl
            add     hl,de
            ld      (hl),a
            inc     hl
            inc     hl
            set     0,(hl)
            xor     a
            pop     hl
            ret
;
;*****************************************************************************************
; Purpose: ???
;
; Input:
;
; Output:
;
;
;*****************************************************************************************
;
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            inc     hl
            push    hl
            push    iy
            pop     hl
            add     hl,de
            ld      de,L0005
            add     hl,de
            ld      a,$06
            pop     de
L83E3:      ex      de,hl
            ld      b,(hl)
            inc     hl
            ex      de,hl
            ld      (hl),b
            dec     hl
            dec     a
            jr      nz,L83E3
            ex      de,hl
            ret
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            inc     hl
            ld      a,(hl)
            inc     hl
            push    hl
            push    iy
            pop     hl
            add     hl,de
            ld      de,L0006
            add     hl,de
            ld      (hl),a
            pop     hl
            xor     a
            ret
            ld      (iy+$0c),$01
            xor     a
            ret
L8407:      sub     a
            add     a,e
            sbc     a,d
            add     a,e
            rra
            add     a,e
            sub     b
            add     a,e
            out     ($83),a
            xor     $83
            ret     nz
            add     a,e
            xor     (hl)
            add     a,e
            ld      bc,LA284
            add     a,e
            xor     b
            add     a,e
            sub     a
            add     a,e
            sub     a
            add     a,e
            sub     a
            add     a,e
            sub     a
            add     a,e
            sub     a
            add     a,e
            ld      a,(L6F83)
            add     a,e
            ld      a,d
            add     a,e
            add     a,l
            add     a,e
            ld      h,h
            add     a,e
            ld      e,c
            add     a,e
            ld      c,(hl)
            add     a,e
            ld      b,h
            add     a,e
L8437:      ld      a,(iy+$11)
            or      a
            jr      z,L846F
            ld      l,(iy+$01)
            ld      h,(iy+$02)
L8443:      ld      a,(hl)
            inc     hl
            cp      $18
            jr      nc,L845E
            exx
            ld      hl,L8462
            push    hl
            ld      hl,L8407
            rlca
            ld      e,a
            ld      d,$00
            add     hl,de
            ld      e,(hl)
            inc     hl
            ld      d,(hl)
            push    de
            exx
            ret
            jr      L8462
L845E:      ld      hl,L8740
            xor     a
L8462:      or      a
            jr      z,L8443
            ld      (iy+$01),l
            ld      (iy+$02),h
            ld      (iy+$11),$00
L846F:      ret
L8470:      xor     $FF
            ld      b,a
            xor     a
            ld      de,L0008
L8477:      rl      b
            adc     a,d
            dec     e
            jr      nz,L8477
            rla
            rla
            rla
            ret
L8481:      ld      bc,L3010
            out     (c),b
            ld      c,$50
            out     (c),b
            in      a, (COINPORT)       ;
            set     3,a                 ; Set service switch bit ???
            call    L8470
            ld      bc,L0C15
            or      a
            jr      nz,L849B
            ld      b,$00
            jr      L849F
L849B:      xor     $7F
            add     a,$32
L849F:      out     (c),b
            out     (TONEC),a
            in      a, (P2PORT)
            and     $3F
            or      $C0
            call    L8470
            ld      bc,L0C56
            or      a
            jr      nz,L84B6
            ld      b,$00
            jr      L84B8
L84B6:      add     a,$4E
L84B8:      out     (c),b
            out     ($51),a
            in      a, (P1PORT)
            and     $3F
            or      $C0
            call    L8470
            ld      bc,L0C16
            or      a
            jr      nz,L84CF
            ld      b,$00
            jr      L84D1
L84CF:      add     a,$27
L84D1:      out     (c),b
            out     (TONEA),a
            ld      a,($D347)
            in      a, (SETTINGS)
            call    L8470
            ld      bc,L0C55
            or      a
            jr      nz,L84E7
            ld      b,$00
            jr      L84EB
L84E7:      xor     $7F
            sub     $0F
L84EB:      out     (c),b
            out     ($53),a
            jp      L81F8
L84F2:      ld      a,(Game_Mode)
            or      a
            jr      nz,L8501
            in      a, (COINPORT)       ;
            bit     3,a                 ; Is service switch on?
            jr      nz,L8501            ; no, skip down
            jp      L8481               ; Otherwise, go here ???
L8501:      ld      a,(Attract_Sound_Enabled)
            or      a
            jr      z,L851C
            push    iy
            ld      iy,Sound_Queue_1_Record
            call    L80E6
            ld      iy,Sound_Queue_2_Record
            call    L80E6
            call    L81F8
            pop     iy
L851C:      ret
L851D:      ld      a,d
            cp      (iy+$03)
            jr      c,L8537
            push    iy
            exx
            pop     de
            call    L8019
            ld      (iy+$11),$01
            ld      (iy+$03),d
            ld      (iy+$01),l
            ld      (iy+$02),h
L8537:      ret
L8538:      ld      hl,Sound_Request_2
            ld      a,(hl)
            or      a
            jr      z,L8582
            ld      (hl),$00
            ld      iy,Sound_Queue_2_Record
            rra
            ld      d,$01
            ld      hl,L8928
            jr      c,L851D
            rra
            ld      d,$00
            ld      hl,L887B
            jr      c,L851D
            rra
            ld      d,$01
            ld      hl,L87EA
            jr      c,L851D
            rra
            ld      d,$00
            ld      hl,L883B
            jp      c,L851D
            rra
            ld      hl,L8825
            jp      c,L851D
            rra
            rra
            ld      hl,L8988
            jp      c,L851D
            ld      iy,Sound_Queue_1_Record
            rra
            ld      d,$01
            ld      hl,L8741
            jp      c,L851D
L8582:      ret
L8583:      ld      hl,Sound_Request_3
            ld      a,(hl)
            ld      (hl),$00
            ld      iy,Sound_Queue_1_Record
            rra
            ld      d,$01
            ld      hl,L8AA1
            jr      nc,L85A2
            call    L851D
            ld      iy,Sound_Queue_2_Record
            ld      hl,L8ADD
            jp      L851D
L85A2:      ld      iy,Sound_Queue_2_Record
            rra
            ld      d,$00
            ld      hl,L890E
            jp      c,L851D
            rra
            ld      hl,L8851
            jp      c,L851D
            rra
            ld      hl,L8851
            jp      c,L851D
            rra
            ld      hl,L8A42
            jp      c,L851D
            rra
            jr      nc,L85D9
            ld      d,$01
            ld      hl,L8A6C
            call    L851D
            ld      iy,Sound_Queue_1_Record
            ld      hl,L8A81
            jp      L851D
L85D9:      rra
            ld      iy,Sound_Queue_1_Record
            ld      d,$01
            rra
            ld      hl,L877B
            jp      c,L851D
            ret
L85E8:      ld      hl,Sound_Request_4
            ld      a,(hl)
            ld      (hl),$00
            ld      iy,Sound_Queue_1_Record
            rra
            ld      d,$02
            ld      hl,L88E2
            jr      nc,L8607
            call    L851D
            ld      iy,Sound_Queue_2_Record
            ld      hl,L8905
            jp      L851D
L8607:      rra
            ld      d,$01
            ld      hl,L8AF6
            jr      nc,L861C
            call    $851D
            ld      hl,L8B1F
            ld      iy,Sound_Queue_2_Record
            jp      L851D
L861C:      ld      iy,Sound_Queue_2_Record
            rra
            ld      hl,L8AF3
            jp      c,L851D
            rra
            ld      hl,L8B5D
            jr      nc,L863A
            call    L851D
            ld      hl,L8B2E
            ld      iy,Sound_Queue_1_Record
            jp      L851D
L863A:      ret
            ld      d,$02
            call    L851D
            ld      d,$00
            ret
L8643:      call    $8316
            ld      iy,Sound_Queue_1_Record
            ld      d,$00
            ld      hl,L89BE
            call    L851D
            ld      iy,Sound_Queue_2_Record
            ld      hl,L89E5
            jp      L851D
L865C:      call    $8316
            ld      d,$00
            ld      iy,Sound_Queue_1_Record
            ld      hl,L8A0C
            call    L851D
            ld      iy,Sound_Queue_2_Record
            ld      hl,L8A27
            jp      L851D
L8675:      ld      iy,Sound_Queue_1_Record
            ld      d,$00
            ld      hl,L8971
            jp      L851D
L8681:      call    $8316
            ld      iy,Sound_Queue_1_Record
            ld      hl,L89A0
            call    L851D
            ld      iy,Sound_Queue_2_Record
            ld      hl,L89AF
            jp      L851D
L8698:      call    $8316
            ld      iy,Sound_Queue_1_Record
            ld      d,$00
            ld      hl,L8981
            call    L851D
            ret
L86A8:      call    $8316
            ld      iy,Sound_Queue_2_Record
            ld      hl,L8772
            ld      d,$00
            call    L851D
            ld      iy,Sound_Queue_1_Record
            ld      hl,L8741
            jp      L851D
L86C1:      ld      a,(Attract_Sound_Enabled)
            or      a
            jr      z,L8717
            push    iy
            ld      hl,Sound_Request_1
            ld      a,(hl)
            or      a
            jr      z,L86FE
            ld      d,$00
            ld      (hl),d
            ld      e,a
            bit     0,e
            call    nz,L8643
            bit     1,e
            call    nz,L8681
            bit     2,e
            call    nz,L86A8
            bit     3,e
            call    nz,L8698
            bit     4,e
            call    nz,L865C
            bit     5,e
            call    nz,L8675
            bit     6,e
            call    nz,$830E
            bit     7,e
            call    nz,$8306
            jr      L8707
L86FE:      call    L8538
            call    L8583
            call    L85E8
L8707:      ld      iy,Sound_Queue_1_Record
            call    L8437
            ld      iy,Sound_Queue_2_Record
            call    L8437
            pop     iy
L8717:      ret

            ; 40 bytes - ROM Padding
            DB      $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

L8740:      inc     bc
L8741:      inc     de
            inc     (hl)
            ld      (de),a
            xor     b
            ld      de,L10FD
            and     a
            inc     b
            ld      sp,hl
            rst     38H
            or      c
            and     a
            dec     b
            inc     bc
            ld      d,l
            ld      d,l
            inc     b
            sub     $FF
            ld      d,l
            ld      b,$FF
            ld      bc,L0117
            dec     b
            sub     $FF
            ld      bc,LFF16
            dec     d
            rrca
            inc     b
            jp      p,L0FFF
            inc     bc
            rst     38H
            inc     bc
            dec     b
            ld      bc,$0508
            jp      p,L01FF
            nop
L8772:      inc     de
            ld      l,d
            ld      (de),a
            sub     (hl)
            ld      de,L02B2
            ld      b,a
            add     a,a
L877B:      djnz    L878D
            inc     b
            ld      sp,hl
            rst     38H
            and     b
            djnz    L8787
            ld      hl,L0101
            inc     de
L8787:      add     hl,hl
            ld      (de),a
            inc     (hl)
            ld      de,L143E
L878D:      add     a,c
            dec     b
            ld      sp,hl
            rst     38H
            dec     b
            ld      d,$DD
            dec     d
            ld      c,$00
            inc     d
            nop
            djnz    L87F5
            inc     de
            ld      d,h
            ld      (de),a
            ld      l,d
            ld      de,L017E
            ex      af,af'
            inc     de
            ld      c,a
            ld      (de),a
            ld      e,(hl)
            ld      de,L016A
            ex      af,af'
            inc     de
            ld      b,(hl)
            ld      (de),a
            ld      d,h
            ld      de,L015E
            ex      af,af'
            djnz    L880A
            inc     de
            ld      d,h
            ld      (de),a
            ld      l,d
            ld      de,L017E
            ex      af,af'
            inc     de
            ld      c,a
            ld      (de),a
            ld      e,(hl)
            ld      de,L016A
            ex      af,af'
            inc     de
            ld      b,(hl)
            ld      (de),a
            ld      d,h
            ld      de,L015E
            ex      af,af'
            djnz    L881F
            inc     de
            ld      d,h
            ld      (de),a
            ld      l,d
            ld      de,L017E
            ex      af,af'
            inc     de
            ld      c,a
            ld      (de),a
            ld      e,(hl)
            ld      de,L016A
            ex      af,af'
            inc     de
            ld      b,(hl)
            ld      (de),a
            ld      d,h
            ld      de,L015E
            ex      af,af'
            ld      (bc),a
            sbc     a,c
            add     a,a
L87EA:      djnz    L878C
            inc     b
            ld      sp,hl
L87EE:      rst     38H
            and     b
            djnz    L87EE
            ld      hl,L0101
L87F5:      inc     de
            ld      a,(de)
            ld      (de),a
            jr      nz,L880B
            dec     h
            inc     d
            add     a,c
            dec     b
            ld      sp,hl
            rst     38H
            dec     b
            ld      d,$CC
            dec     d
            inc     c
            nop
            inc     bc
            djnz    L8829
            dec     d
L880A:      dec     de
L880B:      ld      d,$AA
            nop
            inc     bc
            inc     b
            ld      sp,hl
            rst     38H
            jr      nz,L881A
            inc     iy
L8816:      inc     bc
            ld      bc,LF905
L881A:      rst     38H
            ld      bc,L2713
            ld      (de),a
L881F:      dec     de
            ld      de,L0217
            rlca
            adc     a,b
L8825:      inc     b
            ld      sp,hl
            rst     38H
            jr      nz,L882E
            cp      $23
            ld      (bc),a
            ld      bc,LF905
            rst     38H
            ld      (bc),a
            inc     de
            inc     de
            ld      (de),a
            dec     c
            ld      de,L020B
            rlca
            adc     a,b
L883B:      inc     b
            ld      sp,hl
            rst     38H
            jr      nz,L8842
            cp      $23
L8842:      ld      bc,$0501
            ld      sp,hl
            rst     38H
            inc     bc
            inc     de
            ld      a,(bc)
            ld      (de),a
            ex      af,af'
            ld      de,L0206
            rlca
            adc     a,b
L8851:      inc     de
            inc     l
            ld      (de),a
            inc     d
            ld      de,$100F
            djnz    L885F
            ld      sp,hl
            rst     38H
            ld      (bc),a
            inc     b
            ld      sp,hl
L885F:      rst     38H
            and     b
            djnz    L8867
            ld      hl,L0101
            rla
L8867:      djnz    L886D
            DB      $dd,$ff
            ld      (hl),b
            djnz    L8872
            inc     bc
            ld      bc,$0501
L8872:      DB      $dd,$ff
            ld      bc,L8816
            dec     d
            jr      L887A
L887A:      inc     bc
L887B:      djnz    L8895
            inc     b
            ld      sp,hl
            rst     38H
            jr      L8884
            cp      $21
L8884:      ld      bc,L1301
            daa
            ld      (de),a
            ld      b,(hl)
            ld      de,$057E
            ld      sp,hl
            rst     38H
            ld      bc,L7716
            dec     d
            rla
            rla
L8895:      ld      a,(bc)
            inc     b
            DB      $dd,$ff
            ld      a,(bc)
            ld      (bc),a
            cp      $03
            ld      bc,$0501
            DB      $dd,$ff
            ld      bc,L0400
            ld      sp,hl
            rst     38H
            add     a,b
            ld      (bc),a
            ld      (bc),a
L88AA:      inc     hl
            ld      bc,$0501
            ld      sp,hl
            rst     38H
            ld      bc,L0300
            djnz    L88BB
            inc     b
            ld      sp,hl
            rst     38H
            ld      (hl),d
            ld      b,$05
L88BB:      ld      hl,L0101
            rla
            ld      (LDD04),hl
            rst     38H
            ld      h,h
            dec     b
            inc     bc
            ld      hl,L0101
            dec     b
            DB      $dd,$ff
            inc     b
            inc     de
            ld      de,L1712
            ld      de,Clear_Dungeon_Number
            sbc     a,d
            dec     d
            ld      a,(de)
            nop
            dec     b
            ld      sp,hl
            rst     38H
            ld      bc,LF906
            rst     38H
            ld      bc,L0300
L88E2:      ld      bc,$1302
            ld      hl,(L1812)
            ld      de,$1006
            jr      nc,L88F1
            ld      sp,hl
            rst     38H
            jr      nc,L8911
L88F1:      call    m,L0101
            ld      bc,L0017
            inc     b
            DB      $dd,$ff
            jr      nz,L88FC
L88FC:      ld      (bc),a
            ld      bc,$0404
            ld      d,$FF
            dec     d
            rra
            nop
L8905:      inc     de
            ld      h,h
            ld      (de),a
            ld      d,b
            ld      de,L023C
            jp      pe,L1088
            jr      nz,L8924
L8911:      inc     de
            ld      (de),a
            ld      (de),a
            ld      de,L1710
            djnz    L892F
            ld      h,a
            dec     d
            rla
            inc     b
            ld      sp,hl
            rst     38H
            jr      L8941
            ret     m
            ld      bc,L0202
            ld      bc,Do_Joy_Jump
L8928:      djnz    L8952
            rla
            add     a,h
            inc     b
            DB      $dd,$ff
L892F:      add     a,h
            ld      a,(bc)
            rst     38H
            inc     bc
            ld      bc,L1601
            call    z,L0C15
            inc     d
            add     a,e
            inc     de
            ld      (Select_P1_Life_Icon),hl
            ld      de,L0410
            ex      de,hl
            rst     38H
            adc     a,h
            add     a,e
            ld      bc,L0823
            ex      af,af'
            dec     b
            ex      de,hl
            rst     38H
            ld      bc,$1500
            inc     e
            ld      bc,Clear_Joy_Str
            inc     de
            ld      d,h
            ld      (de),a
            inc     (hl)
            ld      de,L10FD
            jr      nz,L8961
            ld      sp,hl
            rst     38H
            jr      c,L8969
L8961:      rst     38H
            ld      bc,L0101
            dec     b
            jp      p,L01FF
L8969:      ld      bc,L0960
            ld      b,$F9
            rst     38H
            ld      bc,$1600
            rst     38H
            dec     d
            rra
            inc     b
            jp      p,L0FFF
            ld      (bc),a
            rst     38H
            inc     bc
            add     hl,de
            add     hl,de
            ld      (bc),a
            ld      d,h
            adc     a,c
L8981:      ld      d,$22
            dec     d
            ld      (de),a
            ld      (bc),a
            ld      d,h
            adc     a,c
L8988:      djnz    L89AA
            inc     b
            ld      sp,hl
            rst     38H
            jr      nz,L899B
            rst     38H
            inc     bc
            ld      (bc),a
            ld      bc,L5516
            dec     d
            ld      b,$13
            ld      d,h
            ld      (de),a
            ld      l,d
L899B:      ld      de,L01FD
            jr      z,L89A3
L89A0:      djnz    L89D2
            inc     d
L89A3:      add     a,c
            ld      d,$FC
            dec     d
            ld      c,$13
            ld      b,(hl)
L89AA:      ld      (de),a
            inc     l
            ld      de,L00FD
L89AF:      djnz    L89E1
            inc     d
            add     a,c
            ld      d,$FD
            dec     d
            ld      c,$13
            ld      a,(hl)
            ld      (de),a
            ld      e,c
            ld      de,L006A
L89BE:      djnz    L89F0
            ld      d,$FE
            dec     d
            rrca
            inc     d
            add     a,c
            inc     de
            ld      a,$12
            xor     b
            ld      de,L016A
            ld      b,d
            inc     de
            scf
            ld      (de),a
            ld      (hl),b
L89D2:      ld      de,L015E
            ld      d,$13
            dec     (hl)
            ld      (de),a
            ld      l,d
            ld      de,L0154
            inc     (hl)
            inc     de
            ld      a,$12
L89E1:      xor     b
            ld      de,L006A
L89E5:      djnz    L8A17
            inc     d
            add     a,c
            ld      d,$EE
            dec     d
            rrca
            inc     de
            ld      d,h
            ld      (de),a
L89F0:      ld      l,d
            ld      de,L01FD
            ld      b,d
            inc     de
            ld      e,(hl)
            ld      (de),a
            ld      d,h
            ld      de,L01E1
            ld      d,$13
            ld      b,(hl)
            ld      (de),a
            ld      a,$11
            call    nc,L3401
            inc     de
            ld      d,h
            ld      (de),a
            ld      a,(hl)
            ld      de,L00FD
L8A0C:      djnz    L8A3E
            ld      d,$EF
            dec     d
            rrca
            inc     d
            add     a,c
            inc     de
            ld      (hl),b
            ld      (de),a
L8A17:      ld      a,$11
            xor     b
            ld      bc,L1360
            ld      (hl),b
            ld      (de),a
            ld      b,d
            ld      de,L01A8
            ld      e,b
            ld      (bc),a
            cp      (hl)
            adc     a,c
L8A27:      djnz    L8A59
            inc     d
            add     a,c
            ld      d,$EF
            dec     d
            rrca
            inc     de
            ld      c,a
            ld      (de),a
            inc     (hl)
            ld      de,L015E
            ld      h,b
            inc     de
            ld      d,h
            ld      (de),a
            scf
            ld      de,L015E
L8A3E:      ld      e,b
            ld      (bc),a
            push    hl
            adc     a,c
L8A42:      djnz    L8A58
            inc     d
            ld      c,b
            inc     b
            ld      sp,hl
            rst     38H
            inc     d
            ex      af,af'
            rst     38H
            inc     hl
            ld      (bc),a
            inc     bc
            dec     d
            jr      z,L8A69
            jr      nz,L8A58
            DB      $dd,$ff
            ld      d,h
            jr      nz,L8A5D
L8A59:      inc     bc
            ld      (bc),a
            inc     bc
            dec     b
L8A5D:      ld      sp,hl
            rst     38H
            ld      bc,L8816
            inc     de
            DB      $fd,$12
            cp      $11
            rst     38H
            nop
L8A69:      ld      bc,L0306
L8A6C:      inc     de
            ret     po
            ld      (de),a
            ret     z
            ld      de,$10B6
            inc     d
            inc     d
            ld      c,b
            ld      d,$88
            dec     d
            jr      z,L8A92
            jr      nz,L8A7E
            jr      nz,L8A81
            ld      b,d
            adc     a,d
L8A81:      djnz    L8A8C
            inc     d
            ld      c,b
            inc     de
            ret     po
            ld      (de),a
            ret     z
            ld      de,L16B6
L8A8C:      cp      e
            dec     d
            dec     c
            ld      bc,L0420
L8A92:      ld      sp,hl
            rst     38H
            ld      hl,L0209
            ld      hl,L0302
            dec     b
            ld      sp,hl
            rst     38H
            ld      bc,L6202
            adc     a,d
L8AA1:      inc     b
            DB      $dd,$ff
            add     a,b
            nop
            cp      $21
            ld      bc,L1701
            add     a,b
            djnz    L8AEE
            inc     de
            ld      l,b
            ld      (de),a
            ld      b,h
            ld      de,$0521
            DB      $dd,$ff
            ld      bc,L1F15
            ld      d,$EE
            nop
            dec     d
            cpl
            dec     b
            ld      sp,hl
            rst     38H
            ld      (bc),a
            ld      b,$DD
            rst     38H
            ld      bc,LF904
            rst     38H
            add     a,b
            ld      (bc),a
            rst     38H
            ld      hl,L0101
            inc     d
            add     a,b
            inc     b
            ex      de,hl
            rst     38H
            cp      a
            add     a,b
            ld      bc,L0201
            ld      (bc),a
            nop
            inc     bc
L8ADD:      inc     de
            inc     sp
            ld      (de),a
            jr      nc,L8AF3
            ld      (bc),a
            ld      bc,$0404
            DB      $dd,$ff
            add     a,b
            nop
            ld      (bc),a
            ld      hl,L0101
L8AEE:      rla
            nop
            ld      (bc),a
            xor     h
            adc     a,d
L8AF3:      ld      (bc),a
            or      e
            adc     a,b
L8AF6:      djnz    L8B0C
            inc     d
            adc     a,b
            inc     de
            scf
            ld      (de),a
            add     a,l
            ld      de,High_Priority_Sound_Request_Byte
            nop
            ld      d,$AA
            dec     d
            ld      hl,(L2801)
            inc     d
            nop
            inc     b
            ld      sp,hl
L8B0C:      rst     38H
            ld      e,h
            inc     d
            ld      b,$01
            inc     b
            inc     b
            rla
            jr      z,L8B1A
            sub     $FF
            inc     b
            ld      bc,L01FF
            jr      nc,L8B4E
            nop
L8B1F:      djnz    L8B31
            inc     d
            add     a,(hl)
            inc     de
            add     hl,hl
            ld      (de),a
            dec     (hl)
            ld      de,L167E
            sbc     a,c
            dec     d
            add     hl,hl
            nop
L8B2E:      inc     de
            xor     b
            ld      (de),a
L8B31:      ld      a,(de)
            ld      de,L167E
            DB      $dd,$15
            dec     l
            djnz    L8B58
            rla
            jr      L8B51
            ld      bc,LEB05
            rst     38H
            dec     b
            inc     b
            ex      de,hl
            rst     38H
            inc     e
            ld      bc,L2303
            ld      (bc),a
            ld      (bc),a
            nop
            dec     b
            ex      de,hl
L8B4E:      rst     38H
            ld      bc,Maze_14_Data_Byte_13
            inc     b
            ex      de,hl
            rst     38H
            inc     e
            ld      bc,L23FD
            rlca
            rlca
            nop
            inc     bc
L8B5D:      inc     de
            ld      d,h
            ld      (de),a
            inc     (hl)
            ld      de,L02FD
            inc     (hl)
            adc     a,e
            dec     e
            add     a,e
            add     hl,de
            daa
            add     hl,bc
            jr      L8B70
            dec     l
            ld      h,$35
L8B70:      dec     hl
            jr      L8BA6
            add     hl,de
            inc     bc
            dec     e
            dec     (hl)
            dec     hl
            ld      e,$33
            ld      c,$23
            jr      L8B9D
            add     hl,de
            ld      h,$35
            dec     hl
            ld      a,$83
            ld      sp,P1_Life_Icon_Primary
            ld      (L3609),hl
            jr      z,L8BA8
            dec     sp
            nop
            ld      hl,(L282A)
            scf
            dec     h
            dec     d
            dec     l
            ld      a,(Text_Monsters_Visible_Byte_09)
            jr      L8BD8
            add     a,e
            dec     d
            nop
L8B9D:      add     hl,bc
            add     hl,hl
            jr      L8BCB
            jr      nz,L8BBC
            add     hl,de
            dec     sp
            dec     hl
L8BA6:      ld      (L220F),a
            ld      (hl),$28
            inc     bc
            inc     c
            dec     d
            add     hl,bc
            add     hl,hl
            rra
            dec     sp
            jr      L8BD1
            ld      a,$83
            ld      a,(bc)
            add     a,e
            ld      (L2836),hl
            inc     sp
L8BBC:      dec     hl
            daa
            dec     c
            ld      a,$83
            inc     d
            add     a,e
            jr      c,L8BF8
            inc     bc
            ld      e,$33
            dec     c
            ld      a,(de)
            ld      (bc),a
L8BCB:      dec     c
            ld      (de),a
            inc     sp
            rrca
            dec     l
            ld      h,$35
            dec     hl
            dec     hl
            ld      a,$BE
            ex      af,af'
            dec     d
L8BD8:      inc     hl
            add     hl,bc
            add     hl,hl
            cpl
            nop
            inc     c
            ld      a,$11
            ld      a,$38
            ld      (hl),e
            dec     l
            ld      h,a
            ld      (de),a
            ld      a,(L731E)
            ld      c,a
            inc     bc
            ld      l,l
            ld      h,$35
            dec     hl
            dec     hl
            ld      a,$2B
            dec     l
            inc     sp
            dec     c
            ld      c,$23
            ex      af,af'
L8BF8:      add     hl,hl
            ld      hl,(L2B1D)
            inc     sp
            inc     c
            inc     c
            dec     d
            add     hl,bc
            ld      (L2B25),hl
            daa
            ld      hl,(L2229)
            rra
            ld      a,$3E
            cpl
            nop
            dec     c
            ld      e,$22
            ld      (hl),$28
            jr      L8C4F
            add     hl,de
            inc     bc
            rra
            dec     h
            jr      L8C40
            scf
            ld      e,$3E
            inc     e
            inc     c
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            add     hl,de
            dec     hl
            inc     a
            ld      hl,(L3A10)
            rra
            inc     h
            inc     hl
            dec     hl
            dec     hl
            ld      b,$1E
            add     hl,hl
            dec     (hl)
            scf
            cpl
            nop
            add     hl,de
            ld      hl,(L0F0B)
            ld      a,$1E
            dec     l
            ld      h,$2B
            jr      L8C73
L8C40:      add     hl,de
            inc     bc
            dec     l
            daa
            jr      L8C49
            dec     sp
            rra
            inc     bc
L8C49:      add     hl,de
            ld      b,$09
            ld      (L0325),hl
L8C4F:      jr      c,L8C7C
            jr      z,L8C8B
            inc     sp
            ld      e,$26
            dec     (hl)
            dec     hl
            ld      a,$1E
            ld      (L2836),hl
            dec     l
            dec     (hl)
            dec     c
            ld      hl,(L6F1B)
            ld      a,(bc)
            rrca
            inc     bc
            ld      b,$2A
            djnz    L8CD8
            dec     c
            rra
            inc     bc
            dec     e
            inc     (hl)
            dec     hl
            add     hl,hl
            dec     (hl)
            dec     hl
L8C73:      ld      e,$6E
            dec     c
            rra
            ld      a,$1F
            add     a,e
            dec     hl
            inc     a
L8C7C:      inc     c
            ld      a,e
            inc     c
            ld      c,$3A
            ld      a,$55
            nop
            add     hl,bc
            add     hl,hl
            inc     c
            jr      c,L8CBC
            dec     l
            daa
L8C8B:      ld      (de),a
            ld      a,($3E1E)
            dec     c
            dec     d
            ld      hl,(L3629)
            scf
            scf
            ld      a,$83
            inc     l
            ld      c,e
            ld      e,l
            add     hl,hl
            add     hl,bc
            scf
            add     hl,de
            cpl
            nop
            dec     c
            ld      hl,(L0E3E)
            ld      a,h
            ld      hl,(Text_Monsters_Visible_Byte_36)
            dec     hl
            dec     sp
            rra
            ld      hl,(LB83E)
            ld      b,d
            dec     c
            add     hl,hl
            ld      (hl),$37
            jr      L8CC3
            ld      (bc),a
            rrca
            ld      a,(Maze_17_Data_Byte_01)
            ld      b,d
L8CBC:      ld      hl,(Text_Monsters_Visible_Byte_36)
            ld      c,$3B
            rra
            ld      hl,(Init_Sound_Exec)
            ld      sp,L2783
            dec     e
            add     hl,hl
            add     hl,bc
            jr      z,L8CEB
            inc     a
            rra
            ld      hl,(L352B)
            inc     hl
            add     hl,bc
            ld      hl,L080C
            ex      af,af'
L8CD8:      nop
            add     hl,bc
            add     hl,hl
            ld      c,$60
            ld      c,$29
            ld      ($3E1F),hl
            dec     d
            add     hl,bc
            ld      (L2518),hl
            ld      d,l
            dec     h
            add     hl,hl
            ld      (hl),$28
            dec     bc
            dec     c
            jr      c,L8D11
            ld      hl,L0F33
            dec     sp
            dec     c
            ld      a,$83
            dec     d
            add     a,e
            dec     c
            ld      d,l
            inc     hl
            scf
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            inc     c
            inc     e
            dec     sp
            ld      hl,($1427)
            inc     c
            ld      l,$00
            ld      e,$3E
            add     a,e
            dec     de
            add     a,e
            ld      (L2836),hl
            dec     l
            daa
            jr      L8D23
            ld      a,e
            rrca
            ld      a,(L3C18)
            inc     a
            rrca
            dec     l
            ld      h,(hl)
            ld      (hl),l
            dec     hl
            ld      (L5518),a
            nop
            add     hl,hl
            rrca
            ld      a,$83
            dec     d
            add     a,e
            inc     e
            ld      d,l
            dec     hl
            dec     l
            dec     (hl)
            dec     hl
            ld      a,$1C
            dec     (hl)
            dec     (hl)
            ld      l,a
            nop
            dec     e
            ld      hl,(L383A)
            dec     sp
            inc     c
            ld      a,$83
            ld      c,$83
            dec     l
            dec     d
            ld      hl,(L3810)
            inc     sp
            dec     hl
            jr      nz,L8D68
            dec     d
            dec     hl
            inc     bc
            add     a,e
            ld      b,$2D
            ld      h,$2B
            add     hl,hl
            ld      a,(L1D3E)
            add     a,e
            dec     c
            dec     d
            ld      h,e
            ld      (hl),a
            ld      (L3736),hl
            scf
            inc     e
            dec     sp
            ld      hl,(L3903)
            ld      (L5B03),a
            ld      b,d
L8D68:      ld      c,c
            rrca
            inc     a
            dec     l
            ld      b,l
            add     hl,bc
            ld      (L1F2A),hl
            ld      a,$83
            ld      d,$83
            add     hl,hl
            inc     (hl)
            inc     (hl)
            dec     hl
            ld      l,a
            nop
            ld      e,a
            ld      e,c
            daa
            inc     d
            dec     e
            ld      h,$2B
            ld      hl,(L732B)
            ld      c,(hl)
            inc     hl
            jr      L8DC7
            add     a,e
            ld      hl,(P1_Life_Icon_Primary)
            add     hl,hl
            ld      (hl),$28
            ld      hl,($152B)
            nop
            add     hl,bc
            add     hl,hl
            ld      l,a
            dec     c
            add     hl,hl
            dec     de
            ld      d,l
            ld      l,e
            ld      e,$3A
            ld      a,$83
            ld      (L2836),hl
            jr      L8E1A
            dec     c
            jr      L8DD1
            inc     c
            inc     l
            inc     a
            ld      hl,(L272D)
            add     hl,sp
            ld      e,(hl)
            jr      z,L8DDA
            inc     c
            ld      a,$83
            daa
            add     a,e
            ld      c,$7A
            ld      l,e
            dec     l
            ld      h,$2B
            ld      a,$1C
            ld      d,l
            ld      l,e
            dec     l
            ld      h,$2B
            ld      a,$2F
            nop
L8DC7:      dec     c
            ld      e,$39
            ld      h,(hl)
            ld      l,e
            dec     l
            ld      h,$2B
            ld      a,$2D
L8DD1:      daa
            jr      L8DF2
            ld      (hl),$68
            ld      (L2836),hl
            daa
L8DDA:      dec     c
            ld      a,$83
            ld      (L0C83),hl
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            dec     l
            ld      h,(hl)
            ld      l,e
            jr      L8E10
            inc     d
            rra
            dec     d
            inc     hl
            dec     hl
            rrca
            ld      a,e
            ld      b,b
            dec     hl
L8DF2:      add     hl,hl
            rrca
            ld      a,e
            ld      b,b
            dec     hl
            add     hl,hl
            dec     de
            ld      (hl),e
            dec     c
            inc     e
            dec     hl
            add     hl,hl
            ld      a,$83
            inc     hl
            inc     c
            dec     d
            ld      b,b
            ld      c,c
            ld      l,c
            inc     c
            ld      l,a
            ld      e,$1A
            dec     bc
            add     hl,de
            daa
            ld      (de),a
            rra
            ld      hl,(L7D2B)
            dec     c
            inc     e
            dec     hl
            jr      c,L8E46
            nop
            dec     c
            add     hl,hl
L8E1A:      inc     (hl)
            inc     (hl)
            dec     hl
            dec     l
            ld      a,e
            ld      h,l
            ld      (L1F0D),a
            ld      a,$26
            add     a,e
            add     hl,hl
            inc     (hl)
            inc     (hl)
            dec     hl
            ld      c,(hl)
            ld      h,$34
            ld      c,l
            rra
            dec     l
            daa
            jr      L8E36
            jr      L8E4A
            nop
L8E36:      add     hl,hl
            daa
            dec     c
            jr      c,L8E6E
            ld      e,$73
            dec     c
            ld      a,(de)
            ld      (bc),a
            dec     c
            rra
            inc     sp
            rrca
            dec     l
            ld      h,$35
            dec     hl
            dec     hl
            ld      a,$83
            dec     hl
            dec     l
            dec     d
            nop
            add     hl,bc
            jr      L8E74
            halt
            ld      l,b
            ld      e,$3C
            rrca
            ld      (bc),a
            jr      L8E7D
            dec     h
            ld      hl,(L151F)
            add     hl,bc
            ld      hl,L0D3B
            rra
            ld      a,$2D
            inc     a
            add     hl,hl
            ld      e,$3C
            rrca
            ld      (bc),a
            jr      $8E90
            dec     h
L8E6E:      ld      hl,(L2F0C)
            nop
            ld      e,$1A
L8E74:      dec     bc
            add     hl,de
            ld      a,$13

;*****************************************************************************************
; ----> Votrax Speech String: "Hey, Insert coin!"
;
;       Length: $13 (19) bytes. Pitch inflection is applied via bit 6 (+$40).
;*****************************************************************************************
SPK_Hey_Insert_Coin:
            DB      $1B, $60, $4B, $62  ; "Hey,"   (H, A, I1, Y1)
            DB      $3E, $3E            ; Pause    (PA1, PA1)
            DB      $27, $0D, $1F, $7A  ; "Inser-" (I, N, S, ER)
            DB      $6A                 ; "-t"     (T)
            DB      $3E                 ; Pause    (PA1)
            DB      $59, $75, $34, $09  ; "Coi-"   (K, O1, O2, I3)
            DB      $22, $0D            ; "-n!"    (Y1, N)
            DB      $3E                 ; Pause    (PA1)
            DB      $0A                 ; Padding  (I2 - Unplayed 20th byte)


;*****************************************************************************************
; ----> Votrax Speech Strings: Wizard Taunts
;
;       Length: $67 (103) bytes. Pitch inflection is applied via bit 6 (+$40).
;*****************************************************************************************
SPK_Find_Me:
            DB      $1D, $55, $49, $69, $0D, $1E                ; "Find"       (F, AH1, I3, Y, N, D)
            DB      $0C, $2C, $3C, $3E                          ; "me,"        (M, E, E1, PA1)

SPK_Outta_Spite:
            DB      $12, $15, $49, $69, $0C, $03                ; "Zym/I'm"    (Z, AH1, I3, Y, M, PA0)
            DB      $08, $35, $37, $1E, $15, $03                ; "outta"      (AH2, O1, U1, D, AH1, PA0)
            DB      $1F, $25, $08, $4B, $69, $2A, $3E           ; "spite,"     (S, P, AH2, I1, Y, T, PA1)

SPK_Get_Ready:
            DB      $08, $1C, $3B, $2A, $2B, $3B, $1E, $29, $3E ; "Get ready," (AH2, G, EH, T, R, EH, D, Y, PA1)

SPK_Better_Hope:
            DB      $20, $22, $36, $28, $1E, $03                ; "you'd"      (A, Y1, IU, U, D, PA0)
            DB      $0E, $42, $2A, $3A, $03                     ; "better"     (B, EH1, T, ER, PA0)
            DB      $1B, $26, $25                               ; "hope"       (H, O, P)
            DB      $22, $76, $68                               ; "you'll"     (Y1, IU, L)
            DB      $1E, $26, $0D, $2A                          ; "don't"      (D, O, N, T)
            DB      $5D, $55, $09, $22, $0D, $1E                ; "find"       (F, AH1, I3, Y1, N, D)
            DB      $4C, $2C, $3C, $3E, $3E, $3E                ; "me"         (M, E, E1, PA1, PA1, PA1)

SPK_Treasure_Chest:
            DB      $1E, $15, $0D, $33, $39, $3A, $03           ; "down there" (D, AH1, N, UH, TH, ER, PA0)
            DB      $19, $35, $34, $09, $22, $0D                ; "coin/goin'" (K, O1, O2, I3, Y1, N)
            DB      $1D, $26, $2B                               ; "for"        (F, O, R)
            DB      $0C, $55, $49, $62                          ; "my"         (M, AH1, I3, Y1)
            DB      $2A, $2B, $02, $07, $3A                     ; "treasure"   (T, R, EH1, ZH, ER)
            DB      $2A, $10, $3B, $1F, $2A                     ; "chest."     (T, CH, EH, S, T)
            DB      $3E, $0A                                    ; Pause & Pad  (PA1, I2)


            ld      a,$1B
            ld      d,l
            dec     de
            ld      d,l
            dec     de
            dec     d
            dec     de
            dec     d
            ld      a,$22
            ld      h,h
            ex      af,af'
            inc     bc
            ld      e,h
            halt
            halt
            ld      (hl),$36
            ld      e,$3E
            inc     c
            dec     d
            add     hl,bc
            add     hl,hl
            dec     h
            ld      a,e
            ld      hl,(L2D1F)
            ld      a,(Maze_16_Data)
            dec     sp
            ld      hl,($1427)
            dec     de
            ld      (hl),e
            ld      d,h
            inc     e
            dec     hl
            add     hl,hl
            ld      a,$3E
            inc     d
            add     a,e
            ld      (L2836),hl
            jr      L8F43
            dec     sp
            ld      hl,($3E3E)
            jr      c,L8F59
            inc     bc
            ld      c,b
            dec     hl
            inc     l
            dec     c
            dec     d
            ld      a,$BE
            dec     bc
            cp      (hl)
            dec     de
            dec     d
            dec     de
            dec     d
            dec     de
            dec     d
            dec     de
            dec     d
            ld      a,$83
            inc     hl
            dec     d
L8F43:      dec     c
            ld      (L3A38),a
            inc     bc
            dec     l
            ld      h,$2B
            add     hl,hl
            ld      a,(L351D)
            dec     hl
            inc     c
            dec     d
            add     hl,bc
            ld      (L200E),hl
            add     hl,hl
            ld      c,$22
L8F59:      add     hl,hl
            rra
            ld      hl,(L1E28)
            inc     l
            rrca
            dec     d
            inc     (hl)
            scf
            dec     hl
            ld      a,$1D
            add     hl,de
            ld      l,h
            dec     h
            inc     bc
            inc     e
            ld      h,$0B
            ld      (L0314),hl
            ld      l,$0D
            ld      e,$29
            ld      (hl),$28
            dec     l
            daa
            jr      L8F97
            ld      d,l
            dec     bc
            ld      (Initialize_Player_Life_Displays),hl
            inc     c
            inc     l
            inc     a
            ld      a,$1D
            dec     d
            dec     e
            inc     a
            jr      z,L8FB1
            inc     c
            ld      h,$2B
            ld      e,$33
            dec     c
            ld      a,(de)
            ld      (bc),a
            dec     c
            rra
            ld      a,$15
            dec     c
            ld      e,$29
            ld      (hl),$68
            ld      e,b
            ld      c,$2C
            inc     a
            inc     bc
            jr      nz,L8FA7
            ex      af,af'
            dec     l
            ld      h,(hl)
            ld      l,e
            jr      L8FCD
L8FA7:      dec     hl
            ld      e,$3E
            ld      a,(bc)
            add     a,e
            dec     l
            ld      h,(hl)
            ld      l,e
            jr      L8FD7
L8FB1:      dec     hl
            ld      e,$3E
            add     a,e
            ld      (de),a
            add     hl,de
            dec     d
            inc     c
            ld      c,$2E
            add     hl,de
            dec     e
            ld      h,$2B
            inc     c
            ld      h,$35
            dec     hl
            ld      a,$3E
            dec     l
            daa
            add     hl,sp
            daa
            add     a,e
            jr      c,L8FFF
            ld      e,$73
            ld      c,l
            ld      a,(de)
            dec     sp
            dec     c
            rra
            inc     bc
            inc     sp
            rrca
            inc     bc
L8FD7:      dec     l
            ld      h,$35
            dec     hl
            dec     hl
            dec     d
            dec     l
            ld      b,(hl)
            ld      h,c
            add     hl,hl
            ld      hl,(L2903)
            ld      h,$35
            dec     hl
            dec     hl
            add     hl,bc
            inc     a
            ld      hl,(L2B7A)
            dec     c
            ld      a,$83
            dec     hl
            add     a,e
            ld      e,$6C
            inc     a
            dec     h
            daa
            dec     c
            jr      c,L902D
            inc     bc
            add     hl,de
            ld      l,$0F
            ld      a,(L1F0D)
            inc     bc
            inc     sp
            rrca
            dec     l
            ld      h,(hl)
            ld      (hl),l
            dec     hl
            dec     hl
            ld      a,$3E
            ld      (L2836),hl
            scf
            dec     l
            daa
            jr      L901F
            ld      l,h
            ld      a,h
            ld      hl,(L0C03)
            inc     l
            inc     a
            inc     bc
            add     a,e
            ld      c,$3E
            add     hl,sp
L901F:      add     hl,sp
            cpl
            nop
            inc     d
            add     hl,de
            rra
            inc     bc
            add     hl,hl
            ld      (hl),$28
            scf
            ld      a,$18
            add     a,e
L902D:      ld      (L2836),hl
            dec     c
            ld      (hl),l
            ld      (hl),l
            dec     (hl)
            ld      (L2836),hl
            add     hl,de
            cpl
            nop
            dec     c
            ld      e,$36
            jr      z,L904D
            ld      a,e
            ld      hl,($3E3A)
            add     a,e
            ld      h,$1B
            ld      a,d
            ld      l,e
            add     hl,hl
            ld      c,$2F
            nop
            add     hl,de
L904D:      ld      a,$3E
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            add     hl,de
            cpl
            nop
            dec     c
            ld      hl,(L462D)
            ld      h,c
            add     hl,hl
            ld      hl,(L362A)
            scf
            ld      e,$76
            jr      z,L908B
            ld      hl,(Maze_16_Data_Byte_07)
            ld      b,l
            ld      b,d
            dec     c
            ld      a,$27
            ld      (L2836),hl
            add     hl,de
            cpl
            nop
            dec     c
            rra
            ld      hl,(L2B55)
            ld      hl,(L0D15)
            halt
            scf
            dec     l
            ld      a,$BE
            ld      c,$33
            ld      hl,(L351D)
            dec     hl
            dec     c
            dec     d
            ld      h,e
            ld      (hl),a
            add     hl,hl
            inc     (hl)
L908B:      inc     (hl)
            dec     hl
            add     hl,sp
            dec     hl
            ld      (hl),a
            scf
            ld      a,$BE
            ld      (L6C1B),hl
            dec     de
            ld      l,h
            dec     de
            ld      l,h
            dec     de
            ld      h,$1B
            ld      h,$1B
            ld      h,$1B
            dec     d
            dec     de
            dec     d
L90A4:      dec     de
            dec     d
            dec     de
            dec     d
            ld      a,$38
            ld      l,(hl)
            nop
            ld      hl,(L0303)
            dec     l
            inc     sp
            ld      (de),a
            dec     e
            inc     sp
            dec     c
            ld      a,$19
            dec     l
            ld      a,e
            jr      L90D4
            inc     sp
            inc     c
            ld      a,$2A
            scf
            inc     c
            dec     d
            dec     bc
            add     hl,hl
            dec     l
            dec     (hl)
            ld      a,d
            ld      e,b
            ld      e,$33
            rrca
            dec     l
            ld      h,$35
            dec     hl
            ld      a,$21
            rra
            ld      h,(hl)
            add     hl,hl
L90D4:      ld      (hl),$37
            rrca
            add     hl,de
            ld      (hl),e
            ld      c,h
            ld      hl,(L1F37)
            add     hl,de
            ld      h,$35
            dec     hl
            ld      a,$0B
            dec     c
            jr      c,L9118
            dec     l
            dec     (hl)
            ld      a,d
            jr      L9109
            inc     sp
            rrca
            dec     l
            ld      h,(hl)
            dec     (hl)
            dec     hl
            ld      a,$2C
            add     hl,hl
            inc     (hl)
            inc     (hl)
            dec     hl
            dec     a
            dec     e
            ld      hl,(L3736)
            sbc     a,a
            inc     a
            add     hl,hl
            jr      c,L9134
            xor     l
            daa
            ld      (de),a
            ld      a,($3E1E)
            jr      c,L913C
L9109:      inc     c
            cpl
            nop
            ld      e,$1A
            dec     bc
            add     hl,de
            ld      ($AD18),a
            daa
            ld      (de),a
            ld      a,(LB31E)
L9118:      rrca
            dec     l
            dec     (hl)
            inc     (hl)
            dec     hl
            ld      a,$3E
            jr      nz,L90A4
            ld      c,$3A
            dec     hl
            dec     l
            ld      h,$2B
            dec     de
            ld      l,$1F
            dec     c
            ld      hl,(L2A2C)
            ld      (bc),a
            dec     c
            dec     sp
            dec     c
            add     hl,hl
            dec     l
L9134:      inc     sp
            dec     c
            inc     bc
            dec     bc
            dec     c
            inc     c
            inc     sp
            dec     c
L913C:      add     hl,sp
            rra
            ld      a,$83
            ld      d,$0C
            dec     d
            add     hl,bc
            add     hl,hl
            ld      c,$60
            ld      c,$29
            ld      (Disp_Joy_Str),hl
            ld      c,$2B
            inc     a
            add     hl,hl
            add     hl,sp
            dec     e
            ld      d,l
            nop
            ld      hl,$3E2B
            ld      h,$83
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            jr      L917C
            dec     hl
            dec     d
            ld      b,b
            ld      b,b
            ld      l,c
            ld      (L3709),hl
            dec     l
            dec     bc
            add     hl,sp
            inc     c
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            jr      L9194
            ld      c,b
            ld      l,c
            ld      hl,(L270D)
            inc     d
            ld      c,$26
            jr      L91A5
            rra
L917C:      ld      a,$83
            ld      ($151C),hl
            dec     hl
            dec     l
            ld      h,$2B
            cpl
            nop
            dec     c
            ld      e,$39
            ld      h,$2B
            dec     l
            ld      h,$2B
            ld      a,$0E
            add     hl,hl
            add     hl,de
            inc     sp
L9194:      inc     c
            ld      a,$BE
            daa
            dec     c
            rrca
            ld      c,e
            ld      d,d
            dec     bc
            ld      c,$18
            ld      a,$83
            inc     l
            add     a,e
            add     hl,sp
            ld      h,$2B
            dec     l
            ld      h,$2B
            ld      a,$27
            ld      (de),a
            dec     hl
            dec     sp
            ld      e,$3E
            inc     c
            inc     a
            ld      hl,$3E0D
            cpl
            nop
            dec     c
            ld      e,$1B
            ld      (hl),e
            ld      d,h
            inc     e
            dec     hl
            add     hl,hl
            dec     e
            ld      h,$2B
            rra
            dec     h
            ld      b,$09
            add     hl,hl
            rra
            dec     e
            scf
            scf
            ld      e,$3E
            add     a,e
            jr      z,L91FD
            ld      h,$2B
            add     hl,hl
            ld      a,(L211D)
            ld      a,(bc)
            dec     hl
            ld      a,$15
            nop
            add     hl,bc
            add     hl,hl
            ld      e,$2B
            dec     a
            dec     c
            ld      hl,L2B0A
            ld      a,$3C
            ld      hl,(L2A10)
            dec     d
            add     hl,bc
            ld      ($150C),hl
            nop
            add     hl,bc
            add     hl,hl
            ld      (L6125),a
            ld      c,c
            dec     hl
            ld      a,$07
            xor     l
            ld      h,$2B
            add     hl,hl
            ld      a,(L833E)
            rla
            add     hl,hl
            ld      (hl),$37
            rrca
            inc     bc
            ld      a,(de)
            inc     sp
            rra
            ld      hl,(L3B0E)
            dec     c
            dec     e
            dec     hl
            dec     d
            dec     bc
            ld      ($3E1E),hl
            ld      c,$15
            ld      a,(bc)
            ld      (L830F),hl
            ld      c,$23
            dec     d
            add     hl,hl
            ld      hl,(L3338)
            ld      c,$35
            dec     (hl)
            jr      L924F
            ld      a,$83
            dec     e
            dec     l
            inc     sp
            rra
            dec     c
            ld      hl,(L2F38)
            ld      hl,(L2318)
            ld      c,b
            ld      l,c
            ld      hl,(L270D)
            inc     d
            ld      c,$26
            jr      L9266
            inc     bc
            ld      e,$2C
            jr      L924C
            ld      de,L1F32
            ld      a,$2A
            add     a,e
            ld      l,$0D
            ld      e,$03
            inc     c
L924C:      dec     d
            dec     bc
            ld      (L022A),hl
            jr      L9255
            dec     h
            ld      h,$2B
            ld      hl,($140B)
            rra
            dec     h
            dec     sp
            jr      L9261
            add     hl,de
            cpl
            dec     c
L9261:      ld      c,$2C
            inc     bc
            inc     bc
            inc     a
L9266:      rrca
            dec     sp
            dec     c
            dec     e
            ld      l,$1F
            ld      hl,($3E3A)
            add     a,e
            inc     hl
            add     a,e
            dec     c
            ld      d,l
            inc     hl
            scf
            add     hl,hl
            ld      (hl),$37
            scf
            dec     c
            ld      h,$26
            jr      c,L92B2
            ld      hl,($0520)
            rra
            ld      hl,(Text_Radar_Location_Byte_18)
            rrca
            inc     c
            dec     d
            ld      a,(bc)
            ld      (L2F0C),hl
            nop
            ld      e,$1A
            dec     bc
            add     hl,de
            inc     bc
            add     a,e
            ld      d,$0C
            jr      nz,L92C1
            ld      c,$2C
            add     hl,hl
            ld      (hl),$37
            jr      L92BE
            inc     l
            inc     a
            inc     c
            inc     a
            inc     l
            inc     bc
            inc     sp
            inc     e
            ld      b,$01
            dec     c
            ld      a,$23
            ld      (L3434),hl
            dec     hl
            ld      (bc),a
            add     hl,de
L92B2:      ld      e,a
            dec     h
            jr      L931C
            rlca
            inc     sp
            dec     c
            inc     bc
            dec     l
            ld      (L0C1F),a
L92BE:      ld      h,d
            ld      l,b
            rra
L92C1:      daa
            add     hl,de
            ld      hl,(L0C28)
            dec     d
            add     hl,bc
            ld      (L3C03),hl
            ld      a,(L1F2B)
            ld      a,$10
            dec     d
            nop
            add     hl,bc
            add     hl,hl
            jr      L92F5
            jr      nz,L92FA
            daa
            ld      hl,(L1C33)
            ld      b,$01
            dec     c
            ld      a,$22
            add     a,e
            ld      c,$3C
            inc     l
            dec     e
            ld      h,$2B
            dec     l
            dec     (hl)
            ld      h,$2B
            dec     c
            ld      e,$3E
            add     hl,hl
            ld      (hl),$28
            scf
            ld      a,$32
L92F5:      dec     h
            dec     hl
            ld      h,$35
            ld      hl,($3E10)
            jr      c,L9331
            dec     h
            daa
            ld      hl,(L833E)
            ld      (L2983),hl
            inc     (hl)
            inc     (hl)
            dec     hl
            dec     h
            ld      l,$39
            inc     bc
            jr      L933B
            ld      e,$1F
            inc     bc
            ld      e,$3A
            ld      (bc),a
            add     hl,de
            ld      hl,(L2218)
            inc     bc
            ld      hl,(L3728)
            ld      a,$3E
            jr      c,L9354
            dec     h
            daa
            ld      hl,(L833E)
            ld      d,$83
            ld      e,$3C
            inc     l
            dec     h
            ld      a,(L3B3E)
            rrca
            ld      a,(L3C1E)
            inc     l
            dec     h
            ld      a,(L273E)
            dec     c
            ld      hl,($3E28)
            add     a,e
            ld      hl,L0E83
            add     hl,hl
            dec     l
            dec     sp
            dec     hl
            ld      a,$29
            ld      (hl),$28
            dec     d
            dec     hl
            daa
            dec     c
            jr      c,L9381
            dec     l
            ld      h,$2B
            jr      L9379
            dec     hl
L9354:      ld      e,$03
            ld      e,$33
            dec     c
            ld      a,(de)
            ld      (bc),a
            dec     c
            ld      (de),a
            ld      a,$83
            cpl
            add     a,e
            inc     h
            dec     d
            ld      a,$29
            ld      (hl),$28
            add     hl,sp
            dec     a
            ld      hl,(L3629)
            jr      z,L9387
            rla
            ld      e,$1B
            dec     d
            ld      a,(bc)
            ld      ($3E1E),hl
            ld      c,$33
            ld      hl,($0015)
            add     hl,bc
            add     hl,hl
            inc     c
            ld      a,$3E
            jr      c,L93B5
            ld      e,$33
            dec     c
            ld      a,(de)
            ld      (bc),a
L9387:      dec     c
            inc     c
            ld      l,$1F
            ld      hl,($3E3A)
            add     a,e
            dec     de
            add     a,e
            add     hl,sp
            ld      h,$35
            dec     hl
            inc     bc
            ld      c,$3A
            dec     hl
            inc     bc
            inc     e
            inc     h
            dec     hl
            ld      a,$1E
            ld      h,a
            ld      c,l
            ld      a,(Disp_Joy_Str)
            dec     hl
            ld      a,e
            add     hl,bc
            ld      e,$29
            ld      a,$83
            rra
            dec     de
            ld      h,b
            ld      c,e
            ld      h,d
            ld      a,$3E
            add     hl,hl
            inc     (hl)
            inc     (hl)
L93B5:      dec     hl
            rra
            dec     h
            ld      b,$21
            add     hl,hl
            rra
            inc     bc
            ld      c,$28
            scf
            ld      hl,(Disp_Joy_Str)
            inc     sp
            dec     c
            ld      hl,(L0A15)
            ld      ($3E1E),hl
            inc     l
            add     a,e
            inc     c
            dec     d
            nop
            add     hl,bc
            ld      (L2C0E),hl
            inc     a
            rra
            ld      hl,(Disp_Joy_Str)
            dec     hl
            inc     sp
            dec     c
            dec     l
            dec     d
            ld      a,(bc)
            ld      (L1E18),hl
            ld      a,$27
            dec     c
            jr      c,L941A
            dec     l
            ld      h,$2B
            jr      L9412
            dec     hl
            ld      e,$3E
            ld      e,$33
            dec     c
            ld      a,(de)
            ld      (bc),a
            dec     c
            ld      (de),a
            ld      a,$83
            inc     e
            dec     c
            dec     d
            ld      h,e
            ld      (hl),a
            add     hl,hl
            inc     (hl)
            inc     (hl)
            dec     hl
            ld      h,$0D
            jr      L942E
            ld      hl,(L2E10)
            dec     c
            rra
L940A:      dec     bc
            rra
            add     hl,hl
            inc     (hl)
            inc     (hl)
            dec     hl
            ld      e,$2E
L9412:      dec     c
            rra
            ld      a,$24
            add     a,e
            inc     h
            dec     hl
            inc     bc
L941A:      inc     bc
            ld      (L2836),hl
            inc     bc
            add     a,e
            dec     e
            daa
            ld      hl,(L0303)
            ld      hl,(Do_Joy_Jump)
            add     a,e
            rra
            ld      a,(L080F)
            ld      a,(bc)
L942E:      ld      (L030F),hl
            inc     bc
            jr      c,L9467
            inc     bc
            add     a,e
            dec     h
            daa
            ld      hl,(L1F3E)
            jr      z,L9462
            rra
            ld      a,$3E
            dec     d
            inc     hl
            add     hl,bc
            add     hl,hl
            inc     c
            inc     sp
            rra
            ld      hl,(L2F1B)
            rrca
            dec     e
            ld      h,$2B
            inc     e
            dec     d
            ld      hl,(L0D02)
            jr      c,L9488
            dec     l
            dec     a
            jr      L9478
            ld      a,$1B
            add     a,e
            dec     l
            cpl
            ld      a,(L2B15)
            ld      (L2836),hl
            inc     e
            ld      h,$0B
L9467:      inc     d
            ld      hl,(Maze_01_Data_Byte_11)
            dec     d
            ld      a,(bc)
            ld      (L031E),hl
            dec     c
            dec     d
            inc     hl
            jr      z,L94B3
            add     a,e
L9476:      ld      h,(hl)
            adc     a,e
L9478:      add     a,h
            adc     a,e
            pop     bc
            adc     a,e
            sub     $8B
            rst     18H
            adc     a,e
            pop     af
            adc     a,e
            dec     e
            adc     a,h
            ld      a,($3F8C)
            adc     a,l
L9488:      ld      c,(hl)
            adc     a,l
            ld      (hl),a
            adc     a,(hl)
            adc     a,e
            adc     a,(hl)
            sub     (hl)
            adc     a,(hl)
            xor     c
            adc     a,(hl)
            or      d
            adc     a,(hl)
            out     ($8E),a
            jp      p,LFD8E
            adc     a,(hl)
            jr      nz,L942B
            ld      b,c
            adc     a,a
            ld      h,l
            adc     a,a
L94A0:      add     a,e
            adc     a,a
            or      l
            adc     a,a
            ret     z
            adc     a,a
            ret     p
            adc     a,a
            inc     e
            sub     b
            ld      d,l
L94AB:      adc     a,l
            add     hl,hl
            adc     a,l
            adc     a,d
            adc     a,l
            or      l
            adc     a,l
            DB      $dd,$8d
            nop
            adc     a,(hl)
            ld      c,e
            adc     a,(hl)
            inc     h
            adc     a,(hl)
            ld      e,c
            adc     a,h
            ld      a,b
            adc     a,h
            sbc     a,b
            adc     a,h
L94C0:      push    bc
            adc     a,h
            rst     30H
            adc     a,h
            dec     c
            adc     a,l
            ld      a,(hl)
            sub     c
            dec     hl
            sub     b
            ld      b,h
L94CB:      sub     b
            ld      l,e
            sub     b
            sub     e
            sub     b
            or      (hl)
            sub     b
            ret     nc
            sub     b
            jp      p,L1F90
            sub     c
            ld      b,b
            sub     c
            ld      d,a
            sub     c
            and     c
            sub     c
            adc     a,$91
            ld      (hl),e
            adc     a,l
            dec     (hl)
            adc     a,a
            rst     30H
            sub     c
            rst     38H
            sub     c
            rla
            sub     d
            daa
            sub     d
            ld      b,l
            sub     d
            ld      (hl),b
            sub     d
            sub     h
            sub     d
            xor     e
            sub     d
            rst     08H
            sub     d
            and     c
            adc     a,a
            xor     d
            adc     a,a
            ret     po
            sub     d
L94FC:      inc     bc
            sub     e
            ld      h,$93
            dec     a
            sub     e
            ld      e,a
            sub     e
            adc     a,a
            sub     e
            xor     e
            sub     e
            res     2,e
            ret     m
            sub     e
            dec     d
            sub     h
            ld      a,(L5A94)
            sub     h
            or      (hl)
L9513:      adc     a,e
L9514:      add     a,c
            ld      a,(bc)
            add     a,d
            dec     bc
            inc     b
            add     a,c
            ld      a,(bc)
            add     a,d
            inc     c
L951D:      djnz    L94A0
            ld      a,(bc)
            add     a,d
            dec     bc
            inc     b
            add     a,c
            ld      a,(bc)
            add     a,d
            inc     c
            djnz    L94AB
            dec     c
            add     hl,bc
            add     a,d
            ld      c,$04
            add     a,c
            rrca
            add     a,d
            ld      de,L8210
            ld      e,$36
            add     a,c
            dec     l
            add     a,d
            ld      l,$10
            add     a,d
            cpl
            djnz    L94C0
            nop
            add     a,d
            ld      c,(hl)
            ld      (bc),a
            add     a,d
            inc     bc
            inc     b
            add     a,d
            dec     b
            djnz    L94CB
            ld      b,$81
L954C:      rlca
            add     a,d
            ex      af,af'
            scf
            add     a,d
            inc     sp
            ld      (hl),$81
            inc     hl
            add     a,d
            inc     h
            ld      (hl),$82
            daa
            ld      (hl),$82
            dec     h
            ld      (hl),$82
            jr      nc,L9597
            add     a,d
L9562:      ld      sp,L8109
            ld      (P2_Life_Icon_Primary_Byte_20),a
L9568:      add     a,d
            ld      (de),a
            ld      (hl),$81
            inc     de
            add     a,c
L956E:      inc     d
            add     a,d
            dec     d
            ld      b,b
            add     a,d
            scf
L9574:      ld      h,$82
            inc     (hl)
            djnz    L94FC
            add     hl,bc
L957A:      ld      (L8210),hl
            dec     (hl)
            scf
            add     a,d
            ld      a,(de)
            ld      (hl),$81
            dec     de
            add     a,d
            inc     e
            ld      (hl),$82
            ld      bc,L8236
            rra
            add     hl,bc
            add     a,d
            add     hl,bc
            jr      nz,L9513
            ld      hl,L8236
            jr      z,L95CC
            add     a,e
L9597:      ld      d,$04
            djnz    L951D
            rla
            scf
            add     a,d
            jr      L95D7
            add     a,d
            inc     b
            add     hl,de
            add     a,d
            add     hl,hl
            scf
            add     a,c
            ld      hl,(L2B82)
            ld      (hl),$81
            inc     l
            add     a,e
            jr      c,L95B4
            djnz    L9535
            add     hl,sp
            scf
L95B4:      ld      (hl),$82
            ld      a,(L8210)
            dec     sp
            ld      (hl),$82
            inc     a
            scf
            add     a,d
            add     hl,bc
            dec     a
            add     a,d
            ld      a,$10
            add     a,e
            ccf
            inc     (hl)
            djnz    L954C
            ld      b,c
            ld      b,d
            ld      (hl),$83
            ld      b,c
            ld      b,e
            ld      (hl),$83
            ld      b,h
            ld      (bc),a
            ld      (hl),$81
            ld      b,l
            add     a,d
L95D7:      ld      b,(hl)
            ld      (hl),$82
            ld      b,a
            ld      (hl),$82
            ld      c,b
            djnz    L9562
            ld      c,c
            ld      (hl),$82
            ld      c,d
            djnz    L9568
            ld      c,e
            djnz    L956B
            ld      c,h
            djnz    L956E
            ld      c,l
            ld      (hl),$82
            ld      c,d
            djnz    L9574
            ld      c,e
            ld      (hl),$82
            ld      c,h
            djnz    L957A
            ld      c,l
            ld      (hl),$00

            DB      $ff,$ff,$ff,$ff,$ff
;*******************************************************************************
; GARWOR_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_1:
        .DB      $00,$00,$00,$03,$C0 ; . . . . . . . . . . . . . . . 3 3 . . .
        .DB      $00,$02,$AA,$00,$FC ; . . . . . . . 2 2 2 2 2 . . . . 3 3 3 .
        .DB      $00,$0A,$AA,$80,$3C ; . . . . . . 2 2 2 2 2 2 2 . . . . 3 3 .
        .DB      $00,$AA,$0A,$A0,$08 ; . . . . 2 2 2 2 . . 2 2 2 2 . . . . 2 .
        .DB      $0A,$AA,$4A,$A8,$08 ; . . 2 2 2 2 2 2 1 . 2 2 2 2 2 . . . 2 .
        .DB      $0A,$AA,$AA,$AA,$08 ; . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . 2 .
        .DB      $00,$BB,$AA,$AA,$08 ; . . . . 2 3 2 3 2 2 2 2 2 2 2 2 . . 2 .
        .DB      $0F,$FF,$AA,$AA,$88 ; . . 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $32,$EE,$8A,$AA,$88 ; . 3 . 2 3 2 3 2 2 . 2 2 2 2 2 2 2 . 2 .
        .DB      $00,$AA,$2A,$AA,$88 ; . . . . 2 2 2 2 . 2 2 2 2 2 2 2 2 . 2 .
        .DB      $00,$00,$2A,$AA,$A8 ; . . . . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$00,$AA,$AA,$A8 ; . . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$0A,$AA,$AA,$A0 ; . . . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$20,$2A,$AA,$80 ; . . . . . 2 . . . 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$00,$0A,$A8,$00 ; . . . . . . . . . . 2 2 2 2 2 . . . . .
        .DB      $00,$00,$0A,$82,$00 ; . . . . . . . . . . 2 2 2 . . 2 . . . .
        .DB      $00,$00,$0A,$02,$00 ; . . . . . . . . . . 2 2 . . . 2 . . . .
        .DB      $00,$00,$A8,$0A,$00 ; . . . . . . . . 2 2 2 . . . 2 2 . . . .

;*******************************************************************************
; GARWOR_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_2:
        .DB      $00,$0A,$A8,$00,$3C ; . . . . . . 2 2 2 2 2 . . . . . . 3 3 .
        .DB      $00,$2A,$A8,$03,$F0 ; . . . . . 2 2 2 2 2 2 . . . . 3 3 3 . .
        .DB      $02,$A8,$2A,$03,$C0 ; . . . 2 2 2 2 . . 2 2 2 . . . 3 3 . . .
        .DB      $2A,$A9,$2A,$82,$00 ; . 2 2 2 2 2 2 1 . 2 2 2 2 . . 2 . . . .
        .DB      $2A,$AA,$AA,$82,$00 ; . 2 2 2 2 2 2 2 2 2 2 2 2 . . 2 . . . .
        .DB      $02,$EE,$EA,$A2,$A8 ; . . . 2 3 2 3 2 3 2 2 2 2 2 . 2 2 2 2 .
        .DB      $03,$FF,$EA,$A0,$08 ; . . . 3 3 3 3 3 3 2 2 2 2 2 . . . . 2 .
        .DB      $0B,$BB,$AA,$A8,$08 ; . . 2 3 2 3 2 3 2 2 2 2 2 2 2 . . . 2 .
        .DB      $02,$AA,$AA,$AA,$28 ; . . . 2 2 2 2 2 2 2 2 2 2 2 2 2 . 2 2 .
        .DB      $00,$02,$AA,$AA,$20 ; . . . . . . . 2 2 2 2 2 2 2 2 2 . 2 . .
        .DB      $00,$02,$AA,$AA,$A0 ; . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$02,$AA,$AA,$A0 ; . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$08,$AA,$AA,$80 ; . . . . . . 2 . 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$20,$AA,$AA,$00 ; . . . . . 2 . . 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$00,$2A,$A0,$00 ; . . . . . . . . . 2 2 2 2 2 . . . . . .
        .DB      $00,$00,$0A,$0A,$80 ; . . . . . . . . . . 2 2 . . 2 2 2 . . .
        .DB      $00,$00,$02,$00,$80 ; . . . . . . . . . . . 2 . . . . 2 . . .
        .DB      $00,$00,$2A,$00,$00 ; . . . . . . . . . 2 2 2 . . . . . . . .

;*******************************************************************************
; GARWOR_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_3:
        .DB      $00,$02,$AA,$00,$FC ; . . . . . . . 2 2 2 2 2 . . . . 3 3 3 .
        .DB      $00,$0A,$AA,$03,$F0 ; . . . . . . 2 2 2 2 2 2 . . . 3 3 3 . .
        .DB      $00,$AA,$0A,$83,$F0 ; . . . . 2 2 2 2 . . 2 2 2 . . 3 3 3 . .
        .DB      $0A,$AA,$4A,$A0,$80 ; . . 2 2 2 2 2 2 1 . 2 2 2 2 . . 2 . . .
        .DB      $0A,$AA,$AA,$A0,$A8 ; . . 2 2 2 2 2 2 2 2 2 2 2 2 . . 2 2 2 .
        .DB      $00,$BB,$BA,$A8,$08 ; . . . . 2 3 2 3 2 3 2 2 2 2 2 . . . 2 .
        .DB      $0F,$FF,$FA,$A8,$08 ; . . 3 3 3 3 3 3 3 3 2 2 2 2 2 . . . 2 .
        .DB      $32,$EE,$EA,$AA,$08 ; . 3 . 2 3 2 3 2 3 2 2 2 2 2 2 2 . . 2 .
        .DB      $00,$AA,$AA,$AA,$08 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . 2 .
        .DB      $00,$00,$AA,$AA,$88 ; . . . . . . . . 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $00,$00,$AA,$AA,$A8 ; . . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$02,$AA,$AA,$A8 ; . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$00,$2A,$AA,$A0 ; . . . . . . . . . 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$00,$2A,$A8,$00 ; . . . . . . . . . 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$A0,$A0,$00 ; . . . . . . . . 2 2 . . 2 2 . . . . . .
        .DB      $00,$00,$28,$20,$00 ; . . . . . . . . . 2 2 . . 2 . . . . . .
        .DB      $00,$00,$08,$A0,$00 ; . . . . . . . . . . 2 . 2 2 . . . . . .

;*******************************************************************************
; GARWOR_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_1_UP:
        .DB      $00,$00,$0C,$00,$00 ; . . . . . . . . . . 3 . . . . . . . . .
        .DB      $00,$00,$03,$28,$00 ; . . . . . . . . . . . 3 . 2 2 . . . . .
        .DB      $00,$00,$0B,$28,$00 ; . . . . . . . . . . 2 3 . 2 2 . . . . .
        .DB      $00,$00,$2F,$AA,$00 ; . . . . . . . . . 2 3 3 2 2 2 2 . . . .
        .DB      $00,$20,$2B,$EA,$00 ; . . . . . 2 . . . 2 2 3 3 2 2 2 . . . .
        .DB      $00,$08,$2F,$AA,$80 ; . . . . . . 2 . . 2 3 3 2 2 2 2 2 . . .
        .DB      $00,$08,$2B,$EA,$A0 ; . . . . . . 2 . . 2 2 3 3 2 2 2 2 2 . .
        .DB      $20,$0A,$0A,$A4,$A0 ; . 2 . . . . 2 2 . . 2 2 2 2 1 . 2 2 . .
        .DB      $20,$2A,$A2,$A0,$A0 ; . 2 . . . 2 2 2 2 2 . 2 2 2 . . 2 2 . .
        .DB      $2A,$AA,$AA,$AA,$A0 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $0A,$AA,$AA,$AA,$A0 ; . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $02,$AA,$AA,$AA,$80 ; . . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $20,$AA,$AA,$A8,$00 ; . 2 . . 2 2 2 2 2 2 2 2 2 2 2 . . . . .
        .DB      $2A,$2A,$AA,$A0,$0C ; . 2 2 2 . 2 2 2 2 2 2 2 2 2 . . . . 3 .
        .DB      $00,$2A,$AA,$00,$3C ; . . . . . 2 2 2 2 2 2 2 . . . . . 3 3 .
        .DB      $00,$0A,$80,$00,$F0 ; . . . . . . 2 2 2 . . . . . . . 3 3 . .
        .DB      $00,$02,$AA,$AA,$F0 ; . . . . . . . 2 2 2 2 2 2 2 2 2 3 3 . .

;*******************************************************************************
; GARWOR_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_2_UP:
        .DB      $00,$00,$00,$0A,$00 ; . . . . . . . . . . . . . . 2 2 . . . .
        .DB      $00,$00,$02,$0A,$00 ; . . . . . . . . . . . 2 . . 2 2 . . . .
        .DB      $00,$00,$0B,$EA,$80 ; . . . . . . . . . . 2 3 3 2 2 2 2 . . .
        .DB      $00,$00,$0A,$FA,$80 ; . . . . . . . . . . 2 2 3 3 2 2 2 . . .
        .DB      $00,$20,$0B,$EA,$A0 ; . . . . . 2 . . . . 2 3 3 2 2 2 2 2 . .
        .DB      $00,$08,$0A,$FA,$A8 ; . . . . . . 2 . . . 2 2 3 3 2 2 2 2 2 .
        .DB      $00,$02,$AB,$E9,$28 ; . . . . . . . 2 2 2 2 3 3 2 2 1 . 2 2 .
        .DB      $00,$2A,$AA,$F8,$28 ; . . . . . 2 2 2 2 2 2 2 3 3 2 . . 2 2 .
        .DB      $20,$AA,$AA,$AA,$A8 ; . 2 . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $22,$AA,$AA,$AA,$A8 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $2A,$AA,$AA,$AA,$80 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$AA,$AA,$A0,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 . . . . . .
        .DB      $02,$2A,$AA,$00,$00 ; . . . 2 . 2 2 2 2 2 2 2 . . . . . . . .
        .DB      $02,$2A,$A8,$2A,$F0 ; . . . 2 . 2 2 2 2 2 2 . . 2 2 2 3 3 . .
        .DB      $0A,$0A,$80,$20,$F0 ; . . 2 2 . . 2 2 2 . . . . 2 . . 3 3 . .
        .DB      $00,$02,$A8,$20,$3C ; . . . . . . . 2 2 2 2 . . 2 . . . 3 3 .
        .DB      $00,$00,$0A,$A0,$0C ; . . . . . . . . . . 2 2 2 2 . . . . 3 .


; ----> Block of 62 $ff

            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
            DB      $ff,$ff
;*******************************************************************************
; WORRIOR_BLUE_FIRE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_1_UP:
        .DB      $00,$00,$0E,$30,$00 ; . . . . . . . . . . 3 2 . 3 . . . . . .
        .DB      $00,$00,$0A,$B0,$00 ; . . . . . . . . . . 2 2 2 3 . . . . . .
        .DB      $00,$00,$0A,$88,$00 ; . . . . . . . . . . 2 2 2 . 2 . . . . .
        .DB      $00,$00,$02,$00,$00 ; . . . . . . . . . . . 2 . . . . . . . .
        .DB      $00,$10,$03,$00,$00 ; . . . . . 1 . . . . . 3 . . . . . . . .
        .DB      $01,$40,$05,$40,$00 ; . . . 1 1 . . . . . 1 1 1 . . . . . . .
        .DB      $05,$00,$03,$00,$00 ; . . 1 1 . . . . . . . 3 . . . . . . . .
        .DB      $05,$40,$05,$40,$00 ; . . 1 1 1 . . . . . 1 1 1 . . . . . . .
        .DB      $05,$50,$03,$00,$00 ; . . 1 1 1 1 . . . . . 3 . . . . . . . .
        .DB      $00,$54,$03,$00,$00 ; . . . . 1 1 1 . . . . 3 . . . . . . . .
        .DB      $00,$15,$0F,$01,$00 ; . . . . . 1 1 1 . . 3 3 . . . 1 . . . .
        .DB      $00,$05,$5F,$41,$30 ; . . . . . . 1 1 1 1 3 3 1 . . 1 . 3 . .
        .DB      $10,$55,$5F,$55,$04 ; . 1 . . 1 1 1 1 1 1 3 3 1 1 1 1 . . 1 .
        .DB      $11,$55,$5F,$75,$54 ; . 1 . 1 1 1 1 1 1 1 3 3 1 3 1 1 1 1 1 .
        .DB      $15,$55,$5F,$F5,$54 ; . 1 1 1 1 1 1 1 1 1 3 3 3 3 1 1 1 1 1 .
        .DB      $15,$05,$57,$D0,$50 ; . 1 1 1 . . 1 1 1 1 1 3 3 1 . . 1 1 . .
        .DB      $00,$00,$55,$54,$00 ; . . . . . . . . 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$00,$55,$54,$30 ; . . . . . . . . 1 1 1 1 1 1 1 . . 3 . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_2_UP:
        .DB      $00,$00,$00,$0C,$CC ; . . . . . . . . . . . . . . 3 . 3 . 3 .
        .DB      $00,$00,$0C,$02,$B0 ; . . . . . . . . . . 3 . . . . 2 2 3 . .
        .DB      $00,$00,$00,$02,$AC ; . . . . . . . . . . . . . . . 2 2 2 3 .
        .DB      $00,$01,$00,$82,$A0 ; . . . . . . . 1 . . . . 2 . . 2 2 2 . .
        .DB      $00,$14,$00,$02,$80 ; . . . . . 1 1 . . . . . . . . 2 2 . . .
        .DB      $00,$50,$00,$1C,$00 ; . . . . 1 1 . . . . . . . 1 3 . . . . .
        .DB      $00,$50,$00,$74,$00 ; . . . . 1 1 . . . . . . 1 3 1 . . . . .
        .DB      $00,$14,$00,$D0,$00 ; . . . . . 1 1 . . . . . 3 1 . . . . . .
        .DB      $00,$15,$03,$C0,$00 ; . . . . . 1 1 1 . . . 3 3 . . . . . . .
        .DB      $00,$05,$0F,$00,$00 ; . . . . . . 1 1 . . 3 3 . . . . . . . .
        .DB      $10,$05,$0F,$00,$00 ; . 1 . . . . 1 1 . . 3 3 . . . . . . . .
        .DB      $10,$05,$7C,$01,$00 ; . 1 . . . . 1 1 1 3 3 . . . . 1 . . . .
        .DB      $10,$05,$7D,$01,$30 ; . 1 . . . . 1 1 1 3 3 1 . . . 1 . 3 . .
        .DB      $15,$05,$7D,$45,$04 ; . 1 1 1 . . 1 1 1 3 3 1 1 . 1 1 . . 1 .
        .DB      $15,$55,$7F,$55,$54 ; . 1 1 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 1 .
        .DB      $05,$55,$5F,$D5,$54 ; . . 1 1 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 .
        .DB      $00,$55,$57,$54,$50 ; . . . . 1 1 1 1 1 1 1 3 1 1 1 . 1 1 . .
        .DB      $00,$00,$55,$50,$30 ; . . . . . . . . 1 1 1 1 1 1 . . . 3 . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_3_UP:
        .DB      $00,$00,$00,$30,$80 ; . . . . . . . . . . . . . 3 . . 2 . . .
        .DB      $00,$00,$00,$C8,$0C ; . . . . . . . . . . . . 3 . 2 . . . 3 .
        .DB      $00,$00,$00,$2A,$C0 ; . . . . . . . . . . . . . 2 2 2 3 . . .
        .DB      $00,$00,$00,$2A,$00 ; . . . . . . . . . . . . . 2 2 2 . . . .
        .DB      $00,$04,$00,$28,$00 ; . . . . . . 1 . . . . . . 2 2 . . . . .
        .DB      $00,$50,$01,$C0,$08 ; . . . . 1 1 . . . . . 1 3 . . . . . 2 .
        .DB      $01,$40,$03,$43,$00 ; . . . 1 1 . . . . . . 3 1 . . 3 . . . .
        .DB      $01,$50,$0F,$C0,$00 ; . . . 1 1 1 . . . . 3 3 3 . . . . . . .
        .DB      $00,$54,$0F,$00,$00 ; . . . . 1 1 1 . . . 3 3 . . . . . . . .
        .DB      $00,$15,$0F,$00,$00 ; . . . . . 1 1 1 . . 3 3 . . . . . . . .
        .DB      $10,$05,$3F,$00,$00 ; . 1 . . . . 1 1 . 3 3 3 . . . . . . . .
        .DB      $10,$05,$7C,$01,$00 ; . 1 . . . . 1 1 1 3 3 . . . . 1 . . . .
        .DB      $10,$05,$7D,$41,$30 ; . 1 . . . . 1 1 1 3 3 1 1 . . 1 . 3 . .
        .DB      $15,$55,$7D,$55,$04 ; . 1 1 1 1 1 1 1 1 3 3 1 1 1 1 1 . . 1 .
        .DB      $15,$55,$7F,$55,$54 ; . 1 1 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 1 .
        .DB      $00,$55,$5F,$D5,$54 ; . . . . 1 1 1 1 1 1 3 3 3 1 1 1 1 1 1 .
        .DB      $00,$00,$57,$50,$50 ; . . . . . . . . 1 1 1 3 1 1 . . 1 1 . .
        .DB      $00,$00,$55,$54,$30 ; . . . . . . . . 1 1 1 1 1 1 1 . . 3 . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_4_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_4_UP:
        .DB      $00,$00,$0E,$30,$00 ; . . . . . . . . . . 3 2 . 3 . . . . . .
        .DB      $00,$00,$0A,$B0,$00 ; . . . . . . . . . . 2 2 2 3 . . . . . .
        .DB      $00,$00,$0A,$88,$20 ; . . . . . . . . . . 2 2 2 . 2 . . 2 . .
        .DB      $00,$00,$02,$00,$00 ; . . . . . . . . . . . 2 . . . . . . . .
        .DB      $00,$00,$03,$00,$C0 ; . . . . . . . . . . . 3 . . . . 3 . . .
        .DB      $00,$40,$05,$40,$00 ; . . . . 1 . . . . . 1 1 1 . . . . . . .
        .DB      $01,$40,$03,$00,$00 ; . . . 1 1 . . . . . . 3 . . . . . . . .
        .DB      $05,$00,$05,$40,$00 ; . . 1 1 . . . . . . 1 1 1 . . . . . . .
        .DB      $05,$50,$03,$00,$00 ; . . 1 1 1 1 . . . . . 3 . . . . . . . .
        .DB      $00,$55,$03,$00,$00 ; . . . . 1 1 1 1 . . . 3 . . . . . . . .
        .DB      $00,$15,$0F,$01,$00 ; . . . . . 1 1 1 . . 3 3 . . . 1 . . . .
        .DB      $00,$05,$5F,$41,$30 ; . . . . . . 1 1 1 1 3 3 1 . . 1 . 3 . .
        .DB      $10,$05,$5F,$55,$04 ; . 1 . . . . 1 1 1 1 3 3 1 1 1 1 . . 1 .
        .DB      $10,$55,$5F,$75,$54 ; . 1 . . 1 1 1 1 1 1 3 3 1 3 1 1 1 1 1 .
        .DB      $15,$55,$5F,$F5,$54 ; . 1 1 1 1 1 1 1 1 1 3 3 3 3 1 1 1 1 1 .
        .DB      $15,$55,$57,$D0,$50 ; . 1 1 1 1 1 1 1 1 1 1 3 3 1 . . 1 1 . .
        .DB      $00,$00,$55,$54,$00 ; . . . . . . . . 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$00,$55,$54,$30 ; . . . . . . . . 1 1 1 1 1 1 1 . . 3 . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_1:
        .DB      $00,$00,$00,$15,$00 ; . . . . . . . . . . . . . 1 1 1 . . . .
        .DB      $00,$00,$00,$C5,$4C ; . . . . . . . . . . . . 3 . 1 1 1 . 3 .
        .DB      $00,$00,$00,$05,$40 ; . . . . . . . . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$01,$55,$00 ; . . . . . . . . . . . 1 1 1 1 1 . . . .
        .DB      $02,$00,$00,$15,$14 ; . . . 2 . . . . . . . . . 1 1 1 . 1 1 .
        .DB      $3C,$00,$00,$1F,$54 ; . 3 3 . . . . . . . . . . 1 3 3 1 1 1 .
        .DB      $0A,$04,$40,$57,$D4 ; . . 2 2 . . 1 . 1 . . . 1 1 1 3 3 1 1 .
        .DB      $2A,$B7,$7F,$FF,$D4 ; . 2 2 2 2 3 1 3 1 3 3 3 3 3 3 3 3 1 1 .
        .DB      $3A,$04,$43,$FF,$54 ; . 3 2 2 . . 1 . 1 . . 3 3 3 3 3 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$01,$55,$40 ; . . . . . . . . . . . 1 1 1 1 1 1 . . .
        .DB      $00,$00,$05,$55,$40 ; . . . . . . . . . . 1 1 1 1 1 1 1 . . .
        .DB      $00,$10,$15,$15,$00 ; . . . . . 1 . . . 1 1 1 . 1 1 1 . . . .
        .DB      $00,$04,$54,$15,$00 ; . . . . . . 1 . 1 1 1 . . 1 1 1 . . . .
        .DB      $00,$05,$50,$05,$40 ; . . . . . . 1 1 1 1 . . . . 1 1 1 . . .
        .DB      $00,$01,$40,$01,$40 ; . . . . . . . 1 1 . . . . . . 1 1 . . .
        .DB      $00,$00,$00,$15,$40 ; . . . . . . . . . . . . . 1 1 1 1 . . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_2:
        .DB      $33,$00,$00,$05,$40 ; . 3 . 3 . . . . . . . . . . 1 1 1 . . .
        .DB      $0E,$80,$00,$31,$5C ; . . 3 2 2 . . . . . . . . 3 . 1 1 1 3 .
        .DB      $3A,$A0,$00,$01,$50 ; . 3 2 2 2 2 . . . . . . . . . 1 1 1 . .
        .DB      $0A,$A0,$00,$55,$40 ; . . 2 2 2 2 . . . . . . 1 1 1 1 1 . . .
        .DB      $30,$0D,$00,$05,$50 ; . 3 . . . . 3 1 . . . . . . 1 1 1 1 . .
        .DB      $00,$07,$40,$01,$54 ; . . . . . . 1 3 1 . . . . . . 1 1 1 1 .
        .DB      $00,$81,$F0,$05,$D4 ; . . . . 2 . . 1 3 3 . . . . 1 1 3 1 1 .
        .DB      $00,$00,$3F,$17,$F4 ; . . . . . . . . . 3 3 3 . 1 1 3 3 3 1 .
        .DB      $0C,$00,$0F,$FF,$D4 ; . . 3 . . . . . . . 3 3 3 3 3 3 3 1 1 .
        .DB      $00,$00,$00,$FF,$54 ; . . . . . . . . . . . . 3 3 3 3 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$40,$15,$55,$50 ; . . . . 1 . . . . 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$10,$55,$55,$50 ; . . . . . 1 . . 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$15,$50,$01,$50 ; . . . . . 1 1 1 1 1 . . . . . 1 1 1 . .
        .DB      $00,$05,$00,$01,$50 ; . . . . . . 1 1 . . . . . . . 1 1 1 . .
        .DB      $00,$00,$00,$05,$40 ; . . . . . . . . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$00,$05,$40 ; . . . . . . . . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$01,$55,$00 ; . . . . . . . . . . . 1 1 1 1 1 . . . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_3:
        .DB      $0C,$08,$00,$05,$40 ; . . 3 . . . 2 . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$00,$31,$5C ; . . . . . . . . . . . . . 3 . 1 1 1 3 .
        .DB      $23,$00,$00,$01,$50 ; . 2 . 3 . . . . . . . . . . . 1 1 1 . .
        .DB      $02,$83,$00,$55,$40 ; . . . 2 2 . . 3 . . . . 1 1 1 1 1 . . .
        .DB      $0A,$A0,$00,$05,$44 ; . . 2 2 2 2 . . . . . . . . 1 1 1 . 1 .
        .DB      $32,$A0,$00,$05,$54 ; . 3 . 2 2 2 . . . . . . . . 1 1 1 1 1 .
        .DB      $0C,$0D,$C0,$15,$D4 ; . . 3 . . . 3 1 3 . . . . 1 1 1 3 1 1 .
        .DB      $00,$07,$FF,$17,$F4 ; . . . . . . 1 3 3 3 3 3 . 1 1 3 3 3 1 .
        .DB      $00,$00,$FF,$FF,$D4 ; . . . . . . . . 3 3 3 3 3 3 3 3 3 1 1 .
        .DB      $00,$00,$03,$FF,$54 ; . . . . . . . . . . . 3 3 3 3 3 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$05,$55,$40 ; . . . . . . . . . . 1 1 1 1 1 1 1 . . .
        .DB      $00,$10,$15,$55,$40 ; . . . . . 1 . . . 1 1 1 1 1 1 1 1 . . .
        .DB      $00,$04,$54,$05,$40 ; . . . . . . 1 . 1 1 1 . . . 1 1 1 . . .
        .DB      $00,$05,$50,$05,$40 ; . . . . . . 1 1 1 1 . . . . 1 1 1 . . .
        .DB      $00,$01,$40,$05,$00 ; . . . . . . . 1 1 . . . . . 1 1 . . . .
        .DB      $00,$00,$00,$05,$00 ; . . . . . . . . . . . . . . 1 1 . . . .
        .DB      $00,$00,$01,$55,$00 ; . . . . . . . . . . . 1 1 1 1 1 . . . .

;*******************************************************************************
; WORRIOR_BLUE_FIRE_4
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_BLUE_FIRE_4:
        .DB      $00,$00,$00,$15,$00 ; . . . . . . . . . . . . . 1 1 1 . . . .
        .DB      $02,$00,$00,$C5,$4C ; . . . 2 . . . . . . . . 3 . 1 1 1 . 3 .
        .DB      $00,$30,$00,$05,$40 ; . . . . . 3 . . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$01,$55,$00 ; . . . . . . . . . . . 1 1 1 1 1 . . . .
        .DB      $02,$00,$00,$15,$14 ; . . . 2 . . . . . . . . . 1 1 1 . 1 1 .
        .DB      $3C,$00,$00,$1F,$54 ; . 3 3 . . . . . . . . . . 1 3 3 1 1 1 .
        .DB      $0A,$04,$40,$57,$D4 ; . . 2 2 . . 1 . 1 . . . 1 1 1 3 3 1 1 .
        .DB      $2A,$B7,$7F,$FF,$D4 ; . 2 2 2 2 3 1 3 1 3 3 3 3 3 3 3 3 1 1 .
        .DB      $3A,$04,$43,$FF,$54 ; . 3 2 2 . . 1 . 1 . . 3 3 3 3 3 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$00,$55,$54 ; . . . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $00,$00,$05,$55,$40 ; . . . . . . . . . . 1 1 1 1 1 1 1 . . .
        .DB      $00,$00,$05,$55,$40 ; . . . . . . . . . . 1 1 1 1 1 1 1 . . .
        .DB      $00,$00,$15,$05,$40 ; . . . . . . . . . 1 1 1 . . 1 1 1 . . .
        .DB      $00,$05,$14,$05,$40 ; . . . . . . 1 1 . 1 1 . . . 1 1 1 . . .
        .DB      $00,$01,$50,$01,$40 ; . . . . . . . 1 1 1 . . . . . 1 1 . . .
        .DB      $00,$00,$50,$01,$40 ; . . . . . . . . 1 1 . . . . . 1 1 . . .
        .DB      $00,$00,$00,$15,$40 ; . . . . . . . . . . . . . 1 1 1 1 . . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_1_UP:
        .DB      $00,$00,$0E,$30,$00 ; . . . . . . . . . . 3 2 . 3 . . . . . .
        .DB      $00,$00,$0A,$B0,$00 ; . . . . . . . . . . 2 2 2 3 . . . . . .
        .DB      $00,$00,$0A,$88,$00 ; . . . . . . . . . . 2 2 2 . 2 . . . . .
        .DB      $00,$00,$02,$00,$00 ; . . . . . . . . . . . 2 . . . . . . . .
        .DB      $00,$20,$03,$00,$00 ; . . . . . 2 . . . . . 3 . . . . . . . .
        .DB      $02,$80,$0A,$80,$00 ; . . . 2 2 . . . . . 2 2 2 . . . . . . .
        .DB      $0A,$00,$03,$00,$00 ; . . 2 2 . . . . . . . 3 . . . . . . . .
        .DB      $0A,$80,$0A,$80,$00 ; . . 2 2 2 . . . . . 2 2 2 . . . . . . .
        .DB      $0A,$A0,$03,$00,$00 ; . . 2 2 2 2 . . . . . 3 . . . . . . . .
        .DB      $00,$A8,$03,$00,$00 ; . . . . 2 2 2 . . . . 3 . . . . . . . .
        .DB      $00,$2A,$0F,$02,$00 ; . . . . . 2 2 2 . . 3 3 . . . 2 . . . .
        .DB      $00,$0A,$AF,$82,$30 ; . . . . . . 2 2 2 2 3 3 2 . . 2 . 3 . .
        .DB      $20,$AA,$AF,$AA,$08 ; . 2 . . 2 2 2 2 2 2 3 3 2 2 2 2 . . 2 .
        .DB      $22,$AA,$AF,$BA,$A8 ; . 2 . 2 2 2 2 2 2 2 3 3 2 3 2 2 2 2 2 .
        .DB      $2A,$AA,$AF,$FA,$A8 ; . 2 2 2 2 2 2 2 2 2 3 3 3 3 2 2 2 2 2 .
        .DB      $2A,$0A,$AB,$E0,$A0 ; . 2 2 2 . . 2 2 2 2 2 3 3 2 . . 2 2 . .
        .DB      $00,$00,$AA,$A8,$00 ; . . . . . . . . 2 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$AA,$A8,$30 ; . . . . . . . . 2 2 2 2 2 2 2 . . 3 . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_2_UP:
        .DB      $00,$00,$00,$0C,$CC ; . . . . . . . . . . . . . . 3 . 3 . 3 .
        .DB      $00,$00,$0C,$02,$B0 ; . . . . . . . . . . 3 . . . . 2 2 3 . .
        .DB      $00,$00,$00,$02,$AC ; . . . . . . . . . . . . . . . 2 2 2 3 .
        .DB      $00,$02,$00,$42,$A0 ; . . . . . . . 2 . . . . 1 . . 2 2 2 . .
        .DB      $00,$28,$00,$02,$80 ; . . . . . 2 2 . . . . . . . . 2 2 . . .
        .DB      $00,$A0,$00,$2C,$00 ; . . . . 2 2 . . . . . . . 2 3 . . . . .
        .DB      $00,$A0,$00,$B8,$04 ; . . . . 2 2 . . . . . . 2 3 2 . . . 1 .
        .DB      $00,$28,$00,$E0,$00 ; . . . . . 2 2 . . . . . 3 2 . . . . . .
        .DB      $00,$2A,$03,$C0,$00 ; . . . . . 2 2 2 . . . 3 3 . . . . . . .
        .DB      $00,$0A,$0F,$00,$00 ; . . . . . . 2 2 . . 3 3 . . . . . . . .
        .DB      $20,$0A,$0F,$00,$00 ; . 2 . . . . 2 2 . . 3 3 . . . . . . . .
        .DB      $20,$0A,$BC,$02,$00 ; . 2 . . . . 2 2 2 3 3 . . . . 2 . . . .
        .DB      $20,$0A,$BE,$02,$30 ; . 2 . . . . 2 2 2 3 3 2 . . . 2 . 3 . .
        .DB      $2A,$0A,$BE,$8A,$08 ; . 2 2 2 . . 2 2 2 3 3 2 2 . 2 2 . . 2 .
        .DB      $2A,$AA,$BF,$AA,$A8 ; . 2 2 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 2 .
        .DB      $0A,$AA,$AF,$EA,$A8 ; . . 2 2 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 .
        .DB      $00,$AA,$AB,$A8,$A0 ; . . . . 2 2 2 2 2 2 2 3 2 2 2 . 2 2 . .
        .DB      $00,$00,$AA,$A0,$30 ; . . . . . . . . 2 2 2 2 2 2 . . . 3 . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_3_UP:
        .DB      $00,$00,$00,$30,$80 ; . . . . . . . . . . . . . 3 . . 2 . . .
        .DB      $00,$00,$00,$48,$04 ; . . . . . . . . . . . . 1 . 2 . . . 1 .
        .DB      $00,$00,$00,$2A,$C0 ; . . . . . . . . . . . . . 2 2 2 3 . . .
        .DB      $00,$00,$00,$2A,$00 ; . . . . . . . . . . . . . 2 2 2 . . . .
        .DB      $00,$08,$00,$28,$00 ; . . . . . . 2 . . . . . . 2 2 . . . . .
        .DB      $00,$A0,$02,$C0,$08 ; . . . . 2 2 . . . . . 2 3 . . . . . 2 .
        .DB      $02,$80,$03,$83,$00 ; . . . 2 2 . . . . . . 3 2 . . 3 . . . .
        .DB      $02,$A0,$0F,$C0,$00 ; . . . 2 2 2 . . . . 3 3 3 . . . . . . .
        .DB      $00,$A8,$0F,$00,$00 ; . . . . 2 2 2 . . . 3 3 . . . . . . . .
        .DB      $00,$2A,$0F,$00,$00 ; . . . . . 2 2 2 . . 3 3 . . . . . . . .
        .DB      $20,$0A,$3F,$00,$00 ; . 2 . . . . 2 2 . 3 3 3 . . . . . . . .
        .DB      $20,$0A,$BC,$02,$00 ; . 2 . . . . 2 2 2 3 3 . . . . 2 . . . .
        .DB      $20,$0A,$BE,$82,$30 ; . 2 . . . . 2 2 2 3 3 2 2 . . 2 . 3 . .
        .DB      $2A,$AA,$BE,$AA,$08 ; . 2 2 2 2 2 2 2 2 3 3 2 2 2 2 2 . . 2 .
        .DB      $2A,$AA,$BF,$AA,$A8 ; . 2 2 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 2 .
        .DB      $00,$AA,$AF,$EA,$A8 ; . . . . 2 2 2 2 2 2 3 3 3 2 2 2 2 2 2 .
        .DB      $00,$00,$AB,$A0,$A0 ; . . . . . . . . 2 2 2 3 2 2 . . 2 2 . .
        .DB      $00,$00,$AA,$A8,$30 ; . . . . . . . . 2 2 2 2 2 2 2 . . 3 . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_4_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_4_UP:
        .DB      $00,$00,$0E,$30,$00 ; . . . . . . . . . . 3 2 . 3 . . . . . .
        .DB      $00,$00,$4A,$B0,$00 ; . . . . . . . . 1 . 2 2 2 3 . . . . . .
        .DB      $00,$00,$0A,$88,$20 ; . . . . . . . . . . 2 2 2 . 2 . . 2 . .
        .DB      $00,$00,$02,$00,$00 ; . . . . . . . . . . . 2 . . . . . . . .
        .DB      $00,$00,$03,$00,$C0 ; . . . . . . . . . . . 3 . . . . 3 . . .
        .DB      $00,$80,$0A,$80,$00 ; . . . . 2 . . . . . 2 2 2 . . . . . . .
        .DB      $02,$80,$03,$00,$00 ; . . . 2 2 . . . . . . 3 . . . . . . . .
        .DB      $0A,$00,$0A,$80,$00 ; . . 2 2 . . . . . . 2 2 2 . . . . . . .
        .DB      $0A,$A0,$03,$00,$00 ; . . 2 2 2 2 . . . . . 3 . . . . . . . .
        .DB      $00,$AA,$03,$00,$00 ; . . . . 2 2 2 2 . . . 3 . . . . . . . .
        .DB      $00,$2A,$0F,$02,$00 ; . . . . . 2 2 2 . . 3 3 . . . 2 . . . .
        .DB      $00,$0A,$AF,$82,$30 ; . . . . . . 2 2 2 2 3 3 2 . . 2 . 3 . .
        .DB      $20,$0A,$AF,$AA,$08 ; . 2 . . . . 2 2 2 2 3 3 2 2 2 2 . . 2 .
        .DB      $20,$AA,$AF,$BA,$A8 ; . 2 . . 2 2 2 2 2 2 3 3 2 3 2 2 2 2 2 .
        .DB      $2A,$AA,$AF,$FA,$A8 ; . 2 2 2 2 2 2 2 2 2 3 3 3 3 2 2 2 2 2 .
        .DB      $2A,$AA,$AB,$E0,$A0 ; . 2 2 2 2 2 2 2 2 2 2 3 3 2 . . 2 2 . .
        .DB      $00,$00,$AA,$A8,$00 ; . . . . . . . . 2 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$AA,$A8,$30 ; . . . . . . . . 2 2 2 2 2 2 2 . . 3 . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_1:
        .DB      $00,$00,$00,$2A,$00 ; . . . . . . . . . . . . . 2 2 2 . . . .
        .DB      $00,$00,$00,$CA,$8C ; . . . . . . . . . . . . 3 . 2 2 2 . 3 .
        .DB      $00,$00,$00,$0A,$80 ; . . . . . . . . . . . . . . 2 2 2 . . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $02,$00,$00,$2A,$28 ; . . . 2 . . . . . . . . . 2 2 2 . 2 2 .
        .DB      $3C,$00,$00,$2F,$A8 ; . 3 3 . . . . . . . . . . 2 3 3 2 2 2 .
        .DB      $0A,$08,$80,$AB,$E8 ; . . 2 2 . . 2 . 2 . . . 2 2 2 3 3 2 2 .
        .DB      $2A,$BB,$BF,$FF,$E8 ; . 2 2 2 2 3 2 3 2 3 3 3 3 3 3 3 3 2 2 .
        .DB      $3A,$08,$83,$FF,$A8 ; . 3 2 2 . . 2 . 2 . . 3 3 3 3 3 2 2 2 .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$02,$AA,$80 ; . . . . . . . . . . . 2 2 2 2 2 2 . . .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$20,$2A,$2A,$00 ; . . . . . 2 . . . 2 2 2 . 2 2 2 . . . .
        .DB      $00,$08,$A8,$2A,$00 ; . . . . . . 2 . 2 2 2 . . 2 2 2 . . . .
        .DB      $00,$0A,$A0,$0A,$80 ; . . . . . . 2 2 2 2 . . . . 2 2 2 . . .
        .DB      $00,$02,$80,$02,$80 ; . . . . . . . 2 2 . . . . . . 2 2 . . .
        .DB      $00,$00,$00,$2A,$80 ; . . . . . . . . . . . . . 2 2 2 2 . . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_2:
        .DB      $33,$01,$00,$0A,$80 ; . 3 . 3 . . . 1 . . . . . . 2 2 2 . . .
        .DB      $0E,$80,$00,$32,$AC ; . . 3 2 2 . . . . . . . . 3 . 2 2 2 3 .
        .DB      $3A,$A0,$00,$02,$A0 ; . 3 2 2 2 2 . . . . . . . . . 2 2 2 . .
        .DB      $0A,$A0,$00,$AA,$80 ; . . 2 2 2 2 . . . . . . 2 2 2 2 2 . . .
        .DB      $30,$0E,$00,$0A,$A0 ; . 3 . . . . 3 2 . . . . . . 2 2 2 2 . .
        .DB      $00,$0B,$80,$02,$A8 ; . . . . . . 2 3 2 . . . . . . 2 2 2 2 .
        .DB      $00,$42,$F0,$0A,$E8 ; . . . . 1 . . 2 3 3 . . . . 2 2 3 2 2 .
        .DB      $00,$00,$3F,$2B,$F8 ; . . . . . . . . . 3 3 3 . 2 2 3 3 3 2 .
        .DB      $0C,$00,$0F,$FF,$E8 ; . . 3 . . . . . . . 3 3 3 3 3 3 3 2 2 .
        .DB      $00,$00,$00,$FF,$A8 ; . . . . . . . . . . . . 3 3 3 3 2 2 2 .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$80,$2A,$AA,$A0 ; . . . . 2 . . . . 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$20,$AA,$AA,$A0 ; . . . . . 2 . . 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$2A,$A0,$02,$A0 ; . . . . . 2 2 2 2 2 . . . . . 2 2 2 . .
        .DB      $00,$0A,$00,$02,$A0 ; . . . . . . 2 2 . . . . . . . 2 2 2 . .
        .DB      $00,$00,$00,$0A,$80 ; . . . . . . . . . . . . . . 2 2 2 . . .
        .DB      $00,$00,$00,$0A,$80 ; . . . . . . . . . . . . . . 2 2 2 . . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_3:
        .DB      $04,$08,$00,$0A,$80 ; . . 1 . . . 2 . . . . . . . 2 2 2 . . .
        .DB      $00,$00,$00,$32,$AC ; . . . . . . . . . . . . . 3 . 2 2 2 3 .
        .DB      $23,$00,$00,$02,$A0 ; . 2 . 3 . . . . . . . . . . . 2 2 2 . .
        .DB      $02,$83,$00,$AA,$80 ; . . . 2 2 . . 3 . . . . 2 2 2 2 2 . . .
        .DB      $0A,$A0,$00,$0A,$88 ; . . 2 2 2 2 . . . . . . . . 2 2 2 . 2 .
        .DB      $32,$A0,$00,$0A,$A8 ; . 3 . 2 2 2 . . . . . . . . 2 2 2 2 2 .
        .DB      $04,$0E,$C0,$2A,$E8 ; . . 1 . . . 3 2 3 . . . . 2 2 2 3 2 2 .
        .DB      $00,$0B,$FF,$2B,$F8 ; . . . . . . 2 3 3 3 3 3 . 2 2 3 3 3 2 .
        .DB      $00,$00,$FF,$FF,$E8 ; . . . . . . . . 3 3 3 3 3 3 3 3 3 2 2 .
        .DB      $00,$00,$03,$FF,$A8 ; . . . . . . . . . . . 3 3 3 3 3 2 2 2 .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$20,$2A,$AA,$80 ; . . . . . 2 . . . 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$08,$A8,$0A,$80 ; . . . . . . 2 . 2 2 2 . . . 2 2 2 . . .
        .DB      $00,$0A,$A0,$0A,$80 ; . . . . . . 2 2 2 2 . . . . 2 2 2 . . .
        .DB      $00,$02,$80,$0A,$00 ; . . . . . . . 2 2 . . . . . 2 2 . . . .
        .DB      $00,$00,$00,$0A,$00 ; . . . . . . . . . . . . . . 2 2 . . . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .

;*******************************************************************************
; WORRIOR_YELLOW_FIRE_4
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORRIOR_YELLOW_FIRE_4:
        .DB      $00,$00,$00,$2A,$00 ; . . . . . . . . . . . . . 2 2 2 . . . .
        .DB      $02,$00,$00,$CA,$8C ; . . . 2 . . . . . . . . 3 . 2 2 2 . 3 .
        .DB      $00,$30,$00,$0A,$80 ; . . . . . 3 . . . . . . . . 2 2 2 . . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $02,$00,$00,$2A,$28 ; . . . 2 . . . . . . . . . 2 2 2 . 2 2 .
        .DB      $3C,$00,$00,$2F,$A8 ; . 3 3 . . . . . . . . . . 2 3 3 2 2 2 .
        .DB      $0A,$08,$80,$AB,$E8 ; . . 2 2 . . 2 . 2 . . . 2 2 2 3 3 2 2 .
        .DB      $2A,$BB,$BF,$FF,$E8 ; . 2 2 2 2 3 2 3 2 3 3 3 3 3 3 3 3 2 2 .
        .DB      $3A,$08,$83,$FF,$A8 ; . 3 2 2 . . 2 . 2 . . 3 3 3 3 3 2 2 2 .
        .DB      $00,$00,$00,$AA,$A8 ; . . . . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $04,$00,$00,$AA,$A8 ; . . 1 . . . . . . . . . 2 2 2 2 2 2 2 .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$00,$2A,$0A,$80 ; . . . . . . . . . 2 2 2 . . 2 2 2 . . .
        .DB      $00,$0A,$28,$0A,$80 ; . . . . . . 2 2 . 2 2 . . . 2 2 2 . . .
        .DB      $00,$02,$A0,$02,$80 ; . . . . . . . 2 2 2 . . . . . 2 2 . . .
        .DB      $00,$00,$A0,$02,$80 ; . . . . . . . . 2 2 . . . . . 2 2 . . .
        .DB      $00,$00,$00,$2A,$80 ; . . . . . . . . . . . . . 2 2 2 2 . . .

;*******************************************************************************
; BURWOR_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_1_UP:
        .DB      $00,$00,$05,$40,$00 ; . . . . . . . . . . 1 1 1 . . . . . . .
        .DB      $00,$00,$15,$40,$00 ; . . . . . . . . . 1 1 1 1 . . . . . . .
        .DB      $10,$05,$15,$40,$00 ; . 1 . . . . 1 1 . 1 1 1 1 . . . . . . .
        .DB      $10,$55,$15,$50,$00 ; . 1 . . 1 1 1 1 . 1 1 1 1 1 . . . . . .
        .DB      $11,$55,$15,$D4,$00 ; . 1 . 1 1 1 1 1 . 1 1 1 3 1 1 . . . . .
        .DB      $15,$54,$05,$F4,$00 ; . 1 1 1 1 1 1 . . . 1 1 3 3 1 . . . . .
        .DB      $14,$10,$05,$F4,$00 ; . 1 1 . . 1 . . . . 1 1 3 3 1 . . . . .
        .DB      $10,$50,$55,$54,$00 ; . 1 . . 1 1 . . 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$55,$54,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$55,$54,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$01,$41,$00 ; . . . 1 1 1 1 1 . . . 1 1 . . 1 . . . .
        .DB      $01,$55,$01,$10,$00 ; . . . 1 1 1 1 1 . . . 1 . 1 . . . . . .
        .DB      $01,$54,$40,$00,$00 ; . . . 1 1 1 1 . 1 . . . . . . . . . . .
        .DB      $10,$10,$10,$00,$00 ; . 1 . . . 1 . . . 1 . . . . . . . . . .
        .DB      $15,$54,$05,$55,$50 ; . 1 1 1 1 1 1 . . . 1 1 1 1 1 1 1 1 . .
        .DB      $11,$54,$01,$55,$54 ; . 1 . 1 1 1 1 . . . . 1 1 1 1 1 1 1 1 .
        .DB      $10,$55,$00,$55,$50 ; . 1 . . 1 1 1 1 . . . . 1 1 1 1 1 1 . .
        .DB      $10,$05,$00,$05,$00 ; . 1 . . . . 1 1 . . . . . . 1 1 . . . .

;*******************************************************************************
; BURWOR_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_2_UP:
        .DB      $00,$00,$00,$45,$00 ; . . . . . . . . . . . . 1 . 1 1 . . . .
        .DB      $01,$01,$01,$55,$00 ; . . . 1 . . . 1 . . . 1 1 1 1 1 . . . .
        .DB      $01,$05,$41,$45,$00 ; . . . 1 . . 1 1 1 . . 1 1 . 1 1 . . . .
        .DB      $01,$15,$41,$55,$40 ; . . . 1 . 1 1 1 1 . . 1 1 1 1 1 1 . . .
        .DB      $01,$55,$41,$47,$50 ; . . . 1 1 1 1 1 1 . . 1 1 . 1 3 1 1 . .
        .DB      $01,$41,$40,$57,$D0 ; . . . 1 1 . . 1 1 . . . 1 1 1 3 3 1 . .
        .DB      $01,$01,$40,$57,$D0 ; . . . 1 . . . 1 1 . . . 1 1 1 3 3 1 . .
        .DB      $00,$05,$55,$55,$50 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$05,$55,$55,$50 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$05,$55,$55,$50 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$05,$51,$15,$10 ; . . . . . . 1 1 1 1 . 1 . 1 1 1 . 1 . .
        .DB      $00,$05,$40,$11,$00 ; . . . . . . 1 1 1 . . . . 1 . 1 . . . .
        .DB      $00,$15,$50,$00,$00 ; . . . . . 1 1 1 1 1 . . . . . . . . . .
        .DB      $04,$55,$45,$00,$00 ; . . 1 . 1 1 1 1 1 . 1 1 . . . . . . . .
        .DB      $05,$55,$01,$51,$40 ; . . 1 1 1 1 1 1 . . . 1 1 1 . 1 1 . . .
        .DB      $04,$14,$00,$55,$50 ; . . 1 . . 1 1 . . . . . 1 1 1 1 1 1 . .
        .DB      $10,$00,$00,$15,$54 ; . 1 . . . . . . . . . . . 1 1 1 1 1 1 .
        .DB      $10,$00,$00,$05,$44 ; . 1 . . . . . . . . . . . . 1 1 1 . 1 .

;*******************************************************************************
; BURWOR_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_3_UP:
        .DB      $04,$00,$00,$01,$40 ; . . 1 . . . . . . . . . . . . 1 1 . . .
        .DB      $01,$01,$00,$45,$40 ; . . . 1 . . . 1 . . . . 1 . 1 1 1 . . .
        .DB      $00,$45,$40,$41,$40 ; . . . . 1 . 1 1 1 . . . 1 . . 1 1 . . .
        .DB      $00,$55,$40,$45,$50 ; . . . . 1 1 1 1 1 . . . 1 . 1 1 1 1 . .
        .DB      $00,$51,$50,$41,$D4 ; . . . . 1 1 . 1 1 1 . . 1 . . 1 3 1 1 .
        .DB      $00,$40,$50,$15,$F4 ; . . . . 1 . . . 1 1 . . . 1 1 1 3 3 1 .
        .DB      $00,$00,$54,$15,$F4 ; . . . . . . . . 1 1 1 . . 1 1 1 3 3 1 .
        .DB      $00,$00,$55,$55,$54 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$00,$55,$55,$54 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$00,$55,$55,$54 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$00,$54,$45,$44 ; . . . . . . . . 1 1 1 . 1 . 1 1 1 . 1 .
        .DB      $00,$00,$50,$04,$40 ; . . . . . . . . 1 1 . . . . 1 . 1 . . .
        .DB      $00,$40,$54,$00,$00 ; . . . . 1 . . . 1 1 1 . . . . . . . . .
        .DB      $00,$51,$51,$05,$50 ; . . . . 1 1 . 1 1 1 . 1 . . 1 1 1 1 . .
        .DB      $00,$55,$40,$55,$54 ; . . . . 1 1 1 1 1 . . . 1 1 1 1 1 1 1 .
        .DB      $00,$45,$40,$50,$54 ; . . . . 1 . 1 1 1 . . . 1 1 . . 1 1 1 .
        .DB      $01,$01,$00,$00,$14 ; . . . 1 . . . 1 . . . . . . . . . 1 1 .
        .DB      $04,$00,$00,$00,$10 ; . . 1 . . . . . . . . . . . . . . 1 . .

;*******************************************************************************
; BURWOR_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_1:
        .DB      $00,$00,$00,$00,$40 ; . . . . . . . . . . . . . . . . 1 . . .
        .DB      $00,$00,$00,$01,$50 ; . . . . . . . . . . . . . . . 1 1 1 . .
        .DB      $00,$00,$00,$01,$50 ; . . . . . . . . . . . . . . . 1 1 1 . .
        .DB      $00,$00,$01,$01,$54 ; . . . . . . . . . . . 1 . . . 1 1 1 1 .
        .DB      $00,$15,$54,$01,$54 ; . . . . . 1 1 1 1 1 1 . . . . 1 1 1 1 .
        .DB      $00,$5F,$54,$41,$50 ; . . . . 1 1 3 3 1 1 1 . 1 . . 1 1 1 . .
        .DB      $15,$7F,$55,$01,$50 ; . 1 1 1 1 3 3 3 1 1 1 1 . . . 1 1 1 . .
        .DB      $15,$55,$55,$41,$40 ; . 1 1 1 1 1 1 1 1 1 1 1 1 . . 1 1 . . .
        .DB      $15,$55,$54,$01,$00 ; . 1 1 1 1 1 1 1 1 1 1 . . . . 1 . . . .
        .DB      $05,$50,$54,$04,$00 ; . . 1 1 1 1 . . 1 1 1 . . . 1 . . . . .
        .DB      $00,$00,$54,$10,$00 ; . . . . . . . . 1 1 1 . . 1 . . . . . .
        .DB      $01,$50,$15,$40,$14 ; . . . 1 1 1 . . . 1 1 1 1 . . . . 1 1 .
        .DB      $01,$54,$15,$51,$54 ; . . . 1 1 1 1 . . 1 1 1 1 1 . 1 1 1 1 .
        .DB      $00,$55,$55,$55,$50 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$54,$55,$51,$50 ; . . . . 1 1 1 . 1 1 1 1 1 1 . 1 1 1 . .
        .DB      $00,$14,$15,$51,$40 ; . . . . . 1 1 . . 1 1 1 1 1 . 1 1 . . .
        .DB      $00,$05,$00,$01,$00 ; . . . . . . 1 1 . . . . . . . 1 . . . .
        .DB      $01,$55,$40,$05,$54 ; . . . 1 1 1 1 1 1 . . . . . 1 1 1 1 1 .

;*******************************************************************************
; BURWOR_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_2:
        .DB      $00,$00,$00,$00,$14 ; . . . . . . . . . . . . . . . . . 1 1 .
        .DB      $00,$15,$55,$00,$50 ; . . . . . 1 1 1 1 1 1 1 . . . . 1 1 . .
        .DB      $00,$5F,$54,$01,$54 ; . . . . 1 1 3 3 1 1 1 . . . . 1 1 1 1 .
        .DB      $15,$7F,$55,$41,$54 ; . 1 1 1 1 3 3 3 1 1 1 1 1 . . 1 1 1 1 .
        .DB      $15,$55,$55,$00,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 . . . . 1 1 1 .
        .DB      $04,$45,$55,$41,$50 ; . . 1 . 1 . 1 1 1 1 1 1 1 . . 1 1 1 . .
        .DB      $15,$55,$54,$01,$40 ; . 1 1 1 1 1 1 1 1 1 1 . . . . 1 1 . . .
        .DB      $05,$50,$55,$05,$00 ; . . 1 1 1 1 . . 1 1 1 1 . . 1 1 . . . .
        .DB      $00,$00,$54,$04,$00 ; . . . . . . . . 1 1 1 . . . 1 . . . . .
        .DB      $00,$00,$55,$10,$00 ; . . . . . . . . 1 1 1 1 . 1 . . . . . .
        .DB      $01,$55,$55,$54,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $05,$55,$55,$55,$00 ; . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$50,$55,$55,$40 ; . . . 1 1 1 . . 1 1 1 1 1 1 1 1 1 . . .
        .DB      $00,$50,$00,$15,$40 ; . . . . 1 1 . . . . . . . 1 1 1 1 . . .
        .DB      $00,$14,$00,$05,$00 ; . . . . . 1 1 . . . . . . . 1 1 . . . .
        .DB      $05,$55,$00,$01,$00 ; . . 1 1 1 1 1 1 . . . . . . . 1 . . . .
        .DB      $00,$00,$00,$05,$40 ; . . . . . . . . . . . . . . 1 1 1 . . .
        .DB      $00,$00,$00,$00,$14 ; . . . . . . . . . . . . . . . . . 1 1 .

;*******************************************************************************
; BURWOR_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_3:
        .DB      $00,$15,$55,$01,$50 ; . . . . . 1 1 1 1 1 1 1 . . . 1 1 1 . .
        .DB      $00,$5F,$54,$05,$54 ; . . . . 1 1 3 3 1 1 1 . . . 1 1 1 1 1 .
        .DB      $15,$7F,$55,$45,$40 ; . 1 1 1 1 3 3 3 1 1 1 1 1 . 1 1 1 . . .
        .DB      $15,$55,$55,$05,$00 ; . 1 1 1 1 1 1 1 1 1 1 1 . . 1 1 . . . .
        .DB      $04,$45,$55,$45,$00 ; . . 1 . 1 . 1 1 1 1 1 1 1 . 1 1 . . . .
        .DB      $00,$05,$54,$01,$40 ; . . . . . . 1 1 1 1 1 . . . . 1 1 . . .
        .DB      $05,$50,$55,$01,$40 ; . . 1 1 1 1 . . 1 1 1 1 . . . 1 1 . . .
        .DB      $00,$00,$54,$04,$00 ; . . . . . . . . 1 1 1 . . . 1 . . . . .
        .DB      $00,$01,$55,$10,$00 ; . . . . . . . 1 1 1 1 1 . 1 . . . . . .
        .DB      $00,$15,$55,$54,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$55,$55,$40 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
        .DB      $05,$50,$00,$05,$50 ; . . 1 1 1 1 . . . . . . . . 1 1 1 1 . .
        .DB      $01,$40,$00,$01,$40 ; . . . 1 1 . . . . . . . . . . 1 1 . . .
        .DB      $00,$50,$00,$05,$00 ; . . . . 1 1 . . . . . . . . 1 1 . . . .
        .DB      $01,$54,$00,$15,$40 ; . . . 1 1 1 1 . . . . . . 1 1 1 1 . . .
        .DB      $04,$00,$00,$00,$10 ; . . 1 . . . . . . . . . . . . . . 1 . .
        .DB      $10,$00,$00,$00,$04 ; . 1 . . . . . . . . . . . . . . . . 1 .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .

;*******************************************************************************
; BURWOR_FIRE_0_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_0_UP:
        .DB      $00,$00,$CC,$00,$00 ; . . . . . . . . 3 . 3 . . . . . . . . .
        .DB      $00,$00,$07,$50,$00 ; . . . . . . . . . . 1 3 1 1 . . . . . .
        .DB      $10,$05,$15,$50,$00 ; . 1 . . . . 1 1 . 1 1 1 1 1 . . . . . .
        .DB      $10,$55,$17,$50,$00 ; . 1 . . 1 1 1 1 . 1 1 3 1 1 . . . . . .
        .DB      $11,$55,$15,$54,$00 ; . 1 . 1 1 1 1 1 . 1 1 1 1 1 1 . . . . .
        .DB      $15,$54,$17,$75,$00 ; . 1 1 1 1 1 1 . . 1 1 3 1 3 1 1 . . . .
        .DB      $14,$10,$05,$7D,$00 ; . 1 1 . . 1 . . . . 1 1 1 3 3 1 . . . .
        .DB      $10,$50,$05,$7D,$00 ; . 1 . . 1 1 . . . . 1 1 1 3 3 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$41,$50,$40 ; . . . 1 1 1 1 1 1 . . 1 1 1 . . 1 . . .
        .DB      $01,$55,$01,$04,$00 ; . . . 1 1 1 1 1 . . . 1 . . 1 . . . . .
        .DB      $10,$10,$40,$00,$00 ; . 1 . . . 1 . . 1 . . . . . . . . . . .
        .DB      $15,$54,$15,$55,$50 ; . 1 1 1 1 1 1 . . 1 1 1 1 1 1 1 1 1 . .
        .DB      $11,$54,$05,$55,$54 ; . 1 . 1 1 1 1 . . . 1 1 1 1 1 1 1 1 1 .
        .DB      $10,$55,$01,$55,$50 ; . 1 . . 1 1 1 1 . . . 1 1 1 1 1 1 1 . .
        .DB      $10,$05,$00,$15,$00 ; . 1 . . . . 1 1 . . . . . 1 1 1 . . . .

;*******************************************************************************
; BURWOR_FIRE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_1_UP:
        .DB      $30,$00,$CC,$00,$00 ; . 3 . . . . . . 3 . 3 . . . . . . . . .
        .DB      $00,$C0,$0F,$50,$00 ; . . . . 3 . . . . . 3 3 1 1 . . . . . .
        .DB      $10,$05,$1D,$50,$00 ; . 1 . . . . 1 1 . 1 3 1 1 1 . . . . . .
        .DB      $10,$55,$1F,$50,$00 ; . 1 . . 1 1 1 1 . 1 3 3 1 1 . . . . . .
        .DB      $11,$55,$1D,$54,$00 ; . 1 . 1 1 1 1 1 . 1 3 1 1 1 1 . . . . .
        .DB      $15,$54,$1D,$75,$00 ; . 1 1 1 1 1 1 . . 1 3 1 1 3 1 1 . . . .
        .DB      $14,$10,$05,$7D,$00 ; . 1 1 . . 1 . . . . 1 1 1 3 3 1 . . . .
        .DB      $10,$50,$05,$7D,$00 ; . 1 . . 1 1 . . . . 1 1 1 3 3 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$55,$41,$50,$40 ; . . . 1 1 1 1 1 1 . . 1 1 1 . . 1 . . .
        .DB      $01,$55,$01,$04,$00 ; . . . 1 1 1 1 1 . . . 1 . . 1 . . . . .
        .DB      $10,$10,$40,$00,$00 ; . 1 . . . 1 . . 1 . . . . . . . . . . .
        .DB      $15,$54,$15,$55,$54 ; . 1 1 1 1 1 1 . . 1 1 1 1 1 1 1 1 1 1 .
        .DB      $11,$54,$05,$55,$50 ; . 1 . 1 1 1 1 . . . 1 1 1 1 1 1 1 1 . .
        .DB      $10,$55,$01,$55,$40 ; . 1 . . 1 1 1 1 . . . 1 1 1 1 1 1 . . .
        .DB      $10,$05,$00,$15,$00 ; . 1 . . . . 1 1 . . . . . 1 1 1 . . . .

;*******************************************************************************
; BURWOR_FIRE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_2_UP:
        .DB      $00,$20,$30,$CC,$00 ; . . . . . 2 . . . 3 . . 3 . 3 . . . . .
        .DB      $01,$01,$02,$F0,$00 ; . . . 1 . . . 1 . . . 2 3 3 . . . . . .
        .DB      $01,$05,$40,$B1,$40 ; . . . 1 . . 1 1 1 . . . 2 3 . 1 1 . . .
        .DB      $01,$15,$41,$F5,$40 ; . . . 1 . 1 1 1 1 . . 1 3 3 1 1 1 . . .
        .DB      $01,$55,$41,$FD,$40 ; . . . 1 1 1 1 1 1 . . 1 3 3 3 1 1 . . .
        .DB      $31,$41,$41,$F5,$50 ; . 3 . 1 1 . . 1 1 . . 1 3 3 1 1 1 1 . .
        .DB      $01,$01,$51,$FD,$D4 ; . . . 1 . . . 1 1 1 . 1 3 3 3 1 3 1 1 .
        .DB      $00,$05,$50,$75,$F4 ; . . . . . . 1 1 1 1 . . 1 3 1 1 3 3 1 .
        .DB      $0C,$05,$55,$55,$F4 ; . . 3 . . . 1 1 1 1 1 1 1 1 1 1 3 3 1 .
        .DB      $00,$05,$55,$55,$54 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$05,$55,$55,$54 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$05,$54,$45,$44 ; . . . . . . 1 1 1 1 1 . 1 . 1 1 1 . 1 .
        .DB      $00,$15,$50,$04,$40 ; . . . . . 1 1 1 1 1 . . . . 1 . 1 . . .
        .DB      $04,$55,$54,$00,$00 ; . . 1 . 1 1 1 1 1 1 1 . . . . . . . . .
        .DB      $05,$55,$05,$55,$40 ; . . 1 1 1 1 1 1 . . 1 1 1 1 1 1 1 . . .
        .DB      $04,$14,$01,$55,$50 ; . . 1 . . 1 1 . . . . 1 1 1 1 1 1 1 . .
        .DB      $10,$00,$00,$55,$54 ; . 1 . . . . . . . . . . 1 1 1 1 1 1 1 .
        .DB      $10,$00,$00,$15,$50 ; . 1 . . . . . . . . . . . 1 1 1 1 1 . .

;*******************************************************************************
; BURWOR_FIRE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_3_UP:
        .DB      $00,$00,$00,$C8,$00 ; . . . . . . . . . . . . 3 . 2 . . . . .
        .DB      $04,$00,$00,$F0,$00 ; . . 1 . . . . . . . . . 3 3 . . . . . .
        .DB      $01,$01,$02,$F0,$00 ; . . . 1 . . . 1 . . . 2 3 3 . . . . . .
        .DB      $00,$45,$40,$B1,$40 ; . . . . 1 . 1 1 1 . . . 2 3 . 1 1 . . .
        .DB      $08,$55,$41,$F5,$40 ; . . 2 . 1 1 1 1 1 . . 1 3 3 1 1 1 . . .
        .DB      $00,$51,$51,$FD,$40 ; . . . . 1 1 . 1 1 1 . 1 3 3 3 1 1 . . .
        .DB      $00,$41,$51,$F5,$50 ; . . . . 1 . . 1 1 1 . 1 3 3 1 1 1 1 . .
        .DB      $00,$00,$51,$FD,$D4 ; . . . . . . . . 1 1 . 1 3 3 3 1 3 1 1 .
        .DB      $30,$00,$50,$75,$F4 ; . 3 . . . . . . 1 1 . . 1 3 1 1 3 3 1 .
        .DB      $00,$00,$55,$55,$F4 ; . . . . . . . . 1 1 1 1 1 1 1 1 3 3 1 .
        .DB      $03,$00,$55,$55,$54 ; . . . 3 . . . . 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$00,$55,$55,$54 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $00,$40,$54,$45,$44 ; . . . . 1 . . . 1 1 1 . 1 . 1 1 1 . 1 .
        .DB      $00,$51,$54,$04,$40 ; . . . . 1 1 . 1 1 1 1 . . . 1 . 1 . . .
        .DB      $00,$55,$45,$00,$00 ; . . . . 1 1 1 1 1 . 1 1 . . . . . . . .
        .DB      $00,$45,$41,$55,$40 ; . . . . 1 . 1 1 1 . . 1 1 1 1 1 1 . . .
        .DB      $01,$01,$00,$55,$50 ; . . . 1 . . . 1 . . . . 1 1 1 1 1 1 . .
        .DB      $04,$00,$00,$15,$54 ; . . 1 . . . . . . . . . . 1 1 1 1 1 1 .

;*******************************************************************************
; BURWOR_FIRE_0
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_0:
        .DB      $00,$00,$00,$00,$40 ; . . . . . . . . . . . . . . . . 1 . . .
        .DB      $00,$00,$00,$01,$50 ; . . . . . . . . . . . . . . . 1 1 1 . .
        .DB      $00,$00,$00,$41,$50 ; . . . . . . . . . . . . 1 . . 1 1 1 . .
        .DB      $00,$05,$55,$01,$54 ; . . . . . . 1 1 1 1 1 1 . . . 1 1 1 1 .
        .DB      $00,$17,$D5,$11,$54 ; . . . . . 1 1 3 3 1 1 1 . 1 . 1 1 1 1 .
        .DB      $05,$5F,$D5,$41,$54 ; . . 1 1 1 1 3 3 3 1 1 1 1 . . 1 1 1 1 .
        .DB      $05,$55,$55,$41,$50 ; . . 1 1 1 1 1 1 1 1 1 1 1 . . 1 1 1 . .
        .DB      $0D,$DD,$55,$51,$50 ; . . 3 1 3 1 3 1 1 1 1 1 1 1 . 1 1 1 . .
        .DB      $35,$55,$55,$01,$40 ; . 3 1 1 1 1 1 1 1 1 1 1 . . . 1 1 . . .
        .DB      $01,$54,$15,$01,$00 ; . . . 1 1 1 1 . . 1 1 1 . . . 1 . . . .
        .DB      $30,$00,$15,$44,$00 ; . 3 . . . . . . . 1 1 1 1 . 1 . . . . .
        .DB      $01,$50,$15,$50,$14 ; . . . 1 1 1 . . . 1 1 1 1 1 . . . 1 1 .
        .DB      $01,$54,$15,$51,$54 ; . . . 1 1 1 1 . . 1 1 1 1 1 . 1 1 1 1 .
        .DB      $00,$55,$55,$55,$50 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$54,$55,$51,$50 ; . . . . 1 1 1 . 1 1 1 1 1 1 . 1 1 1 . .
        .DB      $00,$14,$15,$51,$40 ; . . . . . 1 1 . . 1 1 1 1 1 . 1 1 . . .
        .DB      $00,$05,$00,$01,$00 ; . . . . . . 1 1 . . . . . . . 1 . . . .
        .DB      $01,$55,$40,$05,$54 ; . . . 1 1 1 1 1 1 . . . . . 1 1 1 1 1 .

;*******************************************************************************
; BURWOR_FIRE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_1:
        .DB      $00,$00,$00,$01,$00 ; . . . . . . . . . . . . . . . 1 . . . .
        .DB      $00,$00,$00,$01,$40 ; . . . . . . . . . . . . . . . 1 1 . . .
        .DB      $00,$00,$00,$41,$50 ; . . . . . . . . . . . . 1 . . 1 1 1 . .
        .DB      $00,$05,$55,$01,$54 ; . . . . . . 1 1 1 1 1 1 . . . 1 1 1 1 .
        .DB      $00,$17,$D5,$11,$54 ; . . . . . 1 1 3 3 1 1 1 . 1 . 1 1 1 1 .
        .DB      $05,$5F,$D5,$41,$54 ; . . 1 1 1 1 3 3 3 1 1 1 1 . . 1 1 1 1 .
        .DB      $05,$55,$55,$41,$50 ; . . 1 1 1 1 1 1 1 1 1 1 1 . . 1 1 1 . .
        .DB      $0D,$D5,$55,$51,$50 ; . . 3 1 3 1 1 1 1 1 1 1 1 1 . 1 1 1 . .
        .DB      $3F,$FD,$55,$01,$40 ; . 3 3 3 3 3 3 1 1 1 1 1 . . . 1 1 . . .
        .DB      $01,$54,$15,$01,$00 ; . . . 1 1 1 1 . . 1 1 1 . . . 1 . . . .
        .DB      $30,$00,$15,$44,$00 ; . 3 . . . . . . . 1 1 1 1 . 1 . . . . .
        .DB      $01,$50,$15,$50,$14 ; . . . 1 1 1 . . . 1 1 1 1 1 . . . 1 1 .
        .DB      $01,$54,$15,$51,$54 ; . . . 1 1 1 1 . . 1 1 1 1 1 . 1 1 1 1 .
        .DB      $00,$55,$55,$55,$50 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $0C,$54,$55,$51,$50 ; . . 3 . 1 1 1 . 1 1 1 1 1 1 . 1 1 1 . .
        .DB      $00,$14,$15,$51,$40 ; . . . . . 1 1 . . 1 1 1 1 1 . 1 1 . . .
        .DB      $00,$05,$00,$01,$00 ; . . . . . . 1 1 . . . . . . . 1 . . . .
        .DB      $31,$55,$40,$05,$54 ; . 3 . 1 1 1 1 1 1 . . . . . 1 1 1 1 1 .

;*******************************************************************************
; BURWOR_FIRE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_2:
        .DB      $00,$01,$55,$40,$10 ; . . . . . . . 1 1 1 1 1 1 . . . . 1 . .
        .DB      $00,$05,$F5,$00,$54 ; . . . . . . 1 1 3 3 1 1 . . . . 1 1 1 .
        .DB      $01,$57,$F5,$51,$54 ; . . . 1 1 1 1 3 3 3 1 1 1 1 . 1 1 1 1 .
        .DB      $01,$55,$55,$41,$54 ; . . . 1 1 1 1 1 1 1 1 1 1 . . 1 1 1 1 .
        .DB      $30,$77,$55,$51,$54 ; . 3 . . 1 3 1 3 1 1 1 1 1 1 . 1 1 1 1 .
        .DB      $0F,$FF,$D5,$01,$54 ; . . 3 3 3 3 3 3 3 1 1 1 . . . 1 1 1 1 .
        .DB      $3E,$FF,$55,$41,$50 ; . 3 3 2 3 3 3 3 1 1 1 1 1 . . 1 1 1 . .
        .DB      $08,$55,$15,$01,$40 ; . . 2 . 1 1 1 1 . 1 1 1 . . . 1 1 . . .
        .DB      $00,$00,$15,$45,$00 ; . . . . . . . . . 1 1 1 1 . 1 1 . . . .
        .DB      $30,$01,$55,$54,$00 ; . 3 . . . . . 1 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$55,$54,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $05,$55,$55,$55,$00 ; . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $01,$50,$55,$55,$40 ; . . . 1 1 1 . . 1 1 1 1 1 1 1 1 1 . . .
        .DB      $20,$50,$00,$15,$40 ; . 2 . . 1 1 . . . . . . . 1 1 1 1 . . .
        .DB      $00,$14,$00,$05,$00 ; . . . . . 1 1 . . . . . . . 1 1 . . . .
        .DB      $05,$55,$00,$01,$00 ; . . 1 1 1 1 1 1 . . . . . . . 1 . . . .
        .DB      $00,$00,$30,$05,$40 ; . . . . . . . . . 3 . . . . 1 1 1 . . .
        .DB      $00,$0C,$00,$00,$14 ; . . . . . . 3 . . . . . . . . . . 1 1 .

;*******************************************************************************
; BURWOR_FIRE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
BURWOR_FIRE_3:
        .DB      $00,$00,$55,$50,$04 ; . . . . . . . . 1 1 1 1 1 1 . . . . 1 .
        .DB      $00,$01,$7D,$40,$14 ; . . . . . . . 1 1 3 3 1 1 . . . . 1 1 .
        .DB      $00,$55,$FD,$54,$54 ; . . . . 1 1 1 1 3 3 3 1 1 1 1 . 1 1 1 .
        .DB      $00,$55,$55,$50,$54 ; . . . . 1 1 1 1 1 1 1 1 1 1 . . 1 1 1 .
        .DB      $20,$1D,$D5,$54,$54 ; . 2 . . . 1 3 1 3 1 1 1 1 1 1 . 1 1 1 .
        .DB      $0F,$FF,$F5,$40,$54 ; . . 3 3 3 3 3 3 3 3 1 1 1 . . . 1 1 1 .
        .DB      $3F,$BF,$D5,$50,$50 ; . 3 3 3 2 3 3 3 3 1 1 1 1 1 . . 1 1 . .
        .DB      $02,$15,$45,$41,$40 ; . . . 2 . 1 1 1 1 . 1 1 1 . . 1 1 . . .
        .DB      $00,$00,$05,$55,$00 ; . . . . . . . . . . 1 1 1 1 1 1 . . . .
        .DB      $00,$05,$55,$54,$00 ; . . . . . . 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$55,$55,$55,$40 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . .
        .DB      $01,$55,$00,$05,$50 ; . . . 1 1 1 1 1 . . . . . . 1 1 1 1 . .
        .DB      $00,$50,$00,$01,$40 ; . . . . 1 1 . . . . . . . . . 1 1 . . .
        .DB      $00,$14,$00,$05,$00 ; . . . . . 1 1 . . . . . . . 1 1 . . . .
        .DB      $00,$55,$00,$15,$40 ; . . . . 1 1 1 1 . . . . . 1 1 1 1 . . .
        .DB      $01,$00,$03,$00,$10 ; . . . 1 . . . . . . . 3 . . . . . 1 . .
        .DB      $04,$20,$00,$00,$04 ; . . 1 . . 2 . . . . . . . . . . . . 1 .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .

;*******************************************************************************
; WORLUK_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_1_UP:
        .DB      $00,$00,$00,$1A,$A0 ; . . . . . . . . . . . . . 1 2 2 2 2 . .
        .DB      $00,$00,$05,$5A,$A0 ; . . . . . . . . . . 1 1 1 1 2 2 2 2 . .
        .DB      $10,$00,$12,$6A,$80 ; . 1 . . . . . . . 1 . 2 1 2 2 2 2 . . .
        .DB      $10,$00,$41,$AA,$00 ; . 1 . . . . . . 1 . . 1 2 2 2 2 . . . .
        .DB      $15,$40,$09,$A8,$00 ; . 1 1 1 1 . . . . . 2 1 2 2 2 . . . . .
        .DB      $00,$10,$06,$8E,$04 ; . . . . . 1 . . . . 1 2 2 . 3 2 . . 1 .
        .DB      $00,$10,$1A,$2F,$84 ; . . . . . 1 . . . 1 2 2 . 2 3 3 2 . 1 .
        .DB      $00,$55,$54,$3F,$D0 ; . . . . 1 1 1 1 1 1 1 . . 3 3 3 3 1 . .
        .DB      $01,$55,$55,$AF,$80 ; . . . 1 1 1 1 1 1 1 1 1 2 2 3 3 2 . . .
        .DB      $05,$55,$56,$AA,$80 ; . . 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 . . .
        .DB      $01,$55,$55,$AF,$80 ; . . . 1 1 1 1 1 1 1 1 1 2 2 3 3 2 . . .
        .DB      $00,$55,$54,$3F,$D0 ; . . . . 1 1 1 1 1 1 1 . . 3 3 3 3 1 . .
        .DB      $00,$10,$1A,$2F,$84 ; . . . . . 1 . . . 1 2 2 . 2 3 3 2 . 1 .
        .DB      $00,$10,$26,$AE,$04 ; . . . . . 1 . . . 2 1 2 2 2 3 2 . . 1 .
        .DB      $15,$40,$09,$AA,$00 ; . 1 1 1 1 . . . . . 2 1 2 2 2 2 . . . .
        .DB      $10,$00,$01,$AA,$A0 ; . 1 . . . . . . . . . 1 2 2 2 2 2 2 . .
        .DB      $10,$00,$40,$6A,$A8 ; . 1 . . . . . . 1 . . . 1 2 2 2 2 2 2 .
        .DB      $00,$00,$15,$5A,$A8 ; . . . . . . . . . 1 1 1 1 1 2 2 2 2 2 .

;*******************************************************************************
; WORLUK_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_2_UP:
        .DB      $00,$00,$2A,$A4,$00 ; . . . . . . . . . 2 2 2 2 2 1 . . . . .
        .DB      $00,$00,$A5,$56,$00 ; . . . . . . . . 2 2 1 1 1 1 1 2 . . . .
        .DB      $00,$02,$9A,$68,$00 ; . . . . . . . 2 2 1 2 2 1 2 2 . . . . .
        .DB      $10,$52,$69,$A0,$00 ; . 1 . . 1 1 . 2 1 2 2 1 2 2 . . . . . .
        .DB      $11,$12,$A6,$8E,$00 ; . 1 . 1 . 1 . 2 2 2 1 2 2 . 3 2 . . . .
        .DB      $14,$10,$9A,$2F,$80 ; . 1 1 . . 1 . . 2 1 2 2 . 2 3 3 2 . . .
        .DB      $00,$55,$54,$3F,$D4 ; . . . . 1 1 1 1 1 1 1 . . 3 3 3 3 1 1 .
        .DB      $01,$55,$55,$AF,$80 ; . . . 1 1 1 1 1 1 1 1 1 2 2 3 3 2 . . .
        .DB      $05,$55,$56,$AA,$80 ; . . 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 . . .
        .DB      $01,$55,$55,$AF,$80 ; . . . 1 1 1 1 1 1 1 1 1 2 2 3 3 2 . . .
        .DB      $00,$55,$54,$3F,$D0 ; . . . . 1 1 1 1 1 1 1 . . 3 3 3 3 1 . .
        .DB      $00,$10,$9A,$2F,$84 ; . . . . . 1 . . 2 1 2 2 . 2 3 3 2 . 1 .
        .DB      $00,$42,$A6,$8E,$00 ; . . . . 1 . . 2 2 2 1 2 2 . 3 2 . . . .
        .DB      $01,$02,$A9,$80,$00 ; . . . 1 . . . 2 2 2 2 1 2 . . . . . . .
        .DB      $14,$02,$69,$A0,$00 ; . 1 1 . . . . 2 1 2 2 1 2 2 . . . . . .
        .DB      $10,$02,$95,$A8,$00 ; . 1 . . . . . 2 2 1 1 1 2 2 2 . . . . .
        .DB      $10,$00,$A5,$68,$00 ; . 1 . . . . . . 2 2 1 1 1 2 2 . . . . .
        .DB      $00,$00,$2A,$68,$00 ; . . . . . . . . . 2 2 2 1 2 2 . . . . .

;*******************************************************************************
; WORLUK_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_3_UP:
        .DB      $02,$A8,$04,$00,$00 ; . . . 2 2 2 2 . . . 1 . . . . . . . . .
        .DB      $02,$AA,$94,$00,$00 ; . . . 2 2 2 2 2 2 1 1 . . . . . . . . .
        .DB      $00,$AA,$64,$00,$00 ; . . . . 2 2 2 2 1 2 1 . . . . . . . . .
        .DB      $00,$29,$A6,$00,$00 ; . . . . . 2 2 1 2 2 1 2 . . . . . . . .
        .DB      $10,$5A,$A6,$00,$00 ; . 1 . . 1 1 2 2 2 2 1 2 . . . . . . . .
        .DB      $11,$12,$A6,$38,$00 ; . 1 . 1 . 1 . 2 2 2 1 2 . 3 2 . . . . .
        .DB      $14,$10,$98,$BE,$00 ; . 1 1 . . 1 . . 2 1 2 . 2 3 3 2 . . . .
        .DB      $10,$55,$50,$FF,$40 ; . 1 . . 1 1 1 1 1 1 . . 3 3 3 3 1 . . .
        .DB      $01,$55,$56,$BE,$10 ; . . . 1 1 1 1 1 1 1 1 2 2 3 3 2 . 1 . .
        .DB      $05,$55,$5A,$AA,$00 ; . . 1 1 1 1 1 1 1 1 2 2 2 2 2 2 . . . .
        .DB      $01,$55,$56,$BE,$00 ; . . . 1 1 1 1 1 1 1 1 2 2 3 3 2 . . . .
        .DB      $10,$55,$50,$FF,$40 ; . 1 . . 1 1 1 1 1 1 . . 3 3 3 3 1 . . .
        .DB      $14,$10,$98,$BE,$10 ; . 1 1 . . 1 . . 2 1 2 . 2 3 3 2 . 1 . .
        .DB      $11,$11,$A6,$38,$00 ; . 1 . 1 . 1 . 1 2 2 1 2 . 3 2 . . . . .
        .DB      $10,$5A,$66,$00,$00 ; . 1 . . 1 1 2 2 1 2 1 2 . . . . . . . .
        .DB      $00,$AA,$96,$00,$00 ; . . . . 2 2 2 2 2 1 1 2 . . . . . . . .
        .DB      $02,$AA,$94,$00,$00 ; . . . 2 2 2 2 2 2 1 1 . . . . . . . . .
        .DB      $02,$AA,$84,$00,$00 ; . . . 2 2 2 2 2 2 . 1 . . . . . . . . .

;*******************************************************************************
; WORLUK_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_1:
        .DB      $00,$05,$00,$14,$28 ; . . . . . . 1 1 . . . . . 1 1 . . 2 2 .
        .DB      $28,$00,$40,$40,$A8 ; . 2 2 . . . . . 1 . . . 1 . . . 2 2 2 .
        .DB      $2A,$02,$EA,$E0,$A8 ; . 2 2 2 . . . 2 3 2 2 2 3 2 . . 2 2 2 .
        .DB      $2A,$8B,$FB,$FA,$A8 ; . 2 2 2 2 . 2 3 3 3 2 3 3 3 2 2 2 2 2 .
        .DB      $2A,$AF,$FB,$FE,$A8 ; . 2 2 2 2 2 3 3 3 3 2 3 3 3 3 2 2 2 2 .
        .DB      $16,$A2,$EA,$EA,$A4 ; . 1 1 2 2 2 . 2 3 2 2 2 3 2 2 2 2 2 1 .
        .DB      $05,$A8,$2A,$0A,$94 ; . . 1 1 2 2 2 . . 2 2 2 . . 2 2 2 1 1 .
        .DB      $06,$5A,$19,$29,$44 ; . . 1 2 1 1 2 2 . 1 2 1 . 2 2 1 1 . 1 .
        .DB      $04,$26,$55,$66,$04 ; . . 1 . . 2 1 2 1 1 1 1 1 2 1 2 . . 1 .
        .DB      $01,$01,$55,$58,$04 ; . . . 1 . . . 1 1 1 1 1 1 1 2 . . . 1 .
        .DB      $00,$40,$55,$40,$10 ; . . . . 1 . . . 1 1 1 1 1 . . . . 1 . .
        .DB      $00,$00,$55,$40,$00 ; . . . . . . . . 1 1 1 1 1 . . . . . . .
        .DB      $00,$00,$55,$40,$00 ; . . . . . . . . 1 1 1 1 1 . . . . . . .
        .DB      $00,$05,$55,$54,$00 ; . . . . . . 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$10,$55,$41,$00 ; . . . . . 1 . . 1 1 1 1 1 . . 1 . . . .
        .DB      $00,$10,$15,$01,$00 ; . . . . . 1 . . . 1 1 1 . . . 1 . . . .
        .DB      $00,$10,$04,$01,$00 ; . . . . . 1 . . . . 1 . . . . 1 . . . .
        .DB      $01,$50,$00,$01,$50 ; . . . 1 1 1 . . . . . . . . . 1 1 1 . .

;*******************************************************************************
; WORLUK_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_2:
        .DB      $00,$01,$00,$40,$00 ; . . . . . . . 1 . . . . 1 . . . . . . .
        .DB      $00,$01,$01,$00,$00 ; . . . . . . . 1 . . . 1 . . . . . . . .
        .DB      $00,$0B,$AB,$80,$00 ; . . . . . . 2 3 2 2 2 3 2 . . . . . . .
        .DB      $08,$2F,$EF,$E0,$00 ; . . 2 . . 2 3 3 3 2 3 3 3 2 . . . . . .
        .DB      $16,$3F,$EF,$F0,$A8 ; . 1 1 2 . 3 3 3 3 2 3 3 3 3 . . 2 2 2 .
        .DB      $26,$8B,$AB,$82,$A8 ; . 2 1 2 2 . 2 3 2 2 2 3 2 . . 2 2 2 2 .
        .DB      $25,$A0,$A8,$2A,$94 ; . 2 1 1 2 2 . . 2 2 2 . . 2 2 2 2 1 1 .
        .DB      $26,$68,$64,$A5,$58 ; . 2 1 2 1 2 2 . 1 2 1 . 2 2 1 1 1 1 2 .
        .DB      $26,$99,$55,$9A,$58 ; . 2 1 2 2 1 2 1 1 1 1 1 2 1 2 2 1 1 2 .
        .DB      $29,$A5,$55,$6A,$68 ; . 2 2 1 2 2 1 1 1 1 1 1 1 2 2 2 1 2 2 .
        .DB      $0A,$69,$55,$A9,$A0 ; . . 2 2 1 2 2 1 1 1 1 1 2 2 2 1 2 2 . .
        .DB      $02,$A1,$55,$2A,$80 ; . . . 2 2 2 . 1 1 1 1 1 . 2 2 2 2 . . .
        .DB      $00,$01,$55,$00,$00 ; . . . . . . . 1 1 1 1 1 . . . . . . . .
        .DB      $00,$55,$55,$40,$00 ; . . . . 1 1 1 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$41,$55,$10,$00 ; . . . . 1 . . 1 1 1 1 1 . 1 . . . . . .
        .DB      $00,$10,$54,$04,$00 ; . . . . . 1 . . 1 1 1 . . . 1 . . . . .
        .DB      $00,$04,$10,$01,$00 ; . . . . . . 1 . . 1 . . . . . 1 . . . .
        .DB      $00,$54,$00,$01,$50 ; . . . . 1 1 1 . . . . . . . . 1 1 1 . .

;*******************************************************************************
; WORLUK_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WORLUK_3:
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$10,$10,$00 ; . . . . . . . . . 1 . . . 1 . . . . . .
        .DB      $00,$00,$40,$40,$00 ; . . . . . . . . 1 . . . 1 . . . . . . .
        .DB      $00,$02,$EA,$E0,$00 ; . . . . . . . 2 3 2 2 2 3 2 . . . . . .
        .DB      $00,$0B,$FB,$F8,$00 ; . . . . . . 2 3 3 3 2 3 3 3 2 . . . . .
        .DB      $00,$0F,$FB,$FC,$00 ; . . . . . . 3 3 3 3 2 3 3 3 3 . . . . .
        .DB      $00,$02,$EA,$E0,$00 ; . . . . . . . 2 3 2 2 2 3 2 . . . . . .
        .DB      $00,$A8,$2A,$0A,$80 ; . . . . 2 2 2 . . 2 2 2 . . 2 2 2 . . .
        .DB      $15,$56,$19,$25,$54 ; . 1 1 1 1 1 1 2 . 1 2 1 . 2 1 1 1 1 1 .
        .DB      $06,$A9,$55,$5A,$50 ; . . 1 2 2 2 2 1 1 1 1 1 1 1 2 2 1 1 . .
        .DB      $09,$AA,$55,$69,$A8 ; . . 2 1 2 2 2 2 1 1 1 1 1 2 2 1 2 2 2 .
        .DB      $0A,$68,$55,$46,$A8 ; . . 2 2 1 2 2 . 1 1 1 1 1 . 1 2 2 2 2 .
        .DB      $2A,$A0,$55,$42,$A8 ; . 2 2 2 2 2 . . 1 1 1 1 1 . . 2 2 2 2 .
        .DB      $2A,$95,$55,$55,$A8 ; . 2 2 2 2 1 1 1 1 1 1 1 1 1 1 1 2 2 2 .
        .DB      $2A,$10,$55,$41,$A8 ; . 2 2 2 . 1 . . 1 1 1 1 1 . . 1 2 2 2 .
        .DB      $28,$04,$15,$04,$28 ; . 2 2 . . . 1 . . 1 1 1 . . 1 . . 2 2 .
        .DB      $00,$01,$04,$10,$00 ; . . . . . . . 1 . . 1 . . 1 . . . . . .
        .DB      $00,$15,$40,$55,$00 ; . . . . . 1 1 1 1 . . . 1 1 1 1 . . . .

;*******************************************************************************
; WIZARD_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_1_UP:
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $00,$00,$04,$00,$00 ; . . . . . . . . . . 1 . . . . . . . . .
        .DB      $00,$00,$05,$40,$00 ; . . . . . . . . . . 1 1 1 . . . . . . .
        .DB      $00,$14,$00,$50,$00 ; . . . . . 1 1 . . . . . 1 1 . . . . . .
        .DB      $11,$54,$00,$15,$40 ; . 1 . 1 1 1 1 . . . . . . 1 1 1 1 . . .
        .DB      $15,$55,$00,$16,$10 ; . 1 1 1 1 1 1 1 . . . . . 1 1 2 . 1 . .
        .DB      $15,$55,$40,$50,$10 ; . 1 1 1 1 1 1 1 1 . . . 1 1 . . . 1 . .
        .DB      $15,$55,$55,$42,$14 ; . 1 1 1 1 1 1 1 1 1 1 1 1 . . 2 . 1 1 .
        .DB      $15,$55,$55,$54,$14 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . 1 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$55,$55,$04 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . 1 .
        .DB      $15,$55,$54,$15,$00 ; . 1 1 1 1 1 1 1 1 1 1 . . 1 1 1 . . . .
        .DB      $15,$54,$00,$14,$00 ; . 1 1 1 1 1 1 . . . . . . 1 1 . . . . .
        .DB      $15,$40,$00,$10,$00 ; . 1 1 1 1 . . . . . . . . 1 . . . . . .
        .DB      $15,$00,$00,$50,$00 ; . 1 1 1 . . . . . . . . 1 1 . . . . . .
        .DB      $14,$00,$01,$40,$00 ; . 1 1 . . . . . . . . 1 1 . . . . . . .
        .DB      $00,$00,$3D,$00,$00 ; . . . . . . . . . 3 3 1 . . . . . . . .

;*******************************************************************************
; WIZARD_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_2_UP:
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $00,$00,$04,$00,$00 ; . . . . . . . . . . 1 . . . . . . . . .
        .DB      $00,$04,$05,$11,$50 ; . . . . . . 1 . . . 1 1 . 1 . 1 1 1 . .
        .DB      $10,$15,$00,$55,$84 ; . 1 . . . 1 1 1 . . . . 1 1 1 1 2 . 1 .
        .DB      $10,$55,$40,$14,$04 ; . 1 . . 1 1 1 1 1 . . . . 1 1 . . . 1 .
        .DB      $15,$55,$50,$50,$94 ; . 1 1 1 1 1 1 1 1 1 . . 1 1 . . 2 1 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$55,$55,$50 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $05,$55,$55,$55,$00 ; . . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $05,$55,$55,$05,$00 ; . . 1 1 1 1 1 1 1 1 1 1 . . 1 1 . . . .
        .DB      $05,$54,$54,$14,$00 ; . . 1 1 1 1 1 . 1 1 1 . . 1 1 . . . . .
        .DB      $05,$50,$00,$50,$00 ; . . 1 1 1 1 . . . . . . 1 1 . . . . . .
        .DB      $05,$40,$01,$40,$00 ; . . 1 1 1 . . . . . . 1 1 . . . . . . .
        .DB      $01,$00,$3D,$00,$00 ; . . . 1 . . . . . 3 3 1 . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .

;*******************************************************************************
; WIZARD_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_3_UP:
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$C0,$00,$00 ; . . . . . . . . 3 . . . . . . . . . . .
        .DB      $00,$00,$C0,$05,$40 ; . . . . . . . . 3 . . . . . 1 1 1 . . .
        .DB      $14,$14,$10,$56,$10 ; . 1 1 . . 1 1 . . 1 . . 1 1 1 2 . 1 . .
        .DB      $15,$55,$14,$50,$50 ; . 1 1 1 1 1 1 1 . 1 1 . 1 1 . . 1 1 . .
        .DB      $15,$55,$41,$41,$50 ; . 1 1 1 1 1 1 1 1 . . 1 1 . . 1 1 1 . .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$55,$54,$04 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . 1 .
        .DB      $15,$55,$55,$14,$00 ; . 1 1 1 1 1 1 1 1 1 1 1 . 1 1 . . . . .
        .DB      $14,$15,$D4,$50,$00 ; . 1 1 . . 1 1 1 3 1 1 . 1 1 . . . . . .
        .DB      $00,$01,$F5,$40,$00 ; . . . . . . . 1 3 3 1 1 1 . . . . . . .
        .DB      $00,$00,$05,$00,$00 ; . . . . . . . . . . 1 1 . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .

;*******************************************************************************
; WIZARD_4_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_4_UP:
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $00,$00,$30,$00,$00 ; . . . . . . . . . 3 . . . . . . . . . .
        .DB      $04,$05,$04,$00,$00 ; . . 1 . . . 1 1 . . 1 . . . . . . . . .
        .DB      $04,$55,$45,$01,$50 ; . . 1 . 1 1 1 1 1 . 1 1 . . . 1 1 1 . .
        .DB      $05,$55,$41,$55,$84 ; . . 1 1 1 1 1 1 1 . . 1 1 1 1 1 2 . 1 .
        .DB      $05,$55,$50,$54,$04 ; . . 1 1 1 1 1 1 1 1 . . 1 1 1 . . . 1 .
        .DB      $15,$55,$51,$50,$94 ; . 1 1 1 1 1 1 1 1 1 . 1 1 1 . . 2 1 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$55,$55,$50 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $15,$55,$55,$55,$00 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $15,$01,$54,$14,$00 ; . 1 1 1 . . . 1 1 1 1 . . 1 1 . . . . .
        .DB      $00,$00,$00,$14,$00 ; . . . . . . . . . . . . . 1 1 . . . . .
        .DB      $00,$00,$00,$50,$00 ; . . . . . . . . . . . . 1 1 . . . . . .
        .DB      $00,$00,$05,$40,$00 ; . . . . . . . . . . 1 1 1 . . . . . . .
        .DB      $00,$00,$F4,$00,$00 ; . . . . . . . . 3 3 1 . . . . . . . . .
        .DB      $00,$00,$00,$00,$00 ; . . . . . . . . . . . . . . . . . . . .

;*******************************************************************************
; WIZARD_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_1:
        .DB      $00,$00,$15,$40,$00 ; . . . . . . . . . 1 1 1 1 . . . . . . .
        .DB      $00,$01,$55,$00,$00 ; . . . . . . . 1 1 1 1 1 . . . . . . . .
        .DB      $00,$04,$01,$00,$00 ; . . . . . . 1 . . . . 1 . . . . . . . .
        .DB      $00,$06,$21,$50,$00 ; . . . . . . 1 2 . 2 . 1 1 1 . . . . . .
        .DB      $00,$05,$05,$54,$00 ; . . . . . . 1 1 . . 1 1 1 1 1 . . . . .
        .DB      $00,$15,$45,$55,$40 ; . . . . . 1 1 1 1 . 1 1 1 1 1 1 1 . . .
        .DB      $00,$50,$55,$40,$50 ; . . . . 1 1 . . 1 1 1 1 1 . . . 1 1 . .
        .DB      $00,$40,$15,$40,$14 ; . . . . 1 . . . . 1 1 1 1 . . . . 1 1 .
        .DB      $01,$40,$15,$50,$0C ; . . . 1 1 . . . . 1 1 1 1 1 . . . . 3 .
        .DB      $3C,$00,$15,$50,$0C ; . 3 3 . . . . . . 1 1 1 1 1 . . . . 3 .
        .DB      $00,$00,$55,$50,$00 ; . . . . . . . . 1 1 1 1 1 1 . . . . . .
        .DB      $00,$01,$55,$50,$00 ; . . . . . . . 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$54,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$15,$55,$54,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$05,$55,$55,$00 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $00,$05,$55,$55,$40 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 . . .
        .DB      $00,$01,$55,$55,$50 ; . . . . . . . 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$05,$55,$55,$50 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . .

;*******************************************************************************
; WIZARD_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_2:
        .DB      $00,$05,$50,$00,$00 ; . . . . . . 1 1 1 1 . . . . . . . . . .
        .DB      $00,$10,$54,$00,$00 ; . . . . . 1 . . 1 1 1 . . . . . . . . .
        .DB      $00,$18,$94,$00,$00 ; . . . . . 1 2 . 2 1 1 . . . . . . . . .
        .DB      $00,$14,$15,$40,$00 ; . . . . . 1 1 . . 1 1 1 1 . . . . . . .
        .DB      $00,$05,$15,$50,$00 ; . . . . . . 1 1 . 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$14,$00 ; . . . . . 1 1 1 1 1 1 1 . 1 1 . . . . .
        .DB      $00,$04,$55,$05,$00 ; . . . . . . 1 . 1 1 1 1 . . 1 1 . . . .
        .DB      $00,$10,$15,$41,$40 ; . . . . . 1 . . . 1 1 1 1 . . 1 1 . . .
        .DB      $00,$50,$15,$50,$C0 ; . . . . 1 1 . . . 1 1 1 1 1 . . 3 . . .
        .DB      $0F,$00,$55,$50,$C0 ; . . 3 3 . . . . 1 1 1 1 1 1 . . 3 . . .
        .DB      $00,$01,$55,$50,$00 ; . . . . . . . 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$40,$00 ; . . . . . . 1 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$15,$55,$50,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$54,$00 ; . . . . . . 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$01,$55,$55,$00 ; . . . . . . . 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $00,$00,$55,$55,$40 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 . . .
        .DB      $00,$00,$55,$55,$00 ; . . . . . . . . 1 1 1 1 1 1 1 1 . . . .
        .DB      $00,$05,$54,$00,$00 ; . . . . . . 1 1 1 1 1 . . . . . . . . .

;*******************************************************************************
; WIZARD_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_3:
        .DB      $00,$00,$15,$00,$00 ; . . . . . . . . . 1 1 1 . . . . . . . .
        .DB      $00,$05,$54,$00,$00 ; . . . . . . 1 1 1 1 1 . . . . . . . . .
        .DB      $00,$11,$54,$00,$00 ; . . . . . 1 . 1 1 1 1 . . . . . . . . .
        .DB      $00,$18,$54,$00,$00 ; . . . . . 1 2 . 1 1 1 . . . . . . . . .
        .DB      $00,$14,$15,$40,$00 ; . . . . . 1 1 . . 1 1 1 1 . . . . . . .
        .DB      $00,$05,$15,$50,$00 ; . . . . . . 1 1 . 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$14,$00 ; . . . . . . 1 1 1 1 1 1 . 1 1 . . . . .
        .DB      $00,$00,$55,$45,$00 ; . . . . . . . . 1 1 1 1 1 . 1 1 . . . .
        .DB      $00,$01,$15,$55,$00 ; . . . . . . . 1 . 1 1 1 1 1 1 1 . . . .
        .DB      $00,$05,$15,$5C,$00 ; . . . . . . 1 1 . 1 1 1 1 1 3 . . . . .
        .DB      $00,$F0,$55,$7C,$00 ; . . . . 3 3 . . 1 1 1 1 1 3 3 . . . . .
        .DB      $00,$01,$55,$54,$00 ; . . . . . . . 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$01,$55,$40,$00 ; . . . . . . . 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$01,$55,$40,$00 ; . . . . . . . 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .

;*******************************************************************************
; WIZARD_4
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_4:
        .DB      $00,$01,$54,$00,$00 ; . . . . . . . 1 1 1 1 . . . . . . . . .
        .DB      $00,$04,$15,$00,$00 ; . . . . . . 1 . . 1 1 1 . . . . . . . .
        .DB      $00,$06,$25,$00,$00 ; . . . . . . 1 2 . 2 1 1 . . . . . . . .
        .DB      $00,$05,$05,$40,$00 ; . . . . . . 1 1 . . 1 1 1 . . . . . . .
        .DB      $00,$01,$45,$54,$00 ; . . . . . . . 1 1 . 1 1 1 1 1 . . . . .
        .DB      $00,$01,$55,$55,$00 ; . . . . . . . 1 1 1 1 1 1 1 1 1 . . . .
        .DB      $00,$01,$55,$41,$40 ; . . . . . . . 1 1 1 1 1 1 . . 1 1 . . .
        .DB      $00,$05,$15,$40,$40 ; . . . . . . 1 1 . 1 1 1 1 . . . 1 . . .
        .DB      $00,$14,$05,$50,$50 ; . . . . . 1 1 . . . 1 1 1 1 . . 1 1 . .
        .DB      $03,$C0,$55,$50,$30 ; . . . 3 3 . . . 1 1 1 1 1 1 . . . 3 . .
        .DB      $00,$05,$55,$50,$30 ; . . . . . . 1 1 1 1 1 1 1 1 . . . 3 . .
        .DB      $00,$15,$55,$50,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$40,$00 ; . . . . . 1 1 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$05,$55,$40,$00 ; . . . . . . 1 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$05,$55,$40,$00 ; . . . . . . 1 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$01,$55,$50,$00 ; . . . . . . . 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$50,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$00,$15,$50,$00 ; . . . . . . . . . 1 1 1 1 1 . . . . . .

;*******************************************************************************
; WIZARD_1_FIRE_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_1_FIRE_UP:
        .DB      $00,$00,$00,$03,$00 ; . . . . . . . . . . . . . . . 3 . . . .
        .DB      $00,$00,$00,$03,$00 ; . . . . . . . . . . . . . . . 3 . . . .
        .DB      $10,$00,$00,$03,$C0 ; . 1 . . . . . . . . . . . . . 3 3 . . .
        .DB      $14,$00,$00,$5F,$00 ; . 1 1 . . . . . . . . . 1 1 3 3 . . . .
        .DB      $15,$50,$01,$54,$00 ; . 1 1 1 1 1 . . . . . 1 1 1 1 . . . . .
        .DB      $15,$54,$01,$40,$00 ; . 1 1 1 1 1 1 . . . . 1 1 . . . . . . .
        .DB      $15,$55,$01,$50,$00 ; . 1 1 1 1 1 1 1 . . . 1 1 1 . . . . . .
        .DB      $15,$55,$41,$51,$50 ; . 1 1 1 1 1 1 1 1 . . 1 1 1 . 1 1 1 . .
        .DB      $15,$55,$55,$55,$84 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 . 1 .
        .DB      $15,$55,$55,$50,$04 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . . 1 .
        .DB      $15,$55,$55,$40,$84 ; . 1 1 1 1 1 1 1 1 1 1 1 1 . . . 2 . 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$55,$00,$50,$50 ; . 1 1 1 1 1 1 1 . . . . 1 1 . . 1 1 . .
        .DB      $15,$40,$01,$50,$00 ; . 1 1 1 1 . . . . . . 1 1 1 . . . . . .
        .DB      $10,$00,$05,$4C,$00 ; . 1 . . . . . . . . 1 1 1 . 3 . . . . .
        .DB      $00,$00,$05,$FC,$00 ; . . . . . . . . . . 1 1 3 3 3 . . . . .
        .DB      $00,$00,$01,$7C,$00 ; . . . . . . . . . . . 1 1 3 3 . . . . .
        .DB      $00,$00,$00,$5C,$00 ; . . . . . . . . . . . . 1 1 3 . . . . .

;*******************************************************************************
; WIZARD_2_FIRE_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_2_FIRE_UP:
        .DB      $00,$00,$00,$0C,$00 ; . . . . . . . . . . . . . . 3 . . . . .
        .DB      $00,$00,$00,$0C,$00 ; . . . . . . . . . . . . . . 3 . . . . .
        .DB      $00,$00,$00,$0C,$00 ; . . . . . . . . . . . . . . 3 . . . . .
        .DB      $10,$00,$00,$3C,$00 ; . 1 . . . . . . . . . . . 3 3 . . . . .
        .DB      $10,$00,$03,$F0,$00 ; . 1 . . . . . . . . . 3 3 3 . . . . . .
        .DB      $15,$00,$03,$C0,$00 ; . 1 1 1 . . . . . . . 3 3 . . . . . . .
        .DB      $15,$54,$00,$14,$00 ; . 1 1 1 1 1 1 . . . . . . 1 1 . . . . .
        .DB      $15,$55,$00,$14,$00 ; . 1 1 1 1 1 1 1 . . . . . 1 1 . . . . .
        .DB      $15,$55,$40,$14,$00 ; . 1 1 1 1 1 1 1 1 . . . . 1 1 . . . . .
        .DB      $15,$55,$55,$55,$50 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $15,$55,$55,$54,$94 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . 2 1 1 .
        .DB      $15,$55,$55,$C0,$04 ; . 1 1 1 1 1 1 1 1 1 1 1 3 . . . . . 1 .
        .DB      $15,$05,$45,$D0,$94 ; . 1 1 1 . . 1 1 1 . 1 1 3 1 . . 2 1 1 .
        .DB      $14,$00,$01,$D5,$50 ; . 1 1 . . . . . . . . 1 3 1 1 1 1 1 . .
        .DB      $10,$00,$00,$D1,$50 ; . 1 . . . . . . . . . . 3 1 . 1 1 1 . .
        .DB      $00,$00,$03,$D0,$40 ; . . . . . . . . . . . 3 3 1 . . 1 . . .
        .DB      $00,$00,$0F,$40,$00 ; . . . . . . . . . . 3 3 1 . . . . . . .
        .DB      $00,$00,$0F,$00,$00 ; . . . . . . . . . . 3 3 . . . . . . . .

;*******************************************************************************
; WIZARD_3_FIRE_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_3_FIRE_UP:
        .DB      $00,$00,$00,$22,$00 ; . . . . . . . . . . . . . 2 . 2 . . . .
        .DB      $00,$00,$00,$22,$00 ; . . . . . . . . . . . . . 2 . 2 . . . .
        .DB      $00,$00,$00,$20,$00 ; . . . . . . . . . . . . . 2 . . . . . .
        .DB      $00,$00,$00,$0C,$C0 ; . . . . . . . . . . . . . . 3 . 3 . . .
        .DB      $00,$00,$00,$3C,$C0 ; . . . . . . . . . . . . . 3 3 . 3 . . .
        .DB      $10,$00,$00,$F3,$C0 ; . 1 . . . . . . . . . . 3 3 . 3 3 . . .
        .DB      $10,$00,$01,$51,$40 ; . 1 . . . . . . . . . 1 1 1 . 1 1 . . .
        .DB      $15,$00,$00,$51,$40 ; . 1 1 1 . . . . . . . . 1 1 . 1 1 . . .
        .DB      $15,$54,$00,$15,$00 ; . 1 1 1 1 1 1 . . . . . . 1 1 1 . . . .
        .DB      $15,$55,$00,$15,$00 ; . 1 1 1 1 1 1 1 . . . . . 1 1 1 . . . .
        .DB      $15,$55,$40,$14,$00 ; . 1 1 1 1 1 1 1 1 . . . . 1 1 . . . . .
        .DB      $15,$55,$40,$14,$10 ; . 1 1 1 1 1 1 1 1 . . . . 1 1 . . 1 . .
        .DB      $15,$55,$50,$54,$94 ; . 1 1 1 1 1 1 1 1 1 . . 1 1 1 . 2 1 1 .
        .DB      $15,$55,$55,$54,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 . 1 1 1 .
        .DB      $15,$55,$55,$55,$54 ; . 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $15,$01,$55,$55,$54 ; . 1 1 1 . . . 1 1 1 1 1 1 1 1 1 1 1 1 .
        .DB      $14,$00,$05,$51,$50 ; . 1 1 . . . . . . . 1 1 1 1 . 1 1 1 . .
        .DB      $10,$00,$00,$00,$40 ; . 1 . . . . . . . . . . . . . . 1 . . .

;*******************************************************************************
; WIZARD_1_FIRE
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_1_FIRE:
        .DB      $00,$00,$15,$40,$00 ; . . . . . . . . . 1 1 1 1 . . . . . . .
        .DB      $00,$00,$40,$50,$00 ; . . . . . . . . 1 . . . 1 1 . . . . . .
        .DB      $03,$00,$62,$50,$00 ; . . . 3 . . . . 1 2 . 2 1 1 . . . . . .
        .DB      $3F,$C0,$50,$40,$00 ; . 3 3 3 3 . . . 1 1 . . 1 . . . . . . .
        .DB      $00,$D0,$10,$43,$FC ; . . . . 3 1 . . . 1 . . 1 . . 3 3 3 3 .
        .DB      $00,$51,$54,$54,$F4 ; . . . . 1 1 . 1 1 1 1 . 1 1 1 . 3 3 1 .
        .DB      $00,$55,$55,$55,$D4 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 3 1 1 .
        .DB      $00,$15,$55,$45,$50 ; . . . . . 1 1 1 1 1 1 1 1 . 1 1 1 1 . .
        .DB      $00,$00,$15,$41,$40 ; . . . . . . . . . 1 1 1 1 . . 1 1 . . .
        .DB      $00,$00,$15,$40,$00 ; . . . . . . . . . 1 1 1 1 . . . . . . .
        .DB      $00,$00,$55,$40,$00 ; . . . . . . . . 1 1 1 1 1 . . . . . . .
        .DB      $00,$01,$55,$50,$00 ; . . . . . . . 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$50,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$15,$55,$54,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$15,$55,$54,$00 ; . . . . . 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$55,$55,$54,$00 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $01,$55,$55,$55,$00 ; . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; WIZARD_2_FIRE
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_2_FIRE:
        .DB      $00,$00,$01,$50,$00 ; . . . . . . . . . . . 1 1 1 . . . . . .
        .DB      $00,$00,$05,$15,$00 ; . . . . . . . . . . 1 1 . 1 1 1 . . . .
        .DB      $00,$00,$06,$25,$40 ; . . . . . . . . . . 1 2 . 2 1 1 1 . . .
        .DB      $00,$00,$04,$05,$00 ; . . . . . . . . . . 1 . . . 1 1 . . . .
        .DB      $3F,$C1,$55,$04,$00 ; . 3 3 3 3 . . 1 1 1 1 1 . . 1 . . . . .
        .DB      $00,$F1,$55,$15,$40 ; . . . . 3 3 . 1 1 1 1 1 . 1 1 1 1 . . .
        .DB      $00,$3C,$05,$FF,$D0 ; . . . . . 3 3 . . . 1 1 3 3 3 3 3 1 . .
        .DB      $00,$3C,$05,$54,$FC ; . . . . . 3 3 . . . 1 1 1 1 1 . 3 3 3 .
        .DB      $00,$00,$05,$50,$3C ; . . . . . . . . . . 1 1 1 1 . . . 3 3 .
        .DB      $00,$00,$05,$40,$00 ; . . . . . . . . . . 1 1 1 . . . . . . .
        .DB      $00,$00,$15,$50,$00 ; . . . . . . . . . 1 1 1 1 1 . . . . . .
        .DB      $00,$00,$55,$50,$00 ; . . . . . . . . 1 1 1 1 1 1 . . . . . .
        .DB      $00,$01,$55,$50,$00 ; . . . . . . . 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$01,$55,$40,$00 ; . . . . . . . 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$01,$55,$40,$00 ; . . . . . . . 1 1 1 1 1 1 . . . . . . .
        .DB      $00,$05,$55,$50,$00 ; . . . . . . 1 1 1 1 1 1 1 1 . . . . . .
        .DB      $00,$05,$55,$54,$00 ; . . . . . . 1 1 1 1 1 1 1 1 1 . . . . .
        .DB      $00,$55,$55,$55,$00 ; . . . . 1 1 1 1 1 1 1 1 1 1 1 1 . . . .

;*******************************************************************************
; WIZARD_3_FIRE
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
WIZARD_3_FIRE:
        .DB      $00,$00,$00,$15,$40 ; . . . . . . . . . . . . . 1 1 1 1 . . .
        .DB      $00,$00,$00,$55,$50 ; . . . . . . . . . . . . 1 1 1 1 1 1 . .
        .DB      $00,$FD,$40,$25,$54 ; . . . . 3 3 3 1 1 . . . . 2 1 1 1 1 1 .
        .DB      $28,$0D,$54,$01,$50 ; . 2 2 . . . 3 1 1 1 1 . . . . 1 1 1 . .
        .DB      $00,$F0,$15,$55,$40 ; . . . . 3 3 . . . 1 1 1 1 1 1 1 1 . . .
        .DB      $2A,$3D,$55,$55,$50 ; . 2 2 2 . 3 3 1 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$0D,$40,$15,$50 ; . . . . . . 3 1 1 . . . . 1 1 1 1 1 . .
        .DB      $00,$01,$00,$05,$50 ; . . . . . . . 1 . . . . . . 1 1 1 1 . .
        .DB      $00,$00,$00,$05,$50 ; . . . . . . . . . . . . . . 1 1 1 1 . .
        .DB      $00,$00,$00,$15,$40 ; . . . . . . . . . . . . . 1 1 1 1 . . .
        .DB      $00,$00,$01,$55,$40 ; . . . . . . . . . . . 1 1 1 1 1 1 . . .
        .DB      $00,$00,$05,$55,$40 ; . . . . . . . . . . 1 1 1 1 1 1 1 . . .
        .DB      $00,$00,$15,$55,$00 ; . . . . . . . . . 1 1 1 1 1 1 1 . . . .
        .DB      $00,$00,$15,$55,$00 ; . . . . . . . . . 1 1 1 1 1 1 1 . . . .
        .DB      $00,$00,$15,$55,$00 ; . . . . . . . . . 1 1 1 1 1 1 1 . . . .
        .DB      $00,$00,$55,$55,$40 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 . . .
        .DB      $00,$00,$55,$55,$50 ; . . . . . . . . 1 1 1 1 1 1 1 1 1 1 . .
        .DB      $00,$05,$55,$55,$54 ; . . . . . . 1 1 1 1 1 1 1 1 1 1 1 1 1 .

;*******************************************************************************
; GARWOR_FIRE_0_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_0_UP:
        .DB      $00,$00,$08,$10,$00 ; . . . . . . . . . . 2 . . 1 . . . . . .
        .DB      $00,$00,$C3,$00,$00 ; . . . . . . . . 3 . . 3 . . . . . . . .
        .DB      $00,$00,$03,$28,$00 ; . . . . . . . . . . . 3 . 2 2 . . . . .
        .DB      $00,$00,$2F,$E8,$00 ; . . . . . . . . . 2 3 3 3 2 2 . . . . .
        .DB      $00,$00,$2F,$AA,$00 ; . . . . . . . . . 2 3 3 2 2 2 2 . . . .
        .DB      $00,$20,$2B,$EA,$00 ; . . . . . 2 . . . 2 2 3 3 2 2 2 . . . .
        .DB      $00,$08,$2F,$AA,$80 ; . . . . . . 2 . . 2 3 3 2 2 2 2 2 . . .
        .DB      $00,$08,$2B,$EA,$A0 ; . . . . . . 2 . . 2 2 3 3 2 2 2 2 2 . .
        .DB      $20,$0A,$0A,$A4,$A0 ; . 2 . . . . 2 2 . . 2 2 2 2 1 . 2 2 . .
        .DB      $20,$2A,$A2,$A0,$A0 ; . 2 . . . 2 2 2 2 2 . 2 2 2 . . 2 2 . .
        .DB      $2A,$AA,$AA,$AA,$A0 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $0A,$AA,$AA,$AA,$A0 ; . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $02,$AA,$AA,$AA,$80 ; . . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $20,$AA,$AA,$A8,$0C ; . 2 . . 2 2 2 2 2 2 2 2 2 2 2 . . . 3 .
        .DB      $2A,$2A,$AA,$A0,$3C ; . 2 2 2 . 2 2 2 2 2 2 2 2 2 . . . 3 3 .
        .DB      $00,$2A,$AA,$00,$F0 ; . . . . . 2 2 2 2 2 2 2 . . . . 3 3 . .
        .DB      $00,$02,$A0,$AA,$F0 ; . . . . . . . 2 2 2 . . 2 2 2 2 3 3 . .

;*******************************************************************************
; GARWOR_FIRE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_1_UP:
        .DB      $00,$00,$2E,$4C,$00 ; . . . . . . . . . 2 3 2 1 . 3 . . . . .
        .DB      $00,$00,$6A,$80,$00 ; . . . . . . . . 1 2 2 2 2 . . . . . . .
        .DB      $00,$00,$07,$0A,$00 ; . . . . . . . . . . 1 3 . . 2 2 . . . .
        .DB      $00,$00,$03,$0A,$00 ; . . . . . . . . . . . 3 . . 2 2 . . . .
        .DB      $00,$00,$2F,$EA,$80 ; . . . . . . . . . 2 3 3 3 2 2 2 2 . . .
        .DB      $00,$00,$2F,$FA,$80 ; . . . . . . . . . 2 3 3 3 3 2 2 2 . . .
        .DB      $00,$20,$2F,$EA,$A0 ; . . . . . 2 . . . 2 3 3 3 2 2 2 2 2 . .
        .DB      $00,$08,$2B,$FA,$A8 ; . . . . . . 2 . . 2 2 3 3 3 2 2 2 2 2 .
        .DB      $00,$02,$AB,$E9,$28 ; . . . . . . . 2 2 2 2 3 3 2 2 1 . 2 2 .
        .DB      $00,$2A,$AA,$F8,$28 ; . . . . . 2 2 2 2 2 2 2 3 3 2 . . 2 2 .
        .DB      $20,$AA,$AA,$AA,$A8 ; . 2 . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $22,$AA,$AA,$AA,$A8 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $2A,$AA,$AA,$AA,$80 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$AA,$AA,$A0,$F0 ; . . . . 2 2 2 2 2 2 2 2 2 2 . . 3 3 . .
        .DB      $02,$2A,$AA,$0B,$FC ; . . . 2 . 2 2 2 2 2 2 2 . . 2 3 3 3 3 .
        .DB      $02,$2A,$A0,$23,$F0 ; . . . 2 . 2 2 2 2 2 . . . 2 . 3 3 3 . .
        .DB      $0A,$0A,$AA,$80,$00 ; . . 2 2 . . 2 2 2 2 2 2 2 . . . . . . .

;*******************************************************************************
; GARWOR_FIRE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_2_UP:
        .DB      $00,$00,$E2,$58,$C0 ; . . . . . . . . 3 2 . 2 1 1 2 . 3 . . .
        .DB      $00,$03,$0B,$40,$00 ; . . . . . . . 3 . . 2 3 1 . . . . . . .
        .DB      $00,$0A,$07,$0A,$00 ; . . . . . . 2 2 . . 1 3 . . 2 2 . . . .
        .DB      $00,$06,$03,$CA,$00 ; . . . . . . 1 2 . . . 3 3 . 2 2 . . . .
        .DB      $00,$00,$2F,$EA,$80 ; . . . . . . . . . 2 3 3 3 2 2 2 2 . . .
        .DB      $00,$00,$2F,$FA,$80 ; . . . . . . . . . 2 3 3 3 3 2 2 2 . . .
        .DB      $00,$20,$2F,$EA,$A0 ; . . . . . 2 . . . 2 3 3 3 2 2 2 2 2 . .
        .DB      $00,$08,$2B,$FA,$A8 ; . . . . . . 2 . . 2 2 3 3 3 2 2 2 2 2 .
        .DB      $00,$02,$AB,$E9,$28 ; . . . . . . . 2 2 2 2 3 3 2 2 1 . 2 2 .
        .DB      $00,$2A,$AA,$F8,$28 ; . . . . . 2 2 2 2 2 2 2 3 3 2 . . 2 2 .
        .DB      $20,$AA,$AA,$AA,$A8 ; . 2 . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $22,$AA,$AA,$AA,$A8 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $2A,$AA,$AA,$AA,$80 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$AA,$AA,$A3,$F0 ; . . . . 2 2 2 2 2 2 2 2 2 2 . 3 3 3 . .
        .DB      $02,$2A,$AA,$0B,$FC ; . . . 2 . 2 2 2 2 2 2 2 . . 2 3 3 3 3 .
        .DB      $02,$2A,$A0,$20,$FC ; . . . 2 . 2 2 2 2 2 . . . 2 . . 3 3 3 .
        .DB      $0A,$0A,$AA,$80,$0C ; . . 2 2 . . 2 2 2 2 2 2 2 . . . . . 3 .

;*******************************************************************************
; GARWOR_FIRE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_3_UP:
        .DB      $00,$00,$C8,$04,$30 ; . . . . . . . . 3 . 2 . . . 1 . . 3 . .
        .DB      $00,$00,$00,$C0,$00 ; . . . . . . . . . . . . 3 . . . . . . .
        .DB      $00,$00,$13,$CA,$00 ; . . . . . . . . . 1 . 3 3 . 2 2 . . . .
        .DB      $00,$04,$03,$CA,$00 ; . . . . . . 1 . . . . 3 3 . 2 2 . . . .
        .DB      $00,$00,$2F,$EA,$80 ; . . . . . . . . . 2 3 3 3 2 2 2 2 . . .
        .DB      $00,$00,$2F,$FA,$80 ; . . . . . . . . . 2 3 3 3 3 2 2 2 . . .
        .DB      $00,$02,$2F,$EA,$A0 ; . . . . . . . 2 . 2 3 3 3 2 2 2 2 2 . .
        .DB      $02,$02,$2B,$FA,$A8 ; . . . 2 . . . 2 . 2 2 3 3 3 2 2 2 2 2 .
        .DB      $0A,$8A,$AB,$E9,$28 ; . . 2 2 2 . 2 2 2 2 2 3 3 2 2 1 . 2 2 .
        .DB      $28,$AA,$AA,$F8,$28 ; . 2 2 . 2 2 2 2 2 2 2 2 3 3 2 . . 2 2 .
        .DB      $00,$AA,$AA,$AA,$A8 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $22,$AA,$AA,$AA,$A8 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $2A,$AA,$AA,$AA,$80 ; . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . . .
        .DB      $00,$AA,$AA,$AA,$00 ; . . . . 2 2 2 2 2 2 2 2 2 2 2 2 . . . .
        .DB      $00,$2A,$AA,$A0,$0C ; . . . . . 2 2 2 2 2 2 2 2 2 . . . . 3 .
        .DB      $00,$2A,$AA,$00,$3C ; . . . . . 2 2 2 2 2 2 2 . . . . . 3 3 .
        .DB      $00,$0A,$80,$00,$F0 ; . . . . . . 2 2 2 . . . . . . . 3 3 . .
        .DB      $00,$02,$AA,$AA,$F0 ; . . . . . . . 2 2 2 2 2 2 2 2 2 3 3 . .

;*******************************************************************************
; GARWOR_FIRE_0
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_0:
        .DB      $00,$00,$00,$03,$C0 ; . . . . . . . . . . . . . . . 3 3 . . .
        .DB      $00,$00,$AA,$80,$FC ; . . . . . . . . 2 2 2 2 2 . . . 3 3 3 .
        .DB      $00,$02,$AA,$A0,$3C ; . . . . . . . 2 2 2 2 2 2 2 . . . 3 3 .
        .DB      $00,$2A,$82,$A8,$08 ; . . . . . 2 2 2 2 . . 2 2 2 2 . . . 2 .
        .DB      $02,$AA,$92,$AA,$08 ; . . . 2 2 2 2 2 2 1 . 2 2 2 2 2 . . 2 .
        .DB      $12,$AA,$AA,$AA,$88 ; . 1 . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $00,$EE,$EA,$AA,$88 ; . . . . 3 2 3 2 3 2 2 2 2 2 2 2 2 . 2 .
        .DB      $0F,$FF,$EA,$AA,$A0 ; . . 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 . .
        .DB      $20,$FB,$A2,$AA,$A0 ; . 2 . . 3 3 2 3 2 2 . 2 2 2 2 2 2 2 . .
        .DB      $00,$AA,$8A,$AA,$A8 ; . . . . 2 2 2 2 2 . 2 2 2 2 2 2 2 2 2 .
        .DB      $0C,$00,$0A,$AA,$A8 ; . . 3 . . . . . . . 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$00,$2A,$AA,$A8 ; . . . . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$02,$AA,$AA,$A0 ; . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$08,$0A,$AA,$A0 ; . . . . . . 2 . . . 2 2 2 2 2 2 2 2 . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $00,$00,$02,$A0,$80 ; . . . . . . . . . . . 2 2 2 . . 2 . . .
        .DB      $00,$00,$02,$80,$80 ; . . . . . . . . . . . 2 2 . . . 2 . . .
        .DB      $00,$00,$2A,$02,$80 ; . . . . . . . . . 2 2 2 . . . 2 2 . . .

;*******************************************************************************
; GARWOR_FIRE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_1:
        .DB      $00,$00,$AA,$80,$C0 ; . . . . . . . . 2 2 2 2 2 . . . 3 . . .
        .DB      $00,$02,$AA,$83,$F0 ; . . . . . . . 2 2 2 2 2 2 . . 3 3 3 . .
        .DB      $00,$2A,$82,$A3,$F0 ; . . . . . 2 2 2 2 . . 2 2 2 . 3 3 3 . .
        .DB      $02,$AA,$92,$A8,$F0 ; . . . 2 2 2 2 2 2 1 . 2 2 2 2 . 3 3 . .
        .DB      $32,$AA,$AA,$A8,$80 ; . 3 . 2 2 2 2 2 2 2 2 2 2 2 2 . 2 . . .
        .DB      $00,$2E,$EE,$AA,$20 ; . . . . . 2 3 2 3 2 3 2 2 2 2 2 . 2 . .
        .DB      $18,$3F,$FE,$AA,$08 ; . 1 2 . . 3 3 3 3 3 3 2 2 2 2 2 . . 2 .
        .DB      $2B,$FF,$FA,$AA,$88 ; . 2 2 3 3 3 3 3 3 3 2 2 2 2 2 2 2 . 2 .
        .DB      $39,$3F,$AA,$AA,$88 ; . 3 2 1 . 3 3 3 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $28,$2A,$AA,$AA,$A8 ; . 2 2 . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $04,$00,$2A,$AA,$A8 ; . . 1 . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$00,$2A,$AA,$A8 ; . . . . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$00,$8A,$AA,$A8 ; . . . . . . . . 2 . 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$02,$0A,$AA,$A0 ; . . . . . . . 2 . . 2 2 2 2 2 2 2 2 . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $00,$00,$00,$A0,$A8 ; . . . . . . . . . . . . 2 2 . . 2 2 2 .
        .DB      $00,$00,$00,$20,$08 ; . . . . . . . . . . . . . 2 . . . . 2 .
        .DB      $00,$00,$02,$A0,$00 ; . . . . . . . . . . . 2 2 2 . . . . . .

;*******************************************************************************
; GARWOR_FIRE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_2:
        .DB      $00,$00,$AA,$80,$FC ; . . . . . . . . 2 2 2 2 2 . . . 3 3 3 .
        .DB      $00,$02,$AA,$83,$F0 ; . . . . . . . 2 2 2 2 2 2 . . 3 3 3 . .
        .DB      $30,$2A,$82,$A3,$F0 ; . 3 . . . 2 2 2 2 . . 2 2 2 . 3 3 3 . .
        .DB      $02,$AA,$92,$AB,$C0 ; . . . 2 2 2 2 2 2 1 . 2 2 2 2 3 3 . . .
        .DB      $22,$AA,$AA,$A8,$80 ; . 2 . 2 2 2 2 2 2 2 2 2 2 2 2 . 2 . . .
        .DB      $10,$2E,$EE,$AA,$20 ; . 1 . . . 2 3 2 3 2 3 2 2 2 2 2 . 2 . .
        .DB      $14,$FF,$FE,$AA,$08 ; . 1 1 . 3 3 3 3 3 3 3 2 2 2 2 2 . . 2 .
        .DB      $2F,$FF,$FA,$AA,$88 ; . 2 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 . 2 .
        .DB      $09,$3F,$AA,$AA,$88 ; . . 2 1 . 3 3 3 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $2C,$2A,$AA,$AA,$A8 ; . 2 3 . . 2 2 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $3C,$00,$2A,$AA,$A8 ; . 3 3 . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $0E,$80,$2A,$AA,$A8 ; . . 3 2 2 . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $02,$40,$8A,$AA,$A8 ; . . . 2 1 . . . 2 . 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$02,$0A,$AA,$A0 ; . . . . . . . 2 . . 2 2 2 2 2 2 2 2 . .
        .DB      $00,$00,$02,$AA,$00 ; . . . . . . . . . . . 2 2 2 2 2 . . . .
        .DB      $00,$00,$00,$A0,$A8 ; . . . . . . . . . . . . 2 2 . . 2 2 2 .
        .DB      $00,$00,$00,$20,$08 ; . . . . . . . . . . . . . 2 . . . . 2 .
        .DB      $00,$00,$02,$A0,$00 ; . . . . . . . . . . . 2 2 2 . . . . . .

;*******************************************************************************
; GARWOR_FIRE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
GARWOR_FIRE_3:
        .DB      $00,$00,$AA,$83,$C0 ; . . . . . . . . 2 2 2 2 2 . . 3 3 . . .
        .DB      $30,$02,$AA,$80,$FC ; . 3 . . . . . 2 2 2 2 2 2 . . . 3 3 3 .
        .DB      $00,$2A,$82,$A0,$3C ; . . . . . 2 2 2 2 . . 2 2 2 . . . 3 3 .
        .DB      $02,$AA,$92,$A8,$08 ; . . . 2 2 2 2 2 2 1 . 2 2 2 2 . . . 2 .
        .DB      $12,$AA,$AA,$A8,$08 ; . 1 . 2 2 2 2 2 2 2 2 2 2 2 2 . . . 2 .
        .DB      $00,$2E,$EE,$AA,$08 ; . . . . . 2 3 2 3 2 3 2 2 2 2 2 . . 2 .
        .DB      $0F,$FF,$FE,$AA,$08 ; . . 3 3 3 3 3 3 3 3 3 2 2 2 2 2 . . 2 .
        .DB      $03,$FF,$FA,$AA,$88 ; . . . 3 3 3 3 3 3 3 2 2 2 2 2 2 2 . 2 .
        .DB      $20,$3F,$AA,$AA,$88 ; . 2 . . . 3 3 3 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $01,$2A,$AA,$AA,$88 ; . . . 1 . 2 2 2 2 2 2 2 2 2 2 2 2 . 2 .
        .DB      $30,$00,$2A,$AA,$A8 ; . 3 . . . . . . . 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$02,$AA,$AA,$A8 ; . . . . . . . 2 2 2 2 2 2 2 2 2 2 2 2 .
        .DB      $00,$40,$2A,$AA,$A0 ; . . . . 1 . . . . 2 2 2 2 2 2 2 2 2 . .
        .DB      $00,$00,$0A,$AA,$80 ; . . . . . . . . . . 2 2 2 2 2 2 2 . . .
        .DB      $00,$00,$2A,$A8,$00 ; . . . . . . . . . 2 2 2 2 2 2 . . . . .
        .DB      $00,$00,$A0,$A0,$00 ; . . . . . . . . 2 2 . . 2 2 . . . . . .
        .DB      $00,$00,$28,$20,$00 ; . . . . . . . . . 2 2 . . 2 . . . . . .
        .DB      $00,$00,$08,$A0,$00 ; . . . . . . . . . . 2 . 2 2 . . . . . .

;*******************************************************************************
; THORWOR_FIRE_0_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_0_UP:
        .DB      $00,$00,$C0,$C0,$00 ; . . . . . . . . 3 . . . 3 . . . . . . .
        .DB      $00,$0F,$00,$30,$00 ; . . . . . . 3 3 . . . . . 3 . . . . . .
        .DB      $00,$0C,$48,$4C,$00 ; . . . . . . 3 . 1 . 2 . 1 . 3 . . . . .
        .DB      $00,$30,$08,$0C,$00 ; . . . . . 3 . . . . 2 . . . 3 . . . . .
        .DB      $00,$3C,$28,$0C,$00 ; . . . . . 3 3 . . 2 2 . . . 3 . . . . .
        .DB      $00,$3F,$28,$3C,$00 ; . . . . . 3 3 3 . 2 2 . . 3 3 . . . . .
        .DB      $00,$0F,$EB,$CF,$00 ; . . . . . . 3 3 3 2 2 3 3 . 3 3 . . . .
        .DB      $00,$03,$FF,$C3,$C0 ; . . . . . . . 3 3 3 3 3 3 . . 3 3 . . .
        .DB      $1F,$0F,$FF,$D0,$F0 ; . 1 3 3 . . 3 3 3 3 3 3 3 1 . . 3 3 . .
        .DB      $13,$FF,$FF,$FF,$F8 ; . 1 . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 .
        .DB      $00,$0F,$FF,$FF,$C8 ; . . . . . . 3 3 3 3 3 3 3 3 3 3 3 . 2 .
        .DB      $1F,$0F,$FF,$FF,$08 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 3 3 . . 2 .
        .DB      $13,$FF,$FF,$FC,$20 ; . 1 . 3 3 3 3 3 3 3 3 3 3 3 3 . . 2 . .
        .DB      $00,$0F,$FC,$00,$20 ; . . . . . . 3 3 3 3 3 . . . . . . 2 . .
        .DB      $1F,$0F,$F0,$03,$80 ; . 1 3 3 . . 3 3 3 3 . . . . . 3 2 . . .
        .DB      $13,$FF,$F0,$0F,$80 ; . 1 . 3 3 3 3 3 3 3 . . . . 3 3 2 . . .
        .DB      $00,$03,$FC,$0C,$C0 ; . . . . . . . 3 3 3 3 . . . 3 . 3 . . .
        .DB      $00,$00,$3F,$F0,$3C ; . . . . . . . . . 3 3 3 3 3 . . . 3 3 .

;*******************************************************************************
; THORWOR_FIRE_1_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_1_UP:
        .DB      $00,$00,$30,$A0,$00 ; . . . . . . . . . 3 . . 2 2 . . . . . .
        .DB      $00,$03,$C2,$83,$00 ; . . . . . . . 3 3 . . 2 2 . . 3 . . . .
        .DB      $00,$03,$12,$03,$00 ; . . . . . . . 3 . 1 . 2 . . . 3 . . . .
        .DB      $00,$08,$0F,$14,$C0 ; . . . . . . 2 . . . 3 3 . 1 1 . 3 . . .
        .DB      $00,$0F,$0A,$03,$C0 ; . . . . . . 3 3 . . 2 2 . . . 3 3 . . .
        .DB      $00,$0F,$EA,$0F,$C0 ; . . . . . . 3 3 3 2 2 2 . . 3 3 3 . . .
        .DB      $00,$03,$FA,$3F,$C0 ; . . . . . . . 3 3 3 2 2 . 3 3 3 3 . . .
        .DB      $00,$03,$FF,$F0,$F0 ; . . . . . . . 3 3 3 3 3 3 3 . . 3 3 . .
        .DB      $00,$0F,$FF,$F4,$F0 ; . . . . . . 3 3 3 3 3 3 3 3 1 . 3 3 . .
        .DB      $00,$FF,$FF,$FC,$30 ; . . . . 3 3 3 3 3 3 3 3 3 3 3 . . 3 . .
        .DB      $13,$CF,$FF,$FF,$F0 ; . 1 . 3 3 . 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $1F,$0F,$FF,$FF,$C8 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 3 3 3 . 2 .
        .DB      $00,$3F,$FF,$F0,$08 ; . . . . . 3 3 3 3 3 3 3 3 3 . . . . 2 .
        .DB      $13,$FF,$FF,$00,$20 ; . 1 . 3 3 3 3 3 3 3 3 3 . . . . . 2 . .
        .DB      $1F,$0F,$F0,$3C,$80 ; . 1 3 3 . . 3 3 3 3 . . . 3 3 . 2 . . .
        .DB      $00,$3F,$C0,$CA,$C0 ; . . . . . 3 3 3 3 . . . 3 . 2 2 3 . . .
        .DB      $13,$FF,$F3,$20,$3C ; . 1 . 3 3 3 3 3 3 3 . 3 . 2 . . . 3 3 .
        .DB      $1F,$03,$FC,$00,$00 ; . 1 3 3 . . . 3 3 3 3 . . . . . . . . .

;*******************************************************************************
; THORWOR_FIRE_2_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_2_UP:
        .DB      $00,$00,$30,$20,$00 ; . . . . . . . . . 3 . . . 2 . . . . . .
        .DB      $00,$03,$C0,$23,$00 ; . . . . . . . 3 3 . . . . 2 . 3 . . . .
        .DB      $00,$03,$10,$83,$00 ; . . . . . . . 3 . 1 . . 2 . . 3 . . . .
        .DB      $00,$0C,$02,$84,$C0 ; . . . . . . 3 . . . . 2 2 . 1 . 3 . . .
        .DB      $00,$0F,$0A,$03,$C0 ; . . . . . . 3 3 . . 2 2 . . . 3 3 . . .
        .DB      $00,$0F,$CA,$0F,$C0 ; . . . . . . 3 3 3 . 2 2 . . 3 3 3 . . .
        .DB      $00,$03,$FA,$3F,$C0 ; . . . . . . . 3 3 3 2 2 . 3 3 3 3 . . .
        .DB      $00,$03,$FF,$F0,$F0 ; . . . . . . . 3 3 3 3 3 3 3 . . 3 3 . .
        .DB      $00,$0F,$FF,$F4,$F0 ; . . . . . . 3 3 3 3 3 3 3 3 1 . 3 3 . .
        .DB      $1F,$0F,$FF,$FC,$30 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 3 . . 3 . .
        .DB      $13,$FF,$FF,$FF,$F0 ; . 1 . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$0F,$FF,$FF,$C8 ; . . . . . . 3 3 3 3 3 3 3 3 3 3 3 . 2 .
        .DB      $1F,$0F,$FF,$F0,$08 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 . . . . 2 .
        .DB      $13,$FF,$FF,$0A,$A0 ; . 1 . 3 3 3 3 3 3 3 3 3 . . 2 2 2 2 . .
        .DB      $00,$0F,$F0,$20,$00 ; . . . . . . 3 3 3 3 . . . 2 . . . . . .
        .DB      $1F,$0F,$C0,$8F,$F0 ; . 1 3 3 . . 3 3 3 . . . 2 . 3 3 3 3 . .
        .DB      $13,$FF,$FF,$F0,$3C ; . 1 . 3 3 3 3 3 3 3 3 3 3 3 . . . 3 3 .
        .DB      $00,$03,$F0,$00,$F0 ; . . . . . . . 3 3 3 . . . . . . 3 3 . .

;*******************************************************************************
; THORWOR_FIRE_3_UP
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_3_UP:
        .DB      $00,$00,$30,$28,$00 ; . . . . . . . . . 3 . . . 2 2 . . . . .
        .DB      $00,$03,$C0,$A3,$00 ; . . . . . . . 3 3 . . . 2 2 . 3 . . . .
        .DB      $00,$03,$10,$83,$00 ; . . . . . . . 3 . 1 . . 2 . . 3 . . . .
        .DB      $00,$0C,$02,$84,$C0 ; . . . . . . 3 . . . . 2 2 . 1 . 3 . . .
        .DB      $00,$0F,$0A,$83,$C0 ; . . . . . . 3 3 . . 2 2 2 . . 3 3 . . .
        .DB      $00,$0F,$EA,$0F,$C0 ; . . . . . . 3 3 3 2 2 2 . . 3 3 3 . . .
        .DB      $00,$03,$F8,$3F,$C0 ; . . . . . . . 3 3 3 2 . . 3 3 3 3 . . .
        .DB      $00,$03,$FF,$F0,$F0 ; . . . . . . . 3 3 3 3 3 3 3 . . 3 3 . .
        .DB      $00,$0F,$FF,$F4,$F0 ; . . . . . . 3 3 3 3 3 3 3 3 1 . 3 3 . .
        .DB      $00,$FF,$FF,$FC,$30 ; . . . . 3 3 3 3 3 3 3 3 3 3 3 . . 3 . .
        .DB      $13,$CF,$FF,$FF,$F0 ; . 1 . 3 3 . 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $1F,$0F,$FF,$FF,$C8 ; . 1 3 3 . . 3 3 3 3 3 3 3 3 3 3 3 . 2 .
        .DB      $00,$3F,$FF,$F0,$20 ; . . . . . 3 3 3 3 3 3 3 3 3 . . . 2 . .
        .DB      $13,$FF,$FF,$00,$80 ; . 1 . 3 3 3 3 3 3 3 3 3 . . . . 2 . . .
        .DB      $1F,$0F,$F0,$2A,$F0 ; . 1 3 3 . . 3 3 3 3 . . . 2 2 2 3 3 . .
        .DB      $00,$3F,$C0,$0C,$3C ; . . . . . 3 3 3 3 . . . . . 3 . . 3 3 .
        .DB      $13,$FF,$F0,$33,$0C ; . 1 . 3 3 3 3 3 3 3 . . . 3 . 3 . . 3 .
        .DB      $1F,$03,$FF,$C3,$FF ; . 1 3 3 . . . 3 3 3 3 3 3 . . 3 3 3 3 3

;*******************************************************************************
; THORWOR_FIRE_0
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_0:
        .DB      $00,$00,$0A,$80,$0C ; . . . . . . . . . . 2 2 2 . . . . . 3 .
        .DB      $00,$00,$3C,$28,$0C ; . . . . . . . . . 3 3 . . 2 2 . . . 3 .
        .DB      $00,$00,$FF,$02,$B0 ; . . . . . . . . 3 3 3 3 . . . 2 2 3 . .
        .DB      $00,$03,$CF,$C3,$C0 ; . . . . . . . 3 3 . 3 3 3 . . 3 3 . . .
        .DB      $03,$FF,$0F,$F0,$F0 ; . . . 3 3 3 3 3 . . 3 3 3 3 . . 3 3 . .
        .DB      $0C,$0C,$1F,$F0,$0C ; . . 3 . . . 3 . . 1 3 3 3 3 . . . . 3 .
        .DB      $31,$03,$FF,$F0,$0C ; . 3 . 1 . . . 3 3 3 3 3 3 3 . . . . 3 .
        .DB      $00,$03,$FF,$F0,$0C ; . . . . . . . 3 3 3 3 3 3 3 . . . . 3 .
        .DB      $02,$AA,$FF,$FC,$3C ; . . . 2 2 2 2 2 3 3 3 3 3 3 3 . . 3 3 .
        .DB      $00,$2A,$FF,$FF,$FC ; . . . . . 2 2 2 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $31,$03,$FF,$FF,$F0 ; . 3 . 1 . . . 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $0C,$0F,$FF,$FF,$F0 ; . . 3 . . . 3 3 3 3 3 3 3 3 3 3 3 3 . .
        .DB      $0F,$3F,$3F,$FF,$C0 ; . . 3 3 . 3 3 3 . 3 3 3 3 3 3 3 3 . . .
        .DB      $00,$FC,$0C,$30,$C0 ; . . . . 3 3 3 . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$0C,$30,$C0 ; . . . . . . . . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$3C,$F3,$C0 ; . . . . . . . . . 3 3 . 3 3 . 3 3 . . .
        .DB      $00,$00,$30,$C3,$00 ; . . . . . . . . . 3 . . 3 . . 3 . . . .
        .DB      $00,$00,$14,$51,$40 ; . . . . . . . . . 1 1 . 1 1 . 1 1 . . .

;*******************************************************************************
; THORWOR_FIRE_1
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_1:
        .DB      $00,$00,$00,$A0,$30 ; . . . . . . . . . . . . 2 2 . . . 3 . .
        .DB      $00,$00,$FF,$08,$30 ; . . . . . . . . 3 3 3 3 . . 2 . . 3 . .
        .DB      $00,$FF,$F3,$C2,$C0 ; . . . . 3 3 3 3 3 3 . 3 3 . . 2 3 . . .
        .DB      $0F,$3F,$03,$C0,$80 ; . . 3 3 . 3 3 3 . . . 3 3 . . . 2 . . .
        .DB      $00,$4F,$1F,$C3,$80 ; . . . . 1 . 3 3 . 1 3 3 3 . . 3 2 . . .
        .DB      $20,$43,$FF,$F3,$20 ; . 2 . . 1 . . 3 3 3 3 3 3 3 . 3 . 2 . .
        .DB      $28,$00,$FF,$F0,$C0 ; . 2 2 . . . . . 3 3 3 3 3 3 . . 3 . . .
        .DB      $0A,$AA,$FF,$FC,$30 ; . . 2 2 2 2 2 2 3 3 3 3 3 3 3 . . 3 . .
        .DB      $00,$AA,$FF,$FC,$0C ; . . . . 2 2 2 2 3 3 3 3 3 3 3 . . . 3 .
        .DB      $31,$0B,$FF,$FF,$3C ; . 3 . 1 . . 2 3 3 3 3 3 3 3 3 3 . 3 3 .
        .DB      $0C,$0F,$FF,$FF,$FC ; . . 3 . . . 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $0F,$3F,$FF,$FF,$FC ; . . 3 3 . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $00,$FC,$3F,$FF,$F0 ; . . . . 3 3 3 . . 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$00,$0C,$3C,$F0 ; . . . . . . . . . . 3 . . 3 3 . 3 3 . .
        .DB      $00,$00,$0F,$0C,$30 ; . . . . . . . . . . 3 3 . . 3 . . 3 . .
        .DB      $00,$00,$03,$CF,$3C ; . . . . . . . . . . . 3 3 . 3 3 . 3 3 .
        .DB      $00,$00,$00,$C3,$0C ; . . . . . . . . . . . . 3 . . 3 . . 3 .
        .DB      $00,$00,$01,$45,$14 ; . . . . . . . . . . . 1 1 . 1 1 . 1 1 .

;*******************************************************************************
; THORWOR_FIRE_2
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_2:
        .DB      $00,$00,$00,$A0,$30 ; . . . . . . . . . . . . 2 2 . . . 3 . .
        .DB      $00,$00,$FF,$08,$FC ; . . . . . . . . 3 3 3 3 . . 2 . 3 3 3 .
        .DB      $00,$FF,$F3,$C8,$CC ; . . . . 3 3 3 3 3 3 . 3 3 . 2 . 3 . 3 .
        .DB      $0F,$3F,$03,$C8,$C0 ; . . 3 3 . 3 3 3 . . . 3 3 . 2 . 3 . . .
        .DB      $00,$4F,$1F,$C8,$C0 ; . . . . 1 . 3 3 . 1 3 3 3 . 2 . 3 . . .
        .DB      $28,$03,$FF,$F2,$30 ; . 2 2 . . . . 3 3 3 3 3 3 3 . 2 . 3 . .
        .DB      $02,$80,$FF,$F0,$B0 ; . . . 2 2 . . . 3 3 3 3 3 3 . . 2 3 . .
        .DB      $00,$AA,$FF,$FC,$30 ; . . . . 2 2 2 2 3 3 3 3 3 3 3 . . 3 . .
        .DB      $00,$2A,$FF,$FC,$30 ; . . . . . 2 2 2 3 3 3 3 3 3 3 . . 3 . .
        .DB      $31,$03,$FF,$FF,$3C ; . 3 . 1 . . . 3 3 3 3 3 3 3 3 3 . 3 3 .
        .DB      $0C,$0F,$FF,$FF,$FC ; . . 3 . . . 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $0F,$3F,$FF,$FF,$FC ; . . 3 3 . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $00,$FC,$3F,$FF,$F0 ; . . . . 3 3 3 . . 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$00,$03,$0C,$30 ; . . . . . . . . . . . 3 . . 3 . . 3 . .
        .DB      $00,$00,$03,$0C,$30 ; . . . . . . . . . . . 3 . . 3 . . 3 . .
        .DB      $00,$00,$0F,$3C,$F0 ; . . . . . . . . . . 3 3 . 3 3 . 3 3 . .
        .DB      $00,$00,$0C,$30,$C0 ; . . . . . . . . . . 3 . . 3 . . 3 . . .
        .DB      $00,$00,$05,$14,$50 ; . . . . . . . . . . 1 1 . 1 1 . 1 1 . .

;*******************************************************************************
; THORWOR_FIRE_3
; 5 bytes/row = 20 pixels wide, 18 rows
;*******************************************************************************
THORWOR_FIRE_3:
        .DB      $00,$00,$00,$80,$FC ; . . . . . . . . . . . . 2 . . . 3 3 3 .
        .DB      $00,$00,$FF,$23,$CC ; . . . . . . . . 3 3 3 3 . 2 . 3 3 . 3 .
        .DB      $00,$FF,$F3,$CB,$0C ; . . . . 3 3 3 3 3 3 . 3 3 . 2 3 . . 3 .
        .DB      $0F,$3F,$03,$C2,$3C ; . . 3 3 . 3 3 3 . . . 3 3 . . 2 . 3 3 .
        .DB      $20,$4F,$1F,$C2,$C0 ; . 2 . . 1 . 3 3 . 1 3 3 3 . . 2 3 . . .
        .DB      $28,$03,$FF,$F2,$30 ; . 2 2 . . . . 3 3 3 3 3 3 3 . 2 . 3 . .
        .DB      $0A,$A0,$FF,$F0,$0C ; . . 2 2 2 2 . . 3 3 3 3 3 3 . . . . 3 .
        .DB      $00,$A8,$FF,$FC,$0C ; . . . . 2 2 2 . 3 3 3 3 3 3 3 . . . 3 .
        .DB      $00,$2A,$FF,$FC,$0C ; . . . . . 2 2 2 3 3 3 3 3 3 3 . . . 3 .
        .DB      $31,$0B,$FF,$FF,$3C ; . 3 . 1 . . 2 3 3 3 3 3 3 3 3 3 . 3 3 .
        .DB      $0C,$0F,$FF,$FF,$FC ; . . 3 . . . 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $0F,$3F,$FF,$FF,$FC ; . . 3 3 . 3 3 3 3 3 3 3 3 3 3 3 3 3 3 .
        .DB      $00,$FC,$3F,$FF,$F0 ; . . . . 3 3 3 . . 3 3 3 3 3 3 3 3 3 . .
        .DB      $00,$00,$0C,$3C,$F0 ; . . . . . . . . . . 3 . . 3 3 . 3 3 . .
        .DB      $00,$00,$0F,$0C,$30 ; . . . . . . . . . . 3 3 . . 3 . . 3 . .
        .DB      $00,$00,$03,$CF,$3C ; . . . . . . . . . . . 3 3 . 3 3 . 3 3 .
        .DB      $00,$00,$00,$C3,$0C ; . . . . . . . . . . . . 3 . . 3 . . 3 .
        .DB      $00,$00,$01,$45,$14 ; . . . . . . . . . . . 1 1 . 1 1 . 1 1 .

;*******************************************************************************
; Bytes following the sprite boundary
;*******************************************************************************
        .DB      $00


            ; "285AVE" Text (i.e., garbage)
            DB      $32, $38, $35, $41, $56, $45

            ; 5 FFs and a 00 - Fragment Data (i.e., garbage)
            DB      $FF, $FF, $FF, $FF, $FF, $00

            ; ROM Padding: 63 bytes ($FF)
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF

;*****************************************************************************************
; ----> Build_Grid
;
;       Builds the CRT alignment grid by painting a dot pattern across the screen,
;       drawing a solid left border, and then drawing evenly spaced horizontal lines.
;*****************************************************************************************
Build_Grid:
            ld      a,$07               ; A = 7 (Color White)
            out     (COL3L),a           ; Set Color 3 to White
            xor     a                   ; A = 0
            out     (COL0L),a           ; Set Color 0 to Black (Background)
            ld      hl,$404F            ; Start near top left of Video RAM
            ld      c,$CA               ; Outer loop counter = 202 rows
Buil1:      ld      b,$14               ; Inner loop counter = 20 dots across
Buil2:      inc     hl                  ; Skip 4 bytes (16 pixels) between dots
            inc     hl                  ;
            inc     hl                  ;
            inc     hl                  ;
            ld      (hl),$03            ; Write a dot (Color 3)
            djnz    Buil2               ; Loop until 20 dots are drawn
            dec     c                   ; Decrement row counter
            jr      nz,Buil1            ; Loop until 202 rows are dotted!
            ld      hl,$4050            ; Start at top left of VRAM
            ld      b,$CA               ; B = 202 rows (pixels) down
            ld      de,$0050            ; DE = 80 bytes (1 scanline offset)
Buil3:      ld      (hl),$C0            ; Write $C0 (Solid pixels on left edge)
            add     hl,de               ; Move pointer exactly one scanline down
            djnz    Buil3               ; Loop until the left line is drawn
            ld      hl,$4000            ; Start at top left of VRAM
            ld      c,$0A               ; C = 10 horizontal lines to draw
            ld      de,$05F0            ; DE = 1520 bytes (19 scanlines)
Buil4:      call    Draw_Grid_Line      ; Call routine to draw a solid horizontal line
            add     hl,de               ; Move pointer 19 scanlines down
            dec     c                   ; Decrement line counter
            jr      nz,Buil4            ; Loop until 10 lines are drawn
            ld      hl,$7F70            ; Point to bottom edge of VRAM
            call    Draw_Grid_Line      ; Draw the final horizontal boundary

;*****************************************************************************************
; ----> Wait_For_Service_Off
;
;       Infinite loop that holds the alignment grid on screen. Exits and reboots
;       the arcade machine only when the physical service switch is flipped OFF.
;*****************************************************************************************
Wait_For_Service_Off:
            in      a, (COINPORT)       ; Read System Inputs (Port $10)
            bit     3,a                 ; Check Bit 3 (Service Switch, Active LOW)
            jr      z,Wait_For_Service_Off ; IF 0 (Switch ON): Loop back and wait!
            rst     00H                 ; IF 1 (Switch OFF): Soft reset the cabinet!

;*****************************************************************************************
; ----> Draw_Grid_Line
;
;       Helper routine for the CRT alignment grid. Draws a solid horizontal line
;       across the screen by writing 80 bytes ($50) of solid pixels ($FF).
;*****************************************************************************************
Draw_Grid_Line:
            ld      b,$50               ; Loop counter = 80 bytes (320 pixels)
Draw1:      ld      (hl),$FF            ; Write $FF (4 solid pixels) to Video RAM
            inc     hl                  ; Advance pointer to next byte
            djnz    Draw1               ; Decrement B and loop until line is drawn
            ret                         ; Return to caller

;*****************************************************************************************
; ----> ROM Identification / Developer Signature
;*****************************************************************************************
            ; 29 bytes of padding for ROM
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
            DB      $FF, $FF, $FF, $FF, $FF

            DB      "THE", $00          ; $54, $48, $45, $00
            DB      "WIZARD", $00       ; $57, $49, $5A, $41, $52, $44, $00
            DB      "OF", $00           ; $4F, $46, $00
            DB      "WOR", $00          ; $57, $4F, $52, $00
            DB      "DNA", $00          ; $44, $4E, $41, $00 (Dave Nutting Associates)
            DB      $04, $22, $81       ; 04-22-81 (April 22, 1981)

            END     ;END OF ASSEMBLY
