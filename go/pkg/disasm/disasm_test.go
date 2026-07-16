package disasm

import "testing"

func TestDisassemble(t *testing.T) {
	mem := []uint8{
		0x00,             // NOP
		0x01, 0x34, 0x12, // LXI B, 0x1234
		0x41,             // MOV B, C
		0xc3, 0x78, 0x56, // JMP 0x5678
		0x76,             // HLT
		0x3e, 0x42,       // MVI A, 0x42
		0xdb, 0x01,       // IN 0x01
		0xc7,             // RST 0
		0xcd, 0xef, 0xbe, // CALL 0xBEEF
		0xff,             // RST 7
	}
	readByte := func(addr uint16) uint8 {
		if int(addr) < len(mem) {
			return mem[addr]
		}
		return 0
	}

	tests := []struct {
		addr     uint16
		expected [3]string
	}{
		{0, [3]string{"NOP", "LXI B, 0x1234", "MOV B, C"}},
		{4, [3]string{"MOV B, C", "JMP, 0x5678", "HLT"}},
		{9, [3]string{"MVI A, 0x42", "IN, 0x01", "RST 0"}},
		{0x0E, [3]string{"CALL, 0xBEEF", "RST 7", "NOP"}},
	}

	for _, tc := range tests {
		result := Disassemble(tc.addr, readByte)
		for i := range result {
			if result[i].Mnemonic != tc.expected[i] {
				t.Errorf("addr 0x%04X insn %d: got %q, want %q",
					tc.addr, i, result[i].Mnemonic, tc.expected[i])
			}
		}
	}
}

func TestDisassembleBytes(t *testing.T) {
	mem := []uint8{
		0x01, 0x34, 0x12, // LXI B, 0x1234
		0x00, // NOP
		0x41, // MOV B, C
	}
	readByte := func(addr uint16) uint8 {
		if int(addr) < len(mem) {
			return mem[addr]
		}
		return 0
	}

	result := Disassemble(0, readByte)

	// LXI B — bytes [0x01, 0x34, 0x12]
	if result[0].Length != 3 {
		t.Errorf("LXI B length: got %d, want 3", result[0].Length)
	}
	if result[0].Address != 0 {
		t.Errorf("LXI B address: got 0x%04X, want 0x0000", result[0].Address)
	}
	if len(result[0].Bytes) != 3 || result[0].Bytes[0] != 0x01 || result[0].Bytes[1] != 0x34 || result[0].Bytes[2] != 0x12 {
		t.Errorf("LXI B bytes: got %v, want [0x01 0x34 0x12]", result[0].Bytes)
	}

	// NOP follows — address should be 3
	if result[1].Address != 3 {
		t.Errorf("NOP address: got 0x%04X, want 0x0003", result[1].Address)
	}
	if result[1].Length != 1 {
		t.Errorf("NOP length: got %d, want 1", result[1].Length)
	}

	// MOV B,C
	if result[2].Address != 4 {
		t.Errorf("MOV B,C address: got 0x%04X, want 0x0004", result[2].Address)
	}
}

func TestDisassembleAllOpcodesCovered(t *testing.T) {
	// Verify every opcode produces exactly one entry
	var seen [256]bool
	for op, entry := range opTable {
		if entry.size < 1 || entry.size > 3 {
			t.Errorf("opcode 0x%02X: invalid size %d", op, entry.size)
		}
		if entry.mnemonic == "" {
			t.Errorf("opcode 0x%02X: empty mnemonic", op)
		}
		seen[op] = true
	}
	for op := range 256 {
		if !seen[op] {
			t.Errorf("opcode 0x%02X: not covered in table", op)
		}
	}
}
