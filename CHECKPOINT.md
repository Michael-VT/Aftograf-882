# Autograf-882 Debug Simulator — Checkpoint

**Date:** 2026-07-05  
**State:** WORKING — major feature update with editable registers/memory, USART terminal, A4 plotter.

## Project Structure

```
./
├── sim/                          ← Browser debug simulator
│   ├── bundle.js                 Single-file JS (build from 4 modules)
│   ├── build.js                  Bundle concatenation script
│   ├── settings.js               SettingsManager + defaults + renderPanel()
│   ├── memory.js                 MMU: ROM(24KB) + RAM(1KB) + I/O
│   ├── cpu8080.js                Full 8080/К580ИК80 emulator, 256 opcodes
│   ├── main.js                   App controller — UI, plotter, disasm, I/O devices
│   ├── index.html                Full 3-column layout with all panels
│   ├── styles.css                Dark theme + A4 plotter + all new styles
│   └── firmware.bin              24KB — concatenated 3x D2764A EPROMs
├── disasm8080.py                 Python recursive disassembler
├── autograf-882-disassembly.asm  Full listing (17792 lines)
├── Autograf-882-*Chip*.bin       3× 8KB ROM dumps
├── 01_Plotter-*-Schematic.pdf    Schematic (reverse-engineered)
├── CHECKPOINT.md                 This file
└── sim/build.js                  Bundle concatenation script
```

## Architecture (3-column layout)

```
┌──────────────────────────────────────────────────────────────┐
│ Header: status + PC + [Space/R/F5/B shortcuts shown]        │
│         [↺Reset][→Step][▶Run][⏸Pause] Speed:[===] [📂ROM] │
├────────┬───────────────────────────┬────────────────────────┤
│ LEFT   │ CENTER                    │ RIGHT (A4)             │
│ 200px  │ Disasm (flex 1)           │ Canvas fills height    │
│ CPU    │  6 columns: addr hex mnem │ A4 portrait 1:√2       │
│ regs*  │  op annot (follow PC)     │ Grid + pen colors      │
│ flags* │ Scrollable memory (64KB)* │ Clear/Autofit buttons  │
│ Current│  — click byte to edit*    │                        │
│ instr  │  region-colored bytes*    │                        │
│ Stack  │  toolbar: addr+refresh    │                        │
│ (50w)* │                          │                        │
│ Pointers│                         │                        │
│ I/O    │                          │                        │
│ USART* │                          │                        │
│ (term) │                          │                        │
└────────┴───────────────────────────┴────────────────────────┘
```

* = New/Enhanced

## New Features (2026-07-05)

### 1. Редактирование регистров CPU
- Клик по значению регистра (A, B, C, D, E, H, L, F, SP, PC) → inline input
- Enter подтверждает, Esc отменяет
- Флаги (S, Z, AC, P, CY) кликабельны — toggle

### 2. Память — прокрутка + редактирование
- Виртуальная прокрутка всей 64KB памяти (16 строк × 4096 рядов)
- Цветовая маркировка: ROM (серый), RAM (жёлтый), I/O (фиолетовый)
- Клик по байту → inline edit; Tab → следующий байт

### 3. Стек — 50 слов
- Показывает 50 слов (100 байт) от SP вверх
- SP помечен маркером →SP
- scrollable контейнер (max-height: 280px)

### 4. Плоттер A4
- Адаптивный размер: пропорция A4 (1:√2), высота на весь правый столбец
- Retina-буфер (2× resolution)
- Кнопки: Очистить холст, Автомасштаб

### 5. USART терминал с XOn-XOff
- Поле вывода (RX лог) с цветовой маркировкой
- Поле ввода hex-байт для отправки CPU (например: `01 02 FF`)
- Отправка файла с XOn-XOff протоколом (XOff=0x13, XOn=0x11)
- Статус TXRDY/RXRDY, размер RX буфера

### 6. Клавиатурные сокращения
| Клавиша | Действие |
|---------|----------|
| Space   | Step     |
| →       | Step     |
| R       | Reset    |
| F5      | Run/Pause|
| B       | BP у PC  |

## Settings — RAM Watch Addresses

Default addresses (from firmware analysis):

| Key        | Address | Description                       |
|-----------|---------|-----------------------------------|
| X_POS_LO  | $6180   | X coordinate low byte (SHLD tgt)  |
| X_POS_HI  | $6181   | X coordinate high byte            |
| Y_POS_LO  | $61CA   | Y coordinate low byte (LHLD src)  |
| Y_POS_HI  | $61CB   | Y coordinate high byte            |
| PEN_STATE | $63F0   | Bit 0 = pen down (1) / up (0)    |
| PEN_COLOR | $61E8   | Pen number 0–6                   |

## How to Run

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
# → http://localhost:8080/sim/
```

Firmware auto-loads on page load (look for green status message).

## Build bundle.js

```bash
cd sim && node build.js
```

## Known Issues

1. Memory virtual scroll jumps on rapid scroll — debounce pending
2. No INTR/interrupt handling in CPU emulator
3. I/O device stubs are simplified (no real PIT counting, PPI modes)
4. Plotter canvas blank until firmware sends stepper commands
5. USART terminal shows TX bytes but CPU doesn't have interrupt-driven RX

## Next Steps / Roadmap

1. **Label mapping** — import labels from `.asm` listing into disassembly
2. **Step-back** — undo last N instructions
3. **Conditional breakpoints** — break on register/value change
4. **Export trace** — log execution to file
5. **I/O accuracy** — proper PIT timing, PPI mode emulation
6. **Font table viewer** — visualize character data at $5E00-$5FFF
7. **Assembly export** — reassemble modified ROM
8. **Save/restore snapshots** — save CPU+mém+plotter state to file
