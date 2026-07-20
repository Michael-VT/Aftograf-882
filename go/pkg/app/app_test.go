package app

import (
	"testing"
	"time"

	fyneTest "fyne.io/fyne/v2/test"
)

func TestDirectUSARTPorts(t *testing.T) {
	a := New()
	a.outPort(0x28, 0x40) // reset command after the initial mode write
	a.outPort(0x19, 0x55)
	if got, ok := a.USART.TxData(); !ok || got != 0x55 {
		t.Fatalf("direct OUT data=%02X, pending=%v; want 55/pending", got, ok)
	}
	a.USART.ReceiveData(0xA5)
	if got := a.inPort(0x19); got != 0xA5 {
		t.Fatalf("direct IN data=%02X, want A5", got)
	}
}

func TestUSARTReceiveRaisesCPUInterrupt(t *testing.T) {
	a := New()
	a.CPU.Intr = false
	a.USART.ReceiveData(0x42)
	if !a.CPU.Intr {
		t.Fatal("USART receive did not raise CPU interrupt request")
	}
}

func TestLiveKeyboardAndSensorInputs(t *testing.T) {
	a := New()
	a.hardwareMu.Lock()
	a.keyboard[2][1] = true
	a.limits[0] = true
	a.dip[3] = true
	a.hardwareMu.Unlock()

	// PPI1.C bit 1 selects column 1; PPI1.A returns the six row bits.
	a.PPI1.Write(3, 0x92) // PPI1.A/B input, PPI1.C output
	a.PPI1.Write(2, 0x02)
	if got := a.PPI1.Read(0); got != 0x04 {
		t.Fatalf("PPI1 keyboard rows=%02X, want 04", got)
	}
	if got := a.PPI1.Read(1); got != 0x81 {
		t.Fatalf("PPI1 sensor byte=%02X, want 81", got)
	}

	// Compatibility scan used by the Rust implementation: PPI2.A selects row 2.
	a.PPI2.Write(0, 0x04)
	if got := a.PPI2.Read(1); got != 0x02 {
		t.Fatalf("PPI2 keyboard columns=%02X, want 02", got)
	}
}

func TestRunStopsAtHLTWithoutGUI(t *testing.T) {
	a := New()
	a.MMU.Poke(0x0000, 0x00) // NOP
	a.MMU.Poke(0x0001, 0x76) // HLT
	a.CPU.Reset()
	a.speedIdx = 0
	a.Run()
	deadline := time.Now().Add(500 * time.Millisecond)
	for time.Now().Before(deadline) {
		a.mu.Lock()
		halted, running := a.CPU.Halt, a.Running
		a.mu.Unlock()
		if halted && !running {
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("Run did not stop at HLT")
}

func TestRunStopsOnPeripheralAccess(t *testing.T) {
	a := New()
	// LDA $E000 — a memory-mapped PPI1 read, followed by NOP.
	a.MMU.Poke(0x0000, 0x3A)
	a.MMU.Poke(0x0001, 0x00)
	a.MMU.Poke(0x0002, 0xE0)
	a.MMU.Poke(0x0003, 0x00)
	a.CPU.Reset()
	a.speedIdx = 0
	a.ioMu.Lock()
	a.peripheralBreak = true
	a.ioMu.Unlock()
	a.Run()

	deadline := time.Now().Add(500 * time.Millisecond)
	for time.Now().Before(deadline) {
		a.mu.Lock()
		running, pc := a.Running, a.CPU.PC
		a.mu.Unlock()
		if !running {
			a.ioMu.Lock()
			event := a.peripheralEvent
			a.ioMu.Unlock()
			if event.addr != 0xE000 || !event.valid || !event.breakHit {
				t.Fatalf("peripheral stop event=%+v", event)
			}
			if pc != 3 {
				t.Fatalf("PC after peripheral access=%04X, want 0003", pc)
			}
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("Run did not stop on peripheral access")
}

func TestMakeWindowSmoke(t *testing.T) {
	app := fyneTest.NewTempApp(t)
	sim := New()
	w := fyneTest.NewTempWindow(t, nil)
	content := sim.MakeWindow(w)
	if content == nil {
		t.Fatal("MakeWindow returned nil content")
	}
	w.SetContent(content)
	if w.Content() != content {
		t.Fatal("MakeWindow did not install content in the window")
	}
	_ = app
}

func TestLoadHPGLRendersImmediately(t *testing.T) {
	a := New()
	if err := a.loadHPGLText("IN;SP1;PU0,0;PD100,0;"); err != nil {
		t.Fatal(err)
	}
	if len(a.Plot.Lines) != 1 || a.hpglStep != 1 {
		t.Fatalf("HPGL load did not render immediately: lines=%d step=%d", len(a.Plot.Lines), a.hpglStep)
	}
}

func TestMemoryJumpKeepsRequestedRow(t *testing.T) {
	a := New()
	a.memJump(0x6000)
	if a.memAddr != 0x6000 {
		t.Fatalf("memory address=%04X, want 6000", a.memAddr)
	}
}

func TestMemoryByteColumnSelection(t *testing.T) {
	for _, tc := range []struct {
		column int
		want   int
	}{
		{6, 0}, {27, 7}, {31, 8}, {52, 15},
		{57, 0}, {72, 15},
	} {
		got, ok := memoryByteAtColumn(tc.column)
		if !ok || got != tc.want {
			t.Fatalf("column %d -> (%d, %v), want (%d, true)", tc.column, got, ok, tc.want)
		}
	}
	for _, column := range []int{0, 5, 29, 30, 54, 56, 73} {
		if got, ok := memoryByteAtColumn(column); ok {
			t.Fatalf("separator column %d selected byte %d", column, got)
		}
	}
}

func TestDebugRowsUseDisassemblerHeight(t *testing.T) {
	app := fyneTest.NewTempApp(t)
	sim := New()
	w := fyneTest.NewTempWindow(t, nil)
	content := sim.MakeWindow(w)
	w.SetContent(content)
	if sim.debugRowHeight <= 0 || sim.stackLbl[0].MinSize().Height != sim.debugRowHeight {
		t.Fatalf("stack row height=%v, disassembler row height=%v", sim.stackLbl[0].MinSize().Height, sim.debugRowHeight)
	}
	_ = app
}
