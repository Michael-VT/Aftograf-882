// Package cpu implements Intel 8080 / K580IK80A emulation.
package cpu

// Flags (8080: S Z 0 AC 0 P 0 CY, bit 1 always set).
const (
	FlagCY uint8 = 0x01
	FlagP  uint8 = 0x04
	FlagAC uint8 = 0x10
	FlagZ  uint8 = 0x40
	FlagS  uint8 = 0x80
)

// CPU8080 emulates an Intel 8080 processor.
type CPU8080 struct {
	A, B, C, D, E, H, L uint8
	SP, PC               uint16
	Flags                uint8
	Cycles               uint64
	Intr                 bool // interrupt pending
	IE                   bool // interrupt enabled
	Halt                 bool

	ReadByte  func(uint16) uint8
	WriteByte func(uint16, uint8)
	InPort    func(uint8) uint8
	OutPort   func(uint8, uint8)
}

// New creates a CPU with the given callback functions.
func New(readByte func(uint16) uint8, writeByte func(uint16, uint8), inPort func(uint8) uint8, outPort func(uint8, uint8)) *CPU8080 {
	return &CPU8080{
		Flags:     0x02, // bit 1 always set
		ReadByte:  readByte,
		WriteByte: writeByte,
		InPort:    inPort,
		OutPort:   outPort,
	}
}

// Parity returns true if val has even parity.
func Parity(val uint8) bool {
	v := val
	v ^= v >> 4
	v ^= v >> 2
	v ^= v >> 1
	return (v & 1) == 0
}

func (c *CPU8080) fetchByte() uint8 {
	b := c.ReadByte(c.PC)
	c.PC = c.PC + 1
	return b
}

func (c *CPU8080) fetchWord() uint16 {
	lo := uint16(c.fetchByte())
	hi := uint16(c.fetchByte())
	return hi<<8 | lo
}

func (c *CPU8080) pushStack(val uint16) {
	c.SP = c.SP - 1
	c.WriteByte(c.SP, uint8(val>>8))
	c.SP = c.SP - 1
	c.WriteByte(c.SP, uint8(val))
}

func (c *CPU8080) popStack() uint16 {
	lo := uint16(c.ReadByte(c.SP))
	c.SP = c.SP + 1
	hi := uint16(c.ReadByte(c.SP))
	c.SP = c.SP + 1
	return hi<<8 | lo
}

func (c *CPU8080) GetBC() uint16 { return uint16(c.B)<<8 | uint16(c.C) }
func (c *CPU8080) GetDE() uint16 { return uint16(c.D)<<8 | uint16(c.E) }
func (c *CPU8080) GetHL() uint16 { return uint16(c.H)<<8 | uint16(c.L) }
func (c *CPU8080) getBC() uint16 { return c.GetBC() }
func (c *CPU8080) getDE() uint16 { return c.GetDE() }
func (c *CPU8080) getHL() uint16 { return c.GetHL() }
func (c *CPU8080) setBC(v uint16) { c.B, c.C = uint8(v>>8), uint8(v) }
func (c *CPU8080) setDE(v uint16) { c.D, c.E = uint8(v>>8), uint8(v) }
func (c *CPU8080) setHL(v uint16) { c.H, c.L = uint8(v>>8), uint8(v) }


