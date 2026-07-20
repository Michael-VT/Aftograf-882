# Session Handoff — 2026-07-20

## Current State: stable Go v1.0.18 baseline

Recent code commits:
```
0f87cfd  Add peripheral access breakpoints and explanations
696aa80  Shorten live hardware panel labels
2e781a2  Keep debugger splitter compact with hardware tab
84b5cc5  Add live keyboard and sensor simulation
2af124c  Avoid nested debugger panel scrolling
1a435e2  Refine debugger layout and preserve A4 plotter view
12b09ac  Restore memory colors and improve I/O navigation
19880e6  I/O tab with PPI/PIT/USART/external status
```

## Architecture (3-panel split)
```
┌──────────────────────────────────────────────────────────────┐
│ Toolbar: [Rst][Stp][Run][Pause] STOP Spd:[1x] [Save][Load][?]│
├──────────┬──────────────────────────┬───────────────────────┤
│ LEFT     │ CENTER                   │ RIGHT                 │
│ Tabs:    │ Disasm (top, 55%)        │ Plotter (A4 canvas)   │
│  CPU     │  BP ●, addr, hex, mnem  │ HPGL: Load ▶N ▶A Clr │
│  Stack   │ Memory (bottom, 45%)     │ X:0 Y:0 Pen:↑#1      │
│  BP      │  Addr + hex + ASCII      │ Progress bar          │
│  I/O     │  Click byte → edit       │                       │
│ USART    │                          │                       │
│ (Send)   │                          │                       │
└──────────┴──────────────────────────┴───────────────────────┘
```

## Left panel tabs

| Tab | Contents |
|-----|----------|
| Debug | CPU registers/flags, stack and breakpoints on one page |
| I/O | PPI1/PPI2 (ports + binary), PIT (3 counters), USART, external state and access breakpoint |
| Hardware | Live 6×2 keyboard matrix, X/Y limit switches, DIP inputs and PPI1.C2–C5 LEDs |
| USART | USART terminal and hexadecimal input |

## Key types & functions

```go
AftografApp{
    CPU, MMU, PPI1/2, PIT, USART, Plot, HPGL, Setts
    regEdit [6]*widget.Entry    // 0=A,1=B,2=C,3=D,4=E,5=SP
    regDisp [8]*widget.Label    // 0=A,1=BC,2=DE,3=HL,4=SP,5=PC,6=Flags,7=Cycles
    breakpoints map[uint16]bool
    insnIndex  []uint16         // linear-sweep instruction index
    pcInsnIdx  int              // index of current PC in insnIndex
}
syncUI()          → updates ALL registers, entries, flags, LEDs, disasm, mem, BP, PIO
refreshDisasm()   → rebuilds insnIndex from memory, scrolls to PC
refreshMem()      → refreshes memory grid
refreshStack()    → updates 24 stack-word labels
refreshBreakpoints() → rebuilds BP list from map
refreshPIO()      → rebuilds PPI/PIT/USART/External status
memJump(ad)       → scrolls memory to ad (2-phase: top then target)
```

## UI layout (MakeWindow)

- Toolbar: version + Rst/Stp/Run/Pause + status + speed + Save/Load/?
- Left: AppTabs(Debug|I/O|Hardware|USART), scrollable
- Center: VSplit(Disassembler card 55% / Memory card 45%)
- Right: Plotter (A4) with HPGL controls
- Offsets: left=0.17, center/right=0.6

## CPU Layout (Debug tab)
```
A:XX  | BC:XXXX        ← A entry + BC button
B:[00]| C:[00]         ← hex entries, OnSubmitted
D:[00]| E:[00]
HL:XXXX SP:[0000]      ← HL button + SP entry (HBox for proper width)
PC:XXXX T:12345
S Z AC P CY            ← clickable flag buttons
LED PC5-PC2:●●●●      ← physical plotter LEDs from PPI1.C2–C5
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| Space / → | Step one instruction |
| R | Reset CPU + firmware |
| F5 | Run / Pause |
| B | Toggle breakpoint at PC |
| ? | Help |
| Click disasm row | Toggle BP at that address + jump to it |
| Click BC/DE/HL/SP | Jump memory to that address |
| ◀ BP / BP ▶ | Previous/next breakpoint |

## Important patterns (see RULES.md)

1. **Disassembly: linear sweep** — `BuildInsnIndex()`, NO fixed-size rows
2. **Highlight: exact match** — `isPC = (id == pcInsnIdx)`, ONE row only
3. **syncUI: update everything** — entries AND pair buttons
4. **Memory scroll: 2-phase** — ScrollTo(0)+Refresh, then ScrollTo(id+17) → target at top
5. **Tests: -count=1** — no cache
6. **Registers: sync always** — B and C entries match GetBC()

## Peripherals (I/O tab)

PPI1/PPI2 (8255): 3 ports each, 3 modes, bit-set/reset on port C
PIT (8253): 3×16-bit counters, 6 operating modes, BCD option
USART (8251): TX/RX buffers, status (ready/error/overrun), TxPending/RxPending
External: keyboard matrix, X/Y limit switches, DIP inputs and plotter LED state; controls are available in the Hardware tab.

Enable `Stop on peripheral access` to stop after the current instruction reads or writes a mapped PPI/PIT/USART register or a direct USART port. The event line identifies READ/WRITE, address or port, value, device and register function; `?` opens the address-map help.

## Build & test

```bash
cd go && ./trygo.sh
cd go && go test -count=1 ./...
cd go && go test -race ./pkg/app
cd go && go vet ./...
```

## Pending items

1. Settings panel UI — expose CPU frequency, HPGL buffer addr, PIT divisor
2. Step-back / undo — last N instructions revert
3. Conditional breakpoints — break on register/value change
4. Plotter canvas: Retina, grid, pen cursor, pen colors
5. Theme system (dark/light)
6. PIT timing accuracy (counters, IRQ)
7. Font table viewer ($5E00-$5FFF)
8. Assembly export — reassemble modified ROM
9. HPGL step-by-step with current command display
10. UART HPGL file feed simulation
