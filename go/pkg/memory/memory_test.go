package memory

import (
	"os"
	"testing"
)

// mockIODevice is a simple I/O device for testing.
type mockIODevice struct {
	regs [4]byte
}

func (m *mockIODevice) Read(port int) uint8    { return m.regs[port] }
func (m *mockIODevice) Write(port int, val uint8) { m.regs[port] = val }

func TestNewMMU(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	if mmu == nil {
		t.Fatal("New() returned nil")
	}
	// ROM area should be filled with 0xFF.
	for _, addr := range []uint16{0x0000, 0x1000, 0x5FFF} {
		if mmu.Peek(addr) != 0xFF {
			t.Errorf("ROM at $%04X = %02X, want FF", addr, mmu.Peek(addr))
		}
	}
	// RAM area should be 0.
	for _, addr := range []uint16{0x6000, 0x6400, 0x67FF} {
		if mmu.Peek(addr) != 0 {
			t.Errorf("RAM at $%04X = %02X, want 00", addr, mmu.Peek(addr))
		}
	}
	// Unmapped should return 0xFF.
	for _, addr := range []uint16{0x6800, 0xE000, 0xFFFF} {
		if mmu.Peek(addr) != 0xFF {
			t.Errorf("Unmapped at $%04X = %02X, want FF", addr, mmu.Peek(addr))
		}
	}
}

func TestLoadROM(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	data := []byte{0xAA, 0xBB, 0xCC, 0xDD}
	mmu.LoadROM(data, 0x1000)
	if mmu.Read(0x1000) != 0xAA {
		t.Errorf("byte at 0x1000 = %02X, want AA", mmu.Read(0x1000))
	}
	if mmu.Read(0x1001) != 0xBB {
		t.Errorf("byte at 0x1001 = %02X, want BB", mmu.Read(0x1001))
	}
	if mmu.Read(0x1003) != 0xDD {
		t.Errorf("byte at 0x1003 = %02X, want DD", mmu.Read(0x1003))
	}
	// Beyond loaded data should still be 0xFF.
	if mmu.Read(0x1004) != 0xFF {
		t.Errorf("byte at 0x1004 = %02X, want FF", mmu.Read(0x1004))
	}
}

func TestLoadROMOffsetOverflow(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	// Offset beyond ROM size should be a no-op.
	mmu.LoadROM([]byte{0x42}, 0x6000)
	if mmu.Read(0x6000) != 0 {
		t.Errorf("ROM load beyond range wrote to RAM, got %02X", mmu.Read(0x6000))
	}
}

func TestRAMReadWrite(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.Write(0x6000, 0x42)
	if mmu.Read(0x6000) != 0x42 {
		t.Errorf("RAM read at 0x6000 = %02X, want 42", mmu.Read(0x6000))
	}
	// Write to next byte.
	mmu.Write(0x6001, 0x24)
	if mmu.Read(0x6001) != 0x24 {
		t.Errorf("RAM read at 0x6001 = %02X, want 24", mmu.Read(0x6001))
	}
	// Original unchanged.
	if mmu.Read(0x6000) != 0x42 {
		t.Errorf("RAM at 0x6000 changed = %02X, want 42", mmu.Read(0x6000))
	}
}

func TestRAMBoundary(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.Write(0x67FF, 0x77)
	if mmu.Read(0x67FF) != 0x77 {
		t.Errorf("RAM boundary at 0x67FF = %02X, want 77", mmu.Read(0x67FF))
	}
	// Beyond RAM boundary should be unmapped.
	if mmu.Peek(0x6800) != 0xFF {
		t.Errorf("beyond RAM at 0x6800 = %02X, want FF", mmu.Peek(0x6800))
	}
}

func TestROMWriteIgnored(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.LoadROM([]byte{0x10}, 0x0000)
	mmu.Write(0x0000, 0xFF) // should be ignored
	if mmu.Read(0x0000) != 0x10 {
		t.Errorf("ROM write not ignored, got %02X, want 10", mmu.Read(0x0000))
	}
}

func TestROMWriteCallback(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	var calledAddr uint16
	var calledVal uint8
	mmu.OnInvalidWrite = func(addr uint16, val uint8) {
		calledAddr = addr
		calledVal = val
	}
	mmu.Write(0x1234, 0xAB)
	if calledAddr != 0x1234 {
		t.Errorf("callback addr = %04X, want 1234", calledAddr)
	}
	if calledVal != 0xAB {
		t.Errorf("callback val = %02X, want AB", calledVal)
	}
}

