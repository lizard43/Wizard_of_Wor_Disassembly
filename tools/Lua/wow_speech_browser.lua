-- wow_speech_browser.lua
-- Wizard of Wor native Z80 speech browser for MAME 0.289+
--
-- Lua is the loader, catalog-page provider, WAV owner, and read-only tracer.
-- After one PC redirect to $D400, injected Z80 owns the frame loop, interrupt
-- service, inputs, selection, rendering, Play All, and speech requests.
--
-- Controls:
--   LEFT / RIGHT  toggle FRAGMENTS / PHRASES
--   UP / DOWN     move selection
--   FIRE          play selected entry
--   1P START      exit MAME through the Lua shell
--   2P START      play all / stop after the current entry

local VERSION = "3.0.3-20260816-0809"
local BUILD_FILE = "wow_speech_browser.lua"
local DEBUG_TRACE = false

local N = {
  CPU_TAG = ":maincpu",
  COINPORT = 0x10,
  P2PORT = 0x11,
  P1PORT = 0x12,
  SETTINGS = 0x13,
  LANGUAGE_MASK = 0x08,
  SOUND_SERVICE_ENTRY = 0x8000,
  SOUND_RESET_ENTRY = 0x8006,
  SPEECH_REQUEST_ENTRY = 0x8009,
  QUEUE_SPEECH_REQUEST = 0x827D,
  PRINT_STRING_COLOR = 0x03B5,
  EN_FRAGMENT_TABLE = 0x9476,
  EN_PHRASE_TABLE = 0x9514,
  PHRASE_COUNT = 80,
  X11_FRAGMENT_PTR = 0xC000,
  X11_PHRASE_PTR = 0xC002,
  X11_TEXT0 = 0xC00D,
  SOUND_REQUEST_1 = 0xD240,
  SOUND_REQUEST_4 = 0xD243,
  SPEECH_ACTIVE = 0xD245,
  QUEUE_WRITE = 0xD2D2,
  QUEUE_READ = 0xD2D4,
  SPEECH_POINTER = 0xD2CE,
  SPEECH_REMAINING = 0xD2D0,
  SPEECH_INFLECTION = 0xD2D1,
  PAGE_HEADER = 0xD050,
  PAGE_ROWS = 0xD078,
  PAGE_FOOTER_1 = 0xD190,
  PAGE_FOOTER_2 = 0xD1B8,
  PAGE_FOOTER_3 = 0xD1E0,
  PAGE_ENTRY_META = 0xD208,
  SIGNATURE = 0xD380,
  PAGE_SEQUENCE = 0xD384,
  PAGE_ACK = 0xD385,
  PAGE_DRAWN = 0xD386,
  PANE = 0xD387,
  SELECTED_FRAGMENT = 0xD388,
  SELECTED_PHRASE = 0xD389,
  FIRST_FRAGMENT = 0xD38A,
  FIRST_PHRASE = 0xD38B,
  COUNT_FRAGMENT = 0xD38C,
  COUNT_PHRASE = 0xD38D,
  PLAY_ALL = 0xD390,
  EVENT_SEQUENCE = 0xD392,
  EVENT_STATE = 0xD393,
  EVENT_KIND = 0xD395,
  EVENT_ID = 0xD396,
  EVENT_ADDRESS = 0xD397,
  HEARTBEAT = 0xD399,
  EXIT_REQUEST = 0xD39A,
  RENDER_COUNT = 0xD39C,
  COMMAND = 0xD39E,
  CAPTURE_FLAGS = 0xD39F,
  STALL_RECOVERIES = 0xD3A8,
  PAYLOAD = 0xD400,
  PAYLOAD_END = 0xD7FC,
  STACK_TOP = 0x8000,
  TAKEOVER_DELAY_SEC = 2.0,
  UI_ROWS = 7,
  WAV_POSTROLL_SEC = 0.15,
}

-- SC-01 phoneme names. Low six bits select the phoneme; bits 6-7 carry
-- inflection/control state.
local SC01_NAMES = {
  [0x00]="EH3", [0x01]="EH2", [0x02]="EH1", [0x03]="PA0",
  [0x04]="DT",  [0x05]="A2",  [0x06]="A1",  [0x07]="ZH",
  [0x08]="AH2", [0x09]="I3",  [0x0A]="I2",  [0x0B]="I1",
  [0x0C]="M",   [0x0D]="N",   [0x0E]="B",   [0x0F]="V",
  [0x10]="CH",  [0x11]="SH",  [0x12]="Z",   [0x13]="AW1",
  [0x14]="NG",  [0x15]="AH1", [0x16]="OO1", [0x17]="OO",
  [0x18]="L",   [0x19]="K",   [0x1A]="J",   [0x1B]="H",
  [0x1C]="G",   [0x1D]="F",   [0x1E]="D",   [0x1F]="S",
  [0x20]="A",   [0x21]="AY",  [0x22]="Y1",  [0x23]="UH3",
  [0x24]="AH",  [0x25]="P",   [0x26]="O",   [0x27]="I",
  [0x28]="U",   [0x29]="Y",   [0x2A]="T",   [0x2B]="R",
  [0x2C]="E",   [0x2D]="W",   [0x2E]="AE",  [0x2F]="AE1",
  [0x30]="AW2", [0x31]="UH2", [0x32]="UH1", [0x33]="UH",
  [0x34]="O2",  [0x35]="O1",  [0x36]="IU",  [0x37]="U1",
  [0x38]="THV", [0x39]="TH",  [0x3A]="ER",  [0x3B]="EH",
  [0x3C]="E1",  [0x3D]="AW",  [0x3E]="PA1", [0x3F]="STOP",
}

