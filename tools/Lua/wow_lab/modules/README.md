# Wizard of Wor Lab

Wizard of Wor Lab is a native diagnostic and reverse-engineering environment hosted inside a running MAME *Wizard of Wor* machine.

Lua remains resident as the supervisor, module loader, filesystem layer, and host-side diagnostic service. Injected Z80 code owns the visible menu and the foreground behavior of native modules. The original *Wizard of Wor* ROM remains unchanged and is used as a resident library of rendering, sound, speech, input, data, and utility routines.

The Lab is designed around a permanent supervisor boundary below `$D400` and a swappable native application workspace at `$D400-$DFFF`. The menu is one native application. Selecting a module replaces that application workspace with the module's own controller, state, UI code, and data while the resident Lab kernel remains active.

## Run

From the repository root:

```sh
mame -console -window -autoboot_script tools/Lua/wow_lab/wow_lab.lua -rompath roms/ wow
```

If the ROM path is already configured, `-rompath roms/` may be omitted.

The entry script resolves the `core/` and `modules/` directories relative to `wow_lab.lua`, so the command may be launched from another working directory when the script path is adjusted accordingly.

## Controls

At the Lab menu:

- **Up / Down** — select a discovered module
- **Fire** — launch the selected module
- **1P Start** — exit MAME

While a module is active:

- **1P Start** — return to the Lab menu
- all other controls are defined by that module

The menu combines P1 and P2 joystick/fire input. Module controls may define a narrower input set when appropriate.

## Operating model

```text
MAME starts Wizard of Wor
        |
        v
wow_lab.lua starts the resident Lua supervisor
        |
        | 120-frame initialization interval
        v
Lab installs permanent ABI + IM2 kernel
        |
        v
Lab injects native menu at $D400
        |
        v
Z80 menu owns foreground execution
        |
        | Fire on selected module
        v
Lua loads and validates modules/<name>.lua
        |
        v
module.start(lab)
        |
        +--> installs module application at $D400-$DFFF
        +--> installs module diagnostics/host services
        +--> transfers Z80 PC to module entry point
        |
        v
native module runs while permanent IM2 kernel remains resident
        |
        | 1P Start
        v
kernel posts RETURN request through Lab ABI
        |
        v
module.stop(lab)
        |
        v
module directory is rescanned
        |
        v
Lab menu is injected again at $D400
```

The module application is disposable. The supervisor ABI and interrupt kernel are permanent for the Lab session.

## Z80 injection and resident ROM services

The Lab does not patch the game ROM. Native controllers are assembled in Lua and written into *Wizard of Wor* work RAM.

The Lab menu configures Z80 IM 2 and points the interrupt vector at the permanent kernel. The kernel preserves the full working register set, calls the resident WoW sound/speech service at `$8000`, advances the Lab heartbeat, and watches 1P Start while a module is active.

The native menu uses WoW's resident colored string renderer at `$03B5`, reads the cabinet input ports directly, and runs an `EI`/`HALT` foreground loop synchronized to the machine interrupt cadence.

A native module is free to replace the complete `$D400-$DFFF` application image. It does not need to carry its own copy of the Lab return mechanism because the interrupt kernel is outside that workspace.

## Memory ownership

```text
$D050-$D23F   shared menu text buffer

$D240-$D37F   resident WoW sound/speech/game work state

$D380-$D3BF   permanent Lab ABI
$D3C0-$D3FD   permanent Lab IM2 kernel
$D3FE-$D3FF   IM2 vector -> $D3C0 kernel

$D400-$DFFF   swappable native application workspace
               menu or active module

$4000-$7FBF   visible bitmap
$7FC0-$7FFF   non-visible menu stack margin
$8000         menu stack top
```

The central boundary is `$D400`: everything below it that belongs to the Lab supervisor or resident WoW services remains available while the active native application is replaced.

The Lab application workspace is deliberately broad. A module can choose its own internal layout for controller code, state, generated display code, text, tables, and stack as long as it stays within its declared ownership and preserves the permanent ABI/kernel.

## Permanent Lab ABI

The supervisor communication block begins at `$D380`:

