# Wizard of Wor Speech Map

Wizard of Wor separates game-level speech requests from the speech fragments used to construct them:

- **79 English speech fragments (`$00-$4E`)** contain the encoded SC-01 speech records. `English_Speech_Fragment_Pointers` maps fragment IDs to these records.
- **80 game phrase IDs (`$00-$4F`)** are the language-independent requests used by the game. `English_Speech_Phrase_Table` and `German_Speech_Phrase_Table` map each phrase ID to one or more language-specific fragment IDs.
- The German X11 ROM keeps the same 80 phrase IDs but provides **84 addressable fragment slots (`$00-$53`)**, including one null/unused pointer at `$4F` and additional German-only fragments.
- When `Dungeon_Class != 0`, the speech queue substitutes fragment `$09` with `$40` and `$37` with `$41`. This changes **Worrior** to **Worlord** without changing the phrase ID.

The English phrase text below is assembled from the English fragment records and phrase table. The German phrase text is reconstructed from the SC-01 phoneme comments in `GERMAN_X11.asm`; punctuation and capitalization are editorial. Entries marked **†** contain wording that remains uncertain and should be verified by listening to the German ROM.

## Speech Fragment Map

79 English fragments (`$00-$4E`). `Bytes` is the encoded SC-01 payload length stored in the record; the record also contains its leading length byte.