local DESC_EN = {
  [0x00] = "Kill Worluk for double score",
  [0x01] = "If you get too powerful, I'll take care of you myself",
  [0x02] = "The dungeons of Wor",
  [0x03] = "I am",
  [0x04] = "The Wizard of Wor",
  [0x05] = "One bite from my pretties, and you'll explode",
  [0x06] = "My creatures are radioactive",
  [0x07] = "Worluk will escape through the door",
  [0x08] = "Watch the radar",
  [0x09] = "Worrior",
  [0x0A] = "Hey, insert coin",
  [0x0B] = "Find me",
  [0x0C] = "I'm out of sight",
  [0x0D] = "Get ready",
  [0x0E] = "You'd better hope you don't find me",
  [0x0F] = "Another coin for my treasure chest",
  [0x10] = "Ha ha ha ha",
  [0x11] = "Ah good! My pets were getting hungry",
  [0x12] = "You'll get the Arena",
  [0x13] = "Another worrior for my babies to devour",
  [0x14] = "Keep going and you will find me",
  [0x15] = "A few more dungeons and you'll be a",
  [0x16] = "Come back for more with",
  [0x17] = "The dungeons of Wor await your return",
  [0x18] = "Deep in the caverns of Wor, you will meet me",
  [0x19] = "thanks you",
  [0x1A] = "Now you get the heavyweights",
  [0x1B] = "Garwor, go after them",
  [0x1C] = "If you try any harder, you'll only meet with doom",
  [0x1D] = "Burwor, Garwor, and Thorwor will do you in",
  [0x1E] = "My worlings are very very hungry",
  [0x1F] = "My magic is stronger than your weapons",
  [0x20] = "While you developed science, we developed magic",
  [0x21] = "Your bones will lie in the dungeons of Wor",
  [0x22] = "You won't have a chance for your dance",
  [0x23] = "Remember, I'm the Wizard, not you",
  [0x24] = "If you can't beat the rest, then you'll never get the best",
  [0x25] = "If you destroy my babies, I'll pop you in the oven",
  [0x26] = "Now I'm getting mad",
  [0x27] = "You'll never leave Wor alive",
  [0x28] = "Garwor and Thorwor become invisible",
  [0x29] = "You know you can do better",
  [0x2A] = "Hurry back, I can't wait to do it again",
  [0x2B] = "You can start anew, but for now you're through",
  [0x2C] = "He he he ho ho ho ha ha ha ha, that was fun",
  [0x2D] = "Welcome to my world of Wor",
  [0x2E] = "So you've come to score in the world of Wor",
  [0x2F] = "You're off to see the Wizard, the magical Wizard of Wor",
  [0x30] = "Burwor hasn't eaten anyone in months",
  [0x31] = "My babies breathe fire",
  [0x32] = "I'll fry you with my lightning bolts",
  [0x33] = "Thorwor is red, mean, and hungry for space food",
  [0x34] = "Worrior fear, I draw near, each time I appear",
  [0x35] = "You're asking for trouble",
  [0x36] = "Ha ha ha ha (padded)",
  [0x37] = "Worrior (padded)",
  [0x38] = "You've just been fried by",
  [0x39] = "Bite the bolt",
  [0x3A] = "Wasn't that lightning bolt delicious",
  [0x3B] = "And my teleporting spell can be even faster",
  [0x3C] = "Now you know the taste of my magic",
  [0x3D] = "Maybe you'll see me again",
  [0x3E] = "Your explosion was music to my ears",
  [0x3F] = "I'll say it again",
  [0x40] = "Worlord",
  [0x41] = "Worlord (padded)",
  [0x42] = "Be forewarned! You approach the Pit",
  [0x43] = "Your path leads directly to the Pit",
  [0x44] = "Deeper, ever deeper into",
  [0x45] = "Beware! You are in the Worlord dungeons",
  [0x46] = "Ah! You thought you could hide, but I'm the dungeon master",
  [0x47] = "Thor, Bur, Gar! Dinner's ready",
  [0x48] = "Hey! Your space boots untied",
  [0x49] = "My beasts run wild in the Worlord dungeons",
  [0x4A] = "Now your only chance is your dance",
  [0x4B] = "Are you fit to survive the Pit",
  [0x4C] = "Oops! I must have forgotten the walls",
  [0x4D] = "Where are you going to hide now",
  [0x4E] = "You're in",
}

local DESC_DE = {
  [0x00] = "Vernichte Worluk für doppelte Punktzahl",
  [0x01] = "Wenn du zu mächtig wirst, greife ich selbst ein",
  [0x02] = "Labyrinth",
  [0x03] = "Ich bin der",
  [0x04] = "Wizard von Wor",
  [0x05] = "Ein Biss von meinen Schönen und du explodierst",
  [0x06] = "Meine Kreaturen sind radioaktiv",
  [0x07] = "Worluk wird durch die Tür entkommen",
  [0x08] = "Beobachte deinen Radarschirm",
  [0x09] = "Worrior",
  [0x0A] = "Hey, wirf Geld ein",
  [0x0B] = "Such mich, den",
  [0x0C] = "Ich bin unsichtbar",
  [0x0D] = "Sei bereit",
  [0x0E] = "Gnade dir Gott, wenn du den Wizard von Wor findest",
  [0x0F] = "Eine weitere Münze für meine Brieftasche",
  [0x10] = "Ha ha ha ha",
  [0x11] = "Sehr gut! Meine Kleinen sind sehr hungrig",
  [0x12] = "Nun wirst du in die Arena geworfen",
  [0x13] = "Noch einen Worrior, den meine Süßen verschlingen werden",
  [0x14] = "Mach weiter und du findest mich",
  [0x15] = "Noch ein paar Labyrinthe und du bist ein",
  [0x16] = "Spiel das Spiel noch einmal; dann wirst du ...",
  [0x17] = "Die Labyrinthe von Wor warten auf deine Rückkehr",
  [0x18] = "Drunten in den Höhlen von Wor wirst du mich treffen",
  [0x19] = "Der",
  [0x1A] = "Jetzt kommen die Schwergewichte",
  [0x1B] = "Garwor, pack sie!",
  [0x1C] = "Wenn du's noch mal versuchst, hauen wir dich in die Pfanne",
  [0x1D] = "Burwor, Garwor und Thorwor werden dich einmachen",
  [0x1E] = "Meine Schützlinge sind sehr gefräßig",
  [0x1F] = "Meine Magiekraft ist stärker als deine Waffen",
  [0x20] = "Du stehst auf Wissenschaft, ich glaube an Magie",
  [0x21] = "Deine Knochen werden in den",
  [0x22] = "Du bleibst nicht ganz nach diesem wilden Tanz",
  [0x23] = "Denk dran, ich bin der Wizard, nicht du",
  [0x24] = "Wenn du den Rest schlägst, dann nenn dich der Beste",
  [0x25] = "Wenn du meine Babys anfasst, werde ich dich im Ofen braten",
  [0x26] = "Langsam werde ich böse",
  [0x27] = "Du wirst Wor nicht lebendig verlassen",
  [0x28] = "Garwor und Thorwor, macht euch unsichtbar",
  [0x29] = "Du weißt genau, dass du es besser kannst",
  [0x2A] = "Komm zurück, Rache ist süß",
  [0x2B] = "Ich greife an mit Gebrüll, schmeiße dich jetzt auf den Müll",
  [0x2C] = "He he he, ho ho ho, ha ha ha ha! Das macht Spaß",
  [0x2D] = "Willkommen in der Welt von Wor",
  [0x2E] = "Mach dem Wizard mal was vor, sammle Punkte in der Welt von Wor",
  [0x2F] = "Gleich siehst du den Wizard, den magischen Wizard von Wor",
  [0x30] = "Seit Monaten hat Burwor niemanden vernascht",
  [0x31] = "Meine Kinder speien Feuer",
  [0x32] = "Mit meiner Lichtkanone verbrenne ich dich",
  [0x33] = "Thorwor ist blutrot, gemein und hungrig auf Kraftnahrung",
  [0x34] = "Sieh genau her, alter Späher, denn ich komme immer näher",
  [0x35] = "Du willst wohl Ärger",
  [0x36] = "Ha ha ha ha (padded)",
  [0x37] = "Worrior (padded)",
  [0x38] = "Der",
  [0x39] = "Das Strahlenschwert kitzelt",
  [0x3A] = "Wie schmeckt die Strahlenkanone?",
  [0x3B] = "Mein Teletransport wird noch schneller",
  [0x3C] = "Nun kennst du den Geschmack meines Zaubers",
  [0x3D] = "Eines Tages treffen wir uns wieder",
  [0x3E] = "Deine Explosion ist Musik für meine Ohren",
  [0x3F] = "Ich sag's noch mal",
  [0x40] = "Worlord",
  [0x41] = "Worlord (padded)",
  [0x42] = "Sei gewarnt, Worlord, du näherst dich dem Verlies",
  [0x43] = "Dein Weg führt direkt ins Verlies",
  [0x44] = "Tiefer, immer tiefer in die Labyrinthe von Wor",
  [0x45] = "Pass auf! Du bist in den Höhlen von Wor",
  [0x46] = "Ah! Du willst dich wohl verstecken, aber ich bin der Höhlenmeister",
  [0x47] = "Thor, Bur, Gar! Essen ist fertig",
  [0x48] = "Hey! Zieh die Siebenmeilenstiefel an",
  [0x49] = "Meine Biester rennen wie wild durch die Höhlen des Worlords",
  [0x4A] = "Dir bleibt keine andre Wahl: tanze oder leide Qual",
  [0x4B] = "Nun musst du dein Bestes geben, sonst wirst du nicht überleben",
  [0x4C] = "Hoppla! Ich habe die Wände vergessen",
  [0x4D] = "Wo willst du dich verstecken?",
  [0x4E] = "Du bist in den",
  [0x50] = "von Wor",
  [0x51] = "von Wor versauern",
  [0x52] = "hat dich gegrillt",
  [0x53] = "bedankt sich",
}

