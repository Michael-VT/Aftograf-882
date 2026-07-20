// Package memory implements the Aftograf-882 memory map.
//
// Memory regions:
//
//	0x0000-0x5FFF  ROM (24 KB, D2764A EPROMs, read-only)
//	0x6000-0x67FF  RAM  (2 KB, KP537PY10)
//	0xE000-0xE3FF  PPI1 (KP580BB55A #1)
//	0xE400-0xE7FF  PPI2 (KP580BB55A #2)
//	0xE800-0xEBFF  PIT  (KP580BM53)
//	0xEC00-0xEFFF  USART (KP580BB51A)
package memory

import (
	_ "embed"
	"os"
	"path/filepath"
)

//go:embed assets/firmware.bin
var firmwareData []byte

// Memory map constants.
const (
	RomStart = 0x0000
	RomEnd   = 0x5FFF
	RomSize  = 0x6000 // 24 KB

	RamStart = 0x6000
	RamEnd   = 0x67FF
	RamSize  = 0x0800 // 2 KB

	PPI1Base = 0xE000
	PPI1End  = 0xE3FF
	PPI2Base = 0xE400
	PPI2End  = 0xE7FF
	PITBase  = 0xE800
	PITEnd   = 0xEBFF
	UARTBase = 0xEC00
	UARTEnd  = 0xEFFF

	MemorySize = 0x10000 // 64 KB address space
)

// IODevice is implemented by memory-mapped peripherals.
type IODevice interface {
	Read(port int) uint8
	Write(port int, val uint8)
}

// AccessKind identifies the direction of a memory-mapped peripheral access.
type AccessKind uint8

const (
	AccessRead AccessKind = iota
	AccessWrite
)

// AccessEvent describes one access to the mapped peripheral address space.
// It is deliberately emitted by MMU, rather than by individual devices, so
// the debugger can stop on PPI, PIT and USART accesses uniformly.
type AccessEvent struct {
	Addr  uint16
	Port  int
	Kind  AccessKind
	Value uint8
}

// MMU manages the system memory map.
type MMU struct {
	memory [MemorySize]byte
	ppi1   IODevice
	ppi2   IODevice
	pit    IODevice
	uart   IODevice

	// LastWriteAddr holds the last RAM write address (for debug views).
	LastWriteAddr uint16
	// OnInvalidWrite, if set, is called when a write targets ROM.
	OnInvalidWrite func(addr uint16, val uint8)
	// OnAccess, if set, receives every mapped peripheral read or write.
	OnAccess func(AccessEvent)
}

// New creates an MMU with the given I/O devices. Devices may be nil.
func New(ppi1, ppi2, pit, uart IODevice) *MMU {
	m := &MMU{ppi1: ppi1, ppi2: ppi2, pit: pit, uart: uart}
	// Fill ROM area with 0xFF (unprogrammed EPROM reads as 0xFF).
	for i := RomStart; i <= RomEnd; i++ {
		m.memory[i] = 0xFF
	}
	return m
}

// LoadROM copies data into ROM at the given offset.  Data is truncated if it
// exceeds available ROM space.
func (m *MMU) LoadROM(data []byte, offset uint16) {
	if int(offset) >= RomSize {
		return
	}
	copy(m.memory[offset:], data)
}

// LoadDefaultFirmware loads the embedded firmware.bin at address 0.
func (m *MMU) LoadDefaultFirmware() {
	m.LoadROM(firmwareData, 0)
}

// LoadFirmwareFrom loads firmware from a file path at address 0.
func (m *MMU) LoadFirmwareFrom(path string) error {
	data, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		return err
	}
	m.LoadROM(data, 0)
	return nil
}

