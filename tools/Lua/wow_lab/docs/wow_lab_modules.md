# Wizard of Wor Lab Modules

A Wizard of Wor Lab module is a dynamically discovered Lua entry point that can install and supervise a native Z80 application inside the Lab's swappable `$D400-$DFFF` work-RAM window.

Modules are independent applications. The resident Lab supervisor supplies discovery, lifecycle control, the permanent IM2 service, CPU handoff, memory definitions, and return-to-menu behavior. Each module defines the experiment that runs inside that boundary.

## Module directory

Visible modules are top-level `.lua` files in:

```text
tools/Lua/wow_lab/modules/
```

Files whose names begin with `_` are not listed.

The menu label is derived from the filename:

```text
maze_browser.lua       -> MAZE BROWSER
sound_browser.lua      -> SOUND BROWSER
010_sprite_browser.lua -> SPRITE BROWSER
```

An optional leading decimal prefix followed by `_` or `-` supplies an explicit sort order. The prefix is not displayed. Entries without an explicit order sort after numbered entries and are then ordered alphabetically by label.

## Version metadata

Every maintained module should expose a version near the beginning of the file:

```lua
local M = {}
M.VERSION = '1.2.3-20260817-1408'
```

The loader scans at most the first 96 lines or 16 KB while discovering files. It recognizes `M.VERSION`, another simple table-name `.VERSION`, or a plain `VERSION` assignment using single or double quotes.

Discovery does not execute the module. The version string is read as metadata for the Lab menu. When the module is loaded, an exported `module.VERSION` becomes authoritative for that loaded entry.

The menu compresses the semantic `major.minor.patch` prefix into a four-character-or-longer tag:

```text
1.1.8-20260817-1344 -> V118
0.1.0-20260817-0846 -> V010
```

The full version remains available through `wlmodules()` and module-specific diagnostics.

## Module contract

A module file returns a Lua table. The supervisor recognizes these lifecycle functions:

```lua
local M = {}
M.VERSION = '1.0.0-20260817-1408'

function M.start(lab)
  -- Initialize module state, install native code/data and host diagnostics,
  -- then transfer foreground execution when appropriate.
end

function M.update(lab)
  -- Optional host-side frame service.
end

function M.stop(lab)
  -- Optional module cleanup before the Lab menu is restored.
end

return M
```

`start`, `update`, and `stop` are individually optional at the loader level. A native application normally implements `start`; diagnostic modules that maintain host-side state normally implement `stop` as well.

The supervisor attaches discovery information as `module.__entry` after a successful load. This includes the module filename, path, menu label, and version metadata.

## Lifecycle

```text
module scan
    |
    v
menu entry displayed
    |
    | Fire
    v
loadfile(module path)
    |
    v
execute module chunk
    |
    v
validate returned table
    |
    v
MODE = module
    |
    v
module.start(lab)
    |
    +--> initialize Lua state
    +--> inject module Z80/data
    +--> install module console commands/taps
    +--> native handoff
    |
    v
module active
    |
    +--> permanent IM2 kernel services every interrupt
    +--> module.update(lab) once per MAME frame when supplied
    |
    | 1P Start or supervisor return request
    v
module.stop(lab)
    |
    v
rescan modules
    |
    v
reinstall native Lab menu
```

The supervisor uses a single MAME frame notifier for the Lab session. It dispatches the active module's `update` callback rather than allowing each module to create another lifecycle scheduler.

## Error containment

Module load, `start`, and `update` operations are protected by the supervisor.

- A load or contract failure is reported in the MAME console.
- A `start` failure restores the Lab menu even if module code has begun replacing `$D400+`.
- An `update` failure returns to the Lab menu because the swappable application image is considered disposable.
- A `stop` failure is logged; menu restoration continues.

The permanent supervisor state below `$D400` is the recovery anchor.

## Memory boundary

The shared Lab map is:

```text
$D050-$D23F   shared menu text buffer
$D240-$D37F   resident WoW sound/speech/game work state
$D380-$D3BF   permanent Lab ABI
$D3C0-$D3FD   permanent Lab IM2 kernel
$D3FE-$D3FF   permanent IM2 vector
$D400-$DFFF   swappable native application workspace
```

### Permanent region

A module must not overwrite:

```text
$D380-$D3BF   supervisor ABI
$D3C0-$D3FD   IM2 service
$D3FE-$D3FF   IM2 vector
```

The kernel survives every application swap. It preserves the foreground register set, calls WoW's resident `$8000` sound/speech service, increments the Lab heartbeat, and posts the module return request when 1P Start is pressed.

