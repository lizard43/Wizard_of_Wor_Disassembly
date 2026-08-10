<!-- KLINGON_PHRASE_MAP.md -->
# Wizard of Wor Klingon speech and display map

This document describes the current Klingon X11 image. Game phrase IDs and speech fragment IDs are separate namespaces. Phrase IDs are the 80 language-independent requests made by Wizard of Wor; the Klingon phrase table expands each request into one to four language-local fragment IDs.

Related documentation: [`README.md`](README.md) · [`docs/SPEECH_MAP.md`](../../docs/SPEECH_MAP.md)

## Display text map

`$62` is the X11 apostrophe glyph and `$63` is the X11 lowercase `q` glyph. The canonical column below is the intended Klingon wording; the ROM encodes those two characters through the alternate font while using the resident uppercase glyphs for the rest.

| ID | English screen text | Klingon display text | Length |
|---:|---|---|---:|
| `$01` | INSERT COIN | `Huch jengva' yIlan` | 18 |
| `$02` | HIGH SCORES | `mIvwa'mey nIv` | 13 |
| `$03` | PRESS ONE PLAYER BUTTON | `wa' QujwI'vaD leQ yI'uy` | 23 |
| `$04` | PRESS TWO PLAYER BUTTON | `cha' QujwI'vaD leQ yI'uy` | 24 |
| `$05` | OR | `ghap` | 4 |
| `$06` | DEPOSIT ADDITIONAL COIN | `latlh Huch jengva' yIlan` | 24 |
| `$07` | FOR TWO PLAYER GAME | `cha' QujwI' Quj` | 15 |
| `$08` | POINTS | `mIvwa'mey` | 9 |
| `$09` | BONUS PLAYER | `latlh QujwI'` | 12 |
| `$0A` | WAIT FOR INSTRUCTIONS | `ra'lu' 'e' yIloS` | 16 |
| `$0B` | INVISIBLE MONSTERS IN THE MAZE | `chen'ongDaq tlhapraghmey So'lu'` | 31 |
| `$0C` | ARE LOCATED USING THE RADAR SCREEN | `tlhapraghmey SammeH HotlhwI' lo'lu'` | 35 |
| `$0D` | MONSTERS BECOME VISIBLE WHEN ENTERING | `tlhapraghmey leghlu'choH` | 24 |
| `$0E` | THE SAME MAZE CORRIDOR AS THE PLAYER | `QujwI' chob lu'elDI'` | 20 |
| `$0F` | GET READY | `yIghuH` | 6 |
| `$10` | RADAR | `HotlhwI'` | 8 |
| `$11` | ESCAPED | `narghpu'` | 8 |
| `$12` | CREDITS | `Huch` | 4 |
| `$13` | DUNGEON | `bIghHa'` | 7 |
| `$14` | WORLORD DUNGEON | `SuvwI' joH bIghHa'` | 18 |
| `$15` | THE ARENA | `SuvmeH Daq` | 10 |
| `$16` | THE PIT | `QemjIq` | 6 |
| `$17` | OR FOR ADDITIONAL WORRIORS | `qoj latlh SuvwI'pu'vaD` | 22 |

## Speech fragment map

The main fragments `$00-$4E` retain the current working pronunciation bytes. Their physical addresses/counts remain on the German X11 layout. `$4F` is null. `$50-$52` are Klingon-specific grammar helpers; `$53` is retained as an unreferenced compatibility record.

`votrax_library_wowk.json` contains all 83 actual Klingon speech records. Its direct SC-01 byte arrays now match the low six bits of the current X11 ROM for every record, including helpers `$50-$53`.

