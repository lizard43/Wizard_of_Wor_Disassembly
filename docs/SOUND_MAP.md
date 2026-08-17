# Wizard of Wor Astrocade Sound Map

This document describes the Astrocade custom I/O IC sound hardware and the non-speech sound system used by *Wizard of Wor*.

WoW sound effects are generated in real time. The Z80 interprets ROM sound streams that update tone, volume, vibrato, and noise registers on two Astrocade custom I/O ICs. SC-01 speech is a separate subsystem documented in [`SPEECH_MAP.md`](SPEECH_MAP.md).

## Astrocade custom I/O IC sound registers

Each IC provides an eight-register sound generator.

| Function | Primary IC | Secondary IC | Description |
| --- | ---: | ---: | --- |
| Master oscillator | `$10` | `$50` | Common oscillator divider |
| Tone A | `$11` | `$51` | Tone A divider |
| Tone B | `$12` | `$52` | Tone B divider |
| Tone C | `$13` | `$53` | Tone C divider |
| Vibrato | `$14` | `$54` | Bits 7-6 speed; bits 5-0 depth |
| Tone C / modulation / noise | `$15` | `$55` | Tone C volume; vibrato/noise modulation select; audible-noise enable |
| Tone A/B volume | `$16` | `$56` | B volume bits 7-4; A volume bits 3-0 |
| Noise | `$17` | `$57` | Eight-bit noise modulation mask; bits 7-4 are audible noise level when noise output is enabled |
| Sound block output | `$18` | `$58` | Block-write port used by WoW to transfer the saved eight-register image |

The three tone generators share the master oscillator. Vibrato or noise can modulate that master oscillator.

The port numbers are direction-sensitive: writes address the Astrocade sound hardware, while reads return cabinet inputs and status.

### Volume and noise

`$15/$55`:

- bits 3-0: Tone C volume
- bit 4: master modulation source: `0` = vibrato, `1` = noise
- bit 5: audible-noise enable

`$16/$56`:

- bits 3-0: Tone A volume
- bits 7-4: Tone B volume

`$17/$57` is the eight-bit noise modulation mask. When `$15/$55` bit 5 enables audible noise, bits 7-4 provide its four-bit output level.

### Eight-register block write

The block ports are `$18` and `$58`. The eight bytes map in descending register order:

```text
byte 0 -> $17 / $57
byte 1 -> $16 / $56
byte 2 -> $15 / $55
byte 3 -> $14 / $54
byte 4 -> $13 / $53
byte 5 -> $12 / $52
byte 6 -> $11 / $51
byte 7 -> $10 / $50
```

## Direct sound example

A minimal Tone A sound on the primary IC:

```asm
        ld      a,$80
        out     ($10),a         ; master oscillator
        ld      a,$20
        out     ($11),a         ; Tone A divider
        ld      a,$0F
        out     ($16),a         ; Tone A volume 15

        ; delay or update registers

        xor     a
        out     ($16),a         ; Tone A/B off
        out     ($15),a         ; Tone C/noise off
        out     ($17),a         ; noise off
```

The secondary IC uses the same register layout at `$50-$57`.

## Wizard of Wor sound implementation

WoW maintains one software sound engine for each Astrocade custom I/O IC.

| Engine | Work-RAM modulator area | Work-RAM engine record | Astrocade I/O registers |
| --- | ---: | ---: | ---: |
| Primary | `$D246-$D26F` | `$D270-$D281` | `$10-$17` |
| Secondary | `$D282-$D2AB` | `$D2AC-$D2BD` | `$50-$57` |

The addresses in the two middle columns are **Z80 memory addresses in writable work RAM**. They are not sound-chip registers and they are not memory-mapped I/O. The addresses in the right column are **Z80 I/O port numbers** used by `OUT`/`OTIR`. Z80 memory space and I/O space are separate namespaces.

### Work RAM versus Astrocade I/O

Three different address classes appear in the sound path and should not be conflated:

