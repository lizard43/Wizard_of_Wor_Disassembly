-- wow_speech_browser.lua
-- Wizard of Wor native speech browser for MAME 0.289+
--
-- Boots WoW normally, then takes over foreground execution while leaving the
-- original interrupt-driven sound and SC-01 service active. The browser uses
-- WoW's native printstr/CHRTBL renderer; no MAME overlay is used.
--
-- Controls:
--   LEFT / RIGHT  toggle FRAGMENTS / PHRASES
--   UP / DOWN     move selection
--   FIRE          play selected entry
--   1P START      exit MAME
--   2P START      play all / stop
--
-- Speech is played directly from the loaded ROM. See whelp() for console tools.

local VERSION = "2.5.5-20260814-0838"
local BUILD_FILE = "wow_speech_browser.lua"

-- Detailed trace is controlled at runtime with wtrace().
local DEBUG_TRACE = false

local C = {
  CPU_TAG = ":maincpu",

  -- Hardware I/O ports (WoW Astrocade board)
  COINPORT = 0x10,
  P2PORT = 0x11,
  P1PORT = 0x12,
  SETTINGS = 0x13,
  LANGUAGE_MASK = 0x08,       -- bit 3: 1 English, 0 X11

  -- Resident speech data/routines
  EN_FRAGMENT_TABLE = 0x9476,
  EN_PHRASE_TABLE = 0x9514,
  QUEUE_SPEECH_REQUEST = 0x827D,
  PHRASE_COUNT = 80,

  -- X11 ABI
  X11_FRAGMENT_PTR = 0xC000,
  X11_PHRASE_PTR = 0xC002,
  X11_TEXT0 = 0xC00D,

  -- WoW RAM speech state
  SOUND_REQUEST_1 = 0xD240,
  SOUND_REQUEST_4 = 0xD243,
  ATTRACT_SOUND_ENABLED = 0xD244,
  SPEECH_ACTIVE = 0xD245,
  SPEECH_QUEUE_BUFFER = 0xD2BE,
  SPEECH_QUEUE_LAST = 0xD2CC,
  SPEECH_PHONEME_POINTER = 0xD2CE,
  SPEECH_PHONEMES_REMAINING = 0xD2D0,
  SPEECH_INFLECTION_STATE = 0xD2D1,
  QUEUE_WRITE = 0xD2D2,
  QUEUE_READ = 0xD2D4,
  GAME_MODE = 0xD303,

  -- Browser work RAM used after takeover.
  IDLE_LOOP = 0xD400,
  DRAW_CODE = 0xD420,
  DRAW_DATA = 0xD600,
  CALL_STACK = 0xDFE0,

  -- Native WoW text renderer (printstr/CHRTBL through Magic RAM).
  PRINT_STRING = 0x03B3,
  PRINT_STRING_COLOR = 0x03B5,

  -- WoW 1bpp-to-2bpp expand colors using the current game palette:
  --   $04 -> color 1 (blue), $08 -> color 2 (yellow), $0C -> color 3 (red).
  XPAND_BLUE = 0x04,
  XPAND_YELLOW = 0x08,
  XPAND_RED = 0x0C,

  TAKEOVER_DELAY_SEC = 2.0,
  INPUT_INITIAL_REPEAT = 15,
  INPUT_REPEAT_RATE = 4,
  UI_ROWS = 7,
  TRACE_STALL_SEC = 1.5,
  WAV_POSTROLL_SEC = 0.15,
}

-- Z80 idle loop: EI / HALT / JP $D401. Interrupts remain active.
local IDLE_LOOP_BYTES = { 0xFB, 0x76, 0xC3, 0x01, 0xD4 }

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
  [0x0C] = "I'm out of spite",
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


local S = {
  enabled = true,
  takeover = false,
  frame_subscription = nil,
  stop_subscription = nil,
  shortcuts = {},
  catalog = { phrase = {}, fragment = {} },
  pane = "fragment",
  selection = { phrase = 0, fragment = 0 },
  window_first = { phrase = 1, fragment = 1 },
  last_language_key = nil,
  pending = nil,
  status = "WAITING FOR WOW INITIALIZATION",
  last_controls = 0,
  last_2p_start = false,
  hold_dir = 0,
  hold_frames = 0,
  injection_count = 0,
  direct_fragment_count = 0,
  trace = nil,
  wav_enabled = false,
  wav_active = false,
  wav_filename = nil,
  wav_stop_at = nil,
  wav_batch_item = false,
  batch = nil,
  takeover_time = nil,
  ui_dirty = false,
  draw_count = 0,
}

local machine = manager.machine
local cpu = machine.devices[C.CPU_TAG]
if not cpu then error("[WOW SPEECH] main CPU not found at " .. C.CPU_TAG) end
local program = cpu.spaces and cpu.spaces["program"] or nil
local io = cpu.spaces and cpu.spaces["io"] or nil
if not program then error("[WOW SPEECH] main CPU program space is unavailable") end
if not io then error("[WOW SPEECH] main CPU I/O space is unavailable") end

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(v) return string.format("$%02X", v & 0xFF) end
local function hex4(v) return string.format("$%04X", v & 0xFFFF) end

local start_play_all
local stop_play_all
local batch_finish_item
local foreground_idle
local read_2p_start

local function print_console_commands()
  print("")
  print("[WOW SPEECH] console commands:")
  print("[WOW SPEECH]   wwav()         toggle WAV capture for Fire plays")
  print("[WOW SPEECH]   wwav(true)     WAV capture ON")
  print("[WOW SPEECH]   wwav(false)    WAV capture OFF")
  print("[WOW SPEECH]   wall()         play all entries in current view")
  print("[WOW SPEECH]   wstop()        stop play-all after current item")
  print("[WOW SPEECH]   wtrace()       toggle detailed speech trace")
  print("[WOW SPEECH]   wtrace(true)   detailed trace ON")
  print("[WOW SPEECH]   wtrace(false)  detailed trace OFF")
  print("[WOW SPEECH]   wexit()        exit MAME")
  print("[WOW SPEECH]   whelp()        show this command list")
  print("")
  printf("[WOW SPEECH]   current WAV capture: %s", S.wav_enabled and "ON" or "OFF")
  printf("[WOW SPEECH]   current trace: %s", DEBUG_TRACE and "ON" or "OFF")
end

