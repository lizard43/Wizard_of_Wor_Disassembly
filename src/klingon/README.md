# Wizard of Wor Klingon X11 prototype

This directory contains an experimental 4 KB Klingon X11 ROM for Wizard of Wor. It preserves the established German X11 physical layout while replacing display text, speech records, and selected phrase compositions. It is a technical and gameplay prototype, not a linguistically certified translation.

The ROM is data-only. The resident game continues to perform phrase selection, rank substitution, queue management, and SC-01 playback.

The resident English fragment and phrase reference is maintained in [`../../docs/SPEECH_MAP.md`](../../docs/SPEECH_MAP.md).

## X11 interface

| Address | Field | Purpose |
| ---: | --- | --- |
| `$C000` | Fragment-table pointer | Points to the 84-slot table at `$CD8D`. |
| `$C002` | Phrase-table pointer | Points to the 80-record table at `$CE35`. |
| `$C00B` | Alternate-font pointer | Points to `$C1D2`; custom glyphs provide apostrophe and lowercase `q`. |
| `$C00D` | Localized text | Begins the 23 length-prefixed display records. |
| `$CF1D` | Checksum compensation | Balances the complete X11 image to an additive checksum of `$00`. |

The fragment table covers IDs `$00-$53`; `$4F` is null. The phrase table covers IDs `$00-$4F`.

## Display records

The arcade text uses the custom apostrophe and lowercase-`q` glyphs where required. Display wording is compact enough for the original screen fields. The insert-coin text remains inside its original 18-byte centered record so later addresses do not move.

| ID | English screen text | Klingon display text | Length | Notes |
| ---: | --- | --- | ---: | --- |
| `$01` | INSERT COIN | `Huch yIlan` | 10 visible (18 stored) | Centered inside the existing 18-byte record |
| `$02` | HIGH SCORES | `mIvwa'mey nIv` | 13 |  |
| `$03` | PRESS ONE PLAYER BUTTON | `wa' QujwI'vaD leQ yI'uy` | 23 |  |
| `$04` | PRESS TWO PLAYER BUTTON | `cha' QujwI'vaD leQ yI'uy` | 24 |  |
| `$05` | OR | `ghap` | 4 |  |
| `$06` | DEPOSIT ADDITIONAL COIN | `latlh Huch jengva' yIlan` | 24 |  |
| `$07` | FOR TWO PLAYER GAME | `cha' QujwI' Quj` | 15 |  |
| `$08` | POINTS | `mIvwa'mey` | 9 |  |
| `$09` | BONUS PLAYER | `latlh QujwI'` | 12 |  |
| `$0A` | WAIT FOR INSTRUCTIONS | `ra'lu' 'e' yIloS` | 16 |  |
| `$0B` | INVISIBLE MONSTERS IN THE MAZE | `chen'ongDaq tlhapraghmey So'lu'` | 31 |  |
| `$0C` | ARE LOCATED USING THE RADAR SCREEN | `tlhapraghmey SammeH HotlhwI' lo'lu'` | 35 |  |
| `$0D` | MONSTERS BECOME VISIBLE WHEN ENTERING | `tlhapraghmey leghlu'choH` | 24 |  |
| `$0E` | THE SAME MAZE CORRIDOR AS THE PLAYER | `QujwI' chob lu'elDI'` | 20 |  |
| `$0F` | GET READY | `yIghuH` | 6 |  |
| `$10` | RADAR | `HotlhwI'` | 8 |  |
| `$11` | ESCAPED | `narghpu'` | 8 |  |
| `$12` | CREDITS | `Huch` | 4 |  |
| `$13` | DUNGEON | `bIghHa'` | 7 |  |
| `$14` | WORLORD DUNGEON | `SuvwI' joH bIghHa'` | 18 |  |
| `$15` | THE ARENA | `SuvmeH Daq` | 10 |  |
| `$16` | THE PIT | `QemjIq` | 6 |  |
| `$17` | OR FOR ADDITIONAL WORRIORS | `qoj latlh SuvwI'pu'vaD` | 22 |  |

## Speech fragments

The main IDs `$00-$4E` retain their English semantic roles. `$50-$52` are Klingon grammar helpers, and `$53` is an unreferenced compatibility record. Stored bits 6-7 remain part of the game's inflection encoding.

The Klingon low-six-bit phoneme choices and the stored upper two bits have different provenance: the pronunciation is project-created, while the upper-bit pattern is retained from the working German-template layout. A Votrax/player stream masked to six bits is therefore suitable for listening work but is not a complete source for rebuilding `KLINGON_X11.asm`.

