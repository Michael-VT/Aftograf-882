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