| Example | Address space | Meaning |
| --- | --- | --- |
| `$8437`, `$851D` | ROM memory | Executable Z80 sound-engine code |
| `$887B`, `$8928` | ROM memory | Interpreted sound-stream bytecode/data |
| `$D246-$D2BD` | Work RAM | Runtime sound-engine and modulator state |
| `$10-$18`, `$50-$58` | Z80 I/O space | Astrocade sound-register and block-output ports |

The relationship is:

```text
             Z80 MEMORY SPACE                              Z80 I/O SPACE

 gameplay code / request bits
          |
          v
 ROM sound stream ($887B, $8928, ...)
          |
          v
 $8437 Decode_Sound_Stream_Commands
          |
          +------> work-RAM engine record
          |          $D270 primary
          |          $D2AC secondary
          |               |
          |               +--> stream pointer / priority / wait / ready
          |               +--> 8-byte sound-register image
          |
          +------> work-RAM modulator slots
                     $D246-$D26F primary
                     $D282-$D2AB secondary
                              |
                              v
                    $80E6 Service_Sound_Engine_Record
                              |
                              v
                    OTIR through block port $18 / $58  ------------->  Astrocade IC
                                                                        $17-$10
                                                                        $57-$50
```

The engine record is therefore a software control structure. It contains the current ROM stream pointer and a RAM image of the sound registers. The periodic service modifies that image, then transfers the eight bytes to the physical Astrocade sound IC.

This also explains why searching the listing for literal `$D246` or `$D282` finds relatively little code. The shared service routine receives the engine-record base in `IY` and reaches the six modulator slots through **negative indexed displacements**. The same instructions therefore work for either engine.

```text
IY = $D270 primary engine record        IY = $D2AC secondary engine record

IY-$2A = $D246  slot 0                  IY-$2A = $D282  slot 0
IY-$23 = $D24D  slot 1                  IY-$23 = $D289  slot 1
IY-$1C = $D254  slot 2                  IY-$1C = $D290  slot 2
IY-$15 = $D25B  slot 3                  IY-$15 = $D297  slot 3
IY-$0E = $D262  slot 4                  IY-$0E = $D29E  slot 4
IY-$07 = $D269  slot 5                  IY-$07 = $D2A5  slot 5
```

Each engine occupies one contiguous 60-byte software bundle: 42 bytes of modulator slots followed immediately by an 18-byte engine record.

```text
Primary bundle                         Secondary bundle

$D246-$D26F  six modulator slots       $D282-$D2AB  six modulator slots
$D270-$D281  engine record             $D2AC-$D2BD  engine record
```

### Engine record

| Offset | Function |
| ---: | --- |
| `+$00` | Sound block-output port: `$18` primary or `$58` secondary |
| `+$01-$02` | Saved ROM stream pointer |
| `+$03` | Stream priority |
| `+$04-$0B` | Sound-register image in `$17` through `$10` transfer order |
| `+$0C` | Master-oscillator/volume coupling enable |
| `+$0D` | Stream wait counter |
| `+$0E-$0F` | No resident sound-engine references identified |
| `+$10` | Per-service-pass guard; set while modulators update and cleared before register output |
| `+$11` | Stream-ready flag |

Resetting an engine clears record bytes `+$03` through `+$10`, clears all six modulator slots, and transfers eight zero bytes through the engine's block-output port. The stream-ready byte at `+$11` is set so the decoder can run.

The two records have the same layout at different RAM bases:

| Field | Primary RAM | Secondary RAM |
| --- | ---: | ---: |
| Block-output port | `$D270` = `$18` | `$D2AC` = `$58` |
| Saved stream pointer | `$D271-$D272` | `$D2AD-$D2AE` |
| Priority | `$D273` | `$D2AF` |
| Eight-register image | `$D274-$D27B` | `$D2B0-$D2B7` |
| Coupling enable | `$D27C` | `$D2B8` |
| Wait counter | `$D27D` | `$D2B9` |
| Unidentified bytes | `$D27E-$D27F` | `$D2BA-$D2BB` |
| Per-service guard | `$D280` | `$D2BC` |
| Stream-ready flag | `$D281` | `$D2BD` |

