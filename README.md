# Wizard of Wor Disassembly Project

This repository contains the disassembly and source code reconstruction for the classic arcade game *Wizard of Wor*. The primary objective is to maintain a highly accurate, clean, and readable codebase for study, preservation, and development, ensuring that it compiles down to a byte-perfect match of the original arcade ROM checksums.

To ensure consistent formatting and layout across all development environments, all contributions and edits to the assembly source code must adhere to the project's formatting guidelines.

---

## 🛠️ Z80 Source Code Formatting Guidelines

> ⚠️ **A Note on Flexibility:** While consistency is key, there are exceptions to every rule. Please use your best judgment—do not shoehorn code, large data structures, or complex expressions into these specific columns if doing so compromises readability or correctness. Clarity and accuracy always take priority.

### Column Placement
To maintain strict visual alignment throughout the codebase, structure your source files using the following column boundaries:

| Code Element | Target Column | Description |
| :--- | :--- | :--- |
| **Labels** | Column 1 | All labels must begin at the absolute start of the line. |
| **Opcodes** | Column 13 | Mnemonics and assembler directives (e.g., `LD`, `DB`, `EQU`). |
| **Operands** | Column 21 | Registers, values, and memory addresses. |
| **Line Comments** | Column 41 | All trailing or standalone line comments. |

### Spacing and Tabs
*   **Use Spaces Only:** Do not use hard tab characters (`\t`) anywhere in the source code. All indentation and column alignments must be achieved using spaces.
*   **Editor Configuration:** Configure your text editor to automatically convert tabs to spaces to ensure a consistent layout across different platforms.

### Pattern Documentation Standards
For all Z80 assembly code patterns, comments should follow this structure to ensure clarity and retain original TERSE contextual history:
*   **Line Lengths:** Comment border lines (`;****...` and `;####...`) must be exactly 90 characters long (1 semicolon + 89 asterisks/hashes).
*   **Word Wrap:** No text inside the comment block may exceed column 88.
*   **Pattern Name:** The first line must contain the pattern name and any title/info drawn directly from the original TERSE source code.
*   **Description & Context:** Include a plain-English description of what the pattern does. Incorporate original TERSE logic or context where meaningful.
*   **Set Relationships:** If a pattern is part of a larger, interconnected set of graphics (e.g., Worluk states, dungeon walls, player Worrior sprites), explicitly note that relationship.
*   **Omit Redundant Metadata:** Do not include byte-counting metadata (e.g., sprite bitmap size, object total size) in individual pattern comments. This technical detail belongs in the master programming documentation.

---

## 📋 Tooling & Pattern Extraction Guidelines

Because *Wizard of Wor* hardcodes its sprite sizes into the Z80 drawing subroutines rather than storing them in a header with the graphics data, the raw ROM bytes do not contain their own dimensions. 

To allow automated tools and image-rendering scripts to parse the assembly code and reconstruct it into visual graphics, **all recovered patterns must be tagged with a standardized size comment.**

### The Size Tag Format
Immediately above the `DB` data block, you must include a comment with the exact keyword `; SIZE: WxH` (Width in bytes × Height in rows).

**Example:**
```assembly
;******************************************************************************************
; BLUE PLAYER (Demo Screen) - Found at $9C38
; SIZE: 5x18
;******************************************************************************************
PATTERN_9C38:
            DB      $30, $00, $00, $00, $2A
            ...