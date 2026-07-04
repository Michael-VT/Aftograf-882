/**
 * Autograf-882 Debug Simulator — Main Controller
 *
 * Wires CPU8080, MMU, I/O device stubs, disassembler, and debugger UI.
 */

import { CPU8080 } from './cpu8080.js';
import { MMU } from './memory.js';
import { SettingsManager, DEFAULTS } from './settings.js';

const PEN_COLORS = [
  { name: 'Чёрный',   stroke: '#000000' },
  { name: 'Красный',  stroke: '#cc0000' },
  { name: 'Синий',    stroke: '#0055ff' },
  { name: 'Зелёный',  stroke: '#009900' },
  { name: 'Жёлтый',   stroke: '#ccaa00' },
  { name: 'Фиолетовый',stroke: '#8800cc' },
  { name: 'Голубой',  stroke: '#0099cc' },
];

/* ═══════════════════════════════════════════════════════════════
 * I/O Device Stubs
 * ═══════════════════════════════════════════════════════════════ */

/**
 * КР580ВВ55А (i8255) — Programmable Peripheral Interface
 * 3 ports (A, B, C) + control register.
 */
class PPI8255 {
  constructor(name = 'PPI') {
    this.name = name;
    this.portA = 0;
    this.portB = 0;
    this.portC = 0;
    this.ctrl = 0;
    this.mode = 0;
    this.modeSet = false;
  }

  read(reg) {
    switch (reg) {
      case 0: return this.portA;
      case 1: return this.portB;
      case 2: return this.portC;
      case 3: return this.ctrl; // readback
      default: return 0xff;
    }
  }

  write(reg, val) {
    switch (reg) {
      case 0: this.portA = val; break;
      case 1: this.portB = val; break;
      case 2: this.portC = val; break;
      case 3:
        this.ctrl = val;
        if (val & 0x80) {
          // Mode set
          this.modeSet = true;
          this.mode = (val >> 5) & 0x03;
        }
        // BSR mode (bit set/reset on port C) — val & 0x80 == 0
        break;
    }
  }

  getState() {
    return {
      portA: this.portA, portB: this.portB, portC: this.portC,
      ctrl: this.ctrl,
    };
  }
}

/**
 * КР580ВИ53 (i8253) — Programmable Interval Timer
 * 3 counters, each 16-bit, decrementing.
 */
class PIT8253 {
  constructor() {
    this.ctrl = 0;
    // Counters: { mode, latch, val, initial }
    this.counters = [
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
    ];
    // Access state per counter: 0=LSB, 1=MSB, 2=both (LSB first)
    this.accessMode = [2, 2, 2];
    this.writeToggle = [false, false, false]; // false=LSB, true=MSB
    this.readToggle = [false, false, false];
  }

  read(reg) {
    if (reg >= 0 && reg <= 2) {
      const ctr = this.counters[reg];
      if (ctr.latched) {
        // Latch read — return latched value in two bytes
        const l = ctr.latch;
        if (!this.readToggle[reg]) {
          this.readToggle[reg] = true;
          return l & 0xff;
        } else {
          this.readToggle[reg] = false;
          ctr.latched = false;
          ctr.latch = null;
          return (l >> 8) & 0xff;
        }
      }
      // Direct read — return current value
      const val = ctr.val;
      if (this.accessMode[reg] === 0) {
        // LSB only
        return val & 0xff;
      } else if (this.accessMode[reg] === 1) {
        // MSB only
        return (val >> 8) & 0xff;
      } else {
        // LSB then MSB
        if (!this.readToggle[reg]) {
          this.readToggle[reg] = true;
          return val & 0xff;
        } else {
          this.readToggle[reg] = false;
          return (val >> 8) & 0xff;
        }
      }
    }
    return 0xff; // reg 3 = control register (write-only)
  }

  write(reg, val) {
    if (reg >= 0 && reg <= 2) {
      const ctr = this.counters[reg];
      if (this.accessMode[reg] === 0) {
        ctr.val = (ctr.val & 0xff00) | val;
        ctr.initial = ctr.val;
      } else if (this.accessMode[reg] === 1) {
        ctr.val = (val << 8) | (ctr.val & 0xff);
        ctr.initial = ctr.val;
      } else {
        if (!this.writeToggle[reg]) {
          this.writeToggle[reg] = true;
          ctr.val = (ctr.val & 0xff00) | val;
        } else {
          this.writeToggle[reg] = false;
          ctr.val = (val << 8) | (ctr.val & 0x00ff);
          ctr.initial = ctr.val;
        }
      }
    } else if (reg === 3) {
      this.ctrl = val;
      const sel = (val >> 6) & 0x03;
      if (sel === 3) {
        // Read-back command — ignore for stub
        return;
      }
      // Latch command (bit 5,6 = counter, bit 4 = 0 for latch?)
      if (val & 0x80) {
        // Mode set
        const ctr = this.counters[sel];
        ctr.mode = (val >> 1) & 0x07;
        if (ctr.mode > 5) ctr.mode = 5;
        ctr.bcd = !!(val & 1);
        const rl = (val >> 4) & 0x03;
        this.accessMode[sel] = rl;
        this.writeToggle[sel] = false;
        this.readToggle[sel] = false;
      } else {
        // Latch counter
        const ctr = this.counters[val >> 6];
        if (!ctr.latched) {
          ctr.latch = ctr.val;
          ctr.latched = true;
          this.readToggle[val >> 6] = false;
        }
      }
    }
  }

  /** Tick all counters by 1 cycle (for PIT clock input simulation). */
  tick() {
    for (let i = 0; i < 3; i++) {
      const ctr = this.counters[i];
      ctr.val = (ctr.val - 1) & 0xffff;
      if (ctr.val === 0) {
        ctr.val = ctr.initial; // auto-reload in mode 2/3
      }
    }
  }

  getState() {
    return this.counters.map((c, i) => ({
      mode: c.mode,
      val: c.val,
      initial: c.initial,
    }));
  }
}

/**
 * КР580ВВ51А (i8251) — USART stub.
 */
class USART8251 {
  constructor() {
    this.data = 0;
    this.status = 0x01; // TXRDY bit set
    this.ctrl = 0;
  }

  read(reg) {
    if (reg === 0) {
      // Data register
      this.status &= ~0x02; // clear RXRDY
      return this.data;
    } else {
      // Status register
      return this.status;
    }
  }

  write(reg, val) {
    if (reg === 0) {
      // Transmit data
      this.data = val;
      this.status |= 0x01; // TXRDY
    } else {
      // Control register
      this.ctrl = val;
    }
  }

  getState() {
    return { data: this.data, status: this.status, ctrl: this.ctrl };
  }
}

/* ═══════════════════════════════════════════════════════════════
 * Plotter Simulation
 * ═══════════════════════════════════════════════════════════════ */

/**
 * Simulates the Autograf-882 XY plotter mechanics.
 * Stepper motors: 4-phase (or 2-phase with phase splitting).
 *
 * PPI1 port A → X stepper (bits 0-3 phases, bit 4-7 maybe enable/etc)
 * PPI1 port B → Y stepper (bits 0-3 phases)
 * PPI2 port A → pen control / misc
 * PPI2 port B → auxiliary
 */
