# Engineering rules — original software first

Mandatory for all coding assistants/contributors:

1. Original source, original programming language, original interpreter/compiler/XC, runtime, graphics/DATA, algorithms and control flow are authoritative wherever available.
2. Feed complete original-style source through the original source loader and native compiler. TERSE source screens, dictionaries, syntax, definitions, compilation sequence and target word allocation are TERSE/XC concerns, never JavaScript concerns.
3. Node/Python/shell host code may launch native tools, transport unchanged source, package compiler output and independently verify; no host parsing/rebuilding original source, synthetic dictionaries/address maps, token relocation, gameplay rewriting or invented graphics.
4. Hardware-specific native code can adapt necessary video/input/sound interfaces where original routines cannot operate unchanged. Record the actual target difference and original routines preserved.
5. **Hard stop:** If the original method is blocked, investigate and explain; seek explicit user authorization before any alternate implementation, compiler, parser or workaround. Never treat passing tests as permission.
6. Source checks, native builds, ROM comparisons, MAME/emulator and physical hardware are distinct verification gates. Report only executed tests; do not claim stubs or static scenes are finished gameplay.
7. Keep README project/build oriented; approved stages in docs/SPRINT-PLAN.md, unresolved deviations in docs/TECHNICAL-DEBT.md. Preserve existing documentation and prior stages.
8. Each development PR must show original source/toolchain, adaptations, prior approvals, actually executed verification and remaining work. Reject unapproved architecture violations even if functional.

No assistant may grant itself an exception.