| ID | English fragment or role | Klingon equivalent | Klingon record | Notes |
| ---: | --- | --- | --- | --- |
| `$00` | Kill Worluk for double score | `Worluk yIHoH. cha'logh mIvwa' DaSuq.` | `$C200` · 41 bytes |  |
| `$01` | If you get too powerful, I'll take care of you myself | `bIHoSghajqu'chugh, qamevmoH jIH.` | `$C22A` · 48 bytes |  |
| `$02` | The dungeons of Wor | `Wor bIghHa'mey.` | `$C26C` · 12 bytes |  |
| `$03` | I am | `jIH.` | `$C307` · 9 bytes |  |
| `$04` | The Wizard of Wor | `Wor 'IDnar pIn.` | `$C284` · 15 bytes |  |
| `$05` | One bite from my pretties, and you'll explode | `DuchopDI' ghumeywIj, bIjor.` | `$C294` · 41 bytes |  |
| `$06` | My creatures are radioactive | `Qob Ha'DIbaHmeywIj.` | `$C2BE` · 36 bytes |  |
| `$07` | Worluk will escape through the door | `lojmIt vegh Worluk 'ej nargh.` | `$C2E3` · 35 bytes |  |
| `$08` | Watch the radar | `HotlhwI' yIbej.` | `$C441` · 32 bytes |  |
| `$09` | Worrior | `SuvwI'.` | `$C462` · 6 bytes |  |
| `$0A` | Hey, insert coin | `Huch yIlan.` | `$C5BA` · 21 bytes |  |
| `$0B` | Find me | `HISam.` | `$C5D0` · 15 bytes |  |
| `$0C` | I'm out of sight | `jISo'.` | `$C5E0` · 19 bytes |  |
| `$0D` | Get ready | `yIghuH.` | `$C5F4` · 11 bytes |  |
| `$0E` | You'd better hope you don't find me | `HISambe' 'e' yItul.` | `$C600` · 49 bytes |  |
| `$0F` | Another coin for my treasure chest | `latlh Huch vIHev.` | `$C632` · 43 bytes |  |
| `$10` | Ha ha ha ha | `Ha ha ha ha!` | `$C65E` · 10 bytes |  |
| `$11` | Ah good! My pets were getting hungry | `maj! ghumeywIj ghungqu'.` | `$C669` · 42 bytes |  |
| `$12` | You'll get the Arena | `SuvmeH DaqDaq bIghoS.` | `$C694` · 35 bytes |  |
| `$13` | Another worrior for my babies to devour | `latlh SuvwI' luSop ghumeywIj.` | `$C6C4` · 49 bytes |  |
| `$14` | Keep going and you will find me | `yItaH; HISam.` | `$C6F6` · 31 bytes |  |
| `$15` | A few more dungeons and you'll be a | `latlh bIghHa'mey puS Daju'DI',` | `$C716` · 40 bytes |  |
| `$16` | Come back for more with | `latlh Qu'vaD yIchegh.` | `$C753` · 53 bytes |  |
| `$17` | The dungeons of Wor await your return | `Wor bIghHa'meyDaq bIchegh.` | `$C789` · 52 bytes |  |
| `$18` | Deep in the caverns of Wor, you will meet me | `Wor DISmeyDaq HISam.` | `$C7BE` · 51 bytes |  |
| `$19` | thanks you | `Dutlho'.` | `$C7F2` · 3 bytes |  |
| `$1A` | Now you get the heavyweights | `SuvwI'pu' HoSghaj DaSuv.` | `$C469` · 27 bytes |  |
| `$1B` | Garwor, go after them | `Garwor, yIHIv!` | `$C42E` · 18 bytes |  |
| `$1C` | If you try any harder, you'll only meet with doom | `latlh DanIDchugh, bIHegh.` | `$C49C` · 54 bytes |  |
| `$1D` | Burwor, Garwor, and Thorwor will do you in | `Burwor Garwor Thorwor je DuHoH.` | `$C4D3` · 48 bytes |  |
| `$1E` | My worlings are very very hungry | `SuvwI'HommeywIj ghungqu'.` | `$C504` · 36 bytes |  |
| `$1F` | My magic is stronger than your weapons | `'IDnarwIj HoS law' nuHmeylIj HoS puS.` | `$C529` · 47 bytes |  |
| `$20` | While you developed science, we developed magic | `QeD Daghoj; 'IDnar wIghoj.` | `$C588` · 49 bytes |  |
| `$21` | Your bones will lie in the dungeons of Wor | `Wor bIghHa'meyDaq HomDu'lIj tu'lu'.` | `$C559` · 26 bytes |  |
| `$22` | You won't have a chance for your dance | `Qapla' Daghajbe'.` | `$C311` · 44 bytes |  |
| `$23` | Remember, I'm the Wizard, not you | `yIqaw: Wor 'IDnar pIn jIH; SoHbe'.` | `$C33E` · 37 bytes |  |
| `$24` | If you can't beat the rest, then you'll never get the best | `Hoch DanIvbe'chugh, bIluj.` | `$C364` · 64 bytes |  |
| `$25` | If you destroy my babies, I'll pop you in the oven | `ghumeywIj DaQaw'chugh, qulDaq qameQmoH.` | `$C3A5` · 56 bytes |  |
| `$26` | Now I'm getting mad | `jIQeHchoH.` | `$C3DE` · 28 bytes |  |
| `$27` | You'll never leave Wor alive | `Worvo' bIyIntaHvIS bImejbe'.` | `$C3FB` · 50 bytes |  |
| `$28` | Garwor and Thorwor become invisible | `Garwor Thorwor je tISo'moH!` | `$C9B4` · 43 bytes |  |
| `$29` | You know you can do better | `bIHoSghajqu'laH.` | `$C804` · 41 bytes |  |
| `$2A` | Hurry back, I can't wait to do it again | `nom yIchegh; qaloS.` | `$C82E` · 33 bytes |  |
| `$2B` | You can start anew, but for now you're through | `Qu' Dachuqa'laH; DaH bIluj.` | `$C850` · 61 bytes |  |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun | `He he he, ho ho ho, ha ha ha ha! maj.` | `$C88E` · 40 bytes |  |
| `$2D` | Welcome to my world of Wor | `Wor qo'Daq yI'el.` | `$C8B7` · 29 bytes |  |
| `$2E` | So you've come to score in the world of Wor | `Wor qo'Daq mIvwa' DaSuq.` | `$C8D5` · 53 bytes |  |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor | `Wor 'IDnar pIn Daghom.` | `$C90B` · 47 bytes |  |
| `$30` | Burwor hasn't eaten anyone in months | `qaStaHvIS 'op jar pagh Sop Burwor.` | `$C93B` · 41 bytes |  |
| `$31` | My babies breathe fire | `qul lutlhuH ghumeywIj.` | `$C965` · 30 bytes |  |
| `$32` | I'll fry you with my lightning bolts | `nISwI' tIHmeywIjmo' bImeQ.` | `$C984` · 47 bytes |  |
| `$33` | Thorwor is red, mean, and hungry for space food | `Doq Thorwor, QeH 'ej ghung.` | `$C9E0` · 56 bytes |  |
| `$34` | Worrior fear, I draw near, each time I appear | `SuvwI', qaSumchoH.` | `$CA19` · 54 bytes |  |
| `$35` | You're asking for trouble | `Seng DaneH.` | `$C485` · 22 bytes |  |
| `$36` | Ha ha ha ha (padded) | `Ha ha ha ha! (padded)` | `$C6B8` · 11 bytes |  |
| `$37` | Worrior (padded) | `SuvwI' (padded)` | `$CA50` · 7 bytes |  |
| `$38` | You've just been fried by | `DuQIHpu'.` | `$CA58` · 3 bytes |  |
| `$39` | Bite the bolt | `nISwI' yIchop.` | `$CA6F` · 28 bytes |  |
| `$3A` | Wasn't that lightning bolt delicious | `nISwI' tIH DaparHa''a'?` | `$CA8C` · 30 bytes |  |
| `$3B` | And my teleporting spell can be even faster | `nom jolwI'wIj Qap.` | `$CAAB` · 39 bytes |  |
| `$3C` | Now you know the taste of my magic | `DaH 'IDnarwIj DaSov.` | `$CAD3` · 45 bytes |  |
| `$3D` | Maybe you'll see me again | `chaq maghomqa'.` | `$CB01` · 32 bytes |  |
| `$3E` | Your explosion was music to my ears | `QoQ 'oH jorlIj'e'.` | `$CB22` · 47 bytes |  |
| `$3F` | I'll say it again | `vIjatlhqa'.` | `$CB52` · 18 bytes |  |
| `$40` | Worlord | `SuvwI' joH` | `$C73F` · 8 bytes |  |
| `$41` | Worlord (padded) | `SuvwI' joH (padded)` | `$C748` · 10 bytes |  |
| `$42` | Be forewarned! You approach the Pit | `yIghuH! QemjIq DaghoS.` | `$CB65` · 52 bytes |  |
| `$43` | Your path leads directly to the Pit | `QemjIqDaq He'lIj ghoS.` | `$CB9A` · 33 bytes |  |
| `$44` | Deeper, ever deeper into | `Wor bIghHa'mey qoDDaq yIghoS.` | `$CBBC` · 43 bytes |  |
| `$45` | Beware! You are in the Worlord dungeons | `yIghuH! SuvwI' joH bIghHa'meyDaq SoH.` | `$CBE8` · 41 bytes |  |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master | `DaSo' 'e' DaQub; bIghHa' pIn jIH.` | `$CC12` · 64 bytes |  |
| `$47` | Thor, Bur, Gar! Dinner's ready | `Thor, Bur, Gar! Soj yISop.` | `$CC53` · 30 bytes | Wording avoids the SC-01 P-to-M instability observed in MAME |
| `$48` | Hey! Your space boots untied | `DaSlIj yIrar!` | `$CC72` · 38 bytes |  |
| `$49` | My beasts run wild in the Worlord dungeons | `SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.` | `$CC99` · 58 bytes |  |
| `$4A` | Now your only chance is your dance | `DaH yImI'; latlh DuH Daghajbe'.` | `$CCD4` · 53 bytes |  |
| `$4B` | Are you fit to survive the Pit | `QemjIqDaq bIyInlaH'a'?` | `$CD0A` · 64 bytes |  |
| `$4C` | Oops! I must have forgotten the walls | `toH! reDmey vIlIjpu'.` | `$CD4B` · 32 bytes |  |
| `$4D` | Where are you going to hide now | `nuqDaq DaSo'?` | `$CD6C` · 32 bytes |  |
| `$4E` | You're in | `SoH.` | `$C25B` · 16 bytes |  |
| `$4F` | — | NULL / unused pointer | — | No speech record |
| `$50` | Klingon grammar helper: you are | `SoH.` | `$C279` · 10 bytes | Klingon grammar helper |
| `$51` | Klingon grammar helper: in the dungeons of Wor | `Wor bIghHa'meyDaq.` | `$C574` · 19 bytes | Klingon grammar helper |
| `$52` | Klingon grammar helper: meet again / come back to meet | `yIghomqa'.` | `$CA5C` · 18 bytes | Klingon grammar helper |
| `$53` | Compatibility record; not referenced by the Klingon phrase table | `Dutlho'` | `$C7F6` · 13 bytes | Compatibility record; not referenced by the Klingon phrase table |