// Step executes one instruction and returns false if HALTed.
func (c *CPU8080) Step() bool {
	if c.Halt {
		return false
	}

	// Interrupt handling
	if c.Intr && c.IE {
		c.IE = false
		c.Intr = false
		c.pushStack(c.PC)
		c.PC = 0x0038 // RST 7 vector
		c.Cycles += 11
		return true
	}

	opcode := c.fetchByte()

	switch opcode {
	case 0x00: // NOP
		c.Cycles += 4

	case 0x01: // LXI B, word
		c.setBC(c.fetchWord())
		c.Cycles += 10

	case 0x02: // STAX B
		c.WriteByte(c.getBC(), c.A)
		c.Cycles += 7

	case 0x03: // INX B
		c.setBC(c.getBC() + 1)
		c.Cycles += 5

	case 0x04: // INR B
		val := c.B + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.B = val
		c.Cycles += 5

	case 0x05: // DCR B
		val := c.B - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.B = val
		c.Cycles += 5

	case 0x06: // MVI B
		c.B = c.fetchByte()
		c.Cycles += 7

	case 0x07: // RLC
		cy := c.A >> 7
		c.A = (c.A << 1) | cy
		c.Flags = (c.Flags & ^FlagCY) | cy | 0x02
		c.Cycles += 4

	case 0x08: // NOP (DAD B variant, treated as NOP)
		c.Cycles += 4

	case 0x09: // DAD B
		hl := uint32(c.getHL()) + uint32(c.getBC())
		c.setHL(uint16(hl))
		c.Flags = (c.Flags & ^FlagCY) | selectBit(hl > 0xffff, FlagCY) | 0x02
		c.Cycles += 10

	case 0x0a: // LDAX B
		c.A = c.ReadByte(c.getBC())
		c.Cycles += 7

	case 0x0b: // DCX B
		c.setBC(c.getBC() - 1)
		c.Cycles += 5

	case 0x0c: // INR C
		val := c.C + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.C = val
		c.Cycles += 5

	case 0x0d: // DCR C
		val := c.C - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.C = val
		c.Cycles += 5

	case 0x0e: // MVI C
		c.C = c.fetchByte()
		c.Cycles += 7

	case 0x0f: // RRC
		cy := c.A & 0x01
		c.A = (c.A >> 1) | (cy << 7)
		c.Flags = (c.Flags & ^FlagCY) | cy | 0x02
		c.Cycles += 4

	case 0x10: // NOP
		c.Cycles += 4

	case 0x11: // LXI D
		c.setDE(c.fetchWord())
		c.Cycles += 10

	case 0x12: // STAX D
		c.WriteByte(c.getDE(), c.A)
		c.Cycles += 7

	case 0x13: // INX D
		c.setDE(c.getDE() + 1)
		c.Cycles += 5

	case 0x14: // INR D
		val := c.D + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.D = val
		c.Cycles += 5

	case 0x15: // DCR D
		val := c.D - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.D = val
		c.Cycles += 5

	case 0x16: // MVI D
		c.D = c.fetchByte()
		c.Cycles += 7

	case 0x17: // RAL
		oldCy := c.Flags & FlagCY
		newCy := selectBit(c.A&0x80 != 0, FlagCY)
		c.A = (c.A << 1) | oldCy
		c.Flags = (c.Flags & ^FlagCY) | newCy | 0x02
		c.Cycles += 4

	case 0x18: // NOP
		c.Cycles += 4

	case 0x19: // DAD D
		hl := uint32(c.getHL()) + uint32(c.getDE())
		c.setHL(uint16(hl))
		c.Flags = (c.Flags & ^FlagCY) | selectBit(hl > 0xffff, FlagCY) | 0x02
		c.Cycles += 10

	case 0x1a: // LDAX D
		c.A = c.ReadByte(c.getDE())
		c.Cycles += 7

	case 0x1b: // DCX D
		c.setDE(c.getDE() - 1)
		c.Cycles += 5

	case 0x1c: // INR E
		val := c.E + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.E = val
		c.Cycles += 5

	case 0x1d: // DCR E
		val := c.E - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.E = val
		c.Cycles += 5

	case 0x1e: // MVI E
		c.E = c.fetchByte()
		c.Cycles += 7

	case 0x1f: // RAR
		oldCy := c.Flags & FlagCY
		newCy := selectBit(c.A&0x01 != 0, FlagCY)
		c.A = (c.A >> 1) | (oldCy << 7)
		c.Flags = (c.Flags & ^FlagCY) | newCy | 0x02
		c.Cycles += 4

	case 0x20: // NOP (RIM on 8085)
		c.Cycles += 4

	case 0x21: // LXI H
		c.setHL(c.fetchWord())
		c.Cycles += 10

	case 0x22: // SHLD addr
		addr := c.fetchWord()
		c.WriteByte(addr, c.L)
		c.WriteByte(addr+1, c.H)
		c.Cycles += 16

	case 0x23: // INX H
		c.setHL(c.getHL() + 1)
		c.Cycles += 5

	case 0x24: // INR H
		val := c.H + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.H = val
		c.Cycles += 5

	case 0x25: // DCR H
		val := c.H - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.H = val
		c.Cycles += 5

	case 0x26: // MVI H
		c.H = c.fetchByte()
		c.Cycles += 7

	case 0x27: // DAA
		a := uint16(c.A)
		origCy := c.Flags & FlagCY
		acSet := false
		if (a&0x0f) > 9 || (c.Flags&FlagAC) != 0 {
			r := a + 6
			a = r
			acSet = r > 0x0f
		}
		cySet := false
		if (a>>4) > 9 || origCy != 0 {
			r := a + 0x60
			a = r
			cySet = r > 0xff
		}
		c.A = uint8(a)
		c.Flags = 0x02 |
			selectBit(acSet, FlagAC) |
			selectBit(cySet, FlagCY) |
			selectBit(c.A&0x80 != 0, FlagS) |
			selectBit(c.A == 0, FlagZ) |
			selectBit(Parity(c.A), FlagP)
		c.Cycles += 4

	case 0x28: // NOP (DCX H variant)
		c.Cycles += 4

	case 0x29: // DAD H
		hl := uint32(c.getHL()) + uint32(c.getHL())
		c.setHL(uint16(hl))
		c.Flags = (c.Flags & ^FlagCY) | selectBit(hl > 0xffff, FlagCY) | 0x02
		c.Cycles += 10

	case 0x2a: // LHLD addr
		addr := c.fetchWord()
		c.L = c.ReadByte(addr)
		c.H = c.ReadByte(addr + 1)
		c.Cycles += 16

	case 0x2b: // DCX H
		c.setHL(c.getHL() - 1)
		c.Cycles += 5

	case 0x2c: // INR L
		val := c.L + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.L = val
		c.Cycles += 5

	case 0x2d: // DCR L
		val := c.L - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.L = val
		c.Cycles += 5

	case 0x2e: // MVI L
		c.L = c.fetchByte()
		c.Cycles += 7

	case 0x2f: // CMA
		c.A = ^c.A
		c.Cycles += 4

	case 0x30: // NOP
		c.Cycles += 4

	case 0x31: // LXI SP
		c.SP = c.fetchWord()
		c.Cycles += 10

	case 0x32: // STA addr
		c.WriteByte(c.fetchWord(), c.A)
		c.Cycles += 13

	case 0x33: // INX SP
		c.SP++
		c.Cycles += 5

	case 0x34: // INR M
		addr := c.getHL()
		val := c.ReadByte(addr) + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.WriteByte(addr, val)
		c.Cycles += 10

	case 0x35: // DCR M
		addr := c.getHL()
		val := c.ReadByte(addr) - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.WriteByte(addr, val)
		c.Cycles += 10

	case 0x36: // MVI M
		c.WriteByte(c.getHL(), c.fetchByte())
		c.Cycles += 10

	case 0x37: // STC
		c.Flags |= FlagCY | 0x02
		c.Cycles += 4

	case 0x38: // NOP
		c.Cycles += 4

	case 0x39: // DAD SP
		hl := uint32(c.getHL()) + uint32(c.SP)
		c.setHL(uint16(hl))
		c.Flags = (c.Flags & ^FlagCY) | selectBit(hl > 0xffff, FlagCY) | 0x02
		c.Cycles += 10

	case 0x3a: // LDA addr
		c.A = c.ReadByte(c.fetchWord())
		c.Cycles += 13

	case 0x3b: // DCX SP
		c.SP--
		c.Cycles += 5

	case 0x3c: // INR A
		val := c.A + 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0, FlagAC) |
			(c.Flags & FlagCY)
		c.A = val
		c.Cycles += 5

	case 0x3d: // DCR A
		val := c.A - 1
		c.Flags = 0x02 |
			selectBit(val&0x80 != 0, FlagS) |
			selectBit(val == 0, FlagZ) |
			selectBit(Parity(val), FlagP) |
			selectBit(val&0x0f == 0x0f, FlagAC) |
			(c.Flags & FlagCY)
		c.A = val
		c.Cycles += 5

	case 0x3e: // MVI A
		c.A = c.fetchByte()
		c.Cycles += 7

	case 0x3f: // CMC
		c.Flags ^= FlagCY
		c.Flags |= 0x02
		c.Cycles += 4

	// MOV B, B..MOV A, A (0x40-0x7f)
	case 0x40: // MOV B, B
		c.Cycles += 5
	case 0x41: // MOV B, C
		c.B = c.C; c.Cycles += 5
	case 0x42: // MOV B, D
		c.B = c.D; c.Cycles += 5
	case 0x43: // MOV B, E
		c.B = c.E; c.Cycles += 5
	case 0x44: // MOV B, H
		c.B = c.H; c.Cycles += 5
	case 0x45: // MOV B, L
		c.B = c.L; c.Cycles += 5
	case 0x46: // MOV B, M
		c.B = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x47: // MOV B, A
		c.B = c.A; c.Cycles += 5
	case 0x48: // MOV C, B
		c.C = c.B; c.Cycles += 5
	case 0x49: // MOV C, C
		c.Cycles += 5
	case 0x4a: // MOV C, D
		c.C = c.D; c.Cycles += 5
	case 0x4b: // MOV C, E
		c.C = c.E; c.Cycles += 5
	case 0x4c: // MOV C, H
		c.C = c.H; c.Cycles += 5
	case 0x4d: // MOV C, L
		c.C = c.L; c.Cycles += 5
	case 0x4e: // MOV C, M
		c.C = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x4f: // MOV C, A
		c.C = c.A; c.Cycles += 5
	case 0x50: // MOV D, B
		c.D = c.B; c.Cycles += 5
	case 0x51: // MOV D, C
		c.D = c.C; c.Cycles += 5
	case 0x52: // MOV D, D
		c.Cycles += 5
	case 0x53: // MOV D, E
		c.D = c.E; c.Cycles += 5
	case 0x54: // MOV D, H
		c.D = c.H; c.Cycles += 5
	case 0x55: // MOV D, L
		c.D = c.L; c.Cycles += 5
	case 0x56: // MOV D, M
		c.D = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x57: // MOV D, A
		c.D = c.A; c.Cycles += 5
	case 0x58: // MOV E, B
		c.E = c.B; c.Cycles += 5
	case 0x59: // MOV E, C
		c.E = c.C; c.Cycles += 5
	case 0x5a: // MOV E, D
		c.E = c.D; c.Cycles += 5
	case 0x5b: // MOV E, E
		c.Cycles += 5
	case 0x5c: // MOV E, H
		c.E = c.H; c.Cycles += 5
	case 0x5d: // MOV E, L
		c.E = c.L; c.Cycles += 5
	case 0x5e: // MOV E, M
		c.E = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x5f: // MOV E, A
		c.E = c.A; c.Cycles += 5
	case 0x60: // MOV H, B
		c.H = c.B; c.Cycles += 5
	case 0x61: // MOV H, C
		c.H = c.C; c.Cycles += 5
	case 0x62: // MOV H, D
		c.H = c.D; c.Cycles += 5
	case 0x63: // MOV H, E
		c.H = c.E; c.Cycles += 5
	case 0x64: // MOV H, H
		c.Cycles += 5
	case 0x65: // MOV H, L
		c.H = c.L; c.Cycles += 5
	case 0x66: // MOV H, M
		c.H = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x67: // MOV H, A
		c.H = c.A; c.Cycles += 5
	case 0x68: // MOV L, B
		c.L = c.B; c.Cycles += 5
	case 0x69: // MOV L, C
		c.L = c.C; c.Cycles += 5
	case 0x6a: // MOV L, D
		c.L = c.D; c.Cycles += 5
	case 0x6b: // MOV L, E
		c.L = c.E; c.Cycles += 5
	case 0x6c: // MOV L, H
		c.L = c.H; c.Cycles += 5
	case 0x6d: // MOV L, L
		c.Cycles += 5
	case 0x6e: // MOV L, M
		c.L = c.ReadByte(c.getHL()); c.Cycles += 7
	case 0x6f: // MOV L, A
		c.L = c.A; c.Cycles += 5
	case 0x70: // MOV M, B
		c.WriteByte(c.getHL(), c.B); c.Cycles += 7
	case 0x71: // MOV M, C
		c.WriteByte(c.getHL(), c.C); c.Cycles += 7
	case 0x72: // MOV M, D
		c.WriteByte(c.getHL(), c.D); c.Cycles += 7
	case 0x73: // MOV M, E
		c.WriteByte(c.getHL(), c.E); c.Cycles += 7
	case 0x74: // MOV M, H
		c.WriteByte(c.getHL(), c.H); c.Cycles += 7
	case 0x75: // MOV M, L
		c.WriteByte(c.getHL(), c.L); c.Cycles += 7
	case 0x76: // HLT
		c.Halt = true
		c.Cycles += 7
	case 0x77: // MOV M, A
		c.WriteByte(c.getHL(), c.A); c.Cycles += 7

	// ADD r (0x80-0x87)
	case 0x80:
		c.opADD(c.B)
	case 0x81:
		c.opADD(c.C)
	case 0x82:
		c.opADD(c.D)
	case 0x83:
		c.opADD(c.E)
	case 0x84:
		c.opADD(c.H)
	case 0x85:
		c.opADD(c.L)
	case 0x86:
		c.opADDM(c.ReadByte(c.getHL()))
	case 0x87:
		c.opADD(c.A)

	// ADC r (0x88-0x8f)
	case 0x88:
		c.opADC(c.B)
	case 0x89:
		c.opADC(c.C)
	case 0x8a:
		c.opADC(c.D)
	case 0x8b:
		c.opADC(c.E)
	case 0x8c:
		c.opADC(c.H)
	case 0x8d:
		c.opADC(c.L)
	case 0x8e:
		c.opADCM(c.ReadByte(c.getHL()))
	case 0x8f:
		c.opADC(c.A)

	// SUB r (0x90-0x97)
	case 0x90:
		c.opSUB(c.B)
	case 0x91:
		c.opSUB(c.C)
	case 0x92:
		c.opSUB(c.D)
	case 0x93:
		c.opSUB(c.E)
	case 0x94:
		c.opSUB(c.H)
	case 0x95:
		c.opSUB(c.L)
	case 0x96:
		c.opSUBM(c.ReadByte(c.getHL()))
	case 0x97:
		c.opSUB(c.A)

	// SBB r (0x98-0x9f)
	case 0x98:
		c.opSBB(c.B)
	case 0x99:
		c.opSBB(c.C)
	case 0x9a:
		c.opSBB(c.D)
	case 0x9b:
		c.opSBB(c.E)
	case 0x9c:
		c.opSBB(c.H)
	case 0x9d:
		c.opSBB(c.L)
	case 0x9e:
		c.opSBBM(c.ReadByte(c.getHL()))
	case 0x9f:
		c.opSBB(c.A)

	// ANA r (0xa0-0xa7)
	case 0xa0:
		c.opANA(c.B)
	case 0xa1:
		c.opANA(c.C)
	case 0xa2:
		c.opANA(c.D)
	case 0xa3:
		c.opANA(c.E)
	case 0xa4:
		c.opANA(c.H)
	case 0xa5:
		c.opANA(c.L)
	case 0xa6:
		c.opANAM(c.ReadByte(c.getHL()))
	case 0xa7:
		c.opANA(c.A)

	// XRA r (0xa8-0xaf)
	case 0xa8:
		c.opXRA(c.B)
	case 0xa9:
		c.opXRA(c.C)
	case 0xaa:
		c.opXRA(c.D)
	case 0xab:
		c.opXRA(c.E)
	case 0xac:
		c.opXRA(c.H)
	case 0xad:
		c.opXRA(c.L)
	case 0xae:
		c.opXRAM(c.ReadByte(c.getHL()))
	case 0xaf:
		c.opXRA(c.A) // XRA A — classic zero-accumulator

	// ORA r (0xb0-0xb7)
	case 0xb0:
		c.opORA(c.B)
	case 0xb1:
		c.opORA(c.C)
	case 0xb2:
		c.opORA(c.D)
	case 0xb3:
		c.opORA(c.E)
	case 0xb4:
		c.opORA(c.H)
	case 0xb5:
		c.opORA(c.L)
	case 0xb6:
		c.opORAM(c.ReadByte(c.getHL()))
	case 0xb7:
		c.opORA(c.A)

	// CMP r (0xb8-0xbf)
	case 0xb8:
		c.opCMP(c.B)
	case 0xb9:
		c.opCMP(c.C)
	case 0xba:
		c.opCMP(c.D)
	case 0xbb:
		c.opCMP(c.E)
	case 0xbc:
		c.opCMP(c.H)
	case 0xbd:
		c.opCMP(c.L)
	case 0xbe:
		c.opCMPM(c.ReadByte(c.getHL()))
	case 0xbf:
		c.opCMP(c.A)

	// Conditional RET (0xc0, 0xc8, 0xd0, 0xd8, 0xe0, 0xe8, 0xf0, 0xf8)
	case 0xc0:
		c.opRET(c.Flags&FlagZ == 0) // RNZ
	case 0xc8:
		c.opRET(c.Flags&FlagZ != 0) // RZ
	case 0xd0:
		c.opRET(c.Flags&FlagCY == 0) // RNC
	case 0xd8:
		c.opRET(c.Flags&FlagCY != 0) // RC
	case 0xe0:
		c.opRET(c.Flags&FlagP == 0) // RPO
	case 0xe8:
		c.opRET(c.Flags&FlagP != 0) // RPE
	case 0xf0:
		c.opRET(c.Flags&FlagS == 0) // RP
	case 0xf8:
		c.opRET(c.Flags&FlagS != 0) // RM

	case 0xc1: // POP B
		val := c.popStack()
		c.C, c.B = uint8(val), uint8(val>>8)
		c.Cycles += 10

	case 0xc2: // JNZ addr
		c.opJMP(c.Flags&FlagZ == 0)
	case 0xca: // JZ addr
		c.opJMP(c.Flags&FlagZ != 0)
	case 0xd2: // JNC addr
		c.opJMP(c.Flags&FlagCY == 0)
	case 0xda: // JC addr
		c.opJMP(c.Flags&FlagCY != 0)
	case 0xe2: // JPO addr
		c.opJMP(c.Flags&FlagP == 0)
	case 0xea: // JPE addr
		c.opJMP(c.Flags&FlagP != 0)
	case 0xf2: // JP addr
		c.opJMP(c.Flags&FlagS == 0)
	case 0xfa: // JM addr
		c.opJMP(c.Flags&FlagS != 0)

	case 0xc3: // JMP addr
		c.PC = c.fetchWord()
		c.Cycles += 10

	case 0xc4: // CNZ addr
		c.opCALL(c.Flags&FlagZ == 0)
	case 0xcc: // CZ addr
		c.opCALL(c.Flags&FlagZ != 0)
	case 0xd4: // CNC addr
		c.opCALL(c.Flags&FlagCY == 0)
	case 0xdc: // CC addr
		c.opCALL(c.Flags&FlagCY != 0)
	case 0xe4: // CPO addr
		c.opCALL(c.Flags&FlagP == 0)
	case 0xec: // CPE addr
		c.opCALL(c.Flags&FlagP != 0)
	case 0xf4: // CP addr
		c.opCALL(c.Flags&FlagS == 0)
	case 0xfc: // CM addr
		c.opCALL(c.Flags&FlagS != 0)

	case 0xc5: // PUSH B
		c.pushStack(c.getBC())
		c.Cycles += 11

	case 0xc6: // ADI
		c.opADD(c.fetchByte())
		c.Cycles += 7

	case 0xc7: // RST 0
		c.pushStack(c.PC)
		c.PC = 0x00
		c.Cycles += 11

	case 0xc9: // RET
		c.PC = c.popStack()
		c.Cycles += 10

	case 0xcb: // JMP (same as 0xc3 on some assemblers)
		c.PC = c.fetchWord()
		c.Cycles += 10

	case 0xcd: // CALL addr
		addr := c.fetchWord()
		c.pushStack(c.PC)
		c.PC = addr
		c.Cycles += 17

	case 0xce: // ACI
		carry := uint16(c.Flags & FlagCY)
		val := c.fetchByte()
		result := uint16(c.A) + uint16(val) + carry
		a := uint8(result)
		c.Flags = 0x02 |
			selectBit(a&0x80 != 0, FlagS) |
			selectBit(a == 0, FlagZ) |
			selectBit(Parity(a), FlagP) |
			selectBit((c.A&0x0f)+(val&0x0f)+(uint8(carry)&0x0f) > 0x0f, FlagAC) |
			selectBit(result > 0xff, FlagCY)
		c.A = a
		c.Cycles += 7

	case 0xcf: // RST 1
		c.pushStack(c.PC)
		c.PC = 0x08
		c.Cycles += 11

	case 0xd1: // POP D
		val := c.popStack()
		c.E, c.D = uint8(val), uint8(val>>8)
		c.Cycles += 10

	case 0xd3: // OUT port
		c.OutPort(c.fetchByte(), c.A)
		c.Cycles += 10

	case 0xd5: // PUSH D
		c.pushStack(c.getDE())
		c.Cycles += 11

	case 0xd6: // SUI
		c.opSUB(c.fetchByte())
		c.Cycles += 7

	case 0xd7: // RST 2
		c.pushStack(c.PC)
		c.PC = 0x10
		c.Cycles += 11

	case 0xdb: // IN port
		c.A = c.InPort(c.fetchByte())
		c.Cycles += 10

	case 0xdd: // RST? Ignored, treat as NOP
		c.Cycles += 4

	case 0xde: // SBI
		carry := uint16(c.Flags & FlagCY)
		val := c.fetchByte()
		result := int16(c.A) - int16(val) - int16(carry)
		a := uint8(result)
		ac := (c.A & 0x0f) < (val & 0x0f) + (uint8(carry) & 0x0f)
		c.Flags = 0x02 |
			selectBit(a&0x80 != 0, FlagS) |
			selectBit(a == 0, FlagZ) |
			selectBit(Parity(a), FlagP) |
			selectBit(ac, FlagAC) |
			selectBit(uint16(c.A) < uint16(val)+carry, FlagCY)
		c.A = a
		c.Cycles += 7

	case 0xdf: // RST 3
		c.pushStack(c.PC)
		c.PC = 0x18
		c.Cycles += 11

	case 0xe1: // POP H
		val := c.popStack()
		c.L, c.H = uint8(val), uint8(val>>8)
		c.Cycles += 10

	case 0xe3: // XTHL
		lo := c.ReadByte(c.SP)
		hi := c.ReadByte(c.SP + 1)
		c.WriteByte(c.SP, c.L)
		c.WriteByte(c.SP+1, c.H)
		c.L = lo
		c.H = hi
		c.Cycles += 18

	case 0xe5: // PUSH H
		c.pushStack(c.getHL())
		c.Cycles += 11

	case 0xe6: // ANI
		c.opANA(c.fetchByte())
		c.Cycles += 7

	case 0xe7: // RST 4
		c.pushStack(c.PC)
		c.PC = 0x20
		c.Cycles += 11

	case 0xe9: // PCHL
		c.PC = c.getHL()
		c.Cycles += 5

	case 0xeb: // XCHG
		c.D, c.H = c.H, c.D
		c.E, c.L = c.L, c.E
		c.Cycles += 5

	case 0xed: // NOP (used as prefix on Z80, NOP on 8080)
		c.Cycles += 4

	case 0xee: // XRI
		a := c.A ^ c.fetchByte()
		c.Flags = 0x02 |
			selectBit(a&0x80 != 0, FlagS) |
			selectBit(a == 0, FlagZ) |
			selectBit(Parity(a), FlagP)
		c.A = a
		c.Cycles += 7

	case 0xef: // RST 5
		c.pushStack(c.PC)
		c.PC = 0x28
		c.Cycles += 11

	case 0xf1: // POP PSW
		val := c.popStack()
		c.Flags = uint8(val) | 0x02
		c.A = uint8(val >> 8)
		c.Cycles += 10

	case 0xf3: // DI
		c.IE = false
		c.Cycles += 4

	case 0xf5: // PUSH PSW
		c.pushStack((uint16(c.A) << 8) | uint16(c.Flags))
		c.Cycles += 11

	case 0xf6: // ORI
		a := c.A | c.fetchByte()
		c.Flags = 0x02 |
			selectBit(a&0x80 != 0, FlagS) |
			selectBit(a == 0, FlagZ) |
			selectBit(Parity(a), FlagP)
		c.A = a
		c.Cycles += 7

	case 0xf7: // RST 6
		c.pushStack(c.PC)
		c.PC = 0x30
		c.Cycles += 11

	case 0xf9: // SPHL
		c.SP = c.getHL()
		c.Cycles += 5

	case 0xfb: // EI
		c.IE = true
		c.Cycles += 4

	case 0xfe: // CPI
		c.opCMP(c.fetchByte())
		c.Cycles += 7

	case 0xff: // RST 7
		c.pushStack(c.PC)
		c.PC = 0x38
		c.Cycles += 11

	default:
		// Unreachable — NOP for safety
		c.Cycles += 4
	}

	return !c.Halt
}