| Fragment | English semantic role | Current Klingon wording | Address | Bytes |
|---:|---|---|---:|---:|
| `$00` | Kill Worluk for double score | `Worluk yIHoH. cha'logh mIvwa' DaSuq.` | `$C200` | 41 |
| `$01` | If you get too powerful, I'll take care of you myself | `bIHoSghajqu'chugh, qamevmoH jIH.` | `$C22A` | 48 |
| `$02` | The dungeons of Wor | `Wor bIghHa'mey.` | `$C26C` | 12 |
| `$03` | I am | `jIH.` | `$C307` | 9 |
| `$04` | The Wizard of Wor | `Wor 'IDnar pIn.` | `$C284` | 15 |
| `$05` | One bite from my pretties, and you'll explode | `DuchopDI' ghumeywIj, bIjor.` | `$C294` | 41 |
| `$06` | My creatures are radioactive | `Qob Ha'DIbaHmeywIj.` | `$C2BE` | 36 |
| `$07` | Worluk will escape through the door | `lojmIt vegh Worluk 'ej nargh.` | `$C2E3` | 35 |
| `$08` | Watch the radar | `HotlhwI' yIbej.` | `$C441` | 32 |
| `$09` | Worrior | `SuvwI'.` | `$C462` | 6 |
| `$0A` | Hey, insert coin | `Huch yIlan.` | `$C5BA` | 21 |
| `$0B` | Find me | `HISam.` | `$C5D0` | 15 |
| `$0C` | I'm out of sight | `jISo'.` | `$C5E0` | 19 |
| `$0D` | Get ready | `yIghuH.` | `$C5F4` | 11 |
| `$0E` | You'd better hope you don't find me | `HISambe' 'e' yItul.` | `$C600` | 49 |
| `$0F` | Another coin for my treasure chest | `latlh Huch vIHev.` | `$C632` | 43 |
| `$10` | Ha ha ha ha | `Ha ha ha ha!` | `$C65E` | 10 |
| `$11` | Ah good! My pets were getting hungry | `maj! ghumeywIj ghungqu'.` | `$C669` | 42 |
| `$12` | You'll get the Arena | `SuvmeH DaqDaq bIghoS.` | `$C694` | 35 |
| `$13` | Another worrior for my babies to devour | `latlh SuvwI' luSop ghumeywIj.` | `$C6C4` | 49 |
| `$14` | Keep going and you will find me | `yItaH; HISam.` | `$C6F6` | 31 |
| `$15` | A few more dungeons and you'll be a | `latlh bIghHa'mey puS Daju'DI',` | `$C716` | 40 |
| `$16` | Come back for more with | `latlh Qu'vaD yIchegh.` | `$C753` | 53 |
| `$17` | The dungeons of Wor await your return | `Wor bIghHa'meyDaq bIchegh.` | `$C789` | 52 |
| `$18` | Deep in the caverns of Wor, you will meet me | `Wor DISmeyDaq HISam.` | `$C7BE` | 51 |
| `$19` | thanks you | `Dutlho'.` | `$C7F2` | 3 |
| `$1A` | Now you get the heavyweights | `SuvwI'pu' HoSghaj DaSuv.` | `$C469` | 27 |
| `$1B` | Garwor, go after them | `Garwor, yIHIv!` | `$C42E` | 18 |
| `$1C` | If you try any harder, you'll only meet with doom | `latlh DanIDchugh, bIHegh.` | `$C49C` | 54 |
| `$1D` | Burwor, Garwor, and Thorwor will do you in | `Burwor Garwor Thorwor je DuHoH.` | `$C4D3` | 48 |
| `$1E` | My worlings are very very hungry | `SuvwI'HommeywIj ghungqu'.` | `$C504` | 36 |
| `$1F` | My magic is stronger than your weapons | `'IDnarwIj HoS law' nuHmeylIj HoS puS.` | `$C529` | 47 |
| `$20` | While you developed science, we developed magic | `QeD Daghoj; 'IDnar wIghoj.` | `$C588` | 49 |
| `$21` | Your bones will lie in the dungeons of Wor | `Wor bIghHa'meyDaq HomDu'lIj tu'lu'.` | `$C559` | 26 |
| `$22` | You won't have a chance for your dance | `Qapla' Daghajbe'.` | `$C311` | 44 |
| `$23` | Remember, I'm the Wizard, not you | `yIqaw: Wor 'IDnar pIn jIH; SoHbe'.` | `$C33E` | 37 |
| `$24` | If you can't beat the rest, then you'll never get the best | `Hoch DanIvbe'chugh, bIluj.` | `$C364` | 64 |
| `$25` | If you destroy my babies, I'll pop you in the oven | `ghumeywIj DaQaw'chugh, qulDaq qameQmoH.` | `$C3A5` | 56 |
| `$26` | Now I'm getting mad | `jIQeHchoH.` | `$C3DE` | 28 |
| `$27` | You'll never leave Wor alive | `Worvo' bIyIntaHvIS bImejbe'.` | `$C3FB` | 50 |
| `$28` | Garwor and Thorwor become invisible | `Garwor Thorwor je tISo'moH!` | `$C9B4` | 43 |
| `$29` | You know you can do better | `bIHoSghajqu'laH.` | `$C804` | 41 |
| `$2A` | Hurry back, I can't wait to do it again | `nom yIchegh; qaloS.` | `$C82E` | 33 |
| `$2B` | You can start anew, but for now you're through | `Qu' Dachuqa'laH; DaH bIluj.` | `$C850` | 61 |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun | `He he he, ho ho ho, ha ha ha ha! maj.` | `$C88E` | 40 |
| `$2D` | Welcome to my world of Wor | `Wor qo'Daq yI'el.` | `$C8B7` | 29 |
| `$2E` | So you've come to score in the world of Wor | `Wor qo'Daq mIvwa' DaSuq.` | `$C8D5` | 53 |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor | `Wor 'IDnar pIn Daghom.` | `$C90B` | 47 |
| `$30` | Burwor hasn't eaten anyone in months | `qaStaHvIS 'op jar pagh Sop Burwor.` | `$C93B` | 41 |
| `$31` | My babies breathe fire | `qul lutlhuH ghumeywIj.` | `$C965` | 30 |
| `$32` | I'll fry you with my lightning bolts | `nISwI' tIHmeywIjmo' bImeQ.` | `$C984` | 47 |
| `$33` | Thorwor is red, mean, and hungry for space food | `Doq Thorwor, QeH 'ej ghung.` | `$C9E0` | 56 |
| `$34` | Worrior fear, I draw near, each time I appear | `SuvwI', qaSumchoH.` | `$CA19` | 54 |
| `$35` | You're asking for trouble | `Seng DaneH.` | `$C485` | 22 |
| `$36` | Ha ha ha ha (padded) | `Ha ha ha ha! (padded)` | `$C6B8` | 11 |
| `$37` | Worrior (padded) | `SuvwI' (padded)` | `$CA50` | 7 |
| `$38` | You've just been fried by | `DuQIHpu'.` | `$CA58` | 3 |
| `$39` | Bite the bolt | `nISwI' yIchop.` | `$CA6F` | 28 |
| `$3A` | Wasn't that lightning bolt delicious | `nISwI' tIH DaparHa''a'?` | `$CA8C` | 30 |
| `$3B` | And my teleporting spell can be even faster | `nom jolwI'wIj Qap.` | `$CAAB` | 39 |
| `$3C` | Now you know the taste of my magic | `DaH 'IDnarwIj DaSov.` | `$CAD3` | 45 |
| `$3D` | Maybe you'll see me again | `chaq maghomqa'.` | `$CB01` | 32 |
| `$3E` | Your explosion was music to my ears | `QoQ 'oH jorlIj'e'.` | `$CB22` | 47 |
| `$3F` | I'll say it again | `vIjatlhqa'.` | `$CB52` | 18 |
| `$40` | Worlord | `SuvwI' joH` | `$C73F` | 8 |
| `$41` | Worlord (padded) | `SuvwI' joH (padded)` | `$C748` | 10 |
| `$42` | Be forewarned! You approach the Pit | `yIghuH! QemjIq DaghoS.` | `$CB65` | 52 |
| `$43` | Your path leads directly to the Pit | `QemjIqDaq He'lIj ghoS.` | `$CB9A` | 33 |
| `$44` | Deeper, ever deeper into | `Wor bIghHa'mey qoDDaq yIghoS.` | `$CBBC` | 43 |
| `$45` | Beware! You are in the Worlord dungeons | `yIghuH! SuvwI' joH bIghHa'meyDaq SoH.` | `$CBE8` | 41 |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master | `DaSo' 'e' DaQub; bIghHa' pIn jIH.` | `$CC12` | 64 |
| `$47` | Thor, Bur, Gar! Dinner's ready | `Thor, Bur, Gar! SopmeH yIghuH.` | `$CC53` | 30 |
| `$48` | Hey! Your space boots untied | `DaSlIj yIrar!` | `$CC72` | 38 |
| `$49` | My beasts run wild in the Worlord dungeons | `SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.` | `$CC99` | 58 |
| `$4A` | Now your only chance is your dance | `DaH yImI'; latlh DuH Daghajbe'.` | `$CCD4` | 53 |
| `$4B` | Are you fit to survive the Pit | `QemjIqDaq bIyInlaH'a'?` | `$CD0A` | 64 |
| `$4C` | Oops! I must have forgotten the walls | `toH! reDmey vIlIjpu'.` | `$CD4B` | 32 |
| `$4D` | Where are you going to hide now | `nuqDaq DaSo'?` | `$CD6C` | 32 |
| `$4E` | You're in | `SoH.` | `$C25B` | 16 |
| `$50` | Klingon grammar helper: you are | `SoH.` | `$C279` | 10 |
| `$51` | Klingon grammar helper: in the dungeons of Wor | `Wor bIghHa'meyDaq.` | `$C574` | 19 |
| `$52` | Klingon grammar helper: meet again / come back to meet | `yIghomqa'.` | `$CA5C` | 18 |
| `$53` | Compatibility record; not referenced by the Klingon phrase table | `Dutlho'` | `$C7F6` | 13 |