## Speech phrases

The seven phrase records that require Klingon word order or helper fragments are identified in the Notes column. Runtime rank substitution still changes `$09 -> $40` and `$37 -> $41` when `Dungeon_Class != 0`.

| Phrase ID | English result | Klingon result | Klingon composition | Notes |
| ---: | --- | --- | --- | --- |
| `$00` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$01` | Find me, the Wizard of Wor | HISam, Wor 'IDnar pIn. | `$0B` + `$04` |  |
| `$02` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$03` | I'm out of sight. Ha ha ha ha! | jISo'. Ha ha ha ha! | `$0C` + `$10` |  |
| `$04` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$05` | Find me, the Wizard of Wor | HISam, Wor 'IDnar pIn. | `$0B` + `$04` |  |
| `$06` | Hey, insert coin | Huch yIlan. | `$0A` |  |
| `$07` | I'm out of sight. Ha ha ha ha! | jISo'. Ha ha ha ha! | `$0C` + `$10` |  |
| `$08` | Get ready, Worrior | yIghuH, SuvwI' / SuvwI' joH. | `$0D` + `$37` | Composition changed for Klingon word order or a helper fragment |
| `$09` | You'd better hope you don't find me, the Wizard of Wor | HISambe' 'e' yItul, Wor 'IDnar pIn. | `$0E` + `$04` |  |
| `$0A` | Another coin for my treasure chest | latlh Huch vIHev. | `$0F` |  |
| `$0B` | Ah good! My pets were getting hungry. Ha ha ha ha! | maj! ghumeywIj ghungqu'. Ha ha ha ha! | `$11` + `$10` |  |
| `$0C` | My worlings are very very hungry. Ha ha ha ha! | SuvwI'HommeywIj ghungqu'. Ha ha ha ha! | `$1E` + `$36` |  |
| `$0D` | Welcome to my world of Wor | Wor qo'Daq yI'el. | `$2D` |  |
| `$0E` | So you've come to score in the world of Wor. Ha ha ha ha! | Wor qo'Daq mIvwa' DaSuq. Ha ha ha ha! | `$2E` + `$10` |  |
| `$0F` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | Wor 'IDnar pIn Daghom. Ha ha ha ha! | `$2F` + `$10` |  |
| `$10` | Kill Worluk for double score | Worluk yIHoH. cha'logh mIvwa' DaSuq. | `$00` |  |
| `$11` | You're in the dungeons of Wor | Wor bIghHa'meyDaq SoH. | `$51` + `$4E` | Composition changed for Klingon word order or a helper fragment |
| `$12` | I am the Wizard of Wor | Wor 'IDnar pIn jIH. | `$04` + `$03` | Composition changed for Klingon word order or a helper fragment |
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
| `$23` | A few more dungeons and you'll be a Worlord | latlh bIghHa'mey puS Daju'DI', SuvwI' joH SoH. | `$15` + `$40` + `$50` | Composition changed for Klingon word order or a helper fragment |
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
| `$30` | Come back for more with the Wizard of Wor. Ha ha ha ha! | Wor 'IDnar pIn yIghomqa'. Ha ha ha ha! | `$04` + `$52` + `$10` | Composition changed for Klingon word order or a helper fragment |
| `$31` | The dungeons of Wor await your return, Worrior | Wor bIghHa'meyDaq bIchegh, SuvwI' / SuvwI' joH. | `$17` + `$37` |  |
| `$32` | Deep in the caverns of Wor, you will meet me, Worrior | Wor DISmeyDaq HISam, SuvwI' / SuvwI' joH. | `$18` + `$37` |  |
| `$33` | The Wizard of Wor thanks you | Dutlho' Wor 'IDnar pIn. | `$19` + `$04` | Composition changed for Klingon word order or a helper fragment |
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
| `$42` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | Wor bIghHa'mey qoDDaq yIghoS. Ha ha ha ha! | `$44` + `$36` | Composition changed for Klingon word order or a helper fragment |
| `$43` | Beware! You are in the Worlord dungeons | yIghuH! SuvwI' joH bIghHa'meyDaq SoH. | `$45` |  |
| `$44` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | DaSo' 'e' DaQub; bIghHa' pIn jIH. Ha ha ha ha! | `$46` + `$36` |  |
| `$45` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | Thor, Bur, Gar! Soj yISop. Ha ha ha ha! | `$47` + `$36` |  |
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

## Known language and speech issues

- Fragments `$00` and `$2E` speak `mIvwa'` for “score,” while the display uses `mIvwa'mey`; changing them requires another SC-01 pronunciation pass.
- Fragment `$0C` corresponds to the spoken line “I'm out of sight.” The legacy resident symbol still says `Spite`; `jISo'` remains a working Klingon rendering that can be refined independently.
- Fragment `$1B` uses `yIHIv` for “go after them.” The plural-object imperative, likely `tIHIv`, should be reviewed.
- Fragments `$46` and `$4D` use transitive `So'` constructions for “hide.” Reflexive wording should be reviewed during the same pronunciation pass.