class Plotter {
  constructor(mmu, settings) {
    this.mmu = mmu;
    this.settings = settings;
    this.x = 0; this.y = 0;
    this.penDown = false;
    this.penNum = 0;
    this.lastXPhase = 0;
    this.lastYPhase = 0;
    this.xPos = 0;
    this.yPos = 0;
    this.lines = [];
    this.currentSegment = null;
    this.lastMemPenState = -1;
    this.lastMemX = -1;
    this.lastMemY = -1;
    this.lastMemColor = -1;
  }

  syncFromMemory() {
    const s = this.settings;
    const xLo = this.mmu.peek(s.getAddr('X_POS_LO'));
    const xHi = this.mmu.peek(s.getAddr('X_POS_HI'));
    const yLo = this.mmu.peek(s.getAddr('Y_POS_LO'));
    const yHi = this.mmu.peek(s.getAddr('Y_POS_HI'));
    const pState = this.mmu.peek(s.getAddr('PEN_STATE'));
    const pColor = this.mmu.peek(s.getAddr('PEN_COLOR'));

    const memX = (xHi << 8) | xLo;
    const memY = (yHi << 8) | yLo;
    const memPenDown = !!(pState & 0x01);
    const memColor = pColor & 0x07;

    // Координаты из RAM имеют приоритет
    if (memX !== this.lastMemX) {
      this.xPos = memX; this.x = memX;
      this.lastMemX = memX;
    }
    if (memY !== this.lastMemY) {
      this.yPos = memY; this.y = memY;
      this.lastMemY = memY;
    }

    // Состояние пера
    if (memPenDown !== this.lastMemPenState) {
      const wasDown = this.penDown;
      this.penDown = memPenDown;
      this.lastMemPenState = memPenDown;

      if (this.penDown && !wasDown) {
        this.currentSegment = { x1: this.xPos, y1: this.yPos, pen: this.penNum };
      } else if (!this.penDown && wasDown && this.currentSegment) {
        this.currentSegment.x2 = this.xPos;
        this.currentSegment.y2 = this.yPos;
        this.lines.push(this.currentSegment);
        this.currentSegment = null;
      }
    }

    // Номер пера / цвет
    if (memColor !== this.lastMemColor) {
      this.penNum = Math.min(memColor, 6);
      this.lastMemColor = memColor;
    }
  }

  /** Приращение от шагового двигателя (PPI write). */
  updateStepper(axis, phases) {
    const phase = phases & 0x0f;
    if (axis === 'x') {
      if (this.lastXPhase !== phase && this.lastXPhase !== 0) {
        this.xPos += this._stepDir(this.lastXPhase, phase);
        this.x = this.xPos;
      }
      this.lastXPhase = phase;
    } else {
      if (this.lastYPhase !== phase && this.lastYPhase !== 0) {
        this.yPos += this._stepDir(this.lastYPhase, phase);
        this.y = this.yPos;
      }
      this.lastYPhase = phase;
    }
  }

  _stepDir(prev, curr) {
    const ring = [0x1, 0x3, 0x2, 0x6, 0x4, 0xc, 0x8, 0x9];
    const pi = ring.indexOf(prev);
    const ci = ring.indexOf(curr);
    if (pi < 0 || ci < 0) return 0;
    const diff = (ci - pi + 8) % 8;
    return (diff === 1 || diff === 2) ? 1 : -1;
  }

  /** Состояние пера из PPI (запасной источник, пока RAM не пишет). */
  setPen(ctl) {
    if (this.lastMemPenState < 0) {
      const wasDown = this.penDown;
      this.penDown = !(ctl & 0x01);
      const pn = (ctl >> 1) & 0x07;
      if (pn < 7) this.penNum = pn;

      if (this.penDown && !wasDown) {
        this.currentSegment = { x1: this.xPos, y1: this.yPos, pen: this.penNum };
      } else if (!this.penDown && wasDown && this.currentSegment) {
        this.currentSegment.x2 = this.xPos;
        this.currentSegment.y2 = this.yPos;
        this.lines.push(this.currentSegment);
        this.currentSegment = null;
      }
    }
  }

  updatePosition() {
    if (this.penDown && !this.currentSegment) {
      this.currentSegment = { x1: this.xPos, y1: this.yPos, pen: this.penNum };
    }
  }

  reset() {
    this.x = 0; this.y = 0;
    this.xPos = 0; this.yPos = 0;
    this.penDown = false;
    this.penNum = 0;
    this.lastXPhase = 0; this.lastYPhase = 0;
    this.lastMemPenState = -1;
    this.lastMemX = -1; this.lastMemY = -1;
    this.lastMemColor = -1;
    this.lines = [];
    this.currentSegment = null;
  }

  getState() {
    return {
      x: this.xPos, y: this.yPos,
      penDown: this.penDown, penNum: this.penNum,
      lines: this.lines.length,
    };
  }
}

/* ═══════════════════════════════════════════════════════════════
 * Disassembler — reuses CPU opcode table
 * ═══════════════════════════════════════════════════════════════ */

const REG_NAMES = ['B','C','D','E','H','L','M','A'];
const COND_NAMES = ['NZ','Z','NC','C','PO','PE','P','M'];