| ID | ROM address | Bytes | Semantic fragment | ASM label |
|---:|---:|---:|---|---|
| $00 | $8B66 | 29 | Kill Worluk for double score | `SPK_Kill_Worluk_For_Double_Score` |
| $01 | $8B84 | 49 | If you get too powerful, I'll take care of you myself | `SPK_If_You_Get_Too_Powerful_Ill_Take_Care_Of_You_Myself` |
| $02 | $8BC1 | 20 | The dungeons of Wor | `SPK_The_Dungeons_Of_Wor` |
| $03 | $8BD6 | 8 | I am | `SPK_I_Am` |
| $04 | $8BDF | 17 | The Wizard of Wor | `SPK_The_Wizard_Of_Wor` |
| $05 | $8BF1 | 43 | One bite from my pretties, and you'll explode | `SPK_One_Bite_From_My_Pretties_And_Youll_Explode` |
| $06 | $8C1D | 28 | My creatures are radioactive | `SPK_My_Creatures_Are_Radioactive` |
| $07 | $8C3A | 30 | Worluk will escape through the door | `SPK_Worluk_Will_Escape_Through_The_Door` |
| $08 | $8D3F | 14 | Watch the radar | `SPK_Watch_The_Radar` |
| $09 | $8D4E | 6 | Worrior | `SPK_Worrior` |
| $0A | $8E77 | 19 | Hey, insert coin | `SPK_Hey_Insert_Coin` |
| $0B | $8E8B | 10 | Find me | `SPK_Find_Me` |
| $0C | $8E96 | 18 | I'm out of spite | `SPK_Im_Out_Of_Spite` |
| $0D | $8EA9 | 8 | Get ready | `SPK_Get_Ready` |
| $0E | $8EB2 | 32 | You'd better hope you don't find me | `SPK_Youd_Better_Hope_You_Dont_Find_Me` |
| $0F | $8ED3 | 30 | Another coin for my treasure chest | `SPK_Another_Coin_For_My_Treasure_Chest` |
| $10 | $8EF2 | 10 | Ha ha ha ha | `SPK_Ha_Ha_Ha_Ha` |
| $11 | $8EFD | 34 | Ah good! My pets were getting hungry | `SPK_Ah_Good_My_Pets_Were_Getting_Hungry` |
| $12 | $8F20 | 20 | You'll get the Arena | `SPK_Youll_Get_The_Arena` |
| $13 | $8F41 | 35 | Another worrior for my babies to devour | `SPK_Another_Worrior_For_My_Babies_To_Devour` |
| $14 | $8F65 | 29 | Keep going and you will find me | `SPK_Keep_Going_And_You_Will_Find_Me` |
| $15 | $8F83 | 29 | A few more dungeons and you'll be a | `SPK_A_Few_More_Dungeons_And_Youll_Be_A` |
| $16 | $8FB5 | 18 | Come back for more with | `SPK_Come_Back_For_More_With` |
| $17 | $8FC8 | 39 | The dungeons of Wor await your return | `SPK_The_Dungeons_Of_Wor_Await_Your_Return` |
| $18 | $8FF0 | 43 | Deep in the caverns of Wor, you will meet me | `SPK_Deep_In_The_Caverns_Of_Wor_You_Will_Meet_Me` |
| $19 | $901C | 14 | thanks you | `SPK_Thanks_You` |
| $1A | $8D55 | 29 | Now you get the heavyweights | `SPK_Now_You_Get_The_Heavyweights` |
| $1B | $8D29 | 21 | Garwor, go after them | `SPK_Garwor_Go_After_Them` |
| $1C | $8D8A | 42 | If you try any harder, you'll only meet with doom | `SPK_If_You_Try_Any_Harder_Youll_Only_Meet_With_Doom` |
| $1D | $8DB5 | 39 | Burwor, Garwor, and Thorwor will do you in | `SPK_Burwor_Garwor_And_Thorwor_Will_Do_You_In` |
| $1E | $8DDD | 34 | My worlings are very very hungry | `SPK_My_Worlings_Are_Very_Very_Hungry` |
| $1F | $8E00 | 35 | My magic is stronger than your weapons | `SPK_My_Magic_Is_Stronger_Than_Your_Weapons` |
| $20 | $8E4B | 43 | While you developed science, we developed magic | `SPK_While_You_Developed_Science_We_Developed_Magic` |
| $21 | $8E24 | 38 | Your bones will lie in the dungeons of Wor | `SPK_Your_Bones_Will_Lie_In_The_Dungeons_Of_Wor` |
| $22 | $8C59 | 30 | You won't have a chance for your dance | `SPK_You_Wont_Have_A_Chance_For_Your_Dance` |
| $23 | $8C78 | 31 | Remember, I'm the Wizard, not you | `SPK_Remember_Im_The_Wizard_Not_You` |
| $24 | $8C98 | 44 | If you can't beat the rest, then you'll never get the best | `SPK_If_You_Cant_Beat_The_Rest_Then_Youll_Never_Get_The_Best` |
| $25 | $8CC5 | 49 | If you destroy my babies, I'll pop you in the oven | `SPK_If_You_Destroy_My_Babies_Ill_Pop_You_In_The_Oven` |
| $26 | $8CF7 | 21 | Now I'm getting mad | `SPK_Now_Im_Getting_Mad` |
| $27 | $8D0D | 27 | You'll never leave Wor alive | `SPK_Youll_Never_Leave_Wor_Alive` |
| $28 | $917E | 34 | Garwor and Thorwor become invisible | `SPK_Garwor_And_Thorwor_Become_Invisible` |
| $29 | $902B | 24 | You know you can do better | `SPK_You_Know_You_Can_Do_Better` |
| $2A | $9044 | 38 | Hurry back, I can't wait to do it again | `SPK_Hurry_Back_I_Cant_Wait_To_Do_It_Again` |
| $2B | $906B | 39 | You can start anew, but for now you're through | `SPK_You_Can_Start_Anew_But_For_Now_Youre_Through` |
| $2C | $9093 | 34 | He he he ho ho ho ha ha ha ha, that was fun | `SPK_He_He_He_Ho_Ho_Ho_Ha_Ha_Ha_Ha_That_Was_Fun` |
| $2D | $90B6 | 25 | Welcome to my world of Wor | `SPK_Welcome_To_My_World_Of_Wor` |
| $2E | $90D0 | 33 | So you've come to score in the world of Wor | `SPK_So_Youve_Come_To_Score_In_The_World_Of_Wor` |
| $2F | $90F2 | 44 | You're off to see the Wizard, the magical Wizard of Wor | `SPK_Youre_Off_To_See_The_Wizard_The_Magical_Wizard_Of_Wor` |
| $30 | $911F | 32 | Burwor hasn't eaten anyone in months | `SPK_Burwor_Hasnt_Eaten_Anyone_In_Months` |
| $31 | $9140 | 22 | My babies breathe fire | `SPK_My_Babies_Breathe_Fire` |
| $32 | $9157 | 38 | I'll fry you with my lightning bolts | `SPK_Ill_Fry_You_With_My_Lightning_Bolts` |
| $33 | $91A1 | 44 | Thorwor is red, mean, and hungry for space food | `SPK_Thorwor_Is_Red_Mean_And_Hungry_For_Space_Food` |
| $34 | $91CE | 40 | Worrior fear, I draw near, each time I appear | `SPK_Worrior_Fear_I_Draw_Near_Each_Time_I_Appear` |
| $35 | $8D73 | 22 | You're asking for trouble | `SPK_Youre_Asking_For_Trouble` |
| $36 | $8F35 | 11 | Ha ha ha ha (padded) | `SPK_Ha_Ha_Ha_Ha_Padded` |
| $37 | $91F7 | 7 | Worrior (padded) | `SPK_Worrior_Padded` |
| $38 | $91FF | 23 | You've just been fried by | `SPK_Youve_Just_Been_Fried_By` |
| $39 | $9217 | 15 | Bite the bolt | `SPK_Bite_The_Bolt` |
| $3A | $9227 | 29 | Wasn't that lightning bolt delicious | `SPK_Wasnt_That_Lightning_Bolt_Delicious` |
| $3B | $9245 | 42 | And my teleporting spell can be even faster | `SPK_And_My_Teleporting_Spell_Can_Be_Even_Faster` |
| $3C | $9270 | 35 | Now you know the taste of my magic | `SPK_Now_You_Know_The_Taste_Of_My_Magic` |
| $3D | $9294 | 22 | Maybe you'll see me again | `SPK_Maybe_Youll_See_Me_Again` |
| $3E | $92AB | 35 | Your explosion was music to my ears | `SPK_Your_Explosion_Was_Music_To_My_Ears` |
| $3F | $92CF | 16 | I'll say it again | `SPK_Ill_Say_It_Again` |
| $40 | $8FA1 | 8 | Worlord | `SPK_Worlord` |
| $41 | $8FAA | 10 | Worlord (padded) | `SPK_Worlord_Padded` |
| $42 | $92E0 | 34 | Be forewarned! You approach the Pit | `SPK_Be_Forewarned_You_Approach_The_Pit` |
| $43 | $9303 | 34 | Your path leads directly to the Pit | `SPK_Your_Path_Leads_Directly_To_The_Pit` |
| $44 | $9326 | 22 | Deeper, ever deeper into | `SPK_Deeper_Ever_Deeper_Into` |
| $45 | $933D | 33 | Beware! You are in the Worlord dungeons | `SPK_Beware_You_Are_In_The_Worlord_Dungeons` |
| $46 | $935F | 47 | Ah! You thought you could hide, but I'm the dungeon master | `SPK_Ah_You_Thought_You_Could_Hide_But_Im_The_Dungeon_Master` |
| $47 | $938F | 27 | Thor, Bur, Gar! Dinner's ready | `SPK_Thor_Bur_Gar_Dinners_Ready` |
| $48 | $93AB | 31 | Hey! Your space boots untied | `SPK_Hey_Your_Space_Boots_Untied` |
| $49 | $93CB | 44 | My beasts run wild in the Worlord dungeons | `SPK_My_Beasts_Run_Wild_In_The_Worlord_Dungeons` |
| $4A | $93F8 | 28 | Now your only chance is your dance | `SPK_Now_Your_Only_Chance_Is_Your_Dance` |
| $4B | $9415 | 36 | Are you fit to survive the Pit | `SPK_Are_You_Fit_To_Survive_The_Pit` |
| $4C | $943A | 31 | Oops! I must have forgotten the walls | `SPK_Oops_I_Must_Have_Forgotten_The_Walls` |
| $4D | $945A | 27 | Where are you going to hide now | `SPK_Where_Are_You_Going_To_Hide_Now` |
| $4E | $8BB6 | 10 | You're in | `SPK_Youre_In` |

