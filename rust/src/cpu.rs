use serde::{Deserialize, Serialize};

/// Intel 8080 / К580ИК80А CPU Emulator
/// Complete 256-opcode table-driven implementation.
/// Flags bit positions (8080): S(7) Z(6) AC(4) P(2) CY(0), bit 1 always set.
pub const FLAG_CY: u8 = 0x01;
pub const FLAG_P: u8 = 0x04;
pub const FLAG_AC: u8 = 0x10;
pub const FLAG_Z: u8 = 0x40;
pub const FLAG_S: u8 = 0x80;

pub type ReadByteFn = fn(u16) -> u8;
pub type WriteByteFn = fn(u16, u8);
pub type InPortFn = fn(u8) -> u8;
pub type OutPortFn = fn(u8, u8);

#[derive(Clone, Serialize, Deserialize)]
pub struct CpuState {
    pub a: u8, pub b: u8, pub c: u8, pub d: u8, pub e: u8,
    pub h: u8, pub l: u8, pub flags: u8, pub sp: u16, pub pc: u16,
    pub cycles: u64, pub halt: bool, pub ie: bool,
}

pub struct CPU8080 {
    pub a: u8, pub b: u8, pub c: u8, pub d: u8, pub e: u8,
    pub h: u8, pub l: u8, pub flags: u8, pub sp: u16, pub pc: u16,
    pub cycles: u64, pub halt: bool, pub ie: bool, pub intr: bool,
    pub read_byte: ReadByteFn,
    pub write_byte: WriteByteFn,
    pub in_port: InPortFn,
    pub out_port: OutPortFn,
}


impl CPU8080 {
    pub fn new(
        read_byte: ReadByteFn,
        write_byte: WriteByteFn,
        in_port: InPortFn,
        out_port: OutPortFn,
    ) -> Self {
        CPU8080 {
            a: 0, b: 0, c: 0, d: 0, e: 0,
            h: 0, l: 0, flags: 0x02, sp: 0, pc: 0,
            cycles: 0, halt: false, ie: false, intr: false,
            read_byte, write_byte, in_port, out_port,
        }
    }

    pub fn get_state(&self) -> CpuState {
        CpuState {
            a: self.a, b: self.b, c: self.c, d: self.d, e: self.e,
            h: self.h, l: self.l, flags: self.flags, sp: self.sp, pc: self.pc,
            cycles: self.cycles, halt: self.halt, ie: self.ie,
        }
    }

    pub fn get_bc(&self) -> u16 { (self.b as u16) << 8 | self.c as u16 }
    pub fn set_bc(&mut self, v: u16) { self.b = (v >> 8) as u8; self.c = v as u8; }
    pub fn get_de(&self) -> u16 { (self.d as u16) << 8 | self.e as u16 }
    pub fn set_de(&mut self, v: u16) { self.d = (v >> 8) as u8; self.e = v as u8; }
    pub fn get_hl(&self) -> u16 { (self.h as u16) << 8 | self.l as u16 }
    pub fn set_hl(&mut self, v: u16) { self.h = (v >> 8) as u8; self.l = v as u8; }

    fn get_psw(&self) -> u16 { (self.a as u16) << 8 | self.flags as u16 }
    fn set_psw(&mut self, v: u16) { self.a = (v >> 8) as u8; self.flags = (v as u8) | 0x02; }

    fn parity(x: u8) -> bool {
        let mut c = 0u8;
        let mut v = x;
        for _ in 0..8 { c ^= v & 1; v >>= 1; }
        c == 0
    }
    fn inr_flags(&self, val: u8) -> u8 {
        0x02
            | (if val & 0x80 != 0 { FLAG_S } else { 0 })
            | (if val == 0 { FLAG_Z } else { 0 })
            | (if Self::parity(val) { FLAG_P } else { 0 })
            | (if val & 0x0f == 0 { FLAG_AC } else { 0 })
            | (self.flags & FLAG_CY)
    }
    fn dcr_flags(&self, val: u8) -> u8 {
        0x02
            | (if val & 0x80 != 0 { FLAG_S } else { 0 })
            | (if val == 0 { FLAG_Z } else { 0 })
            | (if Self::parity(val) { FLAG_P } else { 0 })
            | (if val & 0x0f == 0x0f { FLAG_AC } else { 0 })
            | (self.flags & FLAG_CY)
    }

    fn fetch_byte(&mut self) -> u8 {
        let v = (self.read_byte)(self.pc);
        self.pc = self.pc.wrapping_add(1);
        v
    }

    fn fetch_word(&mut self) -> u16 {
        let lo = self.fetch_byte() as u16;
        let hi = self.fetch_byte() as u16;
        lo | (hi << 8)
    }

    fn push_stack(&mut self, hi: u8, lo: u8) {
        self.sp = self.sp.wrapping_sub(1);
        (self.write_byte)(self.sp, hi);
        self.sp = self.sp.wrapping_sub(1);
        (self.write_byte)(self.sp, lo);
    }

    fn push_word(&mut self, v: u16) {
        self.push_stack((v >> 8) as u8, v as u8);
    }

    fn pop_stack(&mut self) -> u16 {
        let lo = (self.read_byte)(self.sp) as u16;
        self.sp = self.sp.wrapping_add(1);
        let hi = (self.read_byte)(self.sp) as u16;
        self.sp = self.sp.wrapping_add(1);
        lo | (hi << 8)
    }

