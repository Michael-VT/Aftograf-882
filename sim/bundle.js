// Autograf-882 bundle

/**
 * Settings Manager — Autograf-882 Debug Simulator
 *
 * Хранит конфигурацию в localStorage, предоставляет панель настроек.
 *
 * Секции:
 *   chips:   адреса загрузки ROM-чипов
 *   vars:    адреса отслеживаемых переменных (X, Y, перо, цвет)
 *   custom:  пользовательские watch-переменные
 */

const STORAGE_KEY = 'aftograf-settings';

const DEFAULTS = {
  chips: [
    { label: 'Chip 1 (D2764A)', offset: 0x0000, size: 0x2000 },
    { label: 'Chip 2 (D2764A)', offset: 0x2000, size: 0x2000 },
    { label: 'Chip 3 (D2764A)', offset: 0x4000, size: 0x2000 },
  ],
  vars: {
    X_POS_LO:   { label: 'X position (LO)',  addr: 0x6180, size: 1 },
    X_POS_HI:   { label: 'X position (HI)',  addr: 0x6181, size: 1 },
    Y_POS_LO:   { label: 'Y position (LO)',  addr: 0x61ca, size: 1 },
    Y_POS_HI:   { label: 'Y position (HI)',  addr: 0x61cb, size: 1 },
    PEN_STATE:  { label: 'Pen state',        addr: 0x63f0, size: 1 },
    PEN_COLOR:  { label: 'Pen color / num',  addr: 0x61e8, size: 1 },
  },
  theme: 'dark',
  dip: [false, false, false, false],
  custom: [],
};

class SettingsManager {
  constructor() {
    this.config = this._load();
  }

  /** Загрузить из localStorage, смержить с дефолтами */
  _load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const saved = JSON.parse(raw);
        return this._merge(saved);
      }
    } catch (_) { /* corrupted — use defaults */ }
    return this._merge({});
  }

  _merge(saved) {
    const cfg = {
      theme: saved.theme === 'light' ? 'light' : 'dark',
      dip: Array.isArray(saved.dip) ? saved.dip.map(Boolean) : [false, false, false, false],
      chips: (saved.chips || []).length === 3
        ? saved.chips.map((c, i) => ({ ...DEFAULTS.chips[i], ...c }))
        : DEFAULTS.chips.map(c => ({ ...c })),
      vars: { ...DEFAULTS.vars },
      custom: Array.isArray(saved.custom) ? saved.custom.map(c => ({ ...c })) : [],
    };
    // Merge vars
    for (const key of Object.keys(DEFAULTS.vars)) {
      if (saved.vars && saved.vars[key]) {
        cfg.vars[key] = { ...DEFAULTS.vars[key], ...saved.vars[key] };
      }
    }
    return cfg;
  }

  /** Сохранить в localStorage */
  save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.config));
    } catch (_) { /* storage full — ignore */ }
  }

  /** Получить адрес переменной по ключу */
  getAddr(key) {
    const v = this.config.vars[key];
    return v ? v.addr : 0;
  }

  /** Обновить адрес переменной */
  setAddr(key, addr) {
    if (this.config.vars[key]) {
      this.config.vars[key].addr = addr;
    }
  }

  /** Обновить offset чипа */
  setChipOffset(idx, offset) {
    if (idx >= 0 && idx < this.config.chips.length) {
      this.config.chips[idx].offset = offset;
    }
  }

  /** Добавить кастомную переменную */
  addCustom(name, addr, size = 1, type = 'uint8') {
    this.config.custom.push({ name, addr, size, type, id: Date.now() });
  }

  /** Удалить кастомную переменную */
  removeCustom(id) {
    this.config.custom = this.config.custom.filter(c => c.id !== id);
  }

  /** Сбросить на дефолты */
  reset() {
    this.config = this._merge({});
    this.save();
  }

  /** Построить HTML панели настроек */
  renderPanel() {
    const cfg = this.config;
    const chipRows = cfg.chips.map((c, i) => `
      <tr>
        <td>${c.label}</td>
        <td><input type="text" class="cfg-chip-offset" data-idx="${i}" value="$${c.offset.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>${'0x' + c.size.toString(16).toUpperCase()} (${c.size})</td>
      </tr>`).join('');

    const varRows = Object.entries(cfg.vars).map(([key, v]) => `
      <tr>
        <td>${v.label}</td>
        <td><code>${key}</code></td>
        <td><input type="text" class="cfg-var-addr" data-key="${key}" value="$${v.addr.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>${v.size}B</td>
      </tr>`).join('');

    const customRows = cfg.custom.length === 0
      ? '<tr><td colspan="4" style="color:#565f89;text-align:center">Нет пользовательских переменных</td></tr>'
      : cfg.custom.map((c, i) => `
      <tr>
        <td><input type="text" class="cfg-custom-name" data-id="${c.id}" value="${c.name}" size="12"></td>
        <td><input type="text" class="cfg-custom-addr" data-id="${c.id}" value="$${c.addr.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>
          <select class="cfg-custom-size" data-id="${c.id}">
            <option value="1" ${c.size===1?'selected':''}>1B</option>
            <option value="2" ${c.size===2?'selected':''}>2B</option>
          </select>
        </td>
        <td><button class="small-btn cfg-custom-remove" data-id="${c.id}">✕</button></td>
      </tr>`).join('');

    return `
    <div id="settings-overlay" class="settings-overlay">
      <div class="settings-panel">
        <div class="settings-header">
          <h2>Настройки симулятора</h2>
          <button id="settings-close" class="ctrl-btn">✕ Закрыть</button>
        </div>

        <div class="settings-body">
          <!-- Загрузка прошивки -->
          <section class="settings-section">
            <h3>Загрузка прошивки</h3>
            <div class="settings-row">
              <button id="settings-load-rom" class="ctrl-btn">📂 Загрузить файл прошивки</button>
              <input type="file" id="settings-rom-input" accept=".bin,.rom" style="display:none">
              <span id="settings-load-status" class="load-status-info" style="display:none">—</span>
            </div>
            <div class="settings-row">
              <label>Адрес загрузки: <input type="text" id="settings-load-addr" value="$0000" size="6"></label>
              <label class="settings-hint">Hex, например $2000 для Chip 2</label>
            </div>
          </section>

          <!-- Карта чипов -->
          <section class="settings-section">
            <h3>Адреса чипов ROM</h3>
            <table class="settings-table">
              <thead><tr><th>Чип</th><th>Смещение</th><th>Размер</th></tr></thead>
              <tbody>${chipRows}</tbody>
            </table>
            <div class="settings-row">
              <label class="settings-hint">Изменения применяются при следующей загрузке ROM</label>
            </div>
          </section>

          <!-- Переменные плоттера -->
          <section class="settings-section">
            <h3>Переменные плоттера (RAM)</h3>
            <table class="settings-table">
              <thead><tr><th>Описание</th><th>Ключ</th><th>Адрес</th><th>Размер</th></tr></thead>
              <tbody>${varRows}</tbody>
            </table>
            <div class="settings-row">
              <label class="settings-hint">Изменения применяются сразу, после закрытия настроек</label>
            </div>
          </section>


          <!-- DIP-переключатели -->
          <section class="settings-section">
            <h3>Конфигурационные переключатели (DIP)</h3>
            <div class="settings-row">
              ${cfg.dip.map((v,i) => `
                <label style="display:flex;align-items:center;gap:4px;font-size:12px;font-family:var(--font-mono)">
                  <input type="checkbox" class="cfg-dip" data-idx="${i}" ${v?'checked':''}>
                  ComCfg${i+1}
                </label>
              `).join('')}
              <label class="settings-hint">Соответствуют PB4-PB7 на PIO1. Применяются сразу.</label>
            </div>
          </section>
          <!-- Тема оформления -->
          <section class="settings-section">
            <h3>Тема оформления</h3>
            <div class="settings-row">
              <label for="settings-theme">Режим:</label>
              <select id="settings-theme" class="cfg-theme-select" style="background:var(--bg-input);color:var(--text);border:1px solid var(--border);border-radius:3px;padding:2px 4px;font-family:var(--font-mono);font-size:12px">
                <option value="dark" ${cfg.theme==='dark'?'selected':''}>Тёмная (ночная)</option>
                <option value="light" ${cfg.theme==='light'?'selected':''}>Светлая (дневная)</option>
              </select>
              <label class="settings-hint">Применяется сразу после закрытия настроек</label>
            </div>
          </section>

          <!-- Пользовательские watcher'ы -->
          <section class="settings-section">
            <h3>Пользовательские переменные</h3>
            <table class="settings-table" id="custom-vars-table">
              <thead><tr><th>Имя</th><th>Адрес</th><th>Размер</th><th></th></tr></thead>
              <tbody>${customRows}</tbody>
            </table>
            <div class="settings-row">
              <button id="settings-custom-add" class="small-btn">+ Добавить</button>
              <button id="settings-custom-read" class="small-btn">⟳ Прочитать</button>
            </div>
            <div id="custom-readout" class="custom-readout"></div>
          </section>

          <!-- Управление -->
          <section class="settings-section">
            <h3>Управление настройками</h3>
            <div class="settings-row">
              <button id="settings-save" class="ctrl-btn">💾 Сохранить</button>
              <button id="settings-reset" class="ctrl-btn">↺ Сбросить</button>
              <span id="settings-save-status" style="display:none;color:var(--green)">✓ Сохранено</span>
            </div>
          </section>
        </div>
      </div>
    </div>`;
  }
}



/**
 * System Memory — Autograf-882 memory map
 *
 * $0000-$1FFF  ROM1 (D2764A)
 * $2000-$3FFF  ROM2 (D2764A)
 * $4000-$5FFF  ROM3 (D2764A)
 * $6000-$63FF  RAM (КР537РУ10, 1024 bytes)
 * $E000-$E3FF  PPI1 (КР580ВВ55А #1)
 * $E400-$E7FF  PPI2 (КР580ВВ55А #2)
 * $E800-$EBFF  PIT  (КР580ВИ53)
 * $EC00-$EFFF  USART (КР580ВВ51А)
 *
 * Memory-mapped I/O: STA/LDA to $E000+ ports.
 * OUT/IN instructions also map to $E000-FF.
 */

class MMU {
  constructor(ppi1, ppi2, pit, uart) {
    this.rom = new Uint8Array(0x6000);
    this.ram = new Uint8Array(0x0400); // 1KB КР537РУ10

    // Device references
    this.ppi1 = ppi1;
    this.ppi2 = ppi2;
    this.pit = pit;
    this.uart = uart;
    this.lastWriteAddr = -1; // address of last write (for debugger)
    this.onInvalidWrite = null; // callback(addr, val) for writes outside RAM
  }

  /** Load a firmware image (byte array) at the given offset */
  loadROM(data, offset) {
    this.rom.set(data, offset);
  }

  /** Load all three EPROMs */
  loadFirmware(rom1, rom2, rom3) {
    this.loadROM(rom1, 0x0000);
    this.loadROM(rom2, 0x2000);
    this.loadROM(rom3, 0x4000);
  }

  /* ─── Byte read ─── */
  readByte(addr) {
    addr &= 0xffff;

    if (addr < 0x6000) {
      return this.rom[addr];
    }
    if (addr < 0x6400) {
      return this.ram[addr & 0x3ff];
    }
    if (addr >= 0xe000 && addr < 0xe400) {
      // PPI1
      return this.ppi1.read(addr & 0x03);
    }
    if (addr >= 0xe400 && addr < 0xe800) {
      // PPI2
      return this.ppi2.read(addr & 0x03);
    }
    if (addr >= 0xe800 && addr < 0xec00) {
      // PIT
      return this.pit.read(addr & 0x03);
    }
    if (addr >= 0xec00 && addr < 0xf000) {
      // USART
      return this.uart.read(addr & 0x01);
    }
    return 0xff;
  }

  /* ─── Byte write ─── */
  writeByte(addr, val) {
    addr &= 0xffff;
    val &= 0xff;
    this.lastWriteAddr = addr;
    if (addr >= 0x6000 && addr < 0x6400) {
      this.ram[addr & 0x3ff] = val;
      return;
    }
    if (addr >= 0xe000 && addr < 0xe400) {
      this.ppi1.write(addr & 0x03, val);
      return;
    }
    if (addr >= 0xe400 && addr < 0xe800) {
      this.ppi2.write(addr & 0x03, val);
      return;
    }
    if (addr >= 0xe800 && addr < 0xec00) {
      this.pit.write(addr & 0x03, val);
      return;
    }
    if (addr >= 0xec00 && addr < 0xf000) {
      this.uart.write(addr & 0x01, val);
      return;
    }
    // Write to ROM or unmapped area — log error but continue
    const region = addr < 0x6000 ? `ROM ($${addr.toString(16).padStart(4,'0').toUpperCase()})`
      : addr < 0xe000 ? `свободная ($${addr.toString(16).padStart(4,'0').toUpperCase()})`
      : `зарезервированная ($${addr.toString(16).padStart(4,'0').toUpperCase()})`;
    console.warn(`[MMU] Запись $${val.toString(16).padStart(2,'0').toUpperCase()} в ${region} — игнорировано`);
    if (this.onInvalidWrite) this.onInvalidWrite(addr, val);
  }

  /** Get a contiguous block for disassembler or memory dump */
  readBlock(addr, len) {
    const buf = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      buf[i] = this.readByte(addr + i);
    }
    return buf;
  }

  /** Get byte at an address — for external tools */
  peek(addr) {
    return this.readByte(addr);
  }

  /** Set byte at an address — for debugging */
  poke(addr, val) {
    this.writeByte(addr, val);
  }
}



/**
 * i8080 / К580ИК80 CPU Emulator
 * Complete 256-opcode table-driven implementation.
 *
 * Flags: S(7) Z(6) AC(4) P(2) CY(0) — same bit positions as real 8080.
 * CY bit: bit 0; AC bit: bit 4.
 */

const FLAG_CY  = 0x01;
const FLAG_P   = 0x04;
const FLAG_AC  = 0x10;
const FLAG_Z   = 0x40;
const FLAG_S   = 0x80;

class CPU8080 {
  constructor(readByte, writeByte) {
    // Register file
    this.a = 0; this.b = 0; this.c = 0;
    this.d = 0; this.e = 0; this.h = 0; this.l = 0;
    this.flags = 0x02; // bit 1 always set
    this.sp = 0;
    this.pc = 0;
    this.ie = false;    // interrupt-enable flip-flop
    this.halt = false;
    this.cycles = 0;
    this.intr = false;   // interrupt pending (set by USART etc)
    this.intrVector = 7; // RST vector for INTR (0-7)

    // Memory callbacks (injected by MMU)
    this.readByte = readByte;
    this.writeByte = writeByte;

    // Build opcode table once
    this.optable = buildOpcodeTable(this);
  }

  /* ─── Register pair accessors ─── */
  getBC() { return (this.b << 8) | this.c; }
  setBC(v) { this.b = (v >> 8) & 0xff; this.c = v & 0xff; }
  getDE() { return (this.d << 8) | this.e; }
  setDE(v) { this.d = (v >> 8) & 0xff; this.e = v & 0xff; }
  getHL() { return (this.h << 8) | this.l; }
  setHL(v) { this.h = (v >> 8) & 0xff; this.l = v & 0xff; }

  getPSW() { return (this.a << 8) | (this.flags & 0xff); }
  setPSW(v) { this.a = (v >> 8) & 0xff; this.flags = (v & 0xff) | 0x02; }

