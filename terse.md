# Wizard of Wor — TERSE identification and ROM artifact audit

**Audit date:** 2026-11-07  
**Result:** **No confirmed TERSE interpreter, compiler, or embedded TERSE dictionary** in the supplied standard program ROMs or German X11 data ROM. Wizard of Wor **does** have a real native-address threaded game-command interpreter. This is not equivalent to demonstrating the DNA TERSE ABI.  
**Classification:** *native Z80 with a game-specific threaded command stream; TERSE not identified*. This is a negative finding for the supplied binaries, **not** a claim that no unreleased development build ever used TERSE.

## Inputs and reproducibility

The inputs were the actual user-supplied MAME archives, not generated disassembly bytes:

- `wow.zip`: seven 4,096-byte members `wow.x1` through `wow.x7`; archive SHA-256 `85b0180b49d13b1a16163a02271c2647054c7631e157ed96772f21f3cdcff0eb`.
- `wowg(1).zip`: **one** 4,096-byte member `german.x11`; archive SHA-256 `280e0b7daf77df11055d145988f6724d1af928ba9261a091002143b021ede536`. This is **only the German data overlay**; it does not contain a separate set of executable program ROMs.

Member identities:

| Member | CPU address | CRC32 | SHA-1 |
| --- | --- | --- | --- |
| `wow.x1` | `0000–0FFF` | `c1295786` | `1e4f30cc15537aed6603b4e664e6e60f4bccb5c5` |
| `wow.x2` | `1000–1FFF` | `9be93215` | `0bc8ee6d8391104eb217b612f32856b105946682` |
| `wow.x3` | `2000–2FFF` | `75e5a22e` | `50a8ca11909ce49412c47de4da69e39a083ce5af` |
| `wow.x4` | `3000–3FFF` | `ef28eb84` | `d6318b3649fccafc2d0a05e5530e88819d299356` |
| `wow.x5` | `8000–8FFF` | `16912c2b` | `faf9c96d99bc111c5f1618f6863f22fd9269027b` |
| `wow.x6` | `9000–9FFF` | `35797f82` | `376bba29e88c16d95438fa996913b76581df0937` |
| `wow.x7` | `A000–AFFF` | `ce404305` | `a52c6c7b77842f25c79515460be6b7ed959b5edb` |
| `german.x11` | `C000–CFFF` | `16f84d73` | `f426cfdedcd70b157d81b0031df5a65cacea5fb6` |

The seven executable members match the hashes in this repository's README. The loaded ranges are `0000–3FFF` and `8000–AFFF`. `4000–7FFF` is video RAM; empty X8 at `B000–BFFF` is **not** an eighth ROM. German X11 is mapped separately at `C000–CFFF`.

## Positive finding: a native-address command-stream interpreter

This is the principal reason WoW can appear superficially TERSE-like.

1. At `$0070`, the game selects an **IY-based command stream**: `LD IY,$0F70` for attract (`FD 21 70 0F`), or `LD IY,$10FD` for gameplay (`FD 21 FD 10`).
2. At `$007E`, the dispatcher forms a **native Z80 return-chain**, starting with:
   ```text
   $007E: 21 7E 00     LD HL,$007E
   $0081: E5           PUSH HL
   $0082: CD 75 08     CALL $0875  ; fetch native handler pointer from (IY)
   $0085: E5           PUSH HL
   $0086: DB 10        IN A,($10) ; service switch check follows
   $008A: C0           RET NZ     ; transfer to selected native handler
   ```
   The dispatcher pushes its own return address and then the handler address. Returning from the handler resumes the dispatcher. Diagnostic mode has an alternate exit.
3. At `$0875`, `FD 6E 00 FD 23 FD 66 00 FD 23 C9` loads a **little-endian 16-bit address from (IY)** into HL, increments IY by two, and returns. `$087F` fetches a byte; `$0886` fetches a word into DE. These routines consume handler-specific inline parameters.
4. At `$08A0`, `E1 CD 86 08 FD E5 D5 FD E1 E9` implements **nested streams** by saving the parent IY, fetching a new stream address, moving it into IY and resuming the dispatcher continuation; `$08AA` restores the parent stream.
5. The attract stream begins at `$0F70` with `07 08`, a native-handler pointer to `$0807`; the gameplay stream begins at `$10FD` with `2B 08`, a pointer to `$082B`. Following bytes mix other native handler addresses and immediate arguments, so blindly decoding every pair as a pointer is invalid.

