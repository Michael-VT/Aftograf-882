# Autograf-882 Debug Simulator — Checkpoint

**Date:** 2026-07-04  
**State:** WORKING — CPU steps, disassembly renders, settings panel works, plotter draws.

## Project Structure

```
./
├── sim/                          ← Browser debug simulator
│   ├── bundle.js                 Single-file JS (concat of 4 modules)
│   ├── settings.js               SettingsManager + defaults + renderPanel()
│   ├── memory.js                 MMU: ROM(24KB) + RAM(1KB) + I/O
│   ├── cpu8080.js                Full 8080/К580ИК80 emulator, 256 opcodes
│   ├── main.js                   App controller — UI, plotter, disasm, I/O devices
│   ├── index.html                Layout: 3-column (debug | disasm+mem | plotter)
│   ├── styles.css                Dark theme + A4 portrait plotter
│   └── firmware.bin              24KB — concatenated 3x D2764A EPROMs
├── disasm8080.py                 Python recursive disassembler
├── autograf-882-disassembly.asm  Full listing (17792 lines)
├── Autograf-882-*Chip*.bin       3× 8KB ROM dumps
├── 01_Plotter-*-Schematic.pdf    Schematic (reverse-engineered)
└── CHECKPOINT.md                 This file
```

## Architecture (3-column layout)

```
┌──────────────────────────────────────────────────────────────┐
│ Header: status + PC + [⚙ Settings]                          │
│         [↺Reset][→Step][▶Run][⏸Pause] Speed:[===] [📂ROM] │
├────────┬───────────────────────────┬────────────────────────┤
│ LEFT   │ CENTER                    │ RIGHT                  │
│ 180px  │ Disasm (flex 1)           │ Plotter 400px          │
│ CPU    │  6 columns:               │ Canvas 600×848         │
│ regs   │  ● addr hex mnem op annot │ Paper background       │
│ flags  │                           │ (A4 portrait 1:√2)     │
│ Current│ Memory (fixed)            │ Grid + pen colors      │
│ instr  │  Address + hex dump       │                        │
│ Stack  │                           │                        │
│ Pointers│                          │                        │
│ I/O    │                           │                        │
└────────┴───────────────────────────┴────────────────────────┘
```

## Disassembly columns

```
● 0000  F3       DI
  0001  3E 80    MVI A,80
  0003  32 03 E4 STA E403     ; [E403]=$00
  000F  C2 29 02 JNZ 0229     ; → $0229 ($17)
```

- Column 1: breakpoint marker (● / space)
- Column 2: address (4-digit hex)
- Column 3: instruction bytes (left-padded)
- Column 4: mnemonic
- Column 5: operands
- Column 6: annotation — jump target, memory access, port name

## Features Working

- [x] CPU step / run / pause / reset
- [x] Speed control (100Hz to 1MHz)
- [x] Register display (A,B,C,D,E,H,L,SP,PC,flags)
- [x] Disassembly with follow-PC scrolling
- [x] Breakpoints (click line to toggle, pause on hit)
- [x] Memory dump (any address, auto-refresh)
- [x] Stack view (8 words from SP, →SP marker)
- [x] Pointer view (HL→, DE→, BC→, SP→, PC→)
- [x] I/O panel (PPI1, PPI2, PIT, USART)
- [x] Plotter canvas (paper bg, grid, pen colors, position)
- [x] Firmware auto-load (`firmware.bin` or 3 chip files)
- [x] Settings panel (overlay):
  - Load ROM at configurable address
  - Chip offset configuration ($0000/$2000/$4000)
  - Plotter variable addresses (X_POS, Y_POS, PEN_STATE, PEN_COLOR)
  - Custom watch variables (add/remove/read)
  - Save/reset configuration (localStorage)

## Settings — RAM Watch Addresses

Default addresses (from firmware analysis):

| Key        | Address | Description                       |
|-----------|---------|-----------------------------------|
| X_POS_LO  | $6180   | X coordinate low byte (SHLD tgt)  |
| X_POS_HI  | $6181   | X coordinate high byte            |
| Y_POS_LO  | $61CA   | Y coordinate low byte (LHLD src)  |
| Y_POS_HI  | $61CB   | Y coordinate high byte            |
| PEN_STATE | $63F0   | Bit 0 = pen down (1) / up (0)    |
| PEN_COLOR | $61E8   | Pen number 0–6                   |

These are configurable via ⚙ Settings → Переменные плоттера.

## How to Run

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
# → http://localhost:8080/sim/
```

Firmware auto-loads on page load (look for green status message).

## Known Issues

1. Settings button sometimes unresponsive on first load — hard refresh fixes
2. Memory dump shows zeros until firmware writes to RAM ($6000+)
3. Plotter canvas blank until firmware sends stepper commands
4. No INTR/interrupt handling in CPU emulator
5. I/O device stubs are minimal (no real PIT counting, USART loopback)

## Next Steps / Roadmap

1. **Label mapping** — import labels from `.asm` listing into disassembly
2. **Step-back** — reverse step / undo last N instructions
3. **Register watchpoints** — break on register/value change
4. **Memory editor** — poke values from UI
5. **Export trace** — log execution to file
6. **I/O accuracy** — proper PIT interrupt timing, USART flow control
7. **Font table viewer** — visualize character data at $5E00-$5FFF
8. **Assembly export** — reassemble modified ROM from simulator state
