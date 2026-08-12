# Wizard of Wor German X11 language ROM

This directory contains the reconstructed 4 KB German X11 ROM for Wizard of Wor. It preserves the original foreign-language interface: localized display records, a German fragment-pointer table, a German phrase table, coinage data, and the additive checksum byte.

The ROM is data-only. The resident game continues to perform phrase selection, rank substitution, queue management, and SC-01 playback.

The resident English fragment and phrase reference is maintained in [`../../docs/SPEECH_MAP.md`](../../docs/SPEECH_MAP.md).

## X11 interface

| Address | Field | Purpose |
| ---: | --- | --- |
| `$C000` | Fragment-table pointer | Points to 84 slots covering `$00-$53`; `$4F` is null and `$50-$53` are German helper fragments. |
| `$C002` | Phrase-table pointer | Points to 80 German phrase records, IDs `$00-$4F`. |
| `$C004` | Coinage table | Six foreign-mode coinage values. |
| `$C00A` | Expected checksum | Resident target for the additive X11 checksum. |
| `$C00B` | Alternate-font pointer | Points to the reserved German font area. |
| `$C00D` | Localized text | Begins the 23 length-prefixed display records. |

The complete image occupies `$C000-$CFFF`. Character bytes in display records are `$30` or above, allowing the resident display routine to distinguish them from the one-byte length.

## Display records

The source uses ASCII-compatible German spellings because the game does not supply umlaut glyphs in this table. `@` bytes used as spaces or centering padding in the source are shown here as ordinary spaces.

| ID | English screen text | German X11 text | Length | Notes |
| ---: | --- | --- | ---: | --- |
| `$01` | INSERT COIN | `MUENZEINWURF` | 15 stored; centered with padding |  |
| `$02` | HIGH SCORES | `HOECHSTERGEBNIS` | 15 |  |
| `$03` | PRESS ONE PLAYER BUTTON | `DRUECKEN SIE 1 SPIELER KNOPF` | 28 |  |
| `$04` | PRESS TWO PLAYER BUTTON | `DRUECKEN SIE 2 SPIELER KNOPF` | 30 stored; padded |  |
| `$05` | OR | `ODER` | 4 |  |
| `$06` | DEPOSIT ADDITIONAL COIN | `WERFEN SIE ZUSAETZLICHE MUENZE` | 30 |  |
| `$07` | FOR TWO PLAYER GAME | `FUER 2 SPIELER EIN` | 18 |  |
| `$08` | POINTS | `PUNKTE` | 6 |  |
| `$09` | BONUS PLAYER | `BONUS SPIELER` | 13 |  |
| `$0A` | WAIT FOR INSTRUCTIONS | `WARTEN SIE AUF ANWEISUNGEN` | 26 |  |
| `$0B` | INVISIBLE MONSTERS IN THE MAZE | `UNSICHTBARE MONSTER IM LABYRINTH` | 32 |  |
| `$0C` | ARE LOCATED USING THE RADAR SCREEN | `WERDEN DURCH RADARSTRAHLEN LOKALISIERT` | 38 |  |
| `$0D` | MONSTERS BECOME VISIBLE WHEN ENTERING | `MONSTER WERDEN SICHTBAR WENN SIE DEN` | 36 |  |
| `$0E` | THE SAME MAZE CORRIDOR AS THE PLAYER | `KORRIDOR DES SPIELERS BETRETEN` | 30 |  |
| `$0F` | GET READY | `AUF DIE PLAETZE` | 15 |  |
| `$10` | RADAR | `RADAR` | 5 |  |
| `$11` | ESCAPED | `ENTKAM` | 6 |  |
| `$12` | CREDITS | `KREDIT` | 6 |  |
| `$13` | DUNGEON | `LABYRINTH` | 11 stored; padded |  |
| `$14` | WORLORD DUNGEON | `WORLORD LABYRINTH` | 17 |  |
| `$15` | THE ARENA | `DIE ARENA` | 9 |  |
| `$16` | THE PIT | `DIE VERLIESS` | 13 stored; padded | Spelling retained from the existing German ROM source |
| `$17` | OR FOR ADDITIONAL WORRIORS | `ODER FUER WEITERE WORRIORS` | 26 |  |

