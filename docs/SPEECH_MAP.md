# Wizard of Wor Speech Map

Wizard of Wor uses two distinct speech layers: **game phrase IDs** select what the
game wants to say, while **language-local speech fragments** provide the encoded
SC-01 material used to construct that phrase.

## Speech architecture at a glance

| Layer | English | German X11 |
|---|---|---|
| Game phrase IDs | 80 IDs (`$00-$4F`) | Same 80 IDs (`$00-$4F`) |
| Fragment pointer slots | 79 (`$00-$4E`) | 84 (`$00-$53`) |
| Actual speech fragments | 79 | 83 |
| Null / unused fragment slots | none | `$4F` |
| Additional language-only fragments | none | `$50-$53` |

The game-facing phrase IDs are language independent. `English_Speech_Phrase_Table`
and `German_Speech_Phrase_Table` map each phrase ID to one or more fragment IDs.
Fragment IDs are language-local building blocks; the same game phrase can therefore
use a different number and arrangement of fragments in each language.

`English_Speech_Fragment_Pointers` maps English fragment IDs `$00-$4E` to the
resident speech records. The German X11 ROM provides its own pointer table for
`$00-$53`; slot `$4F` is null, while `$50-$53` are real German-only fragments.

The fragment records correspond directly to the Votrax player libraries:
`votrax_library_wow.json` contains the 79 English fragments and
`votrax_library_wowg.json` contains the 83 actual German fragments.

### ROM encoding versus Votrax-library bytes

The ROM speech records are not plain SC-01 byte arrays. Bits 0-5 hold the direct
SC-01 phoneme ID, while the upper bits preserve the game's speech encoding/control
state. The Votrax JSON libraries intentionally contain the direct SC-01 values
(`encoded_byte & $3F`) for playback. Do not regenerate ROM speech records from the
JSON byte arrays; the original encoded ROM bytes must be preserved.

When `Dungeon_Class != 0`, the speech queue substitutes fragment `$09` with `$40`
and `$37` with `$41` before language-specific pointer lookup. This changes
**Worrior** to **Worlord** without changing the game phrase ID.

The English phrase text below is assembled from the English fragment records and
phrase table. German text is reconstructed from the SC-01 phoneme comments in
`GERMAN_X11.asm`; punctuation and capitalization are editorial. Entries marked
**†** contain wording that remains uncertain and should be verified by listening
to the German ROM.

## Speech Fragment Map

This table is the union of the English and German fragment-ID spaces, indexed once
from `$00-$53`. Each language cell shows the semantic fragment followed by its ROM
address, encoded payload length, and ASM label. `Bytes` excludes the leading
length byte.