The eight-byte register image is stored in the exact order expected by the Astrocade block-output operation:

| Record offset | Primary RAM | Secondary RAM | Hardware register |
| ---: | ---: | ---: | --- |
| `+$04` | `$D274` | `$D2B0` | `$17 / $57` noise (`VOLN`) |
| `+$05` | `$D275` | `$D2B1` | `$16 / $56` Tone A/B volume (`VOLAB`) |
| `+$06` | `$D276` | `$D2B2` | `$15 / $55` Tone C/modulation/noise (`VOLC`) |
| `+$07` | `$D277` | `$D2B3` | `$14 / $54` vibrato (`VIBRA`) |
| `+$08` | `$D278` | `$D2B4` | `$13 / $53` Tone C |
| `+$09` | `$D279` | `$D2B5` | `$12 / $52` Tone B |
| `+$0A` | `$D27A` | `$D2B6` | `$11 / $51` Tone A |
| `+$0B` | `$D27B` | `$D2B7` | `$10 / $50` master oscillator (`TONMO`) |

At `Output_Sound_Register_Image` (`$81C5`), WoW loads record byte `+$00` into `C`, points `HL` at record `+$04`, sets `B=8`, and executes `OTIR`. For the primary engine this means `C=$18`, `HL=$D274`; for the secondary it means `C=$58`, `HL=$D2B0`. The Astrocade block port consumes those eight RAM bytes as registers `$17..$10` or `$57..$50`.

```text
PRIMARY

$D270       $18       block-output port number
$D274-$D27B           8-byte RAM register image
     |                    |
     +--------------------+
              |
              v
        OTIR to port $18
              |
              v
     Astrocade registers $17-$10

SECONDARY

$D2AC       $58       block-output port number
$D2B0-$D2B7           8-byte RAM register image
     |                    |
     +--------------------+
              |
              v
        OTIR to port $58
              |
              v
     Astrocade registers $57-$50
```

Direct stream register-write commands `$10-$17` also write the hardware port immediately and mirror the same value into this RAM image. Modulator service then operates on the image so later block transfers remain coherent with the current software state.

### R2.B0 through the secondary engine

`R2.B0` provides a concrete example of all address spaces working together. The R2 request decoder selects the **secondary** engine, passes ROM stream `$8928`, and requests priority 1. `Install_Sound_Stream` does not jump to `$8928`; it stores `$8928` into the secondary engine record as data and marks the record ready for interpretation.

```text
player-death game path
        |
        v
$D241 bit 0 = R2.B0                 work-RAM request byte
        |
        v
$8538 Dispatch_Sound_Request_2      executable ROM code
        |
        |  IY = $D2AC
        |  HL = $8928
        |  D  = 1
        v
$851D Install_Sound_Stream          executable ROM code
        |
        +--> $D2AD-$D2AE = $8928   saved ROM bytecode pointer
        +--> $D2AF       = 1       priority
        +--> $D2BD       = 1       stream ready
        |
        v
$8437 decoder reads bytes at $8928 ROM sound bytecode
        |
        +--> updates $D282-$D2AB   secondary modulator RAM
        +--> updates $D2B0-$D2B7   secondary register image
        |
        v
$80E6 service with IY=$D2AC
        |
        v
OTIR: HL=$D2B0, C=$58, B=8
        |
        v
secondary Astrocade registers $57-$50
```

This is the distinction to keep when reading the disassembly: `$8928` is ROM **sound data**, `$D2AC` is **RAM engine state**, and `$58` is an **I/O port**.

### Modulator slots

Each 7-byte slot has this layout:

| Offset | Function |
| ---: | --- |
| `+$00` | Countdown |
| `+$01` | Reload value |
| `+$02` | Control flags |
| `+$03` | Step value |
| `+$04` | Boundary A |
| `+$05` | Boundary B |
| `+$06` | Completion count |

The periodic engine service assigns the six slots these roles:

| Slot | Role |
| ---: | --- |
| 0 | Modulates slot 5 reload value |
| 1 | Modulates `VOLN` |
| 2 | Modulates slot 5 step value |
| 3 | Modulates `VIBRA` |
| 4 | Modulates a common tone-volume value, mirrors it into both `VOLAB` nibbles, and writes it into the low nibble of `VOLC` |
| 5 | Modulates `TONMO` |

The slot-control byte has these identified bits:

| Bit | Mask | Function |
| ---: | ---: | --- |
| 0 | `$01` | Enable the slot |
| 1 | `$02` | On a completed boundary transition, snap to the selected boundary instead of reversing the signed step |
| 2 | `$04` | Select the random-value path |
| 3 | `$08` | Mark a pending boundary transition |
| 4 | `$10` | Select and track the active boundary (`+$04` or `+$05`) |
| 5 | `$20` | Set `STREAM_READY` when the completion count expires |

Record byte `+$0C` enables the slot-5-to-slot-4 master-oscillator/volume coupling path.

## Sound requests and resident service

Sound requests are posted through four RAM bytes:

| RAM | Function |
| ---: | --- |
| `$D240` | Request bank 1 |
| `$D241` | Request bank 2 |
| `$D242` | Request bank 3 |
| `$D243` | Request bank 4 |
| `$D244` | Sound-service gate: nonzero enables `$8003` request/stream processing and the normal `$8000` periodic sound/speech service |

`R3.B5`, for example, means bit 5 of request byte `$D242`.

### Three layers of a WoW sound event

A sound effect is easiest to follow when the gameplay producer, request selector, and ROM stream are kept separate. They are related, but they are not the same thing.

1. **Gameplay producer** - ordinary game code decides that a sound is required and posts a request. This is the semantic layer: player fire, player death, coin up, Worluk entry, and so on.
2. **Request selector** - the producer sets a bit in `$D240-$D243`. Names such as `R2.B0` and `R2.B1` identify this interface between gameplay code and the resident sound dispatcher.
3. **ROM sound stream** - the dispatcher consumes the request and installs one or two ROM bytecode entry addresses into the primary and/or secondary sound engine. `PSTR` and `SSTR` identify these stream entry addresses. They are not gameplay routines.

After the third layer, the decoder at `$8437` interprets the stream and the periodic service writes the resulting register image to the Astrocade sound ICs.

The complete correlation therefore has this form:

```text
gameplay event
    -> gameplay producer
    -> request selector in $D240-$D243
    -> request decoder
    -> primary/secondary ROM sound stream
    -> sound-stream interpreter
    -> Astrocade sound registers
```

#### Player death example

The player-death relationship is established in the game code rather than inferred from the sound itself. `Handle_Actor_Death` at `$0D59` calls `Request_Actor_Death_Sound` at `$0DD6`. The player branch reaches `Request_Player_Death_Sound` at `$0DFA`, which sets bit 0 of `Sound_Request_2` (`$D241`). The R2 decoder at `$8538` consumes `R2.B0` and installs the secondary stream at `$8928`.

```text
Handle_Actor_Death ($0D59)
    -> Request_Actor_Death_Sound ($0DD6)
    -> Request_Player_Death_Sound ($0DFA)
    -> R2.B0 = $D241 bit 0
    -> Dispatch_Sound_Request_2 ($8538)
    -> SSTR $8928
    -> secondary sound engine
```

This is why `$8928` is identified as the `R2.B0` player-death sound stream. `$8928` is the start of interpreted sound data, not the address of the actor-death gameplay routine.

#### Player fire example

`Finalize_Projectile_And_Post_Fire_Sound` at `$23D2` separates the player and non-player firing paths. The player path reaches `Post_Player_Fire_Sound`, which sets bit 1 of `Sound_Request_2`. The R2 decoder maps `R2.B1` to the secondary stream at `$887B`.

```text
Finalize_Projectile_And_Post_Fire_Sound ($23D2)
    -> Post_Player_Fire_Sound
    -> R2.B1 = $D241 bit 1
    -> Dispatch_Sound_Request_2 ($8538)
    -> SSTR $887B
    -> secondary sound engine
```