  /* ─── Flag helpers ─── */
  setFlags(result, wordSize) {
    const mask = wordSize ? 0xffff : 0xff;
    result &= mask;
    this.flags = (this.flags & ~(FLAG_S|FLAG_Z|FLAG_P)) | 0x02;
    if (result & (wordSize ? 0x8000 : 0x80)) this.flags |= FLAG_S;
    if (result === 0) this.flags |= FLAG_Z;
    if (this.parity(result & 0xff)) this.flags |= FLAG_P;
    return result;
  }

  parity(x) {
    x ^= x >> 4; x ^= x >> 2; x ^= x >> 1;
    return (x & 1) ? 0 : 1;
  }

  /* ─── Fetch & Step ─── */
  fetchByte() {
    const b = this.readByte(this.pc);
    this.pc = (this.pc + 1) & 0xffff;
    this.cycles += 3; // one M-cycle
    return b;
  }

  fetchWord() {
    const lo = this.fetchByte();
    const hi = this.fetchByte();
    return (hi << 8) | lo;
  }

  pushStack(hi, lo) {
    this.sp = (this.sp - 1) & 0xffff;
    this.writeByte(this.sp, hi);
    this.cycles += 3;
    this.sp = (this.sp - 1) & 0xffff;
    this.writeByte(this.sp, lo);
    this.cycles += 3;
  }

  pushWord(v) {
    this.pushStack((v >> 8) & 0xff, v & 0xff);
  }

  popStack() {
    const lo = this.readByte(this.sp);
    this.sp = (this.sp + 1) & 0xffff;
    this.cycles += 3;
    const hi = this.readByte(this.sp);
    this.sp = (this.sp + 1) & 0xffff;
    this.cycles += 3;
    return (hi << 8) | lo;
  }

  /* ─── Execute one instruction. Returns true if halted ─── */
  step() {
    if (this.halt) return true;
    // Check interrupt
    if (this.ie && this.intr) {
      this.ie = false;
      this.intr = false;
      // RST 7 (vector $0038) — standard for USART
      const vector = this.intrVector !== undefined ? this.intrVector : 7;
      const addr = vector * 8;
      this.pushWord(this.pc);
      this.pc = addr;
      this.cycles += 11;
      return this.halt;
    }
    // Fetch and execute
    const opcode = this.fetchByte();
    const op = this.optable[opcode];
    if (!op) return false;
    this.lastPC = this.pc - 1;
    op.exec();
    return this.halt;
  }

  /** Run N instructions or until paused externally. */
  run(maxInsns = 1000000, checkPause = null) {
    let count = 0;
    while (!this.halt && count < maxInsns) {
      this.step();
      count++;
      if (checkPause && checkPause()) break;
    }
    return count;
  }

  reset() {
    this.a = 0; this.b = 0; this.c = 0;
    this.d = 0; this.e = 0; this.h = 0; this.l = 0;
    this.flags = 0x02;
    this.sp = 0;
    this.pc = 0;
    this.ie = false;
    this.halt = false;
    this.intr = false;
    this.cycles = 0;
  }

  /** Get register snapshot for UI */
  getState() {
    return {
      a: this.a, b: this.b, c: this.c,
      d: this.d, e: this.e, h: this.h, l: this.l,
      flags: this.flags,
      sp: this.sp, pc: this.pc,
      ie: this.ie, halt: this.halt,
      cycles: this.cycles,
      lastPC: this.lastPC ?? 0,
    };
  }
}

/* ═══════════════════════════════════
 * Opcode Table Builder
 * ═══════════════════════════════════ */

function buildOpcodeTable(cpu) {
  const O = new Array(256);

  function def(code, mnem, cycles, len, exec) {
    O[code] = { mnem, cycles, len, exec };
  }

  /* ─── MOV r1,r2 (0x40-0x7F) ─── */
  const REG = ['b','c','d','e','h','l','m','a'];
  for (let dst = 0; dst < 8; dst++) {
    for (let src = 0; src < 8; src++) {
      const code = (dst << 3) | src | 0x40;
      if (code === 0x76) continue; // HLT
      const mnem = `MOV ${REG[dst].toUpperCase()},${REG[src].toUpperCase()}`;
      const cycleCount = (dst === 6 || src === 6) ? 7 : 5;
      def(code, mnem, cycleCount, 1, () => {
        let val;
        if (src === 6) {
          val = cpu.readByte(cpu.getHL());
          cpu.cycles += 3;
        } else {
          val = cpu[cpu_reg_idx(src)];
        }
        if (dst === 6) {
          cpu.writeByte(cpu.getHL(), val);
          cpu.cycles += 3;
        } else {
          cpu[cpu_reg_idx(dst)] = val;
        }
        cpu.cycles += (cycleCount - (cycleCount === 5 ? 0 : 0));
      });
    }
  }

  /* ─── HLT 0x76 ─── */
  def(0x76, 'HLT', 7, 1, () => { cpu.halt = true; });

  /* ─── MVI r,byte ─── */
  const MVI_CODES = [0x06,0x0e,0x16,0x1e,0x26,0x2e,0x36,0x3e];
  for (let i = 0; i < 8; i++) {
    const code = MVI_CODES[i];
    const r = REG[i].toUpperCase();
    def(code, `MVI ${r},$02`, 7, 2, () => {
      const val = cpu.fetchByte();
      if (i === 6) { // M
        cpu.writeByte(cpu.getHL(), val);
        cpu.cycles += 3;
      } else {
        cpu[cpu_reg_idx(i)] = val;
      }
    });
  }

  /* ─── LXI rp,word ─── */
  const LXI_CODES = [0x01,0x11,0x21,0x31];
  const RP = [['b','c'],['d','e'],['h','l'],['sp','sp']];
  for (let i = 0; i < 4; i++) {
    def(LXI_CODES[i], `LXI ${RP[i][0] === 'sp' ? 'SP' : RP[i][0].toUpperCase()+RP[i][1].toUpperCase()},$04$02`, 10, 3, () => {
      const val = cpu.fetchWord();
      if (i === 3) {
        cpu.sp = val;
      } else {
        cpu[cpu_reg_idx2(RP[i][0])] = (val >> 8) & 0xff;
        cpu[cpu_reg_idx2(RP[i][1])] = val & 0xff;
      }
    });
  }

  /* ─── Arithmetic: ADD/ADC/SUB/SBB/ANA/XRA/ORA/CMP ─── */
  const ARITH_CODES = [0x80,0x88,0x90,0x98,0xa0,0xa8,0xb0,0xb8];
  const ARITH_NAMES = ['ADD','ADC','SUB','SBB','ANA','XRA','ORA','CMP'];
  for (let i = 0; i < 8; i++) {
    for (let src = 0; src < 8; src++) {
      const code = ARITH_CODES[i] | src;
      const r = REG[src].toUpperCase();
      const mnem = `${ARITH_NAMES[i]} ${r}`;
      const isMem = (src === 6);
      const cycles = isMem ? 7 : 4;
      def(code, mnem, cycles, 1, () => {
        let val;
        if (isMem) {
          val = cpu.readByte(cpu.getHL());
          cpu.cycles += 3;
        } else {
          val = cpu[cpu_reg_idx(src)];
        }
        cpu_arith(cpu, i, val);
      });
    }
  }

  /* ─── Immediate arithmetic ADI/ACI/SUI/SBI/ANI/XRI/ORI/CPI ─── */
  const IMM_CODES = [0xc6,0xce,0xd6,0xde,0xe6,0xee,0xf6,0xfe];
  for (let i = 0; i < 8; i++) {
    def(IMM_CODES[i], `${ARITH_NAMES[i]} $02`, 7, 2, () => {
      const val = cpu.fetchByte();
      cpu_arith(cpu, i, val);
    });
  }

  function cpu_arith(cpu, op, val) {
    switch (op) {
      case 0: { // ADD
        const r = cpu.a + val;
        const carry = r > 0xff;
        cpu.setFlags(r, 0);
        if (carry) cpu.flags |= FLAG_CY;
        if (((cpu.a & 0x0f) + (val & 0x0f)) > 0x0f) cpu.flags |= FLAG_AC;
        cpu.a = r & 0xff;
        break;
      }
      case 1: { // ADC
        const cy = cpu.flags & FLAG_CY;
        const r = cpu.a + val + cy;
        const carry = r > 0xff;
        cpu.setFlags(r, 0);
        if (carry) cpu.flags |= FLAG_CY;
        if (((cpu.a & 0x0f) + (val & 0x0f) + cy) > 0x0f) cpu.flags |= FLAG_AC;
        cpu.a = r & 0xff;
        break;
      }
      case 2: { // SUB
        const r = cpu.a - val;
        const borrow = r < 0;
        cpu.setFlags(r, 0);
        if (borrow) cpu.flags |= FLAG_CY;
        if (((cpu.a & 0x0f) - (val & 0x0f)) < 0) cpu.flags |= FLAG_AC;
        // SUB sets CY on borrow — 8080 sets CY=1 when borrow
        cpu.a = r & 0xff;
        break;
      }
      case 3: { // SBB
        const cy = cpu.flags & FLAG_CY;
        const r = cpu.a - val - cy;
        const borrow = r < 0;
        cpu.setFlags(r, 0);
        if (borrow) cpu.flags |= FLAG_CY;
        if (((cpu.a & 0x0f) - (val & 0x0f) - cy) < 0) cpu.flags |= FLAG_AC;
        cpu.a = r & 0xff;
        break;
      }
      case 4: { // ANA
        const r = cpu.a & val;
        cpu.setFlags(r, 0);
        cpu.flags &= ~FLAG_CY; // ANA clears CY, sets AC
        if (((cpu.a | val) & 0x08)) cpu.flags |= FLAG_AC; // AC = (A|operand) bit 3
        cpu.a = r;
        break;
      }
      case 5: { // XRA
        cpu.a ^= val;
        cpu.setFlags(cpu.a, 0);
        cpu.flags &= ~FLAG_CY; // XRA clears CY, clears AC
        cpu.flags &= ~FLAG_AC;
        break;
      }
      case 6: { // ORA
        cpu.a |= val;
        cpu.setFlags(cpu.a, 0);
        cpu.flags &= ~FLAG_CY; // ORA clears CY, clears AC
        cpu.flags &= ~FLAG_AC;
        break;
      }
      case 7: { // CMP
        const r = cpu.a - val;
        const borrow = r < 0;
        cpu.setFlags(r, 0);
        if (borrow) cpu.flags |= FLAG_CY;
        if (((cpu.a & 0x0f) - (val & 0x0f)) < 0) cpu.flags |= FLAG_AC;
        // Result not stored — only flags
        break;
      }
    }
  }

  /* ─── INR/DCR ─── */
  const INR_CODES = [0x3c,0x04,0x0c,0x14,0x1c,0x24,0x2c,0x34];
  const DCR_CODES = [0x3d,0x05,0x0d,0x15,0x1d,0x25,0x2d,0x35];
  for (let i = 0; i < 8; i++) {
    def(INR_CODES[i], `INR ${REG[i].toUpperCase()}`, i===6?10:5, 1, () => {
      let val;
      if (i === 6) {
        val = cpu.readByte(cpu.getHL());
        cpu.cycles += 3;
      } else {
        val = cpu[cpu_reg_idx(i)];
      }
      const r = (val + 1) & 0xff;
      cpu.flags = (cpu.flags & ~(FLAG_S|FLAG_Z|FLAG_AC|FLAG_P)) | 0x02;
      if (r & 0x80) cpu.flags |= FLAG_S;
      if (r === 0) cpu.flags |= FLAG_Z;
      if (cpu.parity(r)) cpu.flags |= FLAG_P;
      if ((val & 0x0f) === 0x0f) cpu.flags |= FLAG_AC; // carry from low nibble
      if (i === 6) {
        cpu.writeByte(cpu.getHL(), r);
        cpu.cycles += 3;
      } else {
        cpu[cpu_reg_idx(i)] = r;
      }
    });

    def(DCR_CODES[i], `DCR ${REG[i].toUpperCase()}`, i===6?10:5, 1, () => {
      let val;
      if (i === 6) {
        val = cpu.readByte(cpu.getHL());
        cpu.cycles += 3;
      } else {
        val = cpu[cpu_reg_idx(i)];
      }
      const r = (val - 1) & 0xff;
      cpu.flags = (cpu.flags & ~(FLAG_S|FLAG_Z|FLAG_AC|FLAG_P)) | 0x02;
      if (r & 0x80) cpu.flags |= FLAG_S;
      if (r === 0) cpu.flags |= FLAG_Z;
      if (cpu.parity(r)) cpu.flags |= FLAG_P;
      if ((val & 0x0f) === 0x00) cpu.flags |= FLAG_AC; // borrow from low nibble
      if (i === 6) {
        cpu.writeByte(cpu.getHL(), r);
        cpu.cycles += 3;
      } else {
        cpu[cpu_reg_idx(i)] = r;
      }
    });
  }

  /* ─── INX/DCX ─── */
  const INX_CODES = [0x03,0x13,0x23,0x33];
  const DCX_CODES = [0x0b,0x1b,0x2b,0x3b];
  const RP_PAIRS = [['b','c'],['d','e'],['h','l'],['sp','sp']];
  for (let i = 0; i < 4; i++) {
    def(INX_CODES[i], `INX ${RP_PAIRS[i][0]==='sp'?'SP':RP_PAIRS[i][0].toUpperCase()+RP_PAIRS[i][1].toUpperCase()}`, 5, 1, () => {
      if (i === 3) { cpu.sp = (cpu.sp + 1) & 0xffff; }
      else {
        const v = (cpu[cpu_reg_idx2(RP_PAIRS[i][0])] << 8) | cpu[cpu_reg_idx2(RP_PAIRS[i][1])];
        const r = (v + 1) & 0xffff;
        cpu[cpu_reg_idx2(RP_PAIRS[i][0])] = (r >> 8) & 0xff;
        cpu[cpu_reg_idx2(RP_PAIRS[i][1])] = r & 0xff;
      }
    });
    def(DCX_CODES[i], `DCX ${RP_PAIRS[i][0]==='sp'?'SP':RP_PAIRS[i][0].toUpperCase()+RP_PAIRS[i][1].toUpperCase()}`, 5, 1, () => {
      if (i === 3) { cpu.sp = (cpu.sp - 1) & 0xffff; }
      else {
        const v = (cpu[cpu_reg_idx2(RP_PAIRS[i][0])] << 8) | cpu[cpu_reg_idx2(RP_PAIRS[i][1])];
        const r = (v - 1) & 0xffff;
        cpu[cpu_reg_idx2(RP_PAIRS[i][0])] = (r >> 8) & 0xff;
        cpu[cpu_reg_idx2(RP_PAIRS[i][1])] = r & 0xff;
      }
    });
  }

  /* ─── DAD ─── */
  const DAD_CODES = [0x09,0x19,0x29,0x39];
  for (let i = 0; i < 4; i++) {
    def(DAD_CODES[i], `DAD ${RP_PAIRS[i][0]==='sp'?'SP':RP_PAIRS[i][0].toUpperCase()+RP_PAIRS[i][1].toUpperCase()}`, 10, 1, () => {
      let rpVal;
      if (i === 3) rpVal = cpu.sp;
      else rpVal = (cpu[cpu_reg_idx2(RP_PAIRS[i][0])] << 8) | cpu[cpu_reg_idx2(RP_PAIRS[i][1])];
      const hl = cpu.getHL();
      const r = hl + rpVal;
      cpu.setHL(r & 0xffff);
      cpu.flags = (cpu.flags & ~FLAG_CY) | 0x02;
      if (r > 0xffff) cpu.flags |= FLAG_CY;
    });
  }

  /* ─── JMP / Jcc ─── */
  const JMP_OPCODES = [
    [0xc2,'JNZ'],[0xca,'JZ'],[0xd2,'JNC'],[0xda,'JC'],
    [0xe2,'JPO'],[0xea,'JPE'],[0xf2,'JP'],[0xfa,'JM'],
    [0xc3,'JMP'],[0xe9,'PCHL']
  ];
  const JMP_COND = [
    (f) => !(f & FLAG_Z),       // JNZ
    (f) => !!(f & FLAG_Z),      // JZ
    (f) => !(f & FLAG_CY),      // JNC
    (f) => !!(f & FLAG_CY),     // JC
    (f) => !(f & FLAG_P),       // JPO
    (f) => !!(f & FLAG_P),      // JPE
    (f) => !(f & FLAG_S),       // JP
    (f) => !!(f & FLAG_S),      // JM
    null,                       // JMP (unconditional)
  ];

  for (let i = 0; i < 8; i++) {
    const [code, name] = JMP_OPCODES[i];
    def(code, `${name} $04$02`, 10, 3, () => {
      const addr = cpu.fetchWord();
      if (JMP_COND[i](cpu.flags)) {
        cpu.pc = addr;
        cpu.cycles += 5; // taken branch penalty
      }
    });
  }
  // JMP unconditional
  def(0xc3, 'JMP $04$02', 10, 3, () => {
    cpu.pc = cpu.fetchWord();
  });
  // PCHL
  def(0xe9, 'PCHL', 5, 1, () => {
    cpu.pc = cpu.getHL();
  });

  /* ─── CALL / Ccc ─── */
  const CALL_OPCODES = [
    [0xc4,'CNZ'],[0xcc,'CZ'],[0xd4,'CNC'],[0xdc,'CC'],
    [0xe4,'CPO'],[0xec,'CPE'],[0xf4,'CP'],[0xfc,'CM'],
    [0xcd,'CALL'],
  ];
  for (let i = 0; i < 8; i++) {
    const [code, name] = CALL_OPCODES[i];
    def(code, `${name} $04$02`, 11, 3, () => {
      const addr = cpu.fetchWord();
      if (JMP_COND[i](cpu.flags)) {
        const retPC = cpu.pc; // pc already advanced by 2 bytes from fetchWord
        cpu.pushWord(retPC);
        cpu.pc = addr;
        cpu.cycles += 6; // call penalty
      }
    });
  }

  // CALL unconditional
  O[0xcd] = { mnem: 'CALL $04$02', cycles: 17, len: 3, exec: () => {
    const addr = cpu.fetchWord();
    cpu.pushWord(cpu.pc);
    cpu.pc = addr;
  }};

  /* ─── RET / Rcc ─── */
  const RET_OPCODES = [
    [0xc0,'RNZ'],[0xc8,'RZ'],[0xd0,'RNC'],[0xd8,'RC'],
    [0xe0,'RPO'],[0xe8,'RPE'],[0xf0,'RP'],[0xf8,'RM'],
    [0xc9,'RET'],
  ];
  for (let i = 0; i < 8; i++) {
    const [code, name] = RET_OPCODES[i];
    def(code, name, 5, 1, () => {
      if (i < 8 && JMP_COND[i](cpu.flags)) {
        cpu.pc = cpu.popStack();
        cpu.cycles += 6;
      } else if (i === 8) {
        cpu.pc = cpu.popStack();
        cpu.cycles += 5;
      }
    });
  }

  /* ─── PUSH/POP ─── */
  const PUSH_CODES = [0xc5,0xd5,0xe5,0xf5];
  const POP_CODES  = [0xc1,0xd1,0xe1,0xf1];
  const PUSH_REGS = [['b','c'],['d','e'],['h','l'],['a','f']];
  for (let i = 0; i < 4; i++) {
    def(PUSH_CODES[i], `PUSH ${i===3?'PSW':(PUSH_REGS[i][0].toUpperCase()+PUSH_REGS[i][1].toUpperCase())}`, 11, 1, () => {
      if (i === 3) {
        // PUSH PSW
        const psw = ((cpu.a << 8) | (cpu.flags & 0xff)) & 0xffff;
        cpu.pushWord(psw);
      } else {
        const val = ((cpu[cpu_reg_idx2(PUSH_REGS[i][0])] << 8) | cpu[cpu_reg_idx2(PUSH_REGS[i][1])]) & 0xffff;
        cpu.pushWord(val);
      }
    });
    def(POP_CODES[i], `POP ${i===3?'PSW':(PUSH_REGS[i][0].toUpperCase()+PUSH_REGS[i][1].toUpperCase())}`, 10, 1, () => {
      const val = cpu.popStack();
      if (i === 3) {
        cpu.a = (val >> 8) & 0xff;
        cpu.flags = (val & 0xff) | 0x02;
      } else {
        cpu[cpu_reg_idx2(PUSH_REGS[i][0])] = (val >> 8) & 0xff;
        cpu[cpu_reg_idx2(PUSH_REGS[i][1])] = val & 0xff;
      }
    });
  }

  /* ─── RST ─── */
  for (let i = 0; i < 8; i++) {
    const code = 0xc7 | (i << 3);
    def(code, `RST ${i*8}`, 11, 1, () => {
      cpu.pushWord(cpu.pc);
      cpu.pc = i * 8;
    });
  }

  /* ─── LDA/STA ─── */
  def(0x3a, 'LDA $04$02', 13, 3, () => { cpu.a = cpu.readByte(cpu.fetchWord()); cpu.cycles += 3; });
  def(0x32, 'STA $04$02', 13, 3, () => { const addr = cpu.fetchWord(); cpu.writeByte(addr, cpu.a); cpu.cycles += 3; });

  /* ─── LHLD/SHLD ─── */
  def(0x2a, 'LHLD $04$02', 16, 3, () => {
    const addr = cpu.fetchWord();
    cpu.l = cpu.readByte(addr);
    cpu.cycles += 3;
    cpu.h = cpu.readByte(addr + 1);
    cpu.cycles += 3;
  });
  def(0x22, 'SHLD $04$02', 16, 3, () => {
    const addr = cpu.fetchWord();
    cpu.writeByte(addr, cpu.l);
    cpu.cycles += 3;
    cpu.writeByte(addr + 1, cpu.h);
    cpu.cycles += 3;
  });

  /* ─── LDAX/STAX ─── */
  def(0x0a, 'LDAX B', 7, 1, () => { cpu.a = cpu.readByte(cpu.getBC()); cpu.cycles += 3; });
  def(0x1a, 'LDAX D', 7, 1, () => { cpu.a = cpu.readByte(cpu.getDE()); cpu.cycles += 3; });
  def(0x02, 'STAX B', 7, 1, () => { cpu.writeByte(cpu.getBC(), cpu.a); cpu.cycles += 3; });
  def(0x12, 'STAX D', 7, 1, () => { cpu.writeByte(cpu.getDE(), cpu.a); cpu.cycles += 3; });

  /* ─── XCHG ─── */
  def(0xeb, 'XCHG', 5, 1, () => {
    const hl = cpu.getHL();
    const de = cpu.getDE();
    cpu.setHL(de);
    cpu.setDE(hl);
  });

  /* ─── XTHL ─── */
  def(0xe3, 'XTHL', 18, 1, () => {
    const h = cpu.h, l = cpu.l;
    cpu.l = cpu.readByte(cpu.sp);
    cpu.cycles += 3;
    cpu.h = cpu.readByte(cpu.sp + 1);
    cpu.cycles += 3;
    cpu.writeByte(cpu.sp, l);
    cpu.cycles += 3;
    cpu.writeByte(cpu.sp + 1, h);
    cpu.cycles += 3;
  });

  /* ─── SPHL ─── */
  def(0xf9, 'SPHL', 5, 1, () => { cpu.sp = cpu.getHL(); });

  /* ─── IN/OUT ─── */
  def(0xdb, 'IN $02', 10, 2, () => {
    const port = cpu.fetchByte();
    cpu.a = cpu.readByte(0xe000 | port); // memory-mapped I/O via $E000-$E0FF
    cpu.cycles += 3;
  });
  def(0xd3, 'OUT $02', 10, 2, () => {
    const port = cpu.fetchByte();
    cpu.writeByte(0xe000 | port, cpu.a);
    cpu.cycles += 3;
  });

  /* ─── EI/DI ─── */
  def(0xfb, 'EI', 4, 1, () => { cpu.ie = true; });
  def(0xf3, 'DI', 4, 1, () => { cpu.ie = false; });

  /* ─── Rotates: RLC/RRC/RAL/RAR ─── */
  def(0x07, 'RLC', 4, 1, () => {
    const cy = (cpu.a & 0x80) ? 1 : 0;
    cpu.a = ((cpu.a << 1) | cy) & 0xff;
    cpu.flags = (cpu.flags & ~FLAG_CY) | 0x02;
    if (cy) cpu.flags |= FLAG_CY;
  });
  def(0x0f, 'RRC', 4, 1, () => {
    const cy = cpu.a & 1;
    cpu.a = (cpu.a >> 1) | (cy << 7);
    cpu.flags = (cpu.flags & ~FLAG_CY) | 0x02;
    if (cy) cpu.flags |= FLAG_CY;
  });
  def(0x17, 'RAL', 4, 1, () => {
    const oldCY = cpu.flags & FLAG_CY;
    const newCY = (cpu.a & 0x80) ? 1 : 0;
    cpu.a = ((cpu.a << 1) | (oldCY ? 1 : 0)) & 0xff;
    cpu.flags = (cpu.flags & ~FLAG_CY) | 0x02;
    if (newCY) cpu.flags |= FLAG_CY;
  });
  def(0x1f, 'RAR', 4, 1, () => {
    const oldCY = cpu.flags & FLAG_CY;
    const newCY = cpu.a & 1;
    cpu.a = (cpu.a >> 1) | (oldCY ? 0x80 : 0);
    cpu.flags = (cpu.flags & ~FLAG_CY) | 0x02;
    if (newCY) cpu.flags |= FLAG_CY;
  });

  /* ─── CMA/STC/CMC ─── */
  def(0x2f, 'CMA', 4, 1, () => { cpu.a ^= 0xff; });
  def(0x37, 'STC', 4, 1, () => { cpu.flags |= FLAG_CY; });
  def(0x3f, 'CMC', 4, 1, () => { cpu.flags ^= FLAG_CY; });

  /* ─── DAA ─── */
  def(0x27, 'DAA', 4, 1, () => {
    let correction = 0;
    if (((cpu.a & 0x0f) > 9) || (cpu.flags & FLAG_AC)) correction = 0x06;
    if (((cpu.a >> 4) > 9) || (cpu.flags & FLAG_CY)) { correction |= 0x60; cpu.flags |= FLAG_CY; }
    else { cpu.flags &= ~FLAG_CY; }
    const r = (cpu.a + correction) & 0xff;
    cpu.setFlags(r, 0);
    cpu.a = r;
  });

  /* ─── NOP ─── */
  const NOP_CODES = [0x00,0x08,0x10,0x18,0x20,0x28,0x30,0x38,0xcb,0xd9,0xdd,0xed,0xfd];
  for (const c of NOP_CODES) def(c, 'NOP', 4, 1, () => {});

  return O;
}

