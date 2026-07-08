# Autograf-882 Firmware Analysis

## Overview

Three D2764A EPROMs (8KB each) at `$0000-$5FFF`:
- **Chip 1** ($0000-$1FFF): Reset, initialization, low-level routines, HPGL parser, serial I/O
- **Chip 2** ($2000-$3FFF): Main program logic, coordinate math, Bresenham interpolation
- **Chip 3** ($4000-$5FFF): Plotter motor control, pen control, font/character tables

## Memory Map

```
$0000-$1FFF  Chip 1 — Low routines, HPGL parser, serial I/O
$2000-$3FFF  Chip 2 — Main logic, math, coordinate interpolation
$4000-$5FFF  Chip 3 — Plotter routines, font tables
$6000-$63FF  RAM (КР537РУ10, 1024 bytes)
$E000-$E3FF  PIO1 (КР580ВВ55 / i8255) — Keyboard, DIP, LEDs
$E400-$E7FF  PIO2 (КР580ВВ55 / i8255) — Stepper motors, pen, ExecBoard
$E800-$EBFF  PIT  (КР580ВИ53 / i8253) — Timer for USART clock + buzzer
$EC00-$EFFF  SIO  (КР580ВВ51А / i8251) — Serial (RS-232)
```

## I/O Configuration (from firmware initialization)

### PIO1 Control ($E003 = $92 = 1001 0010)
```
D7 = 1   Mode set
D6,D5 = 00  Group A mode 0 (basic I/O)
D4 = 1   Port A = INPUT  (keyboard rows read)
D3 = 0   Port C upper (PC4-PC7) = OUTPUT (LEDs)
D2 = 0   Group B mode 0
D1 = 1   Port B = INPUT  (DIP switches read)
D0 = 0   Port C lower (PC0-PC3) = OUTPUT (keyboard columns)
```

### PIO2 Control ($E403 = $80 = 1000 0000)
```
D7 = 1   Mode set
D6,D5 = 00  Group A mode 0
D4 = 0   Port A = OUTPUT (stepper motor phases)
D3 = 0   Port C upper = OUTPUT
D2 = 0   Group B mode 0
D1 = 0   Port B = OUTPUT (ExecBoard control)
D0 = 0   Port C lower = OUTPUT (pen control)
```

## Peripherals

### U3 К555ИД7 (74LS154) Address Decoder
```
Y0  $E000-$E3FF  PIO1 — КР580ВВ55 (i8255)
   PA0-PA5 = Keyboard row outputs (6 rows)
   PB4-PB7 = DIP switches ComCfg1-4 (4 bits, active high/low)
   PC0-PC1 = Keyboard column inputs (2 columns)
   PC2-PC5 = 4 LEDs (active high: 1=ON, 0=OFF)

Y1  $E400-$E7FF  PIO2 — КР580ВВ55 (i8255)
   PB0-PB1 = ExecBoard signals (Net12, Net13)
   PC0-PC3 = Pen control (4 lines)
   PC5     = Net5
   PC7     = i8253 CE1 (timer chip enable)

Y2  $E800-$EBFF  PIT — КР580ВИ53 (i8253)
   OUT0 = SIO clock (baud rate generator for i8251)
   OUT1 = Buzzer

Y3  $EC00-$EFFF  SIO — КР580ВВ51А (i8251 USART)
   RxD, TxD, RTS, CTS, DTR, DSR — full RS-232 handshake
```

## IN/OUT I/O Port Mapping

The 8080 has a SEPARATE I/O address space accessed via `IN`/`OUT` instructions.
The firmware uses these I/O ports:

| Port | Device | Usage |
|------|--------|-------|
| $19  | USART data | Serial data read/write |
| $28  | USART status/ctrl | Check RXRDY/TXRDY, send commands |
| $0A  | (unknown) | Used in initialization |
| $0C  | (unknown) | Used in initialization |
| $63  | (output) | LED/control write |

**IMPORTANT**: Our current emulator maps `IN port` → `readByte(0xE000|port)` which sends `IN $19` to `$E019` (PIO1 range). This is **WRONG** — the hardware has separate I/O and memory spaces.

## RAM Variables

### Coordinate System (confirmed from firmware analysis)

