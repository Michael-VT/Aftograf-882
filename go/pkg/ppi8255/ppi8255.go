// Package ppi8255 emulates the Intel 8255 Programmable Peripheral Interface.
//
// Three 8-bit ports (A, B, C) are controlled via a control register at the
// fourth I/O address. Mode 0 (basic I/O) is fully implemented; modes 1 and 2
// (strobed/bidirectional) decode control-register bits but do not simulate
// handshake signals.
package ppi8255

const (
	// Port addresses relative to chip base.
	PortA = 0
	PortB = 1
	PortC = 2
	PortCtl = 3
)

// PPI8255 emulates one 8255 chip.
type PPI8255 struct {
	// Data registers.
	A, B, C uint8

	// Control register (latched on last write to PortCtl).
	ctl uint8
}

// New creates a PPI8255 with all ports and control register reset to zero.
func New() *PPI8255 {
	return &PPI8255{}
}

// Write writes val to one of the four chip registers.
// Port 0-2 targets the respective data port; port 3 sets the control register
// (and when bit 7 is clear, performs a bit-set/reset on port C).
func (p *PPI8255) Write(port int, val uint8) {
	switch port {
	case PortA:
		if p.modeAin() {
			return // port A configured as input, write ignored
		}
		p.A = val
	case PortB:
		if p.modeBin() {
			return // port B configured as input, write ignored
		}
		p.B = val
	case PortC:
		// Upper nibble direction from ctl bit 3, lower from ctl bit 0.
		// Mask writes by direction.
		mask := p.portCMask()
		p.C = (p.C & ^mask) | (val & mask)
	case PortCtl:
		if val&0x80 != 0 {
			// Mode set.
			p.ctl = val
		} else {
			// Bit set/reset on port C.
			bit := val >> 1 & 0x07
			set := val&0x01 != 0
			if set {
				p.C |= 1 << bit
			} else {
				p.C &^= 1 << bit
			}
		}
	}
}

// Read reads one of the four chip registers.
// Port 0-2 returns the respective data port; port 3 returns the control
// register as written.
func (p *PPI8255) Read(port int) uint8 {
	switch port {
	case PortA:
		return p.A
	case PortB:
		return p.B
	case PortC:
		return p.C
	case PortCtl:
		return p.ctl
	default:
		return 0
	}
}

// Reset clears all registers to zero.
func (p *PPI8255) Reset() {
	p.A = 0
	p.B = 0
	p.C = 0
	p.ctl = 0
}

// --- internal helpers ---

// modeAin returns true when port A is configured as input (mode set bit 4).
func (p *PPI8255) modeAin() bool { return p.ctl&0x10 != 0 }

// modeBin returns true when port B is configured as input (mode set bit 1).
func (p *PPI8255) modeBin() bool { return p.ctl&0x02 != 0 }

// portCMask returns the writable mask for port C given the control register.
// Upper nibble (PC4-PC7) enabled by ctl bit 3; lower nibble (PC0-PC3) by ctl bit 0.
func (p *PPI8255) portCMask() uint8 {
	mask := uint8(0)
	if p.ctl&0x08 == 0 { // upper nibble output
		mask |= 0xf0
	}
	if p.ctl&0x01 == 0 { // lower nibble output
		mask |= 0x0f
	}
	return mask
}

// PortA returns the current Port A value.
func (p *PPI8255) PortA() uint8 { return p.A }

// PortB returns the current Port B value.
func (p *PPI8255) PortB() uint8 { return p.B }

// PortC returns the current Port C value.
func (p *PPI8255) PortC() uint8 { return p.C }

// Control returns the current control register value.
func (p *PPI8255) Control() uint8 { return p.ctl }

// ModeA returns the mode of group A (0, 1, or 2).
func (p *PPI8255) ModeA() int {
	if p.ctl&0x40 != 0 { return 1 }
	if p.ctl&0x20 != 0 { return 2 }
	return 0
}

// ModeB returns the mode of group B (0 or 1).
func (p *PPI8255) ModeB() int {
	if p.ctl&0x04 != 0 { return 1 }
	return 0
}