function buildDisasmTable() {
  const T = new Array(256);

  function def(code, mnem, size) {
    T[code] = { mnemonic: mnem, size };
  }

  for (let d = 0; d < 8; d++) {
    for (let s = 0; s < 8; s++) {
      const code = (d << 3) | s | 0x40;
      if (code === 0x76) { def(0x76, 'HLT', 1); continue; }
      if (d === s) { def(code, 'NOP', 1); continue; }
      const dst = REG_NAMES[d], src = REG_NAMES[s];
      def(code, `MOV ${dst},${src}`, 1);
    }
  }

  def(0x00, 'NOP', 1); def(0x08, 'NOP', 1); def(0x10, 'NOP', 1);
  def(0x18, 'NOP', 1); def(0x20, 'NOP', 1); def(0x28, 'NOP', 1);
  def(0x30, 'NOP', 1); def(0x38, 'NOP', 1);
  def(0xcb, 'NOP', 1); def(0xd9, 'NOP', 1);
  def(0xdd, 'NOP', 1); def(0xed, 'NOP', 1); def(0xfd, 'NOP', 1);

  def(0x01, 'LXI B,$', 3); def(0x11, 'LXI D,$', 3);
  def(0x21, 'LXI H,$', 3); def(0x31, 'LXI SP,$', 3);
  def(0x02, 'STAX B', 1);  def(0x12, 'STAX D', 1);
  def(0x03, 'INX B', 1);   def(0x13, 'INX D', 1);
  def(0x23, 'INX H', 1);   def(0x33, 'INX SP', 1);
  def(0x0b, 'DCX B', 1);   def(0x1b, 'DCX D', 1);
  def(0x2b, 'DCX H', 1);   def(0x3b, 'DCX SP', 1);
  def(0x09, 'DAD B', 1);   def(0x19, 'DAD D', 1);
  def(0x29, 'DAD H', 1);   def(0x39, 'DAD SP', 1);
  def(0x0a, 'LDAX B', 1);  def(0x1a, 'LDAX D', 1);
  def(0x22, 'SHLD $', 3);  def(0x2a, 'LHLD $', 3);
  def(0x32, 'STA $', 3);   def(0x3a, 'LDA $', 3);
  def(0xeb, 'XCHG', 1);    def(0xe3, 'XTHL', 1);
  def(0xf9, 'SPHL', 1);    def(0xe9, 'PCHL', 1);

  const MVI_CODES = [0x06,0x0e,0x16,0x1e,0x26,0x2e,0x36,0x3e];
  for (let i = 0; i < 8; i++) def(MVI_CODES[i], `MVI ${REG_NAMES[i]},$`, 2);

  const INR_CODES = [0x3c,0x04,0x0c,0x14,0x1c,0x24,0x2c,0x34];
  const DCR_CODES = [0x3d,0x05,0x0d,0x15,0x1d,0x25,0x2d,0x35];
  for (let i = 0; i < 8; i++) {
    def(INR_CODES[i], `INR ${REG_NAMES[i]}`, 1);
    def(DCR_CODES[i], `DCR ${REG_NAMES[i]}`, 1);
  }

  // Arithmetic
  const ARITH = ['ADD','ADC','SUB','SBB','ANA','XRA','ORA','CMP'];
  for (let a = 0; a < 8; a++) {
    for (let r = 0; r < 8; r++) def(0x80 + a*8 + r, `${ARITH[a]} ${REG_NAMES[r]}`, 1);
  }
  const IMM_CODES = [0xc6,0xce,0xd6,0xde,0xe6,0xee,0xf6,0xfe];
  for (let i = 0; i < 8; i++) def(IMM_CODES[i], `${ARITH[i]} $`, 2);

  // Rotates
  def(0x07, 'RLC', 1); def(0x0f, 'RRC', 1);
  def(0x17, 'RAL', 1); def(0x1f, 'RAR', 1);
  def(0x2f, 'CMA', 1); def(0x37, 'STC', 1);
  def(0x3f, 'CMC', 1); def(0x27, 'DAA', 1);
  def(0xfb, 'EI', 1);  def(0xf3, 'DI', 1);

  // Jumps
  def(0xc3, 'JMP $', 3); def(0xc2, 'JNZ $', 3);
  def(0xca, 'JZ $', 3);  def(0xd2, 'JNC $', 3);
  def(0xda, 'JC $', 3);  def(0xe2, 'JPO $', 3);
  def(0xea, 'JPE $', 3); def(0xf2, 'JP $', 3);
  def(0xfa, 'JM $', 3);

  // Calls
  def(0xcd, 'CALL $', 3); def(0xc4, 'CNZ $', 3);
  def(0xcc, 'CZ $', 3);   def(0xd4, 'CNC $', 3);
  def(0xdc, 'CC $', 3);   def(0xe4, 'CPO $', 3);
  def(0xec, 'CPE $', 3);  def(0xf4, 'CP $', 3);
  def(0xfc, 'CM $', 3);

  // Returns
  def(0xc9, 'RET', 1); def(0xc0, 'RNZ', 1);
  def(0xc8, 'RZ', 1);  def(0xd0, 'RNC', 1);
  def(0xd8, 'RC', 1);  def(0xe0, 'RPO', 1);
  def(0xe8, 'RPE', 1); def(0xf0, 'RP', 1);
  def(0xf8, 'RM', 1);

  // RST
  for (let i = 0; i < 8; i++) def(0xc7 | (i << 3), `RST ${i}`, 1);

  // PUSH/POP
  def(0xc5, 'PUSH B', 1);  def(0xd5, 'PUSH D', 1);
  def(0xe5, 'PUSH H', 1);  def(0xf5, 'PUSH PSW', 1);
  def(0xc1, 'POP B', 1);   def(0xd1, 'POP D', 1);
  def(0xe1, 'POP H', 1);   def(0xf1, 'POP PSW', 1);

  // IN/OUT
  def(0xdb, 'IN $', 2);    def(0xd3, 'OUT $', 2);

  return T;
}

function disasmInstruction(mmu, addr) {
  const opcode = mmu.peek(addr);
  const entry = DISASM_TABLE[opcode];
  if (!entry) {
    return { addr, opcode, mnemonic: 'DB $' + opcode.toString(16).padStart(2,'0').toUpperCase(), size: 1, operands: '' };
  }
  let mnem = entry.mnemonic;
  const size = entry.size;
  let operands = '';
  if (size >= 2) {
    const b1 = mmu.peek(addr + 1);
    if (size === 2) {
      mnem = mnem.replace('$', b1.toString(16).padStart(2,'0').toUpperCase());
    } else {
      const b2 = mmu.peek(addr + 2);
      const word = (b2 << 8) | b1;
      mnem = mnem.replace('$', word.toString(16).padStart(4,'0').toUpperCase());
    }
  }
  return { addr, opcode, mnemonic: mnem, size, operands };
}

const DISASM_TABLE = buildDisasmTable();

/* ═══════════════════════════════════════════════════════════════
 * Port annotation helpers
 * ═══════════════════════════════════════════════════════════════ */

const PORT_NAMES = {
  0xe000: 'PPI1-A', 0xe001: 'PPI1-B', 0xe002: 'PPI1-C', 0xe003: 'PPI1-CTRL',
  0xe400: 'PPI2-A', 0xe401: 'PPI2-B', 0xe402: 'PPI2-C', 0xe403: 'PPI2-CTRL',
  0xe800: 'PIT-CNT0', 0xe801: 'PIT-CNT1', 0xe802: 'PIT-CNT2', 0xe803: 'PIT-CTRL',
  0xec00: 'USART-DATA', 0xec01: 'USART-CTRL',
};

/* ═══════════════════════════════════════════════════════════════
 * App Controller
 * ═══════════════════════════════════════════════════════════════ */

class App {
  constructor() {
    try {
      this._construct();
    } catch (e) {
      console.error('[AFTOGRAF] CONSTRUCTOR CRASH:', e);
      this._showFatalError(e);
    }
  }

  _showFatalError(e) {
    // Показываем ошибку прямо на странице, если всё упало
    const root = document.getElementById('app') || document.body;
    const div = document.createElement('div');
    div.style.cssText = 'padding:20px;margin:20px;background:#1a1b26;border:2px solid #f7768e;border-radius:8px;font-family:monospace;font-size:13px;color:#f7768e';
    div.innerHTML = '<h3 style="color:#f7768e;margin:0 0 10px 0">⛔ JavaScript Error</h3>'
      + '<pre style="white-space:pre-wrap;color:#c0caf5;margin:0">'
      + (e?.stack || e?.message || String(e))
      + '</pre>'
      + '<p style="color:#565f89;margin:10px 0 0 0">Открой F12 → Console для деталей</p>';
    root.prepend(div);
  }

  _construct() {
    // Settings (из localStorage)
    this.settings = new SettingsManager();
    // I/O devices
    this.ppi1 = new PPI8255('PPI1');
    this.ppi2 = new PPI8255('PPI2');
    this.pit = new PIT8253();
    this.uart = new USART8251();

    // Memory
    this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);

    // CPU
    this.cpu = new CPU8080(
      (addr) => this.mmu.readByte(addr),
      (addr, val) => this.mmu.writeByte(addr, val)
    );

    // Plotter
    this.plotter = new Plotter(this.mmu, this.settings);

    // State
    this.running = false;
    this.paused = false;
    this.runTimer = null;
    this.romLoaded = false;
    this.breakpoints = new Set();
    this.speedTable = [0, 100, 1000, 10000, 100000, 1000000];
    this.labelMap = {};

    // Disassembly cache
    this.disasmCache = [];
    this.disasmAddr = 0;

    // DOM refs — отказоустойчиво
    this._cacheDOM();
    this._bindEvents();
    this._resetState();