## Speech fragments

The German pointer table contains 84 slots. IDs `$00-$4E` correspond to the resident English meanings, `$4F` is null, and `$50-$53` support German phrase composition. Each record begins with its encoded payload count.

The ROM records preserve the complete encoded SC-01 bytes. Bits 0-5 select the phoneme; bits 6-7 carry the game's stateful inflection/control state. Six-bit Votrax/player data is useful for audition, but it is derivative data and must not be used to reconstruct the ROM.

| ID | English fragment | German equivalent | German record | Notes |
| ---: | --- | --- | --- | --- |
| `$00` | Kill Worluk for double score | Vernichte Worluk für doppelte Punktzahl | `$C200` · 41 bytes |  |
| `$01` | If you get too powerful, I'll take care of you myself | Wenn du zu mächtig wirst, greife ich selbst ein | `$C22A` · 48 bytes |  |
| `$02` | The dungeons of Wor | Labyrinth | `$C26C` · 12 bytes |  |
| `$03` | I am | Ich bin der | `$C307` · 9 bytes |  |
| `$04` | The Wizard of Wor | Wizard von Wor | `$C284` · 15 bytes |  |
| `$05` | One bite from my pretties, and you'll explode | Ein Biss von meinen Schönen und du explodierst | `$C294` · 41 bytes |  |
| `$06` | My creatures are radioactive | Meine Kreaturen sind radioaktiv | `$C2BE` · 36 bytes |  |
| `$07` | Worluk will escape through the door | Worluk wird durch die Tür entkommen | `$C2E3` · 35 bytes |  |
| `$08` | Watch the radar | Beobachte deinen Radarschirm | `$C441` · 32 bytes |  |
| `$09` | Worrior | Worrior | `$C462` · 6 bytes |  |
| `$0A` | Hey, insert coin | Hey, wirf Geld ein | `$C5BA` · 21 bytes |  |
| `$0B` | Find me | Such mich, den | `$C5D0` · 15 bytes |  |
| `$0C` | I'm out of sight | Ich bin unsichtbar | `$C5E0` · 19 bytes |  |
| `$0D` | Get ready | Sei bereit | `$C5F4` · 11 bytes |  |
| `$0E` | You'd better hope you don't find me | Gnade dir Gott, wenn du den Wizard von Wor findest | `$C600` · 49 bytes |  |
| `$0F` | Another coin for my treasure chest | Eine weitere Münze für meine Brieftasche | `$C632` · 43 bytes |  |
| `$10` | Ha ha ha ha | Ha ha ha ha | `$C65E` · 10 bytes |  |
| `$11` | Ah good! My pets were getting hungry | Sehr gut! Meine Kleinen sind sehr hungrig | `$C669` · 42 bytes |  |
| `$12` | You'll get the Arena | Nun wirst du in die Arena geworfen | `$C694` · 35 bytes |  |
| `$13` | Another worrior for my babies to devour | Noch einen Worrior, den meine Süßen verschlingen werden | `$C6C4` · 49 bytes |  |
| `$14` | Keep going and you will find me | Mach weiter und du findest mich | `$C6F6` · 31 bytes |  |
| `$15` | A few more dungeons and you'll be a | Noch ein paar Labyrinthe und du bist ein | `$C716` · 40 bytes |  |
| `$16` | Come back for more with | Spiel das Spiel noch einmal; dann wirst du ... | `$C753` · 53 bytes |  |
| `$17` | The dungeons of Wor await your return | Die Labyrinthe von Wor warten auf deine Rückkehr | `$C789` · 52 bytes |  |
| `$18` | Deep in the caverns of Wor, you will meet me | Drunten in den Höhlen von Wor wirst du mich treffen | `$C7BE` · 51 bytes |  |
| `$19` | thanks you | Der | `$C7F2` · 3 bytes |  |
| `$1A` | Now you get the heavyweights | Jetzt kommen die Schwergewichte | `$C469` · 27 bytes |  |
| `$1B` | Garwor, go after them | Garwor, pack sie! | `$C42E` · 18 bytes |  |
| `$1C` | If you try any harder, you'll only meet with doom | Wenn du's noch mal versuchst, hauen wir dich in die Pfanne | `$C49C` · 54 bytes |  |
| `$1D` | Burwor, Garwor, and Thorwor will do you in | Burwor, Garwor und Thorwor werden dich einmachen | `$C4D3` · 48 bytes |  |
| `$1E` | My worlings are very very hungry | Meine Schützlinge sind sehr gefräßig | `$C504` · 36 bytes |  |
| `$1F` | My magic is stronger than your weapons | Meine Magiekraft ist stärker als deine Waffen | `$C529` · 47 bytes |  |
| `$20` | While you developed science, we developed magic | Du stehst auf Wissenschaft, ich glaube an Magie | `$C588` · 49 bytes |  |
| `$21` | Your bones will lie in the dungeons of Wor | Deine Knochen werden in den | `$C559` · 26 bytes |  |
| `$22` | You won't have a chance for your dance | Du bleibst nicht ganz nach diesem wilden Tanz | `$C311` · 44 bytes |  |
| `$23` | Remember, I'm the Wizard, not you | Denk dran, ich bin der Wizard, nicht du | `$C33E` · 37 bytes |  |
| `$24` | If you can't beat the rest, then you'll never get the best | Wenn du den Rest schlägst, dann nenn dich der Beste | `$C364` · 64 bytes |  |
| `$25` | If you destroy my babies, I'll pop you in the oven | Wenn du meine Babys anfasst, werde ich dich im Ofen braten | `$C3A5` · 56 bytes |  |
| `$26` | Now I'm getting mad | Langsam werde ich böse | `$C3DE` · 28 bytes |  |
| `$27` | You'll never leave Wor alive | Du wirst Wor nicht lebendig verlassen | `$C3FB` · 50 bytes |  |
| `$28` | Garwor and Thorwor become invisible | Garwor und Thorwor, macht euch unsichtbar | `$C9B4` · 43 bytes |  |
| `$29` | You know you can do better | Du weißt genau, dass du es besser kannst | `$C804` · 41 bytes |  |
| `$2A` | Hurry back, I can't wait to do it again | Komm zurück, Rache ist süß | `$C82E` · 33 bytes |  |
| `$2B` | You can start anew, but for now you're through | Ich greife an mit Gebrüll, schmeiße dich jetzt auf den Müll | `$C850` · 61 bytes |  |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun | He he he, ho ho ho, ha ha ha ha! Das macht Spaß | `$C88E` · 40 bytes |  |
| `$2D` | Welcome to my world of Wor | Willkommen in der Welt von Wor | `$C8B7` · 29 bytes |  |
| `$2E` | So you've come to score in the world of Wor | Mach dem Wizard mal was vor, sammle Punkte in der Welt von Wor | `$C8D5` · 53 bytes |  |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor | Gleich siehst du den Wizard, den magischen Wizard von Wor | `$C90B` · 47 bytes |  |
| `$30` | Burwor hasn't eaten anyone in months | Seit Monaten hat Burwor niemanden vernascht | `$C93B` · 41 bytes |  |
| `$31` | My babies breathe fire | Meine Kinder speien Feuer | `$C965` · 30 bytes |  |
| `$32` | I'll fry you with my lightning bolts | Mit meiner Lichtkanone verbrenne ich dich | `$C984` · 47 bytes |  |
| `$33` | Thorwor is red, mean, and hungry for space food | Thorwor ist blutrot, gemein und hungrig auf Kraftnahrung | `$C9E0` · 56 bytes |  |
| `$34` | Worrior fear, I draw near, each time I appear | Sieh genau her, alter Späher, denn ich komme immer näher | `$CA19` · 54 bytes |  |
| `$35` | You're asking for trouble | Du willst wohl Ärger | `$C485` · 22 bytes |  |
| `$36` | Ha ha ha ha (padded) | Ha ha ha ha (padded) | `$C6B8` · 11 bytes |  |
| `$37` | Worrior (padded) | Worrior (padded) | `$CA50` · 7 bytes |  |
| `$38` | You've just been fried by | Der | `$CA58` · 3 bytes |  |
| `$39` | Bite the bolt | Das Strahlenschwert kitzelt | `$CA6F` · 28 bytes |  |
| `$3A` | Wasn't that lightning bolt delicious | Wie schmeckt die Strahlenkanone? | `$CA8C` · 30 bytes |  |
| `$3B` | And my teleporting spell can be even faster | Mein Teletransport wird noch schneller | `$CAAB` · 39 bytes |  |
| `$3C` | Now you know the taste of my magic | Nun kennst du den Geschmack meines Zaubers | `$CAD3` · 45 bytes |  |
| `$3D` | Maybe you'll see me again | Eines Tages treffen wir uns wieder | `$CB01` · 32 bytes |  |
| `$3E` | Your explosion was music to my ears | Deine Explosion ist Musik für meine Ohren | `$CB22` · 47 bytes |  |
| `$3F` | I'll say it again | Ich sag's noch mal | `$CB52` · 18 bytes |  |
| `$40` | Worlord | Worlord | `$C73F` · 8 bytes |  |
| `$41` | Worlord (padded) | Worlord (padded) | `$C748` · 10 bytes |  |
| `$42` | Be forewarned! You approach the Pit | Sei gewarnt, Worlord, du näherst dich dem Verlies | `$CB65` · 52 bytes |  |
| `$43` | Your path leads directly to the Pit | Dein Weg führt direkt ins Verlies | `$CB9A` · 33 bytes |  |
| `$44` | Deeper, ever deeper into | Tiefer, immer tiefer in die Labyrinthe von Wor | `$CBBC` · 43 bytes |  |
| `$45` | Beware! You are in the Worlord dungeons | Pass auf! Du bist in den Höhlen von Wor | `$CBE8` · 41 bytes |  |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master | Ah! Du willst dich wohl verstecken, aber ich bin der Höhlenmeister | `$CC12` · 64 bytes |  |
| `$47` | Thor, Bur, Gar! Dinner's ready | Thor, Bur, Gar! Essen ist fertig | `$CC53` · 30 bytes |  |
| `$48` | Hey! Your space boots untied | Hey! Zieh die Siebenmeilenstiefel an | `$CC72` · 38 bytes |  |
| `$49` | My beasts run wild in the Worlord dungeons | Meine Biester rennen wie wild durch die Höhlen des Worlords | `$CC99` · 58 bytes |  |
| `$4A` | Now your only chance is your dance | Dir bleibt keine andre Wahl: tanze oder leide Qual | `$CCD4` · 53 bytes |  |
| `$4B` | Are you fit to survive the Pit | Nun musst du dein Bestes geben, sonst wirst du nicht überleben | `$CD0A` · 64 bytes |  |
| `$4C` | Oops! I must have forgotten the walls | Hoppla! Ich habe die Wände vergessen | `$CD4B` · 32 bytes |  |
| `$4D` | Where are you going to hide now | Wo willst du dich verstecken? | `$CD6C` · 32 bytes |  |
| `$4E` | You're in | Du bist in den | `$C25B` · 16 bytes |  |
| `$4F` | — | NULL / unused pointer | — |  |
| `$50` | — | von Wor | `$C279` · 10 bytes | German helper fragment |
| `$51` | — | von Wor versauern | `$C574` · 19 bytes | German helper fragment |
| `$52` | — | hat dich gegrillt | `$CA5C` · 18 bytes | German helper fragment |
| `$53` | — | bedankt sich | `$C7F6` · 13 bytes | German helper fragment |