The non-player branch from the same projectile path posts `R3.B2` for monster fire, or `R4.B2` in the identified special-game-state path.

#### Worluk entry example

`Post_Worluk_Entry_Sound` posts `R3.B7`. The R3 decoder installs primary stream `$877B`.

```text
Post_Worluk_Entry_Sound
    -> R3.B7 = $D242 bit 7
    -> Dispatch_Sound_Request_3 ($8583)
    -> PSTR $877B
    -> primary sound engine
```

Not every producer has a proven gameplay name. For example, `Request_Sound_R4_B3_Override` is a known producer of `R4.B3`, and the dispatcher mapping to primary `$8B2E` and secondary `$8B5D` is known, but the precise gameplay event remains unresolved. Keeping these layers separate prevents a stream address or audible impression from being mistaken for a proven game-code identity.

### Request producer cross-reference

This table connects the identified game-code producer to the request bit consumed by the resident sound dispatcher. `Confirmed` means the gameplay meaning is directly established by the producer path. `Context` means the producer has been located but its precise gameplay meaning is not yet resolved.

| Request | Producer / source path | Current identification | Evidence |
| --- | --- | --- | --- |
| `R1.B0-R1.B4` | `Fetch_Sound_Request_From_Stream` | Command-stream selected; individual meanings unresolved | Context |
| `R1.B5` | `Post_Coin_Up_Sound_Request` | Coin up | Confirmed |
| `R2.B0` | `Request_Player_Death_Sound` from `Handle_Actor_Death` | Player death | Confirmed |
| `R2.B1` | `Post_Player_Fire_Sound` from projectile creation | Player fire | Confirmed |
| `R2.B2-R2.B4` | `Select_R2_Actor_State_Sound` | Actor-state requests; precise meanings unresolved | Context |
| `R2.B6` | `Post_Sound_R2_B6_Player_Status_Context` | Player/status context | Context |
| `R2.B7` | No static producer identified | Primary reuse of the `$8741` stream | Unresolved |
| `R3.B0` | `Request_Actor_Death_Sound` | Special actor-death path | Confirmed path |
| `R3.B1` | `Request_Actor_Death_Sound` | Monster death | Confirmed |
| `R3.B2` | `Post_Monster_Fire_Sound` | Monster fire | Confirmed |
| `R3.B3` | Static producer not identified; shares the R3.B2 stream | Monster-fire stream; precise producer unresolved | Unresolved |
| `R3.B4` | `Post_Worluk_Phase_Sound` | Worluk context | Context |
| `R3.B5` | `Post_Sound_R3_B5_Special_Actor_Context` | Special-actor context | Context |
| `R3.B7` | `Post_Worluk_Entry_Sound` | Worluk entry | Confirmed |
| `R4.B0` | `Request_Actor_Death_Sound` | Special death path | Confirmed path |
| `R4.B1` | `Post_Sound_R4_B1_Special_State` | Special-state context | Context |
| `R4.B2` | `Post_Special_Monster_Fire_Sound` | Special monster fire | Confirmed path |
| `R4.B3` | `Request_Sound_R4_B3_Override` | Producer known; precise event unresolved | Context |

The resident entry points used by the sound system are:

| Entry | Function |
| ---: | --- |
| `$8000 -> $84F2` | Periodic sound/speech service |
| `$8003 -> $86C1` | Consume sound requests and decode ready streams |
| `$8006 -> $8316` | Initialize/reset both sound engines and validate speech-queue state |
| `$851D` | Install one ROM sound stream into an engine |
| `$8437` | Decode one engine's ROM sound stream |
| `$80E6` | Periodically service one sound engine |

The normal path is:

```text
request bit in $D240-$D243
        |
        v
$8003 -> $86C1  Dispatch_Sound_Requests
        |
        +--> R1 bits handled inline in $86C1
        |
        +--> $8538 R2 decoder
        +--> $8583 R3 decoder
        +--> $85E8 R4 decoder
                    |
                    v
$851D  Install_Sound_Stream
                    |
                    v
$8437  Decode_Sound_Stream_Commands
        |
        +--> sound-register writes
        +--> waits and modulator state
                    |
                    v
$8000 -> $84F2  periodic service
                    |
                    v
$80E6  Service_Sound_Engine_Record
                    |
                    v
OTIR register-image transfer to $10-$17 / $50-$57
```

