# Session Handoff — 2026-07-17

## Last Session Summary

Critical CPU instruction bugs fixed in Go implementation. Comprehensive test suite added.

## Go CPU Bug Fixes (v1.0.18)

### 🔴 Fix: Missing MOV A,r (0x78–0x7f)
8 instructions were completely absent from `Step()`: MOV A,B/C/D/E/H/L/M/A.
Accumulator could never be loaded from any register or memory.

### 🔴 Fix: 0xCB treated as JMP instead of NOP
On real i8080A, 0xCB is an undocumented NOP (1 byte, 4 cycles). The emulator
treated it as JMP addr (3 bytes, 10 cycles), consuming the next 2 bytes as a
jump target. This was the root cause of "перескочило на 500 байт":
firmware byte 0xCB followed by 0xF4 0x01 → jump to 0x01F4 = 500.

## New CPU Tests

35 comprehensive tests added in `go/pkg/cpu/cpu_test.go`:
- Register-to-register MOV (all combos)
- Memory MOV (r,M and M,r)
- All arithmetic with full flag verification (S,Z,AC,P,CY)
- All logical operations
- Rotates, DAA, stack ops, conditional jumps/calls/returns
- RST 0-7, IN/OUT, interrupt, reset
- Run: `cd go && go test -count=1 ./pkg/cpu/... -v`

## Run Scripts
- Go: `go/trygo.sh` — builds, tests (no cache), launches GUI
- Rust: `rust/tryrust.sh` — builds, tests, launches GUI  
- JS: `sim/tryjs.sh` — bundles, opens HTTP server
**File:** `go/pkg/app/app.go` — 717 lines

### Architecture (3-panel split)
```
┌──────────────────────────────────────────────────────────┐
│ Toolbar: [Rst][Stp][Run][Pause] STOP Spd:[1x] [Save][Load][?]│
├────────┬───────────────────────────┬─────────────────────┤
│ LEFT   │ CENTER                    │ RIGHT               │
│ Tabs:  │ Disasm (top, 55%)         │ Plotter (A4 canvas) │
│  CPU   │  BP ●, address, hex, mnem │ HPGL: Load ▶N ▶A Clr│
│  Stack │ Memory (bottom, 45%)       │ X:0 Y:0 Pen:↑#1    │
│ USART  │  Addr + hex bytes + ASCII │ Progress bar        │
│ (Send) │  Click byte → edit dialog │                     │
└────────┴───────────────────────────┴─────────────────────┘
```

### Key Types
- `AftografApp` struct — owns CPU, MMU, PPI1/2, PIT, USART, Plot, HPGL, Settings
- `regEdit [6]*widget.Entry` — hex entries: [0]=A, [1]=B, [2]=C, [3]=D, [4]=E, [5]=SP
- `regDisp [8]*widget.Label` — live labels: [0]=A, [1]=BC, [2]=DE, [3]=HL, [4]=SP, [5]=PC, [6]=Flags, [7]=Cycles
- `breakpoints map[uint16]bool`
- `uartLog []string` — USART RX log buffer

### Key Functions
- `syncUI()` — updates all labels from CPU state (NOT entries)
- `refreshDisasm()` — rebuilds disassembly grid with BP buttons + address clicks
- `refreshMem()` — rebuilds memory grid with color-coded byte buttons
- `refreshStack()` — updates 8 stack labels
- `saveSession()` / `loadSession()` — JSON serialization via file dialogs
- `memJump(ad)` — jumps memory viewer to address
- `inPort(p)` / `outPort(p,v)` — I/O routing through MMU at `0xE000 | port`

### UI Layout (MakeWindow)
- Toolbar: version label + Rst/Stp/Run/Pause + status + speed selector + Save/Load/?
- Left: AppTabs (CPU card + Stack card) + USART send panel, scrollable
- Center: VSplit (Disassembler card 55% / Memory card 45%)
- Right: Plotter (A4 canvas)
- Main: HSplit(left, HSplit(center, right))
- Offsets: left=0.17, center/right=0.6

### CPU Layout
```
┌────────────────────┐
│ A:XX   │ BC:XXXX  │  ← A entry + BC button
│ B:[00] │ C:[00]   │  ← hex entries, OnSubmitted
│ D:[00] │ E:[00]   │
│ HL:XXXX│ SP:[0000]│  ← HL button + SP entry
│ PC:XXXX│ T:12345  │  ← live labels
│ F:[S][Z][AC][P][CY]│ ← flag buttons + PC→ jump
│ D7-D0:●●●●●●●●    │ ← DIP LEDs
└────────────────────┘
```

### Keyboard Shortcuts (canvas.go SetOnTypedKey)
- Space/→: Step, R: Reset, F5: Run/Pause, B: breakpoint toggle, ?: Help

### Register Entry Wiring
Each `regEdit[i].OnSubmitted` parses hex from entry text and sets the CPU register:
```go
a.regEdit[1].OnSubmitted = func(s string) {
    if v, e := strconv.ParseUint(s, 16, 8); e == nil { a.CPU.B = uint8(v); a.syncUI() }
}
```

### Build/Run
```bash
cd go && go run ./cmd/aftograf
cd go && go test -count=1 ./...
```

### Testing
- `go test -count=1 ./...` passes (3 test packages: cpu 35, memory 28, disasm 3)
- `go vet ./...` passes

## Pending Items
1. Settings panel UI — expose `Settings` struct fields (CPUFreq, HPGLBufferAddr, etc.)
2. Step-back / undo history
3. Conditional breakpoints
4. Plotter canvas: Retina, grid, pen cursor, pen colors
5. Theme system (dark/light)
6. PIT timing accuracy (counters, IRQ)
7. Font table viewer ($5E00-$5FFF)
8. Assembly export