| Address | Name | Description |
|---------|------|-------------|
| $6140 | STACK_TOP | Stack pointer initialized here |
| $6180-$6181 | X_POS | Current X position (LO, HI) |
| $6182-$6183 | X_ACCUM | X accumulator (Bresenham) |
| $6184-$6185 | Y_ACCUM | Y accumulator (Bresenham) |
| $6186-$6187 | Y_POS | Current Y position (LO, HI) |
| $6188-$6189 | X_TARGET | X destination |
| $618A-$618B | Y_TARGET | Y destination |
| $61C8-$61C9 | X_DELTA | Delta X for interpolation |
| $61CA-$61CB | Y_DELTA | Delta Y for interpolation |
| $61E8 | PEN_COLOR | Current pen number (0-6) |
| $63F0 | PEN_STATE | Bit 0 = pen down (1) / up (0) |
| $63F2 | LED_STATE | LED bits (PC2-PC5 on PPI1) |

### Multiple coordinate sets
The firmware uses several coordinate register pairs at $61A3-$61B0 for HPGL command parameter storage and transformation (scaling, rotation).

## Special Debug Markers

The user embedded Z80 opcode prefixes as breakpoint markers for the debugger:

| Byte | Count | Alias | Purpose |
|------|-------|-------|---------|
| $DD | 6 | IX prefix | Debug breakpoint |
| $ED | 14 | Extended prefix | Debug breakpoint |
| $FD | 25 | IY prefix | Debug breakpoint |

On a real 8080 these are effectively `NOP` (skipped or harmless).
The debugger should treat these as breakpoints and pause execution.

**Key locations:**
- $0204: FD — early in initialization (break before RAM test complete)
- $0204, $0283, $051C: FD — during configuration checks
- $07B8: ED — near keyboard scan routine
- $07D9: DD — near keyboard scan
- $0EAF: ED — near serial receive routine
- $1A04: FD — near pen control
- $238E, $23DA: FD — Chip2 coordinate math

## Font Table Area ($5E00-$5FFF)

- $5E00-$5EDF: Character address lookup table (128 entries × 2 bytes = pointers to glyphs)
- $5EE0-$5EE4: Additional pointers
- $5EE8-$5F5F: ASCII uppercase + digits + punctuation lookup
- $5F5E-$5FFF: ASCII lowercase + extended chars

Each character glyph is probably 8-12 bytes defining a 8×N pixel pattern.

## Serial Protocol

The host (EC-1841 / IBM PC/XT) sends HPGL commands via RS-232:

1. Host sends HPGL command string (e.g., `"IN;SP1;PA100,100;PD;"`)
2. USART interrupt (RST 7) triggers firmware to read byte
3. Firmware parses: `IN` → init, `SP` → select pen, `PU` → pen up, `PD` → pen down
4. `PA x,y` → plot absolute, `PR dx,dy` → plot relative
5. Coordinates are 2-byte values (LO, HI) at $6180/$6186
6. Bresenham line algorithm interpolates between current and target

## Startup Sequence

```
$0000: DI                     — Disable interrupts
$0001: MVI A,$80 → STA $E403  — PIO2 control = mode 0, all output
$0006: LXI H,$6000            — Start of RAM
$0009: LXI B,$55AA            — Test pattern
$000C: RAM test loop          — Write $55/$AA, verify, loop through $6000-$67FF
$001F: LXI SP,$6140            — Set stack pointer
$0022: LXI H,$E003 → MVI M,$92 — PIO1 control = PA input, PB input, PC output
$0029: DCX H → DCX H → MVI M,$FC — Write $FC to PIO port
$0032: LXI H,$E803 → JMP $003C — Timer control setup
$003C: MVI M,$36 → MVI M,$76  — PIT mode 3, square wave
$0040: LDA $E002 → check PIO1.PC — Read keyboard columns
$004B-0084: Decode DIP switches (PB4-PB7) → set baud rate, protocol
$00A0: SHLD $6149              — Store HL
$00C0: CALL $223C              — Init plotter
$00C5: STA $E001   → MVI M,$EE — PIO1.PB = $EE (test DIP?)
$00D0: LXI H,$10A4            — Font table base
```
