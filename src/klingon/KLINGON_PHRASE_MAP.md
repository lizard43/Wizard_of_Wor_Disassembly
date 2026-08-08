<!-- KLINGON_PHRASE_MAP.md -->
# Wizard of Wor Klingon Speech Map

This runtime-stability pass deliberately uses the resident English phrase
composition. Fragment IDs `$00-$4E` therefore have the same semantic role in
English and Klingon. The Votrax JSON contains direct SC-01 phoneme IDs; the
ROM contains separately encoded command streams and must not be regenerated
by copying JSON bytes verbatim.

## Klingon Fragment Map

| Fragment ID | Klingon fragment | Votrax bytes | ROM encoded bytes |
|---:|---|---:|---:|
| `$00` | Worluk yIHoH. cha'logh mIvwa' DaSuq. | 34 | 36 |
| `$01` | bIHoSghajqu'chugh, qamevmoH jIH. | 33 | 35 |
| `$02` | Wor bIghHa'mey. | 15 | 17 |
| `$03` | jIH. | 5 | 7 |
| `$04` | Wor 'IDnar pIn. | 14 | 16 |
| `$05` | DuchopDI' ghumeywIj, bIjor. | 27 | 29 |
| `$06` | Qob Ha'DIbaHmeywIj. | 21 | 23 |
| `$07` | lojmIt vegh Worluk 'ej nargh. | 30 | 32 |
| `$08` | HotlhwI' yIbej. | 15 | 17 |
| `$09` | SuvwI'. | 7 | 9 |
| `$0A` | Huch yIlan. | 11 | 13 |
| `$0B` | HISam. | 6 | 8 |
| `$0C` | jISo'. | 7 | 9 |
| `$0D` | yIghuH. | 7 | 9 |
| `$0E` | HISambe' 'e' yItul. | 16 | 18 |
| `$0F` | latlh Huch vIHev. | 17 | 19 |
| `$10` | Ha ha ha ha! | 12 | 14 |
| `$11` | maj! ghumeywIj ghungqu'. | 24 | 26 |
| `$12` | SuvmeH DaqDaq bIghoS. | 21 | 23 |
| `$13` | latlh SuvwI' luSop ghumeywIj. | 29 | 31 |
| `$14` | yItaH; HISam. | 12 | 14 |
| `$15` | latlh bIghHa'mey puS Daju'DI', | 31 | 33 |
| `$16` | latlh Qu'vaD yIchegh. | 22 | 24 |
| `$17` | Wor bIghHa'meyDaq bIchegh. | 26 | 28 |
| `$18` | Wor DISmeyDaq HISam. | 20 | 22 |
| `$19` | Dutlho'. | 8 | 10 |
| `$1A` | SuvwI'pu' HoSghaj DaSuv. | 24 | 26 |
| `$1B` | Garwor, yIHIv! | 13 | 15 |
| `$1C` | latlh DanIDchugh, bIHegh. | 24 | 26 |
| `$1D` | Burwor Garwor Thorwor je DuHoH. | 32 | 34 |
| `$1E` | SuvwI'HommeywIj ghungqu'. | 25 | 27 |
| `$1F` | 'IDnarwIj HoS law' nuHmeylIj HoS puS. | 38 | 39 |
| `$20` | QeD Daghoj; 'IDnar wIghoj. | 27 | 29 |
| `$21` | Wor bIghHa'meyDaq HomDu'lIj tu'lu'. | 36 | 38 |
| `$22` | Qapla' Daghajbe'. | 18 | 20 |
| `$23` | yIqaw: Wor 'IDnar pIn jIH; SoHbe'. | 32 | 34 |
| `$24` | Hoch DanIvbe'chugh, bIluj. | 26 | 28 |
| `$25` | ghumeywIj DaQaw'chugh, qulDaq qameQmoH. | 41 | 43 |
| `$26` | jIQeHchoH. | 12 | 14 |
| `$27` | Worvo' bIyIntaHvIS bImejbe'. | 28 | 30 |
| `$28` | Garwor Thorwor je tISo'moH! | 28 | 30 |
| `$29` | bIHoSghajqu'laH. | 17 | 19 |
| `$2A` | nom yIchegh; qaloS. | 18 | 20 |
| `$2B` | Qu' Dachuqa'laH; DaH bIluj. | 27 | 29 |
| `$2C` | He he he, ho ho ho, ha ha ha ha! maj. | 35 | 37 |
| `$2D` | Wor qo'Daq yI'el. | 17 | 19 |
| `$2E` | Wor qo'Daq mIvwa' DaSuq. | 23 | 25 |
| `$2F` | Wor 'IDnar pIn Daghom. | 21 | 23 |
| `$30` | qaStaHvIS 'op jar pagh Sop Burwor. | 34 | 36 |
| `$31` | qul lutlhuH ghumeywIj. | 23 | 25 |
| `$32` | nISwI' tIHmeywIjmo' bImeQ. | 26 | 28 |
| `$33` | Doq Thorwor, QeH 'ej ghung. | 26 | 28 |
| `$34` | SuvwI', qaSumchoH. | 16 | 18 |
| `$35` | Seng DaneH. | 10 | 12 |
| `$36` | Ha ha ha ha! (padded) | 13 | 14 |
| `$37` | SuvwI' (padded) | 8 | 9 |
| `$38` | DuQIHpu'. | 10 | 12 |
| `$39` | nISwI' yIchop. | 13 | 15 |
| `$3A` | nISwI' tIH DaparHa''a'? | 21 | 23 |
| `$3B` | nom jolwI'wIj Qap. | 21 | 23 |
| `$3C` | DaH 'IDnarwIj DaSov. | 20 | 22 |
| `$3D` | chaq maghomqa'. | 15 | 17 |
| `$3E` | QoQ 'oH jorlIj'e'. | 21 | 23 |
| `$3F` | vIjatlhqa'. | 12 | 14 |
| `$40` | SuvwI' joH | 11 | 13 |
| `$41` | SuvwI' joH (padded) | 12 | 13 |
| `$42` | yIghuH! QemjIq DaghoS. | 23 | 25 |
| `$43` | QemjIqDaq He'lIj ghoS. | 25 | 27 |
| `$44` | Wor bIghHa'mey qoDDaq yIghoS. | 29 | 31 |
| `$45` | yIghuH! SuvwI' joH bIghHa'meyDaq SoH. | 36 | 38 |
| `$46` | DaSo' 'e' DaQub; bIghHa' pIn jIH. | 30 | 32 |
| `$47` | Thor, Bur, Gar! SopmeH yIghuH. | 27 | 29 |
| `$48` | DaSlIj yIrar! | 14 | 16 |
| `$49` | SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj. | 45 | 47 |
| `$4A` | DaH yImI'; latlh DuH Daghajbe'. | 30 | 32 |
| `$4B` | QemjIqDaq bIyInlaH'a'? | 24 | 26 |
| `$4C` | toH! reDmey vIlIjpu'. | 21 | 23 |
| `$4D` | nuqDaq DaSo'? | 13 | 15 |
| `$4E` | SoH. | 4 | 6 |