### Application region

A native module may organize `$D400-$DFFF` as needed. A typical module divides it into:

```text
controller code
module state and mailboxes
generated UI code
UI strings/data
catalog or request tables
private stack
```

The module should define those addresses together near the beginning of its source and document them in its module-specific README.

A module stack must not grow into protected supervisor state, active controller/data, or memory owned by another resident subsystem. `lab.native:handoff(entry, stack_top)` accepts an explicit stack top so each native application can choose a safe layout.

### Resident WoW state

`$D240-$D37F` contains resident WoW sound, speech, and game work state. It is not general module scratch RAM.

A module that tests one of those native systems may read or write the documented fields required by the original WoW interface. Such accesses should be named and documented as resident game state rather than mixed with module-local state.

## Native handoff

A module transfers execution with:

```lua
lab.native:handoff(entry_address, stack_top)
```

The handoff:

- requires an installed Lab native environment;
- requires the entry address to lie in `$D400-$DFFF`;
- sets Lab mode to module;
- clears the supervisor request and menu draw-pending state;
- loads the selected stack pointer;
- releases HALT if necessary;
- sets the Z80 PC to the module entry.

The permanent IM2 configuration and kernel remain in place.

The foreground module therefore does not need to implement the Lab return key. The resident kernel posts request `$02` when 1P Start is pressed while `MODE` is nonzero.

## Native and Lua ownership

A module should keep execution responsibilities explicit.

Native Z80 is the preferred owner for behavior that is being tested as part of the emulated machine:

- cabinet input polling;
- foreground timing and state machines;
- calls into WoW ROM routines;
- request posting;
- playback sequencing;
- native rendering where the display itself is part of the test.

Lua is the preferred owner for host integration:

- file discovery and loading;
- code/data injection;
- MAME object access;
- read-only instrumentation;
- diagnostic capture and serialization;
- module console commands;
- preparation of dynamic display text or tables;
- lifecycle setup and teardown.

A diagnostic observer should not silently become the implementation under test. If a module claims to exercise a WoW service, the native path should use that service directly rather than synthesize an equivalent result in Lua.

## Rendering

Simple module pages can use the Lab's `show_module_page()` helper while the menu application image remains compatible with the Lab draw service.

A native module that replaces the application workspace should own its own display code and data inside `$D400-$DFFF`. It may still call resident WoW rendering routines such as `$03B5` directly.

WoW text must use the game's native character encoding. ASCII spaces and punctuation cannot be assumed to map directly to displayed glyphs.

## Console command ownership

Module-specific console commands should exist only while that module is active.

A module that installs globals should:

- record any pre-existing global value;
- install its command during `start`;
- restore the pre-existing value, or remove the command, during `stop`;
- avoid replacing a global it no longer owns during teardown.

This keeps commands from one module from leaking into another module session.

The Sound Browser follows this rule for the `ws*` commands.

## Host instrumentation

Read-only instrumentation may observe program RAM, I/O writes, CPU state, screen timing, or other MAME-exposed state. Instrumentation should be bounded so a long session cannot grow without limit.

A module that installs taps or notifiers must remove them in `stop`.

Captured data should distinguish:

- observed machine events;
- decoded interpretations of those events;
- module-local administrative state.

That distinction is especially important when capture output is used as reverse-engineering evidence.

## Returning to the Lab

1P Start is a universal module return because it is handled by the resident kernel rather than by the swappable application.

When the supervisor receives request `$02` it:

```text
calls module.stop(lab)
        |
        v
rescans modules/
        |
        v
rebuilds ABI/menu state
        |
        v
reinstalls permanent kernel/vector
        |
        v
injects the native menu application at $D400
        |
        v
returns Z80 foreground execution to the menu
```

The menu entry also places resident sound/speech services into a defined idle state before normal Lab operation resumes.

## Module implementation checklist

A native module is ready to integrate when all of these are explicit:

- `M.VERSION` is present near the top of the source.
- Module-local RAM ranges are documented.
- `$D380-$D3FF` is preserved.
- Resident WoW RAM accesses are named and intentional.
- The native entry point and stack top are documented.
- Native controls and host-side console commands have distinct ownership.
- Host taps/notifiers/shortcuts are removed by `stop`.
- 1P Return succeeds from every module state.
- Re-entering the module starts from a defined state.
- No WoW ROM bytes are patched.

## Module-specific documentation

Each implemented module should have a document in this directory named:

```text
wow_lab_<module>_module.md
```

Current detailed module documentation:

- [Sound Browser module](wow_lab_sound_browser_module.md)