local DESC_KL = {
  [0x00] = "Worluk yIHoH. cha'logh mIvwa' DaSuq.",
  [0x01] = "bIHoSghajqu'chugh, qamevmoH jIH.",
  [0x02] = "Wor bIghHa'mey.",
  [0x03] = "jIH.",
  [0x04] = "Wor 'IDnar pIn.",
  [0x05] = "DuchopDI' ghumeywIj, bIjor.",
  [0x06] = "Qob Ha'DIbaHmeywIj.",
  [0x07] = "lojmIt vegh Worluk 'ej nargh.",
  [0x08] = "HotlhwI' yIbej.",
  [0x09] = "SuvwI'.",
  [0x0A] = "Huch yIlan.",
  [0x0B] = "HISam.",
  [0x0C] = "jISo'.",
  [0x0D] = "yIghuH.",
  [0x0E] = "HISambe' 'e' yItul.",
  [0x0F] = "latlh Huch vIHev.",
  [0x10] = "Ha ha ha ha!",
  [0x11] = "maj! ghumeywIj ghungqu'.",
  [0x12] = "SuvmeH DaqDaq bIghoS.",
  [0x13] = "latlh SuvwI' luSop ghumeywIj.",
  [0x14] = "yItaH; HISam.",
  [0x15] = "latlh bIghHa'mey puS Daju'DI',",
  [0x16] = "latlh Qu'vaD yIchegh.",
  [0x17] = "Wor bIghHa'meyDaq bIchegh.",
  [0x18] = "Wor DISmeyDaq HISam.",
  [0x19] = "Dutlho'.",
  [0x1A] = "SuvwI'pu' HoSghaj DaSuv.",
  [0x1B] = "Garwor, yIHIv!",
  [0x1C] = "latlh DanIDchugh, bIHegh.",
  [0x1D] = "Burwor Garwor Thorwor je DuHoH.",
  [0x1E] = "SuvwI'HommeywIj ghungqu'.",
  [0x1F] = "'IDnarwIj HoS law' nuHmeylIj HoS puS.",
  [0x20] = "QeD Daghoj; 'IDnar wIghoj.",
  [0x21] = "Wor bIghHa'meyDaq HomDu'lIj tu'lu'.",
  [0x22] = "Qapla' Daghajbe'.",
  [0x23] = "yIqaw: Wor 'IDnar pIn jIH; SoHbe'.",
  [0x24] = "Hoch DanIvbe'chugh, bIluj.",
  [0x25] = "ghumeywIj DaQaw'chugh, qulDaq qameQmoH.",
  [0x26] = "jIQeHchoH.",
  [0x27] = "Worvo' bIyIntaHvIS bImejbe'.",
  [0x28] = "Garwor Thorwor je tISo'moH!",
  [0x29] = "bIHoSghajqu'laH.",
  [0x2A] = "nom yIchegh; qaloS.",
  [0x2B] = "Qu' Dachuqa'laH; DaH bIluj.",
  [0x2C] = "He he he, ho ho ho, ha ha ha ha! maj.",
  [0x2D] = "Wor qo'Daq yI'el.",
  [0x2E] = "Wor qo'Daq mIvwa' DaSuq.",
  [0x2F] = "Wor 'IDnar pIn Daghom.",
  [0x30] = "qaStaHvIS 'op jar pagh Sop Burwor.",
  [0x31] = "qul lutlhuH ghumeywIj.",
  [0x32] = "nISwI' tIHmeywIjmo' bImeQ.",
  [0x33] = "Doq Thorwor, QeH 'ej ghung.",
  [0x34] = "SuvwI', qaSumchoH.",
  [0x35] = "Seng DaneH.",
  [0x36] = "Ha ha ha ha! (padded)",
  [0x37] = "SuvwI' (padded)",
  [0x38] = "DuQIHpu'.",
  [0x39] = "nISwI' yIchop.",
  [0x3A] = "nISwI' tIH DaparHa''a'?",
  [0x3B] = "nom jolwI'wIj Qap.",
  [0x3C] = "DaH 'IDnarwIj DaSov.",
  [0x3D] = "chaq maghomqa'.",
  [0x3E] = "QoQ 'oH jorlIj'e'.",
  [0x3F] = "vIjatlhqa'.",
  [0x40] = "SuvwI' joH",
  [0x41] = "SuvwI' joH (padded)",
  [0x42] = "yIghuH! QemjIq DaghoS.",
  [0x43] = "QemjIqDaq He'lIj ghoS.",
  [0x44] = "Wor bIghHa'mey qoDDaq yIghoS.",
  [0x45] = "yIghuH! SuvwI' joH bIghHa'meyDaq SoH.",
  [0x46] = "DaSo' 'e' DaQub; bIghHa' pIn jIH.",
  [0x47] = "Thor, Bur, Gar! SopmeH yIghuH.",
  [0x48] = "DaSlIj yIrar!",
  [0x49] = "SuvwI' joH bIghHa'meyDaq qet Ha'DIbaHmeywIj.",
  [0x4A] = "DaH yImI'; latlh DuH Daghajbe'.",
  [0x4B] = "QemjIqDaq bIyInlaH'a'?",
  [0x4C] = "toH! reDmey vIlIjpu'.",
  [0x4D] = "nuqDaq DaSo'?",
  [0x4E] = "SoH.",
  [0x50] = "SoH.",
  [0x51] = "Wor bIghHa'meyDaq.",
  [0x52] = "yIghomqa'.",
  [0x53] = "Dutlho'",
}