## Klingon Phrase Map

| Phrase ID | English game phrase | Klingon fragment composition |
|---:|---|---|
| `$00` | Hey, insert coin | `$0A` |
| `$01` | Find me, the Wizard of Wor | `$0B` + `$04` |
| `$02` | Hey, insert coin | `$0A` |
| `$03` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` |
| `$04` | Hey, insert coin | `$0A` |
| `$05` | Find me, the Wizard of Wor | `$0B` + `$04` |
| `$06` | Hey, insert coin | `$0A` |
| `$07` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` |
| `$08` | Get ready, Worrior | `$0D` + `$09` |
| `$09` | You'd better hope you don't find me, the Wizard of Wor | `$0E` + `$04` |
| `$0A` | Another coin for my treasure chest | `$0F` |
| `$0B` | Ah good! My pets were getting hungry. Ha ha ha ha! | `$11` + `$10` |
| `$0C` | My worlings are very very hungry. Ha ha ha ha! | `$1E` + `$36` |
| `$0D` | Welcome to my world of Wor | `$2D` |
| `$0E` | So you've come to score in the world of Wor. Ha ha ha ha! | `$2E` + `$10` |
| `$0F` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | `$2F` + `$10` |
| `$10` | Kill Worluk for double score | `$00` |
| `$11` | You're in the dungeons of Wor | `$4E` + `$02` |
| `$12` | I am the Wizard of Wor | `$03` + `$04` |
| `$13` | One bite from my pretties, and you'll explode. Ha ha ha ha! | `$05` + `$10` |
| `$14` | My creatures are radioactive | `$06` |
| `$15` | Worluk will escape through the door | `$07` |
| `$16` | Watch the radar, Worrior | `$08` + `$37` |
| `$17` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! | `$33` + `$36` |
| `$18` | Remember, I'm the Wizard, not you | `$23` |
| `$19` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! | `$24` + `$36` |
| `$1A` | You'll never leave Wor alive. Ha ha ha ha! | `$27` + `$36` |
| `$1B` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! | `$25` + `$36` |
| `$1C` | Burwor hasn't eaten anyone in months. Ha ha ha ha! | `$30` + `$36` |
| `$1D` | My babies breathe fire, Worrior | `$31` + `$09` |
| `$1E` | I'll fry you with my lightning bolts | `$32` |
| `$1F` | Burwor, Garwor, and Thorwor will do you in | `$1D` |
| `$20` | You'll get the Arena. Ha ha ha ha! | `$12` + `$36` |
| `$21` | Another Worrior for my babies to devour | `$13` |
| `$22` | Keep going and you will find me | `$14` |
| `$23` | A few more dungeons and you'll be a Worlord | `$15` + `$40` |
| `$24` | Worrior, now I'm getting mad | `$37` + `$26` |
| `$25` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$34` + `$10` |
| `$26` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | `$09` + `$22` + `$10` |
| `$27` | You're asking for trouble, Worrior | `$35` + `$37` |
| `$28` | Now you get the heavyweights. Ha ha ha ha! | `$1A` + `$36` |
| `$29` | Garwor, go after them! | `$1B` |
| `$2A` | If you try any harder, you'll only meet with doom. Ha ha ha ha! | `$1C` + `$36` |
| `$2B` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! | `$01` + `$36` |
| `$2C` | My magic is stronger than your weapons, Worrior | `$1F` + `$09` |
| `$2D` | Worrior, while you developed science, we developed magic | `$09` + `$20` |
| `$2E` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! | `$21` + `$36` |
| `$2F` | Garwor and Thorwor become invisible. Ha ha ha ha! | `$28` + `$36` |
| `$30` | Come back for more with the Wizard of Wor. Ha ha ha ha! | `$16` + `$04` + `$10` |
| `$31` | The dungeons of Wor await your return, Worrior | `$17` + `$37` |
| `$32` | Deep in the caverns of Wor, you will meet me, Worrior | `$18` + `$37` |
| `$33` | The Wizard of Wor thanks you | `$04` + `$19` |
| `$34` | You know you can do better, Worrior | `$29` + `$37` |
| `$35` | Hurry back, I can't wait to do it again | `$2A` |
| `$36` | You can start anew, but for now you're through. Ha ha ha ha! | `$2B` + `$36` |
| `$37` | He he he, ho ho ho, ha ha ha ha! That was fun | `$2C` |
| `$38` | You've just been fried by the Wizard of Wor. Ha ha ha ha! | `$38` + `$04` + `$10` |
| `$39` | Bite the bolt, Worrior. Ha ha ha ha! | `$39` + `$37` + `$36` |
| `$3A` | Wasn't that lightning bolt delicious? Ha ha ha ha! | `$3A` + `$10` |
| `$3B` | And my teleporting spell can be even faster. Ha ha ha ha! | `$3B` + `$36` |
| `$3C` | Now you know the taste of my magic, Worrior | `$3C` + `$37` |
| `$3D` | Worrior, maybe you'll see me again | `$09` + `$3D` |
| `$3E` | Your explosion was music to my ears. Ha ha ha ha! | `$3E` + `$10` |
| `$3F` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$3F` + `$34` + `$10` |
| `$40` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! | `$41` + `$42` + `$36` |
| `$41` | Worlord, your path leads directly to the Pit. Ha ha ha ha! | `$41` + `$43` + `$36` |
| `$42` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | `$44` + `$02` + `$36` |
| `$43` | Beware! You are in the Worlord dungeons | `$45` |
| `$44` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | `$46` + `$36` |
| `$45` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | `$47` + `$36` |
| `$46` | Hey! Your space boot's untied. Ha ha ha ha! | `$48` + `$10` |
| `$47` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! | `$49` + `$36` |
| `$48` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$10` |
| `$49` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$10` |
| `$4A` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` |
| `$4B` | Where are you going to hide now? Ha ha ha ha! | `$4D` + `$36` |
| `$4C` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$10` |
| `$4D` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$36` |
| `$4E` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` |
| `$4F` | Where are you going to hide now? Ha ha ha ha! | `$4D` + `$36` |
