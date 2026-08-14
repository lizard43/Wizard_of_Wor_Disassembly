# Wizard of Wor speech map

This document maps the English speech used by Wizard of Wor. It covers the resident Astrocade/SC-01 fragment data, the 80 phrase records, and the runtime rules that join them.

## Speech path

Game code requests a phrase ID from `$00-$4F`. The phrase record supplies one to four fragment IDs. Each fragment pointer selects a length-prefixed record of encoded SC-01 commands, which the interrupt-driven speech service writes through I/O port `$17`.

The Language DIP switch selects the source of both tables independently:

| Resource | English mode | Foreign mode |
| --- | --- | --- |
| Fragment-pointer table | Resident game ROM | Pointer read from X11 `$C000` |
| Phrase table | Resident game ROM | Pointer read from X11 `$C002` |

Phrase headers are `$81-$84`; the low seven bits give the number of fragment IDs that follow. Fragment records begin with a payload count. Bits 0-5 select the SC-01 phoneme, while bits 6-7 retain the game's stateful inflection/control state. They must remain intact in ROM builds.

The encoded ROM bytes are the reconstruction authority. A six-bit SC-01 audition/player stream may be derived with `encoded_byte & $3F`, but that derived stream cannot be used to regenerate an X11 or resident speech record because it has discarded the upper-bit state.

When `Dungeon_Class != 0`, the runtime substitutes fragment `$09 -> $40` and `$37 -> $41`, changing “Worrior” to “Worlord” without duplicating phrase records.

## English fragments

The resident English pointer table contains 79 records, IDs `$00-$4E`. Payload counts exclude the leading length byte.

