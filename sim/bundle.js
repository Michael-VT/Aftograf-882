// Autograf-882 bundle



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




class MMU {
  constructor(ppi1, ppi2, pit, uart) {
    this.rom = new Uint8Array(0x6000);
    this.ram = new Uint8Array(0x0400); // 1KB КР537РУ10

    // Device references
    this.ppi1 = ppi1;
    this.ppi2 = ppi2;
    this.pit = pit;
    this.uart = uart;
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
    // Writes to ROM are silently ignored
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
    if (this.ie) { /* TODO: handle INTR — check INTE pin */ }

    const opcode = this.fetchByte();
    const op = this.optable[opcode];
    if (!op) {
      // Undocumented opcode — treat as NOP
      return false;
    }

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
        cpu.flags |= FLAG_CY ? 0 : FLAG_CY; // CY=0 after ANA on real 8080? Actually CY=0 always
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
        cpu.pushWord((cpu.pc - addr + 0x10000) > 0xffff ? cpu.pc : cpu.pc); // push return addr
        // Actually push current PC (points past the 3-byte instruction)
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