    // Build initial disassembly
    this._rebuildDisasm(0);
    this._updateMemoryDump(0x6000);
    this._updateIO();
  }

  _cacheDOM() {
    this.$ = (id) => document.getElementById(id);
    this.els = {
      status: this.$('status'),
      cycleCount: this.$('cycle-count'),
      ipDisplay: this.$('ip-display'),
      regA: this.$('reg-a'), regB: this.$('reg-b'), regC: this.$('reg-c'),
      regD: this.$('reg-d'), regE: this.$('reg-e'), regH: this.$('reg-h'),
      regL: this.$('reg-l'), regSP: this.$('reg-sp'), regPC: this.$('reg-pc'),
      regF: this.$('reg-f'),
      flagS: this.$('flag-s'), flagZ: this.$('flag-z'),
      flagAC: this.$('flag-ac'), flagP: this.$('flag-p'),
      flagCY: this.$('flag-cy'),
      currentInsn: this.$('current-insn'),
      currentBytes: this.$('current-bytes'),
      asmList: this.$('asm-list'),
      asmSearch: this.$('asm-search'),
      asmFollowPc: this.$('asm-follow-pc'),
      memDump: this.$('mem-dump'),
      memAddr: this.$('mem-addr'),
      memRefresh: this.$('mem-refresh'),
      ioPanel: this.$('io-panel'),
      btnReset: this.$('btn-reset'),
      btnStep: this.$('btn-step'),
      btnRun: this.$('btn-run'),
      btnPause: this.$('btn-pause'),
      speedSlider: this.$('speed-slider'),
      speedLabel: this.$('speed-label'),
      btnLoadRom: this.$('btn-load-rom'),
      romFileInput: this.$('rom-file-input'),
      plotterCanvas: this.$('plotter-canvas'),
      plotterPos: this.$('plotter-pos'),
      plotterPen: this.$('plotter-pen'),
      plotterPenNum: this.$('plotter-pen-num'),
      loadStatus: this.$('load-status'),
      plotterColor: this.$('plotter-color'),
      btnSettings: this.$('btn-settings'),
      stackDisplay: this.$('stack-display'),
      pointersDisplay: this.$('pointers-display'),
    };
  }

  _bindEvents() {
    this.els.btnReset.addEventListener('click', () => this.reset());
    this.els.btnStep.addEventListener('click', () => this.step());
    this.els.btnRun.addEventListener('click', () => this.run());
    this.els.btnPause.addEventListener('click', () => this.pause());
    this.els.speedSlider.addEventListener('input', () => {
      const idx = parseInt(this.els.speedSlider.value);
      const speeds = ['∞ (макс)', '100 Hz', '1 KHz', '10 KHz', '100 KHz', '1 MHz'];
      this.els.speedLabel.textContent = speeds[idx];
    });
    this.els.btnLoadRom.addEventListener('click', () => this.els.romFileInput.click());
    this.els.btnSettings.addEventListener('click', () => {
      console.log('[AFTOGRAF] Settings button clicked');
      this._openSettings();
    });
    this.els.romFileInput.addEventListener('change', (e) => this._handleROMFiles(e));
    this.els.asmSearch.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        const addr = parseInt(this.els.asmSearch.value, 16);
        if (!isNaN(addr)) this._rebuildDisasm(addr);
      }
    });
    this.els.memRefresh.addEventListener('click', () => {
      const addr = parseInt(this.els.memAddr.value, 16);
      if (!isNaN(addr)) this._updateMemoryDump(addr);
    });
    this.els.memAddr.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        this.els.memRefresh.click();
      }
    });
  }

  _resetState() {
    this.paused = false;
    this.running = false;
    if (this.runTimer) { clearInterval(this.runTimer); this.runTimer = null; }
    this.els.btnRun.disabled = false;
    this.els.btnPause.disabled = true;
    this.els.btnStep.disabled = !this.romLoaded;
    this._updateStatusBar();
  }

  _updateStatusBar() {
    const s = this.els.status;
    if (this.cpu.halt) {
      s.textContent = 'HLT';
      s.className = 'status-stopped';
      if (this.running) this.pause();
    } else if (this.running) {
      s.textContent = 'RUNNING';
      s.className = 'status-running';
    } else if (this.paused) {
      s.textContent = 'PAUSED';
      s.className = 'status-paused';
    } else {
      s.textContent = 'STOPPED';
      s.className = 'status-stopped';
    }
    this.els.cycleCount.textContent = `${this.cpu.cycles} T-states`;
    this.els.ipDisplay.textContent = `PC: ${this.cpu.pc.toString(16).padStart(4,'0').toUpperCase()}`;
  }
  /** Load ROM from file input.
   *  Поддерживает:
   *  - Один файл 24KB (firmware.bin) — все 3 чипа сразу
   *  - Один файл 8KB — загружается как Chip 1
   *  - Три файла 8KB — загружаются по порядку
   */
  async _handleROMFiles(event) {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    const buffers = [];
    for (const file of files) {
      const buf = await file.arrayBuffer();
      buffers.push(new Uint8Array(buf));
    }

    const totalBytes = buffers.reduce((s, b) => s + b.length, 0);

    // Создаём новый MMU
    this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);

    if (buffers.length === 1 && buffers[0].length === 0x6000) {
      // Один файл 24KB — firmware.bin
      this.mmu.loadROM(buffers[0], 0x0000);
      this._setLoadStatus(`Загружена прошивка 24KB (3 чипа)`, 'ok');
    } else if (buffers.length === 1 && buffers[0].length === 0x2000) {
      // Один чип 8KB
      this.mmu.loadROM(buffers[0], 0x0000);
      this._setLoadStatus(`Загружен Chip 1 (8KB)`, 'ok');
    } else {
      // Несколько файлов — по порядку
      const sorted = Array.from(buffers).sort((a, b) => a.length - b.length);
      for (let i = 0; i < Math.min(sorted.length, 3); i++) {
        this.mmu.loadROM(sorted[i], i * 0x2000);
      }
      this._setLoadStatus(`Загружено ${Math.min(sorted.length, 3)} чипа(ов)`, 'ok');
    }

    this.romLoaded = true;

    // Пересоздаём CPU с новым MMU
    this.cpu = new CPU8080(
      (addr) => this.mmu.readByte(addr),
      (addr, val) => this.mmu.writeByte(addr, val)
    );
    this.plotter.reset();
    this.breakpoints.clear();

    this._resetState();
    this._rebuildDisasm(0);
    this._updateMemoryDump(0x6000);
    this._updateIO();
    this._updatePlotterUI();
    this.els.btnStep.disabled = false;
  }

  _setLoadStatus(msg, type) {
    const el = this.els.loadStatus;
    if (!el) return;
    el.textContent = msg;
    el.className = 'load-status-' + (type || 'info');
    el.style.display = 'block';
    if (type === 'ok') {
      setTimeout(() => { el.style.display = 'none'; }, 5000);
    }
  }

  /* ═══════════════════════════════════
   * Settings Panel
   * ═══════════════════════════════════ */

  _openSettings() {
    try {
      console.log('[AFTOGRAF] Opening settings panel...');
      if (document.getElementById('settings-overlay')) {
        console.log('[AFTOGRAF] Settings already open');
        return;
      }
      const div = document.createElement('div');
      div.innerHTML = this.settings.renderPanel();
      const panel = div.firstElementChild;
      if (!panel) {
        console.error('[AFTOGRAF] renderPanel returned empty');
        return;
      }
      document.body.appendChild(panel);
      console.log('[AFTOGRAF] Settings panel appended to DOM');
      this._bindSettingsEvents();
      console.log('[AFTOGRAF] Settings events bound');
    } catch (err) {
      console.error('[AFTOGRAF] _openSettings error:', err);
    }
  }

  _closeSettings() {
    const overlay = document.getElementById('settings-overlay');
    if (!overlay) return;

    // Применяем изменения адресов переменных
    document.querySelectorAll('.cfg-var-addr').forEach(inp => {
      const key = inp.dataset.key;
      const raw = inp.value.replace(/^\$/, '');
      const addr = parseInt(raw, 16);
      if (!isNaN(addr)) this.settings.setAddr(key, addr);
    });

    // Применяем изменения адресов чипов
    document.querySelectorAll('.cfg-chip-offset').forEach(inp => {
      const idx = parseInt(inp.dataset.idx);
      const raw = inp.value.replace(/^\$/, '');
      const offset = parseInt(raw, 16);
      if (!isNaN(offset)) this.settings.setChipOffset(idx, offset);
    });

    this.settings.save();
    overlay.remove();
  }

  _bindSettingsEvents() {
    const overlay = document.getElementById('settings-overlay');
    if (!overlay) return;

    // Закрытие
    overlay.querySelector('#settings-close').addEventListener('click', () => this._closeSettings());
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) this._closeSettings();
    });
    // Escape
    const onKey = (e) => { if (e.key === 'Escape') this._closeSettings(); };
    document.addEventListener('keydown', onKey);
    // Clean up listener when closed
    const origClose = this._closeSettings.bind(this);
    this._closeSettings = () => { document.removeEventListener('keydown', onKey); origClose(); };

    // Загрузка ROM из настроек
    const loadBtn = overlay.querySelector('#settings-load-rom');
    const fileInput = overlay.querySelector('#settings-rom-input');
    loadBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', (e) => this._handleSettingsROM(e, overlay));

    // Сохранить / Сбросить
    overlay.querySelector('#settings-save').addEventListener('click', () => {
      this._closeSettings();
      this._setLoadStatus('Настройки сохранены', 'ok');
    });
    overlay.querySelector('#settings-reset').addEventListener('click', () => {
      this.settings.reset();
      overlay.remove();
      this._openSettings();
      this._setLoadStatus('Настройки сброшены', 'ok');
    });

    // Кастомные переменные
    overlay.querySelector('#settings-custom-add').addEventListener('click', () => {
      this.settings.addCustom('var' + (this.settings.config.custom.length + 1), 0x6000);
      overlay.remove();
      this._openSettings();
    });
    overlay.querySelector('#settings-custom-remove')?.addEventListener('click', (e) => {
      if (e.target.classList.contains('cfg-custom-remove')) {
        this.settings.removeCustom(parseInt(e.target.dataset.id));
        overlay.remove();
        this._openSettings();
      }
    });
    // Delegate remove clicks on table
    // Use event delegation for remove buttons
    overlay.querySelector('#custom-vars-table tbody').addEventListener('click', (e) => {
      const btn = e.target.closest('.cfg-custom-remove');
      if (btn) {
        this.settings.removeCustom(parseInt(btn.dataset.id));
        overlay.remove();
        this._openSettings();
      }
    });

    // Чтение кастомных переменных
    overlay.querySelector('#settings-custom-read').addEventListener('click', () => {
      this._readCustomVars(overlay);
    });
  }

  async _handleSettingsROM(event, overlay) {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    const addrInput = overlay.querySelector('#settings-load-addr');
    const rawAddr = addrInput.value.replace(/^\$/, '');
    const loadAddr = parseInt(rawAddr, 16) || 0;
    const statusEl = overlay.querySelector('#settings-load-status');

    try {
      const buf = await files[0].arrayBuffer();
      const data = new Uint8Array(buf);
      const sizeKB = (data.length / 1024).toFixed(1);

      // Создаём новый MMU
      this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);

      // Загружаем по указанному адресу
      this.mmu.loadROM(data, loadAddr);

      // Если файл 24KB, загружаем в $0000 (все 3 чипа)
      // Если файл 8KB — в указанный адрес

      this.romLoaded = true;
      this.cpu = new CPU8080(
        (addr) => this.mmu.readByte(addr),
        (addr, val) => this.mmu.writeByte(addr, val)
      );
      this.plotter.reset();
      this.breakpoints.clear();
      this._resetState();
      this._rebuildDisasm(loadAddr);
      this._updateAll();
      this.els.btnStep.disabled = false;

      statusEl.textContent = `✓ Загружено ${sizeKB}KB по адресу $${loadAddr.toString(16).padStart(4,'0').toUpperCase()}`;
      statusEl.style.display = 'block';
      statusEl.className = 'load-status-ok';
    } catch (e) {
      statusEl.textContent = `✕ Ошибка: ${e.message}`;
      statusEl.style.display = 'block';
      statusEl.className = 'load-status-error';
    }
  }

  _readCustomVars(overlay) {
    const readout = overlay.querySelector('#custom-readout');
    const custom = this.settings.config.custom;
    if (custom.length === 0) {
      readout.innerHTML = '<div style="color:var(--text-dim)">Нет переменных для чтения</div>';
      return;
    }

    // Читаем текущие значения из input'ов (могут быть изменены)
    overlay.querySelectorAll('.cfg-custom-addr').forEach(inp => {
      const id = parseInt(inp.dataset.id);
      const raw = inp.value.replace(/^\$/, '');
      const addr = parseInt(raw, 16);
      const c = custom.find(c => c.id === id);
      if (c && !isNaN(addr)) c.addr = addr;
    });

    let html = '';
    for (const c of custom) {
      let val;
      if (c.size === 2) {
        const lo = this.mmu.peek(c.addr);
        const hi = this.mmu.peek(c.addr + 1);
        val = (hi << 8) | lo;
        html += `<div class="readout-row"><span class="readout-name">${c.name}:</span><span>$${val.toString(16).padStart(4,'0').toUpperCase()} (${val})</span></div>`;
      } else {
        val = this.mmu.peek(c.addr);
        html += `<div class="readout-row"><span class="readout-name">${c.name}:</span><span>$${val.toString(16).padStart(2,'0').toUpperCase()} (${val})</span></div>`;
      }
    }
    readout.innerHTML = html;
  }

  /** Reset CPU and state. */
  reset() {
    this._resetState();
    this.cpu.reset();
    this.plotter.reset();
    this._updateAll();
  }

  /** Single step. */
  step() {
    if (!this.romLoaded) return;
    if (this.cpu.halt) return;
    this.paused = true;
    this.running = false;

    const pcBefore = this.cpu.pc;
    this.cpu.step();

    // Update plotter based on I/O writes
    this._syncPlotter();

    this._updateAll();
    if (this.els.asmFollowPc.checked) {
      this._ensureVisible(this.cpu.pc);
    }
  }

  /** Continuous run. */
  run() {
    if (!this.romLoaded || this.cpu.halt) return;
    this.running = true;
    this.paused = false;
    this.els.btnRun.disabled = true;
    this.els.btnPause.disabled = false;
    this.els.btnStep.disabled = true;

    const speedIdx = parseInt(this.els.speedSlider.value);
    const speed = this.speedTable[speedIdx];

    if (speed === 0) {
      // Maximum speed — run in chunks via setTimeout
      this._runMax();
    } else {
      // Timed stepping
      this.runTimer = setInterval(() => {
        if (!this.running || this.cpu.halt) {
          this.pause();
          return;
        }
        const stepsPerTick = Math.max(1, Math.floor(speed / 30));
        for (let i = 0; i < stepsPerTick; i++) {
          if (this.cpu.halt) break;
          const pcBefore = this.cpu.pc;
          this.cpu.step();
          this._syncPlotter();
          // Check breakpoints
          if (this.breakpoints.has(this.cpu.pc)) {
            this.pause();
            break;
          }
        }
        this._updateAll();
      }, 33); // ~30 fps
    }
  }

  _runMax() {
    const BATCH = 5000;
    const tick = () => {
      if (!this.running || this.cpu.halt) {
        this.pause();
        return;
      }
      for (let i = 0; i < BATCH; i++) {
        if (this.cpu.halt) break;
        const pcBefore = this.cpu.pc;
        this.cpu.step();
        this._syncPlotter();
        if (this.breakpoints.has(this.cpu.pc)) {
          this.pause();
          this._updateAll();
          return;
        }
      }
      this._updateAll();
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }

  /** Pause execution. */
  pause() {
    this.running = false;
    this.paused = true;
    if (this.runTimer) { clearInterval(this.runTimer); this.runTimer = null; }
    this.els.btnRun.disabled = false;
    this.els.btnPause.disabled = true;
    this.els.btnStep.disabled = !this.romLoaded;
    if (this.els.asmFollowPc.checked) {
      this._ensureVisible(this.cpu.pc);
    }
    this._updateAll();
  }

  /** Sync plotter state from I/O registers after execution. */
  /** Sync plotter state from RAM addresses (PLOTTER_CFG) + PPI writes. */
  _syncPlotter() {
    // Читаем координаты/перо из RAM (основной источник)
    this.plotter.syncFromMemory();
    // PPI writes — запасной источник для шаговых двигателей
    this.plotter.updateStepper('x', this.ppi1.portA);
    this.plotter.updateStepper('y', this.ppi1.portB);
    this.plotter.setPen(this.ppi2.portA);
    this.plotter.updatePosition();
  }

  /** Update all UI elements. */
  _updateAll() {
    this._updateRegisters();
    this._updateStatusBar();
    this._updateCurrentInsn();
    this._updateDisasmHighlights();
    this._updateMemoryDump(parseInt(this.els.memAddr?.value, 16) || 0x6000);
    this._updateIO();
    this._updatePlotterUI();
    this._updateStack();
    this._updatePointers();
    this._renderPlotterCanvas();
  }

  /** Update register display. */
  _updateRegisters() {
    const s = this.cpu.getState();
    this.els.regA.textContent = s.a.toString(16).padStart(2,'0').toUpperCase();
    this.els.regB.textContent = s.b.toString(16).padStart(2,'0').toUpperCase();
    this.els.regC.textContent = s.c.toString(16).padStart(2,'0').toUpperCase();
    this.els.regD.textContent = s.d.toString(16).padStart(2,'0').toUpperCase();
    this.els.regE.textContent = s.e.toString(16).padStart(2,'0').toUpperCase();
    this.els.regH.textContent = s.h.toString(16).padStart(2,'0').toUpperCase();
    this.els.regL.textContent = s.l.toString(16).padStart(2,'0').toUpperCase();
    this.els.regSP.textContent = s.sp.toString(16).padStart(4,'0').toUpperCase();
    this.els.regPC.textContent = s.pc.toString(16).padStart(4,'0').toUpperCase();
    this.els.regF.textContent = s.flags.toString(16).padStart(2,'0').toUpperCase();

    // Flags
    this.els.flagS.classList.toggle('active', !!(s.flags & 0x80));
    this.els.flagZ.classList.toggle('active', !!(s.flags & 0x40));
    this.els.flagAC.classList.toggle('active', !!(s.flags & 0x10));
    this.els.flagP.classList.toggle('active', !!(s.flags & 0x04));
    this.els.flagCY.classList.toggle('active', !!(s.flags & 0x01));
  }

  /** Show current instruction. */
  _updateCurrentInsn() {
    const pc = this.cpu.pc;
    const insn = disasmInstruction(this.mmu, pc);
    // Raw bytes
    let bytes = '';
    for (let i = 0; i < insn.size; i++) {
      bytes += this.mmu.peek(pc + i).toString(16).padStart(2,'0').toUpperCase() + ' ';
    }
    this.els.currentInsn.textContent = insn.mnemonic;
    this.els.currentBytes.textContent = bytes.trim();
  }

  /** Build disassembly listing around given address. */
  _rebuildDisasm(addr) {
    const NUM_LINES = 256;
    const half = NUM_LINES / 2;
    const start = Math.max(0, addr - half * 2); // 2 bytes per line avg

    this.disasmAddr = start;
    this.disasmCache = [];
    let a = start;
    for (let i = 0; i < NUM_LINES && a < 0x10000; i++) {
      if (a >= 0x6000 && a < 0xe000) break; // unmapped
      const insn = disasmInstruction(this.mmu, a);
      this.disasmCache.push(insn);
      a += insn.size;
    }
    this._renderDisasm();
  }

  _renderDisasm() {
    const list = this.els.asmList;
    list.innerHTML = '';
    const pc = this.cpu.pc;

    for (const insn of this.disasmCache) {
      const line = document.createElement('div');
      line.className = 'asm-line';
      if (this.breakpoints.has(insn.addr)) line.classList.add('bp-set');
      if (insn.addr === pc) line.classList.add('current');

      const bp = this.breakpoints.has(insn.addr) ? '●' : ' ';
      const mnem = insn.mnemonic.split(' ')[0];
      const oper = insn.mnemonic.includes(' ') ? insn.mnemonic.slice(insn.mnemonic.indexOf(' ')+1) : '';

      // Аннотация: адрес перехода для JMP/CALL
      let annot = '';
      if (['JMP','CALL','JNZ','JZ','JNC','JC','JPO','JPE','JP','JM','CNZ','CZ','CNC','CC','CPO','CPE','CP','CM'].includes(mnem)) {
        const addr = parseInt(oper.replace(/^0x/i,''), 16);
        if (!isNaN(addr)) {
          const b = this.mmu.peek(addr);
          annot = `; → $${oper} ($${b.toString(16).padStart(2,'0').toUpperCase()})`;
        }
      } else if (['LDA','STA','LHLD','SHLD'].includes(mnem)) {
        const addr = parseInt(oper.replace(/^0x/i,''), 16);
        if (!isNaN(addr)) {
          const val = this.mmu.peek(addr);
          annot = `; [$${addr.toString(16).padStart(4,'0').toUpperCase()}]=$${val.toString(16).padStart(2,'0').toUpperCase()}`;
        }
      } else if (['OUT','IN'].includes(mnem)) {
        const port = parseInt(oper, 16);
        const name = PORT_NAMES[0xe000 | port] || '';
        if (name) annot = `; ${name}`;
      }

      line.innerHTML = `
        <span class="asm-bp">${bp}</span>
        <span class="asm-addr">${insn.addr.toString(16).padStart(4,'0').toUpperCase()}</span>
        <span class="asm-bytes">${this._formatRawBytes(insn)}</span>
        <span class="asm-mnemonic">${mnem}</span>
        <span class="asm-operands">${oper}</span>
        <span class="asm-annot">${annot}</span>
      `;

      line.addEventListener('click', () => {
        if (this.breakpoints.has(insn.addr)) {
          this.breakpoints.delete(insn.addr);
        } else {
          this.breakpoints.add(insn.addr);
        }
        this._renderDisasm();
      });

      list.appendChild(line);
    }
  }

  _formatRawBytes(insn) {
    let s = '';
    for (let i = 0; i < insn.size; i++) {
      s += this.mmu.peek(insn.addr + i).toString(16).padStart(2,'0').toUpperCase() + ' ';
    }
    return s.padEnd(9);
  }

  _updateDisasmHighlights() {
    // Re-render to highlight current line
    const pc = this.cpu.pc;
    const lines = this.els.asmList.querySelectorAll('.asm-line');
    let idx = 0;
    for (const insn of this.disasmCache) {
      if (idx >= lines.length) break;
      lines[idx].classList.toggle('current', insn.addr === pc);
      idx++;
    }
  }

  _ensureVisible(addr) {
    // Check if addr is in current cache range
    const first = this.disasmCache[0];
    const last = this.disasmCache[this.disasmCache.length - 1];
    if (!first || !last) return;
    if (addr < first.addr || addr > last.addr) {
      this._rebuildDisasm(addr);
      return;
    }
    // Scroll to the line
    const lines = this.els.asmList.querySelectorAll('.asm-line');
    for (let i = 0; i < this.disasmCache.length && i < lines.length; i++) {
      if (this.disasmCache[i].addr === addr) {
        lines[i].scrollIntoView({ block: 'center' });
        break;
      }
    }
  }

  /** Memory dump at given address. */
  _updateMemoryDump(addr) {
    const dump = this.els.memDump;
    dump.innerHTML = '';
    const start = addr & 0xfff0;
    const rows = 16;

    for (let r = 0; r < rows; r++) {
      const base = start + r * 16;
      const line = document.createElement('div');
      line.className = 'mem-line';
      let addrStr = base.toString(16).padStart(4,'0').toUpperCase();
      let hex = '';
      let ascii = '';

      for (let c = 0; c < 16; c++) {
        const byteVal = this.mmu.peek(base + c);
        hex += byteVal.toString(16).padStart(2,'0').toUpperCase() + ' ';
        ascii += (byteVal >= 0x20 && byteVal <= 0x7e) ? String.fromCharCode(byteVal) : '.';
      }

      line.innerHTML = `
        <span class="mem-addr">${addrStr}</span>
        <span class="mem-hex">${hex}</span>
        <span class="mem-ascii">${ascii}</span>
      `;
      dump.appendChild(line);
    }
  }

  /** I/O device state panel. */
  _updateIO() {
    const panel = this.els.ioPanel;
    panel.innerHTML = `
      <div class="io-block">
        <div class="io-name">Порт 8253 (таймер)</div>
        <div>${this.pit.counters.map((c,i) =>
          `<span class="io-reg">CNT${i}: <span class="io-reg-val">${c.val.toString(16).padStart(4,'0').toUpperCase()}</span> (mode=${c.mode})</span>`
        ).join('<br>')}</div>
      </div>
      <div class="io-block">
        <div class="io-name">Порт КР580ВВ55А #1</div>
        <div><span class="io-reg">A: <span class="io-reg-val">${this.ppi1.portA.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">B: <span class="io-reg-val">${this.ppi1.portB.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">C: <span class="io-reg-val">${this.ppi1.portC.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
      </div>
      <div class="io-block">
        <div class="io-name">Порт КР580ВВ55А #2</div>
        <div><span class="io-reg">A: <span class="io-reg-val">${this.ppi2.portA.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">B: <span class="io-reg-val">${this.ppi2.portB.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">C: <span class="io-reg-val">${this.ppi2.portC.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
      </div>
      <div class="io-block">
        <div class="io-name">USART</div>
        <div><span class="io-reg">DATA: <span class="io-reg-val">${this.uart.data.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">STATUS: <span class="io-reg-val">${this.uart.status.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
      </div>
    `;
  }

  /** Update plotter position info. */
  _updatePlotterUI() {
    const set = (el, val) => { if (el) el.textContent = val; };
    set(this.els.plotterPos, `X: ${this.plotter.xPos} Y: ${this.plotter.yPos}`);
    set(this.els.plotterPen, `Перо: ${this.plotter.penDown ? 'Вниз' : 'Вверх'}`);
    set(this.els.plotterPenNum, `Перо #${this.plotter.penNum + 1}`);
    const c = PEN_COLORS[this.plotter.penNum] || PEN_COLORS[0];
    set(this.els.plotterColor, c.name);
    if (this.els.plotterColor) this.els.plotterColor.style.color = c.stroke;
  }

  /** Stack view — последние 8 слов. */
  _updateStack() {
    const el = this.els.stackDisplay;
    if (!el) return;
    const sp = this.cpu.sp;
    let html = '';
    for (let i = 0; i < 8; i++) {
      const addr = (sp + i * 2) & 0xffff;
      const lo = this.mmu.peek(addr);
      const hi = this.mmu.peek(addr + 1);
      const val = (hi << 8) | lo;
      const marker = i === 0 ? '→ SP' : '    ';
      html += `<div style="display:flex;gap:8px;font:11px monospace">
        <span style="color:var(--text-dim);min-width:40px">${marker}</span>
        <span style="color:var(--hl);width:48px">$${addr.toString(16).padStart(4,'0').toUpperCase()}</span>
        <span>$${val.toString(16).padStart(4,'0').toUpperCase()}</span>
      </div>`;
    }
    el.innerHTML = html;
  }

  /** Pointer preview — HL, DE, BC + SP, PC. */
  _updatePointers() {
    const el = this.els.pointersDisplay;
    if (!el) return;
    const s = this.cpu.getState();
    const pw = (a) => (this.mmu.peek(a+1) << 8) | this.mmu.peek(a);
    const pb = (a) => this.mmu.peek(a);
    const pairs = [
      { n: 'HL', v: (s.h << 8) | s.l },
      { n: 'DE', v: (s.d << 8) | s.e },
      { n: 'BC', v: (s.b << 8) | s.c },
    ];
    let html = '';
    for (const p of pairs) {
      html += `<div style="display:flex;gap:8px;font:11px monospace">
        <span style="color:var(--cyan);width:24px">${p.n}</span>
        <span style="color:var(--hl);width:48px">$${p.v.toString(16).padStart(4,'0').toUpperCase()}</span>
        <span>→ [$${pw(p.v).toString(16).padStart(4,'0').toUpperCase()}]</span>
        <span style="color:var(--text-dim)">B:$${pb(p.v).toString(16).padStart(2,'0').toUpperCase()}</span>
      </div>`;
    }
    html += `<div style="display:flex;gap:8px;font:11px monospace">
      <span style="color:var(--cyan);width:24px">SP</span>
      <span style="color:var(--hl);width:48px">$${s.sp.toString(16).padStart(4,'0').toUpperCase()}</span>
      <span>→ [$${pw(s.sp).toString(16).padStart(4,'0').toUpperCase()}]</span>
    </div>
    <div style="display:flex;gap:8px;font:11px monospace">
      <span style="color:var(--cyan);width:24px">PC</span>
      <span style="color:var(--hl);width:48px">$${s.pc.toString(16).padStart(4,'0').toUpperCase()}</span>
      <span>→ [$${pw(s.pc).toString(16).padStart(4,'0').toUpperCase()}]</span>
    </div>`;
    el.innerHTML = html;
  }

  /** Draw accumulated plotter lines onto canvas. */
  _renderPlotterCanvas() {
    const canvas = this.els.plotterCanvas;
    const ctx = canvas.getContext('2d');
    const w = canvas.width, h = canvas.height;

    ctx.fillStyle = '#f5f0e8';
    ctx.fillRect(0, 0, w, h);

    if (this.plotter.lines.length === 0) {
      ctx.fillStyle = '#b8b0a0';
      ctx.textAlign = 'center';
      ctx.fillText('Ожидание команд плоттера…', w / 2, h / 2);
      return;
    }

    // Scale and center
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (const seg of this.plotter.lines) {
      minX = Math.min(minX, seg.x1, seg.x2);
      maxX = Math.max(maxX, seg.x1, seg.x2);
      minY = Math.min(minY, seg.y1, seg.y2);
      maxY = Math.max(maxY, seg.y1, seg.y2);
    }

    const rangeX = maxX - minX || 1;
    const rangeY = maxY - minY || 1;
    const margin = 30;
    const scale = Math.min((w - 2*margin) / rangeX, (h - 2*margin) / rangeY);

    const sx = (x) => margin + (x - minX) * scale;
    const sy = (y) => h - margin - (y - minY) * scale;

    // Draw grid
    ctx.strokeStyle = '#d8d0c0';
    ctx.lineWidth = 0.5;
    for (let g = 0; g < 10; g++) {
      const x = margin + (w - 2*margin) * g / 10;
      const y = margin + (h - 2*margin) * g / 10;
      ctx.beginPath(); ctx.moveTo(x, margin); ctx.lineTo(x, h - margin); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(margin, y); ctx.lineTo(w - margin, y); ctx.stroke();
    }

    // Draw lines
    ctx.lineWidth = 2;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    for (const seg of this.plotter.lines) {
      const c = PEN_COLORS[seg.pen] || PEN_COLORS[0];
      ctx.strokeStyle = c.stroke;
      ctx.beginPath();
      ctx.moveTo(sx(seg.x1), sy(seg.y1));
      ctx.lineTo(sx(seg.x2), sy(seg.y2));
      ctx.stroke();
    }

    // Текущая позиция
    const cx = sx(this.plotter.xPos);
    const cy = sy(this.plotter.yPos);
    ctx.beginPath();
    ctx.arc(cx, cy, 5, 0, Math.PI * 2);
    ctx.fillStyle = this.plotter.penDown ? '#cc0000' : '#3366cc';
    ctx.fill();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1.5;
    ctx.stroke();
  }
}

