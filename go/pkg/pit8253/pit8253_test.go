package pit8253

import "testing"

func TestLowThenHighAcceptsZeroLowByte(t *testing.T) {
	p := New()
	p.Write(CtlReg, 0x36) // counter 0, low/high, mode 3
	p.Write(Counter0, 0x00)
	p.Write(Counter0, 0x12)
	if got := p.CounterReload(0); got != 0x1200 {
		t.Fatalf("reload=%04X, want 1200", got)
	}
	if got := p.CounterVal(0); got != 0x1200 {
		t.Fatalf("count=%04X, want 1200", got)
	}
}

func TestReadBackSelectsOnlyRequestedCounter(t *testing.T) {
	p := New()
	p.Write(CtlReg, 0x30)
	p.Write(Counter0, 0x34)
	p.Write(Counter0, 0x12)
	p.Write(CtlReg, 0x70)
	p.Write(Counter1, 0x78)
	p.Write(Counter1, 0x56)
	// 11x1x000: latch count for counter 0 only (D5=0, D4=1).
	p.Write(CtlReg, 0xD0)
	if got := p.Read(Counter0); got != 0x34 {
		t.Errorf("counter 0 low=%02X, want 34", got)
	}
	if got := p.Read(Counter1); got != 0x78 {
		t.Errorf("counter 1 low=%02X, want 78", got)
	}
}