local function set_wav_capture(value)
  if value == nil then
    S.wav_enabled = not S.wav_enabled
  elseif type(value) == "boolean" then
    S.wav_enabled = value
  elseif type(value) == "number" then
    S.wav_enabled = value ~= 0
  elseif type(value) == "string" then
    local v = value:lower()
    if v == "on" or v == "true" or v == "1" then
      S.wav_enabled = true
    elseif v == "off" or v == "false" or v == "0" then
      S.wav_enabled = false
    else
      print("[WOW SPEECH] usage: wwav() | wwav(true) | wwav(false)")
      return S.wav_enabled
    end
  else
    print("[WOW SPEECH] usage: wwav() | wwav(true) | wwav(false)")
    return S.wav_enabled
  end

  printf("[WOW SPEECH] WAV capture for Fire plays: %s", S.wav_enabled and "ON" or "OFF")
  return S.wav_enabled
end

local function set_debug_trace(value)
  if value == nil then
    DEBUG_TRACE = not DEBUG_TRACE
  elseif type(value) == "boolean" then
    DEBUG_TRACE = value
  elseif type(value) == "number" then
    DEBUG_TRACE = value ~= 0
  elseif type(value) == "string" then
    local v = value:lower()
    if v == "on" or v == "true" or v == "1" then
      DEBUG_TRACE = true
    elseif v == "off" or v == "false" or v == "0" then
      DEBUG_TRACE = false
    else
      print("[WOW SPEECH] usage: wtrace() | wtrace(true) | wtrace(false)")
      return DEBUG_TRACE
    end
  else
    print("[WOW SPEECH] usage: wtrace() | wtrace(true) | wtrace(false)")
    return DEBUG_TRACE
  end

  printf("[WOW SPEECH] detailed trace: %s", DEBUG_TRACE and "ON" or "OFF")
  return DEBUG_TRACE
end

local function install_console_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = {
    handler = handler,
    previous = previous,
    restore = previous ~= nil,
  }
  rawset(_G, name, handler)
end

local function install_console_shortcuts()
  install_console_shortcut("wwav", function(value)
    return set_wav_capture(value)
  end)
  install_console_shortcut("wall", function()
    return start_play_all()
  end)
  install_console_shortcut("wstop", function()
    return stop_play_all()
  end)
  install_console_shortcut("wtrace", function(value)
    return set_debug_trace(value)
  end)
  install_console_shortcut("wexit", function()
    machine:exit()
  end)
  install_console_shortcut("whelp", function()
    print_console_commands()
  end)
end

local function restore_console_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      if shortcut.restore then
        rawset(_G, name, shortcut.previous)
      else
        rawset(_G, name, nil)
      end
    end
  end
  S.shortcuts = {}
end

local function read16(addr)
  local lo = program:read_u8(addr)
  local hi = program:read_u8((addr + 1) & 0xFFFF)
  return lo | (hi << 8)
end

local function write16(addr, value)
  program:write_u8(addr, value & 0xFF)
  program:write_u8((addr + 1) & 0xFFFF, (value >> 8) & 0xFF)
end

local function machine_seconds()
  local ok, value = pcall(function() return machine.time:as_double() end)
  if ok then return value end
  return 0
end

local function validate_program()
  local sig = { 0xFE,0x50,0x30,0x73,0x21,0x14,0x95,0x3C }
  for i = 1, #sig do
    if program:read_u8(C.QUEUE_SPEECH_REQUEST + i - 1) ~= sig[i] then
      return false, string.format("Queue_Speech_Request signature differs at %s", hex4(C.QUEUE_SPEECH_REQUEST + i - 1))
    end
  end
  if read16(C.EN_FRAGMENT_TABLE) ~= 0x8B66 then
    return false, string.format("English fragment table signature differs at %s", hex4(C.EN_FRAGMENT_TABLE))
  end
  local psig = { 0x3E, 0x0C, 0x0E, 0xFF }
  for i = 1, #psig do
    if program:read_u8(C.PRINT_STRING + i - 1) ~= psig[i] then
      return false, string.format("WoW text renderer signature differs at %s", hex4(C.PRINT_STRING + i - 1))
    end
  end
  return true, "stock WoW speech/text signatures match"
end