## Speech phrases

Phrase IDs are unchanged from English, but several German records use different fragment combinations to produce complete German sentences. Runtime rank substitution still changes `$09 -> $40` and `$37 -> $41` when `Dungeon_Class != 0`.

| Phrase ID | English result | German result | English composition | German composition | Notes |
| ---: | --- | --- | --- | --- | --- |
| `$00` | Hey, insert coin | Hey, wirf Geld ein | `$0A` | `$0A` |  |
| `$01` | Find me, the Wizard of Wor | Such mich, den Wizard von Wor | `$0B` + `$04` | `$0B` + `$04` |  |
| `$02` | Hey, insert coin | Hey, wirf Geld ein | `$0A` | `$0A` |  |
| `$03` | I'm out of sight. Ha ha ha ha! | Ich bin unsichtbar. Ha ha ha ha! | `$0C` + `$10` | `$0C` + `$10` |  |
| `$04` | Hey, insert coin | Hey, wirf Geld ein | `$0A` | `$0A` |  |
| `$05` | Find me, the Wizard of Wor | Such mich, den Wizard von Wor | `$0B` + `$04` | `$0B` + `$04` |  |
| `$06` | Hey, insert coin | Hey, wirf Geld ein | `$0A` | `$0A` |  |
| `$07` | I'm out of sight. Ha ha ha ha! | Ich bin unsichtbar. Ha ha ha ha! | `$0C` + `$10` | `$0C` + `$10` |  |
| `$08` | Get ready, Worrior | Sei bereit, Worrior | `$0D` + `$09` | `$0D` + `$09` |  |
| `$09` | You'd better hope you don't find me, the Wizard of Wor | Gnade dir Gott, wenn du den Wizard von Wor findest | `$0E` + `$04` | `$0E` | Composition differs to produce German word order |
| `$0A` | Another coin for my treasure chest | Eine weitere Münze für meine Brieftasche | `$0F` | `$0F` |  |
| `$0B` | Ah good! My pets were getting hungry. Ha ha ha ha! | Sehr gut! Meine Kleinen sind sehr hungrig. Ha ha ha ha! | `$11` + `$10` | `$11` + `$10` |  |
| `$0C` | My worlings are very very hungry. Ha ha ha ha! | Meine Schützlinge sind sehr gefräßig. Ha ha ha ha! | `$1E` + `$36` | `$1E` + `$36` |  |
| `$0D` | Welcome to my world of Wor | Willkommen in der Welt von Wor | `$2D` | `$2D` |  |
| `$0E` | So you've come to score in the world of Wor. Ha ha ha ha! | Mach dem Wizard mal was vor, sammle Punkte in der Welt von Wor. Ha ha ha ha! | `$2E` + `$10` | `$2E` + `$10` |  |
| `$0F` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | Gleich siehst du den Wizard, den magischen Wizard von Wor. Ha ha ha ha! | `$2F` + `$10` | `$2F` + `$10` |  |
| `$10` | Kill Worluk for double score | Vernichte Worluk für doppelte Punktzahl | `$00` | `$00` |  |
| `$11` | You're in the dungeons of Wor | Du bist in den Labyrinthen von Wor | `$4E` + `$02` | `$4E` + `$02` + `$50` | Composition differs to produce German word order |
| `$12` | I am the Wizard of Wor | Ich bin der Wizard von Wor | `$03` + `$04` | `$03` + `$04` |  |
| `$13` | One bite from my pretties, and you'll explode. Ha ha ha ha! | Ein Biss von meinen Schönen und du explodierst. Ha ha ha ha! | `$05` + `$10` | `$05` + `$10` | Transcription requires listening verification |
| `$14` | My creatures are radioactive | Meine Kreaturen sind radioaktiv | `$06` | `$06` |  |
| `$15` | Worluk will escape through the door | Worluk wird durch die Tür entkommen | `$07` | `$07` |  |
| `$16` | Watch the radar, Worrior | Beobachte deinen Radarschirm, Worrior | `$08` + `$37` | `$08` + `$37` |  |
| `$17` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! | Thorwor ist blutrot, gemein und hungrig auf Kraftnahrung. Ha ha ha ha! | `$33` + `$36` | `$33` + `$36` |  |
| `$18` | Remember, I'm the Wizard, not you | Denk dran, ich bin der Wizard, nicht du | `$23` | `$23` |  |
| `$19` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! | Du bleibst nicht ganz nach diesem wilden Tanz. Ha ha ha ha! | `$24` + `$36` | `$24` + `$36` | Transcription requires listening verification |
| `$1A` | You'll never leave Wor alive. Ha ha ha ha! | Du wirst Wor nicht lebendig verlassen. Ha ha ha ha! | `$27` + `$36` | `$27` + `$36` | Transcription requires listening verification |
| `$1B` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! | Wenn du meine Babys anfasst, werde ich dich im Ofen braten. Ha ha ha ha! | `$25` + `$36` | `$25` + `$36` |  |
| `$1C` | Burwor hasn't eaten anyone in months. Ha ha ha ha! | Seit Monaten hat Burwor niemanden vernascht. Ha ha ha ha! | `$30` + `$36` | `$30` + `$36` |  |
| `$1D` | My babies breathe fire, Worrior | Meine Kinder speien Feuer, Worrior | `$31` + `$09` | `$31` + `$09` |  |
| `$1E` | I'll fry you with my lightning bolts | Mit meiner Lichtkanone verbrenne ich dich | `$32` | `$32` |  |
| `$1F` | Burwor, Garwor, and Thorwor will do you in | Burwor, Garwor und Thorwor werden dich einmachen. | `$1D` | `$1D` | Transcription requires listening verification |
| `$20` | You'll get the Arena. Ha ha ha ha! | Nun wirst du in die Arena geworfen. Ha ha ha ha! | `$12` + `$36` | `$12` + `$36` |  |
| `$21` | Another Worrior for my babies to devour | Noch einen Worrior, den meine Süßen verschlingen werden. | `$13` | `$13` | Transcription requires listening verification |
| `$22` | Keep going and you will find me | Mach weiter und du findest mich | `$14` | `$14` |  |
| `$23` | A few more dungeons and you'll be a Worlord | Noch ein paar Labyrinthe und du bist ein Worlord | `$15` + `$40` | `$15` + `$40` |  |
| `$24` | Worrior, now I'm getting mad | Worrior, langsam werde ich böse | `$37` + `$26` | `$37` + `$26` |  |
| `$25` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! | Sieh genau her, alter Späher, denn ich komme immer näher. Ha ha ha ha! | `$34` + `$10` | `$34` + `$10` | Transcription requires listening verification |
| `$26` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | Worrior, du bleibst nicht ganz nach diesem wilden Tanz. Ha ha ha ha! | `$09` + `$22` + `$10` | `$09` + `$22` + `$10` | Transcription requires listening verification |
| `$27` | You're asking for trouble, Worrior | Du willst wohl Ärger, Worrior | `$35` + `$37` | `$35` + `$37` |  |
| `$28` | Now you get the heavyweights. Ha ha ha ha! | Jetzt kommen die Schwergewichte. Ha ha ha ha! | `$1A` + `$36` | `$1A` + `$36` |  |
| `$29` | Garwor, go after them! | Garwor, pack sie! | `$1B` | `$1B` |  |
| `$2A` | If you try any harder, you'll only meet with doom. Ha ha ha ha! | Wenn du's noch mal versuchst, hauen wir dich in die Pfanne. Ha ha ha ha! | `$1C` + `$36` | `$1C` + `$36` | Transcription requires listening verification |
| `$2B` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! | Wenn du zu mächtig wirst, greife ich selbst ein. Ha ha ha ha! | `$01` + `$36` | `$01` + `$36` |  |
| `$2C` | My magic is stronger than your weapons, Worrior | Meine Magiekraft ist stärker als deine Waffen, Worrior | `$1F` + `$09` | `$1F` + `$09` |  |
| `$2D` | Worrior, while you developed science, we developed magic | Worrior, du stehst auf Wissenschaft, ich glaube an Magie | `$09` + `$20` | `$09` + `$20` |  |
| `$2E` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! | Deine Knochen werden in den Labyrinthen von Wor versauern. Ha ha ha ha! | `$21` + `$36` | `$21` + `$02` + `$51` + `$36` | Composition differs to produce German word order |
| `$2F` | Garwor and Thorwor become invisible. Ha ha ha ha! | Garwor und Thorwor, macht euch unsichtbar. Ha ha ha ha! | `$28` + `$36` | `$28` + `$36` |  |
| `$30` | Come back for more with the Wizard of Wor. Ha ha ha ha! | Spiel das Spiel noch einmal; dann wirst du … Ha ha ha ha! | `$16` + `$04` + `$10` | `$16` + `$10` | Transcription requires listening verification |
| `$31` | The dungeons of Wor await your return, Worrior | Die Labyrinthe von Wor warten auf deine Rückkehr, Worrior | `$17` + `$37` | `$17` + `$37` |  |
| `$32` | Deep in the caverns of Wor, you will meet me, Worrior | Drunten in den Höhlen von Wor wirst du mich treffen, Worrior | `$18` + `$37` | `$18` + `$37` |  |
| `$33` | The Wizard of Wor thanks you | Der Wizard von Wor bedankt sich | `$04` + `$19` | `$19` + `$04` + `$53` | Composition differs to produce German word order |
| `$34` | You know you can do better, Worrior | Du weißt genau, dass du es besser kannst, Worrior | `$29` + `$37` | `$29` + `$37` |  |
| `$35` | Hurry back, I can't wait to do it again | Komm zurück, Rache ist süß | `$2A` | `$2A` |  |
| `$36` | You can start anew, but for now you're through. Ha ha ha ha! | Ich greife an mit Gebrüll, schmeiße dich jetzt auf den Müll. Ha ha ha ha! | `$2B` + `$36` | `$2B` + `$36` | Transcription requires listening verification |
| `$37` | He he he, ho ho ho, ha ha ha ha! That was fun | He he he, ho ho ho, ha ha ha ha! Das macht Spaß | `$2C` | `$2C` |  |
| `$38` | You've just been fried by the Wizard of Wor. Ha ha ha ha! | Der Wizard von Wor hat dich gegrillt. Ha ha ha ha! | `$38` + `$04` + `$10` | `$38` + `$04` + `$52` + `$10` | Composition differs to produce German word order |
| `$39` | Bite the bolt, Worrior. Ha ha ha ha! | Das Strahlenschwert kitzelt, Worrior. Ha ha ha ha! | `$39` + `$37` + `$36` | `$39` + `$37` + `$36` | Transcription requires listening verification |
| `$3A` | Wasn't that lightning bolt delicious? Ha ha ha ha! | Wie schmeckt die Strahlenkanone? Ha ha ha ha! | `$3A` + `$10` | `$3A` + `$10` |  |
| `$3B` | And my teleporting spell can be even faster. Ha ha ha ha! | Mein Teletransport wird noch schneller. Ha ha ha ha! | `$3B` + `$36` | `$3B` + `$36` |  |
| `$3C` | Now you know the taste of my magic, Worrior | Nun kennst du den Geschmack meines Zaubers, Worrior | `$3C` + `$37` | `$3C` + `$37` |  |
| `$3D` | Worrior, maybe you'll see me again | Eines Tages treffen wir uns wieder | `$09` + `$3D` | `$3D` | Composition differs to produce German word order |
| `$3E` | Your explosion was music to my ears. Ha ha ha ha! | Deine Explosion ist Musik für meine Ohren. Ha ha ha ha! | `$3E` + `$10` | `$3E` + `$10` |  |
| `$3F` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! | Ich sag’s noch mal: Sieh genau her, alter Späher, denn ich komme immer näher. Ha ha ha ha! | `$3F` + `$34` + `$10` | `$3F` + `$34` + `$10` | Transcription requires listening verification |
| `$40` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! | Sei gewarnt, Worlord, du näherst dich dem Verlies. Ha ha ha ha! | `$41` + `$42` + `$36` | `$42` + `$36` | Composition differs to produce German word order |
| `$41` | Worlord, your path leads directly to the Pit. Ha ha ha ha! | Worlord, dein Weg führt direkt ins Verlies. Ha ha ha ha! | `$41` + `$43` + `$36` | `$41` + `$43` + `$36` |  |
| `$42` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | Tiefer, immer tiefer in die Labyrinthe von Wor. Ha ha ha ha! | `$44` + `$02` + `$36` | `$44` + `$36` | Composition differs to produce German word order |
| `$43` | Beware! You are in the Worlord dungeons | Pass auf! Du bist in den Höhlen von Wor | `$45` | `$45` |  |
| `$44` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | Ah! Du willst dich wohl verstecken, aber ich bin der Höhlenmeister. Ha ha ha ha! | `$46` + `$36` | `$46` + `$36` |  |
| `$45` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | Thor, Bur, Gar! Essen ist fertig. Ha ha ha ha! | `$47` + `$36` | `$47` + `$36` |  |
| `$46` | Hey! Your space boot's untied. Ha ha ha ha! | Hey! Zieh die Siebenmeilenstiefel an. Ha ha ha ha! | `$48` + `$10` | `$48` + `$10` |  |
| `$47` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! | Meine Biester rennen wie wild durch die Höhlen des Worlords. Ha ha ha ha! | `$49` + `$36` | `$49` + `$36` |  |
| `$48` | Now your only chance is your dance. Ha ha ha ha! | Dir bleibt keine andre Wahl: tanze oder leide Qual. Ha ha ha ha! | `$4A` + `$10` | `$4A` + `$36` | Composition differs to produce German word order |
| `$49` | Are you fit to survive the Pit? Ha ha ha ha! | Nun musst du dein Bestes geben, sonst wirst du nicht überleben. Ha ha ha ha! | `$4B` + `$10` | `$4B` + `$10` |  |
| `$4A` | Oops! I must have forgotten the walls. Ha ha ha ha! | Hoppla! Ich habe die Wände vergessen. Ha ha ha ha! | `$4C` + `$10` | `$4C` + `$10` |  |
| `$4B` | Where are you going to hide now? Ha ha ha ha! | Worlord, wo willst du dich verstecken? Ha ha ha ha! | `$4D` + `$36` | `$41` + `$4D` + `$36` | Composition differs to produce German word order |
| `$4C` | Now your only chance is your dance. Ha ha ha ha! | Dir bleibt keine andre Wahl: tanze oder leide Qual. Ha ha ha ha! | `$4A` + `$10` | `$4A` + `$36` | Composition differs to produce German word order |
| `$4D` | Are you fit to survive the Pit? Ha ha ha ha! | Nun musst du dein Bestes geben, sonst wirst du nicht überleben. Ha ha ha ha! | `$4B` + `$36` | `$4B` + `$10` | Composition differs to produce German word order |
| `$4E` | Oops! I must have forgotten the walls. Ha ha ha ha! | Hoppla! Ich habe die Wände vergessen. Ha ha ha ha! | `$4C` + `$10` | `$4C` + `$10` |  |
| `$4F` | Where are you going to hide now? Ha ha ha ha! | Worlord, wo willst du dich verstecken? Ha ha ha ha! | `$4D` + `$36` | `$41` + `$4D` + `$36` | Composition differs to produce German word order |