func TestUnmappedRead(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	if mmu.Peek(0x7000) != 0xFF {
		t.Errorf("unmapped 0x7000 = %02X, want FF", mmu.Peek(0x7000))
	}
	if mmu.Peek(0xFFFF) != 0xFF {
		t.Errorf("unmapped 0xFFFF = %02X, want FF", mmu.Peek(0xFFFF))
	}
	if mmu.Peek(0xF000) != 0xFF {
		t.Errorf("unmapped 0xF000 = %02X, want FF", mmu.Peek(0xF000))
	}
}

func TestWriteUnmapped(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	// Writing to an unmapped area should not crash or corrupt.
	mmu.Write(0x7000, 0x42)
	mmu.Write(0xFFFF, 0x42)
	mmu.Write(0xF000, 0x42)
	// Should not affect any mapped region.
	if mmu.Read(0x6000) != 0 {
		t.Errorf("unmapped write corrupted RAM")
	}
}

func TestPPI1IO(t *testing.T) {
	ppi1 := &mockIODevice{}
	mmu := New(ppi1, nil, nil, nil)
	mmu.Write(0xE000, 0xA5)
	if ppi1.regs[0] != 0xA5 {
		t.Errorf("PPI1 port A = %02X, want A5", ppi1.regs[0])
	}
	if mmu.Read(0xE000) != 0xA5 {
		t.Errorf("PPI1 port A read = %02X, want A5", mmu.Read(0xE000))
	}
}

func TestPPI2IO(t *testing.T) {
	ppi2 := &mockIODevice{}
	mmu := New(nil, ppi2, nil, nil)
	mmu.Write(0xE400, 0x5A)
	if ppi2.regs[0] != 0x5A {
		t.Errorf("PPI2 port A = %02X, want 5A", ppi2.regs[0])
	}
	if mmu.Read(0xE400) != 0x5A {
		t.Errorf("PPI2 port A read = %02X, want 5A", mmu.Read(0xE400))
	}
}

func TestPITIO(t *testing.T) {
	pit := &mockIODevice{}
	mmu := New(nil, nil, pit, nil)
	mmu.Write(0xE800, 0x78)
	if pit.regs[0] != 0x78 {
		t.Errorf("PIT counter 0 = %02X, want 78", pit.regs[0])
	}
	if mmu.Read(0xE800) != 0x78 {
		t.Errorf("PIT counter 0 read = %02X, want 78", pit.regs[0])
	}
}

func TestUARTIO(t *testing.T) {
	uart := &mockIODevice{}
	mmu := New(nil, nil, nil, uart)
	mmu.Write(0xEC00, 0x55)
	if uart.regs[0] != 0x55 {
		t.Errorf("UART data = %02X, want 55", uart.regs[0])
	}
	if mmu.Read(0xEC00) != 0x55 {
		t.Errorf("UART data read = %02X, want 55", mmu.Read(0xEC00))
	}
}

func TestIOWriteWithNilDevice(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	// Writing to I/O with nil devices should not panic.
	mmu.Write(0xE000, 0xFF)
	mmu.Write(0xE400, 0xFF)
	mmu.Write(0xE800, 0xFF)
	mmu.Write(0xEC00, 0xFF)
}

func TestIOReadWithNilDevice(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	// Reading I/O with nil devices should return 0xFF.
	if v := mmu.Read(0xE000); v != 0xFF {
		t.Errorf("nil PPI1 read = %02X, want FF", v)
	}
	if v := mmu.Read(0xE400); v != 0xFF {
		t.Errorf("nil PPI2 read = %02X, want FF", v)
	}
	if v := mmu.Read(0xE800); v != 0xFF {
		t.Errorf("nil PIT read = %02X, want FF", v)
	}
	if v := mmu.Read(0xEC00); v != 0xFF {
		t.Errorf("nil UART read = %02X, want FF", v)
	}
}

func TestPokeROM(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.LoadROM([]byte{0x00}, 0x0000)
	mmu.Poke(0x0000, 0x99)
	if mmu.Peek(0x0000) != 0x99 {
		t.Errorf("Poke ROM = %02X, want 99", mmu.Peek(0x0000))
	}
}

func TestPokeRAM(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.Poke(0x6000, 0x77)
	if mmu.Peek(0x6000) != 0x77 {
		t.Errorf("Poke RAM = %02X, want 77", mmu.Peek(0x6000))
	}
}