| ID | English resident ROM | German X11 ROM |
|---:|---|---|
| `$00` | Kill Worluk for double score<br>`@ $8B66` · 29 bytes<br>`SPK_Kill_Worluk_For_Double_Score` | Vernichte Worluk für doppelte Punktzahl<br>`@ $C200` · 41 bytes<br>`German_Speech_Fragment_00` |
| `$01` | If you get too powerful, I'll take care of you myself<br>`@ $8B84` · 49 bytes<br>`SPK_If_You_Get_Too_Powerful_Ill_Take_Care_Of_You_Myself` | Wenn du zu mächtig wirst, greife ich selbst ein<br>`@ $C22A` · 48 bytes<br>`German_Speech_Fragment_01` |
| `$02` | The dungeons of Wor<br>`@ $8BC1` · 20 bytes<br>`SPK_The_Dungeons_Of_Wor` | Labyrinth<br>`@ $C26C` · 12 bytes<br>`German_Speech_Fragment_02` |
| `$03` | I am<br>`@ $8BD6` · 8 bytes<br>`SPK_I_Am` | Ich bin der<br>`@ $C307` · 9 bytes<br>`German_Speech_Fragment_03` |
| `$04` | The Wizard of Wor<br>`@ $8BDF` · 17 bytes<br>`SPK_The_Wizard_Of_Wor` | Wizard von Wor<br>`@ $C284` · 15 bytes<br>`German_Speech_Fragment_04` |
| `$05` | One bite from my pretties, and you'll explode<br>`@ $8BF1` · 43 bytes<br>`SPK_One_Bite_From_My_Pretties_And_Youll_Explode` | Ein Biss von meinen Schönen und du explodierst<br>`@ $C294` · 41 bytes<br>`German_Speech_Fragment_05` |
| `$06` | My creatures are radioactive<br>`@ $8C1D` · 28 bytes<br>`SPK_My_Creatures_Are_Radioactive` | Meine Kreaturen sind radioaktiv<br>`@ $C2BE` · 36 bytes<br>`German_Speech_Fragment_06` |
| `$07` | Worluk will escape through the door<br>`@ $8C3A` · 30 bytes<br>`SPK_Worluk_Will_Escape_Through_The_Door` | Worluk wird durch die Tür entkommen<br>`@ $C2E3` · 35 bytes<br>`German_Speech_Fragment_07` |
| `$08` | Watch the radar<br>`@ $8D3F` · 14 bytes<br>`SPK_Watch_The_Radar` | Beobachte deinen Radarschirm<br>`@ $C441` · 32 bytes<br>`German_Speech_Fragment_08` |
| `$09` | Worrior<br>`@ $8D4E` · 6 bytes<br>`SPK_Worrior` | Worrior<br>`@ $C462` · 6 bytes<br>`German_Speech_Fragment_09` |
| `$0A` | Hey, insert coin<br>`@ $8E77` · 19 bytes<br>`SPK_Hey_Insert_Coin` | Hey, wirf Geld ein<br>`@ $C5BA` · 21 bytes<br>`German_Speech_Fragment_0A` |
| `$0B` | Find me<br>`@ $8E8B` · 10 bytes<br>`SPK_Find_Me` | Such mich, den<br>`@ $C5D0` · 15 bytes<br>`German_Speech_Fragment_0B` |
| `$0C` | I'm out of spite<br>`@ $8E96` · 18 bytes<br>`SPK_Im_Out_Of_Spite` | Ich bin unsichtbar<br>`@ $C5E0` · 19 bytes<br>`German_Speech_Fragment_0C` |
| `$0D` | Get ready<br>`@ $8EA9` · 8 bytes<br>`SPK_Get_Ready` | Sei bereit<br>`@ $C5F4` · 11 bytes<br>`German_Speech_Fragment_0D` |
| `$0E` | You'd better hope you don't find me<br>`@ $8EB2` · 32 bytes<br>`SPK_Youd_Better_Hope_You_Dont_Find_Me` | Gnade dir Gott, wenn du den Wizard von Wor findest<br>`@ $C600` · 49 bytes<br>`German_Speech_Fragment_0E` |
| `$0F` | Another coin for my treasure chest<br>`@ $8ED3` · 30 bytes<br>`SPK_Another_Coin_For_My_Treasure_Chest` | Eine weitere Münze für meine Brieftasche<br>`@ $C632` · 43 bytes<br>`German_Speech_Fragment_0F` |
| `$10` | Ha ha ha ha<br>`@ $8EF2` · 10 bytes<br>`SPK_Ha_Ha_Ha_Ha` | Ha ha ha ha<br>`@ $C65E` · 10 bytes<br>`German_Speech_Fragment_10` |
| `$11` | Ah good! My pets were getting hungry<br>`@ $8EFD` · 34 bytes<br>`SPK_Ah_Good_My_Pets_Were_Getting_Hungry` | Sehr gut! Meine Kleinen sind sehr hungrig<br>`@ $C669` · 42 bytes<br>`German_Speech_Fragment_11` |
| `$12` | You'll get the Arena<br>`@ $8F20` · 20 bytes<br>`SPK_Youll_Get_The_Arena` | Nun wirst du in die Arena geworfen<br>`@ $C694` · 35 bytes<br>`German_Speech_Fragment_12` |
| `$13` | Another worrior for my babies to devour<br>`@ $8F41` · 35 bytes<br>`SPK_Another_Worrior_For_My_Babies_To_Devour` | Noch einen Worrior, den meine Süßen verschlingen werden<br>`@ $C6C4` · 49 bytes<br>`German_Speech_Fragment_13` |
| `$14` | Keep going and you will find me<br>`@ $8F65` · 29 bytes<br>`SPK_Keep_Going_And_You_Will_Find_Me` | Mach weiter und du findest mich<br>`@ $C6F6` · 31 bytes<br>`German_Speech_Fragment_14` |
| `$15` | A few more dungeons and you'll be a<br>`@ $8F83` · 29 bytes<br>`SPK_A_Few_More_Dungeons_And_Youll_Be_A` | Noch ein paar Labyrinthe und du bist ein<br>`@ $C716` · 40 bytes<br>`German_Speech_Fragment_15` |
| `$16` | Come back for more with<br>`@ $8FB5` · 18 bytes<br>`SPK_Come_Back_For_More_With` | Spiel das Spiel noch einmal; dann wirst du ...<br>`@ $C753` · 53 bytes<br>`German_Speech_Fragment_16` |
| `$17` | The dungeons of Wor await your return<br>`@ $8FC8` · 39 bytes<br>`SPK_The_Dungeons_Of_Wor_Await_Your_Return` | Die Labyrinthe von Wor warten auf deine Rückkehr<br>`@ $C789` · 52 bytes<br>`German_Speech_Fragment_17` |
| `$18` | Deep in the caverns of Wor, you will meet me<br>`@ $8FF0` · 43 bytes<br>`SPK_Deep_In_The_Caverns_Of_Wor_You_Will_Meet_Me` | Drunten in den Höhlen von Wor wirst du mich treffen<br>`@ $C7BE` · 51 bytes<br>`German_Speech_Fragment_18` |
| `$19` | thanks you<br>`@ $901C` · 14 bytes<br>`SPK_Thanks_You` | Der<br>`@ $C7F2` · 3 bytes<br>`German_Speech_Fragment_19` |
| `$1A` | Now you get the heavyweights<br>`@ $8D55` · 29 bytes<br>`SPK_Now_You_Get_The_Heavyweights` | Jetzt kommen die Schwergewichte<br>`@ $C469` · 27 bytes<br>`German_Speech_Fragment_1A` |
| `$1B` | Garwor, go after them<br>`@ $8D29` · 21 bytes<br>`SPK_Garwor_Go_After_Them` | Garwor, pack sie!<br>`@ $C42E` · 18 bytes<br>`German_Speech_Fragment_1B` |
| `$1C` | If you try any harder, you'll only meet with doom<br>`@ $8D8A` · 42 bytes<br>`SPK_If_You_Try_Any_Harder_Youll_Only_Meet_With_Doom` | Wenn du's noch mal versuchst, hauen wir dich in die Pfanne<br>`@ $C49C` · 54 bytes<br>`German_Speech_Fragment_1C` |
| `$1D` | Burwor, Garwor, and Thorwor will do you in<br>`@ $8DB5` · 39 bytes<br>`SPK_Burwor_Garwor_And_Thorwor_Will_Do_You_In` | Burwor, Garwor und Thorwor werden dich einmachen<br>`@ $C4D3` · 48 bytes<br>`German_Speech_Fragment_1D` |
| `$1E` | My worlings are very very hungry<br>`@ $8DDD` · 34 bytes<br>`SPK_My_Worlings_Are_Very_Very_Hungry` | Meine Schützlinge sind sehr gefräßig<br>`@ $C504` · 36 bytes<br>`German_Speech_Fragment_1E` |
| `$1F` | My magic is stronger than your weapons<br>`@ $8E00` · 35 bytes<br>`SPK_My_Magic_Is_Stronger_Than_Your_Weapons` | Meine Magiekraft ist stärker als deine Waffen<br>`@ $C529` · 47 bytes<br>`German_Speech_Fragment_1F` |
| `$20` | While you developed science, we developed magic<br>`@ $8E4B` · 43 bytes<br>`SPK_While_You_Developed_Science_We_Developed_Magic` | Du stehst auf Wissenschaft, ich glaube an Magie<br>`@ $C588` · 49 bytes<br>`German_Speech_Fragment_20` |
| `$21` | Your bones will lie in the dungeons of Wor<br>`@ $8E24` · 38 bytes<br>`SPK_Your_Bones_Will_Lie_In_The_Dungeons_Of_Wor` | Deine Knochen werden in den<br>`@ $C559` · 26 bytes<br>`German_Speech_Fragment_21` |
| `$22` | You won't have a chance for your dance<br>`@ $8C59` · 30 bytes<br>`SPK_You_Wont_Have_A_Chance_For_Your_Dance` | Du bleibst nicht ganz nach diesem wilden Tanz<br>`@ $C311` · 44 bytes<br>`German_Speech_Fragment_22` |
| `$23` | Remember, I'm the Wizard, not you<br>`@ $8C78` · 31 bytes<br>`SPK_Remember_Im_The_Wizard_Not_You` | Denk dran, ich bin der Wizard, nicht du<br>`@ $C33E` · 37 bytes<br>`German_Speech_Fragment_23` |
| `$24` | If you can't beat the rest, then you'll never get the best<br>`@ $8C98` · 44 bytes<br>`SPK_If_You_Cant_Beat_The_Rest_Then_Youll_Never_Get_The_Best` | Wenn du den Rest schlägst, dann nenn dich der Beste<br>`@ $C364` · 64 bytes<br>`German_Speech_Fragment_24` |
| `$25` | If you destroy my babies, I'll pop you in the oven<br>`@ $8CC5` · 49 bytes<br>`SPK_If_You_Destroy_My_Babies_Ill_Pop_You_In_The_Oven` | Wenn du meine Babys anfasst, werde ich dich im Ofen braten<br>`@ $C3A5` · 56 bytes<br>`German_Speech_Fragment_25` |
| `$26` | Now I'm getting mad<br>`@ $8CF7` · 21 bytes<br>`SPK_Now_Im_Getting_Mad` | Langsam werde ich böse<br>`@ $C3DE` · 28 bytes<br>`German_Speech_Fragment_26` |
| `$27` | You'll never leave Wor alive<br>`@ $8D0D` · 27 bytes<br>`SPK_Youll_Never_Leave_Wor_Alive` | Du wirst Wor nicht lebendig verlassen<br>`@ $C3FB` · 50 bytes<br>`German_Speech_Fragment_27` |
| `$28` | Garwor and Thorwor become invisible<br>`@ $917E` · 34 bytes<br>`SPK_Garwor_And_Thorwor_Become_Invisible` | Garwor und Thorwor, macht euch unsichtbar<br>`@ $C9B4` · 43 bytes<br>`German_Speech_Fragment_28` |
| `$29` | You know you can do better<br>`@ $902B` · 24 bytes<br>`SPK_You_Know_You_Can_Do_Better` | Du weißt genau, dass du es besser kannst<br>`@ $C804` · 41 bytes<br>`German_Speech_Fragment_29` |
| `$2A` | Hurry back, I can't wait to do it again<br>`@ $9044` · 38 bytes<br>`SPK_Hurry_Back_I_Cant_Wait_To_Do_It_Again` | Komm zurück, Rache ist süß<br>`@ $C82E` · 33 bytes<br>`German_Speech_Fragment_2A` |
| `$2B` | You can start anew, but for now you're through<br>`@ $906B` · 39 bytes<br>`SPK_You_Can_Start_Anew_But_For_Now_Youre_Through` | Ich greife an mit Gebrüll, schmeiße dich jetzt auf den Müll<br>`@ $C850` · 61 bytes<br>`German_Speech_Fragment_2B` |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun<br>`@ $9093` · 34 bytes<br>`SPK_He_He_He_Ho_Ho_Ho_Ha_Ha_Ha_Ha_That_Was_Fun` | He he he, ho ho ho, ha ha ha ha! Das macht Spaß<br>`@ $C88E` · 40 bytes<br>`German_Speech_Fragment_2C` |
| `$2D` | Welcome to my world of Wor<br>`@ $90B6` · 25 bytes<br>`SPK_Welcome_To_My_World_Of_Wor` | Willkommen in der Welt von Wor<br>`@ $C8B7` · 29 bytes<br>`German_Speech_Fragment_2D` |
| `$2E` | So you've come to score in the world of Wor<br>`@ $90D0` · 33 bytes<br>`SPK_So_Youve_Come_To_Score_In_The_World_Of_Wor` | Mach dem Wizard mal was vor, sammle Punkte in der Welt von Wor<br>`@ $C8D5` · 53 bytes<br>`German_Speech_Fragment_2E` |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor<br>`@ $90F2` · 44 bytes<br>`SPK_Youre_Off_To_See_The_Wizard_The_Magical_Wizard_Of_Wor` | Gleich siehst du den Wizard, den magischen Wizard von Wor<br>`@ $C90B` · 47 bytes<br>`German_Speech_Fragment_2F` |
| `$30` | Burwor hasn't eaten anyone in months<br>`@ $911F` · 32 bytes<br>`SPK_Burwor_Hasnt_Eaten_Anyone_In_Months` | Seit Monaten hat Burwor niemanden vernascht<br>`@ $C93B` · 41 bytes<br>`German_Speech_Fragment_30` |
| `$31` | My babies breathe fire<br>`@ $9140` · 22 bytes<br>`SPK_My_Babies_Breathe_Fire` | Meine Kinder speien Feuer<br>`@ $C965` · 30 bytes<br>`German_Speech_Fragment_31` |
| `$32` | I'll fry you with my lightning bolts<br>`@ $9157` · 38 bytes<br>`SPK_Ill_Fry_You_With_My_Lightning_Bolts` | Mit meiner Lichtkanone verbrenne ich dich<br>`@ $C984` · 47 bytes<br>`German_Speech_Fragment_32` |
| `$33` | Thorwor is red, mean, and hungry for space food<br>`@ $91A1` · 44 bytes<br>`SPK_Thorwor_Is_Red_Mean_And_Hungry_For_Space_Food` | Thorwor ist blutrot, gemein und hungrig auf Kraftnahrung<br>`@ $C9E0` · 56 bytes<br>`German_Speech_Fragment_33` |
| `$34` | Worrior fear, I draw near, each time I appear<br>`@ $91CE` · 40 bytes<br>`SPK_Worrior_Fear_I_Draw_Near_Each_Time_I_Appear` | Sieh genau her, alter Späher, denn ich komme immer näher<br>`@ $CA19` · 54 bytes<br>`German_Speech_Fragment_34` |
| `$35` | You're asking for trouble<br>`@ $8D73` · 22 bytes<br>`SPK_Youre_Asking_For_Trouble` | Du willst wohl Ärger<br>`@ $C485` · 22 bytes<br>`German_Speech_Fragment_35` |
| `$36` | Ha ha ha ha (padded)<br>`@ $8F35` · 11 bytes<br>`SPK_Ha_Ha_Ha_Ha_Padded` | Ha ha ha ha (padded)<br>`@ $C6B8` · 11 bytes<br>`German_Speech_Fragment_36` |
| `$37` | Worrior (padded)<br>`@ $91F7` · 7 bytes<br>`SPK_Worrior_Padded` | Worrior (padded)<br>`@ $CA50` · 7 bytes<br>`German_Speech_Fragment_37` |
| `$38` | You've just been fried by<br>`@ $91FF` · 23 bytes<br>`SPK_Youve_Just_Been_Fried_By` | Der<br>`@ $CA58` · 3 bytes<br>`German_Speech_Fragment_38` |
| `$39` | Bite the bolt<br>`@ $9217` · 15 bytes<br>`SPK_Bite_The_Bolt` | Das Strahlenschwert kitzelt<br>`@ $CA6F` · 28 bytes<br>`German_Speech_Fragment_39` |
| `$3A` | Wasn't that lightning bolt delicious<br>`@ $9227` · 29 bytes<br>`SPK_Wasnt_That_Lightning_Bolt_Delicious` | Wie schmeckt die Strahlenkanone?<br>`@ $CA8C` · 30 bytes<br>`German_Speech_Fragment_3A` |
| `$3B` | And my teleporting spell can be even faster<br>`@ $9245` · 42 bytes<br>`SPK_And_My_Teleporting_Spell_Can_Be_Even_Faster` | Mein Teletransport wird noch schneller<br>`@ $CAAB` · 39 bytes<br>`German_Speech_Fragment_3B` |
| `$3C` | Now you know the taste of my magic<br>`@ $9270` · 35 bytes<br>`SPK_Now_You_Know_The_Taste_Of_My_Magic` | Nun kennst du den Geschmack meines Zaubers<br>`@ $CAD3` · 45 bytes<br>`German_Speech_Fragment_3C` |
| `$3D` | Maybe you'll see me again<br>`@ $9294` · 22 bytes<br>`SPK_Maybe_Youll_See_Me_Again` | Eines Tages treffen wir uns wieder<br>`@ $CB01` · 32 bytes<br>`German_Speech_Fragment_3D` |
| `$3E` | Your explosion was music to my ears<br>`@ $92AB` · 35 bytes<br>`SPK_Your_Explosion_Was_Music_To_My_Ears` | Deine Explosion ist Musik für meine Ohren<br>`@ $CB22` · 47 bytes<br>`German_Speech_Fragment_3E` |
| `$3F` | I'll say it again<br>`@ $92CF` · 16 bytes<br>`SPK_Ill_Say_It_Again` | Ich sag's noch mal<br>`@ $CB52` · 18 bytes<br>`German_Speech_Fragment_3F` |
| `$40` | Worlord<br>`@ $8FA1` · 8 bytes<br>`SPK_Worlord` | Worlord<br>`@ $C73F` · 8 bytes<br>`German_Speech_Fragment_40` |
| `$41` | Worlord (padded)<br>`@ $8FAA` · 10 bytes<br>`SPK_Worlord_Padded` | Worlord (padded)<br>`@ $C748` · 10 bytes<br>`German_Speech_Fragment_41` |
| `$42` | Be forewarned! You approach the Pit<br>`@ $92E0` · 34 bytes<br>`SPK_Be_Forewarned_You_Approach_The_Pit` | Sei gewarnt, Worlord, du näherst dich dem Verlies<br>`@ $CB65` · 52 bytes<br>`German_Speech_Fragment_42` |
| `$43` | Your path leads directly to the Pit<br>`@ $9303` · 34 bytes<br>`SPK_Your_Path_Leads_Directly_To_The_Pit` | Dein Weg führt direkt ins Verlies<br>`@ $CB9A` · 33 bytes<br>`German_Speech_Fragment_43` |
| `$44` | Deeper, ever deeper into<br>`@ $9326` · 22 bytes<br>`SPK_Deeper_Ever_Deeper_Into` | Tiefer, immer tiefer in die Labyrinthe von Wor<br>`@ $CBBC` · 43 bytes<br>`German_Speech_Fragment_44` |
| `$45` | Beware! You are in the Worlord dungeons<br>`@ $933D` · 33 bytes<br>`SPK_Beware_You_Are_In_The_Worlord_Dungeons` | Pass auf! Du bist in den Höhlen von Wor<br>`@ $CBE8` · 41 bytes<br>`German_Speech_Fragment_45` |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master<br>`@ $935F` · 47 bytes<br>`SPK_Ah_You_Thought_You_Could_Hide_But_Im_The_Dungeon_Master` | Ah! Du willst dich wohl verstecken, aber ich bin der Höhlenmeister<br>`@ $CC12` · 64 bytes<br>`German_Speech_Fragment_46` |
| `$47` | Thor, Bur, Gar! Dinner's ready<br>`@ $938F` · 27 bytes<br>`SPK_Thor_Bur_Gar_Dinners_Ready` | Thor, Bur, Gar! Essen ist fertig<br>`@ $CC53` · 30 bytes<br>`German_Speech_Fragment_47` |
| `$48` | Hey! Your space boots untied<br>`@ $93AB` · 31 bytes<br>`SPK_Hey_Your_Space_Boots_Untied` | Hey! Zieh die Siebenmeilenstiefel an<br>`@ $CC72` · 38 bytes<br>`German_Speech_Fragment_48` |
| `$49` | My beasts run wild in the Worlord dungeons<br>`@ $93CB` · 44 bytes<br>`SPK_My_Beasts_Run_Wild_In_The_Worlord_Dungeons` | Meine Biester rennen wie wild durch die Höhlen des Worlords<br>`@ $CC99` · 58 bytes<br>`German_Speech_Fragment_49` |
| `$4A` | Now your only chance is your dance<br>`@ $93F8` · 28 bytes<br>`SPK_Now_Your_Only_Chance_Is_Your_Dance` | Dir bleibt keine andre Wahl: tanze oder leide Qual<br>`@ $CCD4` · 53 bytes<br>`German_Speech_Fragment_4A` |
| `$4B` | Are you fit to survive the Pit<br>`@ $9415` · 36 bytes<br>`SPK_Are_You_Fit_To_Survive_The_Pit` | Nun musst du dein Bestes geben, sonst wirst du nicht überleben<br>`@ $CD0A` · 64 bytes<br>`German_Speech_Fragment_4B` |
| `$4C` | Oops! I must have forgotten the walls<br>`@ $943A` · 31 bytes<br>`SPK_Oops_I_Must_Have_Forgotten_The_Walls` | Hoppla! Ich habe die Wände vergessen<br>`@ $CD4B` · 32 bytes<br>`German_Speech_Fragment_4C` |
| `$4D` | Where are you going to hide now<br>`@ $945A` · 27 bytes<br>`SPK_Where_Are_You_Going_To_Hide_Now` | Wo willst du dich verstecken?<br>`@ $CD6C` · 32 bytes<br>`German_Speech_Fragment_4D` |
| `$4E` | You're in<br>`@ $8BB6` · 10 bytes<br>`SPK_Youre_In` | Du bist in den<br>`@ $C25B` · 16 bytes<br>`German_Speech_Fragment_4E` |
| `$4F` | — | **NULL / unused pointer**<br>No speech record |
| `$50` | — | von Wor<br>`@ $C279` · 10 bytes<br>`German_Speech_Fragment_50`<br>**German-only fragment** |
| `$51` | — | von Wor versauern<br>`@ $C574` · 19 bytes<br>`German_Speech_Fragment_51`<br>**German-only fragment** |
| `$52` | — | hat dich gegrillt<br>`@ $CA5C` · 18 bytes<br>`German_Speech_Fragment_52`<br>**German-only fragment** |
| `$53` | — | bedankt sich<br>`@ $C7F6` · 13 bytes<br>`German_Speech_Fragment_53`<br>**German-only fragment** |

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
