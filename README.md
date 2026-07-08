# Autograf-882 Debug Simulator

An interactive browser-based debugger and simulator for the **Autograf-882** — a Soviet flatbed plotter (drafting machine) built around the **K580IK80A** CPU (a clone of the Intel 8080).

This project provides a complete digital twin of the original hardware: CPU emulation, memory-mapped I/O, disassembler, plotter simulation, USART terminal, and HPGL file loader — all running in the browser with no server-side logic.

## Features

### CPU Emulation (cpu8080.js)
- Full K580IK80A / Intel 8080 emulation — all 256 opcodes, table-driven
- Registers: A, B, C, D, E, H, L, SP, PC
- Flags: S, Z, AC, P, CY (8080 bit positions)
- Interrupt handling (INTR with RST vector)
- T-state cycle counting
- Clock speed slider: from max (unlimited) down to 100 Hz

### System Memory (memory.js)
- ROM: 24 KB at `$0000–$5FFF` (three D2764A EPROMs)
- RAM: 1 KB at `$6000–$63FF` (K537RU10)
- Memory-mapped I/O: PPI1 at `$E000`, PPI2 at `$E400`, PIT at `$E800`, USART at `$EC00`
- Unmapped reads return `$FF`; writes to ROM/unmapped are logged and trigger a callback

### Disassembler
- Recursive-descent hybrid disassembler built from the CPU opcode table
- 6-column layout: breakpoint, address, raw bytes, mnemonic, operands, annotation
- Follow-PC mode highlights the current instruction
- Virtual scroll through all 64 KB of address space
- Click to toggle breakpoints, double-click to jump PC to that address
- Search by address (`J` key jumps to the hovered line)
- Copy-to-clipboard for the visible range

### Memory Viewer
- Virtual-scrollable dump of all 64 KB of address space
- Color-coded regions: ROM (grey), RAM (yellow), I/O (violet)
- Inline byte editing — click a byte, edit in hex, Tab to next byte
- HL pointer highlighting with an orange marker
- Address bar for quick navigation

### I/O Device Stubs
- **PPI8255** (K580VV55A): two chips, 3 ports each + control register
- **PIT8253** (K580VI53): 3 × 16-bit counters with latch/readback
- **USART8251** (K580VV51A): RX/TX buffers with XOn-XOff flow control, interrupt generation

### Plotter Simulation
- XY stepper motor simulation from PPI port phases
- 7 pen colors from firmware analysis
- A4 portrait canvas (1:√2 aspect ratio) with Retina support
- Auto-scaling grid, current-position cursor, pen-up/pen-down tracking
- Clear canvas and autofit buttons

### HPGL File Loader
- Load HPGL plot files: `IN`, `SP`, `PU`, `PD` commands
- **Direct render mode**: parse and draw on the canvas with animation
- **UART mode**: send HPGL text character-by-character to the USART for the firmware to process
- Progress indicator and pause/resume

### USART Terminal
- Hex input field for sending bytes to the CPU (e.g., `01 02 FF`)
- File upload with XOn-XOff paced transfer
- Transmit log with printable character display and hex fallback
- TXRDY/RXRDY status display

### Session Save / Load
- Snapshot the complete CPU state, RAM contents, breakpoints, and plotter lines
- Save as a timestamped JSON file
- Restore from a previously saved session

### Help System
- `?` button in the header and `?`/`/` keyboard shortcut open a help overlay
- Keyboard shortcuts reference table
- Mouse interaction guide
- File format overview
- Quick tips

### Theme Support
- Dark theme (default) — Tokyo Night inspired palette
- Light theme — clean light palette for daytime use
- Switch in Settings panel, persists to `localStorage`

### Settings Panel
- Watch variable address configuration (X, Y, pen position, color)
- Custom watch variables with 1-byte or 2-byte readout
- ROM chip offset configuration
- Manual firmware loading with address selection
- Theme selector
- All settings persist to `localStorage`

## How to Run

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
```

Then open `http://localhost:8080/sim/` in a browser.

Firmware (`firmware.bin`, 24 KB) loads automatically on page start.  
If missing, use the 📂 button or Settings → Load firmware.

## Build bundle.js

```bash
cd sim && node build.js
```

Builds a single-file `bundle.js` from the ES6 modules (`settings.js`, `memory.js`, `cpu8080.js`, `main.js`) — strips `import`/`export` and concatenates in dependency order.

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `Space` / `→` | Step one instruction |
| `R` | Reset CPU |
| `F5` | Run / Pause |
| `B` | Toggle breakpoint at PC |
| `J` | Jump PC to the address under cursor |
| `?` / `/` | Open help overlay |

## Project Structure

```
├── sim/                  ← Browser debug simulator
│   ├── index.html        Entry point (3-column layout)
│   ├── styles.css        Dark/light theme system
│   ├── bundle.js         Single-file build output
│   ├── build.js          Concatenation build script
│   ├── main.js           App controller & I/O device stubs
│   ├── cpu8080.js        K580IK80A CPU emulator
│   ├── memory.js         MMU with ROM, RAM, I/O
│   ├── settings.js       Settings manager + localStorage
│   └── firmware.bin      24 KB firmware image
├── disasm8080.py         Python recursive disassembler
├── autograf-882-disassembly.asm  Full disassembly listing
├── 01_Plotter-*-Schematic.pdf    Reverse-engineered schematic
└── CHECKPOINT.md         Development checkpoint
```

## License

Reverse-engineering and documentation of the Autograf-882 hardware for preservation and educational purposes.

## Acknowledgements

- The Soviet engineers who designed the K580IK80A and the Autograf-882
- The open-source community for 8080 emulation references
