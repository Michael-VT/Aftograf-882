# Autograf-882 Firmware Analysis

## Overview

Three D2764A EPROMs (8KB each) at `$0000-$5FFF`:
- **Chip 1** ($0000-$1FFF): Reset, initialization, low-level routines, HPGL parser, serial I/O
- **Chip 2** ($2000-$3FFF): Main program logic, coordinate math, Bresenham interpolation, pen control
- **Chip 3** ($4000-$5FFF): Plotter motor control, character generator, font tables

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
PA = INPUT  — keyboard rows (PA0-PA5)
PB = INPUT  — DIP switches (PB4-PB7) + limit switches (PB0-PB3)
PC = OUTPUT — keyboard columns (PC0-PC1), LEDs (PC2-PC5)
```

### PIO2 Control ($E403 = $80 = 1000 0000)
```
PA = OUTPUT — stepper motor phases
PB = OUTPUT — ExecBoard control signals
PC = OUTPUT — pen control (PC0-PC3), timer CE (PC7)
```

## Peripherals — U3 К555ИД7 (74LS154) Decoder

```
Y0  $E000-$E3FF  PIO1
   PA0-PA5 = keyboard rows (6)
   PB4-PB7 = DIP switches ComCfg1-4
   PB0-PB3 = limit switches (Xmin, Xmax, Ymin, Ymax)
   PC0-PC1 = keyboard columns (2)
   PC2-PC5 = LEDs (1=ON)

Y1  $E400-$E7FF  PIO2
   PB0-PB1 = ExecBoard signals
   PC0-PC3 = pen control (4 lines, differential)
   PC7     = i8253 CE1

Y2  $E800-$EBFF  PIT
   OUT0 = SIO clock (i8251 baud rate)
   OUT1 = Buzzer

Y3  $EC00-$EFFF  SIO
   RxD, TxD, RTS, CTS, DTR, DSR
