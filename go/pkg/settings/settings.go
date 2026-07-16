// Package settings holds emulator configuration and system settings.
package settings

// Settings stores emulator configuration parameters.
type Settings struct {
	// CPU frequency in Hz.
	CPUFreq int

	// HP-GL command buffer base address in the memory map.
	HPGLBufferAddr uint16

	// Plotter configuration.
	PlotterStepsPerUnit int

	// Display scale factor.
	DisplayScale float64

	// Sound enabled flag.
	SoundEnabled bool

	// PIT (Programmable Interval Timer) frequency divisor.
	PITDivisor uint16
}

// Default returns a Settings struct populated with sensible defaults.
func Default() *Settings {
	return &Settings{
		CPUFreq:             2000000, // 2 MHz
		HPGLBufferAddr:      0x8000,  // firmware convention
		PlotterStepsPerUnit: 40,
		DisplayScale:        1.0,
		SoundEnabled:        true,
		PITDivisor:          2,
	}
}

// Reset restores settings to default values.
func (s *Settings) Reset() {
	*s = *Default()
}