### Priority and request handling

WoW uses stream-install priorities 0, 1, and 2. `$851D` rejects a requested stream when its priority is lower than the priority already active in that engine. An accepted install resets that engine, stores the new priority and stream pointer, and marks the stream ready for decoding.

Request bank 1 has pass-level precedence:

- If `$D240` is nonzero, WoW clears the byte and processes every set R1 bit in ascending order.
- R1 bits 0-5 are sound selectors.
- `R1.B6` resets the secondary engine.
- `R1.B7` resets the primary engine.
- R2-R4 are deferred to a later `$8003` pass.

When R1 is zero, the R2, R3, and R4 decoders are called in order. Each decoder clears its complete request byte, scans from bit 0 upward, and dispatches the first recognized set bit. Thus one R2 selector, one R3 selector, and one R4 selector can be serviced in the same `$8003` pass.

`R2.B5`, `R3.B6`, and `R4.B4-R4.B7` are not sound selectors. Because each R2-R4 request byte is cleared before scanning, additional set bits above the dispatched selector do not remain pending.

`R1.B0` through `R1.B4` reset both engines before installing their streams. `R1.B5` is the coin-up request and installs its primary stream directly.

## WoW ROM sound streams

Sound streams are ROM bytecode/data interpreted by the decoder at `$8437`; they are not ordinary Z80 routines. The sound-data region beginning at `$8740` can produce plausible-looking Z80 mnemonics if decoded linearly as processor instructions, but those mnemonics do not describe how WoW uses the bytes. The Z80 executes the interpreter at `$8437`, which reads these bytes as sound commands. Stream labels such as `Sound_Stream_R2_B0_Secondary` therefore identify bytecode entry points rather than executable Z80 entry points.

Commands `$00-$17` are valid; values `$18` and above are redirected to the fallback stream at `$8740`, whose first command is `$03` reset-engine.

| Command | Function |
| ---: | --- |
| `$00` | Yield |
| `$01` | Set wait and yield |
| `$02` | Jump to another stream address |
| `$03` | Reset current sound engine |
| `$04` | Load six bytes into a selected modulator slot (`+5` through `+0`) |
| `$05` | Set the selected modulator slot completion count at `+6` |
| `$06` | Load a slot countdown and set its enable bit |
| `$07` | Clear a slot countdown and its enable bit |
| `$08` | Set engine-record `+$0C` to enable master-oscillator/volume coupling |
| `$09` | Set stream priority to 1 |
| `$0A` | Set stream priority to 0 |
| `$0B-$0F` | Yield aliases |
| `$10` | Write `TONMO` directly and mirror it in the engine record |
| `$11` | Write `TONEA` directly and mirror it in the engine record |
| `$12` | Write `TONEB` directly and mirror it in the engine record |
| `$13` | Write `TONEC` directly and mirror it in the engine record |
| `$14` | Write `VIBRA` directly and mirror it in the engine record |
| `$15` | Write `VOLC` directly and mirror it in the engine record |
| `$16` | Write `VOLAB` directly and mirror it in the engine record |
| `$17` | Write `VOLN` directly and mirror it in the engine record |

A command handler that yields causes WoW to save the address of the next command in the engine record and clear `STREAM_READY`. Wait expiry or a configured modulator completion can set `STREAM_READY` again so decoding resumes from the saved pointer.

The periodic service applies waits and modulator updates to the saved image, then uses `OTIR` from record `+$04` through `+$0B` with block port `$18` or `$58`. This transfers the image to hardware registers `$17` down through `$10`, or `$57` down through `$50`.

## WoW sound request map

Event names are assigned only where request-posting call sites or runtime behavior provide sufficient evidence. Entries that remain unresolved are identified as such rather than inferred from the audio alone.

