# Wizard of Wor Lab

Wizard of Wor Lab is a native test environment hosted inside a running MAME Wizard of Wor machine. Lua remains resident as the supervisor and module loader. After a short reset/initialization interval, injected Z80 code takes ownership of foreground execution and uses selected Wizard of Wor ROM routines as resident services.

The lab does not patch ROM contents and does not enter the Wizard of Wor game loop after takeover.

## Run

```sh
mame wow -console -window -autoboot_script tools/Lua/wow_lab/wow_lab.lua
```

The entry script may be launched from any working directory; core and module paths are resolved relative to `wow_lab.lua`.

## Native menu controls

- Up / Down: move through discovered modules
- Fire: open the selected module
- 1P Start while a standard module is active: return to the lab menu
- `EXIT MAME`: final menu item; Fire schedules MAME exit

## Architecture

```text
wow_lab.lua
    |
    +-- core/lab.lua             resident lifecycle supervisor
    +-- core/native.lua          Z80 menu/input/render controller
    +-- core/memory.lua          shared address map and memory helpers
    +-- core/module_loader.lua   directory discovery and selected-file loading
    +-- core/path.lua            portable path helpers
    |
    +-- modules/*.lua            dynamically discovered lab modules
```

The supervisor installs one MAME frame notifier for the complete session. MAME 0.289 exposes frame notifier subscriptions and the running-machine exit operation through its Lua API. Module callbacks are dispatched through that single supervisor frame service.

## Dynamic module discovery

The menu contains no hard-coded module list. The supervisor enumerates `modules/*.lua`, derives display names from filenames, sorts them, and adds `EXIT MAME` as the final supervisor-owned item.

Files are not executed during discovery. The selected module is loaded with `loadfile()` when Fire is pressed. Returning to the menu discards the active module reference and scans the directory again.

Example:

```text
modules/
    speech_browser.lua
    sound_browser.lua
    sprite_browser.lua
    maze_browser.lua
```

produces:

```text
SPEECH BROWSER
SOUND BROWSER
SPRITE BROWSER
MAZE BROWSER
EXIT MAME
```

Adding `palette_lab.lua` makes `PALETTE LAB` appear automatically at the next menu scan. Entries sort alphabetically by filename-derived label; optional numeric filename prefixes may be used when an explicit order is wanted.

## Native ownership

The menu controller runs from work RAM beginning at `$D400`. It installs an IM 2 frame handler, reads cabinet controls directly, calls WoW's resident `$8000` sound/speech service each frame, and uses WoW's `$03B5` colored `printstr` entry for the display.

Lua services high-level lifecycle requests through a small ABI at `$D380-$D394`:

| Address | Purpose |
| --- | --- |
| `$D380-$D383` | `WLAB` signature |
| `$D384` | mode: menu/module |
| `$D385` | selected menu index |
| `$D386` | item count including Exit |
| `$D387` | native request mailbox |
| `$D388` | draw request |
| `$D389` | native frame heartbeat |
| `$D38A-$D38F` | input and repeat state |
| `$D390-$D394` | module event/arguments |

The visible frame is cleared and drawn by Z80 code. Lua prepares text and the short native draw program, then posts a draw request. The native controller performs the WoW renderer calls on its next foreground pass.

## Memory ownership

| Range | Owner/use |
| --- | --- |
| `$D050-$D23F` | lab native text buffer |
| `$D240-$D37F` | WoW resident sound/speech state |
| `$D380-$D3BF` | lab Lua/Z80 ABI |
| `$D3CA-$D3CB` | lab IM 2 vector |
| `$D400-$D5FF` | standard native supervisor controller |
| `$D600-$D6FF` | generated native draw program |
| `$4000-$7FBF` | visible bitmap used by Lab clears/rendering |
| `$7FC0-$7FFF` | protected non-visible video-RAM stack margin |

`SP=$8000` places controller call traffic in the non-visible top edge of video RAM. Native screen clears stop at `$7FBF`; `$7FC0-$7FFF` is never cleared while the controller is running.


## Console commands

```text
wlstatus()   supervisor and CPU state
wlmodules()  discovered module list
wlnative()   ABI, IM2 vector, and native-controller state
wlmenu()     reinstall and redraw the lab menu
wlexit()     exit MAME
wlhelp()     command summary
```

These are administrative/diagnostic commands. Cabinet navigation and module control remain native Z80 operations.

## Module lifecycle

```text
MENU
  |
  | Fire
  v
load selected modules/<file>.lua
  |
  v
module.start(lab)
  |
  +--> module.update(lab) once per frame, when supplied
  |
  | 1P Start / module return request
  v
module.stop(lab)
  |
  v
rescan modules directory
reinstall native menu controller
redraw menu
```

See `modules/README.md` for the module interface.
