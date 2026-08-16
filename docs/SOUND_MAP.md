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

| Engine | Modulator area | Engine record | IC outputs |
| --- | ---: | ---: | ---: |
| Primary | `$D246-$D26F` | `$D270-$D281` | `$10-$17` |
| Secondary | `$D282-$D2AB` | `$D2AC-$D2BD` | `$50-$57` |

Each modulator area contains six 7-byte slots. Each 18-byte engine record holds the Astrocade block-output port, ROM stream pointer, priority, eight-register sound image, coupling enable, wait counter, per-service guard, and stream-ready flag. Bytes `+$0E-$0F` have no identified resident sound-engine references.

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

Sound streams are ROM data interpreted by the decoder at `$8437`. Commands `$00-$17` are valid; values `$18` and above are redirected to the fallback stream at `$8740`, whose first command is `$03` reset-engine.

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

`Pri` is the stream-install priority. `PSTR` and `SSTR` are the primary and secondary ROM stream entry addresses.

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
| `R2.B4` | `$D241=$10` | 0 | — | `$8825` | Enemy state event | Ends |
| `R2.B6` | `$D241=$40` | 0 | — | `$8988` | Player status event | Ends |
| `R2.B7` | `$D241=$80` | 1 | `$8741` | — | Global event 2 primary | `>4s`, modulation |
| `R3.B0` | `$D242=$01` | 1 | `$8AA1` | `$8ADD` | Special actor death | `>4s`, modulation |
| `R3.B1` | `$D242=$02` | 0 | — | `$890E` | Monster death | Ends |
| `R3.B2` | `$D242=$04` | 0 | — | `$8851` | Monster fire | Ends |
| `R3.B3` | `$D242=$08` | 0 | — | `$8851` | Monster fire | Ends |
| `R3.B4` | `$D242=$10` | 0 | — | `$8A42` | Worluk phase event | Ends |
| `R3.B5` | `$D242=$20` | 1 | `$8A81` | `$8A6C` | Dual-IC event | Ends |
| `R3.B7` | `$D242=$80` | 1 | `$877B` | — | Worluk entry | `>4s`, wait |
| `R4.B0` | `$D243=$01` | 2 | `$88E2` | `$8905` | Special death event | Sustained, modulation |
| `R4.B1` | `$D243=$02` | 1 | `$8AF6` | `$8B1F` | Dual-IC event | Sustained, modulation/latch |
| `R4.B2` | `$D243=$04` | 1 | — | `$8AF3` | Special monster fire | Ends |
| `R4.B3` | `$D243=$08` | 1 | `$8B2E` | `$8B5D` | Dual-IC event | Ends |

## Notes

- `R3.B2` and `R3.B3` select the same secondary stream at `$8851`.
- `R2.B7` reuses the primary `$8741` stream used by `R1.B2`.
- `R4.B0` carries priority 2. All other catalog requests use priority 0 or 1.
- Stream entry addresses are starting points; the saved engine pointer moves through waits, jumps, and modulation commands during playback.
- The Astrocade sound registers retain their values until software changes them. A stream can finish decoding while the IC continues sounding from the retained register image.
