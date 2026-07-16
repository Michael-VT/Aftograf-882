# Autograf-882 — Checkpoint

**Date:** 2026-07-16  
**State:** STABLE — Go v1.0.15, Rust v1.0.11

## Versions

| Implementation | Version | Status |
|---------------|---------|--------|
| Rust (`rust/`) | v1.0.11 | STABLE — all bugs fixed, 37/37 tests |
| Go (`go/`) | v1.0.15 | STABLE — vet-clean, all tests pass |

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
│   │   ├── app/app.go             717 lines — UI, layout, I/O routing
│   │   ├── cpu/cpu.go             1249 lines — Intel 8080 CPU
│   │   ├── memory/memory.go       190 lines — MMU (28 tests)
│   │   ├── disasm/disasm.go       330 lines — Disassembler (3 tests)
│   │   ├── plotter/plotter.go     210 lines — XY plotter
│   │   ├── hpgl/hpgl.go           337 lines — HPGL parser
│   │   ├── ppi8255/ppi8255.go     113 lines — K580VV55A
│   │   ├── pit8253/pit8253.go     224 lines — K580VI53
│   │   ├── usart8251/usart8251.go 197 lines — K580VV51A
│   │   └── settings/settings.go   40 lines — Configuration
│   └── assets/firmware.bin
├── sim/                           ← Browser debug simulator (legacy)
├── docs/                          ← Documentation & datasheets
├── *.hpgl                         ← Sample HPGL plot files
├── README.*.md                    ← Project docs (6 languages)
├── SUMMARY.md                     ← Project summary
└── CHECKPOINT.md                  ← This file
```

## Go Implementation Status

### Complete
- Full CPU emulation (all 256 opcodes)
- MMU with full I/O decode (PPI1, PPI2, PIT, USART via address bus)
- Disassembler with breakpoints, follow-PC, copy-to-clipboard
- Memory viewer with color coding + click-to-edit bytes
- CPU register card: compact grid layout, hex entry fields with OnSubmit
- USART terminal with hex send + RX log
- HPGL parser + plotter with auto-scaling canvas
- Keyboard shortcuts (Space, R, F5, B, ?)
- Session save/load (JSON file dialogs)
- Help dialog

### Recent Fixes (v1.0.15)
- I/O routing → routes through MMU (`0xE000 | port`) instead of hardcoded PPI1-only
- CPU layout → GridWithColumns(2) with constrained entries, no triple-SP
- Register editing → all 6 entries (A/B/C/D/E/SP) wired with `OnSubmitted`
- Breakpoints → properly rendered in disassembly rows
- Memory colors → ROM/RAM/I/O color-coded byte buttons
- USART → Send button parses hex and calls `ReceiveData()`

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
cd go   && go run ./cmd/aftograf     # Go version
cd rust && cargo run --release       # Rust version
```