`Pri` is the stream-install priority. `PSTR` and `SSTR` are the primary and secondary ROM sound-bytecode entry addresses installed by the request decoder. They identify layer 3 above; they are not the addresses of the gameplay routines that posted the request.

`Ends` records natural idle completion during the observed run. `>4s` records activity beyond four seconds. `Sustained` marks requests confirmed to continue until replacement or reset.

| Request | Write | Pri | PSTR | SSTR | Event | Observed |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `R1.B0` | `$D240=$01` | 0 | `$89BE` | `$89E5` | Global event 0 | `>4s`, latch |
| `R1.B1` | `$D240=$02` | 0 | `$89A0` | `$89AF` | Global event 1 | `>4s`, latch |
| `R1.B2` | `$D240=$04` | 0 | `$8741` | `$8772` | Global event 2 | `>4s`, modulation |
| `R1.B3` | `$D240=$08` | 0 | `$8981` | — | Global event 3 | `>4s`, modulation |
| `R1.B4` | `$D240=$10` | 0 | `$8A0C` | `$8A27` | Global event 4 | `>4s`, wait |
| `R1.B5` | `$D240=$20` | 0 | `$8971` | — | Coin up | `>4s`, modulation |
| `R2.B0` | `$D241=$01` | 1 | — | `$8928` | Player death | Ends |
| `R2.B1` | `$D241=$02` | 0 | — | `$887B` | Player fire | Ends |
| `R2.B2` | `$D241=$04` | 1 | — | `$87EA` | Unresolved event | Ends |
| `R2.B3` | `$D241=$08` | 0 | — | `$883B` | Unresolved event | Ends |
| `R2.B4` | `$D241=$10` | 0 | — | `$8825` | Actor-state context | Ends |
| `R2.B6` | `$D241=$40` | 0 | — | `$8988` | Player/status context | Ends |
| `R2.B7` | `$D241=$80` | 1 | `$8741` | — | Global event 2 primary | `>4s`, modulation |
| `R3.B0` | `$D242=$01` | 1 | `$8AA1` | `$8ADD` | Special actor-death path | `>4s`, modulation |
| `R3.B1` | `$D242=$02` | 0 | — | `$890E` | Monster death | Ends |
| `R3.B2` | `$D242=$04` | 0 | — | `$8851` | Monster fire | Ends |
| `R3.B3` | `$D242=$08` | 0 | — | `$8851` | Monster-fire stream; producer unresolved | Ends |
| `R3.B4` | `$D242=$10` | 0 | — | `$8A42` | Worluk context | Ends |
| `R3.B5` | `$D242=$20` | 1 | `$8A81` | `$8A6C` | Special-actor context | Ends |
| `R3.B7` | `$D242=$80` | 1 | `$877B` | — | Worluk entry | `>4s`, wait |
| `R4.B0` | `$D243=$01` | 2 | `$88E2` | `$8905` | Special death path | Sustained, modulation |
| `R4.B1` | `$D243=$02` | 1 | `$8AF6` | `$8B1F` | Special-state context | Sustained, modulation/latch |
| `R4.B2` | `$D243=$04` | 1 | — | `$8AF3` | Special monster fire | Ends |
| `R4.B3` | `$D243=$08` | 1 | `$8B2E` | `$8B5D` | Unresolved event; producer known | Ends |

## Notes

- For reverse engineering, follow **producer label -> request bit -> stream label/address**. Source/LST line numbers can move as comments and data representation are cleaned up; ROM addresses and symbolic labels are the stable correlation points.
- The ROM sound streams are interpreted data. Apparent Z80 opcodes produced by linear disassembly inside the stream region are not sound-engine execution paths.
- `R3.B2` and `R3.B3` select the same secondary stream at `$8851`.
- `R2.B7` reuses the primary `$8741` stream used by `R1.B2`.
- `R4.B0` carries priority 2. All other catalog requests use priority 0 or 1.
- Stream entry addresses are starting points; the saved engine pointer moves through waits, jumps, and modulation commands during playback.
- The Astrocade sound registers retain their values until software changes them. A stream can finish decoding while the IC continues sounding from the retained register image.
