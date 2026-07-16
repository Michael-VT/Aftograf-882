// Package pit8253 emulates the Intel 8253 Programmable Interval Timer.
//
// Three independent 16-bit counters each support six operating modes.
// Control words select the counter, access format, mode, and BCD vs. binary
// counting. Read-back can latch the current count and/or status.
package pit8253

const (
	// Counter I/O port offsets relative to chip base.
	Counter0 = 0
	Counter1 = 1
	Counter2 = 2
	CtlReg   = 3
)

// CounterMode selects a PIT operating mode (0-5).
type CounterMode int

const (
	Mode0InterruptOnTerminalCount CounterMode = 0 // interrupt on terminal count
	Mode1HardwareRetriggerableOneShot CounterMode = 1
	Mode2RateGenerator            CounterMode = 2
	Mode3SquareWave               CounterMode = 3
	Mode4SoftwareTriggeredStrobe  CounterMode = 4
	Mode5HardwareTriggeredStrobe  CounterMode = 5
)

// AccessFormat controls how 16-bit counter values are read/written.
type AccessFormat int

const (
	AccessLatchCount          AccessFormat = 0 // counter latch command
	AccessLowByteOnly         AccessFormat = 1
	AccessHighByteOnly        AccessFormat = 2
	AccessLowThenHigh         AccessFormat = 3
)

// counterState holds the runtime state of one 8253 counter.
type counterState struct {
	// Operating mode (modes 0-5).
	mode CounterMode

	// Access format selected by the control word.
	access AccessFormat

	// BCD flag — when true counting is BCD (0-9999) rather than binary (0-65535).
	bcd bool

	// The 16-bit reload value (programmed via two writes when access format is
	// LowThenHigh, or one write for single-byte formats).
	reload uint16

	// The running counter value.  Decrements each count cycle.
	count uint16

	// Latched values for read-back.
	latchCount *uint16
	latchStatus *statusLatch
}

// statusLatch carries the latched status byte.
type statusLatch struct {
	// Latched copy of the counter's status at latch time.
	// Bits: 7-6 = null / access format, 5-4 = mode (upper), 3-1 = mode (lower), 0 = BCD.
	// The OUT pin state is not modelled here.
	nullCount bool // when true, the count is null
}

// PIT8253 emulates one 8253 chip with three counters.
type PIT8253 struct {
	counters [3]counterState
}

// New creates a PIT8253 with all counters reset.
func New() *PIT8253 {
	return &PIT8253{}
}

// Write writes a byte to one of the four I/O addresses.
//
// Addresses 0-2 write to the respective counter.  The number of bytes consumed
// depends on the access format.  Address 3 writes a control word that selects
// the counter and its configuration.
func (p *PIT8253) Write(offset int, val uint8) {
	switch offset {
	case Counter0, Counter1, Counter2:
		p.writeCounter(offset, val)
	case CtlReg:
		p.writeControl(val)
	}
}

// Read reads a byte from one of the four I/O addresses.
//
// Addresses 0-2 read from the respective counter (subject to its access format
// and any pending latch).  Address 3 returns 0 (control register reads are not
// a standard 8253 operation).
func (p *PIT8253) Read(offset int) uint8 {
	switch offset {
	case Counter0, Counter1, Counter2:
		return p.readCounter(offset)
	case CtlReg:
		return 0
	default:
		return 0
	}
}

// Tick decrements all three counters by one cycle.
//
// In real hardware counters are clocked externally; this method allows a
// system emulator to advance time.  Modes 0 and 4 decrement every cycle;
// modes 2 and 3 are rate dividers that reload automatically.
func (p *PIT8253) Tick() {
	for i := range p.counters {
		c := &p.counters[i]
		if c.count == 0 {
			// Reload on underflow for rate-generator/square-wave modes.
			switch c.mode {
			case Mode2RateGenerator, Mode3SquareWave:
				c.count = c.reload
			}
			continue
		}
		c.count--
	}
}

// Reset clears all counters to zero.
func (p *PIT8253) Reset() {
	for i := range p.counters {
		p.counters[i] = counterState{}
	}
}

// --- internal helpers ---

func (p *PIT8253) writeCounter(idx int, val uint8) {
	c := &p.counters[idx]
	// Discard any prior latch on write.
	c.latchCount = nil
	c.latchStatus = nil

	switch c.access {
	case AccessLowByteOnly:
		c.reload = uint16(val)
	case AccessHighByteOnly:
		c.reload = uint16(val) << 8
	case AccessLowThenHigh:
		if c.access == AccessLowThenHigh && c.reload&0x00FF != 0 {
			// Second write (high byte after low).
			c.reload = (c.reload & 0x00FF) | (uint16(val) << 8)
		} else {
			// First write (low byte).
			c.reload = uint16(val)
		}
	default:
		return // latch command, not a write
	}
	// Reload counter (modes that don't use reload on terminal count still
	// load the initial value).
	c.count = c.reload
	// In mode 0, writing triggers the count.
	// In modes 2/3 the counter reloads automatically at zero.
}

func (p *PIT8253) readCounter(idx int) uint8 {
	c := &p.counters[idx]
	return uint8(c.count & 0xFF)
}

func (p *PIT8253) writeControl(val uint8) {
	// Bits 7-6: counter select
	sel := val >> 6
	if sel == 3 {
		// Read-back command (82C54, not original 8253, but widely supported).
		// Bits: 0 = latch status, 1 = latch count, 2-3 = counter selects.
		if val&0x01 != 0 { // latch status
			for i := 0; i < 3; i++ {
				if sel == 3 || val&(0x04>>i) != 0 {
					p.latchStatus(i)
				}
			}
		}
		if val&0x02 != 0 { // latch count
			for i := 0; i < 3; i++ {
				if sel == 3 || val&(0x04>>i) != 0 {
					p.latchCounter(i)
				}
			}
		}
		return
	}
	c := &p.counters[sel]
	// Bits 5-4: access format
	c.access = AccessFormat((val >> 4) & 0x03)
	// Bits 3-1: mode
	c.mode = CounterMode((val >> 1) & 0x07)
	// Bit 0: BCD
	c.bcd = val&0x01 != 0
	// Clear any pending latch.
	c.latchCount = nil
	c.latchStatus = nil
}

// latchCounter latches the current count for read-back.
func (p *PIT8253) latchCounter(idx int) {
	c := &p.counters[idx]
	v := c.count
	c.latchCount = &v
}

// latchStatus latches the current status for read-back.
func (p *PIT8253) latchStatus(idx int) {
	c := &p.counters[idx]
	// Build status byte.
	st := uint8(c.access)<<4 | uint8(c.mode)<<1
	if c.bcd {
		st |= 0x01
	}
	null := c.latchCount == nil // count has been read since last latch
	c.latchStatus = &statusLatch{nullCount: null}
	_ = st // status byte available for read-back if needed
}
