# Autograf-882 Debug Simulator — Checkpoint

**Date:** 2026-07-14  
**State:** STABLE — v1.0.11, clippy-clean, all bugs fixed, 37/37 tests parallel.

## Version Convention

**Each fix bumps the PATCH version** (e.g. 1.0.8 → 1.0.9 → 1.0.10).  
Bump until all known bugs are resolved and the simulator is stable.


## Project Structure

```
./
├── rust/                          ← Native GUI (Rust/egui) — PRIMARY
│   ├── Cargo.toml
│   ├── Cargo.lock
│   ├── build.rs                   Firmware embedder
│   ├── TESTS.md                   Test documentation
│   ├── src/
│   │   ├── main.rs                Entry point
│   │   ├── app.rs                 Main application (UI, stepping, callbacks)
│   │   ├── cpu.rs                 Intel 8080 CPU emulator
│   │   ├── memory.rs              MMU: ROM(24KB) + RAM(2KB) + I/O
│   │   ├── disasm.rs              Disassembler
│   │   ├── plotter.rs             XY plotter simulation
│   │   ├── hpgl.rs                HPGL parser
│   │   ├── ppi8255.rs             K580VV55A (PPI)
│   │   ├── pit8253.rs             K580VI53 (PIT)
│   │   ├── usart8251.rs           K580VV51A (USART)
│   │   ├── settings.rs            Configuration
│   │   └── session.rs             Save/load state
│   └── assets/firmware.bin        24KB firmware image
├── sim/                           ← Browser debug simulator (legacy)
│   ├── bundle.js
│   ├── main.js, cpu8080.js, memory.js
│   └── firmware.bin
├── docs/                          ← Documentation & datasheets
├── *.hpgl                         ← Sample HPGL plot files
├── README.*.md                    ← Project docs (6 languages)
└── CHECKPOINT.md                  ← This file
```

## Architecture (3-column layout)

```
┌──────────────────────────────────────────────────────────────┐
│ Header: status + PC + shortcuts + [?] [⚙]                   │
│         [↺Reset][→Step][▶Run][⏸Pause] Speed:[===] [📂ROM] │
├────────┬───────────────────────────┬────────────────────────┤
│ LEFT   │ CENTER                    │ RIGHT (A4)             │
│ 200px  │ Disasm (flex 1)           │ Canvas fills height    │
│ CPU    │  6 columns: addr hex mnem │ A4 portrait 1:√2       │
│ regs   │  op annot (follow PC)     │ Grid + pen colors      │
│ flags  │ Scrollable memory (64KB)  │ Clear/Autofit buttons  │
│ Current│  — click byte to edit     │ HPGL load + progress   │
│ instr  │  region-colored bytes     │ Position / pen info    │
│ Stack  │  toolbar: addr+refresh    │                        │
│ (50w)  │  resizable splitter       │                        │
│ Pointers│                         │                        │
│ I/O    │                          │                        │
│ USART  │                          │                        │
│ (term) │                          │                        │
└────────┴───────────────────────────┴────────────────────────┘
```

## Features

### CPU Emulation
- Full К580ИК80А / Intel 8080 emulation — all 256 opcodes, table-driven
- Registers: A, B, C, D, E, H, L, SP, PC with inline editing
- Flags: S, Z, AC, P, CY — clickable toggle
- Interrupt handling (INTR with RST 7 vector)
- T-state cycle counting
- Speed: max (unlimited) through 100 Hz

### Memory
- ROM: 24KB at $0000-$5FFF (3× D2764A EPROMs)
- RAM: 1KB at $6000-$63FF (КР537РУ10)
- Memory-mapped I/O: PPI1, PPI2, PIT, USART
- Virtual-scrollable 64KB dump with byte editing
- Color-coded: ROM (grey), RAM (yellow), I/O (purple)
- HL pointer highlight
- Scroll, address entry, and auto-follow all work correctly

### Disassembler
- Hybrid recursive-descent from CPU opcode table
- 6 columns: BP, address, bytes, mnemonic, operands, annotation
- Follow-PC mode, virtual scroll, click BP, double-click jump
- Copy visible range to clipboard

