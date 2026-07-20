# Autograf-882 — Checkpoint

**Date:** 2026-07-20
**State:** STABLE — Go v1.0.18, Rust v1.0.11, JavaScript v0.0.7

## Versions

| Implementation | Version | Status |
|---------------|---------|--------|
| Rust (`rust/`) | v1.0.11 | STABLE — all bugs fixed, 37/37 tests |
| Go (`go/`) | v1.0.18 | STABLE — `go test ./...`, race test and vet pass |

## Project Structure

```
./
├── rust/                          ← Native GUI (Rust/egui) — PRIMARY
│   ├── Cargo.toml
│   ├── Cargo.lock
│   ├── build.rs                   Firmware embedder
│   ├── src/
│   │   ├── main.rs                Entry point
│   │   ├── app.rs                 1563 lines — UI, stepping, I/O
│   │   ├── cpu.rs                 1318 lines — Intel 8080 CPU
│   │   ├── memory.rs              199 lines — MMU
│   │   ├── disasm.rs              296 lines — Disassembler
│   │   ├── plotter.rs             188 lines — XY plotter
│   │   ├── hpgl.rs                266 lines — HPGL parser
│   │   ├── ppi8255.rs             69 lines — K580VV55A
│   │   ├── pit8253.rs             121 lines — K580VI53
│   │   ├── usart8251.rs           112 lines — K580VV51A
│   │   ├── settings.rs            69 lines — Configuration
│   │   └── session.rs             74 lines — Save/load
│   └── assets/firmware.bin
├── go/                             ← Native GUI (Go/Fyne) — ACTIVE
│   ├── go.mod / go.sum
│   ├── cmd/aftograf/main.go
│   ├── pkg/
│   │   ├── app/app.go             UI, layout, I/O routing, hardware controls
│   │   ├── cpu/cpu.go             Intel 8080 CPU
│   │   ├── memory/memory.go       MMU with ROM/RAM/I/O decode
│   │   ├── disasm/disasm.go       Disassembler
│   │   ├── plotter/plotter.go     XY plotter
│   │   ├── hpgl/hpgl.go           HPGL parser
│   │   ├── ppi8255/ppi8255.go     K580VV55A
│   │   ├── pit8253/pit8253.go     K580VI53
│   │   ├── usart8251/usart8251.go K580VV51A
│   │   └── settings/settings.go   Configuration
│   └── assets/firmware.bin
├── sim/                           ← Browser debug simulator (legacy)
├── docs/                          ← Documentation & datasheets
├── *.hpgl                         ← Sample HPGL plot files
├── RULES.md                      ← Architecture rules (must follow)
├── SUMMARY.md                     ← Project summary
└── CHECKPOINT.md                  ← This file

## Go Implementation Status

### Complete
- Full CPU emulation (all 256 opcodes)
- MMU with full I/O decode (PPI1, PPI2, PIT, USART via address bus)
- Disassembler with breakpoints, follow-PC, copy-to-clipboard
- Memory viewer with color coding + click-to-edit bytes
- CPU register card: compact grid layout, hex entry fields with OnSubmit
- USART terminal with hex send + RX log
- Hardware tab with live 6×2 keyboard matrix, X/Y limit switches, DIP inputs and PPI1.C2–C5 LEDs
- Optional stop after a peripheral read/write, with a device/register access description in the I/O tab
- HPGL parser + plotter with auto-scaling canvas
- Keyboard shortcuts (Space, R, F5, B, ?)
- Session save/load (JSON file dialogs)
- Help dialog

### Earlier Fixes (v1.0.15)
- I/O routing → routes through MMU (`0xE000 | port`) instead of hardcoded PPI1-only
- CPU layout → GridWithColumns(2) with constrained entries, no triple-SP
- Register editing → all 6 entries (A/B/C/D/E/SP) wired with `OnSubmitted`
- Breakpoints → properly rendered in disassembly rows
- Memory colors → ROM/RAM/I/O color-coded byte buttons
- USART → Send button parses hex and calls `ReceiveData()`

### Recent Fixes (v1.0.18) — Instruction-indexed disassembly, UI and hardware debugging
- **Disassembly: linear sweep** — replaced fixed-size rows (2-byte then 1-byte) with
  `disasm.BuildInsnIndex()` — all instructions shown as complete rows regardless of length.
  No more misaligned decodes or garbage instructions in the listing.
- **Highlight: exact instruction match** — `isPC = (id == pcInsnIdx)`. Only ONE row
  highlighted at a time, no over-highlighting across multiple rows.
- **Memory viewer scroll** — `ScrollTo(id)` without offset, target centered in viewport.
- **Register entry fields** — A/B/C/D/E/SP hex entries now update in `syncUI()`, matching
  pair buttons (BC:XXXX, DE:XXXX) exactly.
- `trygo.sh` forces fresh test runs with `go test -count=1` + clear PASS/FAIL summary.
- Created `sim/tryjs.sh` for browser version.
- Added live Go simulation controls for the keyboard, limit switches, DIP inputs and plotter LEDs.
- Added a peripheral-access callback and the Go I/O breakpoint with READ/WRITE event details.
- Added the Go CPU and I/O checkpoint screenshots under `images/`.
- Fixed the JavaScript HPGL loader to handle stateful `PU/PD`, absolute `PA` and relative `PR` coordinates.
- Added Node HPGL regression tests to `sim/tryjs.sh` and rebuilt the browser bundle.
### Known Issues
1. I/O device stubs simplified (no real PIT counting, PPI modes)
2. USART interrupt is single RST 7 — no multi-vector
3. Plotter canvas empty until firmware sends stepper commands (same as Rust)
4. No Retina/high-DPI canvas support
5. No theme system (always Fyne default)
6. No settings panel UI
7. `dialog.ShowFileSave` shows Save dialog but the filename hint behavior is limited

## Next Steps (Roadmap)

1. **Settings panel** — expose CPU frequency, HPGL buffer addr, PIT divisor in UI
2. **Step-back / undo** — last N instructions revert
3. **Conditional breakpoints** — break on register/value change
4. **Plotter canvas improvements** — Retina support, grid overlay, pen cursor
5. **Theme system** — dark/light toggle
6. **I/O accuracy** — proper PIT timing, PPI mode emulation
7. **Font table viewer** — visualize character data at $5E00-$5FFF
8. **Assembly export** — reassemble modified ROM

## How to Run

```bash
cd go   && ./trygo.sh                # Go: build, tests, GUI smoke test and launch
cd rust && cargo run --release       # Rust version
```

For a Go build without launching the GUI, use `go build ./cmd/aftograf`. The browser implementation is served from the repository root with `python3 -m http.server 8080`, then open `/sim/`.
