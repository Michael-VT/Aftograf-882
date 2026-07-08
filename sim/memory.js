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

export class MMU {
  constructor(ppi1, ppi2, pit, uart) {
    this.rom = new Uint8Array(0x6000);
    this.ram = new Uint8Array(0x0800); // 2KB — firmware tests $6000-$67FF

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
    if (addr < 0x6800) {
      return this.ram[addr & 0x7ff];
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
    if (addr >= 0x6000 && addr < 0x6800) {
      this.ram[addr & 0x7ff] = val;
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