### Known speech-language tuning items

- `$00` and `$2E` currently speak `mIvwa'` for score. Current Klingon vocabulary uses `mIvwa'mey` for tally/score; changing these requires a new SC-01 pronunciation pass.
- `$0C` corresponds to the English line “I’m out of sight.” The current `jISo'` is only a rough working rendering and should be replaced during speech retuning.
- `$1B` currently uses `yIHIv` for “go after them”; the plural-object imperative should be reviewed (`tIHIv` is the likely target).
- `$46` and `$4D` use transitive `So'` constructions for English “hide.” These should be reviewed as reflexive hiding expressions during the same pronunciation pass.

## Klingon phrase map

The table below is the exact 80-record phrase composition stored at `$CE35`. The seven rows marked **Klingon order/helper** differ from the resident English composition. Rank substitution `$09 -> $40` and `$37 -> $41` still occurs at runtime when `Dungeon_Class != 0`.

| Phrase | English game line | Klingon working result | Composition | Note |
|---:|---|---|---|---|
| `$00` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$01` | Find me, the Wizard of Wor | HISam, Wor 'IDnar pIn. | `$0B` + `$04` |  |
| `$02` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$03` | I'm out of sight. Ha ha ha ha! | jISo'. Ha ha ha ha! | `$0C` + `$10` |  |
| `$04` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$05` | Find me, the Wizard of Wor | HISam, Wor 'IDnar pIn. | `$0B` + `$04` |  |
| `$06` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$07` | I'm out of sight. Ha ha ha ha! | jISo'. Ha ha ha ha! | `$0C` + `$10` |  |
| `$08` | Get ready, Worrior | yIghuH, SuvwI' / SuvwI' joH. | `$0D` + `$37` | **Klingon order/helper** |
| `$09` | You'd better hope you don't find me, the Wizard of Wor | HISambe' 'e' yItul, Wor 'IDnar pIn. | `$0E` + `$04` |  |
| `$0A` | Another coin for my treasure chest | latlh Huch vIHev. | `$0F` |  |
| `$0B` | Ah good! My pets were getting hungry. Ha ha ha ha! | maj! ghumeywIj ghungqu'. Ha ha ha ha! | `$11` + `$10` |  |
| `$0C` | My worlings are very very hungry. Ha ha ha ha! | SuvwI'HommeywIj ghungqu'. Ha ha ha ha! | `$1E` + `$36` |  |
| `$0D` | Welcome to my world of Wor | Wor qo'Daq yI'el. | `$2D` |  |
| `$0E` | So you've come to score in the world of Wor. Ha ha ha ha! | Wor qo'Daq mIvwa' DaSuq. Ha ha ha ha! | `$2E` + `$10` |  |
| `$0F` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | Wor 'IDnar pIn Daghom. Ha ha ha ha! | `$2F` + `$10` |  |
| `$10` | Kill Worluk for double score | Worluk yIHoH. cha'logh mIvwa' DaSuq. | `$00` |  |
| `$11` | You're in the dungeons of Wor | Wor bIghHa'meyDaq SoH. | `$51` + `$4E` | **Klingon order/helper** |
| `$12` | I am the Wizard of Wor | Wor 'IDnar pIn jIH. | `$04` + `$03` | **Klingon order/helper** |
| `$13` | One bite from my pretties, and you'll explode. Ha ha ha ha! | DuchopDI' ghumeywIj, bIjor. Ha ha ha ha! | `$05` + `$10` |  |
| `$14` | My creatures are radioactive | Qob Ha'DIbaHmeywIj. | `$06` |  |
| `$15` | Worluk will escape through the door | lojmIt vegh Worluk 'ej nargh. | `$07` |  |
| `$16` | Watch the radar, Worrior | HotlhwI' yIbej, SuvwI' / SuvwI' joH. | `$08` + `$37` |  |
| `$17` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! | Doq Thorwor, QeH 'ej ghung. Ha ha ha ha! | `$33` + `$36` |  |
| `$18` | Remember, I'm the Wizard, not you | yIqaw: Wor 'IDnar pIn jIH; SoHbe'. | `$23` |  |
| `$19` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! | Hoch DanIvbe'chugh, bIluj. Ha ha ha ha! | `$24` + `$36` |  |
| `$1A` | You'll never leave Wor alive. Ha ha ha ha! | Worvo' bIyIntaHvIS bImejbe'. Ha ha ha ha! | `$27` + `$36` |  |
| `$1B` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! | ghumeywIj DaQaw'chugh, qulDaq qameQmoH. Ha ha ha ha! | `$25` + `$36` |  |
| `$1C` | Burwor hasn't eaten anyone in months. Ha ha ha ha! | qaStaHvIS 'op jar pagh Sop Burwor. Ha ha ha ha! | `$30` + `$36` |  |
| `$1D` | My babies breathe fire, Worrior | qul lutlhuH ghumeywIj, SuvwI' / SuvwI' joH. | `$31` + `$09` |  |
| `$1E` | I'll fry you with my lightning bolts | nISwI' tIHmeywIjmo' bImeQ. | `$32` |  |
| `$1F` | Burwor, Garwor, and Thorwor will do you in | Burwor Garwor Thorwor je DuHoH. | `$1D` |  |
| `$20` | You'll get the Arena. Ha ha ha ha! | SuvmeH DaqDaq bIghoS. Ha ha ha ha! | `$12` + `$36` |  |
| `$21` | Another Worrior for my babies to devour | latlh SuvwI' luSop ghumeywIj. | `$13` |  |
| `$22` | Keep going and you will find me | yItaH; HISam. | `$14` |  |
| `$23` | A few more dungeons and you'll be a Worlord | latlh bIghHa'mey puS Daju'DI', SuvwI' joH SoH. | `$15` + `$40` + `$50` | **Klingon order/helper** |
| `$24` | Worrior, now I'm getting mad | SuvwI' / SuvwI' joH, jIQeHchoH. | `$37` + `$26` |  |
| `$25` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! | SuvwI', qaSumchoH. Ha ha ha ha! | `$34` + `$10` |  |
| `$26` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | SuvwI' / SuvwI' joH, Qapla' Daghajbe'. Ha ha ha ha! | `$09` + `$22` + `$10` |  |
| `$27` | You're asking for trouble, Worrior | Seng DaneH, SuvwI' / SuvwI' joH. | `$35` + `$37` |  |
| `$28` | Now you get the heavyweights. Ha ha ha ha! | SuvwI'pu' HoSghaj DaSuv. Ha ha ha ha! | `$1A` + `$36` |  |
| `$29` | Garwor, go after them! | Garwor, yIHIv! | `$1B` |  |
| `$2A` | If you try any harder, you'll only meet with doom. Ha ha ha ha! | latlh DanIDchugh, bIHegh. Ha ha ha ha! | `$1C` + `$36` |  |
| `$2B` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! | bIHoSghajqu'chugh, qamevmoH jIH. Ha ha ha ha! | `$01` + `$36` |  |
| `$2C` | My magic is stronger than your weapons, Worrior | 'IDnarwIj HoS law' nuHmeylIj HoS puS, SuvwI' / SuvwI' joH. | `$1F` + `$09` |  |
| `$2D` | Worrior, while you developed science, we developed magic | SuvwI' / SuvwI' joH, QeD Daghoj; 'IDnar wIghoj. | `$09` + `$20` |  |
| `$2E` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! | Wor bIghHa'meyDaq HomDu'lIj tu'lu'. Ha ha ha ha! | `$21` + `$36` |  |
| `$2F` | Garwor and Thorwor become invisible. Ha ha ha ha! | Garwor Thorwor je tISo'moH! Ha ha ha ha! | `$28` + `$36` |  |
| `$30` | Come back for more with the Wizard of Wor. Ha ha ha ha! | Wor 'IDnar pIn yIghomqa'. Ha ha ha ha! | `$04` + `$52` + `$10` | **Klingon order/helper** |
| `$31` | The dungeons of Wor await your return, Worrior | Wor bIghHa'meyDaq bIchegh, SuvwI' / SuvwI' joH. | `$17` + `$37` |  |
| `$32` | Deep in the caverns of Wor, you will meet me, Worrior | Wor DISmeyDaq HISam, SuvwI' / SuvwI' joH. | `$18` + `$37` |  |
| `$33` | The Wizard of Wor thanks you | Dutlho' Wor 'IDnar pIn. | `$19` + `$04` | **Klingon order/helper** |
| `$34` | You know you can do better, Worrior | bIHoSghajqu'laH, SuvwI' / SuvwI' joH. | `$29` + `$37` |  |
| `$35` | Hurry back, I can't wait to do it again | nom yIchegh; qaloS. | `$2A` |  |
| `$36` | You can start anew, but for now you're through. Ha ha ha ha! | Qu' Dachuqa'laH; DaH bIluj. Ha ha ha ha! | `$2B` + `$36` |  |
| `$37` | He he he, ho ho ho, ha ha ha ha! That was fun | He he he, ho ho ho, ha ha ha ha! maj. | `$2C` |  |
| `$38` | You've just been fried by the Wizard of Wor. Ha ha ha ha! | DuQIHpu' Wor 'IDnar pIn. Ha ha ha ha! | `$38` + `$04` + `$10` |  |
| `$39` | Bite the bolt, Worrior. Ha ha ha ha! | nISwI' yIchop, SuvwI' / SuvwI' joH. Ha ha ha ha! | `$39` + `$37` + `$36` |  |
| `$3A` | Wasn't that lightning bolt delicious? Ha ha ha ha! | nISwI' tIH DaparHa''a'? Ha ha ha ha! | `$3A` + `$10` |  |
| `$3B` | And my teleporting spell can be even faster. Ha ha ha ha! | nom jolwI'wIj Qap. Ha ha ha ha! | `$3B` + `$36` |  |
| `$3C` | Now you know the taste of my magic, Worrior | DaH 'IDnarwIj DaSov, SuvwI' / SuvwI' joH. | `$3C` + `$37` |  |
| `$3D` | Worrior, maybe you'll see me again | SuvwI' / SuvwI' joH, chaq maghomqa'. | `$09` + `$3D` |  |
| `$3E` | Your explosion was music to my ears. Ha ha ha ha! | QoQ 'oH jorlIj'e'. Ha ha ha ha! | `$3E` + `$10` |  |
| `$3F` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! | vIjatlhqa': SuvwI', qaSumchoH. Ha ha ha ha! | `$3F` + `$34` + `$10` |  |
| `$40` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! | SuvwI' joH, yIghuH! QemjIq DaghoS. Ha ha ha ha! | `$41` + `$42` + `$36` |  |
| `$41` | Worlord, your path leads directly to the Pit. Ha ha ha ha! | SuvwI' joH, QemjIqDaq He'lIj ghoS. Ha ha ha ha! | `$41` + `$43` + `$36` |  |
| `$42` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | Wor bIghHa'mey qoDDaq yIghoS. Ha ha ha ha! | `$44` + `$36` | **Klingon order/helper** |
| `$43` | Beware! You are in the Worlord dungeons | yIghuH! SuvwI' joH bIghHa'meyDaq SoH. | `$45` |  |
| `$44` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | DaSo' 'e' DaQub; bIghHa' pIn jIH. Ha ha ha ha! | `$46` + `$36` |  |
| `$45` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | Thor, Bur, Gar! SopmeH yIghuH. Ha ha ha ha! | `$47` + `$36` |  |
| `$46` | Hey! Your space boot's untied. Ha ha ha ha! | DaSlIj yIrar! Ha ha ha ha! | `$48` + `$10` |  |
| `$47` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! | SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. Ha ha ha ha! | `$49` + `$36` |  |
| `$48` | Now your only chance is your dance. Ha ha ha ha! | DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha! | `$4A` + `$10` |  |
| `$49` | Are you fit to survive the Pit? Ha ha ha ha! | QemjIqDaq bIyInlaH'a'? Ha ha ha ha! | `$4B` + `$10` |  |
| `$4A` | Oops! I must have forgotten the walls. Ha ha ha ha! | toH! reDmey vIlIjpu'. Ha ha ha ha! | `$4C` + `$10` |  |
| `$4B` | Where are you going to hide now? Ha ha ha ha! | nuqDaq DaSo'? Ha ha ha ha! | `$4D` + `$36` |  |
| `$4C` | Now your only chance is your dance. Ha ha ha ha! | DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha! | `$4A` + `$10` |  |
| `$4D` | Are you fit to survive the Pit? Ha ha ha ha! | QemjIqDaq bIyInlaH'a'? Ha ha ha ha! | `$4B` + `$36` |  |
| `$4E` | Oops! I must have forgotten the walls. Ha ha ha ha! | toH! reDmey vIlIjpu'. Ha ha ha ha! | `$4C` + `$10` |  |
| `$4F` | Where are you going to hide now? Ha ha ha ha! | nuqDaq DaSo'? Ha ha ha ha! | `$4D` + `$36` |  |

## Structural invariants

- X11 image: 4096 bytes at `$C000-$CFFF`.
- Header pointers: fragment table `$CD8D`, phrase table `$CE35`, alternate font `$C1D2`.
- 84 fragment pointer slots; `$4F` is null.
- 80 phrase records occupying exactly 230 bytes at `$CE35-$CF1A`.
- `$CF1B-$CF1C` remain erased, keeping checksum compensation at `$CF1D`.
- Speech record addresses/count bytes and stored control bits 7-6 remain identical to the current working German-template baseline.
- Complete-ROM additive checksum is `$00`.
- Votrax Klingon library contains 83 records and matches ROM low-six-bit speech payloads 83/83.
