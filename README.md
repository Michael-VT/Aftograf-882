# Autograf-882 Debug Simulator v1.0.18

![Autograf-882 — Original Device](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*The original Autograf-882 flatbed plotter*

A native debugger and simulator for the **Autograf-882** — a Soviet flatbed plotter built around the **K580IK80A** CPU (Intel 8080 clone).

This project provides a complete digital twin of the original hardware: CPU emulation, memory-mapped I/O, disassembler, plotter simulation, USART terminal, and HPGL file loader — implemented in **two native GUI implementations**:

| Implementation | Framework | Status |
|---------------|-----------|--------|
| **Rust** (`rust/`) | egui/eframe | Primary, feature-complete |
| **Go** (`go/`) | Fyne v2 | Near-feature-complete, actively developed |

A legacy browser-based version (`sim/`) is also available.

## Features

### CPU Emulation (Rust & Go)
- Full K580IK80A / Intel 8080 emulation — all 256 opcodes, table-driven dispatch
- Registers: A, B, C, D, E, H, L, SP, PC (editable in UI via hex entry fields)
- Flags: S, Z, AC, P, CY (8080 bit positions, clickable toggle)
- Interrupt handling (INTR with RST 7 vector)
- T-state cycle counting — displayed in the CPU panel
- Clock speed control: 1x/10x/100x/1Kx/10Kx/100Kx speed multiplier (Go)

### System Memory
- ROM: 24 KB at `$0000–$5FFF` (three D2764A EPROMs, firmware embedded)
- RAM: 2 KB at `$6000–$67FF` (K537RU10)
- Memory-mapped I/O: PPI1 at `$E000`, PPI2 at `$E400`, PIT at `$E800`, USART at `$EC00`
- Unmapped reads return `$FF`; writes to ROM are silently ignored

### Disassembler (Rust & Go)
- Table-driven disassembler from the CPU opcode table
- Breakpoint toggle (click to set/clear)
- **Follow PC** mode — current instruction centered in the view
- Full 64 KB address range via search bar and navigation buttons (◀▶)
- Click address to jump memory viewer to that address
- Copy visible disassembly range to clipboard (Go: Copy button)

### Memory Viewer (Rust & Go)
- 32 rows × 16 bytes = 512 bytes visible at a time (Go); 64 rows × 16 bytes (Rust)
- Full 64 KB navigation via address bar, Go button, and ◀▶ buttons
- Click **BC:**, **DE:**, **HL:**, **SP:** in the CPU panel to jump memory to that address
- Color-coded regions: ROM (brown), RAM (gold), I/O (purple) — Go version
- Inline byte editing — click a byte, type hex value, press Enter (Go); double-click (Rust)
- ASCII representation column on the right

### Peripherals (Rust & Go)
- **K580VV55A (PPI8255)**: two chips (PPI1, PPI2), 3 ports each + control register
- **K580VI53 (PIT8253)**: 3 × 16-bit counters with latch
- **K580VV51A (USART8251)**: RX/TX buffers, status register, hex send with log

### Plotter Simulation (Rust & Go)
- XY stepper motor simulation from PPI port phases
- 7 pen colors from firmware analysis
- A4 canvas with auto-scaling grid
- HPGL file loading and step execution

### HPGL File Loader
- Load HPGL plot files: `IN`, `SP`, `PU`, `PD`, `PA`, `PR` commands
- **Preview mode**: draw all segments on the plotter canvas
- **Step mode**: ▶ Next / ▶▶ All / ⟲ Reset
- Progress bar

### USART Terminal (Go)
- Hex input field for sending bytes to the CPU
- Transmit log with last 20 entries displayed
- TXRDY/RXRDY status indicators

### Sensors & Diagnostics
- CPU register panel with cycle counter (Rust & Go)
- Stack display (8 words in Go, configurable)
- DIP switch LEDs (PPI1 port A bits)
- Session save/load to JSON file (Go)
- Keyboard shortcuts: Space/→ Step, R Reset, F5 Run/Pause, B breakpoint, ? Help

![Autograf-882 Debug Simulator](images/Avtograf8445-sh003.png)
*Debugger simulator in action (Rust/egui)*

## Build & Run

### Rust (primary)

```bash
cd rust
cargo run --release
```

Tests:
```bash
cd rust
cargo test -- --test-threads=1
```

### Go (actively developed)

```bash
cd go
go run ./cmd/aftograf
```

The Go version uses Fyne v2.5 for GUI. Requires a display server (X11/macOS/Wayland).

Tests:

```bash
cd go
go test -count=1 ./...
```

### Browser Version (`sim/`)

The legacy browser-based version:

```bash
cd sim && ./tryjs.sh
# Or manually:
python3 -m http.server 8080
# Open http://localhost:8080/sim/
```
![Autograf-882 Debug Simulator (JS)](images/Aftograf-882-Debuger.png)
*Browser-based debugger simulator (JavaScript)*

## Project Structure

```
├── rust/                  ← Rust native GUI (primary)
│   ├── Cargo.toml
│   ├── build.rs          Firmware embedder
│   ├── TESTS.md
│   ├── src/
│   │   ├── main.rs
│   │   ├── app.rs        UI, stepping, I/O callbacks
│   │   ├── cpu.rs        Intel 8080 emulator
│   │   ├── memory.rs     MMU: ROM + RAM + I/O decode
│   │   ├── disasm.rs     Disassembler
│   │   ├── plotter.rs    XY plotter
│   │   ├── hpgl.rs       HPGL parser
│   │   ├── ppi8255.rs    K580VV55A (PPI)
│   │   ├── pit8253.rs    K580VI53 (PIT)
│   │   ├── usart8251.rs  K580VV51A (USART)
│   │   ├── settings.rs   Configuration
│   │   └── session.rs    Save/load state
│   └── assets/firmware.bin
├── go/                    ← Go native GUI (Fyne)
│   ├── go.mod / go.sum
│   ├── cmd/aftograf/main.go
│   ├── pkg/
│   │   ├── app/app.go    UI, layout, I/O routing
│   │   ├── cpu/cpu.go    Intel 8080 emulator
│   │   ├── memory/       MMU + tests
│   │   ├── disasm/       Disassembler + tests
│   │   ├── plotter/      XY plotter
│   │   ├── hpgl/         HPGL parser
│   │   ├── ppi8255/      PPI8255
│   │   ├── pit8253/      PIT8253
│   │   ├── usart8251/    USART8251
│   │   └── settings/     Configuration
│   └── assets/firmware.bin
├── sim/                   ← Browser-based version (legacy)
├── docs/                  ← Documentation & datasheets
├── images/                ← Screenshots
├── *.hpgl                 ← Sample HPGL plot files
├── README.*.md            ← This file (6 languages)
└── CHECKPOINT.md          ← Development notes
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` / `→` | Step one instruction |
| `R` | Reset CPU |
| `F5` | Run / Pause |
| `B` | Toggle breakpoint at PC |
| `?` | Open help (Go) / `?` / `/` (Rust) |
| `Escape` | Close help/settings |
| `J` | Jump PC (Rust only) |

## License

Reverse-engineering and documentation of the Autograf-882 hardware for preservation and educational purposes.

---

**Other languages:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