/* ═══════════════════════════════════════════════════════════════
 * Startup
 * ═══════════════════════════════════════════════════════════════ */

// Глобальный обработчик ошибок — в консоль + на страницу
window.addEventListener('error', (e) => {
  console.error('[AFTOGRAF] Uncaught:', e.error || e.message);
  const statusEl = document.getElementById('load-status');
  if (statusEl) {
    statusEl.textContent = '⛔ JS Error: ' + (e.error?.message || e.message);
    statusEl.style.display = 'block';
    statusEl.className = 'load-status-error';
  }
});

window.addEventListener('unhandledrejection', (e) => {
  console.error('[AFTOGRAF] Unhandled Promise:', e.reason);
});

console.log('[AFTOGRAF] Starting App...');
const app = new App();
console.log('[AFTOGRAF] App initialized');

// Auto-load ROMs from server if served
async function tryAutoLoadROMs() {
  console.log('[AFTOGRAF] Auto-load: trying firmware.bin...');

  // Шаг 1: пробуем единый firmware.bin
  try {
    const resp = await fetch('./firmware.bin?_=' + Date.now());
    console.log('[AFTOGRAF] firmware.bin fetch:', resp.status, resp.statusText);
    if (resp.ok) {
      const buf = await resp.arrayBuffer();
      const data = new Uint8Array(buf);
      console.log('[AFTOGRAF] firmware.bin loaded:', data.length, 'bytes');
      app.mmu = new MMU(app.ppi1, app.ppi2, app.pit, app.uart);
      app.mmu.loadROM(data, 0x0000);
      app.romLoaded = true;
      app.cpu = new CPU8080(
        (addr) => app.mmu.readByte(addr),
        (addr, val) => app.mmu.writeByte(addr, val)
      );
      app.plotter.reset();
      app._resetState();
      app._rebuildDisasm(0);
      app._updateMemoryDump(0x6000);
      app._updateIO();
      app._updatePlotterUI();
      app.els.btnStep.disabled = false;
      app._setLoadStatus('✓ ROM автозагружена (firmware.bin, ' + (data.length/1024).toFixed(0) + 'KB)', 'ok');
      console.log('[AFTOGRAF] Auto-load SUCCESS');
      return;
    } else {
      console.warn('[AFTOGRAF] firmware.bin fetch failed:', resp.status);
    }
  } catch (err) {
    console.error('[AFTOGRAF] firmware.bin error:', err);
  }

  console.log('[AFTOGRAF] Auto-load: trying individual chip files...');
  // Шаг 2: пробуем три отдельных чипа (старый формат)
  const candidates = [
    'Autograf-882-CPU_Board-On_Top-Small-Chip01-FromLeft-D2764A-NearOfHeatsink.bin',
    'Autograf-882-CPU_Board-On_Top-Small-Chip02-FromLeft-D2764A-InMiddle.bin',
    'Autograf-882-CPU_Board-On_Top-Small-Chip03-FromLeft-D2764A-FarOfHeatsink.bin',
  ];
  const encode = (s) => s.replace(/ /g, '%20');

  const buffers = [];
  for (const path of candidates) {
    try {
      const url = encode(path) + '?_=' + Date.now();
      const resp = await fetch(url);
      console.log('[AFTOGRAF] Fetch', path.slice(0, 40) + '...', resp.status);
      if (resp.ok) {
        const buf = await resp.arrayBuffer();
        buffers.push(new Uint8Array(buf));
      }
    } catch (err) {
      console.warn('[AFTOGRAF] Fetch error:', path.slice(0, 40), err.message);
    }
  }

  if (buffers.length > 0) {
    console.log('[AFTOGRAF] Loaded', buffers.length, 'chip(s)');
    app.mmu = new MMU(app.ppi1, app.ppi2, app.pit, app.uart);
    for (let i = 0; i < Math.min(buffers.length, 3); i++) {
      app.mmu.loadROM(buffers[i], i * 0x2000);
    }
    app.romLoaded = true;
    app.cpu = new CPU8080(
      (addr) => app.mmu.readByte(addr),
      (addr, val) => app.mmu.writeByte(addr, val)
    );
    app.plotter.reset();
    app._resetState();
    app._rebuildDisasm(0);
    app._updateMemoryDump(0x6000);
    app._updateIO();
    app._updatePlotterUI();
    app.els.btnStep.disabled = false;
    app._setLoadStatus('✓ ROM автозагружены: ' + buffers.length + ' чипа', 'ok');
  } else {
    console.warn('[AFTOGRAF] Auto-load FAILED: no ROM files found');
    app._setLoadStatus('⚠ ROM не найдены. Нажмите ⚙ Настройки → Загрузить', 'error');
  }
}

tryAutoLoadROMs();