func TestPokeIOPassthrough(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	// Poke to an I/O address should be silently ignored.
	mmu.Poke(0xE000, 0x42)
	if mmu.Peek(0xE000) != 0xFF {
		t.Errorf("Poke I/O corrupted memory, got %02X", mmu.Peek(0xE000))
	}
}

func TestLastWriteAddr(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.Write(0x6000, 0xFF)
	if mmu.LastWriteAddr != 0x6000 {
		t.Errorf("LastWriteAddr = %04X, want 6000", mmu.LastWriteAddr)
	}
	// ROM writes should not update LastWriteAddr.
	mmu.Write(0x0000, 0xFF)
	if mmu.LastWriteAddr != 0x6000 {
		t.Errorf("ROM write changed LastWriteAddr to %04X", mmu.LastWriteAddr)
	}
}

func TestLoadDefaultFirmware(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.LoadDefaultFirmware()
	// The embedded firmware is 24576 bytes, matching ROM size.
	if mmu.Read(0x0000) == 0xFF {
		t.Error("LoadDefaultFirmware didn't overwrite ROM default 0xFF")
	}
	// Last byte of firmware should not be 0xFF unless the firmware contains it.
	if mmu.Peek(0x5FFF) == 0xFF {
		t.Log("Note: firmware last byte is 0xFF (may be valid)")
	}
}

func TestLoadFirmwareFrom(t *testing.T) {
	// Write a test firmware file.
	tmp := t.TempDir()
	fwPath := tmp + "/test.bin"
	if err := os.WriteFile(fwPath, []byte{0x11, 0x22, 0x33, 0x44}, 0644); err != nil {
		t.Fatal(err)
	}
	mmu := New(nil, nil, nil, nil)
	if err := mmu.LoadFirmwareFrom(fwPath); err != nil {
		t.Fatalf("LoadFirmwareFrom failed: %v", err)
	}
	if mmu.Read(0x0000) != 0x11 {
		t.Errorf("fw byte 0 = %02X, want 11", mmu.Read(0x0000))
	}
	if mmu.Read(0x0003) != 0x44 {
		t.Errorf("fw byte 3 = %02X, want 44", mmu.Read(0x0003))
	}
}

func TestLoadFirmwareFromNotFound(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	if err := mmu.LoadFirmwareFrom("/nonexistent/firmware.bin"); err == nil {
		t.Error("LoadFirmwareFrom with bad path should error")
	}
}

func TestIOPortDecoding(t *testing.T) {
	// Verify I/O port address decoding (addr & mask).
	ppi1 := &mockIODevice{}
	pit := &mockIODevice{}
	mmu := New(ppi1, nil, pit, nil)

	// PPI1 uses addr & 3 → addresses 0xE000-0xE3FF map to ports 0-3.
	mmu.Write(0xE001, 0x11)
	mmu.Write(0xE005, 0x22) // wraps to port 1 again
	if ppi1.regs[1] != 0x22 {
		t.Errorf("PPI1 addr 0xE005 wrote to port %d = %02X, want 22", 1, ppi1.regs[1])
	}

	// PIT uses addr & 3 → addresses 0xE800-0xEBFF map to ports 0-3.
	mmu.Write(0xE803, 0x33)
	if pit.regs[3] != 0x33 {
		t.Errorf("PIT addr 0xE803 = %02X, want 33", pit.regs[3])
	}
}

func TestReadRomRegion(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.LoadROM([]byte{0xDE, 0xAD, 0xBE, 0xEF}, 0)
	rom := mmu.ReadROM()
	if len(rom) != RomSize {
		t.Errorf("ReadROM length = %d, want %d", len(rom), RomSize)
	}
	if rom[0] != 0xDE || rom[3] != 0xEF {
		t.Errorf("ReadROM content mismatch")
	}
}

func TestReadRamRegion(t *testing.T) {
	mmu := New(nil, nil, nil, nil)
	mmu.Write(0x6000, 0x12)
	mmu.Write(0x67FF, 0x34)
	ram := mmu.ReadRAM()
	if len(ram) != RamSize {
		t.Errorf("ReadRAM length = %d, want %d", len(ram), RamSize)
	}
	if ram[0] != 0x12 {
		t.Errorf("ReadRAM[0] = %02X, want 12", ram[0])
	}
	if ram[RamSize-1] != 0x34 {
		t.Errorf("ReadRAM[last] = %02X, want 34", ram[RamSize-1])
	}
}