| ID | English fragment | Address | Bytes | Source label | Notes |
| ---: | --- | ---: | ---: | --- | --- |
| `$00` | Kill Worluk for double score | `$8B66` | 29 | `SPK_Kill_Worluk_For_Double_Score` |  |
| `$01` | If you get too powerful, I'll take care of you myself | `$8B84` | 49 | `SPK_F01_If_Too_Powerful` |  |
| `$02` | The dungeons of Wor | `$8BC1` | 20 | `SPK_The_Dungeons_Of_Wor` |  |
| `$03` | I am | `$8BD6` | 8 | `SPK_I_Am` |  |
| `$04` | The Wizard of Wor | `$8BDF` | 17 | `SPK_The_Wizard_Of_Wor` |  |
| `$05` | One bite from my pretties, and you'll explode | `$8BF1` | 43 | `SPK_F05_One_Bite_Pretties` |  |
| `$06` | My creatures are radioactive | `$8C1D` | 28 | `SPK_My_Creatures_Are_Radioactive` |  |
| `$07` | Worluk will escape through the door | `$8C3A` | 30 | `SPK_Worluk_Will_Escape_Through_The_Door` |  |
| `$08` | Watch the radar | `$8D3F` | 14 | `SPK_Watch_The_Radar` |  |
| `$09` | Worrior | `$8D4E` | 6 | `SPK_Worrior` | Runtime rank substitution may replace this with the Worlord form |
| `$0A` | Hey, insert coin | `$8E77` | 19 | `SPK_Hey_Insert_Coin` |  |
| `$0B` | Find me | `$8E8B` | 10 | `SPK_Find_Me` |  |
| `$0C` | I'm out of sight | `$8E96` | 18 | `SPK_Im_Out_Of_Spite` | Legacy source label retains `Spite`; documentation uses the spoken line “sight” |
| `$0D` | Get ready | `$8EA9` | 8 | `SPK_Get_Ready` |  |
| `$0E` | You'd better hope you don't find me | `$8EB2` | 32 | `SPK_Youd_Better_Hope_You_Dont_Find_Me` |  |
| `$0F` | Another coin for my treasure chest | `$8ED3` | 30 | `SPK_Another_Coin_For_My_Treasure_Chest` |  |
| `$10` | Ha ha ha ha | `$8EF2` | 10 | `SPK_Ha_Ha_Ha_Ha` |  |
| `$11` | Ah good! My pets were getting hungry | `$8EFD` | 34 | `SPK_Ah_Good_My_Pets_Were_Getting_Hungry` |  |
| `$12` | You'll get the Arena | `$8F20` | 20 | `SPK_Youll_Get_The_Arena` |  |
| `$13` | Another worrior for my babies to devour | `$8F41` | 35 | `SPK_F13_Worrior_For_Babies` |  |
| `$14` | Keep going and you will find me | `$8F65` | 29 | `SPK_Keep_Going_And_You_Will_Find_Me` |  |
| `$15` | A few more dungeons and you'll be a | `$8F83` | 29 | `SPK_A_Few_More_Dungeons_And_Youll_Be_A` |  |
| `$16` | Come back for more with | `$8FB5` | 18 | `SPK_Come_Back_For_More_With` |  |
| `$17` | The dungeons of Wor await your return | `$8FC8` | 39 | `SPK_F17_Dungeons_Await_Return` |  |
| `$18` | Deep in the caverns of Wor, you will meet me | `$8FF0` | 43 | `SPK_F18_Deep_Caverns_Meet_Me` |  |
| `$19` | thanks you | `$901C` | 14 | `SPK_Thanks_You` |  |
| `$1A` | Now you get the heavyweights | `$8D55` | 29 | `SPK_Now_You_Get_The_Heavyweights` |  |
| `$1B` | Garwor, go after them | `$8D29` | 21 | `SPK_Garwor_Go_After_Them` |  |
| `$1C` | If you try any harder, you'll only meet with doom | `$8D8A` | 42 | `SPK_F1C_Try_Harder_Meet_Doom` |  |
| `$1D` | Burwor, Garwor, and Thorwor will do you in | `$8DB5` | 39 | `SPK_F1D_Bur_Gar_Thor_Do_You_In` |  |
| `$1E` | My worlings are very very hungry | `$8DDD` | 34 | `SPK_My_Worlings_Are_Very_Very_Hungry` |  |
| `$1F` | My magic is stronger than your weapons | `$8E00` | 35 | `SPK_F1F_Magic_Stronger_Weapons` |  |
| `$20` | While you developed science, we developed magic | `$8E4B` | 43 | `SPK_F20_Science_Vs_Magic` |  |
| `$21` | Your bones will lie in the dungeons of Wor | `$8E24` | 38 | `SPK_F21_Bones_In_Dungeons` |  |
| `$22` | You won't have a chance for your dance | `$8C59` | 30 | `SPK_F22_No_Chance_For_Dance` |  |
| `$23` | Remember, I'm the Wizard, not you | `$8C78` | 31 | `SPK_Remember_Im_The_Wizard_Not_You` |  |
| `$24` | If you can't beat the rest, then you'll never get the best | `$8C98` | 44 | `SPK_F24_Cant_Beat_Rest` |  |
| `$25` | If you destroy my babies, I'll pop you in the oven | `$8CC5` | 49 | `SPK_F25_Destroy_My_Babies` |  |
| `$26` | Now I'm getting mad | `$8CF7` | 21 | `SPK_Now_Im_Getting_Mad` |  |
| `$27` | You'll never leave Wor alive | `$8D0D` | 27 | `SPK_Youll_Never_Leave_Wor_Alive` |  |
| `$28` | Garwor and Thorwor become invisible | `$917E` | 34 | `SPK_Garwor_And_Thorwor_Become_Invisible` |  |
| `$29` | You know you can do better | `$902B` | 24 | `SPK_You_Know_You_Can_Do_Better` |  |
| `$2A` | Hurry back, I can't wait to do it again | `$9044` | 38 | `SPK_F2A_Hurry_Back` |  |
| `$2B` | You can start anew, but for now you're through | `$906B` | 39 | `SPK_F2B_Start_Anew_Youre_Through` |  |
| `$2C` | He he he ho ho ho ha ha ha ha, that was fun | `$9093` | 34 | `SPK_F2C_He_Ho_Ha_That_Was_Fun` |  |
| `$2D` | Welcome to my world of Wor | `$90B6` | 25 | `SPK_Welcome_To_My_World_Of_Wor` |  |
| `$2E` | So you've come to score in the world of Wor | `$90D0` | 33 | `SPK_F2E_Come_To_Score` |  |
| `$2F` | You're off to see the Wizard, the magical Wizard of Wor | `$90F2` | 44 | `SPK_F2F_Off_To_See_Wizard` |  |
| `$30` | Burwor hasn't eaten anyone in months | `$911F` | 32 | `SPK_Burwor_Hasnt_Eaten_Anyone_In_Months` |  |
| `$31` | My babies breathe fire | `$9140` | 22 | `SPK_My_Babies_Breathe_Fire` |  |
| `$32` | I'll fry you with my lightning bolts | `$9157` | 38 | `SPK_Ill_Fry_You_With_My_Lightning_Bolts` |  |
| `$33` | Thorwor is red, mean, and hungry for space food | `$91A1` | 44 | `SPK_F33_Thorwor_Red_Hungry` |  |
| `$34` | Worrior fear, I draw near, each time I appear | `$91CE` | 40 | `SPK_F34_Worrior_Fear` |  |
| `$35` | You're asking for trouble | `$8D73` | 22 | `SPK_Youre_Asking_For_Trouble` |  |
| `$36` | Ha ha ha ha (padded) | `$8F35` | 11 | `SPK_Ha_Ha_Ha_Ha_Padded` |  |
| `$37` | Worrior (padded) | `$91F7` | 7 | `SPK_Worrior_Padded` | Runtime rank substitution may replace this with the Worlord form |
| `$38` | You've just been fried by | `$91FF` | 23 | `SPK_Youve_Just_Been_Fried_By` |  |
| `$39` | Bite the bolt | `$9217` | 15 | `SPK_Bite_The_Bolt` |  |
| `$3A` | Wasn't that lightning bolt delicious | `$9227` | 29 | `SPK_Wasnt_That_Lightning_Bolt_Delicious` |  |
| `$3B` | And my teleporting spell can be even faster | `$9245` | 42 | `SPK_F3B_Teleport_Spell_Faster` |  |
| `$3C` | Now you know the taste of my magic | `$9270` | 35 | `SPK_Now_You_Know_The_Taste_Of_My_Magic` |  |
| `$3D` | Maybe you'll see me again | `$9294` | 22 | `SPK_Maybe_Youll_See_Me_Again` |  |
| `$3E` | Your explosion was music to my ears | `$92AB` | 35 | `SPK_Your_Explosion_Was_Music_To_My_Ears` |  |
| `$3F` | I'll say it again | `$92CF` | 16 | `SPK_Ill_Say_It_Again` |  |
| `$40` | Worlord | `$8FA1` | 8 | `SPK_Worlord` |  |
| `$41` | Worlord (padded) | `$8FAA` | 10 | `SPK_Worlord_Padded` |  |
| `$42` | Be forewarned! You approach the Pit | `$92E0` | 34 | `SPK_Be_Forewarned_You_Approach_The_Pit` |  |
| `$43` | Your path leads directly to the Pit | `$9303` | 34 | `SPK_Your_Path_Leads_Directly_To_The_Pit` |  |
| `$44` | Deeper, ever deeper into | `$9326` | 22 | `SPK_Deeper_Ever_Deeper_Into` |  |
| `$45` | Beware! You are in the Worlord dungeons | `$933D` | 33 | `SPK_F45_Worlord_Dungeons` |  |
| `$46` | Ah! You thought you could hide, but I'm the dungeon master | `$935F` | 47 | `SPK_F46_Dungeon_Master` |  |
| `$47` | Thor, Bur, Gar! Dinner's ready | `$938F` | 27 | `SPK_Thor_Bur_Gar_Dinners_Ready` |  |
| `$48` | Hey! Your space boots untied | `$93AB` | 31 | `SPK_Hey_Your_Space_Boots_Untied` |  |
| `$49` | My beasts run wild in the Worlord dungeons | `$93CB` | 44 | `SPK_F49_Beasts_Wild_Worlord` |  |
| `$4A` | Now your only chance is your dance | `$93F8` | 28 | `SPK_Now_Your_Only_Chance_Is_Your_Dance` |  |
| `$4B` | Are you fit to survive the Pit | `$9415` | 36 | `SPK_Are_You_Fit_To_Survive_The_Pit` |  |
| `$4C` | Oops! I must have forgotten the walls | `$943A` | 31 | `SPK_Oops_I_Must_Have_Forgotten_The_Walls` |  |
| `$4D` | Where are you going to hide now | `$945A` | 27 | `SPK_Where_Are_You_Going_To_Hide_Now` |  |
| `$4E` | You're in | `$8BB6` | 10 | `SPK_Youre_In` |  |

