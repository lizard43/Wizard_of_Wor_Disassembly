<!-- KLINGON_PHRASE_MAP.md -->
# Wizard of Wor Klingon Speech Map

This revision deliberately makes the Klingon speech data parallel the resident English speech architecture.

- `votrax_library_wowk.json` contains **79 speech fragments** `$00-$4E`, just like the English library.
- The X11 ROM contains the same 79 Klingon fragment payloads and the exact resident English **80-entry phrase table**.
- JSON records append `$3F STOP` only so each library item terminates deterministically in the Votrax player. That STOP byte is not stored in the X11 fragment.
- Laughter is not baked into unrelated fragments. Dedicated laugh suffixes use `$10` or padded `$36`; fragment `$2C` is the one complete laugh-heavy sentence that contains its own laughter, matching the English semantic fragment.

## Klingon Fragment Map

| Fragment ID | English semantic fragment | Klingon fragment | JSON bytes | X11 bytes | X11 address |
|---:|---|---|---:|---:|---:|
| `$00` | Kill Worluk for double score | Worluk yIHoH. cha'logh mIvwa' DaSuq. | 35 | 34 | `$C200` |
| `$01` | If you get too powerful, I'll take care of you myself | bIHoSghajqu'chugh, qamevmoH jIH. | 34 | 33 | `$C223` |
| `$02` | The dungeons of Wor | Wor bIghHa'mey. | 16 | 15 | `$C245` |
| `$03` | I am | jIH. | 6 | 5 | `$C255` |
| `$04` | The Wizard of Wor | Wor 'IDnar pIn. | 15 | 14 | `$C25B` |
| `$05` | One bite from my pretties, and you'll explode | DuchopDI' ghumeywIj, bIjor. | 28 | 27 | `$C26A` |
| `$06` | My creatures are radioactive | Qob Ha'DIbaHmeywIj. | 22 | 21 | `$C286` |
| `$07` | Worluk will escape through the door | lojmIt vegh Worluk 'ej nargh. | 31 | 30 | `$C29C` |
| `$08` | Watch the radar | HotlhwI' yIbej. | 16 | 15 | `$C2BB` |
| `$09` | Worrior | SuvwI'. | 8 | 7 | `$C2CB` |
| `$0A` | Hey, insert coin | Huch yIlan. | 12 | 11 | `$C2D3` |
| `$0B` | Find me | HISam. | 7 | 6 | `$C2DF` |
| `$0C` | I'm out of spite | jISo'. | 8 | 7 | `$C2E6` |
| `$0D` | Get ready | yIghuH. | 8 | 7 | `$C2EE` |
| `$0E` | You'd better hope you don't find me | HISambe' 'e' yItul. | 17 | 16 | `$C2F6` |
| `$0F` | Another coin for my treasure chest | latlh Huch vIHev. | 18 | 17 | `$C307` |
| `$10` | Ha ha ha ha | Ha ha ha ha! | 13 | 12 | `$C319` |
| `$11` | Ah good! My pets were getting hungry | maj! ghumeywIj ghungqu'. | 25 | 24 | `$C326` |
| `$12` | You'll get the Arena | SuvmeH DaqDaq bIghoS. | 22 | 21 | `$C33F` |
| `$13` | Another worrior for my babies to devour | latlh SuvwI' luSop ghumeywIj. | 30 | 29 | `$C355` |
| `$14` | Keep going and you will find me | yItaH; HISam. | 13 | 12 | `$C373` |
| `$15` | A few more dungeons and you'll be a | latlh bIghHa'mey puS Daju'DI', | 32 | 31 | `$C380` |
| `$16` | Come back for more with | latlh Qu'vaD yIchegh. | 23 | 22 | `$C3A0` |
| `$17` | The dungeons of Wor await your return | Wor bIghHa'meyDaq bIchegh. | 27 | 26 | `$C3B7` |
| `$18` | Deep in the caverns of Wor, you will meet me | Wor DISmeyDaq HISam. | 21 | 20 | `$C3D2` |
| `$19` | thanks you | Dutlho'. | 9 | 8 | `$C3E7` |
| `$1A` | Now you get the heavyweights | SuvwI'pu' HoSghaj DaSuv. | 25 | 24 | `$C3F0` |
| `$1B` | Garwor, go after them | Garwor, yIHIv! | 14 | 13 | `$C409` |
| `$1C` | If you try any harder, you'll only meet with doom | latlh DanIDchugh, bIHegh. | 25 | 24 | `$C417` |
| `$1D` | Burwor, Garwor, and Thorwor will do you in | Burwor Garwor Thorwor je DuHoH. | 33 | 32 | `$C430` |
| `$1E` | My worlings are very very hungry | SuvwI'HommeywIj ghungqu'. | 26 | 25 | `$C451` |
| `$1F` | My magic is stronger than your weapons | 'IDnarwIj HoS law' nuHmeylIj HoS puS. | 39 | 38 | `$C46B` |
| `$20` | While you developed science, we developed magic | QeD Daghoj; 'IDnar wIghoj. | 28 | 27 | `$C492` |
| `$21` | Your bones will lie in the dungeons of Wor | Wor bIghHa'meyDaq HomDu'lIj tu'lu'. | 37 | 36 | `$C4AE` |
| `$22` | You won't have a chance for your dance | Qapla' Daghajbe'. | 19 | 18 | `$C4D3` |
| `$23` | Remember, I'm the Wizard, not you | yIqaw: Wor 'IDnar pIn jIH; SoHbe'. | 33 | 32 | `$C4E6` |
| `$24` | If you can't beat the rest, then you'll never get the best | Hoch DanIvbe'chugh, bIluj. | 27 | 26 | `$C507` |
| `$25` | If you destroy my babies, I'll pop you in the oven | ghumeywIj DaQaw'chugh, qulDaq qameQmoH. | 42 | 41 | `$C522` |
| `$26` | Now I'm getting mad | jIQeHchoH. | 13 | 12 | `$C54C` |
| `$27` | You'll never leave Wor alive | Worvo' bIyIntaHvIS bImejbe'. | 29 | 28 | `$C559` |
| `$28` | Garwor and Thorwor become invisible | Garwor Thorwor je tISo'moH! | 29 | 28 | `$C576` |
| `$29` | You know you can do better | bIHoSghajqu'laH. | 18 | 17 | `$C593` |
| `$2A` | Hurry back, I can't wait to do it again | nom yIchegh; qaloS. | 19 | 18 | `$C5A5` |
| `$2B` | You can start anew, but for now you're through | Qu' Dachuqa'laH; DaH bIluj. | 28 | 27 | `$C5B8` |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun | He he he, ho ho ho, ha ha ha ha! maj. | 36 | 35 | `$C5D4` |
| `$2D` | Welcome to my world of Wor | Wor qo'Daq yI'el. | 18 | 17 | `$C5F8` |
| `$2E` | So you've come to score in the world of Wor | Wor qo'Daq mIvwa' DaSuq. | 24 | 23 | `$C60A` |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor | Wor 'IDnar pIn Daghom. | 22 | 21 | `$C622` |
| `$30` | Burwor hasn't eaten anyone in months | qaStaHvIS 'op jar pagh Sop Burwor. | 35 | 34 | `$C638` |
| `$31` | My babies breathe fire | qul lutlhuH ghumeywIj. | 24 | 23 | `$C65B` |
| `$32` | I'll fry you with my lightning bolts | nISwI' tIHmeywIjmo' bImeQ. | 27 | 26 | `$C673` |
| `$33` | Thorwor is red, mean, and hungry for space food | Doq Thorwor, QeH 'ej ghung. | 27 | 26 | `$C68E` |
| `$34` | Worrior fear, I draw near, each time I appear | SuvwI', qaSumchoH. | 17 | 16 | `$C6A9` |
| `$35` | You're asking for trouble | Seng DaneH. | 11 | 10 | `$C6BA` |
| `$36` | Ha ha ha ha (padded) | Ha ha ha ha! (padded) | 14 | 13 | `$C6C5` |
| `$37` | Worrior (padded) | SuvwI' (padded) | 9 | 8 | `$C6D3` |
| `$38` | You've just been fried by | DuQIHpu'. | 11 | 10 | `$C6DC` |
| `$39` | Bite the bolt | nISwI' yIchop. | 14 | 13 | `$C6E7` |
| `$3A` | Wasn't that lightning bolt delicious | nISwI' tIH DaparHa''a'? | 22 | 21 | `$C6F5` |
| `$3B` | And my teleporting spell can be even faster | nom jolwI'wIj Qap. | 22 | 21 | `$C70B` |
| `$3C` | Now you know the taste of my magic | DaH 'IDnarwIj DaSov. | 21 | 20 | `$C721` |
| `$3D` | Maybe you'll see me again | chaq maghomqa'. | 16 | 15 | `$C736` |
| `$3E` | Your explosion was music to my ears | QoQ 'oH jorlIj'e'. | 22 | 21 | `$C746` |
| `$3F` | I'll say it again | vIjatlhqa'. | 13 | 12 | `$C75C` |
| `$40` | Worlord | SuvwI' joH | 12 | 11 | `$C769` |
| `$41` | Worlord (padded) | SuvwI' joH (padded) | 13 | 12 | `$C775` |
| `$42` | Be forewarned! You approach the Pit | yIghuH! QemjIq DaghoS. | 24 | 23 | `$C782` |
| `$43` | Your path leads directly to the Pit | QemjIqDaq He'lIj ghoS. | 26 | 25 | `$C79A` |
| `$44` | Deeper, ever deeper into | Wor bIghHa'mey qoDDaq yIghoS. | 30 | 29 | `$C7B4` |
| `$45` | Beware! You are in the Worlord dungeons | yIghuH! SuvwI' joH bIghHa'meyDaq SoH. | 37 | 36 | `$C7D2` |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master | DaSo' 'e' DaQub; bIghHa' pIn jIH. | 31 | 30 | `$C7F7` |
| `$47` | Thor, Bur, Gar! Dinner's ready | Thor, Bur, Gar! SopmeH yIghuH. | 28 | 27 | `$C816` |
| `$48` | Hey! Your space boots untied | DaSlIj yIrar! | 15 | 14 | `$C832` |
| `$49` | My beasts run wild in the Worlord dungeons | SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. | 46 | 45 | `$C841` |
| `$4A` | Now your only chance is your dance | DaH yImI'; latlh DuH Daghajbe'. | 31 | 30 | `$C86F` |
| `$4B` | Are you fit to survive the Pit | QemjIqDaq bIyInlaH'a'? | 25 | 24 | `$C88E` |
| `$4C` | Oops! I must have forgotten the walls | toH! reDmey vIlIjpu'. | 22 | 21 | `$C8A7` |
| `$4D` | Where are you going to hide now | nuqDaq DaSo'? | 14 | 13 | `$C8BD` |
| `$4E` | You're in | SoH. | 5 | 4 | `$C8CB` |