These addresses and instruction sequences were checked against **the supplied ROM bytes** and the checked-in `src/wow_disassembly.asm`. The source's `dispatch`, `Stream_Fetch_Word_HL`, `Stream_Fetch_Byte_A`, `Enter_Nested_Command_Stream`, `Leave_Nested_Command_Stream`, `ATTRACT_COMMAND_STREAM` and `GAME_COMMAND_STREAM` labels agree with the binary.

**Interpretation:** WoW has an *interpreted* control program, not just a monolithic native game. However, the observed command ABI uses **IY as the stream pointer**, generic native routine addresses as commands, and the **Z80 hardware stack for dispatcher/nesting continuations**. This is distinct from the separately characterized TERSE direct-threaded execution ABI and its control/return conventions in the Sea Wolf II, Gorf, Robby Roto, and later families. A threaded list of native routine addresses *alone* is not a sufficient TERSE fingerprint.

## Negative checks and limits

- All seven 4 KB executable ROM members were loaded at their actual CPU addresses, and the independent X11 member was examined as data.
- An exact plaintext ASCII scan of the executable ROM regions found **no** `TERSE`, `FORTH`, `NEXT`, `COLON`, `LIT16`, `LIT8`, `BRANCH`, `VARIABLE`, `CONSTANT`, `DEFINITIONS`, `BUILD`, `TABLE`, `ARRAY`, or `GAS ROOT`. These are **heuristics**, not exclusion tests: compiled TERSE normally need not contain word names, and generic English strings can cause false hits.
- Inspection of `$0008` found bytes `3E 2C` (`LD A,$2C`), **not** an `RST $08` entry-point stub. The reconstructed program's known main dispatcher and stream-control paths are the native-address command machinery above; a game-specific dispatcher should not be relabeled TERSE merely because it is threaded.
- The resident high-ROM entries at `$8000` begin `C3 F2 84 C3 C1 86 C3 16 83 ...` and are documented native **sound/speech service** entry jumps, not proven TERSE compiler entry points.
- Raw counts of Z80 opcode byte values or 16-bit pointers in mixed code/data are **not** proof of executable instructions. In particular, bytes that resemble `RST` instructions occur within graphics, speech, tables, and command operands. This audit does **not** infer execution paths from raw opcode frequency.
- No evidence of the named, linked TERSE dictionary/compiler vocabulary seen in Ten Pin Deluxe's `tpd_x6.bin` was established here. **Absence of printable names cannot exclude an unnamed, stripped or packed vocabulary**, and complete reachability analysis of every ROM byte has not been claimed.

### German X11 is a resource bank, not another executable engine

The `wowg(1).zip` input contains only `german.x11`, which is loaded **alongside** the standard executable program ROMs. The X11 header begins:

```text
$C000: 8D CD 35 CE 10 20 30 40 70 50 00 D2 C1 ...
```

The first two 16-bit values are pointers to speech-fragment and speech-phrase resources (`$CD8D`, `$CE35`); the alternate font pointer at offset `$000B` is `$C1D2`. The beginning of the localized text includes German-language strings (e.g. `MUENZEINWURF`). The repository README and `src/german/GERMAN_X11.asm` document this X11 resource interface. Do **not** describe this archive as an independent alternate WoW program or use it as evidence for another language runtime.

## Conclusions and next evidence standard

- **Confirmed:** WoW uses an intentional IY-based, native-address threaded command interpreter with inline arguments and nested command streams.
- **Not identified:** A TERSE `NEXT`/colon execution system, TERSE ABI, linked TERSE vocabulary, or compiler in these exact supplied ROM members.
- **Classification for the DNA lineage list:** **WoW: native Z80 + game-specific threaded command stream; TERSE not confirmed**. Do **not** mark as a confirmed TERSE game on this evidence.
- **Not ruled out:** An older development version that used TERSE; unreleased builds; or a small reused TERSE-inspired routine stripped of the larger runtime. Those require *different ROMs* or additional direct evidence.

For a future positive TERSE reclassification, identify and document at least a coherent executable dispatcher **plus** actual thread/colon/return semantics consistent with one of the recovered TERSE ABIs, or independently recovered compiler/source or dictionary structures. Provide exact ROM name, hash, CPU address, bytes, decoded execution contract and (ideally) a runtime trace. Do not rely on shared Astrocade hardware, reused native routines, generic indirect jumps, strings, or the mere fact that the game has bytecode-like sequencing.

**Scope limit:** This was a static, byte-level and source-correlated audit of the **provided ROM sets**. It was **not** a fresh complete reachability proof, hardware-in-the-loop run, or analysis of every historic revision. The negative conclusion is intentionally bounded by that scope.