// opADD adds val to A.
func (c *CPU8080) opADD(val uint8) {
	result := uint16(c.A) + uint16(val)
	a := uint8(result)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit((c.A&0x0f)+(val&0x0f) > 0x0f, FlagAC) |
		selectBit(result > 0xff, FlagCY)
	c.A = a
	c.Cycles += 4
}

// opADDM adds memory value to A (7 cycles).
func (c *CPU8080) opADDM(val uint8) {
	result := uint16(c.A) + uint16(val)
	a := uint8(result)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit((c.A&0x0f)+(val&0x0f) > 0x0f, FlagAC) |
		selectBit(result > 0xff, FlagCY)
	c.A = a
	c.Cycles += 7
}

// opADC adds val + carry to A.
func (c *CPU8080) opADC(val uint8) {
	carry := uint16(c.Flags & FlagCY)
	result := uint16(c.A) + uint16(val) + carry
	a := uint8(result)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit((c.A&0x0f)+(val&0x0f)+(uint8(carry)&0x0f) > 0x0f, FlagAC) |
		selectBit(result > 0xff, FlagCY)
	c.A = a
	c.Cycles += 4
}

// opADCM is ADC with memory operand.
func (c *CPU8080) opADCM(val uint8) {
	c.opADC(val)
	c.Cycles += 3 // bump from 4 to 7
}