local function x11_info()
  local fp = read16(C.X11_FRAGMENT_PTR)
  local pp = read16(C.X11_PHRASE_PTR)
  local valid = fp >= 0xC000 and fp <= 0xCFFF and pp >= 0xC000 and pp <= 0xCFFF and pp > fp
  if not valid then
    return { present=false, fragment_table=fp, phrase_table=pp, fragment_count=0, variant="none", desc=DESC_EN }
  end

  local count = (pp - fp) // 2
  if count < 1 or count > 128 or (fp + count * 2) ~= pp then
    return { present=false, fragment_table=fp, phrase_table=pp, fragment_count=0, variant="invalid", desc=DESC_EN }
  end

  local n = program:read_u8(C.X11_TEXT0)
  local chars = {}
  for i = 1, math.min(n, 16) do chars[#chars + 1] = string.char(program:read_u8(C.X11_TEXT0 + i)) end
  local first = table.concat(chars)
  local variant, desc = "X11", DESC_EN
  if first:find("@MUENZ", 1, true) then
    variant, desc = "German", DESC_DE
  elseif first:find("HUCH", 1, true) or first:find("Huch", 1, true) then
    variant, desc = "Klingon", DESC_KL
  end

  return {
    present=true, fragment_table=fp, phrase_table=pp, fragment_count=count,
    variant=variant, first_text=first, desc=desc
  }
end

local function dip_info()
  local ok, raw = pcall(function() return io:read_u8(C.SETTINGS) end)
  if not ok then return {raw=nil, foreign=false, readable=false} end
  return {raw=raw, foreign=(raw & C.LANGUAGE_MASK) == 0, readable=true}
end

local function active_language()
  local dip = dip_info()
  local x11 = x11_info()
  if dip.readable and dip.foreign then
    if not x11.present then
      return {
        key="foreign-invalid", name="Foreign DIP / no valid X11", valid=false,
        fragment_table=x11.fragment_table, phrase_table=x11.phrase_table,
        fragment_count=0, desc=DESC_EN, dip=dip, x11=x11
      }
    end
    return {
      key="x11:" .. x11.variant, name=x11.variant .. " X11", valid=true,
      fragment_table=x11.fragment_table, phrase_table=x11.phrase_table,
      fragment_count=x11.fragment_count, desc=x11.desc, dip=dip, x11=x11
    }
  end

  return {
    key="english", name="English resident", valid=true,
    fragment_table=C.EN_FRAGMENT_TABLE, phrase_table=C.EN_PHRASE_TABLE,
    fragment_count=(C.EN_PHRASE_TABLE - C.EN_FRAGMENT_TABLE) // 2,
    desc=DESC_EN, dip=dip, x11=x11
  }
end


local function wav_language_slug()
  local lang = active_language()
  local s = tostring(lang.key or "unknown"):gsub("^x11:", ""):lower()
  s = s:gsub("[^a-z0-9]+", "_"):gsub("^_+", ""):gsub("_+$", "")
  return s ~= "" and s or "unknown"
end

local function wav_filename(entry, kind)
  return string.format("wow_%s_%s_%04X.wav",
    wav_language_slug(), kind, entry.address & 0xFFFF)
end

local function stop_owned_wav(reason)
  if not S.wav_active then return end
  pcall(function() machine.sound:stop_recording() end)
  printf("[WOW SPEECH] WAV %s: %s", reason or "saved", tostring(S.wav_filename or ""))
  S.wav_active = false
  S.wav_filename = nil
  S.wav_stop_at = nil
  S.wav_batch_item = false
end

local function start_entry_wav(entry, kind, batch_item)
  if S.wav_active then
    return false, "browser WAV recorder is still active"
  end

  local already = false
  pcall(function() already = machine.sound.recording == true end)
  if already then
    return false, "MAME sound recorder is already active"
  end

  local name = wav_filename(entry, kind)
  local ok, started = pcall(function()
    return machine.sound:start_recording(name)
  end)
  if not ok or not started then
    return false, "MAME could not start WAV " .. name
  end

  S.wav_active = true
  S.wav_filename = name
  S.wav_stop_at = nil
  S.wav_batch_item = batch_item == true
  return true
end

local function finish_entry_wav()
  if S.wav_active then
    S.wav_stop_at = machine_seconds() + C.WAV_POSTROLL_SEC
  end
end


local function fragment_desc(lang, id)
  local d = lang.desc[id]
  if d then return d end
  local fallback = DESC_EN[id]
  if fallback then return fallback .. " [semantic]" end
  return "local fragment " .. hex2(id)
end

local function build_catalog(force)
  local lang = active_language()
  if not lang.valid then
    S.catalog.phrase = {}
    S.catalog.fragment = {}
    S.last_language_key = lang.key
    return lang, false
  end
  if not force and S.last_language_key == lang.key and #S.catalog.phrase > 0 then
    return lang, true
  end

  local fragments = {}
  for id = 0, lang.fragment_count - 1 do
    local p = read16(lang.fragment_table + id * 2)
    if p ~= 0 then
      fragments[#fragments + 1] = {
        kind="fragment", id=id, address=p,
        description=fragment_desc(lang,id), playable=true
      }
    end
  end

  local phrases = {}
  local p = lang.phrase_table
  for id = 0, C.PHRASE_COUNT - 1 do
    local record = p
    local marker = program:read_u8(p)
    if marker < 0x80 then
      printf("[WOW SPEECH] invalid phrase marker %s at %s (phrase %s)", hex2(marker), hex4(p), hex2(id))
      break
    end
    local count = marker & 0x7F
    local ids, parts = {}, {}
    for j = 1, count do
      local fid = program:read_u8(p + j)
      ids[#ids + 1] = fid
      parts[#parts + 1] = fragment_desc(lang, fid)
    end
    local description = count == 0 and "suppressed" or table.concat(parts, " + ")
    phrases[#phrases + 1] = {
      kind="phrase", id=id, address=record, fragments=ids,
      description=description, playable=count > 0
    }
    p = p + 1 + count
  end

  -- Display fragments in physical ROM-address order; retain logical IDs for playback.
  table.sort(fragments, function(a, b)
    if a.address ~= b.address then return a.address < b.address end
    return a.id < b.id
  end)

  S.catalog.fragment = fragments
  S.catalog.phrase = phrases
  S.last_language_key = lang.key
  for _, kind in ipairs({"phrase","fragment"}) do
    local n = #S.catalog[kind]
    if n == 0 then
      S.selection[kind] = 0
      S.window_first[kind] = 1
    else
      if S.selection[kind] < 0 then S.selection[kind] = 0 end
      if S.selection[kind] > n then S.selection[kind] = n end
      local max_first = math.max(1, n - C.UI_ROWS + 1)
      local first = S.window_first[kind] or 1
      if first < 1 then first = 1 end
      if first > max_first then first = max_first end
      S.window_first[kind] = first
    end
  end
  return lang, true
end

local function speech_idle()
  return program:read_u8(C.SPEECH_ACTIVE) == 0 and read16(C.QUEUE_WRITE) == read16(C.QUEUE_READ)
end

local function sound_requests_idle()
  for addr = C.SOUND_REQUEST_1, C.SOUND_REQUEST_4 do
    if program:read_u8(addr) ~= 0 then return false end
  end
  return true
end

local function reset_speech_state()
  for addr = C.SPEECH_QUEUE_BUFFER, C.SPEECH_QUEUE_LAST + 1 do program:write_u8(addr, 0) end
  program:write_u8(C.SPEECH_ACTIVE, 0)
  write16(C.SPEECH_PHONEME_POINTER, 0)
  program:write_u8(C.SPEECH_PHONEMES_REMAINING, 0)
  program:write_u8(C.SPEECH_INFLECTION_STATE, 0)
  write16(C.QUEUE_WRITE, C.SPEECH_QUEUE_BUFFER)
  write16(C.QUEUE_READ, C.SPEECH_QUEUE_BUFFER)
  for addr = C.SOUND_REQUEST_1, C.SOUND_REQUEST_4 do program:write_u8(addr, 0) end
  program:write_u8(C.ATTRACT_SOUND_ENABLED, 1)
  -- Non-zero avoids the service-switch diagnostic branch in the normal sound ISR.
  program:write_u8(C.GAME_MODE, 1)
end

local function install_idle_loop()
  for i = 1, #IDLE_LOOP_BYTES do
    program:write_u8(C.IDLE_LOOP + i - 1, IDLE_LOOP_BYTES[i])
  end
  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  if cpu.state["IFF1"] then cpu.state["IFF1"].value = 1 end
  if cpu.state["IFF2"] then cpu.state["IFF2"].value = 1 end
  if cpu.state["SP"] then cpu.state["SP"].value = C.CALL_STACK end
  cpu.state["PC"].value = C.IDLE_LOOP
end

local function clear_video_ram()
  -- Clear the display once; subsequent text uses WoW's native renderer.
  for addr = 0x4000, 0x7FFF do program:write_u8(addr, 0) end
end

local function takeover(reason)
  if S.takeover then return true end
  local ok, why = validate_program()
  if not ok then
    S.status = "PROGRAM VALIDATION FAILED"
    printf("[WOW SPEECH] takeover refused: %s", why)
    return false
  end

  local lang, cat_ok = build_catalog(true)
  if not cat_ok then
    S.status = "FOREIGN DIP SELECTED - X11 INVALID"
    printf("[WOW SPEECH] takeover refused: %s", lang.name)
    return false
  end

  reset_speech_state()
  clear_video_ram()
  install_idle_loop()
  S.takeover = true
  S.takeover_time = machine_seconds()
  -- Start with no selection; first UP/DOWN chooses an entry.
  S.selection.phrase = 0
  S.selection.fragment = 0
  S.window_first.phrase = 1
  S.window_first.fragment = 1
  S.trace = nil
  S.batch = nil
  S.wav_active = false
  S.wav_filename = nil
  S.wav_stop_at = nil
  S.wav_batch_item = false
  S.last_controls = 0
  S.last_2p_start = read_2p_start()
  S.hold_dir = 0
  S.hold_frames = 0
  S.pending = nil
  S.status = "READY"
  S.ui_dirty = true
  printf("[WOW SPEECH] browser takeover active (%s); bank=%s", reason or "manual", lang.name)
  printf("[WOW SPEECH] catalog: %d phrases, %d fragments; native renderer=%s/%s", #S.catalog.phrase, #S.catalog.fragment, hex4(C.PRINT_STRING), hex4(C.PRINT_STRING_COLOR))
  print("[WOW SPEECH] controls: UP/DOWN select; LEFT/RIGHT type; FIRE play; 1P exit; 2P play all/stop")
  return true
end


local function start_fragment_address(address)
  if not S.takeover then return false, "browser has not taken over" end
  if not speech_idle() then return false, "speech busy" end

  -- Prime the fragment state normally established by Service_Speech_Queue;
  -- the native ISR performs all SC-01 output.
  local lang = active_language()
  local lo, hi
  if lang.key == "english" then
    lo, hi = 0x8000, 0xAFFF
  else
    lo, hi = 0xC000, 0xCFFF
  end
  if address < lo or address > hi then
    return false, string.format("fragment address %s outside active speech ROM", hex4(address))
  end

  local count = program:read_u8(address)
  if count == 0 then
    return false, string.format("fragment %s has zero payload length", hex4(address))
  end
  if address + count > hi then
    return false, string.format("fragment %s payload overruns active speech ROM", hex4(address))
  end

  -- Play the selected fragment directly from ROM.
  local play_record = address
  local play_count = count

  -- Keep the phrase queue empty so native end-of-fragment handling issues STOP.
  write16(C.QUEUE_WRITE, C.SPEECH_QUEUE_BUFFER)
  write16(C.QUEUE_READ, C.SPEECH_QUEUE_BUFFER)
  program:write_u8(C.SPEECH_PHONEMES_REMAINING, play_count)
  write16(C.SPEECH_PHONEME_POINTER, play_record + 1)
  -- Preserve the differential inflection state used by native fragment loading.
  program:write_u8(C.SPEECH_ACTIVE, 1)

  if S.trace and S.trace.kind == "fragment" then
    S.trace.expected_end = play_record + play_count + 1
  end

  S.direct_fragment_count = S.direct_fragment_count + 1
  return true
end

local function speech_snapshot()
  local p1 = io:read_u8(C.P1PORT)
  local pc = cpu.state["PC"] and (cpu.state["PC"].value & 0xFFFF) or 0
  return {
    active = program:read_u8(C.SPEECH_ACTIVE),
    remain = program:read_u8(C.SPEECH_PHONEMES_REMAINING),
    pointer = read16(C.SPEECH_PHONEME_POINTER),
    inflection = program:read_u8(C.SPEECH_INFLECTION_STATE),
    qwrite = read16(C.QUEUE_WRITE),
    qread = read16(C.QUEUE_READ),
    p1 = p1,
    ready = (p1 & 0x80) ~= 0,
    pc = pc,
  }
end

local function trace_state(label, st)
  st = st or speech_snapshot()
  if DEBUG_TRACE then
    printf("[WOW SPEECH DEBUG] %s active=%d remain=%02X ptr=%04X infl=%02X qW=%04X qR=%04X READY=%d P1=%02X PC=%04X",
      label, st.active, st.remain, st.pointer, st.inflection,
      st.qwrite, st.qread, st.ready and 1 or 0, st.p1, st.pc)
  end
  return st
end

local function fragment_stream(address, initial_inflection)
  local count = program:read_u8(address)
  local items, names, raws, commands = {}, {}, {}, {}
  local inf = initial_inflection & 0x80
  for i = 0, count - 1 do
    local a = address + 1 + i
    local raw = program:read_u8(a)
    local command = raw ~ inf
    inf = command & 0x80
    local phone = command & 0x3F
    local name = SC01_NAMES[phone] or string.format("P%02X", phone)
    items[#items+1] = {address=a, raw=raw, command=command, phone=phone, name=name}
    names[#names+1] = name
    raws[#raws+1] = string.format("%02X", raw)
    commands[#commands+1] = string.format("%02X", command)
  end
  return count, items, table.concat(names, " "), table.concat(raws, " "), table.concat(commands, " "), inf
end

local function resolve_fragment_address(lang, id)
  if not lang or not lang.valid then return 0 end
  if id < 0 or id >= lang.fragment_count then return 0 end
  return read16(lang.fragment_table + id * 2)
end

local function trace_request(entry, kind)
  local pre = trace_state("PRE")
  print("")
  printf("[WOW SPEECH] PLAY %s id=%s address=%s text=\"%s\"",
    kind:upper(), hex2(entry.id), hex4(entry.address), tostring(entry.description or ""))

  if kind == "fragment" then
    local count, items, phones, raws, commands = fragment_stream(entry.address, pre.inflection)
    printf("[WOW SPEECH] PHONEMES %s", phones)
    if DEBUG_TRACE then
      printf("[WOW SPEECH DEBUG] FRAGMENT length=%s payload=%s-%s",
        hex2(count), hex4(entry.address + 1), hex4(entry.address + count))
      printf("[WOW SPEECH DEBUG] RAW      %s", raws)
      printf("[WOW SPEECH DEBUG] COMMANDS %s", commands)
    end
    S.trace = {
      kind=kind, id=entry.id, address=entry.address, description=entry.description,
      start_time=machine_seconds(), last_progress_time=machine_seconds(),
      last_pointer=entry.address + 1, last_remain=count,
      sim_inflection=pre.inflection & 0x80, seq=0, stall_reported=false,
      seen_activity=false, last_phone=nil, last_transition=nil,
      expected_end=entry.address + count + 1,
    }
  else
    local lang = active_language()
    local fragments = entry.fragments or {}
    local phrase_inflection = pre.inflection & 0x80

    for n, fid in ipairs(fragments) do
      local addr = resolve_fragment_address(lang, fid)
      local desc = fragment_desc(lang, fid)

      printf("[WOW SPEECH]   FRAGMENT %d/%d id=%s address=%s text=\"%s\"",
        n, #fragments, hex2(fid), hex4(addr), tostring(desc or ""))

      if addr ~= 0 then
        local count, _, phones, raws, commands, next_inflection =
          fragment_stream(addr, phrase_inflection)
        printf("[WOW SPEECH]     PHONEMES %s", phones)

        if DEBUG_TRACE then
          printf("[WOW SPEECH DEBUG]     length=%s payload=%s-%s",
            hex2(count), hex4(addr + 1), hex4(addr + count))
          printf("[WOW SPEECH DEBUG]     RAW      %s", raws)
          printf("[WOW SPEECH DEBUG]     COMMANDS %s", commands)
        end

        phrase_inflection = next_inflection
      else
        print("[WOW SPEECH]     PHONEMES <fragment address unavailable>")
      end
    end

    S.trace = {
      kind=kind, id=entry.id, address=entry.address, description=entry.description,
      start_time=machine_seconds(), last_progress_time=machine_seconds(),
      last_pointer=pre.pointer, last_remain=pre.remain,
      sim_inflection=pre.inflection & 0x80, seq=0, stall_reported=false,
      seen_activity=false, last_phone=nil, last_transition=nil,
    }
  end
  return pre
end

local function trace_started()
  if not S.trace then return end
  local st = trace_state("START")
  S.trace.last_pointer = st.pointer
  S.trace.last_remain = st.remain
  S.trace.sim_inflection = st.inflection & 0x80
  S.trace.last_progress_time = machine_seconds()
  if st.active ~= 0 or st.remain ~= 0 or st.qwrite ~= st.qread then
    S.trace.seen_activity = true
  end
end

local function trace_progress()
  local t = S.trace
  if not t then return end
  local st = speech_snapshot()
  local now = machine_seconds()
  if st.active ~= 0 or st.remain ~= 0 or st.qwrite ~= st.qread then
    t.seen_activity = true
  end
  local progressed = (st.pointer ~= t.last_pointer) or (st.remain ~= t.last_remain)

  if t.kind == "fragment" and st.pointer > t.last_pointer and st.pointer <= (t.expected_end or st.pointer) then
    for addr = t.last_pointer, st.pointer - 1 do
      local raw = program:read_u8(addr)
      local command = raw ~ (t.sim_inflection or 0)
      t.sim_inflection = command & 0x80
      t.seq = t.seq + 1
      local phone = command & 0x3F
      local name = SC01_NAMES[phone] or string.format("P%02X", phone)
      local transition = (t.last_phone or "START") .. "->" .. name
      t.last_phone = name
      t.last_transition = transition
      if DEBUG_TRACE then
        printf("[WOW SPEECH DEBUG] #%02d ROM=%04X raw=%02X cmd=%02X phone=%02X %-4s transition=%s remain=%02X ptr=%04X infl=%02X READY=%d",
          t.seq, addr & 0xFFFF, raw, command, phone, name, transition,
          st.remain, st.pointer, st.inflection, st.ready and 1 or 0)
      end
    end
  elseif progressed and t.kind == "phrase" and DEBUG_TRACE then
    printf("[WOW SPEECH DEBUG] PROGRESS remain=%02X ptr=%04X infl=%02X READY=%d",
      st.remain, st.pointer, st.inflection, st.ready and 1 or 0)
  end

  if progressed then
    t.last_progress_time = now
    t.stall_reported = false
    t.last_pointer = st.pointer
    t.last_remain = st.remain
  end

  if t.seen_activity and st.active == 0 and st.remain == 0 and st.qwrite == st.qread then
    trace_state("END", st)
    if t.kind == "fragment" then
      printf("[WOW SPEECH] END FRAGMENT id=%s address=%s elapsed=%.3fs phonemes=%d",
        hex2(t.id), hex4(t.address), now - t.start_time, t.seq or 0)
    else
      printf("[WOW SPEECH] END PHRASE id=%s address=%s elapsed=%.3fs",
        hex2(t.id), hex4(t.address), now - t.start_time)
    end
    local batch_item = S.batch and S.batch.current_index ~= nil
    S.trace = nil
    if S.wav_active then
      finish_entry_wav()
    elseif batch_item then
      batch_finish_item()
    end
    return
  end

  if st.active ~= 0 and (now - t.last_progress_time) >= C.TRACE_STALL_SEC and not t.stall_reported then
    t.stall_reported = true
    trace_state("STALL", st)
    printf("[WOW SPEECH] STALL %.2fs: %s id=%s address=%s last_seq=%d last_source=%s last_phone=%s transition=%s READY=%d",
      now - t.last_progress_time, t.kind:upper(), hex2(t.id), hex4(t.address),
      t.seq or 0, hex4((st.pointer - 1) & 0xFFFF), tostring(t.last_phone or "none"),
      tostring(t.last_transition or "none"), st.ready and 1 or 0)
  end
end

local function call_phrase_id(id)
  if not S.takeover then return false, "browser has not taken over" end
  if not speech_idle() then return false, "speech busy" end

  -- Enter Queue_Speech_Request with a synthetic return frame; WoW resolves the
  -- active language and queues the phrase's fragment addresses.
  local sp = C.CALL_STACK
  program:write_u8(sp, (C.IDLE_LOOP + 1) & 0xFF)
  program:write_u8(sp + 1, ((C.IDLE_LOOP + 1) >> 8) & 0xFF)
  if cpu.state["SP"] then cpu.state["SP"].value = sp end
  if cpu.state["AF"] then
    local af = cpu.state["AF"].value & 0xFFFF
    cpu.state["AF"].value = ((id & 0xFF) << 8) | (af & 0x00FF)
  else
    return false, "Z80 AF register state unavailable"
  end
  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  cpu.state["PC"].value = C.QUEUE_SPEECH_REQUEST
  S.injection_count = S.injection_count + 1
  return true
end

local function current_list(kind)
  kind = kind or S.pane
  return S.catalog[kind], kind
end

local function selected_entry(kind)
  local list, actual = current_list(kind)
  local index = S.selection[actual]
  return index, list[index], actual
end

local function keep_selection_visible(kind, index)
  local list = S.catalog[kind]
  if not list or #list == 0 or not index or index < 1 then return end

  local first = S.window_first[kind] or 1
  if index < first then
    first = index
  elseif index > first + C.UI_ROWS - 1 then
    first = index - C.UI_ROWS + 1
  end

  local max_first = math.max(1, #list - C.UI_ROWS + 1)
  if first < 1 then first = 1 end
  if first > max_first then first = max_first end
  S.window_first[kind] = first
end

local function request_entry(index, kind, source)
  local list = S.catalog[kind]
  local e = list and list[index] or nil
  if not e then return false, "index out of range" end
  if e.playable == false then return false, "entry is suppressed" end
  S.selection[kind] = index
  keep_selection_visible(kind, index)
  S.pending = {index=index, kind=kind, entry=e, source=source or "manual"}
  S.status = string.format("QUEUED %s %d %s", kind:upper(), index, hex2(e.id))
  S.ui_dirty = true
  return true
end


batch_finish_item = function()
  local b = S.batch
  if not b or not b.active or not b.current_index then return end
  b.completed = b.completed + 1
  b.current_index = nil

  if b.stop_requested then
    printf("[WOW SPEECH] play-all stopped: %d/%d completed", b.completed, b.total)
    S.batch = nil
    S.ui_dirty = true
  elseif b.completed >= b.total then
    printf("[WOW SPEECH] play-all complete: %d %s entries", b.completed, b.kind)
    S.batch = nil
    S.ui_dirty = true
  end
end

local function service_wav_capture()
  if not S.wav_active or not S.wav_stop_at then return end
  if machine_seconds() < S.wav_stop_at then return end

  local was_batch = S.wav_batch_item
  local name = S.wav_filename
  pcall(function() machine.sound:stop_recording() end)
  S.wav_active = false
  S.wav_filename = nil
  S.wav_stop_at = nil
  S.wav_batch_item = false
  printf("[WOW SPEECH] WAV saved: %s", tostring(name or ""))

  if was_batch then batch_finish_item() end
end

local function service_batch()
  local b = S.batch
  if not b or not b.active then return end
  if b.stop_requested and not b.current_index then
    printf("[WOW SPEECH] play-all stopped: %d/%d completed", b.completed, b.total)
    S.batch = nil
    S.ui_dirty = true
    return
  end
  if b.current_index or S.pending or S.trace or S.wav_active then return end
  if not speech_idle() or not foreground_idle() then return end

  while b.next_index <= #S.catalog[b.kind] do
    local index = b.next_index
    b.next_index = b.next_index + 1
    local e = S.catalog[b.kind][index]
    if e and e.playable ~= false then
      b.current_index = index
      local ok, err = request_entry(index, b.kind, "batch")
      if not ok then
        printf("[WOW SPEECH] play-all error: %s", tostring(err))
        S.batch = nil
        S.ui_dirty = true
      end
      return
    end
  end

  if not b.current_index then
    printf("[WOW SPEECH] play-all complete: %d %s entries", b.completed, b.kind)
    S.batch = nil
    S.ui_dirty = true
  end
end

start_play_all = function()
  if not S.takeover then
    print("[WOW SPEECH] wall(): browser has not taken over yet")
    return false
  end
  if S.batch then
    print("[WOW SPEECH] wall(): play-all is already running")
    return false
  end
  if S.pending or S.trace or S.wav_active or not speech_idle() then
    print("[WOW SPEECH] wall(): wait for current speech/WAV to finish")
    return false
  end

  local kind = S.pane
  local total = 0
  for _, e in ipairs(S.catalog[kind]) do
    if e.playable ~= false then total = total + 1 end
  end
  if total == 0 then
    printf("[WOW SPEECH] wall(): no playable %s entries", kind)
    return false
  end

  S.batch = {
    active=true, kind=kind, next_index=1, current_index=nil,
    completed=0, total=total, stop_requested=false,
  }
  S.ui_dirty = true
  printf("[WOW SPEECH] play-all: %d %s entries; WAV capture %s", total, kind, S.wav_enabled and "ON" or "OFF")
  return true
end

stop_play_all = function()
  if not S.batch then
    print("[WOW SPEECH] wstop(): no play-all run is active")
    return false
  end

  local b = S.batch
  b.stop_requested = true

  if S.pending and S.pending.source == "batch" and not S.trace and not S.wav_active then
    S.pending = nil
    b.current_index = nil
    printf("[WOW SPEECH] play-all stopped: %d/%d completed", b.completed, b.total)
    S.batch = nil
    S.ui_dirty = true
  elseif b.current_index then
    print("[WOW SPEECH] play-all will stop after the current item")
  else
    printf("[WOW SPEECH] play-all stopped: %d/%d completed", b.completed, b.total)
    S.batch = nil
    S.ui_dirty = true
  end
  return true
end


foreground_idle = function()
  if not S.takeover or not cpu.state["PC"] then return false end
  local pc = cpu.state["PC"].value & 0xFFFF
  return pc >= C.IDLE_LOOP and pc <= (C.IDLE_LOOP + #IDLE_LOOP_BYTES - 1)
end

local function service_pending()
  if not S.pending or not S.takeover or not speech_idle() or not foreground_idle() then return end
  if S.wav_active then return end

  local p = S.pending
  local batch_item = p.source == "batch"

  if batch_item and S.batch and S.batch.stop_requested then
    S.pending = nil
    S.batch.current_index = nil
    printf("[WOW SPEECH] play-all stopped: %d/%d completed", S.batch.completed, S.batch.total)
    S.batch = nil
    S.ui_dirty = true
    return
  end
  local want_wav = S.wav_enabled

  if want_wav then
    local wav_ok, wav_err = start_entry_wav(p.entry, p.kind, batch_item)
    if not wav_ok then
      printf("[WOW SPEECH] WAV ERROR: %s", tostring(wav_err))
      if batch_item then
        printf("[WOW SPEECH] play-all aborted because WAV capture is ON but recording could not start")
        S.pending = nil
        S.batch = nil
        return
      end
    end
  end

  local ok, err
  trace_request(p.entry, p.kind)
  if p.kind == "phrase" then ok, err = call_phrase_id(p.entry.id)
  else ok, err = start_fragment_address(p.entry.address) end
  if ok then
    trace_started()
    S.status = string.format("PLAYING %s %d %s", p.kind:upper(), p.index, hex2(p.entry.id))
    S.pending = nil
  elseif err ~= "speech busy" then
    S.status = "ERROR: " .. tostring(err)
    printf("[WOW SPEECH] START ERROR: %s", tostring(err))
    S.trace = nil
    S.pending = nil
    if S.wav_active then stop_owned_wav("discarded") end
    if batch_item then S.batch = nil end
  end
end

local function move_selection(delta)
  local kind = S.pane
  local list = S.catalog[kind]
  if #list == 0 then return end
  local current = S.selection[kind] or 0
  local n
  if current == 0 then
    -- No selection at takeover. DOWN enters at the start; UP enters at the end.
    n = (delta < 0) and #list or 1
  else
    n = current + delta
    if n < 1 then n = #list
    elseif n > #list then n = 1 end
  end

  S.selection[kind] = n
  keep_selection_visible(kind, n)

  S.status = "READY"
  S.ui_dirty = true
end

local function select_pane(kind)
  if kind ~= "phrase" and kind ~= "fragment" then return end
  if S.pane == kind then return end
  S.pane = kind
  S.status = "READY"
  S.ui_dirty = true
end

local function read_controls()
  local p1 = io:read_u8(C.P1PORT)
  local p2 = io:read_u8(C.P2PORT)
  return ((~p1) | (~p2)) & 0x3F
end

local function read_1p_start()
  -- Port $10 bit 5 is the 1-player Start switch (active low).
  return ((~io:read_u8(C.COINPORT)) & 0x20) ~= 0
end

read_2p_start = function()
  -- Port $10 bit 6 is the 2-player Start switch (active low).
  return ((~io:read_u8(C.COINPORT)) & 0x40) ~= 0
end

local function process_inputs()
  if not S.takeover then return end
  local c = read_controls()
  local start2 = read_2p_start()
  local start2_pressed = start2 and not S.last_2p_start

  if S.batch then
    if start2_pressed then stop_play_all() end
    if read_1p_start() then machine:exit() end
    S.last_controls = c
    S.last_2p_start = start2
    return
  end

  if start2_pressed then start_play_all() end

  local pressed = c & (~S.last_controls) & 0x3F

  -- Either horizontal direction toggles between fragments and phrases.
  if (pressed & 0x0C) ~= 0 then
    select_pane(S.pane == "fragment" and "phrase" or "fragment")
  end

  local dir = 0
  if (c & 0x01) ~= 0 and (c & 0x02) == 0 then dir = -1
  elseif (c & 0x02) ~= 0 and (c & 0x01) == 0 then dir = 1 end

  if dir ~= 0 then
    if dir ~= S.hold_dir then
      S.hold_dir = dir
      S.hold_frames = 0
      move_selection(dir)
    else
      S.hold_frames = S.hold_frames + 1
      if S.hold_frames >= C.INPUT_INITIAL_REPEAT and ((S.hold_frames - C.INPUT_INITIAL_REPEAT) % C.INPUT_REPEAT_RATE) == 0 then
        move_selection(dir)
      end
    end
  else
    S.hold_dir = 0
    S.hold_frames = 0
  end

  if (pressed & 0x30) ~= 0 then
    local index, e, kind = selected_entry()
    if e then
      local ok, err = request_entry(index, kind)
      if not ok then S.status = "ERROR: " .. tostring(err) end
    end
  end

  if read_1p_start() then
    if S.trace then trace_state("EXIT") end
    machine:exit()
  end

  S.last_controls = c
  S.last_2p_start = start2
end

local function transliterate_for_wow(text)
  local s = tostring(text or "")
  -- Normalize display text to glyphs available in the resident font.
  local repl = {
    ["Ä"]="AE", ["Ö"]="OE", ["Ü"]="UE", ["ẞ"]="SS",
    ["ä"]="AE", ["ö"]="OE", ["ü"]="UE", ["ß"]="SS",
  }
  for from,to in pairs(repl) do s = s:gsub(from,to) end
  s = s:upper()

  local out = {}
  for i = 1, #s do
    local ch = s:sub(i,i)
    local b = ch:byte()
    if (b >= 0x30 and b <= 0x39) or (b >= 0x41 and b <= 0x5A) then
      out[#out+1] = ch
    elseif ch == " " then
      out[#out+1] = "@"       -- resident CHRTBL space
    elseif ch == "-" then
      out[#out+1] = "_"       -- resident CHRTBL dash
    elseif ch == "'" then
      out[#out+1] = "`"       -- resident CHRTBL apostrophe
    else
      out[#out+1] = "@"
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

local function native_center(text)
  local s = transliterate_for_wow(text)
  if #s > 40 then s = s:sub(1, 40) end
  local col = math.max(0, (40 - #s) // 2)
  return s, col
end

local function native_center_row(text)
  local s, col = native_center(text)
  local row = string.rep("@", col) .. s
  if #row < 40 then row = row .. string.rep("@", 40 - #row) end
  return row:sub(1, 40)
end

local function screen_de(row, col)
  -- Native text coordinates: rows advance by 5 in D; columns by 2 in E.
  return (((row * 5) & 0xFF) << 8) | ((col * 2) & 0xFF)
end

local function native_menu_lines()
  local lang = active_language()
  local list = S.catalog[S.pane]
  local selected = S.selection[S.pane]
  local rows = C.UI_ROWS
  -- Scroll only when the selection leaves the seven-row viewport.
  local first = S.window_first[S.pane] or 1
  local max_first = math.max(1, #list - rows + 1)
  if first < 1 then first = 1 end
  if first > max_first then first = max_first end
  S.window_first[S.pane] = first

  local lines = {}

  -- Heading: active language and catalog.
  local display_lang = lang.name:gsub(" resident$", ""):gsub(" X11$", "")
  local pane_name = S.pane == "phrase" and "PHRASES" or "FRAGMENTS"
  local bankline, bank_col = native_center(display_lang .. "  " .. pane_name)
  -- Clear the heading row before repainting it.
  bankline = string.rep("@", bank_col) .. bankline
  if #bankline < 40 then bankline = bankline .. string.rep("@", 40 - #bankline) end
  lines[#lines+1] = { row=0, col=0, text=bankline, color=C.XPAND_BLUE }

  -- Native-safe short version derived from VERSION.
  local vmaj, vmin, vpatch = VERSION:match("^(%d+)%.(%d+)%.(%d+)")
  local short_version = vmaj and ("V" .. vmaj .. vmin .. vpatch) or "VER"
  lines[#lines+1] = {
    row=0,
    col=math.max(0, 40 - #short_version),
    text=short_version,
    color=C.XPAND_BLUE
  }

  -- Row 1 is blank; catalog rows show ROM address and description.
  for row = 0, rows - 1 do
    local idx = first + row
    local e = list[idx]
    if e then
      local desc = fixed_native_text(e.description, 34)
      local text = string.format("%04X@%s", e.address & 0xFFFF, desc)
      if #text < 39 then text = text .. string.rep("@", 39 - #text) end
      if #text > 39 then text = text:sub(1,39) end

      -- Leave column 0 for the selector arrow; catalog text begins at column 1.
      local screen_row = 2 + row
      lines[#lines+1] = { row=screen_row, col=1, text=text, color=C.XPAND_RED }
      -- Lowercase 'a' maps to WoW's resident right-arrow glyph.
      local marker = idx == selected and "a" or "@"
      lines[#lines+1] = { row=screen_row, col=0, text=marker, color=C.XPAND_YELLOW }
    end
  end

  -- Bottom control legend.
  local footer1 = native_center_row("UP DOWN  SELECT - FIRE  PLAY SOUND")
  local footer2 = native_center_row("LEFT RIGHT  CHANGE SOUND TYPE")
  local footer3
  if S.batch then
    footer3 = native_center_row("1P  EXIT - 2P  STOP")
  else
    footer3 = native_center_row("1P  EXIT - 2P  PLAY ALL")
  end
  lines[#lines+1] = { row=10, col=0, text=footer1, color=C.XPAND_YELLOW }
  lines[#lines+1] = { row=11, col=0, text=footer2, color=C.XPAND_YELLOW }
  lines[#lines+1] = { row=12, col=0, text=footer3, color=C.XPAND_YELLOW }
  return lines
end

local function write_native_draw_program(lines)
  local data = C.DRAW_DATA
  local code = {}
  local function emit(v) code[#code+1] = v & 0xFF end
  local function emit16(v) emit(v); emit(v >> 8) end

  for _,line in ipairs(lines) do
    local text = line.text
    local addr = data
    for i = 1, #text do
      program:write_u8(data, text:byte(i))
      data = data + 1
    end

    -- L03B5 supplies C=$FF and enters native printstr.
    emit(0x21); emit16(addr)
    emit(0x11); emit16(screen_de(line.row, line.col))
    emit(0x06); emit(#text)
    emit(0x3E); emit(line.color or C.XPAND_RED)
    emit(0xCD); emit16(C.PRINT_STRING_COLOR)
  end

  -- printstr leaves interrupts disabled; re-enable them before returning to HALT.
  emit(0xFB)                         -- EI
  emit(0xC3); emit16(C.IDLE_LOOP + 1) -- JP HALT

  if C.DRAW_CODE + #code >= C.DRAW_DATA then
    return false, "native UI display list exceeds reserved RAM"
  end
  if data >= C.CALL_STACK - 0x40 then
    return false, "native UI strings exceed reserved RAM"
  end
  for i,b in ipairs(code) do program:write_u8(C.DRAW_CODE + i - 1, b) end
  return true
end

local function render_ui_native()
  if not S.takeover or not S.ui_dirty or not foreground_idle() then return end
  local ok, err = write_native_draw_program(native_menu_lines())
  if not ok then
    S.status = "ERROR: " .. err
    printf("[WOW SPEECH] %s", err)
    S.ui_dirty = false
    return
  end
  if cpu.state["SP"] then cpu.state["SP"].value = C.CALL_STACK end
  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  cpu.state["PC"].value = C.DRAW_CODE
  S.ui_dirty = false
  S.draw_count = S.draw_count + 1
end

local function on_frame()
  if not S.enabled then return end

  local lang = active_language()
  if lang.key ~= S.last_language_key then
    build_catalog(true)
    if S.takeover then S.status = "BANK CHANGED: " .. lang.name:upper() end
    S.pending = nil
    S.ui_dirty = true
  end

  if not S.takeover then
    local elapsed = machine_seconds()
    if elapsed >= C.TAKEOVER_DELAY_SEC and speech_idle() and sound_requests_idle() then
      takeover("auto")
    end
    return
  end

  process_inputs()
  trace_progress()
  service_wav_capture()
  service_batch()
  service_pending()
  render_ui_native()
end

print("============================================================")
printf("[WOW SPEECH] WOW SPEECH BROWSER %s", VERSION)
printf("[WOW SPEECH] takeover RAM: $%04X; native UI code: $%04X; ROM patching: NONE", C.IDLE_LOOP, C.DRAW_CODE)
print("[WOW SPEECH] display: native WoW L03B5/printstr + resident CHRTBL; blue/yellow/red UI; MAME overlay: NONE")
install_console_shortcuts()
print_console_commands()
print("============================================================")

build_catalog(true)

if emu.add_machine_frame_notifier then
  S.frame_subscription = emu.add_machine_frame_notifier(on_frame)
else
  emu.register_frame_done(on_frame, "wow_speech_browser")
end

if emu.add_machine_stop_notifier then
  S.stop_subscription = emu.add_machine_stop_notifier(function()
    S.enabled = false
    if S.wav_active then stop_owned_wav("closed") end
    restore_console_shortcuts()
  end)
end

print(string.format("[WOW SPEECH] %s loaded from %s; WoW boots normally, then browser takeover begins after %.1fs when speech/sound requests are idle", VERSION, BUILD_FILE, C.TAKEOVER_DELAY_SEC))