-- Exact zmac output from wow_speech_browser_native.asm.
local PAYLOAD_HEX = [[
f3 31 00 80 af 21 00 40 11 01 40 01 ff 3f 77 ed
b0 21 9d d4 22 ca d3 3e d3 ed 47 ed 5e 3e ca d3
0d 3e a8 d3 0f 3e 08 d3 0e af 32 45 d2 32 d0 d2
32 d1 d2 67 6f 22 d2 d2 21 be d2 22 d4 d2 cd 06
80 3e 01 32 44 d2 32 03 d3 af 32 8e d3 32 8f d3
32 90 d3 32 91 d3 32 93 d3 32 9a d3 32 99 d3 32
9c d3 32 9e d3 32 50 d3 32 a0 d3 32 a1 d3 32 a2
d3 32 a3 d3 32 a4 d3 32 a5 d3 32 a6 d3 32 a7 d3
32 a8 d3 3d 32 86 d3 fb 76 cd ee d7 cd 29 d7 cd
ac d5 cd c2 d4 cd db d6 cd d2 d5 18 ea f5 c5 d5
e5 dd e5 fd e5 08 f5 d9 c5 d5 e5 cd 00 80 21 99
d3 34 e1 d1 c1 d9 f1 08 fd e1 dd e1 e1 d1 c1 f1
fb c9 db 12 2f e6 3f 47 db 11 2f e6 3f b0 47 32
a2 d3 3a 8e d3 2f a0 4f 32 a3 d3 78 32 8e d3 db
10 2f e6 60 47 3a 8f d3 2f a0 57 78 32 8f d3 cb
6a c4 db d7 3a a4 d3 b7 c0 cb 72 c4 77 d7 3a 90
d3 b7 c0 3a a3 d3 e6 0c c4 4b d5 cd 17 d5 3a a3
d3 e6 30 c4 89 d6 c9 3a a2 d3 e6 03 28 25 fe 03
28 21 47 3a a0 d3 b8 20 09 21 a1 d3 35 c0 36 04
18 09 78 32 a0 d3 3e 0f 32 a1 d3 cb 40 c2 71 d5
c3 62 d5 af 32 a0 d3 32 a1 d3 c9 3a 87 d3 ee 01
32 87 d3 c3 a7 d5 dd 21 88 d3 3a 87 d3 b7 c8 dd
23 c9 cd 56 d5 dd 7e 00 3c dd be 04 38 17 af 18
14 cd 56 d5 dd 7e 00 b7 28 07 fe ff 28 03 3d 18
04 dd 7e 04 3d dd 77 00 4f dd 7e 02 47 79 b8 38
0f 90 fe 07 da f3 d5 79 d6 06 dd 77 02 c3 a7 d5
79 dd 77 02 c3 a7 d5 21 84 d3 34 c9 3a 9e d3 b7
c8 47 af 32 9e d3 78 fe 03 ca db d7 05 20 08 3a
90 d3 b7 c0 c3 77 d7 10 08 3a 90 d3 b7 c8 c3 77
d7 c9 3a 85 d3 47 3a 84 d3 b8 c0 3a 86 d3 b8 c8
78 32 86 d3 cd f3 d5 3a 91 d3 b7 c8 af 32 91 d3
c3 89 d6 3a 85 d3 47 3a 84 d3 b8 c0 f3 21 50 d0
11 00 00 06 28 3e 04 cd b5 03 21 78 d0 11 00 0a
3e 07 32 9b d3 06 28 3e 0c cd b5 03 1e 00 7a c6
05 57 3a 9b d3 3d 32 9b d3 20 ea 21 90 d1 11 00
32 06 28 3e 08 cd b5 03 21 b8 d1 11 00 37 06 28
3e 08 cd b5 03 21 e0 d1 11 00 3c 06 28 3e 08 cd
b5 03 21 9c d3 34 cd 56 d5 dd 7e 00 fe ff c8 dd
96 02 fe 07 d0 4f 87 87 81 c6 0a 57 1e 00 21 78
d6 06 01 3e 08 c3 b5 03 61 3a 45 d2 b7 c0 2a d2
d2 ed 5b d4 d2 b7 ed 52 c9 3a 93 d3 fe 01 c8 fe
02 c8 cd 79 d6 c0 cd 56 d5 dd 7e 00 fe ff c8 dd
96 02 fe 07 d0 5f 16 00 6f 26 00 29 19 11 08 d2
19 7e 32 96 d3 23 5e 23 56 ed 53 97 d3 3a 87 d3
32 95 d3 21 92 d3 34 3a 9f d3 e6 01 3e 02 28 02
3e 0c 32 94 d3 3e 01 32 93 d3 c9 3a 93 d3 fe 01
c0 21 94 d3 7e b7 28 02 35 c9 cd 79 d6 c0 3a 95
d3 b7 28 08 3a 96 d3 cd 09 80 18 1c 2a 97 d3 11
be d2 7d 12 13 7c 12 13 ed 53 d2 d2 11 be d2 ed
53 d4 d2 3e 01 32 45 d2 2a ce d2 22 a5 d3 3e 78
32 a7 d3 3e 02 32 93 d3 c9 3a 93 d3 fe 02 c0 cd
79 d6 28 04 cd 9d d7 c0 3e 03 32 93 d3 3a 90 d3
b7 c8 cd 56 d5 dd 7e 00 3c dd be 04 30 22 dd 77
00 4f dd 7e 02 47 79 90 fe 07 38 0e 79 d6 06 dd
77 02 3e 01 32 91 d3 c3 a7 d5 cd f3 d5 c3 89 d6
af 32 90 d3 c3 a7 d5 3a 90 d3 b7 20 16 3c 32 90
d3 cd 56 d5 af dd 77 00 dd 77 02 3e 01 32 91 d3
c3 a7 d5 af 32 90 d3 32 91 d3 c3 a7 d5 2a ce d2
ed 5b a5 d3 b7 ed 52 28 0d 2a ce d2 22 a5 d3 3e
78 32 a7 d3 b7 c9 21 a7 d3 35 7e b7 c0 cd c6 d7
21 a8 d3 34 af c9 af 32 45 d2 32 d0 d2 67 6f 22
d2 d2 cd 06 80 3e 01 32 44 d2 c9 cd c6 d7 af 32
90 d3 32 91 d3 32 93 d3 3e 06 32 a4 d3 c9 21 a4
d3 7e b7 c8 35 c0 3e 01 32 9a d3 c9
]]
local PAYLOAD_SIZE = 1020
local PAYLOAD_FNV1A = 0x9D86CCDE

local machine = manager.machine
local cpu = machine.devices[N.CPU_TAG]
if not cpu then error("[WOW SPEECH] main CPU not found at " .. N.CPU_TAG) end
local program = cpu.spaces and cpu.spaces["program"] or nil
local io = cpu.spaces and cpu.spaces["io"] or nil
if not program then error("[WOW SPEECH] main CPU program space is unavailable") end
if not io then error("[WOW SPEECH] main CPU I/O space is unavailable") end

local S = {
  enabled = true,
  takeover = false,
  takeover_time = nil,
  catalog = { fragment = {}, phrase = {} },
  fragment_by_address = {},
  language = nil,
  frame_subscription = nil,
  stop_subscription = nil,
  shortcuts = {},
  last_page_sequence = nil,
  last_event_sequence = nil,
  last_event_state = 0,
  event = nil,
  wav_enabled = false,
  wav_active = false,
  wav_filename = nil,
  wav_stop_at = nil,
  pending_wav_event = nil,
  last_heartbeat = nil,
  last_stall_recoveries = nil,
  heartbeat_time = nil,
}

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(v) return string.format("$%02X", v & 0xFF) end
local function hex4(v) return string.format("$%04X", v & 0xFFFF) end