```

## I/O Port Mapping (IN/OUT instructions)

The 8080 has separate I/O space. Our emulator routes:
| Port | Device | Function |
|------|--------|----------|
| $19  | USART data | Read/write serial byte |
| $28  | USART status | Check RXRDY/TXRDY |
| other | $E000+port | Fallback to memory space |

## RAM Variables

| Address | Name | Description |
|---------|------|-------------|
| $6140 | STACK_TOP | Stack pointer = $6140 |
| $6148 | CUR_CHAR | Current received char from USART |
| $6149 | TEMP_HL | Temporary HL storage |
| $6180-$6181 | X_POS | Current X position (LO, HI) |
| $6182-$6183 | X_ACCUM | X Bresenham accumulator |
| $6184-$6185 | Y_ACCUM | Y Bresenham accumulator |
| $6186-$6187 | Y_POS | Current Y position (LO, HI) |
| $6188-$6189 | X_TARGET | X destination |
| $618A-$618B | Y_TARGET | Y destination |
| $61A3-$61A4 | COORD_A | HPGL parameter A |
| $61A5-$61A6 | COORD_B | HPGL parameter B |
| $61C8-$61C9 | X_DELTA | Delta X (Bresenham) |
| $61CA-$61CB | Y_DELTA | Delta Y (Bresenham) |
| $61E8 | PEN_COLOR | Pen number 0-6 |
| $63F0 | PEN_STATE | Bit 0: pen down (1) |
| $63F2 | LED_STATE | Mirrors PIO1.PC LED bits |

## Firmware Subroutine Table

### Chip 1 ($0000-$1FFF) — Low-Level Routines

| Address | Called | Signature | Description |
|---------|--------|-----------|-------------|
| **$027C** | 18× | `3A 8B 63 32 8C 63` | **Save byte to RAM buffer** — writes A to $638B, shifts to $638C |
| **$0288** | 16× | `3A 8C 63 32 8B 63` | **Load byte from RAM buffer** — restores from $638C→$638B |
| **$0762** | 17× | `CD 44 61 FE 00 6F` | **Read keyboard/DIP** — reads PIO1 port C, checks config bits |
| **$0AFF** | 16× | `3A 01 EC E6 02 CA` | **USART receive byte** — read $EC01 status, check RXRDY bit 1, read $EC00 |
| **$0B4A** | 1× | `STA $EC00` | **USART send byte** — write A to USART data, wait for TXRDY |
| **$0C8D** | — | `CD 44 61` | **USART read with wait** — loop until byte received |
| **$0F1A** | — | — | **Parse HPGL command** — dispatches to handlers |
| **$110C** | 30× | `F5 AF 32 2F 63 32` | **Save state** — push register state to RAM save area |
| **$1116** | 18× | `F5 3E FF 32 2F 63` | **Restore state** — pop register state from RAM save area |
| **$19CA** | 46× | `3A 48 61 FE 20 C2` | **USART check char** — compare received char with threshold, branch |
| **$19D8** | 33× | `CD 44 61 3A 48 61` | **USART get char** — wait for USART char, return in A |
| **$19DB** | 25× | `3A 48 61 FE 20 C2` | **Char classification** — check if char is printable/control |
| **$1CE0** | 40× | `2A 5D 63 3A 8B 63` | **Coordinate load** — loads coordinate pair from RAM |
| **$2252** | 19× | `3E 63 32 B7 63 3A` | **Set speed/acceleration** — configures movement speed |

### Chip 2 ($2000-$3FFF) — Main Logic & Math

| Address | Called | Signature | Description |
|---------|--------|-----------|-------------|
| **$2587** | 16× | `CD 44 61 3A AC 61` | **Coordinate transform** — scale/rotate coordinates |
| **$2648** | 22× | `CD 44 61 06 07 AF` | **Multi-byte multiply** — 8×8→16 multiply routine |
| **$264B** | 16× | `06 07 AF 21 00 00` | **16-bit multiply** — HL × DE → HL |
| **$27EA** | 37× | `7C BA C0 7D BB C9` | **Compare HL** — compare HL with DE, set flags |
| **$27F0** | 26× | `7D 93 6F 7C 9A 67` | **Subtract HL-DE** — HL = HL - DE (16-bit) |
| **$28BB** | 24× | `44 19 1F AC A8 AA` | **Bresenham step** — single interpolation step |
| **$2957** | 22× | `7B CD 70 29 E5 F5` | **Line draw** — draw line from (x1,y1) to (x2,y2) |
| **$3109** | 22× | `7C BA C0 7D BB C9` | **Compare signed** — signed 16-bit comparison |
| **$35E5** | 21× | `7C BA C0 7D BB C9` | **Absolute value** — compute |HL| |

### Chip 3 ($4000-$5FFF) — Plotter & Fonts

| Address | Called | Signature | Description |
|---------|--------|-----------|-------------|
| **$41C7** | 1× | `OUT $FA` | **Stepper motor sequence** — outputs phase pattern |
| **$45F4** | 1× | `OUT $4C` | **Pen solenoid control** — actuate pen lift/drop |
| **$4668** | — | `IN $48` | **Read limit switches** — read limit switch inputs |
| **$58C5** | 1× | `OUT $E5` | **ExecBoard command** — send command to ExecBoard |
| **$5CA0-$5E00** | — | — | **Character generator** — glyph rendering routines |
| **$5E00-$5FFF** | — | — | **Font tables** — character definitions + ASCII maps |

### Reset Vector ($0000) — Boot Sequence

```
$0000  DI                      ; Disable interrupts
$0001  MVI A,$80 → STA $E403  ; PIO2 control = all output
$0006  LXI H,$6000            ; Start RAM test
$0009  LXI B,$55AA            ; Test pattern
$000C  RAM test loop          ; Write/verify $55/$AA through $6000-$67FF
$001F  LXI SP,$6140           ; Stack pointer
$0022  LXI H,$E003 → MVI M,$92 ; PIO1: PA+PB=input, PC=output
$0032  LXI H,$E803            ; Timer control
$003C  MVI M,$36 → MVI M,$76  ; PIT: cntr0 mode3 + cntr1 mode3
$0040  LDA $E002              ; Read PIO1 port C
$0043-0084  Decode DIP switches (PB4-PB7) → configure baud rate, protocol
```

## Special Debug Markers

The user embedded Z80 opcode prefixes as breakpoints:

| Byte | Count | Purpose |
|------|-------|---------|
| $FD | 25 | Debug breakpoint — pause execution |
| $ED | 14 | Debug breakpoint |
| $DD | 6 | Debug breakpoint |

## Startup Sequence Detail

1. **RAM test** ($000C-001C): Write $55, $AA to all RAM, verify. On fail → error handler $0229
2. **PIO1 init** ($0022-0031): Port A+B = input, Port C = output. Write $FC as initial state
3. **Timer init** ($003C-003E): Counter 0 = mode 3 (USART clock), Counter 1 = mode 3 (buzzer)
4. **DIP read** ($0040-0084): Read DIP switches from PIO1.PC, decode baud rate and protocol
5. **Main loop entry** → Jump to $0090 after initialization completes

## Limit Switches

| Bit | Pin | Signal | Description |
|-----|-----|--------|-------------|
| PIO1.PB0 | PB0 | LIMIT_XMIN | X axis minimum (left edge) |
| PIO1.PB1 | PB1 | LIMIT_XMAX | X axis maximum (right edge) |
| PIO1.PB2 | PB2 | LIMIT_YMIN | Y axis minimum (bottom edge) |
| PIO1.PB3 | PB3 | LIMIT_YMAX | Y axis maximum (top edge) |
| — | — | LIMIT_PEN_UP | Pen mechanism at top (change position) |
| — | — | LIMIT_PEN_DN | Pen mechanism at bottom (change position) |

The firmware reads limit switches during homing sequence and as safety stops during movement. When triggered, movement in that direction stops. The limit bits are fed into PIO1 port B bits PB0-PB3 along with DIP switches on PB4-PB7.
