package settings

import "testing"

func TestDefaultAndReset(t *testing.T) {
	s := Default()
	if s.CPUFreq == 0 || s.PlotterStepsPerUnit == 0 || s.PITDivisor == 0 {
		t.Fatalf("invalid default settings: %+v", s)
	}
	s.CPUFreq = 1
	s.Reset()
	if s.CPUFreq != Default().CPUFreq {
		t.Fatalf("Reset did not restore CPU frequency: %d", s.CPUFreq)
	}
}