local function read16(addr)
  local lo = program:read_u8(addr)
  local hi = program:read_u8((addr + 1) & 0xFFFF)
  return lo | (hi << 8)
end

local function write16(addr, value)
  program:write_u8(addr, value & 0xFF)
  program:write_u8(addr + 1, (value >> 8) & 0xFF)
end

local function machine_seconds()
  local ok, value = pcall(function() return machine.time:as_double() end)
  return ok and value or 0
end

local function payload_bytes()
  local out = {}
  for pair in PAYLOAD_HEX:gmatch("%x%x") do
    out[#out + 1] = tonumber(pair, 16)
  end
  return out
end

local function fnv1a(bytes)
  local value = 0x811C9DC5
  for _, b in ipairs(bytes) do
    value = ((value ~ b) * 0x01000193) & 0xFFFFFFFF
  end
  return value
end

local PAYLOAD = payload_bytes()
if #PAYLOAD ~= PAYLOAD_SIZE then
  error(string.format("[WOW SPEECH] embedded payload size mismatch: %d != %d", #PAYLOAD, PAYLOAD_SIZE))
end
if fnv1a(PAYLOAD) ~= PAYLOAD_FNV1A then
  error("[WOW SPEECH] embedded payload FNV-1a mismatch")
end

local function validate_program()
  local checks = {
    {N.SOUND_SERVICE_ENTRY, 0xC3, "sound service JP"},
    {N.SOUND_RESET_ENTRY, 0xC3, "sound reset JP"},
    {N.SPEECH_REQUEST_ENTRY, 0xC3, "speech request JP"},
  }
  for _, check in ipairs(checks) do
    if program:read_u8(check[1]) ~= check[2] then
      return false, string.format("%s signature differs at %s", check[3], hex4(check[1]))
    end
  end
  if read16(N.SOUND_SERVICE_ENTRY + 1) ~= 0x84F2 then
    return false, "sound service entry no longer targets $84F2"
  end
  if read16(N.SOUND_RESET_ENTRY + 1) ~= 0x8316 then
    return false, "sound reset entry no longer targets $8316"
  end
  if read16(N.SPEECH_REQUEST_ENTRY + 1) ~= N.QUEUE_SPEECH_REQUEST then
    return false, "speech request entry no longer targets $827D"
  end

  local qsig = {0xFE, 0x50, 0x30, 0x73, 0x21, 0x14, 0x95, 0x3C}
  for i, expected in ipairs(qsig) do
    if program:read_u8(N.QUEUE_SPEECH_REQUEST + i - 1) ~= expected then
      return false, string.format("Queue_Speech_Request signature differs at %s",
        hex4(N.QUEUE_SPEECH_REQUEST + i - 1))
    end
  end
  if read16(N.EN_FRAGMENT_TABLE) ~= 0x8B66 then
    return false, "English fragment table signature differs at $9476"
  end
  local psig = {0x0E, 0xFF, 0xC3}
  for i, expected in ipairs(psig) do
    if program:read_u8(N.PRINT_STRING_COLOR + i - 1) ~= expected then
      return false, string.format("printstr entry signature differs at %s",
        hex4(N.PRINT_STRING_COLOR + i - 1))
    end
  end
  return true
end

local function x11_info()
  local fp = read16(N.X11_FRAGMENT_PTR)
  local pp = read16(N.X11_PHRASE_PTR)
  local valid = fp >= 0xC000 and fp <= 0xCFFF and
                pp >= 0xC000 and pp <= 0xCFFF and pp > fp
  if not valid then
    return {present=false, fragment_table=fp, phrase_table=pp, fragment_count=0}
  end

  local count = (pp - fp) // 2
  if count < 1 or count > 128 or fp + count * 2 ~= pp then
    return {present=false, fragment_table=fp, phrase_table=pp, fragment_count=0}
  end

  local n = program:read_u8(N.X11_TEXT0)
  local chars = {}
  for i = 1, math.min(n, 16) do
    chars[#chars + 1] = string.char(program:read_u8(N.X11_TEXT0 + i))
  end
  local first = table.concat(chars)
  local variant, desc = "X11", DESC_EN
  if first:find("@MUENZ", 1, true) then
    variant, desc = "German", DESC_DE
  elseif first:find("HUCH", 1, true) or first:find("Huch", 1, true) then
    variant, desc = "Klingon", DESC_KL
  end
  return {
    present=true, fragment_table=fp, phrase_table=pp,
    fragment_count=count, variant=variant, desc=desc, first_text=first
  }
end

local function active_language()
  local raw = io:read_u8(N.SETTINGS)
  local foreign = (raw & N.LANGUAGE_MASK) == 0
  local x11 = x11_info()
  if foreign then
    if not x11.present then
      return {valid=false, key="foreign-invalid", name="Foreign DIP / invalid X11"}
    end
    return {
      valid=true, key="x11:" .. x11.variant, name=x11.variant,
      fragment_table=x11.fragment_table, phrase_table=x11.phrase_table,
      fragment_count=x11.fragment_count, desc=x11.desc
    }
  end
  return {
    valid=true, key="english", name="English",
    fragment_table=N.EN_FRAGMENT_TABLE, phrase_table=N.EN_PHRASE_TABLE,
    fragment_count=(N.EN_PHRASE_TABLE - N.EN_FRAGMENT_TABLE) // 2,
    desc=DESC_EN
  }
end

local function fragment_desc(lang, id)
  return lang.desc[id] or DESC_EN[id] or string.format("Fragment %02X", id)
end

local function build_catalog()
  local lang = active_language()
  if not lang.valid then return false, lang.name end

  local fragments = {}
  local by_address = {}
  for id = 0, lang.fragment_count - 1 do
    local address = read16(lang.fragment_table + id * 2)
    if address ~= 0 then
      local entry = {
        kind="fragment", id=id, address=address,
        description=fragment_desc(lang, id), playable=true
      }
      fragments[#fragments + 1] = entry
      by_address[address] = by_address[address] or {}
      by_address[address][id] = entry
    end
  end
  table.sort(fragments, function(a, b)
    if a.address ~= b.address then return a.address < b.address end
    return a.id < b.id
  end)

  local phrases = {}
  local p = lang.phrase_table
  for id = 0, N.PHRASE_COUNT - 1 do
    local record = p
    local marker = program:read_u8(p)
    if marker < 0x80 then
      return false, string.format("invalid phrase marker %s at %s", hex2(marker), hex4(p))
    end
    local count = marker & 0x7F
    local ids, parts = {}, {}
    for j = 1, count do
      local fid = program:read_u8(p + j)
      ids[#ids + 1] = fid
      parts[#parts + 1] = fragment_desc(lang, fid)
    end
    phrases[#phrases + 1] = {
      kind="phrase", id=id, address=record, fragments=ids,
      description=count == 0 and "Suppressed" or table.concat(parts, " + "),
      playable=count > 0
    }
    p = p + count + 1
  end

  S.language = lang
  S.catalog.fragment = fragments
  S.catalog.phrase = phrases
  S.fragment_by_address = by_address
  return true
end

local function transliterate_for_wow(text)
  local s = tostring(text or "")
  local repl = {
    ["Ä"]="AE", ["Ö"]="OE", ["Ü"]="UE", ["ẞ"]="SS",
    ["ä"]="AE", ["ö"]="OE", ["ü"]="UE", ["ß"]="SS",
  }
  for from, to in pairs(repl) do s = s:gsub(from, to) end
  s = s:upper()

  local out = {}
  for i = 1, #s do
    local ch = s:sub(i, i)
    local b = ch:byte()
    if (b >= 0x30 and b <= 0x39) or (b >= 0x41 and b <= 0x5A) then
      out[#out + 1] = ch
    elseif ch == " " then
      out[#out + 1] = "@"
    elseif ch == "-" then
      out[#out + 1] = "_"
    elseif ch == "'" then
      out[#out + 1] = string.char(0x60)
    else
      out[#out + 1] = "@"
    end
  end
  return table.concat(out)
end

local function fixed_native_text(text, width)
  local s = transliterate_for_wow(text)
  if #s > width then s = s:sub(1, width) end
  if #s < width then s = s .. string.rep("@", width - #s) end
  return s
end

local function centered_native_row(text)
  local s = transliterate_for_wow(text)
  if #s > 40 then s = s:sub(1, 40) end
  local left = math.max(0, (40 - #s) // 2)
  return (string.rep("@", left) .. s .. string.rep("@", 40)):sub(1, 40)
end

local function write_native_string(address, text, width)
  -- Callers supply CHRTBL-ready text; preserve @, _, and the apostrophe glyph.
  local s = tostring(text or "")
  if #s > width then s = s:sub(1, width) end
  if #s < width then s = s .. string.rep("@", width - #s) end
  for i = 1, width do program:write_u8(address + i - 1, s:byte(i)) end
end

local function page_state()
  local pane = program:read_u8(N.PANE) == 0 and "fragment" or "phrase"
  local first_addr = pane == "fragment" and N.FIRST_FRAGMENT or N.FIRST_PHRASE
  local selected_addr = pane == "fragment" and N.SELECTED_FRAGMENT or N.SELECTED_PHRASE
  return pane, program:read_u8(first_addr), program:read_u8(selected_addr)
end

local function write_page_buffer()
  local pane, first = page_state()
  local list = S.catalog[pane]
  local pane_name = pane == "fragment" and "FRAGMENTS" or "PHRASES"
  local header = centered_native_row(S.language.name .. "  " .. pane_name)
  local tag = "V303"
  header = header:sub(1, 40 - #tag) .. tag
  write_native_string(N.PAGE_HEADER, header, 40)

  for row = 0, N.UI_ROWS - 1 do
    local entry = list[first + row + 1]
    local row_addr = N.PAGE_ROWS + row * 40
    local meta_addr = N.PAGE_ENTRY_META + row * 3
    if entry then
      local line = "@" .. string.format("%04X@", entry.address & 0xFFFF) ..
                   fixed_native_text(entry.description, 34)
      write_native_string(row_addr, line, 40)
      program:write_u8(meta_addr, entry.id)
      write16(meta_addr + 1, entry.address)
    else
      write_native_string(row_addr, "", 40)
      program:write_u8(meta_addr, 0xFF)
      write16(meta_addr + 1, 0)
    end
  end

  write_native_string(N.PAGE_FOOTER_1,
    centered_native_row("UP DOWN SELECT - FIRE PLAY SPEECH"), 40)
  write_native_string(N.PAGE_FOOTER_2,
    centered_native_row("LEFT RIGHT - CHANGE SPEECH TYPE"), 40)
  local footer3 = program:read_u8(N.PLAY_ALL) ~= 0 and
    "1P EXIT - 2P STOP AFTER CURRENT" or "1P EXIT - 2P PLAY ALL"
  write_native_string(N.PAGE_FOOTER_3, centered_native_row(footer3), 40)
end

local function initialize_abi()
  local signature = {string.byte("W"), string.byte("S"), string.byte("N"), string.byte("2")}
  for i, b in ipairs(signature) do program:write_u8(N.SIGNATURE + i - 1, b) end
  for address = N.PAGE_SEQUENCE, N.CAPTURE_FLAGS do program:write_u8(address, 0) end
  program:write_u8(N.SELECTED_FRAGMENT, 0xFF)
  program:write_u8(N.SELECTED_PHRASE, 0xFF)
  program:write_u8(N.COUNT_FRAGMENT, #S.catalog.fragment)
  program:write_u8(N.COUNT_PHRASE, #S.catalog.phrase)
  program:write_u8(N.CAPTURE_FLAGS, S.wav_enabled and 1 or 0)
  program:write_u8(N.STALL_RECOVERIES, 0)
  write_page_buffer()
  program:write_u8(N.PAGE_ACK, 0)
  program:write_u8(N.PAGE_DRAWN, 0xFF)
end

local function install_payload()
  if #PAYLOAD ~= N.PAYLOAD_END - N.PAYLOAD then
    return false, string.format("payload span mismatch: %d bytes", #PAYLOAD)
  end
  for i, b in ipairs(PAYLOAD) do program:write_u8(N.PAYLOAD + i - 1, b) end
  for i, b in ipairs(PAYLOAD) do
    if program:read_u8(N.PAYLOAD + i - 1) ~= b then
      return false, string.format("payload verify failed at %s", hex4(N.PAYLOAD + i - 1))
    end
  end
  return true
end

local function speech_idle()
  return program:read_u8(N.SPEECH_ACTIVE) == 0 and
         read16(N.QUEUE_WRITE) == read16(N.QUEUE_READ)
end

local function sound_requests_idle()
  for address = N.SOUND_REQUEST_1, N.SOUND_REQUEST_4 do
    if program:read_u8(address) ~= 0 then return false end
  end
  return true
end

local function takeover()
  if S.takeover then return true end
  local ok, why = validate_program()
  if not ok then
    printf("[WOW SPEECH] takeover refused: %s", why)
    S.enabled = false
    return false
  end
  ok, why = build_catalog()
  if not ok then
    printf("[WOW SPEECH] takeover refused: %s", why)
    S.enabled = false
    return false
  end
  if #S.catalog.fragment > 255 or #S.catalog.phrase > 255 then
    print("[WOW SPEECH] takeover refused: catalog exceeds native 8-bit ABI")
    S.enabled = false
    return false
  end

  ok, why = install_payload()
  if not ok then
    printf("[WOW SPEECH] takeover refused: %s", why)
    S.enabled = false
    return false
  end
  initialize_abi()

  -- This is the only CPU control-state handoff in the browser.
  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  if cpu.state["SP"] then cpu.state["SP"].value = N.STACK_TOP end
  cpu.state["PC"].value = N.PAYLOAD

  S.takeover = true
  S.takeover_time = machine_seconds()
  S.last_page_sequence = 0
  S.last_event_sequence = program:read_u8(N.EVENT_SEQUENCE)
  S.last_event_state = program:read_u8(N.EVENT_STATE)
  S.last_heartbeat = program:read_u8(N.HEARTBEAT)
  S.last_stall_recoveries = 0
  S.heartbeat_time = machine_seconds()

  printf("[WOW SPEECH] native takeover active; bank=%s", S.language.name)
  printf("[WOW SPEECH] catalog: %d phrases, %d fragments",
    #S.catalog.phrase, #S.catalog.fragment)
  printf("[WOW SPEECH] Z80: %s-%s (%d bytes, FNV-1a %08X)",
    hex4(N.PAYLOAD), hex4(N.PAYLOAD_END - 1), #PAYLOAD, PAYLOAD_FNV1A)
  print("[WOW SPEECH] native ownership: IM2/frame/input/UI/playback/play-all/$8000 service")
  print("[WOW SPEECH] Lua ownership: validation/page text/WAV/read-only trace/exit")
  return true
end

local function service_page_mailbox()
  local sequence = program:read_u8(N.PAGE_SEQUENCE)
  local ack = program:read_u8(N.PAGE_ACK)
  if sequence == ack then return end
  write_page_buffer()
  program:write_u8(N.PAGE_ACK, sequence) -- commit last
  S.last_page_sequence = sequence
end

local function fragment_stream(address, initial_inflection)
  local count = program:read_u8(address)
  local names, raws, commands = {}, {}, {}
  local inflection = initial_inflection & 0x80
  for i = 0, count - 1 do
    local raw = program:read_u8(address + 1 + i)
    local command = raw ~ inflection
    inflection = command & 0x80
    local name = SC01_NAMES[command & 0x3F] or string.format("P%02X", command & 0x3F)
    names[#names + 1] = name
    raws[#raws + 1] = string.format("%02X", raw)
    commands[#commands + 1] = string.format("%02X", command)
  end
  return count, table.concat(names, " "), table.concat(raws, " "),
         table.concat(commands, " "), inflection
end

local function event_entry(kind, id, address)
  if kind == "fragment" then
    local aliases = S.fragment_by_address[address]
    return (aliases and aliases[id]) or {
      kind=kind, id=id, address=address, description=fragment_desc(S.language, id)
    }
  end
  return S.catalog.phrase[id + 1] or {
    kind=kind, id=id, address=address, description=string.format("Phrase %02X", id)
  }
end

local function log_event_request(event)
  print("")
  printf("[WOW SPEECH] PLAY %s id=%s address=%s text=\"%s\"",
    event.kind:upper(), hex2(event.id), hex4(event.address), event.entry.description)

  local inflection = program:read_u8(N.SPEECH_INFLECTION) & 0x80
  if event.kind == "fragment" then
    local count, phones, raws, commands = fragment_stream(event.address, inflection)
    event.expected_end = event.address + count + 1
    event.last_pointer = event.address + 1
    event.sim_inflection = inflection
    event.seq = 0
    printf("[WOW SPEECH] PHONEMES %s", phones)
    if DEBUG_TRACE then
      printf("[WOW SPEECH DEBUG] RAW      %s", raws)
      printf("[WOW SPEECH DEBUG] COMMANDS %s", commands)
    end
  else
    local fragments = event.entry.fragments or {}
    for index, fid in ipairs(fragments) do
      local address = read16(S.language.fragment_table + fid * 2)
      printf("[WOW SPEECH]   FRAGMENT %d/%d id=%s address=%s text=\"%s\"",
        index, #fragments, hex2(fid), hex4(address), fragment_desc(S.language, fid))
      if address == 0 then
        print("[WOW SPEECH]     PHONEMES <null fragment pointer>")
      else
        local count, phones, raws, commands, next_inflection =
          fragment_stream(address, inflection)
        printf("[WOW SPEECH]     PHONEMES %s", phones)
        if DEBUG_TRACE then
          printf("[WOW SPEECH DEBUG]     length=%s RAW %s", hex2(count), raws)
          printf("[WOW SPEECH DEBUG]     COMMANDS %s", commands)
        end
        inflection = next_inflection
      end
    end
  end
end

local function wav_language_slug()
  return (S.language and S.language.name or "unknown"):lower():gsub("[^a-z0-9]+", "_")
end

local function start_event_wav(event)
  if not S.wav_enabled or S.wav_active then return false end
  local already = false
  pcall(function() already = machine.sound.recording == true end)
  if already then
    print("[WOW SPEECH] WAV not started: MAME recorder is already active")
    return false
  end
  local filename = string.format("wow_%s_%s_%04X.wav",
    wav_language_slug(), event.kind, event.address & 0xFFFF)
  local ok, started = pcall(function() return machine.sound:start_recording(filename) end)
  if not ok or not started then
    printf("[WOW SPEECH] WAV not started: %s", filename)
    return false
  end
  S.wav_active = true
  S.wav_filename = filename
  S.wav_stop_at = nil
  return true
end

local function stop_owned_wav(reason)
  if not S.wav_active then return end
  pcall(function() machine.sound:stop_recording() end)
  printf("[WOW SPEECH] WAV %s: %s", reason or "saved", S.wav_filename or "")
  S.wav_active = false
  S.wav_filename = nil
  S.wav_stop_at = nil
end

local function finish_event(event, reason)
  if not event or event.finished then return end
  event.finished = true
  local elapsed = machine_seconds() - event.announced_at
  printf("[WOW SPEECH] END %s id=%s address=%s elapsed=%.3fs%s",
    event.kind:upper(), hex2(event.id), hex4(event.address), elapsed,
    reason and (" " .. reason) or "")
  if S.wav_active then S.wav_stop_at = machine_seconds() + N.WAV_POSTROLL_SEC end
end

local function service_trace_progress(event, state)
  if not DEBUG_TRACE or not event or event.kind ~= "fragment" or state ~= 2 then return end
  local pointer = read16(N.SPEECH_POINTER)
  if not event.last_pointer or pointer <= event.last_pointer then return end
  if event.expected_end and pointer > event.expected_end then return end
  local limit = event.expected_end or pointer
  for address = event.last_pointer, math.min(pointer - 1, limit - 1) do
    local raw = program:read_u8(address)
    local command = raw ~ (event.sim_inflection or 0)
    event.sim_inflection = command & 0x80
    event.seq = (event.seq or 0) + 1
    printf("[WOW SPEECH DEBUG] #%02d ROM=%04X raw=%02X cmd=%02X phone=%s remain=%02X READY=%d",
      event.seq, address, raw, command,
      SC01_NAMES[command & 0x3F] or string.format("P%02X", command & 0x3F),
      program:read_u8(N.SPEECH_REMAINING),
      (io:read_u8(N.P1PORT) & 0x80) ~= 0 and 1 or 0)
  end
  event.last_pointer = pointer
end

local function service_event_mailbox()
  local sequence = program:read_u8(N.EVENT_SEQUENCE)
  local state = program:read_u8(N.EVENT_STATE)

  if sequence ~= S.last_event_sequence then
    if S.event and not S.event.finished then finish_event(S.event, "[next event]") end

    local kind = program:read_u8(N.EVENT_KIND) == 0 and "fragment" or "phrase"
    local id = program:read_u8(N.EVENT_ID)
    local address = read16(N.EVENT_ADDRESS)
    local event = {
      sequence=sequence, kind=kind, id=id, address=address,
      entry=event_entry(kind, id, address),
      announced_at=machine_seconds(), state=state, finished=false,
    }
    S.event = event
    S.last_event_sequence = sequence
    S.last_event_state = state
    log_event_request(event)

    if S.wav_enabled then
      if S.wav_active then
        S.pending_wav_event = event
      else
        start_event_wav(event)
      end
    end
  else
    service_trace_progress(S.event, state)
    if S.event and state == 2 and S.last_event_state ~= 2 and DEBUG_TRACE then
      printf("[WOW SPEECH DEBUG] START active=%02X remain=%02X ptr=%04X",
        program:read_u8(N.SPEECH_ACTIVE), program:read_u8(N.SPEECH_REMAINING),
        read16(N.SPEECH_POINTER))
    elseif S.event and state == 3 and S.last_event_state ~= 3 then
      finish_event(S.event)
    end
    S.last_event_state = state
  end
end

local function service_wav()
  if S.wav_active and S.wav_stop_at and machine_seconds() >= S.wav_stop_at then
    stop_owned_wav("saved")
  end
  if not S.wav_active and S.pending_wav_event then
    local event = S.pending_wav_event
    S.pending_wav_event = nil
    start_event_wav(event)
  end
end

local function set_wav_capture(value)
  if value == nil then
    S.wav_enabled = not S.wav_enabled
  elseif type(value) == "boolean" then
    S.wav_enabled = value
  elseif type(value) == "number" then
    S.wav_enabled = value ~= 0
  else
    local text = tostring(value):lower()
    if text == "on" or text == "true" or text == "1" then
      S.wav_enabled = true
    elseif text == "off" or text == "false" or text == "0" then
      S.wav_enabled = false
    else
      print("[WOW SPEECH] usage: wwav() | wwav(true) | wwav(false)")
      return S.wav_enabled
    end
  end
  if S.takeover then program:write_u8(N.CAPTURE_FLAGS, S.wav_enabled and 1 or 0) end
  printf("[WOW SPEECH] WAV capture: %s", S.wav_enabled and "ON" or "OFF")
  return S.wav_enabled
end

local function set_debug_trace(value)
  if value == nil then
    DEBUG_TRACE = not DEBUG_TRACE
  elseif type(value) == "boolean" then
    DEBUG_TRACE = value
  elseif type(value) == "number" then
    DEBUG_TRACE = value ~= 0
  else
    local text = tostring(value):lower()
    if text == "on" or text == "true" or text == "1" then
      DEBUG_TRACE = true
    elseif text == "off" or text == "false" or text == "0" then
      DEBUG_TRACE = false
    else
      print("[WOW SPEECH] usage: wtrace() | wtrace(true) | wtrace(false)")
      return DEBUG_TRACE
    end
  end
  printf("[WOW SPEECH] detailed trace: %s", DEBUG_TRACE and "ON" or "OFF")
  return DEBUG_TRACE
end

local function post_native_command(command, name)
  if not S.takeover then
    printf("[WOW SPEECH] %s: native takeover is not active", name)
    return false
  end
  if program:read_u8(N.COMMAND) ~= 0 then
    printf("[WOW SPEECH] %s: native command mailbox is busy", name)
    return false
  end
  program:write_u8(N.COMMAND, command)
  return true
end

local function print_console_commands()
  print("")
  print("[WOW SPEECH] console commands:")
  print("[WOW SPEECH]   wwav([bool])    toggle/set WAV capture")
  print("[WOW SPEECH]   wtrace([bool])  toggle/set read-only trace")
  print("[WOW SPEECH]   wall()          request native Play All")
  print("[WOW SPEECH]   wstop()         request native stop-after-current")
  print("[WOW SPEECH]   wexit()         exit MAME")
  print("[WOW SPEECH]   whelp()         show this list")
end

local function install_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = {handler=handler, previous=previous, restore=previous ~= nil}
  rawset(_G, name, handler)
end

local function install_console_shortcuts()
  install_shortcut("wwav", set_wav_capture)
  install_shortcut("wtrace", set_debug_trace)
  install_shortcut("wall", function() return post_native_command(1, "wall()") end)
  install_shortcut("wstop", function() return post_native_command(2, "wstop()") end)
  install_shortcut("wexit", function() return post_native_command(3, "wexit()") end)
  install_shortcut("whelp", print_console_commands)
end

local function restore_console_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      rawset(_G, name, shortcut.restore and shortcut.previous or nil)
    end
  end
  S.shortcuts = {}
end

local function service_heartbeat()
  local value = program:read_u8(N.HEARTBEAT)
  if value ~= S.last_heartbeat then
    S.last_heartbeat = value
    S.heartbeat_time = machine_seconds()
  elseif machine_seconds() - (S.heartbeat_time or 0) > 1.0 then
    printf("[WOW SPEECH] ERROR: native heartbeat stalled at %s", hex2(value))
    S.heartbeat_time = machine_seconds()
  end
end

local function service_stall_recovery_log()
  local value = program:read_u8(N.STALL_RECOVERIES)
  if value == S.last_stall_recoveries then return end
  S.last_stall_recoveries = value
  local event = S.event
  if event then
    printf("[WOW SPEECH] NATIVE STALL RECOVERY count=%d kind=%s id=%s address=%s",
      value, event.kind, hex2(event.id), hex4(event.address))
  else
    printf("[WOW SPEECH] NATIVE STALL RECOVERY count=%d", value)
  end
end

local function on_frame()
  if not S.enabled then return end
  if not S.takeover then
    if machine_seconds() >= N.TAKEOVER_DELAY_SEC and speech_idle() and sound_requests_idle() then
      takeover()
    end
    return
  end

  -- Lua services only the documented mailbox ABI.  It never polls controls,
  -- selects entries, writes speech state, renders by redirecting PC, or changes
  -- CPU registers after Browser_Entry.
  service_page_mailbox()
  service_event_mailbox()
  service_wav()
  service_heartbeat()
  service_stall_recovery_log()
  if program:read_u8(N.EXIT_REQUEST) ~= 0 then machine:exit() end
end

print("============================================================")
printf("[WOW SPEECH] WOW NATIVE SPEECH BROWSER %s", VERSION)
printf("[WOW SPEECH] payload: %s-%s, %d bytes, FNV-1a %08X",
  hex4(N.PAYLOAD), hex4(N.PAYLOAD_END - 1), #PAYLOAD, PAYLOAD_FNV1A)
print("[WOW SPEECH] resident paths: $8009 phrase queue; $81F8 speech queue; $8000 service")
print("[WOW SPEECH] CPU redirect after takeover: exactly once")
install_console_shortcuts()
print_console_commands()
print("============================================================")

if emu.add_machine_frame_notifier then
  S.frame_subscription = emu.add_machine_frame_notifier(on_frame)
else
  emu.register_frame_done(on_frame, "wow_speech_browser_native")
end

if emu.add_machine_stop_notifier then
  S.stop_subscription = emu.add_machine_stop_notifier(function()
    S.enabled = false
    stop_owned_wav("closed")
    restore_console_shortcuts()
  end)
end

printf("[WOW SPEECH] %s loaded from %s; waiting %.1fs for idle takeover",
  VERSION, BUILD_FILE, N.TAKEOVER_DELAY_SEC)