### I/O Devices
- PPI8255 (КР580ВВ55А): 2 chips, 3 ports + control
- PIT8253 (КР580ВИ53): 3 × 16-bit counters
- USART8251 (КР580ВВ51А): RX/TX with XOn-XOff, interrupt

### Plotter
- XY stepper motor simulation from PPI port phases
- 7 pen colors, A4 portrait canvas (1:√2), Retina support
- Auto-scale grid, position cursor, pen tracking
- HPGL file loader (direct render + UART mode)

### USART Terminal
- Hex input, file upload with XOn-XOff pacing
- RX log with printable chars and hex fallback
- TXRDY/RXRDY status

### Session Save/Load
- Full CPU + RAM + breakpoints + plotter state
- Save as timestamped JSON, restore from file

### Help System
- `?` button + `?`/`/` keys → help overlay
- Keyboard shortcuts, mouse actions, file formats, tips

### Theme System
- Dark (Tokyo Night, default) and Light themes
- Toggle in Settings panel, persists to localStorage

### Settings Panel
- Watch variable addresses (X, Y, pen, color)
- Custom watch variables (1B/2B)
- ROM chip offsets, manual firmware load
- Theme selector
- All saved to localStorage

## Bug Fixes (v0.0.7)

| # | Bug | Fix |
|---|-----|-----|
| 1 | `tryAutoLoadROMs()` never called | Added call at end of main.js |
| 2 | Conditional CALL pushed 2 words | Removed extra pushWord() |
| 3 | Plotter used stale MMU after ROM reload | Added `plotter.mmu = this.mmu` |
| 4 | Opcode 0xcb = JMP in disasm (CPU = NOP) | Changed to NOP |
| 5 | Memory auto-jumped to 0x0000 each step | HL>0 guard, writeAddr≥0x6000 |
| 6 | Memory virtual scroll: centering cascade | Removed centering offset, added diff≥16 hysteresis |
| 7 | `#mem-container` missing `overflow-y: auto` | Added to CSS, spacer-based scroll |
| 8 | Unused `_firmwareLoaded` flag | Removed |
| 9 | Unused `pcBefore` variables | Removed |
| 10 | Dead code in ANA flag logic | Removed |
| 11 | `_renderDisasm(before)` with ignored arg | Fixed |

## Bug Fixes (v1.0.11)

| # | Bug | Fix |
|---|-----|-----|
| 1 | Tests failed in parallel (7/37) — shared `static mut TEST_MEM` | `thread_local!` per-thread memory |
| 2 | Memory viewer empty on Go/HL due to `scroll_to_rect` race | `ScrollArea::show_viewport()` with direct viewport |
| 3 | Plotter canvas scale changed on hover/click — `SidePanel` stored rect width feedback loop | `.exact_width(320.0)` breaks the loop; cached scale in struct |
| 4 | HPGL drawing jumped on mouse enter — `allocate_space`/`allocate_exact_size` triggered hover relayout | `allocate_space` + `painter_at` + fully inert `Sense` |

## How to Run

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
# → http://localhost:8080/sim/
```

Firmware (`firmware.bin`, 24KB) auto-loads on page start.

## Build bundle.js

```bash
cd sim && node build.js
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space / → | Step |
| R | Reset |
| F5 | Run / Pause |
| B | Breakpoint at PC |
| J | Jump PC to hovered address |
| ? / / | Open help |
| Esc | Close help / settings |

## Known Issues

1. I/O device stubs are simplified (no real PIT counting, PPI modes)
2. USART interrupt is a single RST 7 — no multi-vector support
3. No INTR timing accuracy (immediate dispatch)
4. Plotter canvas empty until firmware sends stepper commands
5. HPGL UART mode does not echo through firmware accurately yet

## Roadmap

1. **Label mapping** — import labels from `.asm` listing into disassembly
2. **Step-back** — undo last N instructions
3. **Conditional breakpoints** — break on register/value change
4. **Export trace** — log execution to file
5. **I/O accuracy** — proper PIT timing, PPI mode emulation
6. **Font table viewer** — visualize character data at $5E00-$5FFF
7. **Assembly export** — reassemble modified ROM
8. **Multiple installable themes** — user-customisable palette