// opSUB subtracts val from A.
func (c *CPU8080) opSUB(val uint8) {
	result := int16(c.A) - int16(val)
	a := uint8(result)
	borrow := c.A < val
	ac := (c.A & 0x0f) < (val & 0x0f)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit(ac, FlagAC) |
		selectBit(borrow, FlagCY)
	c.A = a
	c.Cycles += 4
}

// opSUBM is SUB with memory operand.
func (c *CPU8080) opSUBM(val uint8) {
	c.opSUB(val)
	c.Cycles += 3
}

// opSBB subtracts val + borrow from A.
func (c *CPU8080) opSBB(val uint8) {
	carry := uint16(c.Flags & FlagCY)
	result := int16(c.A) - int16(val) - int16(carry)
	a := uint8(result)
	borrow := uint16(c.A) < uint16(val)+carry
	ac := (c.A & 0x0f) < (val & 0x0f) + (uint8(carry) & 0x0f)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit(ac, FlagAC) |
		selectBit(borrow, FlagCY)
	c.A = a
	c.Cycles += 4
}

// opSBBM is SBB with memory operand.
func (c *CPU8080) opSBBM(val uint8) {
	c.opSBB(val)
	c.Cycles += 3
}

// opANA does A & val, sets flags.
func (c *CPU8080) opANA(val uint8) {
	a := c.A & val
	c.Flags = 0x02 | FlagAC |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP)
	c.A = a
	c.Cycles += 4
}

