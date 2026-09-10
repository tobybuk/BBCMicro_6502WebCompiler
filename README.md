# BBC 6502 Web Assembler (ChatGPT assisted)

A dependency-free, browser-based **two-pass assembler, source editor and project viewer for the NMOS 6502**.

The complete assembler application is distributed as **one self-contained HTML file**: `BBC_6502_Web_Assembler.html`. The HTML, CSS, editor logic and human-readable JavaScript assembler are all embedded in that file. There are no external JavaScript files, CSS files, packages, libraries, runtime dependencies or web services required to use it.

The assembler is intended for BBC Micro development, reverse engineering and general 6502 work. It understands ordinary symbolic assembly source, multiple source files, relocatable labels, multiple `ORG` regions, data directives, expressions, listings and symbol maps. It also supports a deliberately selected set of undocumented NMOS 6502 instructions.

The application runs entirely on the local machine. It does not upload source files, contact a compiler service or require a web server.

---

## Contents

- [Quick start](#quick-start)
- [Single-file distribution](#single-file-distribution)
- [User interface](#user-interface)
- [Working with source files and projects](#working-with-source-files-and-projects)
- [Assembly model](#assembly-model)
- [Source syntax](#source-syntax)
- [Labels and constants](#labels-and-constants)
- [Numbers, characters and strings](#numbers-characters-and-strings)
- [Expressions](#expressions)
- [Addressing modes](#addressing-modes)
- [Zero-page and absolute address selection](#zero-page-and-absolute-address-selection)
- [Directives](#directives)
- [Including multiple source files](#including-multiple-source-files)
- [Official NMOS 6502 instructions](#official-nmos-6502-instructions)
- [Undocumented NMOS 6502 instructions](#undocumented-nmos-6502-instructions)
- [Build output](#build-output)
- [Diagnostics](#diagnostics)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Known limitations and deliberate design choices](#known-limitations-and-deliberate-design-choices)
- [Undocumented-opcode references](#undocumented-opcode-references)

---

# Quick start

The assembler is supplied as one file:

```text
BBC_6502_Web_Assembler.html
```

To use it:

1. Download `BBC_6502_Web_Assembler.html`.
2. Open it directly in a modern browser.
3. Click **Open file(s)** and select an assembly source file, or select all source files required by a multi-file source project.
4. Choose the main source file from the **Source** drop-down if more than one file is loaded.
5. Edit the source in the built-in editor.
6. Click **Assemble**, or press **Ctrl+Enter** / **Cmd+Enter**.
7. Review the **Build**, **Segments**, **Symbols** and **Listing** tabs.
8. Save the required output using **Save binary**, a segment-specific **Save** button, **Save listing**, or **Save symbols**.
9. Use **Save source** or **Save As…** to download edited source.

No installation, package manager, local server or Internet connection is required.

---

# Single-file distribution

The executable application is deliberately kept in a **single self-contained HTML file**:

```text
BBC_6502_Web_Assembler.html
```

That one file contains:

- the complete user interface;
- all CSS;
- the source editor;
- file/project handling;
- the two-pass assembler;
- opcode and addressing-mode tables;
- expression parsing;
- directive handling;
- symbol and listing generation;
- binary/segment output code;
- support for undocumented NMOS 6502 opcodes;
- all application JavaScript.

The JavaScript is intentionally stored in **human-readable, unminified form** inside the HTML. Anyone who wants to inspect or modify the implementation can open the HTML in a text editor or use the browser's **View Source** / developer tools.

The compiler itself does not require or load separate `.js`, `.css`, library, package or module files. If somebody chooses to split the HTML into separate implementation files for their own development workflow, that is outside the distribution model documented here.

`README.md` is documentation only; it is not required to run the assembler.

Source programs being assembled may themselves use multiple files through `INCLUDE`. That is independent of the assembler application's single-file distribution.

---

# User interface

## Toolbar

### New

Creates a new in-memory source project containing a small example program named `untitled.asm`.

If the current editor has unsaved changes, the browser asks for confirmation before replacing it.

### Open file(s)

Loads one or more source files from the local machine. Selected files become the complete current in-browser project.

Useful extensions include:

```text
.asm
.s
.inc
.6502
.txt
```

The assembler itself does not depend on the file extension; the extensions above are primarily used to choose a sensible initial source file in the UI.

### Open project folder

Where supported by the browser, this loads all files selected from a directory tree and retains their relative paths. This is convenient for projects using `INCLUDE` and subdirectories.

This control uses the browser's directory-selection facility, commonly exposed through `webkitdirectory`. Browser support varies.

### Save source

Downloads the current editor contents using the current project filename.

Because ordinary browser pages cannot silently overwrite arbitrary local files, **Save source downloads a file**; it does not modify the originally opened file in place.

### Save As…

Prompts for a new filename, adds or replaces that filename in the current in-memory project, makes it the active source file, and downloads the source under the new name.

The old project entry is retained in memory when a different name is chosen. This is useful when creating a modified variant while keeping the original source available in the Source drop-down.

Shortcut:

```text
Ctrl+Shift+S
Cmd+Shift+S
```

### Assemble

Runs the complete two-pass assembly process using the active file as the project's main source.

Shortcut:

```text
Ctrl+Enter
Cmd+Enter
```

### Save binary

After a successful build, downloads a **flat binary** spanning from the lowest emitted address to the highest emitted address.

If the program contains address gaps between `ORG` regions, those gaps are filled using the selected **gap fill** byte.

### Save listing

Downloads a textual assembler listing containing address, generated bytes, source file, source line and original source text.

### Save symbols

Downloads a textual symbol map sorted by address.

### Undocumented NMOS opcodes

Controls whether the assembler accepts the explicitly undocumented mnemonic families such as `SLO`, `SAX`, `LAX`, `DCP`, `ISC`, `ARR`, etc.

It is enabled by default.

**Important:** undocumented operand-bearing `NOP` forms use the normal mnemonic `NOP` and therefore remain accepted even when this box is cleared. See [Undocumented NOP forms](#undocumented-nop-forms).

### Gap fill

Specifies the byte used when **Save binary** has to fill unused addresses between multiple emitted segments.

The value is entered as two hexadecimal digits, for example:

```text
00
FF
EA
```

An invalid value falls back to `00`.

The gap-fill value affects only the generated flat binary. It does not alter individual emitted segments.

### Syntax help

Displays a concise in-application summary of the assembler syntax. This README is the complete reference.

---

# Editor and result panes

The left side of the application is the source editor. The status bar shows the current line and column plus source line/character counts.

The right side contains four result tabs.

## Build

After a successful build this shows:

```text
Status
Origin
End
Emitted bytes
Flat span
Segments
Symbols
Assembly time
SHA-256
```

`SHA-256` is calculated over the **flat binary**, including gap-fill bytes. It is displayed when the browser provides the Web Crypto API.

Build errors and warnings are also displayed here. Clicking a diagnostic attempts to open the appropriate project file and select the offending line.

## Segments

Every contiguous emitted address range appears as a separate segment with:

```text
segment number
start address
end address
byte count
Save button
```

The segment's **Save** button downloads only that raw range and does not insert gap-fill bytes.

## Symbols

Shows the assembled symbol table sorted by address. The filter box narrows the displayed symbols by name.

Clicking a symbol attempts to locate its definition in one of the loaded source files and jumps the editor to it.

## Listing

Shows the generated assembler listing. Each emitted source statement contains the generated address and bytes together with the source filename and line number.

---

# Working with source files and projects

The browser holds the current project entirely in memory as a collection of filename/text pairs.

Selecting several files with **Open file(s)** loads them together. This is how `INCLUDE` files are made available to the assembler.

The **Source** drop-down chooses which loaded file is visible in the editor and, importantly, which file acts as the **main source file** when Assemble is pressed.

For example, load:

```text
main.asm
constants.inc
graphics.asm
sound.asm
```

and make `main.asm` active. It might contain:

```asm
INCLUDE "constants.inc"
INCLUDE "graphics.asm"
INCLUDE "sound.asm"
```

Pressing Assemble recursively expands those files and assembles the resulting source.

Switching between files preserves editor changes in the in-memory project.

Dragging one or more files onto the application window is equivalent to using **Open file(s)**.

The application warns when closing/reloading the page if the active editor contains unsaved changes.

---

# Assembly model

The assembler is a conventional **two-pass absolute assembler**.

## Pass 1

Pass 1:

- expands `INCLUDE` files;
- processes `ORG` directives;
- determines instruction sizes and addressing modes;
- assigns addresses to labels;
- resolves constants where possible;
- records output regions;
- records assertions for checking during pass 2.

Forward label references are supported.

Constants can also refer to later labels or constants. Deferred constant assignments are repeatedly resolved after the first source scan. Circular or otherwise unresolvable assignments produce an error.

## Pass 2

Pass 2:

- evaluates final operands and expressions;
- checks branch distances;
- emits instruction and data bytes;
- applies fills and alignment;
- checks `ASSERT` expressions;
- detects overlapping output;
- builds the listing, segments, flat binary and symbol map.

The address space is 16-bit:

```text
&0000-&FFFF
```

This is an assembler for an ordinary NMOS 6502 address space, not a banked linker or object-file system.

---

# Source syntax

A minimal program is:

```asm
OSWRCH = &FFEE

ORG &1900

start:
    LDX #0

.loop:
    LDA message,X
    BEQ done
    JSR OSWRCH
    INX
    BNE .loop

.done:
    RTS

message:
    EQUS "HELLO FROM 6502!"
    EQUB 13,10,0
```

The syntax is intentionally familiar to BBC Micro programmers while also accepting common generic/BeebAsm-style forms.

Source is case-insensitive for mnemonics and symbols.

---

# Comments

A semicolon starts a comment outside a quoted string:

```asm
LDA #&20       ; select space character
JSR OSWRCH     ; print it
```

A semicolon inside a quoted string is not treated as a comment:

```asm
EQUS "A;B;C"
```

The assembler does not currently use `\`, `//` or `/* ... */` as source-comment syntax.

---

# Labels and constants

## Colon labels

```asm
start:
    LDA #0
```

A statement can follow a colon label on the same source line:

```asm
start: LDA #0
```

## Dot labels

BBC/BeebAsm-style dot labels are also accepted:

```asm
.loop
    INX
    BNE .loop
```

or with a statement on the same line:

```asm
.loop INX
```

### Dot labels are not local scopes

The leading dot is syntactic convenience only. Internally it is removed during symbol canonicalisation.

Therefore:

```asm
.loop
```

and:

```asm
loop:
```

refer to the **same global symbol**.

There is currently no routine-local or module-local label scope. Give labels unique names in multi-file projects.

## Allowed symbol characters

A symbol must begin with one of:

```text
A-Z  a-z  _  .  $  @
```

and subsequent characters may additionally contain digits.

Examples:

```text
start
player_x
.loop
@temporary
sprite.table
value$1
```

Symbols are case-insensitive:

```asm
Player_X = &40
LDA player_x
```

refers to the same symbol.

The first spelling used for a symbol is retained for display in the symbol map.

## Constant assignment

All of the following forms are accepted:

```asm
OSWRCH = &FFEE
SCREEN EQU &3000
EQU MODE2_SIZE, &5000
.EQU MAX_OBJECTS, 73
```

Assignments can use expressions and can reference labels:

```asm
start:
    RTS

end:
program_size = end - start
```

A symbol cannot be redefined to a different value. A duplicate/redefinition with a different value is an assembly error.

---

# Numbers, characters and strings

## Decimal

```asm
LDA #10
EQUB 13,10,0
```

## BBC-style hexadecimal

```asm
LDA #&FF
JSR &FFEE
```

## Dollar-style hexadecimal

```asm
LDA #$FF
JSR $FFEE
```

Both hexadecimal syntaxes are equivalent.

## Binary

```asm
LDA #%10101010
```

## Character expressions

A quoted single character can be used as a numeric expression:

```asm
LDA #"A"
CMP #'Z'
```

A character expression must contain exactly one decoded character.

## Strings

`EQUS`, `.TEXT` and `ASCII` emit strings directly:

```asm
EQUS "HELLO"
.TEXT "WORLD"
ASCII "BBC MICRO"
```

`EQUB` may also contain strings mixed with expressions:

```asm
EQUB "GAME OVER",13,10,0
```

Supported string escapes are:

| Escape | Byte/meaning |
|---|---|
| `\n` | line feed, `&0A` |
| `\r` | carriage return, `&0D` |
| `\t` | tab, `&09` |
| `\0` | zero byte, `&00` |
| `\xHH` | byte with hexadecimal value `HH` |
| `\\` | backslash |
| `\"` | double quote in a double-quoted string |
| `\'` | single quote in a single-quoted string |

The assembler is byte-oriented. String characters are emitted using the low eight bits of their JavaScript character code. For precise non-ASCII binary data, prefer explicit numeric bytes or `\xHH` escapes.

---

# Expressions

Expressions are integer expressions and can contain numbers, character literals, symbols, the current assembly address and operators.

Examples:

```asm
screen_end = &3000 + &5000
page       = >routine
low_byte   = <routine
mask       = (%11110000 | 3) & &FF
size       = end - start

LDA #<message
LDY #>message
ASSERT * <= &3000
```

## Current assembly address

In prefix position, `*` means the address of the current source statement:

```asm
here = *
```

In infix position it is multiplication:

```asm
bytes = count * 4
```

## Unary operators

```text
+expr       unary plus
-expr       arithmetic negation
~expr       bitwise NOT
<expr       low byte: expr AND &FF
>expr       high byte: (expr >> 8) AND &FF
*           current assembly address
```

## Binary operators and precedence

From highest precedence to lowest:

| Precedence | Operators | Meaning |
|---:|---|---|
| 6 | `* / %` | multiply, integer divide, remainder |
| 5 | `+ -` | addition, subtraction |
| 4 | `<< >>` | shifts |
| 3 | `&` | bitwise AND |
| 2 | `^` | bitwise XOR |
| 1 | `\|` | bitwise OR |

Parentheses override precedence:

```asm
value = ((a + b) << 2) | 3
```

Operators of the same precedence are evaluated left-to-right.

Division is integer division truncated toward zero. Division or remainder by zero is an error.

### Hexadecimal `&` versus bitwise AND

BBC hexadecimal notation uses `&` as a prefix, while expressions also use `&` for bitwise AND. Write spaces around the AND operator for clarity:

```asm
masked = flags & &0F
```

---

# Addressing modes

The assembler selects among ordinary NMOS 6502 addressing modes according to the mnemonic and operand syntax.

## Implied

```asm
CLC
SEI
RTS
```

## Accumulator

```asm
ASL A
LSR A
ROL A
ROR A
```

## Immediate

```asm
LDA #&20
LDX #10
CMP #<table
```

## Zero page

```asm
LDA &70
STA pointer
```

## Zero page,X

```asm
LDA &70,X
STA buffer,X
```

## Zero page,Y

Used only by instructions that actually have this NMOS 6502 mode, such as `LDX`, `STX`, `LAX` and `SAX`:

```asm
LDX &70,Y
STX &80,Y
```

## Absolute

```asm
LDA &3000
JSR &FFEE
JMP routine
```

## Absolute,X

```asm
LDA table,X
STA &3000,X
```

## Absolute,Y

```asm
LDA table,Y
LDX table,Y
```

## Indexed indirect `(zero page,X)`

```asm
LDA (&70,X)
STA (&80,X)
```

The pointer operand is an 8-bit zero-page address.

## Indirect indexed `(zero page),Y`

```asm
LDA (&70),Y
STA (&80),Y
```

## Absolute indirect

The NMOS 6502 provides this addressing mode for `JMP`:

```asm
JMP (&0200)
```

The assembler emits the original NMOS `JMP (absolute)` instruction. The well-known NMOS page-boundary indirect-JMP hardware behaviour is a CPU characteristic, not changed by the assembler.

## Relative branches

```asm
loop:
    DEX
    BNE loop
```

Supported branch mnemonics are:

```text
BCC BCS BEQ BMI BNE BPL BVC BVS
```

The branch destination must be within the signed 8-bit relative range:

```text
-128 through +127 bytes from the address following the branch
```

An out-of-range branch is a build error.

---

# Zero-page and absolute address selection

For instructions supporting both zero-page and absolute forms, the assembler normally chooses zero page when the operand is known during pass 1 and is between `&00` and `&FF`.

For example:

```asm
LDA &F0
```

assembles as zero page.

## Four-digit hexadecimal forces absolute

A simple hexadecimal literal written with four or more digits deliberately requests absolute addressing:

```asm
LDA &00F0     ; absolute, not zero page
LDA $00F0     ; absolute, not zero page
```

This feature exists primarily for exact binary reconstruction, where a program may intentionally contain a three-byte absolute instruction even though the address lies in zero page.

## Explicit `.ZP` / `.Z`

Zero-page addressing can be forced with:

```asm
LDA.ZP pointer
LDA.Z pointer
```

## Explicit `.ABS` / `.A`

Absolute addressing can be forced with:

```asm
LDA.ABS pointer
LDA.A pointer
```

The `.A` suffix means **absolute**. It is unrelated to accumulator syntax; accumulator addressing is written using an operand of `A`, for example:

```asm
ASL A
```

## Forward-label consideration

When a forward-referenced operand is not yet known in pass 1, the assembler cannot infer that the final value will be in zero page. If the mnemonic has an absolute form, it therefore normally selects the absolute form.

For a forward label that must use zero page, write the intent explicitly:

```asm
LDA.ZP forward_zp_variable
```

Likewise, use `.ABS` when exact instruction width matters.

## 8-bit truncation

For immediate and zero-page-class instruction operands, values outside the normal 8-bit range are truncated to the low byte and generate a warning.

Use forced addressing carefully: `.ZP` does not turn an out-of-range address into a valid zero-page location; it requests an 8-bit operand encoding.

---

# Directives

Directive names are case-insensitive. Most can optionally be prefixed with a dot.

For example:

```asm
ORG &1900
.ORG &1900

BYTE 1,2,3
.BYTE 1,2,3
```

are accepted.

## `ORG`

```asm
ORG expression
```

Sets the current assembly address.

Example:

```asm
ORG &1900
```

The address must resolve during pass 1 and must lie in `&0000-&FFFF`.

Multiple `ORG` directives are allowed. Each disjoint emitted region becomes an output segment.

Example:

```asm
ORG &1900
code:
    RTS

ORG &3000
screen_data:
    EQUB 1,2,3,4
```

Overlapping emitted regions are rejected during pass 2.

If no `ORG` appears, assembly begins at `&0000` and the assembler emits a warning.

---

## `EQUB`, `BYTE`, `DB`

Aliases:

```text
EQUB
BYTE
.BYTE
DB
```

Syntax:

```asm
EQUB item [, item ...]
```

Each numeric expression emits one byte. Strings emit all their characters.

Examples:

```asm
EQUB &00,&01,&FE,&FF
BYTE 10,20,30
DB <table,>table
EQUB "HELLO",13,0
```

Numeric values are emitted as their low eight bits.

---

## `EQUS`, `TEXT`, `ASCII`

Aliases:

```text
EQUS
TEXT
.TEXT
ASCII
```

Syntax:

```asm
EQUS string [, string ...]
```

Every argument must be a quoted string.

Examples:

```asm
EQUS "HELLO"
.TEXT "GAME ","OVER"
ASCII "BBC MICRO"
```

No terminator is added automatically.

---

## `EQUW`, `WORD`, `DW`

Aliases:

```text
EQUW
WORD
.WORD
DW
```

Syntax:

```asm
EQUW expression [, expression ...]
```

Each value emits a 16-bit **little-endian** word.

Example:

```asm
EQUW &1234
```

emits:

```text
34 12
```

A pointer table can therefore be written:

```asm
WORD handler0,handler1,handler2
```

---

## `EQUD`, `DWORD`, `DD`

Aliases:

```text
EQUD
DWORD
.DWORD
DD
```

Syntax:

```asm
EQUD expression [, expression ...]
```

Each value emits a 32-bit **little-endian** value.

Example:

```asm
EQUD &12345678
```

emits:

```text
78 56 34 12
```

---

## `SKIP`, `DS`, `RES`

Aliases:

```text
SKIP
DS
RES
```

Syntax:

```asm
SKIP count [, fill_byte]
```

The directive emits `count` bytes. The default value is zero.

Examples:

```asm
SKIP 32
DS 256,&FF
RES buffer_size,&EA
```

**This assembler's reserve directives emit bytes.** They do not create uninitialised holes.

`count` must be known during pass 1 and cannot be negative.

---

## `FILL`

```asm
FILL count [, fill_byte]
```

Emits `count` copies of `fill_byte`, defaulting to zero.

Examples:

```asm
FILL 16
FILL 100,&FF
```

`FILL` is functionally equivalent to `SKIP`/`DS`/`RES` in the current assembler; the separate spelling is provided for source readability.

---

## `ALIGN`

```asm
ALIGN boundary [, fill_byte]
```

Advances the current assembly address to the next multiple of `boundary`, emitting fill bytes as necessary.

The default fill byte is zero.

Examples:

```asm
ALIGN 256
ALIGN &100,&FF
ALIGN 16,&EA
```

If the current address is already correctly aligned, no bytes are emitted.

`boundary` must be greater than zero and must resolve during pass 1.

---

## `ASSERT`

```asm
ASSERT expression
```

The expression is evaluated during pass 2. Assembly fails if it evaluates to zero.

Examples:

```asm
ASSERT end_of_game <= &3000
ASSERT table_size = 32
```

Note that the expression language does not currently provide comparison operators such as `==` or `<=`; the first example above is illustrative of intent but **not valid syntax in version 1.1.0**. In version 1.1.0, assertions must use the arithmetic/bitwise expression operators actually supported by the parser.

Valid examples include:

```asm
ASSERT table_size
ASSERT end_of_game - start_of_game
ASSERT expected_value ^ actual_value
```

`ASSERT 0` always fails and any non-zero result succeeds.

---

## `INCLUDE`

```asm
INCLUDE "filename"
```

or:

```asm
.INCLUDE "filename"
```

See [Including multiple source files](#including-multiple-source-files).

---

## `EQU`

`EQU` is a symbol-definition directive rather than emitted data.

Accepted forms include:

```asm
screen EQU &3000
EQU screen,&3000
.EQU screen,&3000
```

The simpler assignment form is also supported:

```asm
screen = &3000
```

---

# Including multiple source files

`INCLUDE` allows a project to be separated into modules while retaining one global symbol table.

Example `main.asm`:

```asm
INCLUDE "constants.inc"

ORG &1900
INCLUDE "graphics.asm"
INCLUDE "sound.asm"
```

All referenced files must already be part of the files loaded into the browser project. The application deliberately does not use hidden filesystem or network access to fetch includes.

`INCLUDE` is expanded recursively before pass 1.

## Filename resolution

The assembler first looks for the exact loaded filename/path specified by `INCLUDE`.

If that is not found, it falls back to comparing the basename of loaded files. This allows a source containing:

```asm
INCLUDE "graphics.asm"
```

to work when a folder picker supplied the loaded name as:

```text
project/src/graphics.asm
```

For unambiguous projects, avoid loading two different files with the same basename when relying on this fallback behavior.

## Recursive includes

Recursive include loops are detected and rejected.

For example:

```text
a.asm includes b.asm
b.asm includes a.asm
```

produces a preprocess error rather than infinite recursion.

## Global symbols

All included files share one global case-insensitive symbol namespace.

There are currently no local module namespaces. Use unique labels across modules.

---

# Official NMOS 6502 instructions

The complete documented NMOS 6502 mnemonic set supported by the assembler is:

```text
ADC AND ASL
BCC BCS BEQ BIT BMI BNE BPL BRK BVC BVS
CLC CLD CLI CLV CMP CPX CPY
DEC DEX DEY
EOR
INC INX INY
JMP JSR
LDA LDX LDY LSR
NOP
ORA
PHA PHP PLA PLP
ROL ROR RTI RTS
SBC SEC SED SEI STA STX STY
TAX TAY TSX TXA TXS TYA
```

The assembler validates addressing modes against the actual NMOS 6502 opcode table. For example, `STY address,Y` is rejected because the NMOS 6502 has no such instruction form.

This is **not a 65C02 assembler**. Instructions added by later CMOS processors are not part of the supported instruction set.

---

# Undocumented NMOS 6502 instructions

## Important terminology and hardware warning

The original NMOS 6502 decodes many byte values that MOS Technology did not document as supported instructions. These are variously called:

```text
undocumented opcodes
unofficial opcodes
illegal opcodes
unsupported opcodes
```

Many are deterministic consequences of the NMOS 6502's internal decode logic and are used by real commercial software. Others are electrically unstable and cannot truthfully be assigned one portable, guaranteed behavior across all physical NMOS chips, temperatures, manufacturers and surrounding bus conditions.

This assembler's responsibility is to **emit the requested opcode bytes**. It does not emulate or simulate the CPU. The behavioral descriptions below explain what a genuine NMOS 6502 normally does when those bytes execute.

Do not assume undocumented instructions behave the same way on a 65C02, 65C816 or other 6502-family CPU. Many later processors reused formerly unused opcode values for entirely different instructions.

For byte-perfect archaeology, an unsupported alternative encoding can always be emitted explicitly using `EQUB`.

## Flag notation

The normal 6502 flags referred to below are:

```text
N  negative
V  overflow
D  decimal mode
I  interrupt disable
Z  zero
C  carry
```

When the description says an operation behaves as two ordinary instructions combined, the later ALU operation normally determines the final `N`/`Z` and related flags, while a shift/rotate may supply carry into the second operation.

---

## Stable read-modify-write combinations

These are among the most useful undocumented instructions and are generally considered stable on NMOS 6502-family silicon.

### `SLO` — ASL then ORA

Operation:

```text
memory = memory << 1
C      = old memory bit 7
A      = A OR memory
N,Z    = result in A
```

Conceptually:

```asm
ASL memory
ORA memory
```

The shift is a genuine read-modify-write memory operation. Final `C` comes from the shift; final `N` and `Z` come from the ORA result. `V` is unchanged.

Supported encodings:

| Addressing mode | Syntax example | Opcode |
|---|---|---:|
| `(zp,X)` | `SLO (&40,X)` | `&03` |
| zero page | `SLO &40` | `&07` |
| absolute | `SLO &4000` | `&0F` |
| `(zp),Y` | `SLO (&40),Y` | `&13` |
| zero page,X | `SLO &40,X` | `&17` |
| absolute,Y | `SLO &4000,Y` | `&1B` |
| absolute,X | `SLO &4000,X` | `&1F` |

---

### `RLA` — ROL then AND

Operation:

```text
oldC   = C
C      = old memory bit 7
memory = (memory << 1) OR oldC
A      = A AND memory
N,Z    = result in A
```

Conceptually:

```asm
ROL memory
AND memory
```

Final `C` comes from the rotate. Final `N` and `Z` come from the AND result. `V` is unchanged.

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&23` |
| zero page | `&27` |
| absolute | `&2F` |
| `(zp),Y` | `&33` |
| zero page,X | `&37` |
| absolute,Y | `&3B` |
| absolute,X | `&3F` |

---

### `SRE` — LSR then EOR

Operation:

```text
C      = old memory bit 0
memory = memory >> 1
A      = A XOR memory
N,Z    = result in A
```

Conceptually:

```asm
LSR memory
EOR memory
```

Final `C` comes from the shift. Final `N` and `Z` come from EOR. `V` is unchanged.

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&43` |
| zero page | `&47` |
| absolute | `&4F` |
| `(zp),Y` | `&53` |
| zero page,X | `&57` |
| absolute,Y | `&5B` |
| absolute,X | `&5F` |

---

### `RRA` — ROR then ADC

Operation:

```text
rotate memory right through C
then ADC the rotated memory value into A
```

More explicitly in binary mode:

```text
oldC   = C
newC   = old memory bit 0
memory = (oldC << 7) OR (memory >> 1)
ADC uses newC as its carry input
A      = A + memory + newC
```

This is important: the carry produced by the `ROR` becomes the carry input to the `ADC`. The final `N`, `V`, `Z` and `C` are those produced by the ADC operation.

If the processor's decimal flag is set, the ADC portion follows the NMOS 6502's decimal arithmetic behavior. Code relying on undocumented instructions in decimal mode should be tested on the intended hardware.

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&63` |
| zero page | `&67` |
| absolute | `&6F` |
| `(zp),Y` | `&73` |
| zero page,X | `&77` |
| absolute,Y | `&7B` |
| absolute,X | `&7F` |

---

### `DCP` — DEC then CMP

Operation:

```text
memory = memory - 1
compare A with the new memory value
```

Conceptually:

```asm
DEC memory
CMP memory
```

The final flags are the comparison flags:

```text
C = 1 when A >= memory unsigned
Z = 1 when A == memory
N = bit 7 of A - memory
```

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&C3` |
| zero page | `&C7` |
| absolute | `&CF` |
| `(zp),Y` | `&D3` |
| zero page,X | `&D7` |
| absolute,Y | `&DB` |
| absolute,X | `&DF` |

---

### `ISC` / `ISB` — INC then SBC

`ISC` and `ISB` are aliases in this assembler and emit the same bytes.

Operation:

```text
memory = memory + 1
A = A - memory - (1-C)
```

Conceptually:

```asm
INC memory
SBC memory
```

Final `N`, `V`, `Z` and `C` are those produced by SBC. The decimal flag, when set on a real NMOS 6502, affects the SBC part according to the processor's decimal-mode rules.

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&E3` |
| zero page | `&E7` |
| absolute | `&EF` |
| `(zp),Y` | `&F3` |
| zero page,X | `&F7` |
| absolute,Y | `&FB` |
| absolute,X | `&FF` |

---

## Stable load/store combinations

### `SAX` — store A AND X

Operation:

```text
memory = A AND X
```

`A` and `X` are unchanged. Status flags are unchanged.

This can be viewed as the store-side combination of `STA` and `STX`.

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&83` |
| zero page | `&87` |
| absolute | `&8F` |
| zero page,Y | `&97` |

---

### `LAX` — load A and X together

Operation:

```text
A = memory
X = memory
N,Z set from the loaded value
```

Conceptually:

```asm
LDA memory
TAX
```

Supported encodings:

| Addressing mode | Opcode |
|---|---:|
| `(zp,X)` | `&A3` |
| zero page | `&A7` |
| absolute | `&AF` |
| `(zp),Y` | `&B3` |
| zero page,Y | `&B7` |
| absolute,Y | `&BF` |

The unstable immediate opcode sometimes called `LAX #imm`, `LXA` or `OAL` is **not** selected by the `LAX` mnemonic in this assembler. Emit its byte explicitly with `EQUB` only if you deliberately need it.

---

### `LAS` — load A, X and stack pointer

Supported form:

```asm
LAS address,Y
```

Opcode:

```text
&BB
```

Operation:

```text
value = memory AND S
A = value
X = value
S = value
N,Z set from value
```

Other flags are unchanged.

---

# Immediate undocumented ALU instructions

## `ANC #imm`

Opcode emitted by this assembler:

```text
&0B
```

Operation:

```text
A = A AND immediate
N,Z set from A
C = bit 7 of A
```

Thus carry becomes a copy of the result's sign bit.

A second real-NMOS encoding, `&2B`, is often also called `ANC`, but this assembler deliberately chooses `&0B`. Use `EQUB &2B,value` if the exact alternative encoding is required.

---

## `ALR #imm` / `ASR #imm`

`ALR` and `ASR` are aliases in this assembler.

Opcode:

```text
&4B
```

Operation:

```text
temporary = A AND immediate
C = temporary bit 0
A = temporary >> 1
N = 0
Z set from A
```

Conceptually:

```asm
AND #imm
LSR A
```

`V` is unchanged.

---

## `ARR #imm`

Opcode:

```text
&6B
```

In ordinary binary mode the useful description is:

```text
temporary = A AND immediate
A = (C << 7) OR (temporary >> 1)
N = A bit 7
Z = 1 if A == 0
C = A bit 6
V = A bit 6 XOR A bit 5
```

The unusual `C` and `V` behavior distinguishes `ARR` from a simple `AND` followed by an ordinary `ROR A`.

The NMOS decimal-mode behavior of `ARR` is more complicated and is not well represented by the simple binary formula above. Avoid depending on it unless specifically targeting and testing the intended NMOS hardware.

---

## `AXS #imm` / `SBX #imm`

`AXS` and `SBX` are aliases.

Opcode:

```text
&CB
```

Operation:

```text
temporary = A AND X
X = temporary - immediate
```

The subtraction is performed as if there were no borrow input. `A` is unchanged.

Flags:

```text
N = result bit 7
Z = 1 if X == 0
C = 1 if temporary >= immediate (no unsigned borrow)
```

`V` is not meaningfully updated by the operation.

---

# Unstable undocumented instructions

The following instructions are supported because they are real NMOS opcode encodings and are useful for reverse engineering, but they should **not** be treated as portable deterministic programming primitives.

Their behavior involves internal bus conflicts and/or the peculiar indexed-store circuitry. Physical behavior can vary with chip revision and operating conditions.

The assembler emits the documented byte pattern shown here; it does not attempt to decide whether using the instruction is safe on a particular processor.

## `XAA #imm`

Opcode:

```text
&8B
```

Also known as `ANE` in some references.

There is no single fully portable mathematical definition for a physical NMOS 6502. A common approximate model is:

```text
A = (A OR magic_value) AND X AND immediate
```

where the effective `magic_value` can depend on the particular silicon and electrical conditions. Some simplified emulators model it closer to:

```text
A = A AND X AND immediate
```

`N` and `Z` follow the resulting accumulator value.

**Do not use XAA when deterministic cross-machine behavior is required.** It is included primarily so existing binaries and deliberately hardware-specific source can be represented symbolically.

---

## Store-high family: common notation

For the instructions below, let:

```text
base = the unindexed 16-bit address/pointer
H    = high_byte(base) + 1
```

The common non-page-crossing behavior is described using `H`. However, indexed page crossings can also corrupt the high byte of the actual write address. This is part of the hardware quirk, not an assembler transformation.

Do not use these instructions to write memory-mapped I/O or critical memory unless their behavior has been verified on the target hardware.

---

## `AHX` / `SHA`

`AHX` and `SHA` are aliases.

Supported forms:

| Addressing mode | Opcode |
|---|---:|
| `(zp),Y` | `&93` |
| absolute,Y | `&9F` |

Common NMOS behavior without the problematic page-cross case:

```text
memory = A AND X AND H
```

where `H` is one greater than the high byte associated with the base address.

On indexed page crossings, the high byte of the effective write address may itself be affected by the value being stored. Exact behavior is hardware-dependent enough that this opcode is classified as unstable.

Flags are not intentionally modified.

---

## `SHY absolute,X`

Opcode:

```text
&9C
```

Common non-page-crossing behavior:

```text
memory = Y AND H
```

where `H = high_byte(base) + 1`.

On a page crossing, the write-address high byte may be corrupted according to the same NMOS store-high mechanism.

Flags are unchanged.

---

## `SHX absolute,Y`

Opcode:

```text
&9E
```

Common non-page-crossing behavior:

```text
memory = X AND H
```

where `H = high_byte(base) + 1`.

Indexed page crossings can alter the high byte of the write address.

Flags are unchanged.

---

## `TAS absolute,Y` / `SHS absolute,Y`

`TAS` and `SHS` are aliases.

Opcode:

```text
&9B
```

Common operation:

```text
S = A AND X
memory = S AND H
```

where `H = high_byte(base) + 1`.

The same page-crossing address corruption caveat applies as for `AHX`, `SHX` and `SHY`.

Status flags are unchanged, but the stack pointer `S` is modified.

---

# `KIL` / `JAM`

`KIL` and `JAM` are aliases in this assembler.

The assembler emits:

```text
&02
```

On a genuine NMOS 6502 this enters a locked internal processor state: normal instruction execution stops and the CPU does not recover through an ordinary interrupt. A hardware **RESET** is required to resume useful execution.

This is not a sleep instruction and not an ordinary infinite loop. Use it only deliberately.

Real NMOS 6502s have several byte values belonging to this JAM/KIL family. Version 1.1.0 chooses `&02` for the mnemonic. Other exact encodings can be emitted with `EQUB`.

---

# Undocumented NOP forms

In addition to official implied `NOP` (`&EA`), the assembler supports one selected undocumented NOP encoding for several operand forms:

| Syntax class | Selected opcode |
|---|---:|
| `NOP` implied | `&EA` — official NOP |
| `NOP #imm` | `&80` |
| `NOP zp` | `&04` |
| `NOP zp,X` | `&14` |
| `NOP abs` | `&0C` |
| `NOP abs,X` | `&DC` |

The `&DC` absolute-X form is the assembler's selected encoding for this addressing class. Other real-NMOS encodings exist; use `EQUB` when an exact alternative byte value is required.

Operand-bearing NOPs do not alter programmer-visible registers or flags, but they still perform instruction fetches and relevant memory/dummy-read bus activity. Consequently, they are **not necessarily side-effect-free when their operand touches memory-mapped hardware**.

There are several alternative real-NMOS NOP byte values for many of these addressing modes. Use `EQUB` when an exact alternative encoding matters.

Because `NOP` is also an official mnemonic, the application's **undocumented NMOS opcodes** checkbox does not currently reject these alternate NOP addressing forms. The checkbox rejects the separately named undocumented mnemonics listed above.

---

# Summary of undocumented mnemonics supported

| Mnemonic | Aliases | Core behavior | Stability |
|---|---|---|---|
| `SLO` | — | `ASL memory`, then `ORA memory` | stable NMOS |
| `RLA` | — | `ROL memory`, then `AND memory` | stable NMOS |
| `SRE` | — | `LSR memory`, then `EOR memory` | stable NMOS |
| `RRA` | — | `ROR memory`, then `ADC memory` | stable NMOS |
| `SAX` | — | store `A AND X` | stable NMOS |
| `LAX` | — | load same value into `A` and `X` | stable supported memory forms |
| `DCP` | — | `DEC memory`, then `CMP memory` | stable NMOS |
| `ISC` | `ISB` | `INC memory`, then `SBC memory` | stable NMOS |
| `ANC` | — | `AND #imm`, then copy `N` to `C` | generally stable selected encoding |
| `ALR` | `ASR` | `AND #imm`, then `LSR A` | generally stable |
| `ARR` | — | `AND`, rotate, special `C/V` rules | binary behavior established; decimal caveat |
| `AXS` | `SBX` | `X=(A AND X)-imm` | generally stable |
| `LAS` | — | `A=X=S=memory AND S` | generally stable |
| `XAA` | — | unstable immediate bus-conflict operation | unstable |
| `AHX` | `SHA` | store `A AND X AND H` with address quirks | unstable |
| `SHY` | — | store `Y AND H` with address quirks | unstable |
| `SHX` | — | store `X AND H` with address quirks | unstable |
| `TAS` | `SHS` | `S=A AND X`; store `S AND H` with quirks | unstable |
| `KIL` | `JAM` | lock CPU until reset | deterministic halt family |

---

# Exact undocumented opcode table used by this assembler

A blank cell means that the assembler does not provide that mnemonic/addressing-mode combination directly.

| Mnemonic | `#imm` | `zp` | `zp,X` | `zp,Y` | `abs` | `abs,X` | `abs,Y` | `(zp,X)` | `(zp),Y` | implied |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `SLO` | | `07` | `17` | | `0F` | `1F` | `1B` | `03` | `13` | |
| `RLA` | | `27` | `37` | | `2F` | `3F` | `3B` | `23` | `33` | |
| `SRE` | | `47` | `57` | | `4F` | `5F` | `5B` | `43` | `53` | |
| `RRA` | | `67` | `77` | | `6F` | `7F` | `7B` | `63` | `73` | |
| `SAX` | | `87` | | `97` | `8F` | | | `83` | | |
| `LAX` | | `A7` | | `B7` | `AF` | | `BF` | `A3` | `B3` | |
| `DCP` | | `C7` | `D7` | | `CF` | `DF` | `DB` | `C3` | `D3` | |
| `ISC` / `ISB` | | `E7` | `F7` | | `EF` | `FF` | `FB` | `E3` | `F3` | |
| `ANC` | `0B` | | | | | | | | | |
| `ALR` / `ASR` | `4B` | | | | | | | | | |
| `ARR` | `6B` | | | | | | | | | |
| `XAA` | `8B` | | | | | | | | | |
| `AXS` / `SBX` | `CB` | | | | | | | | | |
| `LAS` | | | | | | | `BB` | | | |
| `AHX` / `SHA` | | | | | | | `9F` | | `93` | |
| `SHY` | | | | | | `9C` | | | | |
| `SHX` | | | | | | | `9E` | | | |
| `TAS` / `SHS` | | | | | | | `9B` | | | |
| `KIL` / `JAM` | | | | | | | | | | `02` |

Hexadecimal values in this table are raw opcode bytes.

---

# Build output

A successful assembly produces two related views of the output.

## Segments

Every contiguous address range containing emitted bytes is a segment.

Example source:

```asm
ORG &1000
EQUB 1,2,3

ORG &2000
EQUB 4,5
```

creates two segments:

```text
&1000-&1002   3 bytes
&2000-&2001   2 bytes
```

Saving an individual segment downloads exactly those bytes.

## Flat binary

**Save binary** constructs one binary beginning at the lowest emitted address and ending at the highest emitted address.

For the example above, it spans:

```text
&1000-&2001
```

and the unused addresses between the two segments are filled with the configured **gap fill** byte.

The build summary distinguishes:

```text
Emitted bytes   bytes actually produced by instructions/directives
Flat span       total lowest-to-highest address span including gaps
```

## Origin and end

`Origin` is the start address of the lowest emitted segment.

`End` is the final address of the highest emitted segment.

These addresses are not stored as a header in `.bin` downloads. Binary files are raw bytes. Record load/execute metadata separately when required by your target platform.

## SHA-256

The browser calculates SHA-256 over the generated flat binary when Web Crypto is available. This is particularly useful for regression tests and byte-exact reverse-engineering projects.

---

# Listing format

A listing line has the general form:

```text
ADDRESS  BYTES                    file:line  original source
```

For example:

```text
1900  A2 00                     main.asm:5  LDX #0
1902  BD 10 19                  main.asm:7  LDA message,X
```

Only statements which emit bytes appear as emitted listing entries.

The listing can be copied from the UI or downloaded as a `.lst` file.

---

# Symbol-map format

The downloaded symbol map is sorted by address and uses:

```text
AAAA symbol_name
```

For example:

```text
1900 start
1910 message
FFEE OSWRCH
```

The map is intended to be human-readable and easy to process with scripts.

---

# Diagnostics

The assembler reports the source file and line wherever possible.

Typical errors include:

```text
unknown opcode/directive
unknown symbol
unsupported addressing mode
duplicate/redefined symbol
unresolved constant assignment
branch out of range
recursive INCLUDE
INCLUDE file not loaded
ORG outside the 16-bit address space
negative reserve/fill size
invalid alignment boundary
output overlap
output exceeds &FFFF
ASSERT failure
```

Warnings include:

```text
no ORG directive
8-bit operand truncation
```

Clicking an error or warning in the Build tab attempts to select the corresponding source line.

Assembly output is not considered successful when any error exists. Save-binary/listing/symbol controls are enabled only for successful builds.

---

# Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+Enter` / `Cmd+Enter` | Assemble |
| `Ctrl+S` / `Cmd+S` | Save source |
| `Ctrl+Shift+S` / `Cmd+Shift+S` | Save As… |

---

# Known limitations and deliberate design choices

## NMOS 6502 only

The opcode model is the original NMOS 6502. It is not currently a 65C02, 65C816 or 6510-specific assembler.

## 16-bit address space

Assembly addresses are limited to `&0000-&FFFF`. There is no bank-aware linker or object-file format.

## No linker/object files

All source is assembled as one absolute project. `INCLUDE` is textual source inclusion, not object linking.

## Global symbol namespace

All labels are global and case-insensitive. Dot-prefixed labels do not create local scope.

## No macros or conditional assembly

Version 1.1.0 does not currently provide macro definitions, `IF`/`ELSE` conditional assembly, repeat blocks or source-time loops.

## No comparison/logical expression operators

The expression parser currently supports arithmetic, shifts and bitwise operators but not relational syntax such as:

```text
== != < <= > >=
```

Note also that `<expr` and `>expr` are already used as unary low-byte/high-byte operators.

## No automatic branch relaxation

An out-of-range conditional branch is an error. The assembler does not automatically rewrite it as an inverted branch plus `JMP`.

## No automatic local filesystem include access

For browser security and predictable offline behavior, included files must have been explicitly loaded into the project.

## Browser saves are downloads

The browser UI does not silently overwrite the original source file. **Save source** and **Save As…** create downloads. This affects the source program being edited; the assembler application itself remains the single `BBC_6502_Web_Assembler.html` file.

## Zero-page choice is made during pass 1

Unknown forward operands cannot automatically become shorter zero-page instructions later. Use `.ZP` where a forward symbol is known by design to reside in zero page.

## Exact alternative undocumented encodings

For undocumented instructions that have multiple possible real-NMOS byte encodings, the assembler chooses one defined encoding per supported mnemonic/mode. Use `EQUB` for a different exact byte pattern.

## Unstable illegal instructions are inherently unstable

No assembler can make `XAA` or the store-high family electrically deterministic. Supporting a mnemonic means the correct opcode byte can be emitted; it is not a promise that every chip will execute it identically.

---

# Practical examples

## Table of pointers

```asm
ORG &2000

handlers:
    EQUW handler_a,handler_b,handler_c

handler_a:
    RTS

handler_b:
    RTS

handler_c:
    RTS
```

## Low/high pointer bytes

```asm
pointer:
    EQUB <message,>message

message:
    EQUS "HELLO"
    EQUB 0
```

## Multiple output regions

```asm
ORG &1000
bootstrap:
    JMP main

ORG &3000
main:
    RTS
```

The Segments tab will show two ranges. The flat binary fills `&1003-&2FFF` using the configured gap-fill byte.

## Force original absolute encoding

```asm
variable = &F0

LDA variable        ; normally zero page
LDA.ABS variable    ; deliberately absolute
LDA &00F0           ; four-digit literal also forces absolute
```

## Explicit zero-page forward reference

```asm
ORG &1000

    LDA.ZP workspace
    RTS

workspace = &70
```

## Undocumented opcode

```asm
ORG &1900

    LDA #&F0
    LDX #&0F
    SAX &70         ; stores A AND X = 0
    RTS
```

## Binary layout check

```asm
ORG &2000
start:
    FILL 16,&FF
end:

size = end-start
ASSERT size
```

---

# Undocumented-opcode references

The behavioral descriptions in this README are based on established NMOS 6502 reverse engineering and physical/switch-level investigation. Useful further reading includes:

- NESdev Wiki — CPU unofficial opcodes: <https://www.nesdev.org/wiki/CPU_unofficial_opcodes>
- NESdev Wiki — Programming with unofficial opcodes: <https://www.nesdev.org/wiki/Programming_with_unofficial_opcodes>
- NESdev Wiki — Visual6502 unsupported opcodes: <https://www.nesdev.org/wiki/Visual6502wiki/6502_Unsupported_Opcodes>
- NESdev Wiki — XAA/ANE opcode `&8B`: <https://www.nesdev.org/wiki/Visual6502wiki/6502_Opcode_8B_%28XAA%2C_ANE%29>
- NESdev Wiki — official instruction reference: <https://www.nesdev.org/wiki/Instruction_reference>

Names for undocumented opcodes are not official and differ between assemblers and references. This assembler supports several common aliases (`ISB`, `ASR`, `SBX`, `SHA`, `SHS`, `JAM`) to reduce that ambiguity.

---

# Version

Current documented assembler version:

```text
1.1.0
```

Version 1.1 added:

- **Save As…** for source files;
- `Ctrl/Cmd+Shift+S` for Save As;
- deliberately unminified, human-readable JavaScript;
- the **(ChatGPT assisted)** application credit.

---

# Credit

**BBC 6502 Web Assembler (ChatGPT assisted)** was developed with ChatGPT assistance as a general-purpose browser-based assembler and development tool for BBC Micro and NMOS 6502 software.