## Build

Linux:

```sh
./build.sh -k
```

Windows:

```bat
build.bat -k
```

The build creates `roms/klingon.x11` and the project archive `roms/wowk.zip`. It then runs `src/klingon/renameK.sh` or `renameK.bat` automatically, creating the MAME-compatible `roms/wowg.zip` with the same X11 bytes stored under the member name `german.x11`.

The current Linux script writes the seven populated CPU members, `wow.x1` through `wow.x7`, and uses `sc01.bin` when present. The Windows script also emits `wow.x8` from the `$B000` socket and uses `sc01a.bin` when present.

## MAME compatibility

Stock MAME defines `wowg` but not `wowk`. The compatibility archive therefore runs through the German clone driver:

```text
mame -window -skip_gameinfo -rompath roms wowg
```

Audit warnings are expected because the `wowg` driver describes the catalogued German ROM while this archive supplies a Klingon X11 image.

## Verification status

Static verification should cover the 4096-byte image, header pointers, 23 display records, 84 fragment slots, 80 phrase records, helper references, alternate-font glyphs, checksum compensation at `$CF1D`, and a whole-image additive checksum of `$00`. Runtime testing has covered the normal attract, score, instruction, coin, player, radar, and gameplay paths; every phrase still requires final listening and linguistic review before release.
