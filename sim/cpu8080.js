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

export class CPU8080 {
  constructor(readByte, writeByte, inPort, outPort) {
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
    // I/O port callbacks (separate from memory space)
    this.inPort = inPort || ((port) => this.readByte(0xe000 | port));
    this.outPort = outPort || ((port, val) => this.writeByte(0xe000 | port, val));

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
  def(0xdb, 'IN $02', 10, 2, () => {
    const port = cpu.fetchByte();
    cpu.a = cpu.inPort(port);
    cpu.cycles += 3;
  });
  def(0xd3, 'OUT $02', 10, 2, () => {
    const port = cpu.fetchByte();
    cpu.outPort(port, cpu.a);
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