// Read reads a byte from the given address.  I/O reads return 0xFF when
// the corresponding device is nil.
func (m *MMU) Read(addr uint16) uint8 {
	switch {
	case addr <= RomEnd:
		return m.memory[addr]
	case addr >= RamStart && addr <= RamEnd:
		return m.memory[addr]
	case addr >= PPI1Base && addr <= PPI1End:
		value := uint8(0xFF)
		if m.ppi1 != nil {
			value = m.ppi1.Read(int(addr & 3))
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessRead, Value: value})
		return value
	case addr >= PPI2Base && addr <= PPI2End:
		value := uint8(0xFF)
		if m.ppi2 != nil {
			value = m.ppi2.Read(int(addr & 3))
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessRead, Value: value})
		return value
	case addr >= PITBase && addr <= PITEnd:
		value := uint8(0xFF)
		if m.pit != nil {
			value = m.pit.Read(int(addr & 3))
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessRead, Value: value})
		return value
	case addr >= UARTBase && addr <= UARTEnd:
		value := uint8(0xFF)
		if m.uart != nil {
			value = m.uart.Read(int(addr & 1))
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 1), Kind: AccessRead, Value: value})
		return value
	}
	return 0xFF
}

// Write writes a byte to the given address.
//
// ROM writes are silently ignored (with an optional OnInvalidWrite callback).
// Unmapped addresses are silently ignored.
func (m *MMU) Write(addr uint16, val uint8) {
	switch {
	case addr <= RomEnd:
		if m.OnInvalidWrite != nil {
			m.OnInvalidWrite(addr, val)
		}
	case addr >= RamStart && addr <= RamEnd:
		m.memory[addr] = val
		m.LastWriteAddr = addr
	case addr >= PPI1Base && addr <= PPI1End:
		if m.ppi1 != nil {
			m.ppi1.Write(int(addr&3), val)
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessWrite, Value: val})
	case addr >= PPI2Base && addr <= PPI2End:
		if m.ppi2 != nil {
			m.ppi2.Write(int(addr&3), val)
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessWrite, Value: val})
	case addr >= PITBase && addr <= PITEnd:
		if m.pit != nil {
			m.pit.Write(int(addr&3), val)
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 3), Kind: AccessWrite, Value: val})
	case addr >= UARTBase && addr <= UARTEnd:
		if m.uart != nil {
			m.uart.Write(int(addr&1), val)
		}
		m.notifyAccess(AccessEvent{Addr: addr, Port: int(addr & 1), Kind: AccessWrite, Value: val})
	}
}

func (m *MMU) notifyAccess(event AccessEvent) {
	if m.OnAccess != nil {
		m.OnAccess(event)
	}
}

// Peek reads a byte without I/O side effects.  Returns 0xFF for I/O or
// unmapped addresses.
func (m *MMU) Peek(addr uint16) uint8 {
	switch {
	case addr <= RomEnd:
		return m.memory[addr]
	case addr >= RamStart && addr <= RamEnd:
		return m.memory[addr]
	default:
		return 0xFF
	}
}

// Poke writes a byte directly to ROM or RAM, bypassing I/O routing.
// Writes to I/O or unmapped addresses are silently ignored.
func (m *MMU) Poke(addr uint16, val uint8) {
	switch {
	case addr <= RomEnd:
		m.memory[addr] = val
	case addr >= RamStart && addr <= RamEnd:
		m.memory[addr] = val
	}
}

// ReadROM returns a read-only slice of the ROM region.
func (m *MMU) ReadROM() []byte {
	return m.memory[RomStart : RomEnd+1]
}

// ReadRAM returns a read-only slice of the RAM region.
func (m *MMU) ReadRAM() []byte {
	return m.memory[RamStart : RamEnd+1]
}

// LoadRAM restores a RAM snapshot. Extra bytes are ignored and missing bytes
// are cleared, making sessions portable between compatible builds.
func (m *MMU) LoadRAM(data []byte) {
	m.ClearRAM()
	copy(m.memory[RamStart:RamEnd+1], data)
}

// ClearRAM resets all RAM bytes without touching ROM or I/O devices.
func (m *MMU) ClearRAM() {
	for i := RamStart; i <= RamEnd; i++ {
		m.memory[i] = 0
	}
	m.LastWriteAddr = 0
}
