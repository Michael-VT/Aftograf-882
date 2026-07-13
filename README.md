# Autograf-882 Debug Simulator v1.0.10

![Autograf-882 — Original Device](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*The original Autograf-882 flatbed plotter*


A native macOS debugger and simulator for the **Autograf-882** — a Soviet flatbed plotter built around the **K580IK80A** CPU (Intel 8080 clone).

This project provides a complete digital twin of the original hardware: CPU emulation, memory-mapped I/O, disassembler, plotter simulation, USART terminal, and HPGL file loader — implemented as a native GUI application using **egui/eframe (Rust)**.

A browser-based version (`sim/`) is also available.

## Features

### CPU Emulation (Rust)
- Full K580IK80A / Intel 8080 emulation — all 256 opcodes, table-driven dispatch
- Registers: A, B, C, D, E, H, L, SP, PC (editable in UI)
- Flags: S, Z, AC, P, CY (8080 bit positions)
- Interrupt handling (INTR with RST vector)
- T-state cycle counting — displayed in the CPU panel
- Clock speed control: 5000 / 10000 / 50000 / 100000 / 33333 (1 MHz) instructions per batch

### System Memory
- ROM: 24 KB at `$0000–$5FFF` (three D2764A EPROMs, firmware embedded at build time)
- RAM: 2 KB at `$6000–$67FF` (K537RU10)
- Memory-mapped I/O: PPI1 at `$E000`, PPI2 at `$E400`, PIT at `$E800`, USART at `$EC00`
- Unmapped reads return `$FF`; writes to ROM are blocked with a warning

### Disassembler
- Table-driven disassembler from the CPU opcode table
- 6-column layout: breakpoint, address, raw bytes, mnemonic, operands, annotation
- **Follow PC** mode — current instruction always centered in the window
- Full 64 KB address range accessible via search bar and navigation buttons (◀▶)
- Click to toggle breakpoints, hover to preview addresses
- 256 instructions visible per view

### Memory Viewer
- 64 rows × 16 bytes = 1 KB visible at a time
- Full 64 KB navigation via address bar, Go button, and ◀▶ buttons
- Click **BC:**, **DE:**, **HL:**, **SP:** in the CPU panel to jump memory to that address
- Color-coded regions: ROM (brown), RAM (yellow), PPI1/2 (red/teal), PIT (olive), USART (purple)
- HL pointer highlighted in orange
- Inline byte editing — double-click a byte, type hex value, press Enter or click away
- ASCII representation column on the right

### Peripherals (Rust)
- **K580VV55A (PPI8255)**: two chips, 3 ports each + control register
- **K580VI53 (PIT8253)**: 3 × 16-bit counters with latch
- **K580VV51A (USART8251)**: RX/TX buffers with XOn-XOff flow control, interrupt generation

### Plotter Simulation
- XY stepper motor simulation from PPI port phases
- 7 pen colors from firmware analysis
- A4 portrait canvas (1:√2 aspect ratio)
- Auto-scaling grid, cursor tracking, limit switches
- Clear canvas and HPGL controls

### Keyboard / Sensors
- **DIP switches (D4-D7)**: toggleable in the Sensors panel under CPU registers
- **End stops (D0-D3)**: toggleable limit switches
- **LED indicators**: PPI1 port C bits shown graphically
- **Keyboard matrix**: 6×2 key state display

### HPGL File Loader
- Load HPGL plot files: `IN`, `SP`, `PU`, `PD`, `PA`, `PR` commands
- **Preview mode**: draw all segments on the plotter canvas
- **Step mode**: ▶ Next / ▶▶ All / ⟲ Reset — step through segments one by one
- **Draw up to line N**: enter a segment number and click Go
- Active line highlighted in yellow with line number indicator
- Progress bar with percentage

### USART Terminal
- Hex input field for sending bytes to the CPU
- Transmit log with display of printable characters and hex codes
- TXRDY/RXRDY status

### Sensors & Diagnostics
- CPU register panel with cycle counter
- Stack display (4 words)
- Trace buffer (last 100 instructions)
- I/O device status (PPI, PIT, USART register values)
- Memory region color legend

![Autograf-882 Debug Simulator](images/Avtograf8445-sh003.png)
*Debugger simulator in action (Rust/egui)*


## How to Build & Run (Rust)

### Prerequisites
- Rust toolchain (install via `rustup`)
- macOS (for native GUI; egui/eframe supports Linux and Windows too)

### Build & Run

```bash
cd rust
cargo run --release
```

### Run Tests

```bash
cd rust
cargo test -- --test-threads=1
```

## Browser Version (`sim/`)

The older browser-based version is in the `sim/` directory. To run:

```bash
python3 -m http.server 8080
# Open http://localhost:8080/sim/
```

## Project Structure

```
├── rust/                  ← Rust native GUI (primary)
│   ├── Cargo.toml        Package manifest
│   ├── build.rs          Firmware embedder
│   ├── TESTS.md          Test description
│   ├── src/
│   │   ├── main.rs       Entry point + eframe window
│   │   ├── app.rs        Main application (UI, stepping, I/O callbacks)
│   │   ├── cpu.rs        Intel 8080 CPU emulator
│   │   ├── memory.rs     MMU with ROM, RAM, I/O decode
│   │   ├── disasm.rs     Disassembler
│   │   ├── plotter.rs    XY plotter simulation
│   │   ├── hpgl.rs       HPGL parser
│   │   ├── ppi8255.rs    K580VV55A (PPI)
│   │   ├── pit8253.rs    K580VI53 (PIT)
│   │   ├── usart8251.rs  K580VV51A (USART)
│   │   ├── settings.rs   Configuration
│   │   └── session.rs    Save/load state
│   └── assets/
│       └── firmware.bin  24 KB firmware image
├── sim/                   ← Browser-based version
│   ├── index.html
│   ├── styles.css
│   ├── bundle.js
│   ├── build.js
│   ├── cpu8080.js
│   ├── memory.js
│   └── firmware.bin
├── docs/                  ← Documentation & datasheets
├── images/                ← Screenshots
├── *.hpgl                 ← Sample HPGL plot files
├── README.*.md            ← This file (6 languages)
└── CHECKPOINT.md          ← Development notes
```

## Keyboard Shortcuts (Rust version)

| Key | Action |
|-----|--------|
| `Space` / `→` | Step one instruction |
| `R` | Reset CPU |
| `F5` | Run / Pause |
| `B` | Toggle breakpoint at PC |
| `J` | Jump PC to the address under cursor |
| `?` / `/` | Open help overlay |
| `Escape` | Close help/settings |

## License

Reverse-engineering and documentation of the Autograf-882 hardware for preservation and educational purposes.

---

**Other languages:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