function cpu_reg_idx(i) {
  // 0=b,1=c,2=d,3=e,4=h,5=l,6=m(not used here),7=a
  return ['b','c','d','e','h','l','x','a'][i];
}

function cpu_reg_idx2(r) {
  return {b:'b',c:'c',d:'d',e:'e',h:'h',l:'l'}[r];
}



/**
 * Autograf-882 Debug Simulator — Main Controller
 *
 * Wires CPU8080, MMU, I/O device stubs, disassembler, and debugger UI.
 * Features: editable registers, scrollable+editable memory, USART terminal,
 *           stack (50 words), A4 plotter, keyboard shortcuts.
 */
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
      case 0: return this.onReadPortA ? this.onReadPortA() : this.portA;
      case 1: return this.onReadPortB ? this.onReadPortB() : this.portB;
      case 2: return this.portC;
      case 3: return this.ctrl;
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
          this.modeSet = true;
          this.mode = (val >> 5) & 0x03;
        }
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
    this.counters = [
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
      { mode: 3, val: 0xffff, initial: 0xffff, latch: null, latched: false, bcd: false },
    ];
    this.accessMode = [2, 2, 2];
    this.writeToggle = [false, false, false];
    this.readToggle = [false, false, false];
  }
  read(reg) {
    if (reg >= 0 && reg <= 2) {
      const ctr = this.counters[reg];
      if (ctr.latched) {
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
      const val = ctr.val;
      if (this.accessMode[reg] === 0) {
        return val & 0xff;
      } else if (this.accessMode[reg] === 1) {
        return (val >> 8) & 0xff;
      } else {
        if (!this.readToggle[reg]) {
          this.readToggle[reg] = true;
          return val & 0xff;
        } else {
          this.readToggle[reg] = false;
          return (val >> 8) & 0xff;
        }
      }
    }
    return 0xff;
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
        return;
      }
      if (val & 0x80) {
        const ctr = this.counters[sel];
        ctr.mode = (val >> 1) & 0x07;
        if (ctr.mode > 5) ctr.mode = 5;
        ctr.bcd = !!(val & 1);
        const rl = (val >> 4) & 0x03;
        this.accessMode[sel] = rl;
        this.writeToggle[sel] = false;
        this.readToggle[sel] = false;
      } else {
        const ctr = this.counters[val >> 6];
        if (!ctr.latched) {
          ctr.latch = ctr.val;
          ctr.latched = true;
          this.readToggle[val >> 6] = false;
        }
      }
    }
  }
  tick() {
    for (let i = 0; i < 3; i++) {
      const ctr = this.counters[i];
      ctr.val = (ctr.val - 1) & 0xffff;
      if (ctr.val === 0) {
        ctr.val = ctr.initial;
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
 * КР580ВВ51А (i8251) — USART with terminal I/O and XOn-XOff.
 *
 * Хранит буфер принятых данных (RX) для чтения CPU.
 * Буфер передачи (TX) отправляется в терминал.
 * XOn/XOff: при заполнении RX буфера > 200 байт шлём XOff (0x13),
 * при освобождении < 50 байт — XOn (0x11).
 */
class USART8251 {
  constructor() {
    this.data = 0;
    this.status = 0x01; // TXRDY = 1
    this.ctrl = 0;
    // RX buffer — данные от терминала к CPU
    this.rxBuffer = [];
    this.rxMax = 256;
    // TX buffer — данные от CPU к терминалу
    this.txBuffer = [];
    // XOn-XOff flow control
    this.xonSent = true;
    this.xoffSent = false;
    this.xonThreshold = 50;
    this.xoffThreshold = 200;
    // Callback for terminal output
    this.onTxByte = null;
  }
  /** CPU reads USART */
  read(reg) {
    if (reg === 0) {
      // Data register — return next RX byte
      if (this.rxBuffer.length > 0) {
        const byte = this.rxBuffer.shift();
        this.data = byte;
        // Re-check flow control
        this._checkFlowControl();
      }
      this.status &= ~0x02; // clear RXRDY
      if (this.rxBuffer.length > 0) {
        this.status |= 0x02; // still have data
      }
      return this.data;
    } else {
      // Status register
      return this.status;
    }
  }
  /** CPU writes USART */
  write(reg, val) {
    if (reg === 0) {
      // Transmit data — CPU sent a byte
      this.data = val;
      this.txBuffer.push(val);
      this.status |= 0x01; // TXRDY
      // Notify terminal
      if (this.onTxByte) {
        this.onTxByte(val);
      }
    } else {
      // Control register
      if (val & 0x10) {
        // Reset
        this.rxBuffer = [];
        this.txBuffer = [];
        this.status = 0x01;
      }
      this.ctrl = val;
    }
  }
  /** Terminal sends data to USART (RX path) */
  receiveByte(byte) {
    if (byte === 0x13) {
      // XOff received — CPU should stop sending
      this.status &= ~0x01; // clear TXRDY
      return;
    }
    if (byte === 0x11) {
      // XOn received — CPU may resume
      this.status |= 0x01; // set TXRDY
      return;
    }
    this.rxBuffer.push(byte);
    this.status |= 0x02; // RXRDY
    this._checkFlowControl();
    // Trigger CPU interrupt
    if (this.onRxInterrupt) this.onRxInterrupt();
  }
  _checkFlowControl() {
    if (this.rxBuffer.length >= this.xoffThreshold && !this.xoffSent) {
      // Send XOff — tell terminal to pause
      this.xoffSent = true;
      this.xonSent = false;
      if (this.onTxByte) this.onTxByte(0x13);
    } else if (this.rxBuffer.length <= this.xonThreshold && this.xoffSent) {
      // Send XOn — tell terminal to resume
      this.xoffSent = false;
      this.xonSent = true;
      if (this.onTxByte) this.onTxByte(0x11);
    }
  }
  /** Get pending TX bytes for terminal display */
  drainTx() {
    const bytes = this.txBuffer.slice();
    this.txBuffer = [];
    return bytes;
  }
  getState() {
    return {
      data: this.data,
      status: this.status,
      ctrl: this.ctrl,
      rxPending: this.rxBuffer.length,
    };
  }
}
/* ═══════════════════════════════════════════════════════════════
 * Plotter Simulation
 * ═══════════════════════════════════════════════════════════════ */
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
    // Limit switches — triggered when head reaches table edge
    this.limitXmin = false;
    this.limitXmax = false;
    this.limitYmin = false;
    this.limitYmax = false;
    this.tableXmin = 0;
    this.tableXmax = 17200;  // plotter working area (HPGL units)
    this.tableYmin = 0;
    this.tableYmax = 12200;
  }
  checkLimits() {
    this.limitXmin = this.xPos <= this.tableXmin;
    this.limitXmax = this.xPos >= this.tableXmax;
    this.limitYmin = this.yPos <= this.tableYmin;
    this.limitYmax = this.yPos >= this.tableYmax;
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
    if (memX !== this.lastMemX) {
      this.xPos = memX; this.x = memX;
      this.lastMemX = memX;
    }
    if (memY !== this.lastMemY) {
      this.yPos = memY; this.y = memY;
      this.lastMemY = memY;
    }
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
    if (memColor !== this.lastMemColor) {
      this.penNum = Math.min(memColor, 6);
      this.lastMemColor = memColor;
    }
  }
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
  clearLines() {
    this.lines = [];
    this.currentSegment = null;
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
  const t = [];
  for (let i = 0; i < 256; i++) t[i] = null;
  // Helper
  const R = REG_NAMES;
  const C = COND_NAMES;
  const W = (a) => String.fromCharCode(a & 0xff);
  const def = (op, mnem, size, fmt) => {
    t[op] = { mnem, size, fmt: fmt || 'none' };
  };
  // NOP
  def(0x00, 'NOP', 1);
  // LXI B, D16
  def(0x01, 'LXI B,$$$1', 3, 'word');
  // STAX B
  def(0x02, 'STAX B', 1);
  // INX B
  def(0x03, 'INX B', 1);
  // INR B
  def(0x04, 'INR B', 1);
  // DCR B
  def(0x05, 'DCR B', 1);
  // MVI B, D8
  def(0x06, 'MVI B,$$$1', 2, 'byte');
  // RLC
  def(0x07, 'RLC', 1);
  // —
  def(0x08, 'NOP', 1); // undocumented
  // DAD B
  def(0x09, 'DAD B', 1);
  // LDAX B
  def(0x0a, 'LDAX B', 1);
  // DCX B
  def(0x0b, 'DCX B', 1);
  // INR C
  def(0x0c, 'INR C', 1);
  // DCR C
  def(0x0d, 'DCR C', 1);
  // MVI C, D8
  def(0x0e, 'MVI C,$$$1', 2, 'byte');
  // RRC
  def(0x0f, 'RRC', 1);
  // —
  def(0x10, 'NOP', 1);
  // LXI D, D16
  def(0x11, 'LXI D,$$$1', 3, 'word');
  // STAX D
  def(0x12, 'STAX D', 1);
  // INX D
  def(0x13, 'INX D', 1);
  // INR D
  def(0x14, 'INR D', 1);
  // DCR D
  def(0x15, 'DCR D', 1);
  // MVI D, D8
  def(0x16, 'MVI D,$$$1', 2, 'byte');
  // RAL
  def(0x17, 'RAL', 1);
  // —
  def(0x18, 'NOP', 1);
  // DAD D
  def(0x19, 'DAD D', 1);
  // LDAX D
  def(0x1a, 'LDAX D', 1);
  // DCX D
  def(0x1b, 'DCX D', 1);
  // INR E
  def(0x1c, 'INR E', 1);
  // DCR E
  def(0x1d, 'DCR E', 1);
  // MVI E, D8
  def(0x1e, 'MVI E,$$$1', 2, 'byte');
  // RAR
  def(0x1f, 'RAR', 1);
  // —
  def(0x20, 'NOP', 1);
  // LXI H, D16
  def(0x21, 'LXI H,$$$1', 3, 'word');
  // SHLD adr
  def(0x22, 'SHLD $$$1', 3, 'word');
  // INX H
  def(0x23, 'INX H', 1);
  // INR H
  def(0x24, 'INR H', 1);
  // DCR H
  def(0x25, 'DCR H', 1);
  // MVI H, D8
  def(0x26, 'MVI H,$$$1', 2, 'byte');
  // DAA
  def(0x27, 'DAA', 1);
  // —
  def(0x28, 'NOP', 1);
  // DAD H
  def(0x29, 'DAD H', 1);
  // LHLD adr
  def(0x2a, 'LHLD $$$1', 3, 'word');
  // DCX H
  def(0x2b, 'DCX H', 1);
  // INR L
  def(0x2c, 'INR L', 1);
  // DCR L
  def(0x2d, 'DCR L', 1);
  // MVI L, D8
  def(0x2e, 'MVI L,$$$1', 2, 'byte');
  // CMA
  def(0x2f, 'CMA', 1);
  // —
  def(0x30, 'NOP', 1);
  // LXI SP, D16
  def(0x31, 'LXI SP,$$$1', 3, 'word');
  // STA adr
  def(0x32, 'STA $$$1', 3, 'word');
  // INX SP
  def(0x33, 'INX SP', 1);
  // INR M
  def(0x34, 'INR M', 1);
  // DCR M
  def(0x35, 'DCR M', 1);
  // MVI M, D8
  def(0x36, 'MVI M,$$$1', 2, 'byte');
  // STC
  def(0x37, 'STC', 1);
  // —
  def(0x38, 'NOP', 1);
  // DAD SP
  def(0x39, 'DAD SP', 1);
  // LDA adr
  def(0x3a, 'LDA $$$1', 3, 'word');
  // DCX SP
  def(0x3b, 'DCX SP', 1);
  // INR A
  def(0x3c, 'INR A', 1);
  // DCR A
  def(0x3d, 'DCR A', 1);
  // MVI A, D8
  def(0x3e, 'MVI A,$$$1', 2, 'byte');
  // CMC
  def(0x3f, 'CMC', 1);
  // MOV B,B
  def(0x40, 'MOV B,B', 1);
  for (let d = 0; d < 8; d++) {
    for (let s = 0; s < 8; s++) {
      const op = 0x40 | (d << 3) | s;
      if (op >= 0x40 && op <= 0x7f && !t[op]) {
        def(op, `MOV ${R[d]},${R[s]}`, 1);
      }
    }
  }
  // HLT is 0x76, which would be MOV M,M — override
  def(0x76, 'HLT', 1);
  def(0x7f, 'MOV A,A', 1);
  // ADD r
  for (let r = 0; r < 8; r++) def(0x80 + r, `ADD ${R[r]}`, 1);
  // ADC r
  for (let r = 0; r < 8; r++) def(0x88 + r, `ADC ${R[r]}`, 1);
  // SUB r
  for (let r = 0; r < 8; r++) def(0x90 + r, `SUB ${R[r]}`, 1);
  // SBB r
  for (let r = 0; r < 8; r++) def(0x98 + r, `SBB ${R[r]}`, 1);
  // ANA r
  for (let r = 0; r < 8; r++) def(0xa0 + r, `ANA ${R[r]}`, 1);
  // XRA r
  for (let r = 0; r < 8; r++) def(0xa8 + r, `XRA ${R[r]}`, 1);
  // ORA r
  for (let r = 0; r < 8; r++) def(0xb0 + r, `ORA ${R[r]}`, 1);
  // CMP r
  for (let r = 0; r < 8; r++) def(0xb8 + r, `CMP ${R[r]}`, 1);
  // Conditional return / jump / call
  for (let c = 0; c < 8; c++) {
    def(0xc0 + c, `R${C[c]}`, 1);
    def(0xc2 + c, `J${C[c]} $$$1`, 3, 'word');
    def(0xc4 + c, `C${C[c]} $$$1`, 3, 'word');
  }
  def(0xc1, 'POP B', 1);
  def(0xc3, 'JMP $$$1', 3, 'word');
  def(0xc5, 'PUSH B', 1);
  def(0xc6, 'ADI $$$1', 2, 'byte');
  def(0xc7, 'RST 0', 1);
  def(0xc9, 'RET', 1);
  def(0xcb, 'NOP', 1);
  def(0xcd, 'CALL $$$1', 3, 'word');
  def(0xce, 'ACI $$$1', 2, 'byte');
  def(0xcf, 'RST 1', 1);
  // D1-D7
  def(0xd1, 'POP D', 1);
  def(0xd3, 'OUT $$$1', 2, 'port');
  def(0xd5, 'PUSH D', 1);
  def(0xd6, 'SUI $$$1', 2, 'byte');
  def(0xd7, 'RST 2', 1);
  def(0xda, 'JC $$$1', 3, 'word');
  def(0xdb, 'IN $$$1', 2, 'port');
  def(0xdc, 'CC $$$1', 3, 'word');
  def(0xde, 'SBI $$$1', 2, 'byte');
  def(0xdf, 'RST 3', 1);
  // E1-E7
  def(0xe1, 'POP H', 1);
  def(0xe3, 'XTHL', 1);
  def(0xe5, 'PUSH H', 1);
  def(0xe6, 'ANI $$$1', 2, 'byte');
  def(0xe7, 'RST 4', 1);
  def(0xe9, 'PCHL', 1);
  def(0xeb, 'XCHG', 1);
  def(0xec, 'CPE $$$1', 3, 'word');
  def(0xee, 'XRI $$$1', 2, 'byte');
  def(0xef, 'RST 5', 1);
  // F1-F7
  def(0xf1, 'POP PSW', 1);
  def(0xf3, 'DI', 1);
  def(0xf5, 'PUSH PSW', 1);
  def(0xf6, 'ORI $$$1', 2, 'byte');
  def(0xf7, 'RST 6', 1);
  def(0xf9, 'SPHL', 1);
  def(0xfb, 'EI', 1);
  def(0xfc, 'CM $$$1', 3, 'word');
  def(0xfe, 'CPI $$$1', 2, 'byte');
  def(0xff, 'RST 7', 1);
  return t;
}
function disasmInstruction(mmu, addr, optable) {
  const opcode = mmu.peek(addr);
  const op = optable ? optable[opcode] : null;
  if (!op) {
    return { addr, opcode, size: 1, mnemonic: 'DB $' + opcode.toString(16).padStart(2,'0').toUpperCase() };
  }
  let mnem = op.mnem;
  const size = op.len;
  if (size >= 2) {
    const b1 = mmu.peek(addr + 1);
    if (size === 2) {
      mnem = mnem.replace('$02', b1.toString(16).padStart(2,'0').toUpperCase());
    } else {
      const b2 = mmu.peek(addr + 2);
      const word = (b2 << 8) | b1;
      mnem = mnem.replace('$04$02', word.toString(16).padStart(4,'0').toUpperCase());
    }
  }
  return { addr, opcode, mnemonic: mnem, size };
}
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
    this.settings = new SettingsManager();
    this.ppi1 = new PPI8255('PPI1');
    this.ppi2 = new PPI8255('PPI2');
    this.pit = new PIT8253();
    this.uart = new USART8251();
    this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);
    this.mmu.onInvalidWrite = (addr, val) => this._onInvalidWrite(addr, val);
    this.cpu = new CPU8080(
      (addr) => this.mmu.readByte(addr),
      (addr, val) => this.mmu.writeByte(addr, val)
    );
    // Keyboard matrix state (6 rows × 2 columns)
    this._keyState = Array.from({length: 6}, () => [false, false]);
    // PPI1 read callbacks — keyboard rows on port A, DIP on port B
    this.ppi1.onReadPortA = () => this._readKeyboard();
    this.ppi1.onReadPortB = () => {
      const dip = this.settings?.config?.dip;
      let val = 0;
      if (dip) for (let i = 0; i < 4; i++) if (dip[i]) val |= (1 << (4 + i));
      // Inject limit switch bits into PB0-PB3
      if (this.plotter.limitXmin) val |= 0x01;
      if (this.plotter.limitXmax) val |= 0x02;
      if (this.plotter.limitYmin) val |= 0x04;
      if (this.plotter.limitYmax) val |= 0x08;
      return val;
    };
    this.plotter = new Plotter(this.mmu, this.settings);
    this.running = false;
    this.paused = false;
    this.runTimer = null;
    this.romLoaded = false;
    this.breakpoints = new Set();
    this.speedTable = [0, 100, 1000, 10000, 100000, 1000000];
    this.labelMap = {};
    this.disasmCache = [];
    this.disasmAddr = 0;
    // Memory dump state
    this.memScrollAddr = 0x6000;
    this.editingByte = null; // { addr, element }
    // USART terminal state
    this.usartTxLog = '';
    this.usartAutoScroll = true;
    // HPGL state
    this.hpglTotal = 0;
    this.hpglCurrent = 0;
    this.hpglCmdText = '';
    this.hpglCmds = [];
    this._asmHoverAddr = null;
    this._hpglPaused = false;
    this._memUpdating = false;
    this._cacheDOM();
    this._bindEvents();
    this._resetState();
    // Show placeholder until firmware loads
    this.els.asmList.innerHTML = '<div style="color:var(--text-dim);padding:20px;text-align:center;font-size:12px;font-family:var(--font-mono)">Waiting for firmware...</div>';
    this._updateMemoryDump(0x6000);
    this._updateIO();
    this._setupPlotterResize();
    this._applyTheme(this.settings.config.theme);
    this._syncDIP();
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
      memContainer: this.$('mem-container'),
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
      plotterClear: this.$('plotter-clear'),
      plotterAutofit: this.$('plotter-autofit'),
      loadStatus: this.$('load-status'),
      plotterColor: this.$('plotter-color'),
      btnSettings: this.$('btn-settings'),
      stackDisplay: this.$('stack-display'),
      pointersDisplay: this.$('pointers-display'),
      usartRxLog: this.$('usart-rx-log'),
      usartTxInput: this.$('usart-tx-input'),
      usartTxSend: this.$('usart-tx-send'),
      usartTxFile: this.$('usart-tx-file'),
      usartFileInput: this.$('usart-file-input'),
      usartClear: this.$('usart-clear'),
      usartStatus: this.$('usart-status'),
      btnSaveSession: this.$('btn-save-session'),
      btnLoadSession: this.$('btn-load-session'),
      sessionFileInput: this.$('session-file-input'),
      btnLoadHpgl: this.$('btn-load-hpgl'),
      hpglFileInput: this.$('hpgl-file-input'),
      hpglStatus: this.$('hpgl-status'),
      hpglProgress: this.$('plotter-hpgl-progress'),
      hpglCmd: this.$('plotter-hpgl-cmd'),
      hpglUartMode: this.$('hpgl-uart-mode'),
      hpglPause: this.$('hpgl-pause'),
      btnCopyAsm: this.$('btn-copy-asm'),
      btnHelp: this.$('btn-help'),
    };
  }
  _bindEvents() {
    if (this.els.btnReset) this.els.btnReset.addEventListener('click', () => this.reset());
    if (this.els.btnStep) this.els.btnStep.addEventListener('click', () => this.step());
    if (this.els.btnRun) this.els.btnRun.addEventListener('click', () => this.run());
    if (this.els.btnPause) this.els.btnPause.addEventListener('click', () => this.pause());
    if (this.els.speedSlider) this.els.speedSlider.addEventListener('input', () => {
      const idx = parseInt(this.els.speedSlider.value);
      const speeds = ['∞ (макс)', '100 Hz', '1 KHz', '10 KHz', '100 KHz', '1 MHz'];
      this.els.speedLabel.textContent = speeds[idx];
    });
    if (this.els.btnLoadRom) this.els.btnLoadRom.addEventListener('click', () => this.els.romFileInput.click());
    if (this.els.btnSettings) this.els.btnSettings.addEventListener('click', () => {
      this._openSettings();
    });
    if (this.els.btnHelp) this.els.btnHelp.addEventListener('click', () => this._openHelp());
    if (this.els.romFileInput) this.els.romFileInput.addEventListener('change', (e) => this._handleROMFiles(e));
    if (this.els.asmSearch) this.els.asmSearch.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        const addr = parseInt(this.els.asmSearch.value, 16);
        if (!isNaN(addr)) this._rebuildDisasm(addr);
      }
    });
    // Infinite scroll for disassembler
    if (this.els.asmList) this.els.asmList.addEventListener('scroll', () => {
      const list = this.els.asmList;
      if (!list || list.scrollHeight <= list.clientHeight) return;
      const scrollPct = list.scrollTop / (list.scrollHeight - list.clientHeight);
      if (scrollPct > 0.85 && this._asmLastAddr < 0xfff0) this._appendDisasm();
      else if (scrollPct < 0.05 && this._asmFirstAddr > 0) this._prependDisasm();
    });
    // Copy disassembly range
    if (this.els.btnCopyAsm) this.els.btnCopyAsm.addEventListener('click', () => this._copyDisasmRange());
    if (this.els.memRefresh) this.els.memRefresh.addEventListener('click', () => {
      const addr = parseInt(this.els.memAddr.value, 16);
      if (!isNaN(addr)) { this.memScrollAddr = addr; this._updateMemoryDump(addr); }
    });
    if (this.els.memAddr) this.els.memAddr.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        const addr = parseInt(this.els.memAddr.value.trim().replace(/^\$/,''), 16);
        if (!isNaN(addr)) { this.memScrollAddr = addr & 0xfff0; this._updateMemoryDump(this.memScrollAddr); }
      }
    });
    if (this.els.memContainer) this.els.memContainer.addEventListener('scroll', () => this._onMemScroll());
    this._setupRegisterEditing();
    this._setupUSARTTerminal();
    if (this.els.plotterClear) this.els.plotterClear.addEventListener('click', () => { this.plotter.clearLines(); this._renderPlotterCanvas(); });
    if (this.els.plotterAutofit) this.els.plotterAutofit.addEventListener('click', () => this._renderPlotterCanvas(true));
    if (this.els.btnSaveSession) this.els.btnSaveSession.addEventListener('click', () => this._saveSession());
    if (this.els.btnLoadSession) this.els.btnLoadSession.addEventListener('click', () => this.els.sessionFileInput.click());
    if (this.els.sessionFileInput) this.els.sessionFileInput.addEventListener('change', (e) => this._loadSession(e));
    if (this.els.btnLoadHpgl) this.els.btnLoadHpgl.addEventListener('click', () => this.els.hpglFileInput.click());
    if (this.els.hpglFileInput) this.els.hpglFileInput.addEventListener('change', (e) => this._loadHPGL(e));
    if (this.els.hpglPause) this.els.hpglPause.addEventListener('click', () => {
      this._hpglPaused = !this._hpglPaused;
      this.els.hpglPause.textContent = this._hpglPaused ? '\u25B6' : '\u23F8';
    });
    this.uart.onTxByte = (byte) => this._onUSARTTxByte(byte);
    this.uart.onRxInterrupt = () => { this.cpu.intr = true; };
    document.addEventListener('keydown', (e) => this._onKeyDown(e));
    window.addEventListener('resize', () => this._updatePlotterSize());
    // Keyboard matrix buttons
    document.querySelectorAll('.kbd-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const r = parseInt(btn.dataset.r);
        const c = parseInt(btn.dataset.c);
        this._keyState[r][c] = !this._keyState[r][c];
        btn.classList.toggle('kbd-pressed');
      });
    });
    this._setupSplitter();
  }
  /* ═══════════════════════════════════════════════════════════════
   * Keyboard shortcuts
   * ═══════════════════════════════════════════════════════════════ */
  _onKeyDown(e) {
    // Don't hijack when typing in inputs
    const tag = e.target.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
    switch (e.key) {
      case ' ':
      case 'ArrowRight':
        e.preventDefault();
        this.step();
        break;
      case 'r':
      case 'R':
        this.reset();
        break;
      case 'F5':
        e.preventDefault();
        if (this.running) this.pause();
        else this.run();
        break;
      case 'b':
      case 'B':
        if (this.breakpoints.has(this.cpu.pc)) {
          this.breakpoints.delete(this.cpu.pc);
        } else {
          this.breakpoints.add(this.cpu.pc);
        }
        this._renderDisasm();
        break;
      case 'j':
      case 'J':
        // Jump PC to hovered address in disasm
        if (this._asmHoverAddr !== undefined && this._asmHoverAddr !== null) {
          this.cpu.pc = this._asmHoverAddr;
          this._updateAll();
          if (this.els.asmFollowPc.checked) this._ensureVisible(this.cpu.pc);
        }
        break;
      case '/':
      case '?':
        e.preventDefault();
        this._openHelp();
        break;
    }
  }
  /* ═══════════════════════════════════════════════════════════════
   * Plotter A4 resize
   * ═══════════════════════════════════════════════════════════════ */
  _setupPlotterResize() {
    this._updatePlotterSize();
    if (window.ResizeObserver) {
      const obs = new ResizeObserver(() => this._updatePlotterSize());
      obs.observe(this.els.plotterCanvas.parentElement);
    }
  }
  _updatePlotterSize() {
    const canvas = this.els.plotterCanvas;
    if (!canvas) return;
    const parent = canvas.parentElement;
    const availHeight = parent.clientHeight - 30; // info line
    const availWidth = window.innerWidth * 0.25; // max ~25% of viewport
    // A4 portrait: w/h = 1/√2 ≈ 0.707
    const a4Ratio = 1 / Math.SQRT2;
    let h = Math.min(availHeight, window.innerHeight - 160);
    let w = h * a4Ratio;
    if (w > availWidth) {
      w = Math.max(availWidth, 250);
      h = w / a4Ratio;
    }
    w = Math.max(w, 200);
    h = Math.max(h, 280);
    canvas.style.width = Math.floor(w) + 'px';
    canvas.style.height = Math.floor(h) + 'px';
    canvas.width = Math.floor(w * 2); // retina-scale canvas buffer
    canvas.height = Math.floor(h * 2);
  }
  /* ═══════════════════════════════════════════════════════════════
   * Resizable splitter (disasm / memory)
   * ═══════════════════════════════════════════════════════════════ */
  _setupSplitter() {
    const splitter = document.getElementById('splitter');
    const disasmSection = document.getElementById('disasm-section');
    const memSection = document.getElementById('memory-section');
    if (!splitter || !disasmSection || !memSection) return;
    let dragging = false;
    splitter.addEventListener('mousedown', (e) => {
      dragging = true;
      document.body.style.cursor = 'ns-resize';
      document.body.style.userSelect = 'none';
    });
    document.addEventListener('mousemove', (e) => {
      if (!dragging) return;
      const center = document.getElementById('center-region');
      if (!center) return;
      const rect = center.getBoundingClientRect();
      const y = e.clientY - rect.top;
      const minDisasm = 100;
      const minMem = 80;
      const total = rect.height;
      const disasmH = Math.max(minDisasm, Math.min(total - minMem, y));
      const memH = Math.max(minMem, total - disasmH);
      disasmSection.style.flex = 'none';
      disasmSection.style.height = disasmH + 'px';
      memSection.style.flex = 'none';
      memSection.style.height = memH + 'px';
    });
    document.addEventListener('mouseup', () => {
      dragging = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    });
  }
  /* ═══════════════════════════════════════════════════════════════
   * Editable registers
   * ═══════════════════════════════════════════════════════════════ */
  _setupRegisterEditing() {
    const regs8 = ['regA','regB','regC','regD','regE','regH','regL','regF'];
    const regs16 = ['regSP','regPC'];
    const regMap8 = { regA:'a', regB:'b', regC:'c', regD:'d', regE:'e', regH:'h', regL:'l', regF:'flags' };
    const regMap16 = { regSP:'sp', regPC:'pc' };
    for (const key of regs8) {
      const el = this.els[key];
      if (!el) continue;
      el.addEventListener('click', () => {
        if (el.classList.contains('editing')) return;
        const cur = el.textContent;
        el.innerHTML = `<input class="reg-val-inp" type="text" value="${cur}" maxlength="2" style="width:32px">`;
        el.classList.add('editing');
        const inp = el.querySelector('input');
        inp.focus();
        inp.select();
        const finish = () => {
          const raw = inp.value.trim().toLowerCase();
          let val = parseInt(raw, 16);
          if (isNaN(val)) val = parseInt(cur, 16);
          val = Math.min(0xff, Math.max(0, val));
          this.cpu[regMap8[key]] = val;
          el.classList.remove('editing');
          this._updateAll();
        };
        inp.addEventListener('blur', finish);
        inp.addEventListener('keydown', (ev) => {
          if (ev.key === 'Enter') { inp.blur(); }
          if (ev.key === 'Escape') { el.innerHTML = cur; el.classList.remove('editing'); }
        });
      });
    }
    for (const key of regs16) {
      const el = this.els[key];
      if (!el) continue;
      el.addEventListener('click', () => {
        if (el.classList.contains('editing')) return;
        const cur = el.textContent;
        el.innerHTML = `<input class="reg-val-inp pc-sp" type="text" value="${cur}" maxlength="4">`;
        el.classList.add('editing');
        const inp = el.querySelector('input');
        inp.focus();
        inp.select();
        const finish = () => {
          const raw = inp.value.trim().toLowerCase();
          let val = parseInt(raw, 16);
          if (isNaN(val)) val = parseInt(cur, 16);
          val = Math.min(0xffff, Math.max(0, val));
          this.cpu[regMap16[key]] = val;
          el.classList.remove('editing');
          this._updateAll();
        };
        inp.addEventListener('blur', finish);
        inp.addEventListener('keydown', (ev) => {
          if (ev.key === 'Enter') { inp.blur(); }
          if (ev.key === 'Escape') { el.innerHTML = cur; el.classList.remove('editing'); }
        });
      });
    }
    // Click flags to toggle
    ['flagS','flagZ','flagAC','flagP','flagCY'].forEach(key => {
      const el = this.els[key];
      if (!el) return;
      el.classList.add('clickable');
      el.addEventListener('click', () => {
        let bit;
        switch (key) {
          case 'flagS': bit = 0x80; break;
          case 'flagZ': bit = 0x40; break;
          case 'flagAC': bit = 0x10; break;
          case 'flagP': bit = 0x04; break;
          case 'flagCY': bit = 0x01; break;
        }
        this.cpu.flags ^= bit;
        this.cpu.flags |= 0x02; // keep bit 1 always set (8080)
        this._updateRegisters();
      });
    });
  }
  /* ═══════════════════════════════════════════════════════════════
   * USART Terminal
   * ═══════════════════════════════════════════════════════════════ */
  _setupUSARTTerminal() {
    this.els.usartTxSend.addEventListener('click', () => this._sendUSARTBytes());
    this.els.usartTxInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') this._sendUSARTBytes();
    });
    this.els.usartTxFile.addEventListener('click', () => this.els.usartFileInput.click());
    this.els.usartFileInput.addEventListener('change', (e) => this._sendUSARTFile(e));
    this.els.usartClear.addEventListener('click', () => {
      this.usartTxLog = '';
      this.els.usartRxLog.textContent = '';
    });
  }
  _sendUSARTBytes() {
    const raw = this.els.usartTxInput.value.trim();
    if (!raw) return;
    // Parse hex bytes: "01 02 FF" or "01,02,FF"
    const parts = raw.split(/[\s,;]+/);
    for (const p of parts) {
      const b = parseInt(p, 16);
      if (!isNaN(b) && b >= 0 && b <= 0xff) {
        this.uart.receiveByte(b);
        this._logToUSART(`→ $${b.toString(16).padStart(2,'0').toUpperCase()}`, 'var(--cyan)');
      }
    }
    this.els.usartTxInput.value = '';
    this._updateUSARTStatus();
  }
  async _sendUSARTFile(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    const buf = await file.arrayBuffer();
    const bytes = new Uint8Array(buf);
    this._logToUSART(`📂 Файл: ${file.name} (${bytes.length} B)`, 'var(--yellow)');
    this._logToUSART(`  XOn-XOff: отправка...`, 'var(--text-dim)');
    // Send with XOn-XOff pacing
    let i = 0;
    const sendNext = () => {
      const batch = 16;
      for (let j = 0; j < batch && i < bytes.length; j++, i++) {
        this.uart.receiveByte(bytes[i]);
      }
      this._logToUSART(`· ${i}/${bytes.length}`, 'var(--text-dim)');
      this._updateUSARTStatus();
      if (i < bytes.length) {
        setTimeout(sendNext, 5);
      } else {
        this._logToUSART(`✓ Передача завершена`, 'var(--green)');
      }
    };
    sendNext();
    event.target.value = '';
  }
  _onUSARTTxByte(byte) {
    // Show printable chars directly, hex for others
    const c = (byte >= 0x20 && byte <= 0x7e) ? String.fromCharCode(byte) : '';
    const hex = `$${byte.toString(16).padStart(2,'0').toUpperCase()}`;
    if (byte === 0x13) {
      this._logToUSART(`[XOff]`, 'var(--yellow)');
    } else if (byte === 0x11) {
      this._logToUSART(`[XOn]`, 'var(--green)');
    } else if (c) {
      this._logToUSART(c, 'var(--text)');
    } else {
      this._logToUSART(`<${hex}>`, 'var(--text-dim)');
    }
    this._updateUSARTStatus();
  }
  _logToUSART(text, color) {
    const el = this.els.usartRxLog;
    if (!el) return;
    const span = document.createElement('span');
    span.textContent = text;
    if (color) span.style.color = color;
    el.appendChild(span);
    el.scrollTop = el.scrollHeight;
  }
  _updateUSARTStatus() {
    const el = this.els.usartStatus;
    if (!el) return;
    const s = this.uart.status;
    const txrdy = s & 0x01 ? '✓' : '✕';
    const rxrdy = s & 0x02 ? '✓' : '✕';
    const rxQ = this.uart.rxBuffer.length;
    el.textContent = `TXRDY:${txrdy} RXRDY:${rxrdy} RXQ:${rxQ} | TX:${this.uart.txBuffer.length}B`;
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
  async _handleROMFiles(event) {
    const files = event.target.files;
    if (!files || files.length === 0) return;
    const buffers = [];
    for (const file of files) {
      const buf = await file.arrayBuffer();
      buffers.push(new Uint8Array(buf));
    }
    const totalBytes = buffers.reduce((s, b) => s + b.length, 0);
    this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);
    this.mmu.onInvalidWrite = (addr, val) => this._onInvalidWrite(addr, val);
    if (buffers.length === 1 && buffers[0].length === 0x6000) {
      this.mmu.loadROM(buffers[0], 0x0000);
      this._setLoadStatus(`Загружена прошивка 24KB (3 чипа)`, 'ok');
    } else if (buffers.length === 1 && buffers[0].length === 0x2000) {
      this.mmu.loadROM(buffers[0], 0x0000);
      this._setLoadStatus(`Загружен Chip 1 (8KB)`, 'ok');
    } else {
      const sorted = Array.from(buffers).sort((a, b) => a.length - b.length);
      for (let i = 0; i < Math.min(sorted.length, 3); i++) {
        this.mmu.loadROM(sorted[i], i * 0x2000);
      }
      this._setLoadStatus(`Загружено ${Math.min(sorted.length, 3)} чипа(ов)`, 'ok');
    }
    this.romLoaded = true;
    this.cpu = new CPU8080(
      (addr) => this.mmu.readByte(addr),
      (addr, val) => this.mmu.writeByte(addr, val)
    );
    this.plotter.reset();
    this.plotter.mmu = this.mmu;
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
  /* ═══════════════════════════════════════════════════════════════
   * Settings Panel (unchanged)
   * ═══════════════════════════════════════════════════════════════ */
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
    document.querySelectorAll('.cfg-var-addr').forEach(inp => {
      const key = inp.dataset.key;
      const raw = inp.value.replace(/^\$/, '');
      const addr = parseInt(raw, 16);
      if (!isNaN(addr)) this.settings.setAddr(key, addr);
    });
    document.querySelectorAll('.cfg-chip-offset').forEach(inp => {
      const idx = parseInt(inp.dataset.idx);
      const raw = inp.value.replace(/^\$/, '');
      const offset = parseInt(raw, 16);
      if (!isNaN(offset)) this.settings.setChipOffset(idx, offset);
    });
    // Read DIP switches
    document.querySelectorAll('.cfg-dip').forEach(cb => {
      const idx = parseInt(cb.dataset.idx);
      this.settings.config.dip[idx] = cb.checked;
    });
    this._syncDIP();
    this.settings.save();
    overlay.remove();
  }
  _bindSettingsEvents() {
    const overlay = document.getElementById('settings-overlay');
    if (!overlay) return;
    overlay.querySelector('#settings-close').addEventListener('click', () => this._closeSettings());
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) this._closeSettings();
    });
    const onKey = (e) => { if (e.key === 'Escape') this._closeSettings(); };
    document.addEventListener('keydown', onKey);
    const origClose = this._closeSettings.bind(this);
    this._closeSettings = () => { document.removeEventListener('keydown', onKey); origClose(); };
    const loadBtn = overlay.querySelector('#settings-load-rom');
    const fileInput = overlay.querySelector('#settings-rom-input');
    loadBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', (e) => this._handleSettingsROM(e, overlay));
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
    overlay.querySelector('#settings-custom-add').addEventListener('click', () => {
      this.settings.addCustom('var' + (this.settings.config.custom.length + 1), 0x6000);
      overlay.remove();
      this._openSettings();
    });
    overlay.querySelector('#custom-vars-table tbody').addEventListener('click', (e) => {
      const btn = e.target.closest('.cfg-custom-remove');
      if (btn) {
        this.settings.removeCustom(parseInt(btn.dataset.id));
        overlay.remove();
        this._openSettings();
      }
    });
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
      this.mmu = new MMU(this.ppi1, this.ppi2, this.pit, this.uart);
      this.mmu.onInvalidWrite = (addr, val) => this._onInvalidWrite(addr, val);
      this.mmu.loadROM(data, loadAddr);
      this.romLoaded = true;
      this.cpu = new CPU8080(
        (addr) => this.mmu.readByte(addr),
        (addr, val) => this.mmu.writeByte(addr, val)
      );
      this.plotter.reset();
    this.plotter.mmu = this.mmu;
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
  reset() {
    this._resetState();
    this.cpu.reset();
    this.plotter.reset();
    this._updateAll();
  }
  step() {
    try {
      if (!this.romLoaded) return;
      if (this.cpu.halt) return;
      this.paused = true;
      this.running = false;
      this.cpu.step();
      this._syncPlotter();
      this._updateAll();
      if (this.els.asmFollowPc && this.els.asmFollowPc.checked) {
        this._ensureVisible(this.cpu.pc);
      }
    } catch (e) {
      console.error('[AFTOGRAF] step() error:', e);
    }
  }
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
      this._runMax();
    } else {
      this.runTimer = setInterval(() => {
        if (!this.running || this.cpu.halt) {
          this.pause();
          return;
        }
        const stepsPerTick = Math.max(1, Math.floor(speed / 30));
        for (let i = 0; i < stepsPerTick; i++) {
          if (this.cpu.halt) break;
          this.cpu.step();
          this._syncPlotter();
          if (this.breakpoints.has(this.cpu.pc)) {
            this.pause();
            break;
          }
        }
        this._updateAll();
      }, 33);
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
  /** Sync DIP switch state to PIO1 port B bits PB4-PB7 and port C bits PC4-PC7 */
  _syncDIP() {
    const dip = this.settings?.config?.dip;
    if (!dip) return;
    let val = 0;
    for (let i = 0; i < 4; i++) {
      if (dip[i]) val |= (1 << (4 + i));
    }
    this.ppi1.portB = (this.ppi1.portB & 0x0f) | val;
    this.ppi1.portC = (this.ppi1.portC & 0x0f) | val;
  }
  /** Read keyboard matrix state for PPI1 port A.
   *  Firmware scans by driving column bits (PC0-PC1) low and reading rows (PA0-PA5).
   *  Returns row bits: bit N = 0 when key at (row N, active column) is pressed. */
  _readKeyboard() {
    const activeCol = (~this.ppi1.portC) & 0x03;
    let rows = 0xff;
    for (let c = 0; c < 2; c++) {
      if (activeCol & (1 << c)) {
        for (let r = 0; r < 6; r++) {
          if (this._keyState[r][c]) rows &= ~(1 << r);
        }
      }
    }
    return rows;
  }

  _syncPlotter() {
    this.plotter.syncFromMemory();
    this.plotter.updateStepper('x', this.ppi1.portA);
    this.plotter.updateStepper('y', this.ppi1.portB);
    this.plotter.setPen(this.ppi2.portC);
    this.plotter.updatePosition();
    this.plotter.checkLimits();
  }
  _updateAll() {
    this._updateRegisters();
    this._updateStatusBar();
    this._updateCurrentInsn();
    this._updateDisasmHighlights();
    this._hlAddr = this.cpu.getHL();
    const writeAddr = this.mmu.lastWriteAddr;
    let targetAddr = -1;
    // Only auto-follow memory view when writes happen in RAM range (0x6000+)
    // or when HL points to a non-zero address — prevents jump to 0 after reset
    if (writeAddr >= 0x6000 && writeAddr < 0x10000) targetAddr = writeAddr;
    else if (this._hlAddr > 0 && this._hlAddr < 0x10000) targetAddr = this._hlAddr;
    if (targetAddr >= 0) {
      this.memScrollAddr = targetAddr & 0xfff0;
      this.els.memAddr.value = this.memScrollAddr.toString(16).padStart(4,'0').toUpperCase();
    }
    this._updateMemoryDump(this.memScrollAddr);
    this._updateIO();
    this._updatePlotterUI();
    this._updateStack();
    this._updatePointers();
    this._renderPlotterCanvas();
    this._updateUSARTStatus();
  }
  _onInvalidWrite(addr, val) {
    this.pause();
    const region = addr < 0x6000 ? 'ROM' : addr < 0xe000 ? 'свободная область' : 'зарезервированная';
    const msg = `⛔ Запись $${val.toString(16).padStart(2,'0').toUpperCase()} в ${region} ($${addr.toString(16).padStart(4,'0').toUpperCase()})`;
    if (this.els.loadStatus) {
      this.els.loadStatus.textContent = msg;
      this.els.loadStatus.className = 'load-status-error';
      this.els.loadStatus.style.display = 'block';
    }
    console.warn('[MMU]', msg);
  }
  _updateRegisters() {
    const s = this.cpu.getState();
    const setReg = (el, val, len) => {
      if (el && !el.classList.contains('editing')) {
        el.textContent = val.toString(16).padStart(len,'0').toUpperCase();
      }
    };
    setReg(this.els.regA, s.a, 2);
    setReg(this.els.regB, s.b, 2);
    setReg(this.els.regC, s.c, 2);
    setReg(this.els.regD, s.d, 2);
    setReg(this.els.regE, s.e, 2);
    setReg(this.els.regH, s.h, 2);
    setReg(this.els.regL, s.l, 2);
    setReg(this.els.regSP, s.sp, 4);
    setReg(this.els.regPC, s.pc, 4);
    setReg(this.els.regF, s.flags, 2);
    this.els.flagS.classList.toggle('active', !!(s.flags & 0x80));
    this.els.flagZ.classList.toggle('active', !!(s.flags & 0x40));
    this.els.flagAC.classList.toggle('active', !!(s.flags & 0x10));
    this.els.flagCY.classList.toggle('active', !!(s.flags & 0x01));
  }
  _updateCurrentInsn() {
    const pc = this.cpu.pc;
    const insn = disasmInstruction(this.mmu, pc, this.cpu.optable);
    let bytes = '';
    for (let i = 0; i < insn.size; i++) {
      bytes += this.mmu.peek(pc + i).toString(16).padStart(2,'0').toUpperCase() + ' ';
    }
    this.els.currentInsn.textContent = insn.mnemonic;
    this.els.currentBytes.textContent = bytes.trim();
  }
  _rebuildDisasm(addr) {
    const NUM_LINES = 512;
    const half = NUM_LINES / 2;
    const start = Math.max(0, addr - half * 2);
    this.disasmAddr = start;
    this.disasmCache = [];
    let a = start;
    for (let i = 0; i < NUM_LINES && a < 0x10000; i++) {
      const insn = disasmInstruction(this.mmu, a, this.cpu.optable);
      if (i < 4) console.log(`[DASM] $${a.toString(16).padStart(4,'0')} → '${insn.mnemonic}'`);
      this.disasmCache.push(insn);
      a += insn.size;
    }
    this._asmFirstAddr = this.disasmCache.length > 0 ? this.disasmCache[0].addr : 0;
    this._asmLastAddr = this.disasmCache.length > 0 ? this.disasmCache[this.disasmCache.length-1].addr : 0;
    this._renderDisasm();
  }
  _appendDisasm() {
    if (!this.disasmCache.length) return;
    const last = this.disasmCache[this.disasmCache.length - 1];
    let a = last.addr + last.size;
    const before = this.disasmCache.length;
    for (let i = 0; i < 200 && a < 0x10000; i++) {
      const insn = disasmInstruction(this.mmu, a, this.cpu.optable);
      this.disasmCache.push(insn);
      a += insn.size;
    }
    this._asmLastAddr = this.disasmCache[this.disasmCache.length - 1].addr;
    this._renderDisasm();
  }
  _prependDisasm() {
    if (!this.disasmCache.length) return;
    const firstAddr = this.disasmCache[0].addr;
    let a = Math.max(0, firstAddr - 200);
    const newInsns = [];
    for (let i = 0; i < 200 && a < firstAddr && a < 0x10000; i++) {
      const insn = disasmInstruction(this.mmu, a, this.cpu.optable);
      if (insn.addr + insn.size <= firstAddr) {
        newInsns.push(insn);
      }
      if (insn.addr + insn.size > firstAddr) break;
      a += insn.size;
    }
    if (newInsns.length > 0) {
      const scrollTarget = this.disasmCache[0].addr;
      const removeCount = Math.min(newInsns.length, Math.floor(this.disasmCache.length * 0.3));
      this.disasmCache.splice(this.disasmCache.length - removeCount, removeCount);
      this.disasmCache.unshift(...newInsns);
      this._asmFirstAddr = this.disasmCache[0].addr;
      this._asmLastAddr = this.disasmCache[this.disasmCache.length - 1].addr;
      this._renderDisasm();
    }
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
      // Hover tracking for J-key jump
      line.addEventListener('mouseenter', () => {
        this._asmHoverAddr = insn.addr;
        line.classList.add('asm-hover');
      });
      line.addEventListener('mouseleave', () => {
        line.classList.remove('asm-hover');
      });
      line.addEventListener('click', () => {
        if (this.breakpoints.has(insn.addr)) {
          this.breakpoints.delete(insn.addr);
        } else {
          this.breakpoints.add(insn.addr);
        }
        this._renderDisasm();
      });
      // Double-click — jump PC to this address
      line.addEventListener('dblclick', () => {
        this._asmHoverAddr = insn.addr;
        this.cpu.pc = insn.addr;
        this._updateAll();
        if (this.els.asmFollowPc.checked) this._ensureVisible(this.cpu.pc);
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
    const pc = this.cpu.pc;
    const lines = this.els.asmList.querySelectorAll('.asm-line');
    let idx = 0;
    for (const insn of this.disasmCache) {
      if (idx >= lines.length) break;
      lines[idx].classList.toggle('current', insn.addr === pc);
      idx++;
    }
  }

  _copyDisasmRange() {
    let text = '';
    for (const insn of this.disasmCache) {
      const bytes = [];
      for (let i = 0; i < insn.size; i++) bytes.push(this.mmu.peek(insn.addr + i).toString(16).padStart(2,'0').toUpperCase());
      text += `${insn.addr.toString(16).padStart(4,'0').toUpperCase()} ${bytes.join(' ').padEnd(9)} ${insn.mnemonic}\n`;
    }
    navigator.clipboard.writeText(text).catch(() => {});
    if (this.els.loadStatus) {
      this.els.loadStatus.textContent = `📋 Скопировано ${this.disasmCache.length} строк`;
      this.els.loadStatus.className = 'load-status-info';
      this.els.loadStatus.style.display = 'block';
      setTimeout(() => { if (this.els.loadStatus) this.els.loadStatus.style.display = 'none'; }, 2000);
    }
  }
  _ensureVisible(addr) {
    const first = this.disasmCache[0];
    const last = this.disasmCache[this.disasmCache.length - 1];
    if (!first || !last) return;
    if (addr < first.addr || addr > last.addr) {
      this._rebuildDisasm(addr);
      return;
    }
    const lines = this.els.asmList.querySelectorAll('.asm-line');
    for (let i = 0; i < this.disasmCache.length && i < lines.length; i++) {
      if (this.disasmCache[i].addr === addr) {
        lines[i].scrollIntoView({ block: 'center' });
        break;
      }
    }
  }
  /* ═══════════════════════════════════════════════════════════════
   * Memory Dump — scrollable through all 64KB, editable bytes
   */
  _onMemScroll() {
    if (this._memUpdating) return;
    const container = this.els.memContainer;
    if (!container) return;
    const scrollTop = container.scrollTop;
    const lineHeight = 17;
    const rowIndex = Math.floor(scrollTop / lineHeight);
    const newAddr = rowIndex * 16;
    if (newAddr >= 0 && newAddr <= 0xfff0) {
      // Only re-render if address changed by more than 1 row (16 bytes)
      // — prevents cascade from programmatic scrollTop settling
      const diff = Math.abs(newAddr - this.memScrollAddr);
      if (diff >= 16) {
        this.memScrollAddr = newAddr;
        this.els.memAddr.value = newAddr.toString(16).padStart(4,'0').toUpperCase();
        this._updateMemoryDump(newAddr);
      }
    }
  }
  _updateMemoryDump(addr) {
    const dump = this.els.memDump;
    const container = this.els.memContainer;
    if (!dump || !container) return;
    if (this._memUpdating) return;
    this._memUpdating = true;
    this.memScrollAddr = addr & 0xfff0;

    const totalRows = 0x10000 / 16; // 4096 rows
    const lineHeight = 17;

    // Ensure spacer exists for scroll extent
    let spacer = container.querySelector('.mem-spacer');
    if (!spacer) {
      spacer = document.createElement('div');
      spacer.className = 'mem-spacer';
      spacer.style.cssText = 'height:1px;pointer-events:none';
      container.insertBefore(spacer, dump);
    }
    spacer.style.height = (totalRows * lineHeight) + 'px';

    const targetRow = this.memScrollAddr / 16;
    const visHeight = container.clientHeight || 200;
    // Scroll to exact target row — NO centering offset.
    // Centering (targetRow - visRows/2) causes cascade: the read-back scrollTop
    // gives a different address, _onMemScroll fires again, another update → loop.
    // Exact row ensures scrollTop → rowIndex → newAddr round-trips correctly.
    container.scrollTop = Math.max(0, targetRow * lineHeight);

    // Calculate visible rows from scroll position (container, now scrollable)
    const scrollTop = container.scrollTop || 0;
    const firstRow = Math.max(0, Math.floor(scrollTop / lineHeight));
    const lastRow = Math.min(totalRows - 1, Math.ceil((scrollTop + visHeight) / lineHeight));

    // Position the dump
    dump.style.position = 'absolute';
    dump.style.top = (firstRow * lineHeight) + 'px';
    dump.style.width = '100%';
    dump.innerHTML = '';

    const ramStart = 0x6000;
    const ramEnd = 0x63ff;
    for (let r = firstRow; r <= lastRow; r++) {
      const base = r * 16;
      const line = document.createElement('div');
      line.className = 'mem-line';
      if (base >= ramStart && base <= ramEnd) line.classList.add('watch');
      let addrStr = base.toString(16).padStart(4,'0').toUpperCase();
      const hexSpan = document.createElement('span');
      hexSpan.className = 'mem-hex';
      for (let c = 0; c < 16; c++) {
        const byteAddr = base + c;
        const byteVal = this.mmu.peek(byteAddr);
        const byteSpan = document.createElement('span');
        byteSpan.className = 'mem-byte';
        byteSpan.textContent = byteVal.toString(16).padStart(2,'0').toUpperCase();
        byteSpan.dataset.addr = byteAddr;
        byteSpan.dataset.val = byteVal;
        // Color by region
        if (byteAddr >= 0xe000) {
          byteSpan.style.color = 'var(--purple)';
        } else if (byteAddr >= ramStart && byteAddr <= ramEnd) {
          byteSpan.style.color = 'var(--yellow)';
        } else if (byteAddr < 0x6000) {
          byteSpan.style.color = 'var(--text-dim)';
        }
        // Highlight if this is the HL pointer address
        if (byteAddr === this._hlAddr) {
          byteSpan.style.background = 'rgba(255,158,100,0.4)';
          byteSpan.style.outline = '1px solid var(--orange)';
        }
        // Click to edit
        byteSpan.addEventListener('click', (e) => {
          e.stopPropagation();
          this._editMemoryByte(byteSpan);
        });
        hexSpan.appendChild(byteSpan);
        // Spacer
        if (c === 7) {
          hexSpan.appendChild(document.createTextNode(' '));
        }
      }
      // ASCII
      let ascii = '';
      for (let c = 0; c < 16; c++) {
        const bv = this.mmu.peek(base + c);
        ascii += (bv >= 0x20 && bv <= 0x7e) ? String.fromCharCode(bv) : '.';
      }
      const asciiSpan = document.createElement('span');
      asciiSpan.className = 'mem-ascii';
      asciiSpan.textContent = ascii;
      line.innerHTML = `<span class="mem-addr">${addrStr}</span>`;
      line.appendChild(hexSpan);
      line.appendChild(asciiSpan);
      dump.appendChild(line);
    }
    this._memUpdating = false;
  }

  _editMemoryByte(byteSpan) {
    if (byteSpan.classList.contains('editing')) return;
    if (this.editingByte) {
      // Commit any pending edit
      this._commitByteEdit();
    }
    const addr = parseInt(byteSpan.dataset.addr);
    const curVal = parseInt(byteSpan.dataset.val);
    byteSpan.classList.add('editing');
    const inp = document.createElement('input');
    inp.type = 'text';
    inp.className = 'mem-byte-inp';
    inp.value = curVal.toString(16).padStart(2,'0').toUpperCase();
    inp.maxLength = 2;
    byteSpan.textContent = '';
    byteSpan.appendChild(inp);
    inp.focus();
    inp.select();
    this.editingByte = { addr, element: byteSpan, input: inp, original: curVal };
    const finish = (commit) => {
      if (!this.editingByte || this.editingByte.element !== byteSpan) return;
      let newVal = this.editingByte.original;
      if (commit) {
        const raw = inp.value.trim().toLowerCase();
        const parsed = parseInt(raw, 16);
        if (!isNaN(parsed) && parsed >= 0 && parsed <= 0xff) {
          newVal = parsed;
        }
      }
      if (newVal !== this.editingByte.original) {
        this.mmu.poke(addr, newVal);
      }
      // Re-render just this byte
      byteSpan.classList.remove('editing');
      byteSpan.textContent = newVal.toString(16).padStart(2,'0').toUpperCase();
      byteSpan.dataset.val = newVal;
      this.editingByte = null;
      // Update annotations that depend on memory
      this._updateDisasmHighlights();
    };
    inp.addEventListener('blur', () => finish(true));
    inp.addEventListener('keydown', (ev) => {
      if (ev.key === 'Enter') { finish(true); }
      else if (ev.key === 'Escape') { finish(false); }
      else if (ev.key === 'Tab') {
        ev.preventDefault();
        finish(true);
        // Find next byte
        const next = byteSpan.nextElementSibling;
        if (next && next.classList.contains('mem-byte')) {
          this._editMemoryByte(next);
        }
      }
    });
  }
  _commitByteEdit() {
    if (!this.editingByte) return;
    const inp = this.editingByte.input;
    if (inp) inp.blur();
  }
  /* ═══════════════════════════════════════════════════════════════
   * I/O panel
   * ═══════════════════════════════════════════════════════════════ */
  _updateIO() {
    const panel = this.els.ioPanel;
    const pc = this.ppi1.portC;
    const ledOn = (bit) => (pc & (1 << bit)) ? 'led-on' : 'led-off';
    const ls = this.plotter;
    panel.innerHTML = `
      <div class="io-block">
        <div class="io-name">Светодиоды (PIO1.PC2-PC5)</div>
        <div class="led-row">
          <span class="led ${ledOn(2)}" title="Led1 (PC2)"></span>
          <span class="led ${ledOn(3)}" title="Led2 (PC3)"></span>
          <span class="led ${ledOn(4)}" title="Led3 (PC4)"></span>
          <span class="led ${ledOn(5)}" title="Led4 (PC5)"></span>
        </div>
      </div>
      <div class="io-block">
        <div class="io-name">Концевые датчики</div>
        <div class="limit-row">
          <span class="limit ${ls.limitXmin?'limit-on':'limit-off'}">X←</span>
          <span class="limit ${ls.limitXmax?'limit-on':'limit-off'}">X→</span>
          <span class="limit ${ls.limitYmin?'limit-on':'limit-off'}">Y↓</span>
          <span class="limit ${ls.limitYmax?'limit-on':'limit-off'}">Y↑</span>
        </div>
        <div class="io-reg">Поз: <span class="io-reg-val">X=${this.plotter.xPos} Y=${this.plotter.yPos}</span></div>
      </div>
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
        <div class="io-name">USART (с терминалом)</div>
        <div><span class="io-reg">DATA: <span class="io-reg-val">${this.uart.data.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">STATUS: <span class="io-reg-val">${this.uart.status.toString(16).padStart(2,'0').toUpperCase()}</span></span></div>
        <div><span class="io-reg">RX буфер: <span class="io-reg-val">${this.uart.rxBuffer.length} байт</span></span></div>
      </div>
    `;
  }
  _updatePlotterUI() {
    const set = (el, val) => { if (el) el.textContent = val; };
    set(this.els.plotterPos, `X: ${this.plotter.xPos} Y: ${this.plotter.yPos}`);
    const c = PEN_COLORS[this.plotter.penNum] || PEN_COLORS[0];
    set(this.els.plotterPen, `Перо: ${this.plotter.penDown ? '↓' : '↑'} #${this.plotter.penNum + 1}`);
    if (this.els.plotterColor) {
      this.els.plotterColor.innerHTML = `<span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:${c.stroke};margin-right:4px;vertical-align:middle"></span> ${c.name}`;
      this.els.plotterColor.style.color = c.stroke;
    }
    // HPGL progress
    if (this.hpglTotal > 0) {
      set(this.els.hpglProgress, `HPGL: ${this.hpglCurrent}/${this.hpglTotal}`);
      set(this.els.hpglCmd, this.hpglCmdText);
    } else {
      set(this.els.hpglProgress, '');
      set(this.els.hpglCmd, '');
    }
  }
  /* ═══════════════════════════════════════════════════════════════
   * Stack — 50 words (100 bytes), scrollable
   * ═══════════════════════════════════════════════════════════════ */
  _updateStack() {
    const el = this.els.stackDisplay;
    if (!el) return;
    const sp = this.cpu.sp;
    const depth = 50; // 50 words
    let html = '';
    for (let i = 0; i < depth; i++) {
      const addr = (sp + i * 2) & 0xffff;
      const lo = this.mmu.peek(addr);
      const hi = this.mmu.peek(addr + 1);
      const val = (hi << 8) | lo;
      const marker = i === 0 ? '→SP' : '   ';
      const cls = i === 0 ? 'stack-sp' : '';
      html += `<div>
        <span style="color:var(--text-dim);min-width:28px">${marker}</span>
        <span style="color:var(--hl);width:48px">$${addr.toString(16).padStart(4,'0').toUpperCase()}</span>
        <span class="${cls}">$${val.toString(16).padStart(4,'0').toUpperCase()}</span>
      </div>`;
    }
    el.innerHTML = html;
  }
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
  _renderPlotterCanvas(autofit) {
    const canvas = this.els.plotterCanvas;
    const ctx = canvas.getContext('2d');
    const w = canvas.width, h = canvas.height;
    ctx.fillStyle = '#f5f0e8';
    ctx.fillRect(0, 0, w, h);
    // Collect all points for scaling
    const allSegments = [...this.plotter.lines];
    if (this.plotter.currentSegment) allSegments.push(this.plotter.currentSegment);
    if (allSegments.length === 0) {
      // No data yet — show placeholder and cursor if moving
      ctx.fillStyle = '#b8b0a0';
      ctx.textAlign = 'center';
      ctx.font = '14px sans-serif';
      ctx.fillText('Ожидание команд плоттера…', w / 2, h / 2);
      // Draw pen cursor at current position even before any lines
      if (this.plotter.xPos !== 0 || this.plotter.yPos !== 0) {
        const cx = w / 2 + this.plotter.xPos % w;
        const cy = h / 2 - this.plotter.yPos % h;
        const penC = PEN_COLORS[this.plotter.penNum] || PEN_COLORS[0];
        const penSize = 6;
        ctx.globalAlpha = this.plotter.penDown ? 1 : 0.5;
        ctx.fillStyle = penC.stroke;
        ctx.beginPath();
        ctx.moveTo(cx - penSize, cy + penSize);
        ctx.lineTo(cx, cy + penSize * 1.8);
        ctx.lineTo(cx + penSize, cy + penSize);
        ctx.lineTo(cx + penSize * 0.4, cy - penSize * 1.2);
        ctx.lineTo(cx - penSize * 0.4, cy - penSize * 1.2);
        ctx.closePath();
        ctx.fill();
        ctx.globalAlpha = 1;
      }
      return;
    }
    // Scale from all segment bounds
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (const seg of allSegments) {
      if (seg.x1 < minX) minX = seg.x1; if (seg.x1 > maxX) maxX = seg.x1;
      if (seg.x2 < minX) minX = seg.x2; if (seg.x2 > maxX) maxX = seg.x2;
      if (seg.y1 < minY) minY = seg.y1; if (seg.y1 > maxY) maxY = seg.y1;
      if (seg.y2 < minY) minY = seg.y2; if (seg.y2 > maxY) maxY = seg.y2;
    }
    const rangeX = maxX - minX || 1;
    const rangeY = maxY - minY || 1;
    const margin = 30;
    const scale = Math.min((w - 2*margin) / rangeX, (h - 2*margin) / rangeY);
    const sx = (x) => margin + (x - minX) * scale;
    const sy = (y) => h - margin - (y - minY) * scale;
    // Grid
    ctx.strokeStyle = '#d8d0c0';
    ctx.lineWidth = 0.5;
    for (let g = 0; g < 10; g++) {
      const x = margin + (w - 2*margin) * g / 10;
      const y = margin + (h - 2*margin) * g / 10;
      ctx.beginPath(); ctx.moveTo(x, margin); ctx.lineTo(x, h - margin); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(margin, y); ctx.lineTo(w - margin, y); ctx.stroke();
    }
    // Draw finalized lines
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
    // Draw current segment (in progress) — dashed
    if (this.plotter.currentSegment) {
      const c = PEN_COLORS[this.plotter.currentSegment.pen] || PEN_COLORS[0];
      ctx.strokeStyle = c.stroke;
      ctx.lineWidth = 2;
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(sx(this.plotter.currentSegment.x1), sy(this.plotter.currentSegment.y1));
      ctx.lineTo(sx(this.plotter.currentSegment.x2), sy(this.plotter.currentSegment.y2));
      ctx.stroke();
      ctx.setLineDash([]);
    }
    // Current position — draw as pen tip
    const cx = sx(this.plotter.xPos);
    const cy = sy(this.plotter.yPos);
    const penC = PEN_COLORS[this.plotter.penNum] || PEN_COLORS[0];
    const penSize = 7;
    // Pen body (rectangle)
    ctx.fillStyle = penC.stroke;
    ctx.globalAlpha = this.plotter.penDown ? 1 : 0.5;
    ctx.beginPath();
    ctx.moveTo(cx - penSize, cy + penSize);
    ctx.lineTo(cx, cy + penSize * 1.8);
    ctx.lineTo(cx + penSize, cy + penSize);
    ctx.lineTo(cx + penSize * 0.4, cy - penSize * 1.2);
    ctx.lineTo(cx - penSize * 0.4, cy - penSize * 1.2);
    ctx.closePath();
    ctx.fill();
    // Pen tip (colored dot at nib)
    ctx.globalAlpha = 1;
    ctx.beginPath();
    ctx.arc(cx, cy - penSize * 1, 2.5, 0, Math.PI * 2);
    ctx.fillStyle = penC.stroke;
    ctx.fill();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.globalAlpha = 1;
  }


  /* ═══════════════════════════════════════════════════════════════
   * HPGL File Loader
   * ═══════════════════════════════════════════════════════════════ */

  _loadHPGL(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const text = e.target.result;
        const cmds = text.split(';').map(s => s.trim()).filter(s => s.length > 0);
        // Reset plotter
        this.plotter.reset();
        this.plotter.clearLines();
        let penDown = false;
        let penNum = 0;
        let x = 0, y = 0;
        // HPGL units → plotter coordinate scale
        // Find bounds for auto-scaling
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
        const coords = [];
        for (const cmd of cmds) {
          const m = cmd.match(/^([A-Z]{2,3})\s*(.*)$/);
          if (!m) continue;
          const op = m[1];
          const args = m[2].trim();
          if (op === 'PU' || op === 'PD') {
            const nums = args.split(/[\s,]+/).filter(s => s.length > 0).map(Number);
            for (let i = 0; i + 1 < nums.length; i += 2) {
              const cx = nums[i], cy = nums[i+1];
              coords.push({ x: cx, y: cy, cmd: op, pen: penNum });
              if (cx < minX) minX = cx; if (cx > maxX) maxX = cx;
              if (cy < minY) minY = cy; if (cy > maxY) maxY = cy;
            }
          } else if (op === 'SP') {
            penNum = Math.min(6, Math.max(0, parseInt(args) - 1));
          }
          // IN — handled via initial reset above
        }
        const rangeX = maxX - minX || 1;
        const rangeY = maxY - minY || 1;
        const scale = 1000 / Math.max(rangeX, rangeY);
        const ox = 100, oy = 100; // offset to center on plotter
        const hpglAddr = (name) => this.settings.getAddr(name);
        // Init HPGL display state
        this.hpglTotal = coords.length;
        this.hpglCurrent = 0;
        // Check mode
        const uartMode = this.els.hpglUartMode?.checked;
        if (uartMode) {
          // UART mode: send HPGL as raw text to USART, CPU runs firmware
          this._logToUSART(`\n📐 HPGL UART: ${file.name} (${text.length} chars)\n`, 'var(--yellow)');
          // Send HPGL text character by character to USART
          let charIdx = 0;
          const uartInterval = setInterval(() => {
            if (charIdx >= text.length) {
              clearInterval(uartInterval);
              this._logToUSART(`\n✓ HPGL UART done\n`, 'var(--green)');
              if (this.els.hpglStatus) {
                this.els.hpglStatus.textContent = `✓ ${file.name} (UART)`;
                this.els.hpglStatus.style.color = 'var(--green)';
              }
              return;
            }
            const ch = text.charCodeAt(charIdx);
            this.uart.receiveByte(ch);
            charIdx++;
            if (charIdx % 200 === 0) {
              this._updatePlotterUI();
              this._renderPlotterCanvas();
            }
          }, 2);
          return; // skip direct drawing below
        }
        // Animate drawing
        if (this.els.hpglStatus) {
          this.els.hpglStatus.textContent = `▶ ${file.name} (${coords.length} coords)`;
          this.els.hpglStatus.style.color = 'var(--cyan)';
        }
        // Force an initial canvas render to show the cleared state
        this._renderPlotterCanvas();
        console.log('[HPGL] direct draw start — coords=' + coords.length);
        // Show pause button
        if (this.els.hpglPause) {
          this.els.hpglPause.style.display = 'inline-block';
          this.els.hpglPause.textContent = '\u23F8';
        }
        let idx = 0;
        const interval = setInterval(() => {
          try {
            if (idx >= coords.length) {
              clearInterval(interval);
              this._renderPlotterCanvas(true);
              return;
            }
            // Pause check
            if (this._hpglPaused) {
              // Skip rendering, just wait
              return;
            }
            const pt = coords[idx];
            const sx = Math.round(pt.x * scale + ox);
            const sy = Math.round(pt.y * scale + oy);
            this.plotter.xPos = sx;
            this.plotter.yPos = sy;
            this.plotter.x = sx;
            this.plotter.y = sy;
            if (pt.cmd === 'PD') {
              this.plotter.penDown = true;
              if (this.plotter.currentSegment) {
                this.plotter.currentSegment.x2 = sx;
                this.plotter.currentSegment.y2 = sy;
              } else {
                const prev = idx > 0 ? coords[idx-1] : pt;
                const px = Math.round(prev.x * scale + ox);
                const py = Math.round(prev.y * scale + oy);
                this.plotter.currentSegment = { x1: px, y1: py, pen: pt.pen };
                this.plotter.currentSegment.x2 = sx;
                this.plotter.currentSegment.y2 = sy;
              }
            } else {
              this.plotter.penDown = false;
              if (this.plotter.currentSegment) {
                this.plotter.lines.push(this.plotter.currentSegment);
                this.plotter.currentSegment = null;
              }
            }
            this.mmu.poke(hpglAddr('X_POS_LO'), sx & 0xff);
            this.mmu.poke(hpglAddr('X_POS_HI'), (sx >> 8) & 0xff);
            this.mmu.poke(hpglAddr('Y_POS_LO'), sy & 0xff);
            this.mmu.poke(hpglAddr('Y_POS_HI'), (sy >> 8) & 0xff);
            this.mmu.poke(hpglAddr('PEN_STATE'), pt.cmd === 'PD' ? 0x01 : 0x00);
            this.mmu.poke(hpglAddr('PEN_COLOR'), pt.pen);
            if (pt.cmd === 'PD' && this.plotter.currentSegment) {
              const next = coords[idx + 1];
              if (!next || next.cmd === 'PU') {
                this.plotter.lines.push(this.plotter.currentSegment);
                this.plotter.currentSegment = null;
              }
            }
            // Batch renders for performance
            const doRender = (idx % 16 === 0) || (idx === coords.length - 1) || idx < 4;
            if (doRender) {
              this._renderPlotterCanvas();
              this.hpglCurrent = idx + 1;
              const rawCmd = idx < this.hpglCmds.length ? this.hpglCmds[idx] : '';
              this.hpglCmdText = rawCmd;
              this._updatePlotterUI();
            }
            idx++;
          } catch (e) {
            clearInterval(interval);
            if (this.els.hpglStatus) {
              this.els.hpglStatus.textContent = `✕ ${e.message}`;
              this.els.hpglStatus.style.color = 'var(--red)';
            }
            console.error('[AFTOGRAF] HPGL error at idx=' + idx + ':', e);
          }
        }, 5);
      } catch (err) {
        if (this.els.hpglStatus) {
          this.els.hpglStatus.textContent = `✕ ${err.message}`;
          this.els.hpglStatus.style.color = 'var(--red)';
        }
      }
    };
    reader.readAsText(file);
    event.target.value = '';
  }

  _saveSession() {
    const s = this.cpu.getState();
    // Capture RAM content ($6000-$63FF)
    const ram = new Uint8Array(0x0400);
    for (let i = 0; i < 0x0400; i++) ram[i] = this.mmu.peek(0x6000 + i);
    // Capture plotter lines
    const lines = this.plotter.lines.map(l => ({ ...l }));
    const session = {
      version: 1,
      date: new Date().toISOString().replace(/T/, ' ').replace(/\.\d+Z/, ''),
      cpu: {
        a: s.a, b: s.b, c: s.c, d: s.d, e: s.e, h: s.h, l: s.l,
        flags: s.flags, sp: s.sp, pc: s.pc, cycles: s.cycles, halt: s.halt,
      },
      ram: Array.from(ram),
      breakpoints: Array.from(this.breakpoints),
      plotter: {
        xPos: this.plotter.xPos, yPos: this.plotter.yPos,
        penDown: this.plotter.penDown, penNum: this.plotter.penNum,
        lines,
      },
    };
    const json = JSON.stringify(session, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `aftograf-${session.date.replace(/[: ]/g,'-')}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    this._setLoadStatus(`Сессия сохранена: ${a.download}`, 'ok');
  }

  _loadSession(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const session = JSON.parse(e.target.result);
        if (!session || !session.cpu) {
          this._setLoadStatus('✕ Неверный формат сессии', 'error');
          return;
        }
        // Restore CPU
        const c = session.cpu;
        this.cpu.a = c.a; this.cpu.b = c.b; this.cpu.c = c.c;
        this.cpu.d = c.d; this.cpu.e = c.e; this.cpu.h = c.h; this.cpu.l = c.l;
        this.cpu.flags = c.flags; this.cpu.sp = c.sp; this.cpu.pc = c.pc;
        this.cpu.cycles = c.cycles; this.cpu.halt = c.halt;
        this.cpu.ie = false;
        // Restore RAM
        if (session.ram && session.ram.length === 0x0400) {
          for (let i = 0; i < 0x0400; i++) this.mmu.poke(0x6000 + i, session.ram[i]);
        }
        // Restore breakpoints
        this.breakpoints = new Set(session.breakpoints || []);
        // Restore plotter
        if (session.plotter) {
          const p = session.plotter;
          this.plotter.xPos = p.xPos; this.plotter.yPos = p.yPos;
          this.plotter.penDown = p.penDown; this.plotter.penNum = p.penNum;
          this.plotter.lines = (p.lines || []).map(l => ({ ...l }));
          this.plotter.currentSegment = null;
          this.plotter.x = p.xPos; this.plotter.y = p.yPos;
          this.plotter.lastMemPenState = -1;
          this.plotter.lastMemX = -1; this.plotter.lastMemY = -1;
          this.plotter.lastMemColor = -1;
          this.plotter.lastXPhase = 0; this.plotter.lastYPhase = 0;
        }
        this._updateAll();
        this._renderPlotterCanvas();
        this._resetState();
        this._setLoadStatus(`✓ Загружена сессия от ${session.date}`, 'ok');
      } catch (err) {
        this._setLoadStatus(`✕ Ошибка загрузки: ${err.message}`, 'error');
      }
    };
    reader.readAsText(file);
    event.target.value = '';
  }
  /* ═══════════════════════════════════════════════════════════════
   * Theme management
   * ═══════════════════════════════════════════════════════════════ */
  _applyTheme(theme) {
    const root = document.documentElement;
    if (theme === 'light') {
      root.dataset.theme = 'light';
    } else {
      delete root.dataset.theme; // default dark
    }
    // Persist
    if (this.settings) {
      this.settings.config.theme = theme === 'light' ? 'light' : 'dark';
      this.settings.save();
    }
  }
  /* ═══════════════════════════════════════════════════════════════
   * Help overlay
   * ═══════════════════════════════════════════════════════════════ */
  _openHelp() {
    if (document.getElementById('help-overlay')) return;
    const div = document.createElement('div');
    div.id = 'help-overlay';
    div.innerHTML = `
      <div id="help-panel">
        <div id="help-header">
          <h2>Подсказка</h2>
          <button class="help-dismiss" id="help-close">✕ Закрыть</button>
        </div>
        <div id="help-body">
          <section>
            <h3>Клавиатурные сокращения</h3>
            <table>
              <tr><td><kbd>Space</kbd> / <kbd>→</kbd></td><td>Step (шаг)</td></tr>
              <tr><td><kbd>R</kbd></td><td>Reset (сброс CPU)</td></tr>
              <tr><td><kbd>F5</kbd></td><td>Run / Pause (пуск / пауза)</td></tr>
              <tr><td><kbd>B</kbd></td><td>Breakpoint at PC (точка останова)</td></tr>
              <tr><td><kbd>J</kbd></td><td>Jump PC к адресу под курсором</td></tr>
              <tr><td><kbd>?</kbd> / <kbd>/</kbd></td><td>Эта подсказка</td></tr>
              <tr><td><kbd>Esc</kbd></td><td>Закрыть подсказку / настройки</td></tr>
            </table>
          </section>
          <section>
            <h3>Мышь</h3>
            <table>
              <tr><td>Клик по регистру</td><td>Редактировать значение</td></tr>
              <tr><td>Клик по флагу</td><td>Переключить флаг</td></tr>
              <tr><td>Клик по строке дизассемблера</td><td>Toggle breakpoint</td></tr>
              <tr><td>Двойной клик по строке дизассемблера</td><td>Jump PC</td></tr>
              <tr><td>Клик по байту памяти</td><td>Редактировать байт</td></tr>
              <tr><td>Клик по холсту плоттера</td><td>Нет действия (только просмотр)</td></tr>
            </table>
          </section>
          <section>
            <h3>Файлы</h3>
            <table>
              <tr><td>📂 Загрузка ROM</td><td>firmware.bin (24KB) или 3×8KB чипа</td></tr>
              <tr><td>💾 Save Session</td><td>CPU + RAM + breakpoints + plotter</td></tr>
              <tr><td>📂 Load HPGL</td><td>HPGL-файл (прямой рендер или через UART)</td></tr>
            </table>
          </section>
          <section>
            <h3>Советы</h3>
            <table>
              <tr><td>HLT</td><td>CPU остановлен. Нажми R для Reset</td></tr>
              <tr><td>Run без прошивки</td><td>Загрузи firmware.bin через 📂 или настройки</td></tr>
              <tr><td>Скорость</td><td>Slider от ∞ до 1 MHz</td></tr>
            </table>
          </section>
        </div>
      </div>`;
    document.body.appendChild(div);
    // Bind close
    const closeBtn = div.querySelector('#help-close');
    if (closeBtn) closeBtn.addEventListener('click', () => this._closeHelp());
    div.addEventListener('click', (e) => { if (e.target === div) this._closeHelp(); });
    const onKey = (e) => { if (e.key === 'Escape') { this._closeHelp(); } };
    this._helpKeyHandler = onKey;
    document.addEventListener('keydown', onKey);
  }
  _closeHelp() {
    if (this._helpKeyHandler) {
      document.removeEventListener('keydown', this._helpKeyHandler);
      this._helpKeyHandler = null;
    }
    const el = document.getElementById('help-overlay');
    if (el) el.remove();
  }
  }

/* ═══════════════════════════════════════════════════════════════
 * Startup
 * ═══════════════════════════════════════════════════════════════ */
window.addEventListener('error', (e) => {
  console.error('[AFTOGRAF] Error:', e.error || e.message);
});
window.addEventListener('unhandledrejection', (e) => {
  console.error('[AFTOGRAF] Unhandled Promise:', e.reason);
});
console.log('[AFTOGRAF] Starting App...');
const app = new App();
console.log('[AFTOGRAF] App initialized');
// Auto-load ROMs from server if served
async function tryAutoLoadROMs() {
  const urls = ['firmware.bin'];
  for (const url of urls) {
    try {
      const res = await fetch(url);
      if (!res.ok) {
        console.log('[AFTOGRAF] Firmware not found:', url, res.status);
        continue;
      }
      const buf = await res.arrayBuffer();
      const data = new Uint8Array(buf);
      console.log('[AFTOGRAF] Loaded', url, '—', data.length, 'bytes');
      if (data.length === 0x6000) {
        app.mmu.loadROM(data, 0x0000);
        app.romLoaded = true;
        app.cpu = new CPU8080(
          (addr) => app.mmu.readByte(addr),
          (addr, val) => app.mmu.writeByte(addr, val)
        );
        app.breakpoints.clear();
        app._resetState();
        console.log('[AFTOGRAF] ROM[0..7] =',
          Array.from({length:8}, (_,i) => app.mmu.peek(i).toString(16).padStart(2,'0')).join(' '));
        app._rebuildDisasm(0);
        app._updateAll();
        // Log first cache entry
        if (app.disasmCache.length > 0) {
          console.log('[DASM] cache[0] addr=$' + app.disasmCache[0].addr.toString(16) + ' mnem="' + app.disasmCache[0].mnemonic + '"');
        }
        app._setLoadStatus(`Авто-загрузка: firmware.bin (${(data.length/1024).toFixed(0)}KB)`, 'ok');
        return;
      } else {
        console.log('[AFTOGRAF] Unexpected firmware size:', data.length);
      }
    } catch (e) {
      console.log('[AFTOGRAF] Fetch failed:', url, e.message);
    }
  }
  console.log('[AFTOGRAF] No firmware found — waiting for manual load');
}
tryAutoLoadROMs();