## Klingon Phrase Map

The composition column below is byte-for-byte the resident English phrase table. This is the conservative runtime-stability baseline. Klingon grammar can be improved later with a language-specific phrase table after the ROM is stable in MAME.

When `Dungeon_Class != 0`, the resident game substitutes `$09 -> $40` and `$37 -> $41` before resolving the X11 fragment pointer.

| Phrase ID | English game phrase | Fragment composition | Klingon result | Worlord form when applicable |
|---:|---|---|---|---|
| `$00` | Hey, insert coin | `$0A` | Huch yIlan. | — |
| `$01` | Find me, the Wizard of Wor | `$0B` + `$04` | HISam. Wor 'IDnar pIn. | — |
| `$02` | Hey, insert coin | `$0A` | Huch yIlan. | — |
| `$03` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` | jISo'. Ha ha ha ha! | — |
| `$04` | Hey, insert coin | `$0A` | Huch yIlan. | — |
| `$05` | Find me, the Wizard of Wor | `$0B` + `$04` | HISam. Wor 'IDnar pIn. | — |
| `$06` | Hey, insert coin | `$0A` | Huch yIlan. | — |
| `$07` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` | jISo'. Ha ha ha ha! | — |
| `$08` | Get ready, Worrior | `$0D` + `$09` | yIghuH. SuvwI'. | `$0D` + `$40` → yIghuH. SuvwI' joH |
| `$09` | You'd better hope you don't find me, the Wizard of Wor | `$0E` + `$04` | HISambe' 'e' yItul. Wor 'IDnar pIn. | — |
| `$0A` | Another coin for my treasure chest | `$0F` | latlh Huch vIHev. | — |
| `$0B` | Ah good! My pets were getting hungry. Ha ha ha ha! | `$11` + `$10` | maj! ghumeywIj ghungqu'. Ha ha ha ha! | — |
| `$0C` | My worlings are very very hungry. Ha ha ha ha! | `$1E` + `$36` | SuvwI'HommeywIj ghungqu'. Ha ha ha ha! (padded) | — |
| `$0D` | Welcome to my world of Wor | `$2D` | Wor qo'Daq yI'el. | — |
| `$0E` | So you've come to score in the world of Wor. Ha ha ha ha! | `$2E` + `$10` | Wor qo'Daq mIvwa' DaSuq. Ha ha ha ha! | — |
| `$0F` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | `$2F` + `$10` | Wor 'IDnar pIn Daghom. Ha ha ha ha! | — |
| `$10` | Kill Worluk for double score | `$00` | Worluk yIHoH. cha'logh mIvwa' DaSuq. | — |
| `$11` | You're in the dungeons of Wor | `$4E` + `$02` | SoH. Wor bIghHa'mey. | — |
| `$12` | I am the Wizard of Wor | `$03` + `$04` | jIH. Wor 'IDnar pIn. | — |
| `$13` | One bite from my pretties, and you'll explode. Ha ha ha ha! | `$05` + `$10` | DuchopDI' ghumeywIj, bIjor. Ha ha ha ha! | — |
| `$14` | My creatures are radioactive | `$06` | Qob Ha'DIbaHmeywIj. | — |
| `$15` | Worluk will escape through the door | `$07` | lojmIt vegh Worluk 'ej nargh. | — |
| `$16` | Watch the radar, Worrior | `$08` + `$37` | HotlhwI' yIbej. SuvwI' (padded) | `$08` + `$41` → HotlhwI' yIbej. SuvwI' joH (padded) |
| `$17` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! | `$33` + `$36` | Doq Thorwor, QeH 'ej ghung. Ha ha ha ha! (padded) | — |
| `$18` | Remember, I'm the Wizard, not you | `$23` | yIqaw: Wor 'IDnar pIn jIH; SoHbe'. | — |
| `$19` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! | `$24` + `$36` | Hoch DanIvbe'chugh, bIluj. Ha ha ha ha! (padded) | — |
| `$1A` | You'll never leave Wor alive. Ha ha ha ha! | `$27` + `$36` | Worvo' bIyIntaHvIS bImejbe'. Ha ha ha ha! (padded) | — |
| `$1B` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! | `$25` + `$36` | ghumeywIj DaQaw'chugh, qulDaq qameQmoH. Ha ha ha ha! (padded) | — |
| `$1C` | Burwor hasn't eaten anyone in months. Ha ha ha ha! | `$30` + `$36` | qaStaHvIS 'op jar pagh Sop Burwor. Ha ha ha ha! (padded) | — |
| `$1D` | My babies breathe fire, Worrior | `$31` + `$09` | qul lutlhuH ghumeywIj. SuvwI'. | `$31` + `$40` → qul lutlhuH ghumeywIj. SuvwI' joH |
| `$1E` | I'll fry you with my lightning bolts | `$32` | nISwI' tIHmeywIjmo' bImeQ. | — |
| `$1F` | Burwor, Garwor, and Thorwor will do you in | `$1D` | Burwor Garwor Thorwor je DuHoH. | — |
| `$20` | You'll get the Arena. Ha ha ha ha! | `$12` + `$36` | SuvmeH DaqDaq bIghoS. Ha ha ha ha! (padded) | — |
| `$21` | Another Worrior for my babies to devour | `$13` | latlh SuvwI' luSop ghumeywIj. | — |
| `$22` | Keep going and you will find me | `$14` | yItaH; HISam. | — |
| `$23` | A few more dungeons and you'll be a Worlord | `$15` + `$40` | latlh bIghHa'mey puS Daju'DI', SuvwI' joH | — |
| `$24` | Worrior, now I'm getting mad | `$37` + `$26` | SuvwI' (padded) jIQeHchoH. | `$41` + `$26` → SuvwI' joH (padded) jIQeHchoH. |
| `$25` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$34` + `$10` | SuvwI', qaSumchoH. Ha ha ha ha! | — |
| `$26` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | `$09` + `$22` + `$10` | SuvwI'. Qapla' Daghajbe'. Ha ha ha ha! | `$40` + `$22` + `$10` → SuvwI' joH Qapla' Daghajbe'. Ha ha ha ha! |
| `$27` | You're asking for trouble, Worrior | `$35` + `$37` | Seng DaneH. SuvwI' (padded) | `$35` + `$41` → Seng DaneH. SuvwI' joH (padded) |
| `$28` | Now you get the heavyweights. Ha ha ha ha! | `$1A` + `$36` | SuvwI'pu' HoSghaj DaSuv. Ha ha ha ha! (padded) | — |
| `$29` | Garwor, go after them! | `$1B` | Garwor, yIHIv! | — |
| `$2A` | If you try any harder, you'll only meet with doom. Ha ha ha ha! | `$1C` + `$36` | latlh DanIDchugh, bIHegh. Ha ha ha ha! (padded) | — |
| `$2B` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! | `$01` + `$36` | bIHoSghajqu'chugh, qamevmoH jIH. Ha ha ha ha! (padded) | — |
| `$2C` | My magic is stronger than your weapons, Worrior | `$1F` + `$09` | 'IDnarwIj HoS law' nuHmeylIj HoS puS. SuvwI'. | `$1F` + `$40` → 'IDnarwIj HoS law' nuHmeylIj HoS puS. SuvwI' joH |
| `$2D` | Worrior, while you developed science, we developed magic | `$09` + `$20` | SuvwI'. QeD Daghoj; 'IDnar wIghoj. | `$40` + `$20` → SuvwI' joH QeD Daghoj; 'IDnar wIghoj. |
| `$2E` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! | `$21` + `$36` | Wor bIghHa'meyDaq HomDu'lIj tu'lu'. Ha ha ha ha! (padded) | — |
| `$2F` | Garwor and Thorwor become invisible. Ha ha ha ha! | `$28` + `$36` | Garwor Thorwor je tISo'moH! Ha ha ha ha! (padded) | — |
| `$30` | Come back for more with the Wizard of Wor. Ha ha ha ha! | `$16` + `$04` + `$10` | latlh Qu'vaD yIchegh. Wor 'IDnar pIn. Ha ha ha ha! | — |
| `$31` | The dungeons of Wor await your return, Worrior | `$17` + `$37` | Wor bIghHa'meyDaq bIchegh. SuvwI' (padded) | `$17` + `$41` → Wor bIghHa'meyDaq bIchegh. SuvwI' joH (padded) |
| `$32` | Deep in the caverns of Wor, you will meet me, Worrior | `$18` + `$37` | Wor DISmeyDaq HISam. SuvwI' (padded) | `$18` + `$41` → Wor DISmeyDaq HISam. SuvwI' joH (padded) |
| `$33` | The Wizard of Wor thanks you | `$04` + `$19` | Wor 'IDnar pIn. Dutlho'. | — |
| `$34` | You know you can do better, Worrior | `$29` + `$37` | bIHoSghajqu'laH. SuvwI' (padded) | `$29` + `$41` → bIHoSghajqu'laH. SuvwI' joH (padded) |
| `$35` | Hurry back, I can't wait to do it again | `$2A` | nom yIchegh; qaloS. | — |
| `$36` | You can start anew, but for now you're through. Ha ha ha ha! | `$2B` + `$36` | Qu' Dachuqa'laH; DaH bIluj. Ha ha ha ha! (padded) | — |
| `$37` | He he he, ho ho ho, ha ha ha ha! That was fun | `$2C` | He he he, ho ho ho, ha ha ha ha! maj. | — |
| `$38` | You've just been fried by the Wizard of Wor. Ha ha ha ha! | `$38` + `$04` + `$10` | DuQIHpu'. Wor 'IDnar pIn. Ha ha ha ha! | — |
| `$39` | Bite the bolt, Worrior. Ha ha ha ha! | `$39` + `$37` + `$36` | nISwI' yIchop. SuvwI' (padded) Ha ha ha ha! (padded) | `$39` + `$41` + `$36` → nISwI' yIchop. SuvwI' joH (padded) Ha ha ha ha! (padded) |
| `$3A` | Wasn't that lightning bolt delicious? Ha ha ha ha! | `$3A` + `$10` | nISwI' tIH DaparHa''a'? Ha ha ha ha! | — |
| `$3B` | And my teleporting spell can be even faster. Ha ha ha ha! | `$3B` + `$36` | nom jolwI'wIj Qap. Ha ha ha ha! (padded) | — |
| `$3C` | Now you know the taste of my magic, Worrior | `$3C` + `$37` | DaH 'IDnarwIj DaSov. SuvwI' (padded) | `$3C` + `$41` → DaH 'IDnarwIj DaSov. SuvwI' joH (padded) |
| `$3D` | Worrior, maybe you'll see me again | `$09` + `$3D` | SuvwI'. chaq maghomqa'. | `$40` + `$3D` → SuvwI' joH chaq maghomqa'. |
| `$3E` | Your explosion was music to my ears. Ha ha ha ha! | `$3E` + `$10` | QoQ 'oH jorlIj'e'. Ha ha ha ha! | — |
| `$3F` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$3F` + `$34` + `$10` | vIjatlhqa'. SuvwI', qaSumchoH. Ha ha ha ha! | — |
| `$40` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! | `$41` + `$42` + `$36` | SuvwI' joH (padded) yIghuH! QemjIq DaghoS. Ha ha ha ha! (padded) | — |
| `$41` | Worlord, your path leads directly to the Pit. Ha ha ha ha! | `$41` + `$43` + `$36` | SuvwI' joH (padded) QemjIqDaq He'lIj ghoS. Ha ha ha ha! (padded) | — |
| `$42` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | `$44` + `$02` + `$36` | Wor bIghHa'mey qoDDaq yIghoS. Wor bIghHa'mey. Ha ha ha ha! (padded) | — |
| `$43` | Beware! You are in the Worlord dungeons | `$45` | yIghuH! SuvwI' joH bIghHa'meyDaq SoH. | — |
| `$44` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | `$46` + `$36` | DaSo' 'e' DaQub; bIghHa' pIn jIH. Ha ha ha ha! (padded) | — |
| `$45` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | `$47` + `$36` | Thor, Bur, Gar! SopmeH yIghuH. Ha ha ha ha! (padded) | — |
| `$46` | Hey! Your space boot's untied. Ha ha ha ha! | `$48` + `$10` | DaSlIj yIrar! Ha ha ha ha! | — |
| `$47` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! | `$49` + `$36` | SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. Ha ha ha ha! (padded) | — |
| `$48` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$10` | DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha! | — |
| `$49` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$10` | QemjIqDaq bIyInlaH'a'? Ha ha ha ha! | — |
| `$4A` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` | toH! reDmey vIlIjpu'. Ha ha ha ha! | — |
| `$4B` | Where are you going to hide now? Ha ha ha ha! | `$4D` + `$36` | nuqDaq DaSo'? Ha ha ha ha! (padded) | — |
| `$4C` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$10` | DaH yImI'; latlh DuH Daghajbe'. Ha ha ha ha! | — |
| `$4D` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$36` | QemjIqDaq bIyInlaH'a'? Ha ha ha ha! (padded) | — |
| `$4E` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` | toH! reDmey vIlIjpu'. Ha ha ha ha! | — |
| `$4F` | Where are you going to hide now? Ha ha ha ha! | `$4D` + `$36` | nuqDaq DaSo'? Ha ha ha ha! (padded) | — |