## English phrases

The resident phrase table contains 80 records, IDs `$00-$4F`. Duplicate lines and the alternation between the padded and unpadded laugh or rank fragments are part of the original table.

| Phrase ID | Fragment composition | Resulting English phrase | Notes |
| ---: | --- | --- | --- |
| `$00` | `$0A` | Hey, insert coin |  |
| `$01` | `$0B` + `$04` | Find me, the Wizard of Wor |  |
| `$02` | `$0A` | Hey, insert coin |  |
| `$03` | `$0C` + `$10` | I'm out of sight. Ha ha ha ha! |  |
| `$04` | `$0A` | Hey, insert coin |  |
| `$05` | `$0B` + `$04` | Find me, the Wizard of Wor |  |
| `$06` | `$0A` | Hey, insert coin |  |
| `$07` | `$0C` + `$10` | I'm out of sight. Ha ha ha ha! |  |
| `$08` | `$0D` + `$09` | Get ready, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$09` | `$0E` + `$04` | You'd better hope you don't find me, the Wizard of Wor |  |
| `$0A` | `$0F` | Another coin for my treasure chest |  |
| `$0B` | `$11` + `$10` | Ah good! My pets were getting hungry. Ha ha ha ha! |  |
| `$0C` | `$1E` + `$36` | My worlings are very very hungry. Ha ha ha ha! |  |
| `$0D` | `$2D` | Welcome to my world of Wor |  |
| `$0E` | `$2E` + `$10` | So you've come to score in the world of Wor. Ha ha ha ha! |  |
| `$0F` | `$2F` + `$10` | You're off to see the Wizard, the magical Wizard of Wor. Ha ha ha ha! |  |
| `$10` | `$00` | Kill Worluk for double score |  |
| `$11` | `$4E` + `$02` | You're in the dungeons of Wor |  |
| `$12` | `$03` + `$04` | I am the Wizard of Wor |  |
| `$13` | `$05` + `$10` | One bite from my pretties, and you'll explode. Ha ha ha ha! |  |
| `$14` | `$06` | My creatures are radioactive |  |
| `$15` | `$07` | Worluk will escape through the door |  |
| `$16` | `$08` + `$37` | Watch the radar, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$17` | `$33` + `$36` | Thorwor is red, mean, and hungry for space food. Ha ha ha ha! |  |
| `$18` | `$23` | Remember, I'm the Wizard, not you |  |
| `$19` | `$24` + `$36` | If you can't beat the rest, then you'll never get the best. Ha ha ha ha! |  |
| `$1A` | `$27` + `$36` | You'll never leave Wor alive. Ha ha ha ha! |  |
| `$1B` | `$25` + `$36` | If you destroy my babies, I'll pop you in the oven. Ha ha ha ha! |  |
| `$1C` | `$30` + `$36` | Burwor hasn't eaten anyone in months. Ha ha ha ha! |  |
| `$1D` | `$31` + `$09` | My babies breathe fire, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$1E` | `$32` | I'll fry you with my lightning bolts |  |
| `$1F` | `$1D` | Burwor, Garwor, and Thorwor will do you in |  |
| `$20` | `$12` + `$36` | You'll get the Arena. Ha ha ha ha! |  |
| `$21` | `$13` | Another Worrior for my babies to devour |  |
| `$22` | `$14` | Keep going and you will find me |  |
| `$23` | `$15` + `$40` | A few more dungeons and you'll be a Worlord |  |
| `$24` | `$37` + `$26` | Worrior, now I'm getting mad | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$25` | `$34` + `$10` | Worrior fear, I draw near, each time I appear. Ha ha ha ha! |  |
| `$26` | `$09` + `$22` + `$10` | Worrior, you won't have a chance for your dance. Ha ha ha ha! | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$27` | `$35` + `$37` | You're asking for trouble, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$28` | `$1A` + `$36` | Now you get the heavyweights. Ha ha ha ha! |  |
| `$29` | `$1B` | Garwor, go after them! |  |
| `$2A` | `$1C` + `$36` | If you try any harder, you'll only meet with doom. Ha ha ha ha! |  |
| `$2B` | `$01` + `$36` | If you get too powerful, I'll take care of you myself. Ha ha ha ha! |  |
| `$2C` | `$1F` + `$09` | My magic is stronger than your weapons, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$2D` | `$09` + `$20` | Worrior, while you developed science, we developed magic | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$2E` | `$21` + `$36` | Your bones will lie in the dungeons of Wor. Ha ha ha ha! |  |
| `$2F` | `$28` + `$36` | Garwor and Thorwor become invisible. Ha ha ha ha! |  |
| `$30` | `$16` + `$04` + `$10` | Come back for more with the Wizard of Wor. Ha ha ha ha! |  |
| `$31` | `$17` + `$37` | The dungeons of Wor await your return, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$32` | `$18` + `$37` | Deep in the caverns of Wor, you will meet me, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$33` | `$04` + `$19` | The Wizard of Wor thanks you |  |
| `$34` | `$29` + `$37` | You know you can do better, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$35` | `$2A` | Hurry back, I can't wait to do it again |  |
| `$36` | `$2B` + `$36` | You can start anew, but for now you're through. Ha ha ha ha! |  |
| `$37` | `$2C` | He he he, ho ho ho, ha ha ha ha! That was fun |  |
| `$38` | `$38` + `$04` + `$10` | You've just been fried by the Wizard of Wor. Ha ha ha ha! |  |
| `$39` | `$39` + `$37` + `$36` | Bite the bolt, Worrior. Ha ha ha ha! | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$3A` | `$3A` + `$10` | Wasn't that lightning bolt delicious? Ha ha ha ha! |  |
| `$3B` | `$3B` + `$36` | And my teleporting spell can be even faster. Ha ha ha ha! |  |
| `$3C` | `$3C` + `$37` | Now you know the taste of my magic, Worrior | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$3D` | `$09` + `$3D` | Worrior, maybe you'll see me again | Worrior fragment changes to Worlord when `Dungeon_Class != 0` |
| `$3E` | `$3E` + `$10` | Your explosion was music to my ears. Ha ha ha ha! |  |
| `$3F` | `$3F` + `$34` + `$10` | I'll say it again: Worrior fear, I draw near, each time I appear. Ha ha ha ha! |  |
| `$40` | `$41` + `$42` + `$36` | Worlord, be forewarned! You approach the Pit. Ha ha ha ha! |  |
| `$41` | `$41` + `$43` + `$36` | Worlord, your path leads directly to the Pit. Ha ha ha ha! |  |
| `$42` | `$44` + `$02` + `$36` | Deeper, ever deeper into the dungeons of Wor. Ha ha ha ha! |  |
| `$43` | `$45` | Beware! You are in the Worlord dungeons |  |
| `$44` | `$46` + `$36` | Ah! You thought you could hide, but I'm the dungeon master. Ha ha ha ha! |  |
| `$45` | `$47` + `$36` | Thor, Bur, Gar! Dinner's ready. Ha ha ha ha! |  |
| `$46` | `$48` + `$10` | Hey! Your space boot's untied. Ha ha ha ha! |  |
| `$47` | `$49` + `$36` | My beasts run wild in the Worlord dungeons. Ha ha ha ha! |  |
| `$48` | `$4A` + `$10` | Now your only chance is your dance. Ha ha ha ha! |  |
| `$49` | `$4B` + `$10` | Are you fit to survive the Pit? Ha ha ha ha! |  |
| `$4A` | `$4C` + `$10` | Oops! I must have forgotten the walls. Ha ha ha ha! |  |
| `$4B` | `$4D` + `$36` | Where are you going to hide now? Ha ha ha ha! |  |
| `$4C` | `$4A` + `$10` | Now your only chance is your dance. Ha ha ha ha! |  |
| `$4D` | `$4B` + `$36` | Are you fit to survive the Pit? Ha ha ha ha! |  |
| `$4E` | `$4C` + `$10` | Oops! I must have forgotten the walls. Ha ha ha ha! |  |
| `$4F` | `$4D` + `$36` | Where are you going to hide now? Ha ha ha ha! |  |

## Implementation notes

- Phrase IDs and fragment IDs are separate namespaces.
- Foreign X11 images may add helper fragments above `$4E`, but the resident English table ends at `$4E`.
- The fragment queue stores two-byte record pointers; the playback service sends the stop command only after the queue is empty.
- Fragment `$0C` is documented by its spoken result, “I'm out of sight.” The legacy symbol `SPK_Im_Out_Of_Spite` is retained as source provenance and should not be silently renamed in code.
