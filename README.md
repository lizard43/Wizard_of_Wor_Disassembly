# Z80 Code Architecture & Formatting Guidelines

This document outlines the structural, formatting, and documentation standards for the Z80 disassembly and development project. 

---

## 1. General Code Rules

These rules apply universally to all source files, instructions, and data structures to ensure a consistent codebase.

### Column Placement
To maintain strict visual alignment throughout the codebase, structure your source files using the following exact column boundaries:

| Code Element | Target Column | Description |
| :--- | :--- | :--- |
| **Labels** | Column 1 | All labels must begin at the absolute start of the line. |
| **Opcodes** | Column 13 | Mnemonics and assembler directives (e.g., LD, DB, EQU). |
| **Operands** | Column 21 | Registers, values, and memory addresses. |
| **Line Comments** | Column 41 | All trailing or standalone line comments. |

> A Note on Flexibility: While consistency is key, there are exceptions to every rule. Please use your best judgment—do not shoehorn code, large data structures, or complex expressions into these specific columns if doing so compromises readability or correctness. Clarity and accuracy always take priority.

### Spacing and Tabs
* **Use Spaces Only:** Do not use hard tab characters (\t) anywhere in the source code. All indentation and column alignments must be achieved using spaces.
* **Editor Configuration:** Configure your text editor to automatically convert tabs to spaces to ensure a consistent layout across different platforms.

### Header & Text Layout
* **Header Borders:** Header border lines (e.g., ;****... and ;####...) must be exactly 90 characters long (1 semicolon + 89 asterisks/hashes).
* **Word Wrap:** No text inside a comment block may exceed column 88.
* **The ----> Rule:** Any header containing ----> must have a blank comment line (;) separating the title line from the explanation line below it.

### Label Naming Conventions
* **Internal Short Jumps:** Loops or jumps that are completely internal to a specific code block must not use random or arbitrary Lnnnn labels.
* **Naming Structure:** Use the first four letters of the main routine's label followed by an incremental number.
* **Example:** For a main routine labeled PrintString, internal jumps should be named Prin1, Prin2, etc.

---

## 2. Pattern Data Specifications

All Z80 assembly code patterns, graphics assets, and standard routines must adhere to these documentation standards to preserve original TERSE contextual history while keeping the codebase clean. **These specifications act as a superset and must be applied in addition to the General Code Rules.**

### Pattern Section Guidelines
When documenting individual graphic or data patterns, apply the following strict rules:

* **Pattern Name:** The first line of the block must contain the pattern name and any title/info drawn directly from the original TERSE source code.
* **Description & Context:** Include a plain-English description of what the pattern does. Incorporate original TERSE logic or context where meaningful.
* **Set Relationships:** If a pattern is part of a larger, interconnected set of graphics (e.g., Worluk states, dungeon walls, player Worrior sprites), explicitly note that relationship.
* **Omit Redundant Metadata:** Do not include byte-counting metadata (e.g., sprite bitmap size, object total size) in individual pattern comments. This technical detail belongs exclusively in the master programming documentation.

### Data Block Size Tags
Immediately above any DB data block, you must include a comment containing the exact SIZE keyword using the following format:

```assembly
; SIZE: WxH
```

(Where W is the width in bytes, and H is the height in rows).