// opANAM is ANA with memory operand.
func (c *CPU8080) opANAM(val uint8) {
	c.opANA(val)
	c.Cycles += 3
}

// opXRA does A ^ val.
func (c *CPU8080) opXRA(val uint8) {
	a := c.A ^ val
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP)
	c.A = a
	c.Cycles += 4
}

// opXRAM is XRA with memory operand.
func (c *CPU8080) opXRAM(val uint8) {
	c.opXRA(val)
	c.Cycles += 3
}

// opORA does A | val.
func (c *CPU8080) opORA(val uint8) {
	a := c.A | val
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP)
	c.A = a
	c.Cycles += 4
}

// opORAM is ORA with memory operand.
func (c *CPU8080) opORAM(val uint8) {
	c.opORA(val)
	c.Cycles += 3
}

// opCMP compares A with val.
func (c *CPU8080) opCMP(val uint8) {
	result := int16(c.A) - int16(val)
	a := uint8(result)
	borrow := c.A < val
	ac := (c.A & 0x0f) < (val & 0x0f)
	c.Flags = 0x02 |
		selectBit(a&0x80 != 0, FlagS) |
		selectBit(a == 0, FlagZ) |
		selectBit(Parity(a), FlagP) |
		selectBit(ac, FlagAC) |
		selectBit(borrow, FlagCY)
	c.Cycles += 4
}