## Speech Phrase Map

80 game phrase IDs (`$00-$4F`). Fragment composition is shown exactly as stored in each language's phrase table. Duplicate phrase IDs are intentional.

| Phrase ID | English fragment composition | Resulting English phrase | German fragment composition | Resulting German phrase |
|---:|---|---|---|---|
| `$00` | `$0A` | Hey, insert coin | `$0A` | Hey, wirf Geld ein |
| `$01` | `$0B` + `$04` | Find me, the Wizard of Wor | `$0B` + `$04` | Such mich, den Wizard von Wor |
| `$02` | `$0A` | Hey, insert coin | `$0A` | Hey, wirf Geld ein |
| `$03` | `$0C` + `$10` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` | Ich bin unsichtbar. Ha ha ha ha! |
| `$04` | `$0A` | Hey, insert coin | `$0A` | Hey, wirf Geld ein |
| `$05` | `$0B` + `$04` | Find me, the Wizard of Wor | `$0B` + `$04` | Such mich, den Wizard von Wor |
| `$06` | `$0A` | Hey, insert coin | `$0A` | Hey, wirf Geld ein |
| `$07` | `$0C` + `$10` | I'm out of spite. Ha ha ha ha! | `$0C` + `$10` | Ich bin unsichtbar. Ha ha ha ha! |
| `$08` | `$0D` + `$09` | Get ready, Worrior | `$0D` + `$09` | Sei bereit, Worrior |
| `$09` | `$0E` + `$04` | You'd better hope you don't find me, the Wizard of Wor | `$0E` | Gnade dir Gott, wenn du den Wizard von Wor findest |
| `$0A` | `$0F` | Another coin for my treasure chest | `$0F` | Eine weitere Münze für meine Brieftasche |
| `$0B` | `$11` + `$10` | Ah good! My pets were getting hungry. Ha ha ha ha! | `$11` + `$10` | Sehr gut! Meine Kleinen sind sehr hungrig. Ha ha ha ha! |
| `$0C` | `$1E` + `$36` | My worlings are very very hungry. Ha ha ha ha! | `$1E` + `$36` | Meine Schützlinge sind sehr gefräßig. Ha ha ha ha! |
| `$0D` | `$2D` | Welcome to my world of Wor | `$2D` | Willkommen in der Welt von Wor |
| `$0E` | `$2E` + `$10` | So you've come to score in the world of Wor. Ha ha ha ha! | `$2E` + `$10` | Mach dem Wizard mal was vor, sammle Punkte in der Welt von Wor. Ha ha ha ha! |
| `$0F` | `$2F` + `$10` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! | `$2F` + `$10` | Gleich siehst du den Wizard, den magischen Wizard von Wor. Ha ha ha ha! |
| `$10` | `$00` | Kill Worluk for double score | `$00` | Vernichte Worluk für doppelte Punktzahl |
| `$11` | `$4E` + `$02` | You're in the dungeons of Wor | `$4E` + `$02` + `$50` | Du bist in den Labyrinthen von Wor |
| `$12` | `$03` + `$04` | I am the Wizard of Wor | `$03` + `$04` | Ich bin der Wizard von Wor |
| `$13` | `$05` + `$10` | One bite from my pretties, and you'll explode. Ha ha ha ha! | `$05` + `$10` | Ein Biss von meinen Schönen und du explodierst. Ha ha ha ha! † |
| `$14` | `$06` | My creatures are radioactive | `$06` | Meine Kreaturen sind radioaktiv |
| `$15` | `$07` | Worluk will escape through the door | `$07` | Worluk wird durch die Tür entkommen |
| `$16` | `$08` + `$37` | Watch the radar, Worrior | `$08` + `$37` | Beobachte deinen Radarschirm, Worrior |
| `$17` | `$33` + `$36` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! | `$33` + `$36` | Thorwor ist blutrot, gemein und hungrig auf Kraftnahrung. Ha ha ha ha! |
| `$18` | `$23` | Remember, I'm the Wizard, not you | `$23` | Denk dran, ich bin der Wizard, nicht du |
| `$19` | `$24` + `$36` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! | `$24` + `$36` | Du bleibst nicht ganz nach diesem wilden Tanz. Ha ha ha ha! † |
| `$1A` | `$27` + `$36` | You'll never leave Wor alive. Ha ha ha ha! | `$27` + `$36` | Du wirst Wor nicht lebendig verlassen. Ha ha ha ha! † |
| `$1B` | `$25` + `$36` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! | `$25` + `$36` | Wenn du meine Babys anfasst, werde ich dich im Ofen braten. Ha ha ha ha! |
| `$1C` | `$30` + `$36` | Burwor hasn't eaten anyone in months. Ha ha ha ha! | `$30` + `$36` | Seit Monaten hat Burwor niemanden vernascht. Ha ha ha ha! |
| `$1D` | `$31` + `$09` | My babies breathe fire, Worrior | `$31` + `$09` | Meine Kinder speien Feuer, Worrior |
| `$1E` | `$32` | I'll fry you with my lightning bolts | `$32` | Mit meiner Lichtkanone verbrenne ich dich |
| `$1F` | `$1D` | Burwor, Garwor, and Thorwor will do you in | `$1D` | Burwor, Garwor und Thorwor werden dich einmachen. † |
| `$20` | `$12` + `$36` | You'll get the Arena. Ha ha ha ha! | `$12` + `$36` | Nun wirst du in die Arena geworfen. Ha ha ha ha! |
| `$21` | `$13` | Another Worrior for my babies to devour | `$13` | Noch einen Worrior, den meine Süßen verschlingen werden. † |
| `$22` | `$14` | Keep going and you will find me | `$14` | Mach weiter und du findest mich |
| `$23` | `$15` + `$40` | A few more dungeons and you'll be a Worlord | `$15` + `$40` | Noch ein paar Labyrinthe und du bist ein Worlord |
| `$24` | `$37` + `$26` | Worrior, now I'm getting mad | `$37` + `$26` | Worrior, langsam werde ich böse |
| `$25` | `$34` + `$10` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$34` + `$10` | Sieh genau her, alter Späher, denn ich komme immer näher. Ha ha ha ha! † |
| `$26` | `$09` + `$22` + `$10` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | `$09` + `$22` + `$10` | Worrior, du bleibst nicht ganz nach diesem wilden Tanz. Ha ha ha ha! † |
| `$27` | `$35` + `$37` | You're asking for trouble, Worrior | `$35` + `$37` | Du willst wohl Ärger, Worrior |
| `$28` | `$1A` + `$36` | Now you get the heavyweights. Ha ha ha ha! | `$1A` + `$36` | Jetzt kommen die Schwergewichte. Ha ha ha ha! |
| `$29` | `$1B` | Garwor, go after them! | `$1B` | Garwor, pack sie! |
| `$2A` | `$1C` + `$36` | If you try any harder, you'll only meet with doom. Ha ha ha ha! | `$1C` + `$36` | Wenn du's noch mal versuchst, hauen wir dich in die Pfanne. Ha ha ha ha! † |
| `$2B` | `$01` + `$36` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! | `$01` + `$36` | Wenn du zu mächtig wirst, greife ich selbst ein. Ha ha ha ha! |
| `$2C` | `$1F` + `$09` | My magic is stronger than your weapons, Worrior | `$1F` + `$09` | Meine Magiekraft ist stärker als deine Waffen, Worrior |
| `$2D` | `$09` + `$20` | Worrior, while you developed science, we developed magic | `$09` + `$20` | Worrior, du stehst auf Wissenschaft, ich glaube an Magie |
| `$2E` | `$21` + `$36` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! | `$21` + `$02` + `$51` + `$36` | Deine Knochen werden in den Labyrinthen von Wor versauern. Ha ha ha ha! |
| `$2F` | `$28` + `$36` | Garwor and Thorwor become invisible. Ha ha ha ha! | `$28` + `$36` | Garwor und Thorwor, macht euch unsichtbar. Ha ha ha ha! |
| `$30` | `$16` + `$04` + `$10` | Come back for more with the Wizard of Wor. Ha ha ha ha! | `$16` + `$10` | Spiel das Spiel noch einmal; dann wirst du … Ha ha ha ha! † |
| `$31` | `$17` + `$37` | The dungeons of Wor await your return, Worrior | `$17` + `$37` | Die Labyrinthe von Wor warten auf deine Rückkehr, Worrior |
| `$32` | `$18` + `$37` | Deep in the caverns of Wor, you will meet me, Worrior | `$18` + `$37` | Drunten in den Höhlen von Wor wirst du mich treffen, Worrior |
| `$33` | `$04` + `$19` | The Wizard of Wor thanks you | `$19` + `$04` + `$53` | Der Wizard von Wor bedankt sich |
| `$34` | `$29` + `$37` | You know you can do better, Worrior | `$29` + `$37` | Du weißt genau, dass du es besser kannst, Worrior |
| `$35` | `$2A` | Hurry back, I can't wait to do it again | `$2A` | Komm zurück, Rache ist süß |
| `$36` | `$2B` + `$36` | You can start anew, but for now you're through. Ha ha ha ha! | `$2B` + `$36` | Ich greife an mit Gebrüll, schmeiße dich jetzt auf den Müll. Ha ha ha ha! † |
| `$37` | `$2C` | He he he, ho ho ho, ha ha ha ha! That was fun | `$2C` | He he he, ho ho ho, ha ha ha ha! Das macht Spaß |
| `$38` | `$38` + `$04` + `$10` | You've just been fried by the Wizard of Wor. Ha ha ha ha! | `$38` + `$04` + `$52` + `$10` | Der Wizard von Wor hat dich gegrillt. Ha ha ha ha! |
| `$39` | `$39` + `$37` + `$36` | Bite the bolt, Worrior. Ha ha ha ha! | `$39` + `$37` + `$36` | Das Strahlenschwert kitzelt, Worrior. Ha ha ha ha! † |
| `$3A` | `$3A` + `$10` | Wasn't that lightning bolt delicious? Ha ha ha ha! | `$3A` + `$10` | Wie schmeckt die Strahlenkanone? Ha ha ha ha! |
| `$3B` | `$3B` + `$36` | And my teleporting spell can be even faster. Ha ha ha ha! | `$3B` + `$36` | Mein Teletransport wird noch schneller. Ha ha ha ha! |
| `$3C` | `$3C` + `$37` | Now you know the taste of my magic, Worrior | `$3C` + `$37` | Nun kennst du den Geschmack meines Zaubers, Worrior |
| `$3D` | `$09` + `$3D` | Worrior, maybe you'll see me again | `$3D` | Eines Tages treffen wir uns wieder |
| `$3E` | `$3E` + `$10` | Your explosion was music to my ears. Ha ha ha ha! | `$3E` + `$10` | Deine Explosion ist Musik für meine Ohren. Ha ha ha ha! |
| `$3F` | `$3F` + `$34` + `$10` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! | `$3F` + `$34` + `$10` | Ich sag’s noch mal: Sieh genau her, alter Späher, denn ich komme immer näher. Ha ha ha ha! † |
| `$40` | `$41` + `$42` + `$36` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! | `$42` + `$36` | Sei gewarnt, Worlord, du näherst dich dem Verlies. Ha ha ha ha! |
| `$41` | `$41` + `$43` + `$36` | Worlord, your path leads directly to the Pit. Ha ha ha ha! | `$41` + `$43` + `$36` | Worlord, dein Weg führt direkt ins Verlies. Ha ha ha ha! |
| `$42` | `$44` + `$02` + `$36` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! | `$44` + `$36` | Tiefer, immer tiefer in die Labyrinthe von Wor. Ha ha ha ha! |
| `$43` | `$45` | Beware! You are in the Worlord dungeons | `$45` | Pass auf! Du bist in den Höhlen von Wor |
| `$44` | `$46` + `$36` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! | `$46` + `$36` | Ah! Du willst dich wohl verstecken, aber ich bin der Höhlenmeister. Ha ha ha ha! |
| `$45` | `$47` + `$36` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! | `$47` + `$36` | Thor, Bur, Gar! Essen ist fertig. Ha ha ha ha! |
| `$46` | `$48` + `$10` | Hey! Your space boot's untied. Ha ha ha ha! | `$48` + `$10` | Hey! Zieh die Siebenmeilenstiefel an. Ha ha ha ha! |
| `$47` | `$49` + `$36` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! | `$49` + `$36` | Meine Biester rennen wie wild durch die Höhlen des Worlords. Ha ha ha ha! |
| `$48` | `$4A` + `$10` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$36` | Dir bleibt keine andre Wahl: tanze oder leide Qual. Ha ha ha ha! |
| `$49` | `$4B` + `$10` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$10` | Nun musst du dein Bestes geben, sonst wirst du nicht überleben. Ha ha ha ha! |
| `$4A` | `$4C` + `$10` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` | Hoppla! Ich habe die Wände vergessen. Ha ha ha ha! |
| `$4B` | `$4D` + `$36` | Where are you going to hide now? Ha ha ha ha! | `$41` + `$4D` + `$36` | Worlord, wo willst du dich verstecken? Ha ha ha ha! |
| `$4C` | `$4A` + `$10` | Now your only chance is your dance. Ha ha ha ha! | `$4A` + `$36` | Dir bleibt keine andre Wahl: tanze oder leide Qual. Ha ha ha ha! |
| `$4D` | `$4B` + `$36` | Are you fit to survive the Pit? Ha ha ha ha! | `$4B` + `$10` | Nun musst du dein Bestes geben, sonst wirst du nicht überleben. Ha ha ha ha! |
| `$4E` | `$4C` + `$10` | Oops! I must have forgotten the walls. Ha ha ha ha! | `$4C` + `$10` | Hoppla! Ich habe die Wände vergessen. Ha ha ha ha! |
| `$4F` | `$4D` + `$36` | Where are you going to hide now? Ha ha ha ha! | `$41` + `$4D` + `$36` | Worlord, wo willst du dich verstecken? Ha ha ha ha! |