| Address | Purpose |
| --- | --- |
| `$D380-$D383` | `WLAB` signature |
| `$D384` | mode: `0` menu, nonzero module/application |
| `$D385` | selected menu index |
| `$D386` | discovered module count |
| `$D387` | supervisor request mailbox |
| `$D388` | menu draw-pending flag |
| `$D389` | interrupt heartbeat |
| `$D38A-$D38F` | menu input and repeat state |
| `$D390-$D394` | module/supervisor event arguments |
| `$D395-$D3BF` | reserved supervisor ABI space |

Supervisor request values are:

| Value | Meaning |
| ---: | --- |
| `$00` | no request |
| `$01` | launch selected module |
| `$02` | return active module to Lab |
| `$03` | exit MAME |

The permanent IM2 service occupies `$D3C0-$D3FD`; `$D3FE-$D3FF` contains the vector address.

## Core components

```text
wow_lab/
    wow_lab.lua
    README.md

    core/
        lab.lua
        memory.lua
        module_loader.lua
        native.lua
        path.lua

    modules/
        maze_browser.lua
        sound_browser.lua
        speech_browser.lua
        sprite_browser.lua

    docs/
        wow_lab_modules.md
        wow_lab_sound_browser_module.md
```

`wow_lab.lua` resolves the Lab root, loads the core pieces, starts the supervisor, and installs the global Lab console commands.

`core/lab.lua` owns the session lifecycle: startup delay, module scans, menu rendering, module launch/update/stop, error recovery, and MAME exit.

`core/native.lua` builds the permanent IM2 kernel and native menu controller, performs CPU handoff, owns the menu input model, and builds native WoW text-renderer calls.

`core/memory.lua` defines the shared memory map and byte helpers. Its address definitions are the ownership contract between the supervisor and native applications.

`core/module_loader.lua` discovers module files, reads version metadata for the menu, validates loaded module tables, and attaches discovery metadata to the active module.

`core/path.lua` provides path normalization and path construction independent of the process working directory.

## Module discovery and swapping

The Lab has no hard-coded module registry. Every top-level `.lua` file in `modules/` that does not begin with `_` becomes a menu entry.

Menu names are derived from filenames:

```text
sound_browser.lua      -> SOUND BROWSER
speech_browser.lua     -> SPEECH BROWSER
010_sprite_browser.lua -> SPRITE BROWSER
```

An optional numeric prefix controls ordering and is omitted from the displayed label. Entries without numeric prefixes sort alphabetically by label.

Discovery reads bounded version metadata from the source file without executing the module. The module itself is executed only when selected. Returning to the Lab performs another directory scan, so the menu reflects the module files and versions currently present on disk.

See [Lab module architecture and contract](docs/wow_lab_modules.md) for the module lifecycle, memory rules, version metadata, console ownership, and native handoff requirements.

## Module documentation

- [Lab module architecture and contract](docs/wow_lab_modules.md)
- [Sound Browser module](docs/wow_lab_sound_browser_module.md)

Module-specific documents live in `docs/` using the `wow_lab_<module>_module.md` naming pattern.

For the underlying WoW sound architecture, request map, ROM sound streams, sound-engine work RAM, and Astrocade custom I/O IC registers, see [`docs/SOUND_MAP.md`](../../../docs/SOUND_MAP.md).

## Console administration

The Lab installs these commands for the complete session:

```text
wlstatus()    supervisor and CPU state
wlmodules()   discovered module list and versions
wlnative()    ABI, vector, menu, kernel, and workspace state
wlmenu()      reinstall and redraw the Lab menu
wlexit()      exit MAME
wlhelp()      show the Lab command list
```

Module-specific console commands exist only while their module is active. A module owns installation and teardown of those commands.

## Design rules

The Lab follows a small set of hard boundaries:

- The Wizard of Wor ROM is not patched.
- `$D380-$D3FF` is permanent supervisor state and is not module workspace.
- `$D400-$DFFF` is the swappable native application workspace.
- The resident WoW sound/speech work area at `$D240-$D37F` is preserved and used through the game's real interfaces.
- Native Z80 owns cabinet-driven foreground behavior for modules that exercise native game systems.
- Lua owns module discovery, lifecycle, filesystem access, MAME integration, and diagnostic observation.
- 1P Return is supervisor-owned and remains available independently of module foreground code.
- Module cleanup must remove host-side taps, callbacks, files, and console shortcuts that belong to the module.

These boundaries keep native experiments reproducible while allowing modules to use the original WoW ROM as the implementation under test.