// opCMPM is CMP with memory operand.
func (c *CPU8080) opCMPM(val uint8) {
	c.opCMP(val)
	c.Cycles += 3
}

// opJMP conditionally sets PC.
func (c *CPU8080) opJMP(cond bool) {
	addr := c.fetchWord()
	if cond {
		c.PC = addr
		c.Cycles += 10
	} else {
		c.Cycles += 10
	}
}

// opCALL conditionally calls.
func (c *CPU8080) opCALL(cond bool) {
	addr := c.fetchWord()
	if cond {
		c.pushStack(c.PC)
		c.PC = addr
		c.Cycles += 17
	} else {
		c.Cycles += 11
	}
}

// opRET conditionally returns.
func (c *CPU8080) opRET(cond bool) {
	if cond {
		c.PC = c.popStack()
		c.Cycles += 11
	} else {
		c.Cycles += 5
	}
}

// Reset resets the CPU state.
func (c *CPU8080) Reset() {
	c.A, c.B, c.C, c.D, c.E, c.H, c.L = 0, 0, 0, 0, 0, 0, 0
	c.SP = 0
	c.PC = 0
	c.Flags = 0x02
	c.Cycles = 0
	c.Intr = false
	c.IE = false
	c.Halt = false
}

func selectBit(cond bool, bit uint8) uint8 {
	if cond {
		return bit
	}
	return 0
}

