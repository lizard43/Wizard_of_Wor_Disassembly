# Wizard of Wor Graphical Memory Map

```text
┌─────────────────────────────┐ $FFFF
│                             │
│    X12-X13 EMPTY SOCKETS    │
│         (Unmapped)          │
│                             │
├─────────────────────────────┤ $DFFF
│                             │
│  Empty Static RAM Sockets   │
│                             │
├─────────────────────────────┤ $D3FF
│    STATIC RAM (Work RAM)    │ $D040
├─────────────────────────────┤
│        Protected RAM        │ $D000
├─────────────────────────────┤ $CFFF
│      X11 EMPTY SOCKET       │
│    (Foreign Language ROM)   │
├─────────────────────────────┤ $BFFF
│           ROM X8            │
│         (Unmapped)          │
├─────────────────────────────┤ $AFFF
│                             │
│         ROMs X5-X7          │
│         (High ROM)          │
│                             │
├─────────────────────────────┤ $7FFF
│  Non-viewable Area (STACK)  │ $7FC0
├─────────────────────────────┤ 
│                             │
│     Viewable SCREEN RAM     │
│        (Framebuffer)        │
│                             │
├─────────────────────────────┤ $3FFF
│                             │
│         ROMs X1-X4          │
│    (Low ROM / Magic RAM)    │
│                             │
└─────────────────────────────┘ $0000
```

## Memory Map Details

| Address Range | Description | Hardware Sockets | Notes |
| :--- | :--- | :--- | :--- |
| **`$E000 - $FFFF`** | **Unmapped** | X12-X13 | Empty sockets; open-bus behavior. |
| **`$D400 - $DFFF`** | **Empty RAM Sockets** | X23-X28 | Unused in Wizard of Wor (normally used in the game Gorf). |
| **`$D040 - $D3FF`** | **Static RAM (Work RAM)**| X21-X22 | Scratchpad runtime workspace for structs, input snapshots, object state, and buffers. |
| **`$D000 - $D03F`** | **Protected RAM** | X21-X22 | 64 bytes strictly reserved for credits, latches, and bookkeeping. Writes must go through the write-enable path. |
| **`$C000 - $CFFF`** | **Foreign Language ROM** | X11 | Empty socket; treat as open-bus behavior if language chip is not present. |
| **`$B000 - $BFFF`** | **Unmapped** | X8 | Normally an empty socket. |
| **`$8000 - $AFFF`** | **High ROM** | X5-X7 | Normal ROM for upper game code, lookup tables, strings, and sprite data. |
| **`$7FC0 - $7FFF`** | **Stack** | - | Non-viewable `$40` bytes used exclusively for the game's stack. |
| **`$4000 - $7FBF`** | **Viewable Screen RAM** | - | Framebuffer memory. Every line on the screen is `$50` bytes long. |
| **`$0000 - $3FFF`** | **Low ROM / Magic Write**| X1-X4 | Reads normally fetch ROM bytes; writes are intercepted by the Magic function generator and mirror into VRAM (`0x4000` + offset). |