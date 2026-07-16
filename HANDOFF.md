# Session Handoff — 2026-07-16

## Last Session Summary

Synchronized the Go implementation with Rust features. All 15 planned tasks completed.

## Go App State

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
cd go && go test ./...
```

### Testing
- `go test ./...` passes (2 test packages: memory, disasm)
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