## Build

Linux:

```sh
./build.sh -g
```

Windows:

```bat
build.bat -g
```

Both scripts assemble `src/wow_disassembly.asm` and `src/german/GERMAN_X11.asm`. The X11 output is `roms/german.x11`.

The German build packages the result directly as `roms/wowg.zip`. The default build remains `roms/wow.zip`; using `-g` does not overwrite the English archive. The Linux script writes the seven populated CPU members, `wow.x1` through `wow.x7`, and includes `sc01.bin` when present. The Windows script also emits `wow.x8` from the `$B000` socket and includes `sc01a.bin` when present.

## MAME compatibility

Stock MAME provides the German clone `wowg`, whose X11 member is named `german.x11`. Both build scripts create the correctly named `roms/wowg.zip`; no manual copy or internal ROM renaming is required.

Run:

```text
mame -window -skip_gameinfo -rompath roms wowg
```

The `wowg` driver defaults the Language setting to Foreign. Audit warnings may appear when locally rebuilt members differ from the catalogued set; the extra Windows `wow.x8` member is not loaded by the stock driver.

The Klingon build also creates `roms/wowg.zip` as its MAME compatibility archive because stock MAME has no `wowk` driver. The most recent `-g` or `-k` build therefore determines the contents of `wowg.zip`. Running the German build again restores the German archive; the separate Klingon project archive remains `roms/wowk.zip`.

## Verification and provenance

The speech and display data retain the existing German reconstruction credited in the source to Richard C. Degler. The tables above organize that work without changing its encoded bytes. Entries marked for listening verification remain unresolved transcriptions, not new translations.

The English semantic text uses the spoken `$0C` line “I'm out of sight”; the legacy resident symbol `SPK_Im_Out_Of_Spite` remains unchanged as source provenance.

Verification should cover the 4096-byte image, header pointers, 23 display records, 84 fragment slots, 80 phrase records, helper-fragment references, rank substitution, and a whole-image additive checksum of `$00`. Runtime review should include attract speech, instructions, coin-up, both rank forms, gameplay taunts, and end-of-game speech.
