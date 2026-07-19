package ppi8255

import "testing"

func TestModeAEncoding(t *testing.T) {
	tests := []struct {
		ctl  uint8
		want int
	}{
		{0x80, 0}, // mode 0
		{0xA0, 1}, // D5 set: mode 1
		{0xC0, 2}, // D6 set: mode 2
		{0xE0, 2}, // 1x remains mode 2
	}
	for _, tt := range tests {
		p := New()
		p.Write(PortCtl, tt.ctl)
		if got := p.ModeA(); got != tt.want {
			t.Errorf("control %02X: ModeA()=%d, want %d", tt.ctl, got, tt.want)
		}
	}
}

func TestInputProviderOverridesLatchedPort(t *testing.T) {
	p := New()
	p.Write(PortB, 0x12)
	p.SetInputProvider(func(port int) (uint8, bool) {
		if port == PortB {
			return 0xA5, true
		}
		return 0, false
	})
	if got := p.Read(PortB); got != 0xA5 {
		t.Fatalf("input provider returned %02X, want A5", got)
	}
	if got := p.Read(PortA); got != 0 {
		t.Fatalf("unhandled port changed read value to %02X", got)
	}
}