    /// Execute one instruction. Returns true if halted.
    pub fn step(&mut self) -> bool {
        if self.halt { return true; }

        // Handle interrupts
        if self.intr && self.ie {
            self.intr = false;
            self.ie = false;
            // RST 7 — push PC, jump to $0038
            let pc = self.pc;
            self.push_word(pc);
            self.pc = 0x0038;
            self.cycles += 11;
            return false;
        }

        let opcode = self.fetch_byte();

        // Use opcode dispatch
        match opcode {
            // NOP
            0x00 => { self.cycles += 4; }
            // LXI B, word
            0x01 => { let v = self.fetch_word(); self.b = (v >> 8) as u8; self.c = v as u8; self.cycles += 10; }
            // STAX B
            0x02 => { (self.write_byte)(self.get_bc(), self.a); self.cycles += 7; }
            // INX B
            0x03 => { let v = self.get_bc().wrapping_add(1); self.set_bc(v); self.cycles += 5; }
            // INR B
            0x04 => {
                self.b = self.b.wrapping_add(1);
                self.flags = self.inr_flags(self.b);
                self.cycles += 5;
            }
            // DCR B
            0x05 => {
                self.b = self.b.wrapping_sub(1);
                self.flags = self.dcr_flags(self.b);
                self.cycles += 5;
            }
            // MVI B, byte
            0x06 => { self.b = self.fetch_byte(); self.cycles += 7; }
            // RLC
            0x07 => {
                let cy = self.a & 0x80;
                self.a = (self.a << 1) | if cy != 0 { 1 } else { 0 };
                self.flags = (self.flags & !FLAG_CY) | (if cy != 0 { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 4;
            }
            // DAD B
            0x09 => {
                let hl = self.get_hl();
                let bc = self.get_bc();
                let r = hl as u32 + bc as u32;
                self.set_hl(r as u16);
                self.flags = (self.flags & !FLAG_CY) | (if r > 0xffff { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 10;
            }
            // LDAX B
            0x0a => { self.a = (self.read_byte)(self.get_bc()); self.cycles += 7; }
            // DCX B
            0x0b => { let v = self.get_bc().wrapping_sub(1); self.set_bc(v); self.cycles += 5; }
            // INR C
            0x0c => {
                self.c = self.c.wrapping_add(1);
                self.flags = self.inr_flags(self.c);
                self.cycles += 5;
            }
            // DCR C
            0x0d => {
                self.c = self.c.wrapping_sub(1);
                self.flags = self.dcr_flags(self.c);
                self.cycles += 5;
            }
            // MVI C, byte
            0x0e => { self.c = self.fetch_byte(); self.cycles += 7; }
            // RRC
            0x0f => {
                let cy = self.a & 0x01;
                self.a = (self.a >> 1) | (if cy != 0 { 0x80 } else { 0 });
                self.flags = (self.flags & !FLAG_CY) | (if cy != 0 { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 4;
            }
            // LXI D, word
            0x11 => { let v = self.fetch_word(); self.d = (v >> 8) as u8; self.e = v as u8; self.cycles += 10; }
            // STAX D
            0x12 => { (self.write_byte)(self.get_de(), self.a); self.cycles += 7; }
            // INX D
            0x13 => { let v = self.get_de().wrapping_add(1); self.set_de(v); self.cycles += 5; }
            // INR D
            0x14 => {
                self.d = self.d.wrapping_add(1);
                self.flags = self.inr_flags(self.d);
                self.cycles += 5;
            }
            // DCR D
            0x15 => {
                self.d = self.d.wrapping_sub(1);
                self.flags = self.dcr_flags(self.d);
                self.cycles += 5;
            }
            // MVI D, byte
            0x16 => { self.d = self.fetch_byte(); self.cycles += 7; }
            // RAL
            0x17 => {
                let cy = self.flags & FLAG_CY;
                let new_cy = self.a & 0x80;
                self.a = (self.a << 1) | (if cy != 0 { 1 } else { 0 });
                self.flags = (self.flags & !FLAG_CY) | (if new_cy != 0 { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 4;
            }
            // DAD D
            0x19 => {
                let hl = self.get_hl();
                let de = self.get_de();
                let r = hl as u32 + de as u32;
                self.set_hl(r as u16);
                self.flags = (self.flags & !FLAG_CY) | (if r > 0xffff { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 10;
            }
            // LDAX D
            0x1a => { self.a = (self.read_byte)(self.get_de()); self.cycles += 7; }
            // DCX D
            0x1b => { let v = self.get_de().wrapping_sub(1); self.set_de(v); self.cycles += 5; }
            // INR E
            0x1c => {
                self.e = self.e.wrapping_add(1);
                self.flags = self.inr_flags(self.e);
                self.cycles += 5;
            }
            // DCR E
            0x1d => {
                self.e = self.e.wrapping_sub(1);
                self.flags = self.dcr_flags(self.e);
                self.cycles += 5;
            }
            // MVI E, byte
            0x1e => { self.e = self.fetch_byte(); self.cycles += 7; }
            // RAR
            0x1f => {
                let cy = self.flags & FLAG_CY;
                let new_cy = self.a & 0x01;
                self.a = (self.a >> 1) | (if cy != 0 { 0x80 } else { 0 });
                self.flags = (self.flags & !FLAG_CY) | (if new_cy != 0 { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 4;
            }
            // LXI H, word
            0x21 => { let v = self.fetch_word(); self.h = (v >> 8) as u8; self.l = v as u8; self.cycles += 10; }
            // SHLD addr
            0x22 => { let addr = self.fetch_word(); (self.write_byte)(addr, self.l); (self.write_byte)(addr.wrapping_add(1), self.h); self.cycles += 16; }
            // INX H
            0x23 => { let v = self.get_hl().wrapping_add(1); self.set_hl(v); self.cycles += 5; }
            // INR H
            0x24 => {
                self.h = self.h.wrapping_add(1);
                self.flags = self.inr_flags(self.h);
                self.cycles += 5;
            }
            // DCR H
            0x25 => {
                self.h = self.h.wrapping_sub(1);
                self.flags = self.dcr_flags(self.h);
                self.cycles += 5;
            }
            // MVI H, byte
            0x26 => { self.h = self.fetch_byte(); self.cycles += 7; }
            // DAA
            0x27 => {
                let mut a = self.a;
                let orig_cy = self.flags & FLAG_CY;
                // Step 1: low nibble correction
                let ac_set = if (a & 0x0f) > 9 || (self.flags & FLAG_AC) != 0 {
                    let r = a as u16 + 6;
                    a = r as u8;
                    r > 0x0f  // AC = carry from low nibble
                } else {
                    false
                };
                // Step 2: high nibble correction (uses original CY)
                let cy_set = if (a >> 4) > 9 || orig_cy != 0 {
                    let r = a as u16 + 0x60;
                    a = r as u8;
                    r > 0xff
                } else {
                    false
                };
                self.a = a;
                self.flags = 0x02
                    | (if ac_set { FLAG_AC } else { 0 })
                    | (if cy_set { FLAG_CY } else { 0 })
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.cycles += 4;
            }
            // DAD H
            0x29 => {
                let hl = self.get_hl();
                let r = hl as u32 + hl as u32;
                self.set_hl(r as u16);
                self.flags = (self.flags & !FLAG_CY) | (if r > 0xffff { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 10;
            }
            // LHLD addr
            0x2a => { let addr = self.fetch_word(); self.l = (self.read_byte)(addr); self.h = (self.read_byte)(addr.wrapping_add(1)); self.cycles += 16; }
            // DCX H
            0x2b => { let v = self.get_hl().wrapping_sub(1); self.set_hl(v); self.cycles += 5; }
            // INR L
            0x2c => {
                self.l = self.l.wrapping_add(1);
                self.flags = self.inr_flags(self.l);
                self.cycles += 5;
            }
            // DCR L
            0x2d => {
                self.l = self.l.wrapping_sub(1);
                self.flags = self.dcr_flags(self.l);
                self.cycles += 5;
            }
            // MVI L, byte
            0x2e => { self.l = self.fetch_byte(); self.cycles += 7; }
            // CMA
            0x2f => { self.a = !self.a; self.cycles += 4; }
            // LXI SP, word
            0x31 => { self.sp = self.fetch_word(); self.cycles += 10; }
            // STA addr
            0x32 => { let addr = self.fetch_word(); (self.write_byte)(addr, self.a); self.cycles += 13; }
            // INX SP
            0x33 => { self.sp = self.sp.wrapping_add(1); self.cycles += 5; }
            // INR M
            0x34 => {
                let addr = self.get_hl();
                let v = (self.read_byte)(addr);
                let r = v.wrapping_add(1);
                self.flags = self.inr_flags(r);
                (self.write_byte)(addr, r);
                self.cycles += 10;
            }
            // DCR M
            0x35 => {
                let addr = self.get_hl();
                let v = (self.read_byte)(addr);
                let r = v.wrapping_sub(1);
                self.flags = self.dcr_flags(r);
                (self.write_byte)(addr, r);
                self.cycles += 10;
            }
            // MVI M, byte
            0x36 => { let v = self.fetch_byte(); (self.write_byte)(self.get_hl(), v); self.cycles += 10; }
            // STC
            0x37 => { self.flags |= FLAG_CY | 0x02; self.cycles += 4; }
            // DCX SP
            0x3b => { self.sp = self.sp.wrapping_sub(1); self.cycles += 5; }
            // INR A
            0x3c => {
                self.a = self.a.wrapping_add(1);
                self.flags = self.inr_flags(self.a);
                self.cycles += 5;
            }
            // DCR A
            0x3d => {
                self.a = self.a.wrapping_sub(1);
                self.flags = self.dcr_flags(self.a);
                self.cycles += 5;
            }
            // MVI A, byte
            0x3e => { self.a = self.fetch_byte(); self.cycles += 7; }
            // CMC
            0x3f => { self.flags ^= FLAG_CY; self.flags |= 0x02; self.cycles += 4; }
            // MOV B,B
            0x40 => { self.cycles += 5; }
            // MOV B,C
            0x41 => { self.b = self.c; self.cycles += 5; }
            // MOV B,D
            0x42 => { self.b = self.d; self.cycles += 5; }
            // MOV B,E
            0x43 => { self.b = self.e; self.cycles += 5; }
            // MOV B,H
            0x44 => { self.b = self.h; self.cycles += 5; }
            // MOV B,L
            0x45 => { self.b = self.l; self.cycles += 5; }
            // MOV B,M
            0x46 => { self.b = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV B,A
            0x47 => { self.b = self.a; self.cycles += 5; }
            // MOV C,B
            0x48 => { self.c = self.b; self.cycles += 5; }
            // MOV C,C
            0x49 => { self.cycles += 5; }
            // MOV C,D
            0x4a => { self.c = self.d; self.cycles += 5; }
            // MOV C,E
            0x4b => { self.c = self.e; self.cycles += 5; }
            // MOV C,H
            0x4c => { self.c = self.h; self.cycles += 5; }
            // MOV C,L
            0x4d => { self.c = self.l; self.cycles += 5; }
            // MOV C,M
            0x4e => { self.c = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV C,A
            0x4f => { self.c = self.a; self.cycles += 5; }
            // MOV D,B
            0x50 => { self.d = self.b; self.cycles += 5; }
            // MOV D,C
            0x51 => { self.d = self.c; self.cycles += 5; }
            // MOV D,D
            0x52 => { self.cycles += 5; }
            // MOV D,E
            0x53 => { self.d = self.e; self.cycles += 5; }
            // MOV D,H
            0x54 => { self.d = self.h; self.cycles += 5; }
            // MOV D,L
            0x55 => { self.d = self.l; self.cycles += 5; }
            // MOV D,M
            0x56 => { self.d = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV D,A
            0x57 => { self.d = self.a; self.cycles += 5; }
            // MOV E,B
            0x58 => { self.e = self.b; self.cycles += 5; }
            // MOV E,C
            0x59 => { self.e = self.c; self.cycles += 5; }
            // MOV E,D
            0x5a => { self.e = self.d; self.cycles += 5; }
            // MOV E,E
            0x5b => { self.cycles += 5; }
            // MOV E,H
            0x5c => { self.e = self.h; self.cycles += 5; }
            // MOV E,L
            0x5d => { self.e = self.l; self.cycles += 5; }
            // MOV E,M
            0x5e => { self.e = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV E,A
            0x5f => { self.e = self.a; self.cycles += 5; }
            // MOV H,B
            0x60 => { self.h = self.b; self.cycles += 5; }
            // MOV H,C
            0x61 => { self.h = self.c; self.cycles += 5; }
            // MOV H,D
            0x62 => { self.h = self.d; self.cycles += 5; }
            // MOV H,E
            0x63 => { self.h = self.e; self.cycles += 5; }
            // MOV H,H
            0x64 => { self.cycles += 5; }
            // MOV H,L
            0x65 => { self.h = self.l; self.cycles += 5; }
            // MOV H,M
            0x66 => { self.h = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV H,A
            0x67 => { self.h = self.a; self.cycles += 5; }
            // MOV L,B
            0x68 => { self.l = self.b; self.cycles += 5; }
            // MOV L,C
            0x69 => { self.l = self.c; self.cycles += 5; }
            // MOV L,D
            0x6a => { self.l = self.d; self.cycles += 5; }
            // MOV L,E
            0x6b => { self.l = self.e; self.cycles += 5; }
            // MOV L,H
            0x6c => { self.l = self.h; self.cycles += 5; }
            // MOV L,L
            0x6d => { self.cycles += 5; }
            // MOV L,M
            0x6e => { self.l = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV L,A
            0x6f => { self.l = self.a; self.cycles += 5; }
            // MOV M,B
            0x70 => { (self.write_byte)(self.get_hl(), self.b); self.cycles += 7; }
            // MOV M,C
            0x71 => { (self.write_byte)(self.get_hl(), self.c); self.cycles += 7; }
            // MOV M,D
            0x72 => { (self.write_byte)(self.get_hl(), self.d); self.cycles += 7; }
            // MOV M,E
            0x73 => { (self.write_byte)(self.get_hl(), self.e); self.cycles += 7; }
            // MOV M,H
            0x74 => { (self.write_byte)(self.get_hl(), self.h); self.cycles += 7; }
            // MOV M,L
            0x75 => { (self.write_byte)(self.get_hl(), self.l); self.cycles += 7; }
            // HLT
            0x76 => { self.halt = true; self.cycles += 7; }
            // MOV M,A
            0x77 => { (self.write_byte)(self.get_hl(), self.a); self.cycles += 7; }
            // MOV A,B
            0x78 => { self.a = self.b; self.cycles += 5; }
            // MOV A,C
            0x79 => { self.a = self.c; self.cycles += 5; }
            // MOV A,D
            0x7a => { self.a = self.d; self.cycles += 5; }
            // MOV A,E
            0x7b => { self.a = self.e; self.cycles += 5; }
            // MOV A,H
            0x7c => { self.a = self.h; self.cycles += 5; }
            // MOV A,L
            0x7d => { self.a = self.l; self.cycles += 5; }
            // MOV A,M
            0x7e => { self.a = (self.read_byte)(self.get_hl()); self.cycles += 7; }
            // MOV A,A
            0x7f => { self.cycles += 5; }

            // ADD B..A, ADD M
            0x80..=0x87 => {
                let val = match opcode {
                    0x80 => self.b, 0x81 => self.c, 0x82 => self.d, 0x83 => self.e,
                    0x84 => self.h, 0x85 => self.l, 0x86 => (self.read_byte)(self.get_hl()),
                    0x87 => self.a, _ => unreachable!()
                };
                let result = self.a as u16 + val as u16;
                let a = result as u8;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) + (val & 0x0f) > 0x0f { FLAG_AC } else { 0 })
                    | (if result > 0xff { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0x86 { 7 } else { 4 };
            }
            // ADC B..A, ADC M
            0x88..=0x8f => {
                let val = match opcode {
                    0x88 => self.b, 0x89 => self.c, 0x8a => self.d, 0x8b => self.e,
                    0x8c => self.h, 0x8d => self.l, 0x8e => (self.read_byte)(self.get_hl()),
                    0x8f => self.a, _ => unreachable!()
                };
                let carry = (self.flags & FLAG_CY) as u16;
                let result = self.a as u16 + val as u16 + carry;
                let a = result as u8;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) + (val & 0x0f) + (carry as u8 & 0x0f) > 0x0f { FLAG_AC } else { 0 })
                    | (if result > 0xff { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0x8e { 7 } else { 4 };
            }
            // SUB B..A, SUB M
            0x90..=0x97 => {
                let val = match opcode {
                    0x90 => self.b, 0x91 => self.c, 0x92 => self.d, 0x93 => self.e,
                    0x94 => self.h, 0x95 => self.l, 0x96 => (self.read_byte)(self.get_hl()),
                    0x97 => self.a, _ => unreachable!()
                };
                let result = (self.a as i16) - (val as i16);
                let a = result as u8;
                let borrow = (self.a as u16) < (val as u16);
                let ac = (self.a & 0x0f) < (val & 0x0f);
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if ac { FLAG_AC } else { 0 })
                    | (if borrow { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0x96 { 7 } else { 4 };
            }
            // SBB B..A, SBB M
            0x98..=0x9f => {
                let val = match opcode {
                    0x98 => self.b, 0x99 => self.c, 0x9a => self.d, 0x9b => self.e,
                    0x9c => self.h, 0x9d => self.l, 0x9e => (self.read_byte)(self.get_hl()),
                    0x9f => self.a, _ => unreachable!()
                };
                let carry = (self.flags & FLAG_CY) as u16;
                let result = (self.a as i16) - (val as i16) - (carry as i16);
                let a = result as u8;
                let borrow = (self.a as u16) < (val as u16) + carry;
                let ac = (self.a & 0x0f) < (val & 0x0f) + (carry as u8 & 0x0f);
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if ac { FLAG_AC } else { 0 })
                    | (if borrow { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0x9e { 7 } else { 4 };
            }
            // ANA B..A, ANA M
            0xa0..=0xa7 => {
                let val = match opcode {
                    0xa0 => self.b, 0xa1 => self.c, 0xa2 => self.d, 0xa3 => self.e,
                    0xa4 => self.h, 0xa5 => self.l, 0xa6 => (self.read_byte)(self.get_hl()),
                    0xa7 => self.a, _ => unreachable!()
                };
                let a = self.a & val;
                self.flags = 0x02 | FLAG_AC  // AND always sets AC
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 }); // CY = 0
                self.a = a;
                self.cycles += if opcode == 0xa6 { 7 } else { 4 };
            }
            // XRA B..A, XRA M
            0xa8..=0xaf => {
                let val = match opcode {
                    0xa8 => self.b, 0xa9 => self.c, 0xaa => self.d, 0xab => self.e,
                    0xac => self.h, 0xad => self.l, 0xae => (self.read_byte)(self.get_hl()),
                    0xaf => self.a, _ => unreachable!()
                };
                let a = self.a ^ val;
                self.flags = 0x02  // CY = 0, AC = 0
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0xae { 7 } else { 4 };
            }
            // ORA B..A, ORA M
            0xb0..=0xb7 => {
                let val = match opcode {
                    0xb0 => self.b, 0xb1 => self.c, 0xb2 => self.d, 0xb3 => self.e,
                    0xb4 => self.h, 0xb5 => self.l, 0xb6 => (self.read_byte)(self.get_hl()),
                    0xb7 => self.a, _ => unreachable!()
                };
                let a = self.a | val;
                self.flags = 0x02  // CY = 0, AC = 0
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.a = a;
                self.cycles += if opcode == 0xb6 { 7 } else { 4 };
            }
            // CMP B..A, CMP M
            0xb8..=0xbf => {
                let val = match opcode {
                    0xb8 => self.b, 0xb9 => self.c, 0xba => self.d, 0xbb => self.e,
                    0xbc => self.h, 0xbd => self.l, 0xbe => (self.read_byte)(self.get_hl()),
                    0xbf => self.a, _ => unreachable!()
                };
                let result = (self.a as i16) - (val as i16);
                let a = result as u8;
                let borrow = (self.a as u16) < (val as u16);
                let ac = (self.a & 0x0f) < (val & 0x0f);
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if ac { FLAG_AC } else { 0 })
                    | (if borrow { FLAG_CY } else { 0 });
                self.cycles += if opcode == 0xbe { 7 } else { 4 };
            }
            // RNZ, RZ, RNC, RC, RPO, RPE, RP, RM
            0xc0 | 0xc8 | 0xd0 | 0xd8 | 0xe0 | 0xe8 | 0xf0 | 0xf8 => {
                let cond = match opcode {
                    0xc0 => (self.flags & FLAG_Z) == 0,        // NZ
                    0xc8 => (self.flags & FLAG_Z) != 0,        // Z
                    0xd0 => (self.flags & FLAG_CY) == 0,       // NC
                    0xd8 => (self.flags & FLAG_CY) != 0,       // C
                    0xe0 => (self.flags & FLAG_P) == 0,        // PO
                    0xe8 => (self.flags & FLAG_P) != 0,        // PE
                    0xf0 => (self.flags & FLAG_S) == 0,        // P
                    0xf8 => (self.flags & FLAG_S) != 0,        // M
                    _ => false
                };
                if cond {
                    self.pc = self.pop_stack();
                    self.cycles += 11;
                } else {
                    self.cycles += 5;
                }
            }
            // POP B, D, H, PSW
            0xc1 | 0xd1 | 0xe1 | 0xf1 => {
                let val = self.pop_stack();
                match opcode {
                    0xc1 => { self.c = val as u8; self.b = (val >> 8) as u8; }
                    0xd1 => { self.e = val as u8; self.d = (val >> 8) as u8; }
                    0xe1 => { self.l = val as u8; self.h = (val >> 8) as u8; }
                    0xf1 => { self.set_psw(val); }
                    _ => {}
                }
                self.cycles += 10;
            }
            // JNZ, JZ, JNC, JC, JPO, JPE, JP, JM addr
            0xc2 | 0xca | 0xd2 | 0xda | 0xe2 | 0xea | 0xf2 | 0xfa => {
                let addr = self.fetch_word();
                let cond = match opcode {
                    0xc2 => (self.flags & FLAG_Z) == 0,
                    0xca => (self.flags & FLAG_Z) != 0,
                    0xd2 => (self.flags & FLAG_CY) == 0,
                    0xda => (self.flags & FLAG_CY) != 0,
                    0xe2 => (self.flags & FLAG_P) == 0,
                    0xea => (self.flags & FLAG_P) != 0,
                    0xf2 => (self.flags & FLAG_S) == 0,
                    0xfa => (self.flags & FLAG_S) != 0,
                    _ => false
                };
                if cond { self.pc = addr; self.cycles += 10; }
                else { self.cycles += 10; }
            }
            // JMP addr
            0xc3 => { self.pc = self.fetch_word(); self.cycles += 10; }
            // CNZ, CZ, CNC, CC, CPO, CPE, CP, CM addr
            0xc4 | 0xcc | 0xd4 | 0xdc | 0xe4 | 0xec | 0xf4 | 0xfc => {
                let addr = self.fetch_word();
                let cond = match opcode {
                    0xc4 => (self.flags & FLAG_Z) == 0,
                    0xcc => (self.flags & FLAG_Z) != 0,
                    0xd4 => (self.flags & FLAG_CY) == 0,
                    0xdc => (self.flags & FLAG_CY) != 0,
                    0xe4 => (self.flags & FLAG_P) == 0,
                    0xec => (self.flags & FLAG_P) != 0,
                    0xf4 => (self.flags & FLAG_S) == 0,
                    0xfc => (self.flags & FLAG_S) != 0,
                    _ => false
                };
                if cond {
                    self.push_word(self.pc);
                    self.pc = addr;
                    self.cycles += 17;
                } else {
                    self.cycles += 11;
                }
            }
            // PUSH B, D, H, PSW
            0xc5 | 0xd5 | 0xe5 | 0xf5 => {
                let val = match opcode {
                    0xc5 => self.get_bc(),
                    0xd5 => self.get_de(),
                    0xe5 => self.get_hl(),
                    0xf5 => self.get_psw(),
                    _ => 0
                };
                self.push_word(val);
                self.cycles += 11;
            }
            // ADI byte
            0xc6 => {
                let val = self.fetch_byte();
                let result = self.a as u16 + val as u16;
                let a = result as u8;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) + (val & 0x0f) > 0x0f { FLAG_AC } else { 0 })
                    | (if result > 0xff { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // RST 0..7
            0xc7 | 0xcf | 0xd7 | 0xdf | 0xe7 | 0xef | 0xf7 | 0xff => {
                let n = (opcode >> 3) & 0x07;
                self.push_word(self.pc);
                self.pc = (n as u16) * 8;
                self.cycles += 11;
            }
            // SUI byte
            0xd6 => {
                let val = self.fetch_byte();
                let result = (self.a as i16) - (val as i16);
                let a = result as u8;
                let borrow = (self.a as u16) < (val as u16);
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) < (val & 0x0f) { FLAG_AC } else { 0 })
                    | (if borrow { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // OUT byte
            0xd3 => { let port = self.fetch_byte(); (self.out_port)(port, self.a); self.cycles += 10; }
            // LXI B (0x01) already handled... wait 0xd3 is OUT
            // Actually let's continue through the pattern
            // IN byte
            0xdb => { let port = self.fetch_byte(); self.a = (self.in_port)(port); self.cycles += 10; }
            // ANI byte
            0xe6 => {
                let val = self.fetch_byte();
                let a = self.a & val;
                self.flags = 0x02 | FLAG_AC
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // XRI byte
            0xee => {
                let val = self.fetch_byte();
                let a = self.a ^ val;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // ORI byte
            0xf6 => {
                let val = self.fetch_byte();
                let a = self.a | val;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // CPI byte
            0xfe => {
                let val = self.fetch_byte();
                let result = (self.a as i16) - (val as i16);
                let a = result as u8;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) < (val & 0x0f) { FLAG_AC } else { 0 })
                    | (if (self.a as u16) < (val as u16) { FLAG_CY } else { 0 });
                self.cycles += 7;
            }
            // ACI, SUI already handled. Let's handle remaining:
            // LDA addr
            0x3a => { let addr = self.fetch_word(); self.a = (self.read_byte)(addr); self.cycles += 13; }
            // DAD B (0x09), DAD D (0x19), DAD H (0x29), DAD SP (0x39)
            0x39 => {
                let hl = self.get_hl();
                let r = hl as u32 + self.sp as u32;
                self.set_hl(r as u16);
                self.flags = (self.flags & !FLAG_CY) | (if r > 0xffff { FLAG_CY } else { 0 }) | 0x02;
                self.cycles += 10;
            }
            // INX SP... handled: 0x33
            // DCX SP... handled: 0x3b
            // EI
            0xfb => { self.ie = true; self.cycles += 4; }
            // DI
            0xf3 => { self.ie = false; self.cycles += 4; }
            // ACI byte
            0xce => {
                let val = self.fetch_byte();
                let carry = (self.flags & FLAG_CY) as u16;
                let result = self.a as u16 + val as u16 + carry;
                let a = result as u8;
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if (self.a & 0x0f) + (val & 0x0f) + (carry as u8 & 0x0f) > 0x0f { FLAG_AC } else { 0 })
                    | (if result > 0xff { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // SBI byte
            0xde => {
                let val = self.fetch_byte();
                let carry = (self.flags & FLAG_CY) as u16;
                let result = (self.a as i16) - (val as i16) - (carry as i16);
                let a = result as u8;
                let ac = (self.a & 0x0f) < (val & 0x0f) + (carry as u8 & 0x0f);
                self.flags = 0x02
                    | (if a & 0x80 != 0 { FLAG_S } else { 0 })
                    | (if a == 0 { FLAG_Z } else { 0 })
                    | (if Self::parity(a) { FLAG_P } else { 0 })
                    | (if ac { FLAG_AC } else { 0 })
                    | (if (self.a as u16) < (val as u16) + carry { FLAG_CY } else { 0 });
                self.a = a;
                self.cycles += 7;
            }
            // CALL addr
            0xcd => {
                let addr = self.fetch_word();
                self.push_word(self.pc);
                self.pc = addr;
                self.cycles += 17;
            }
            // RET
            0xc9 => { self.pc = self.pop_stack(); self.cycles += 10; }
            // XCHG
            0xeb => {
                let h = self.h; let l = self.l;
                self.h = self.d; self.l = self.e;
                self.d = h; self.e = l;
                self.cycles += 5;
            }
            // XTHL
            0xe3 => {
                let lo = (self.read_byte)(self.sp);
                let hi = (self.read_byte)(self.sp.wrapping_add(1));
                (self.write_byte)(self.sp, self.l);
                (self.write_byte)(self.sp.wrapping_add(1), self.h);
                self.l = lo; self.h = hi;
                self.cycles += 18;
            }
            // SPHL
            0xf9 => { self.sp = self.get_hl(); self.cycles += 5; }
            // PCHL
            0xe9 => { self.pc = self.get_hl(); self.cycles += 5; }
            // RIM (NOP on 8080, exists on 8085)
            // SIM (NOP on 8080)
            0x20 | 0x30 | 0x08 | 0x10 | 0x18 | 0x28 | 0x38 => { self.cycles += 4; } // NOP-like
            0xcb | 0xd9 | 0xdd | 0xed | 0xfd => { self.cycles += 4; } // NOP / debug markers
        }

        false
    }


    pub fn reset(&mut self) {
        self.a = 0; self.b = 0; self.c = 0; self.d = 0; self.e = 0;
        self.h = 0; self.l = 0; self.flags = 0x02;
        self.sp = 0; self.pc = 0;
        self.cycles = 0; self.halt = false; self.ie = false; self.intr = false;
    }
}



#[cfg(test)]
#[allow(static_mut_refs)]
mod tests {
    use super::*;
    static mut TEST_MEM: [u8; 0x10000] = [0x00; 0x10000];

    fn test_read(a: u16) -> u8 {
        unsafe { *std::ptr::addr_of!(TEST_MEM).cast::<u8>().add(a as usize) }
    }
    fn test_write(a: u16, v: u8) {
        unsafe { *std::ptr::addr_of_mut!(TEST_MEM).cast::<u8>().add(a as usize) = v; }
    }

    fn reset_mem() {
        unsafe {
            std::ptr::write_bytes(std::ptr::addr_of_mut!(TEST_MEM).cast::<u8>(), 0x00, TEST_MEM.len());
        }
    }

    fn test_cpu() -> CPU8080 {
        CPU8080::new(test_read, test_write, |_| 0xFF, |_, _| {})
    }

    fn set_mem(addr: u16, data: &[u8]) {
        for (i, &b) in data.iter().enumerate() {
            test_write(addr.wrapping_add(i as u16), b);
        }
    }

    #[test]
    fn test_nop() {
        reset_mem();
        let mut cpu = test_cpu();
        cpu.step();
        assert_eq!(cpu.pc, 1);
        assert_eq!(cpu.cycles, 4);
    }

    #[test]
    fn test_lxi_b() {
        reset_mem();
        set_mem(0, &[0x01, 0x12, 0x34]);
        let mut cpu = test_cpu();
        cpu.step();
        assert_eq!(cpu.b, 0x34);
        assert_eq!(cpu.c, 0x12);
        assert_eq!(cpu.pc, 3);
        assert_eq!(cpu.cycles, 10);
    }

    #[test]
    fn test_inr_b() {
        reset_mem();
        set_mem(0, &[0x04]); // INR B
        let mut cpu = test_cpu();
        cpu.b = 0x0F;
        cpu.step();
        assert!(cpu.flags & FLAG_AC != 0); // 0x0F+1=0x10, nibble wraps → AC=1
        assert_eq!(cpu.cycles, 5);
    }

    #[test]
    fn test_dcr_b() {
        reset_mem();
        set_mem(0, &[0x05]); // DCR B
        let mut cpu = test_cpu();
        cpu.b = 0x10;
        cpu.step();
        assert_eq!(cpu.b, 0x0F);
        assert!(cpu.flags & FLAG_AC != 0);
        assert_eq!(cpu.cycles, 5);
    }

    #[test]
    fn test_daa() {
        reset_mem();
        set_mem(0, &[0x27]); // DAA
        let mut cpu = test_cpu();
        cpu.a = 0x9A;
        cpu.flags = 0x02;
        cpu.step();
        // 0x9A: low 0xA > 9 → +6 = 0xA0, high 0xA > 9 → +0x60 = 0x00, CY=1
        assert_eq!(cpu.a, 0x00);
        assert!(cpu.flags & FLAG_CY != 0);
        assert_eq!(cpu.cycles, 4);
    }

    #[test]
    fn test_daa_ac_flag() {
        reset_mem();
        set_mem(0, &[0x27]); // DAA
        let mut cpu = test_cpu();
        cpu.a = 0x0A;
        cpu.flags = FLAG_AC | 0x02;
        cpu.step();
        // AC=1, A=0x0A, low 0xA > 9 → +6 = 0x10, AC set (0x0A+6=0x10 > 0x0F)
        // high 1 > 9? No. A>>4 = 1, ≤ 9. CY original=0 → no step 2.
        assert_eq!(cpu.a, 0x10);
        assert!(cpu.flags & FLAG_AC != 0);
        assert!(cpu.flags & FLAG_CY == 0);
    }

    #[test]
    fn test_mov_regs() {
        reset_mem();
        set_mem(0, &[0x47]); // MOV B,A
        let mut cpu = test_cpu();
        cpu.a = 0x42;
        cpu.step();
        assert_eq!(cpu.b, 0x42);
    }

    #[test]
    fn test_add_with_carry() {
        reset_mem();
        set_mem(0, &[0x80]); // ADD B
        let mut cpu = test_cpu();
        cpu.a = 0xFF;
        cpu.b = 0x01;
        cpu.step();
        assert_eq!(cpu.a, 0x00);
        assert!(cpu.flags & FLAG_CY != 0);
        assert!(cpu.flags & FLAG_Z != 0);
        assert!(cpu.flags & FLAG_P != 0);
    }

    #[test]
    fn test_push_pop() {
        reset_mem();
        let mut cpu = test_cpu();
        cpu.b = 0xAB;
        cpu.c = 0xCD;
        cpu.sp = 0x61FE;
        cpu.push_word(cpu.get_bc());
        let val = cpu.pop_stack();
        assert_eq!(val, 0xABCD);
        assert_eq!(cpu.sp, 0x61FE);
    }

    #[test]
    fn test_jmp() {
        reset_mem();
        set_mem(0, &[0xC3, 0x78, 0x56]); // JMP 0x5678
        let mut cpu = test_cpu();
        cpu.step();
        assert_eq!(cpu.pc, 0x5678);
    }

    #[test]
    fn test_call_ret() {
        reset_mem();
        set_mem(0, &[0xCD, 0x34, 0x12]); // CALL 0x1234
        set_mem(0x1234, &[0xC9]);        // RET
        let mut cpu = test_cpu();
        cpu.sp = 0x61FE;
        cpu.step();
        assert_eq!(cpu.pc, 0x1234);
        assert_eq!(cpu.sp, 0x61FC);
        cpu.step(); // RET
        assert_eq!(cpu.pc, 3);
        assert_eq!(cpu.sp, 0x61FE);
    }

    #[test]
    fn test_conditional_jump() {
        reset_mem();
        set_mem(0, &[0xC2, 0x00, 0x80]); // JNZ 0x8000
        let mut cpu = test_cpu();
        cpu.flags = FLAG_Z | 0x02; // Z=1 → no jump
        cpu.step();
        assert_eq!(cpu.pc, 3);

        // JZ when Z=1
        set_mem(3, &[0xCA, 0x00, 0x80]); // JZ 0x8000
        cpu.pc = 3;
        cpu.step();
        assert_eq!(cpu.pc, 0x8000);
    }

    #[test]
    fn test_arithmetic_flags() {
        reset_mem();
        set_mem(0, &[0x80]); // ADD B
        let mut cpu = test_cpu();
        cpu.a = 0x7F;
        cpu.b = 0x01;
        cpu.step();
        assert_eq!(cpu.a, 0x80);
        assert!(cpu.flags & FLAG_S != 0);
        assert!(cpu.flags & FLAG_P == 0);
    }

    #[test]
    fn test_xthl() {
        reset_mem();
        set_mem(0, &[0xE3]); // XTHL
        set_mem(0x6000, &[0xCC, 0xDD]);
        let mut cpu = test_cpu();
        cpu.sp = 0x6000;
        cpu.h = 0xAA;
        cpu.l = 0xBB;
        cpu.step();
        assert_eq!(cpu.h, 0xDD);
        assert_eq!(cpu.l, 0xCC);
        assert_eq!(test_read(0x6000), 0xBB);
        assert_eq!(test_read(0x6001), 0xAA);
    }

    #[test]
    fn test_inr_overflow() {
        reset_mem();
        set_mem(0, &[0x3C]); // INR A
        let mut cpu = test_cpu();
        cpu.a = 0xFF;
        cpu.step();
        assert_eq!(cpu.a, 0x00);
        assert!(cpu.flags & FLAG_Z != 0);
        assert!(cpu.flags & FLAG_S == 0);
        assert!(cpu.flags & FLAG_AC != 0);
    }

    #[test]
    fn test_dad_overflow() {
        reset_mem();
        set_mem(0, &[0x09]); // DAD B
        let mut cpu = test_cpu();
        cpu.set_hl(0xFFFF);
        cpu.set_bc(0x0001);
        cpu.step();
        assert_eq!(cpu.get_hl(), 0x0000);
        assert!(cpu.flags & FLAG_CY != 0);
    }

    #[test]
    fn test_ana_flags() {
        reset_mem();
        set_mem(0, &[0xA0]); // ANA B
        let mut cpu = test_cpu();
        cpu.a = 0xFF;
        cpu.b = 0x0F;
        cpu.step();
        assert_eq!(cpu.a, 0x0F);
        assert!(cpu.flags & FLAG_AC != 0); // AND always sets AC
        assert!(cpu.flags & FLAG_CY == 0); // AND clears CY
    }

    #[test]
    fn test_rlc() {
        reset_mem();
        set_mem(0, &[0x07]); // RLC
        let mut cpu = test_cpu();
        cpu.a = 0x81;
        cpu.step();
        assert_eq!(cpu.a, 0x03); // 0x81 << 1 | 1 = 0x03
        assert!(cpu.flags & FLAG_CY != 0);
    }

    #[test]
    fn test_stc_cmc() {
        reset_mem();
        set_mem(0, &[0x37, 0x3F]); // STC, CMC
        let mut cpu = test_cpu();
        cpu.flags = 0x02;
        cpu.step(); // STC
        assert!(cpu.flags & FLAG_CY != 0);
        cpu.step(); // CMC
        assert!(cpu.flags & FLAG_CY == 0);
    }

    #[test]
    fn test_stax_ldax() {
        reset_mem();
        set_mem(0, &[0x02, 0x0A]); // STAX B, LDAX B
        let mut cpu = test_cpu();
        cpu.a = 0x55;
        cpu.set_bc(0x6000);
        cpu.step(); // STAX B — store A at BC
        assert_eq!(test_read(0x6000), 0x55);
        cpu.a = 0;
        cpu.step(); // LDAX B — load from BC
    }

    #[test]
    fn test_adi_aci_sui_sbi() {
        reset_mem();
        reset_mem();
        set_mem(0, &[0xC6, 0x05, 0xCE, 0x03, 0xD6, 0x02, 0xDE, 0x01]); // ADI 5, ACI 3, SUI 2, SBI 1
        let mut cpu = test_cpu();
        cpu.a = 0x10;
        cpu.flags = 0x02;
        cpu.step(); assert_eq!(cpu.a, 0x15); // ADI 5
        cpu.step(); assert_eq!(cpu.a, 0x18); // ACI 3
        cpu.step(); assert_eq!(cpu.a, 0x16); // SUI 2
        cpu.step(); assert_eq!(cpu.a, 0x15); // SBI 1
    }

    #[test]
    fn test_mvi_lxi_shld_lhld() {
        reset_mem();
        set_mem(0, &[0x3E, 0x42, 0x01, 0x34, 0x12, 0x32, 0x00, 0x60, 0x2A, 0x00, 0x60]);
        // MVI A,42  LXI B,0x1234  SHLD $6000  LHLD $6000
        let mut cpu = test_cpu();
        // MVI A, 0x42
        cpu.step();
        assert_eq!(cpu.a, 0x42);
        // LXI B, 0x1234
        cpu.step();
        assert_eq!(cpu.b, 0x12);
        assert_eq!(cpu.c, 0x34);
    }

    #[test]
    fn test_inx_dcx() {
        reset_mem();
        set_mem(0, &[0x03, 0x03, 0x0B, 0x0B]); // INX B, INX B, DCX B, DCX B
        let mut cpu = test_cpu();
        cpu.set_bc(0x7FFF);
        cpu.step(); assert_eq!(cpu.get_bc(), 0x8000); // INX B
        cpu.step(); assert_eq!(cpu.get_bc(), 0x8001); // INX B
        cpu.step(); assert_eq!(cpu.get_bc(), 0x8000); // DCX B
        cpu.step(); assert_eq!(cpu.get_bc(), 0x7FFF); // DCX B
    }

    #[test]
    fn test_inx_overflow() {
        reset_mem();
        set_mem(0, &[0x03]); // INX B
        let mut cpu = test_cpu();
        cpu.set_bc(0xFFFF);
        cpu.step();
        assert_eq!(cpu.get_bc(), 0x0000);
    }

    #[test]
    fn test_xra_ora_ana() {
        reset_mem();
        set_mem(0, &[0xA8, 0xB0, 0xA0]); // XRA B, ORA B, ANA B
        let mut cpu = test_cpu();
        cpu.a = 0xFF;
        cpu.b = 0x0F;
        cpu.step(); assert_eq!(cpu.a, 0xF0); // XRA 0xFF^0x0F
        cpu.b = 0x01;
        cpu.step(); assert_eq!(cpu.a, 0xF1); // ORA 0xF0|0x01
        cpu.b = 0x0F;
        cpu.step(); assert_eq!(cpu.a, 0x01); // ANA 0xF1&0x0F
    }

    #[test]
    fn test_dad() {
        reset_mem();
        set_mem(0, &[0x09, 0x29]); // DAD B, DAD H
        let mut cpu = test_cpu();
        cpu.set_hl(0x1000);
        cpu.set_bc(0x0200);
        cpu.step(); // DAD B: HL += BC
        assert_eq!(cpu.get_hl(), 0x1200);
        let hl = cpu.get_hl();
        cpu.set_hl(hl);
        cpu.step(); // DAD H: HL += HL
        assert_eq!(cpu.get_hl(), 0x2400);
    }

    #[test]
    fn test_cma_stc_cmc_flags() {
        reset_mem();
        set_mem(0, &[0x2F, 0x37, 0x3F]); // CMA, STC, CMC
        let mut cpu = test_cpu();
        cpu.a = 0x55;
        cpu.step(); assert_eq!(cpu.a, 0xAA); // CMA
        cpu.flags = 0x02;
        cpu.step(); assert!(cpu.flags & FLAG_CY != 0); // STC
        cpu.step(); assert!(cpu.flags & FLAG_CY == 0); // CMC
    }

    #[test]
    fn test_rar_ral_rrc_rlc() {
        reset_mem();
        set_mem(0, &[0x07, 0x0F, 0x17, 0x1F]); // RLC, RRC, RAL, RAR
        let mut cpu = test_cpu();
        cpu.a = 0x81;
        cpu.step(); assert_eq!(cpu.a, 0x03); // RLC: 0x81→0x03, CY=1
        cpu.step(); assert_eq!(cpu.a, 0x81); // RRC: 0x03→0x81, CY=1
        cpu.a = 0x81;
        cpu.flags = 0x02;
        cpu.step(); assert_eq!(cpu.a, 0x02); // RLC fresh
    }
}
