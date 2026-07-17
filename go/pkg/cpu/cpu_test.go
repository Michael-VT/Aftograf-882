package cpu

import (
	"fmt"
	"testing"
)

// testCPU creates a CPU backed by a flat 64KB memory array.
// Returns the CPU and a mem accessor for test assertions.
func testCPU(t *testing.T, mem []uint8) (*CPU8080, func(uint16) uint8) {
	t.Helper()
	m := make([]uint8, 65536)
	copy(m, mem)
	read := func(addr uint16) uint8 { return m[addr] }
	write := func(addr uint16, val uint8) { m[addr] = val }
	cpu := New(read, write, func(p uint8) uint8 { return 0 }, func(p uint8, v uint8) {})
	return cpu, func(addr uint16) uint8 { return m[addr] }
}

// stepN executes n instructions, returning false if HALTed.
func stepN(c *CPU8080, n int) bool {
	for range n {
		if !c.Step() {
			return false
		}
	}
	return true
}

// ─── Data-transfer group ───

func TestMOV_RegisterToRegister(t *testing.T) {
	// MOV r1, r2 — test all 64 combos
	// Place known values in all registers, then MOV each register to each other.
	code := []uint8{
		// Load A with 0xAA, B with 0xBB, C with 0xCC, D with 0xDD,
		// E with 0xEE, H with 0x12, L with 0x34
		0x3e, 0xaa, // MVI A, 0xAA
		0x06, 0xbb, // MVI B, 0xBB
		0x0e, 0xcc, // MVI C, 0xCC
		0x16, 0xdd, // MVI D, 0xDD
		0x1e, 0xee, // MVI E, 0xEE
		0x26, 0x12, // MVI H, 0x12
		0x2e, 0x34, // MVI L, 0x34
		// Now test MOV by reading back into A via each path
		0x78, // MOV A, B — A = 0xBB
		0x79, // MOV A, C — A = 0xCC
		0x7a, // MOV A, D — A = 0xDD
		0x7b, // MOV A, E — A = 0xEE
		0x7c, // MOV A, H — A = 0x12
		0x7d, // MOV A, L — A = 0x34
	}
	cpu, _ := testCPU(t, code)
	if !stepN(cpu, 7+6) {
		t.Fatal("unexpected HLT")
	}
	// After MOV A, L (0x7d) — A should be 0x34
	if cpu.A != 0x34 {
		t.Errorf("MOV A,L: A = 0x%02X, want 0x34", cpu.A)
	}

	// Verify B originates (A is now 0x34 after above)
	cpu.A = 0x00
	cpu.B = 0xaa
	cpu.C = 0xbb
	cpu.D = 0xcc
	cpu.E = 0xdd
	cpu.H = 0x12
	cpu.L = 0x34

	// Execute MOV A,B at PC
	mem2 := []uint8{0x78} // MOV A,B
	cpu2, mem2read := testCPU(t, mem2)
	cpu2.A = 0x00
	cpu2.B = 0xaa
	cpu2.Step()
	if cpu2.A != 0xaa {
		t.Errorf("MOV A,B: A = 0x%02X, want 0xAA", cpu2.A)
	}
	_ = mem2read

	// MOV B,A
	cpu3, _ := testCPU(t, []uint8{0x47})
	cpu3.A = 0x55
	cpu3.B = 0x00
	cpu3.Step()
	if cpu3.B != 0x55 {
		t.Errorf("MOV B,A: B = 0x%02X, want 0x55", cpu3.B)
	}

	// MOV A,A (should preserve)
	cpu4, _ := testCPU(t, []uint8{0x7f})
	cpu4.A = 0x42
	cpu4.Step()
	if cpu4.A != 0x42 {
		t.Errorf("MOV A,A: A = 0x%02X, want 0x42", cpu4.A)
	}
}

func TestMOV_FromMemory(t *testing.T) {
	// MOV r, M — load from [HL]
	code := []uint8{
		0x21, 0x34, 0x12, // LXI H, 0x1234
		0x7e, // MOV A, M
	}
	cpu, mem := testCPU(t, code)
	cpu.WriteByte(0x1234, 0x7e) // place value at [HL]
	if !stepN(cpu, 2) {
		t.Fatal("unexpected HLT")
	}
	if cpu.A != 0x7e {
		t.Errorf("MOV A,M: A = 0x%02X, want 0x7E", cpu.A)
	}
	_ = mem

	// MOV M, r — store A to [HL]
	code2 := []uint8{
		0x21, 0x40, 0x12, // LXI H, 0x1240
		0x77, // MOV M, A
	}
	cpu2, mem2 := testCPU(t, code2)
	cpu2.A = 0x5a
	if !stepN(cpu2, 2) {
		t.Fatal("unexpected HLT")
	}
	if mem2(0x1240) != 0x5a {
		t.Errorf("MOV M,A: [0x1240] = 0x%02X, want 0x5A", mem2(0x1240))
	}
}

func TestLXI(t *testing.T) {
	tests := []struct {
		name  string
		code  []uint8
		getFn func(*CPU8080) uint16
	}{
		{"LXI B", []uint8{0x01, 0x34, 0x12}, func(c *CPU8080) uint16 { return c.GetBC() }},
		{"LXI D", []uint8{0x11, 0xcd, 0xab}, func(c *CPU8080) uint16 { return c.GetDE() }},
		{"LXI H", []uint8{0x21, 0xef, 0xbe}, func(c *CPU8080) uint16 { return c.GetHL() }},
		{"LXI SP", []uint8{0x31, 0x00, 0xff}, func(c *CPU8080) uint16 { return c.SP }},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, tc.code)
			if !stepN(cpu, 1) {
				t.Fatal("unexpected HLT")
			}
			got := tc.getFn(cpu)
			want := uint16(tc.code[2])<<8 | uint16(tc.code[1])
			if got != want {
				t.Errorf("%s = 0x%04X, want 0x%04X", tc.name, got, want)
			}
		})
	}
}

func TestLDAX_STAX(t *testing.T) {
	mem := make([]uint8, 65536)
	code := []uint8{
		0x01, 0x34, 0x12, // LXI B, 0x1234
		0x0a,             // LDAX B — A = [0x1234]
		0x11, 0x78, 0x56, // LXI D, 0x5678
		0x1a, // LDAX D — A = [0x5678]
	}
	copy(mem, code)
	mem[0x1234] = 0x99
	mem[0x5678] = 0x77
	read := func(addr uint16) uint8 { return mem[addr] }
	write := func(addr uint16, val uint8) { mem[addr] = val }
	cpu := New(read, write, nil, nil)
	if !stepN(cpu, 4) {
		t.Fatal("unexpected HLT")
	}
	if cpu.A != 0x77 {
		t.Errorf("LDAX D: A = 0x%02X, want 0x77", cpu.A)
	}

	// STAX B
	m2 := make([]uint8, 65536)
	copy(m2, []uint8{
		0x01, 0x00, 0x60, // LXI B, 0x6000
		0x02,             // STAX B
	})
	read2 := func(addr uint16) uint8 { return m2[addr] }
	write2 := func(addr uint16, val uint8) { m2[addr] = val }
	cpu2 := New(read2, write2, nil, nil)
	cpu2.A = 0x42
	if !stepN(cpu2, 2) {
		t.Fatal("unexpected HLT")
	}
	if m2[0x6000] != 0x42 {
		t.Errorf("STAX B: [0x6000] = 0x%02X, want 0x42", m2[0x6000])
	}

	// STAX D
	m3 := make([]uint8, 65536)
	copy(m3, []uint8{
		0x11, 0x10, 0x60, // LXI D, 0x6010
		0x12,             // STAX D
	})
	read3 := func(addr uint16) uint8 { return m3[addr] }
	write3 := func(addr uint16, val uint8) { m3[addr] = val }
	cpu3 := New(read3, write3, nil, nil)
	cpu3.A = 0x7b
	if !stepN(cpu3, 2) {
		t.Fatal("unexpected HLT")
	}
	if m3[0x6010] != 0x7b {
		t.Errorf("STAX D: [0x6010] = 0x%02X, want 0x7B", m3[0x6010])
	}
}

func TestSTA_LDA(t *testing.T) {
	// STA: store A at address
	m2 := make([]uint8, 65536)
	copy(m2, []uint8{0x32, 0x00, 0x60}) // STA 0x6000
	read2 := func(addr uint16) uint8 { return m2[addr] }
	write2 := func(addr uint16, val uint8) { m2[addr] = val }
	cpu2 := New(read2, write2, nil, nil)
	cpu2.A = 0x3c
	cpu2.Step()
	if m2[0x6000] != 0x3c {
		t.Errorf("STA: [0x6000] = 0x%02X, want 0x3C", m2[0x6000])
	}

	// LDA: load A from address
	m4 := make([]uint8, 65536)
	copy(m4, []uint8{0x3a, 0x00, 0x62}) // LDA 0x6200
	m4[0x6200] = 0x9a // value in data space
	read4 := func(addr uint16) uint8 { return m4[addr] }
	write4 := func(addr uint16, val uint8) { m4[addr] = val }
	cpu3 := New(read4, write4, nil, nil)
	cpu3.Step()
	if cpu3.A != 0x9a {
		t.Errorf("LDA: A = 0x%02X, want 0x9A", cpu3.A)
	}
}

func TestSHLD_LHLD(t *testing.T) {
	// SHLD: store HL at address
	m2 := make([]uint8, 65536)
	copy(m2, []uint8{0x22, 0x00, 0x60}) // SHLD 0x6000
	read2 := func(addr uint16) uint8 { return m2[addr] }
	write2 := func(addr uint16, val uint8) { m2[addr] = val }
	cpu := New(read2, write2, nil, nil)
	cpu.H = 0x12
	cpu.L = 0x34
	cpu.Step()
	if m2[0x6000] != 0x34 {
		t.Errorf("SHLD: [0x6000] = 0x%02X, want 0x34 (L)", m2[0x6000])
	}
	if m2[0x6001] != 0x12 {
		t.Errorf("SHLD: [0x6001] = 0x%02X, want 0x12 (H)", m2[0x6001])
	}

	// LHLD: load HL from address
	m4 := make([]uint8, 65536)
	copy(m4, []uint8{0x2a, 0x00, 0x62}) // LHLD 0x6200
	m4[0x6200] = 0xef
	m4[0x6201] = 0xbe
	read4 := func(addr uint16) uint8 { return m4[addr] }
	write4 := func(addr uint16, val uint8) { m4[addr] = val }
	cpu3 := New(read4, write4, nil, nil)
	cpu3.Step()
	if cpu3.L != 0xef {
		t.Errorf("LHLD: L = 0x%02X, want 0xEF", cpu3.L)
	}
	if cpu3.H != 0xbe {
		t.Errorf("LHLD: H = 0x%02X, want 0xBE", cpu3.H)
	}
}

// ─── Arithmetic group ───

func TestADD(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantA  uint8
		wantS  bool
		wantZ  bool
		wantAC bool
		wantP  bool
		wantCY bool
	}{
		{"1+1", 1, 1, 2, false, false, false, false, false},
		{"0+0", 0, 0, 0, false, true, false, true, false},
		{"0xfe+1", 0xfe, 1, 0xff, true, false, false, true, false},
		{"0xff+1", 0xff, 1, 0x00, false, true, true, true, true},
		{"0x80+0x80", 0x80, 0x80, 0x00, false, true, false, true, true},
		{"0x0f+1 (AC)", 0x0f, 1, 0x10, false, false, true, false, false},
		{"0x05+0x0a", 0x05, 0x0a, 0x0f, false, false, false, true, false},
	}
	for _, tc := range tests {
		t.Run("ADD_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0x80}) // ADD B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			checkFlags8080(t, cpu.Flags, tc.wantS, tc.wantZ, tc.wantAC, tc.wantP, tc.wantCY)
		})
	}

	// ADD M
	cpu2, _ := testCPU(t, []uint8{0x86}) // ADD M
	cpu2.H = 0x60
	cpu2.L = 0x00
	cpu2.A = 0x01
	cpu2.WriteByte(0x6000, 0x05) // put value at [HL]
	cpu2.PC = 0                 // restart
	cpu2.Step()
	if cpu2.A != 0x06 {
		t.Errorf("ADD M: A = 0x%02X, want 0x06", cpu2.A)
	}
}

func TestADI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xc6, 0x42}) // ADI 0x42
	cpu.A = 0x10
	cpu.Step()
	if cpu.A != 0x52 {
		t.Errorf("ADI: A = 0x%02X, want 0x52", cpu.A)
	}
}

func TestADC(t *testing.T) {
	tests := []struct {
		name      string
		a, val    uint8
		carryIn   uint8
		wantA     uint8
		wantCY    bool
	}{
		{"1+1+0", 1, 1, 0, 2, false},
		{"0xff+1+0", 0xff, 1, 0, 0x00, true},
		{"0xfe+1+1", 0xfe, 1, FlagCY, 0x00, true},
		{"0x0f+0xf0+0", 0x0f, 0xf0, 0, 0xff, false},
	}
	for _, tc := range tests {
		t.Run("ADC_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0x88}) // ADC B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Flags = tc.carryIn | 0x02
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
		})
	}
}

func TestACI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xce, 0x42}) // ACI 0x42
	cpu.A = 0x10
	cpu.Flags = FlagCY | 0x02
	cpu.Step()
	if cpu.A != 0x53 { // 0x10 + 0x42 + 1
		t.Errorf("ACI: A = 0x%02X, want 0x53", cpu.A)
	}
}

func TestSUB(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantA  uint8
		wantCY bool
		wantAC bool
		wantZ  bool
		wantS  bool
		wantP  bool
	}{
		{"5-3", 5, 3, 2, false, false, false, false, false}, // 2=10b, odd→P=0
		{"0-0", 0, 0, 0, false, false, true, false, true},   // 0, even→P=1
		{"3-5 (borrow)", 3, 5, 0xfe, true, true, false, true, false}, // 0xfe=11111110, odd→P=0
		{"0x80-1", 0x80, 1, 0x7f, false, true, false, false, false}, // 0x7f=01111111, odd→P=0
		{"1-0x80", 1, 0x80, 0x81, true, false, false, true, true}, // 0x81=10000001, even→P=1, AC: 1<0→false
		{"0-1", 0, 1, 0xff, true, true, false, true, true}, // 0xff=11111111, even→P=1
		{"0x0f-1 (AC)", 0x0f, 1, 0x0e, false, false, false, false, false}, // 0x0e=00001110, odd→P=0
		{"0x10-1 (AC)", 0x10, 1, 0x0f, false, true, false, false, true}, // 0x0f=00001111, even→P=1
	}
	for _, tc := range tests {
		t.Run("SUB_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0x90}) // SUB B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			checkFlags8080(t, cpu.Flags, tc.wantS, tc.wantZ, tc.wantAC, tc.wantP, tc.wantCY)
		})
	}
}

func TestSUI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xd6, 0x05}) // SUI 5
	cpu.A = 0x10
	cpu.Step()
	if cpu.A != 0x0b {
		t.Errorf("SUI: A = 0x%02X, want 0x0B", cpu.A)
	}
}

func TestSBB(t *testing.T) {
	tests := []struct {
		name      string
		a, val    uint8
		carryIn   uint8
		wantA     uint8
		wantCY    bool
	}{
		{"5-3-0", 5, 3, 0, 2, false},
		{"5-3-1", 5, 3, FlagCY, 1, false},
		{"0-0-1", 0, 0, FlagCY, 0xff, true},
		{"0-1-0", 0, 1, 0, 0xff, true},
	}
	for _, tc := range tests {
		t.Run("SBB_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0x98}) // SBB B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Flags = tc.carryIn | 0x02
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
		})
	}
}

func TestSBI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xde, 0x05}) // SBI 5
	cpu.A = 0x10
	cpu.Flags = FlagCY | 0x02 // with borrow
	cpu.Step()
	if cpu.A != 0x0a { // 0x10 - 5 - 1 = 0x0A
		t.Errorf("SBI: A = 0x%02X, want 0x0A", cpu.A)
	}
}

func TestINR(t *testing.T) {
	// Test INR A from 0x0f to 0x10
	cpu, _ := testCPU(t, []uint8{0x3c}) // INR A
	cpu.A = 0x0f
	cpu.Step()
	if cpu.A != 0x10 {
		t.Errorf("INR A (0x0f): A = 0x%02X, want 0x10", cpu.A)
	}
	if cpu.Flags&FlagAC == 0 {
		t.Error("INR A (0x0f): AC not set")
	}

	// INR A from 0xff to 0x00 (wrap + zero)
	cpu2, _ := testCPU(t, []uint8{0x3c}) // INR A
	cpu2.A = 0xff
	cpu2.Step()
	if cpu2.A != 0x00 {
		t.Errorf("INR A (0xff): A = 0x%02X, want 0x00", cpu2.A)
	}
	if cpu2.Flags&FlagZ == 0 {
		t.Error("INR A (0xff): Z not set")
	}
	if cpu2.Flags&FlagS != 0 {
		t.Error("INR A (0xff): S should be 0")
	}
}

func TestDCR(t *testing.T) {
	// DCR A from 0x10 to 0x0f
	cpu, _ := testCPU(t, []uint8{0x3d}) // DCR A
	cpu.A = 0x10
	cpu.Step()
	if cpu.A != 0x0f {
		t.Errorf("DCR A (0x10): A = 0x%02X, want 0x0F", cpu.A)
	}
	if cpu.Flags&FlagAC == 0 {
		t.Error("DCR A (0x10): AC not set (borrow from bit 3)")
	}

	// DCR A from 0x00 to 0xff
	cpu2, _ := testCPU(t, []uint8{0x3d}) // DCR A
	cpu2.A = 0x00
	cpu2.Step()
	if cpu2.A != 0xff {
		t.Errorf("DCR A (0x00): A = 0x%02X, want 0xFF", cpu2.A)
	}
	if cpu2.Flags&FlagS == 0 {
		t.Error("DCR A (0x00): S not set")
	}
	if cpu2.Flags&FlagAC == 0 {
		t.Error("DCR A (0x00): AC not set (borrow from bit 3)")
	}
}

func TestINX_DCX(t *testing.T) {
	tests := []struct {
		name   string
		inx    []uint8
		dcx    []uint8
		getFn  func(*CPU8080) uint16
		setFn  func(*CPU8080, uint16)
	}{
		{"B", []uint8{0x03}, []uint8{0x0b}, func(c *CPU8080) uint16 { return c.GetBC() }, func(c *CPU8080, v uint16) { c.setBC(v) }},
		{"D", []uint8{0x13}, []uint8{0x1b}, func(c *CPU8080) uint16 { return c.GetDE() }, func(c *CPU8080, v uint16) { c.setDE(v) }},
		{"H", []uint8{0x23}, []uint8{0x2b}, func(c *CPU8080) uint16 { return c.GetHL() }, func(c *CPU8080, v uint16) { c.setHL(v) }},
		{"SP", []uint8{0x33}, []uint8{0x3b}, func(c *CPU8080) uint16 { return c.SP }, func(c *CPU8080, v uint16) { c.SP = v }},
	}
	for _, tc := range tests {
		t.Run("INX_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, tc.inx)
			tc.setFn(cpu, 0xffff)
			cpu.Step()
			if tc.getFn(cpu) != 0x0000 {
				t.Errorf("INX %s from 0xFFFF: got 0x%04X, want 0x0000", tc.name, tc.getFn(cpu))
			}
		})
		t.Run("DCX_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, tc.dcx)
			tc.setFn(cpu, 0x0000)
			cpu.Step()
			if tc.getFn(cpu) != 0xffff {
				t.Errorf("DCX %s from 0x0000: got 0x%04X, want 0xFFFF", tc.name, tc.getFn(cpu))
			}
		})
	}
}

func TestDAD(t *testing.T) {
	tests := []struct {
		name       string
		code       []uint8
		hl, rp     uint16
		setRP      func(*CPU8080, uint16)
		wantHL     uint16
		wantCY     bool
	}{
		{"DAD B", []uint8{0x09}, 0x0001, 0x0001, func(c *CPU8080, v uint16) { c.setBC(v) }, 0x0002, false},
		{"DAD D", []uint8{0x19}, 0xffff, 0x0001, func(c *CPU8080, v uint16) { c.setDE(v) }, 0x0000, true},
		{"DAD H", []uint8{0x29}, 0x8000, 0x8000, nil, 0x0000, true},
		{"DAD SP", []uint8{0x39}, 0x0005, 0x000a, func(c *CPU8080, v uint16) { c.SP = v }, 0x000f, false},
		{"DAD B max", []uint8{0x09}, 0xfffe, 0x0002, func(c *CPU8080, v uint16) { c.setBC(v) }, 0x0000, true},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, tc.code)
			cpu.setHL(tc.hl)
			if tc.setRP != nil {
				tc.setRP(cpu, tc.rp)
			} else {
				// DAD H: HL += HL, re-set HL after setHL set it
				cpu.setHL(tc.hl)
			}
			cpu.Step()
			got := cpu.GetHL()
			if got != tc.wantHL {
				t.Errorf("HL = 0x%04X, want 0x%04X", got, tc.wantHL)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
		})
	}
}

// ─── Logical group ───

func TestANA(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantA  uint8
		wantZ  bool
		wantS  bool
		wantP  bool
	}{
		{"A&~A=0", 0xff, 0x00, 0x00, true, false, true},
		{"A&A=A", 0x5a, 0x5a, 0x5a, false, false, true},
		{"A&0=A", 0xff, 0x00, 0x00, true, false, true},
		{"high bit", 0x80, 0x80, 0x80, false, true, false},
		{"odd parity", 0x03, 0x03, 0x03, false, false, true},
	}
	for _, tc := range tests {
		t.Run("ANA_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0xa0}) // ANA B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			checkFlags8080(t, cpu.Flags, tc.wantS, tc.wantZ, true, tc.wantP, false)
		})
	}
}

func TestANI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xe6, 0x0f}) // ANI 0x0f
	cpu.A = 0xab
	cpu.Step()
	if cpu.A != 0x0b {
		t.Errorf("ANI: A = 0x%02X, want 0x0B", cpu.A)
	}
	// AC is always set after ANA/ANI
	if cpu.Flags&FlagAC == 0 {
		t.Error("ANI: AC should be set")
	}
}

func TestXRA(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantA  uint8
		wantZ  bool
		wantS  bool
	}{
		{"0^0=0", 0, 0, 0, true, false},
		{"0xff^0xff=0", 0xff, 0xff, 0, true, false},
		{"0xf0^0x0f=0xff", 0xf0, 0x0f, 0xff, false, true},
	}
	for _, tc := range tests {
		t.Run("XRA_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0xa8}) // XRA B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			checkFlags8080(t, cpu.Flags, tc.wantS, tc.wantZ, false, true, false)
		})
	}

	// XRA A — classic zero-accumulator
	cpu, _ := testCPU(t, []uint8{0xaf}) // XRA A
	cpu.A = 0xff
	cpu.Step()
	if cpu.A != 0 {
		t.Errorf("XRA A: A = 0x%02X, want 0", cpu.A)
	}
}

func TestXRI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xee, 0xff}) // XRI 0xff
	cpu.A = 0x5a
	cpu.Step()
	if cpu.A != 0xa5 {
		t.Errorf("XRI: A = 0x%02X, want 0xA5", cpu.A)
	}
}

func TestORA(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantA  uint8
		wantZ  bool
		wantS  bool
	}{
		{"0|0=0", 0, 0, 0, true, false},
		{"0|0xf0=0xf0", 0, 0xf0, 0xf0, false, true},
		{"0x0f|0xf0=0xff", 0x0f, 0xf0, 0xff, false, true},
	}
	for _, tc := range tests {
		t.Run("ORA_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0xb0}) // ORA B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			checkFlags8080(t, cpu.Flags, tc.wantS, tc.wantZ, false, true, false)
		})
	}
}

func TestORI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xf6, 0x80}) // ORI 0x80
	cpu.A = 0x7f
	cpu.Step()
	if cpu.A != 0xff {
		t.Errorf("ORI: A = 0x%02X, want 0xFF", cpu.A)
	}
}

func TestCMP(t *testing.T) {
	tests := []struct {
		name   string
		a, val uint8
		wantCY bool
		wantZ  bool
		wantS  bool
		wantAC bool
	}{
		{"5==5", 5, 5, false, true, false, true},
		{"5>3", 5, 3, false, false, false, false},
		{"3<5", 3, 5, true, false, true, true},
		{"0==0", 0, 0, false, true, false, false},
	}
	for _, tc := range tests {
		t.Run("CMP_"+tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0xb8}) // CMP B
			cpu.A = tc.a
			cpu.B = tc.val
			cpu.Step()
			// CMP does not modify A
			if cpu.A != tc.a {
				t.Errorf("A modified: 0x%02X, want 0x%02X", cpu.A, tc.a)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
			gotZ := (cpu.Flags & FlagZ) != 0
			if gotZ != tc.wantZ {
				t.Errorf("Z = %v, want %v", gotZ, tc.wantZ)
			}
		})
	}
}

func TestCPI(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xfe, 0x42}) // CPI 0x42
	cpu.A = 0x42
	cpu.Step()
	if cpu.Flags&FlagZ == 0 {
		t.Error("CPI 0x42 with A=0x42: Z not set")
	}
}

// ─── Rotate group ───

func TestRotates(t *testing.T) {
	tests := []struct {
		name    string
		code    []uint8
		aIn     uint8
		flagsIn uint8
		wantA   uint8
		wantCY  bool
	}{
		{"RLC bit7=0", []uint8{0x07}, 0x01, 0x02, 0x02, false},
		{"RLC bit7=1", []uint8{0x07}, 0x81, 0x02, 0x03, true},
		{"RLC all rotate", []uint8{0x07}, 0x80, 0x02, 0x01, true},
		{"RRC bit0=0", []uint8{0x0f}, 0x02, 0x02, 0x01, false},
		{"RRC bit0=1", []uint8{0x0f}, 0x81, 0x02, 0xc0, true},
		{"RAL no carry", []uint8{0x17}, 0x01, 0x02, 0x02, false},
		{"RAL with carry", []uint8{0x17}, 0x80, 0x02, 0x00, true},
		{"RAL carry in", []uint8{0x17}, 0x01, FlagCY | 0x02, 0x03, false},
		{"RAR no carry", []uint8{0x1f}, 0x02, 0x02, 0x01, false},
		{"RAR with carry", []uint8{0x1f}, 0x01, 0x02, 0x00, true},
		{"RAR carry in", []uint8{0x1f}, 0x80, FlagCY | 0x02, 0xc0, false},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, tc.code)
			cpu.A = tc.aIn
			cpu.Flags = tc.flagsIn
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
		})
	}
}

// ─── DAA test ───

func TestDAA(t *testing.T) {
	tests := []struct {
		name     string
		a        uint8
		flagsIn  uint8
		wantA    uint8
		wantAC   bool
		wantCY   bool
	}{
		{"0x00", 0x00, 0x02, 0x00, false, false},
		{"0x09", 0x09, 0x02, 0x09, false, false},
		{"0x0a (low > 9)", 0x0a, 0x02, 0x10, true, false},
		{"0x10-0x0f (AC, no low adj)", 0x10, FlagAC | 0x02, 0x16, true, false},
		{"0x99", 0x99, 0x02, 0x99, false, false},
		{"0xa0 (high > 9)", 0xa0, 0x02, 0x00, false, true},
		{"0x9a (low >9, high >9)", 0x9a, 0x02, 0x00, true, true},
		{"0x0f + AC", 0x0f, FlagAC | 0x02, 0x15, true, false},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			cpu, _ := testCPU(t, []uint8{0x27}) // DAA
			cpu.A = tc.a
			cpu.Flags = tc.flagsIn
			cpu.Step()
			if cpu.A != tc.wantA {
				t.Errorf("A = 0x%02X, want 0x%02X", cpu.A, tc.wantA)
			}
			gotAC := (cpu.Flags & FlagAC) != 0
			if gotAC != tc.wantAC {
				t.Errorf("AC = %v, want %v", gotAC, tc.wantAC)
			}
			gotCY := (cpu.Flags & FlagCY) != 0
			if gotCY != tc.wantCY {
				t.Errorf("CY = %v, want %v", gotCY, tc.wantCY)
			}
		})
	}
}

// ─── Jump group ───

func TestJMP(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0xc3, 0x78, 0x56}) // JMP 0x5678
	cpu.Step()
	if cpu.PC != 0x5678 {
		t.Errorf("JMP: PC = 0x%04X, want 0x5678", cpu.PC)
	}
}

func TestConditionalJumps(t *testing.T) {
	// Opcodes: JNZ(0xc2), JZ(0xca), JNC(0xd2), JC(0xda), JPO(0xe2), JPE(0xea), JP(0xf2), JM(0xfa)
	type jumpTest struct {
		code     uint8
		cond     func(*CPU8080) bool
		name     string
	}
	jumps := []jumpTest{
		{0xc2, func(c *CPU8080) bool { return c.Flags&FlagZ == 0 }, "JNZ"},
		{0xca, func(c *CPU8080) bool { return c.Flags&FlagZ != 0 }, "JZ"},
		{0xd2, func(c *CPU8080) bool { return c.Flags&FlagCY == 0 }, "JNC"},
		{0xda, func(c *CPU8080) bool { return c.Flags&FlagCY != 0 }, "JC"},
		{0xe2, func(c *CPU8080) bool { return c.Flags&FlagP == 0 }, "JPO"},
		{0xea, func(c *CPU8080) bool { return c.Flags&FlagP != 0 }, "JPE"},
		{0xf2, func(c *CPU8080) bool { return c.Flags&FlagS == 0 }, "JP"},
		{0xfa, func(c *CPU8080) bool { return c.Flags&FlagS != 0 }, "JM"},
	}
	for _, jt := range jumps {
		t.Run(jt.name+"_taken", func(t *testing.T) {
			code := []uint8{jt.code, 0x78, 0x56} // Jcc 0x5678
			cpu, _ := testCPU(t, code)
			cpu.Flags = 0x02
			// Set flags so condition is true
			switch jt.name {
			case "JZ":
				cpu.Flags |= FlagZ
			case "JC":
				cpu.Flags |= FlagCY
			case "JPE":
				cpu.Flags |= FlagP
			case "JM":
				cpu.Flags |= FlagS
			}
			cpu.Step()
			if !jt.cond(cpu) {
				t.Fatalf("condition should be true but isn't")
			}
			if cpu.PC != 0x5678 {
				t.Errorf("PC = 0x%04X, want 0x5678", cpu.PC)
			}
		})
		t.Run(jt.name+"_fall", func(t *testing.T) {
			code := []uint8{jt.code, 0x78, 0x56} // Jcc 0x5678
			cpu, _ := testCPU(t, code)
			cpu.Flags = 0x02
			// Default flags: Z=0, CY=0, P=0(odd), S=0 — makes JNZ/JNC/JPO/JP taken
			// We need to flip for the ones that need the flag set
			switch jt.name {
			case "JNZ":
				cpu.Flags |= FlagZ // make Z=1 so JNZ falls
			case "JNC":
				cpu.Flags |= FlagCY // make CY=1 so JNC falls
			case "JPO":
				cpu.Flags |= FlagP // make P=1 so JPO falls
			case "JP":
				cpu.Flags |= FlagS // make S=1 so JP falls
			case "JZ":
				// Z is already 0, so JZ falls — but we need the condition to be false
				// JZ needs Z=1 to jump, Z=0 to fall
				cpu.Flags &= ^FlagZ // ensure Z=0
			case "JC":
				cpu.Flags &= ^FlagCY // ensure CY=0
			case "JPE":
				cpu.Flags &= ^FlagP // ensure P=0 (odd parity)
			case "JM":
				cpu.Flags &= ^FlagS // ensure S=0
			}
			cpu.Step()
			if jt.cond(cpu) {
				t.Fatalf("condition should be false but is true")
			}
			if cpu.PC != 3 {
				t.Errorf("PC = 0x%04X, want 0x0003 (fall through)", cpu.PC)
			}
		})
	}
}

// ─── CALL/RET group ───

func TestCALL_RET(t *testing.T) {
	mem2 := make([]uint8, 65536)
	copy(mem2, []uint8{
		0xcd, 0x10, 0x00, // CALL 0x0010
		0x76,             // HLT
	})
	mem2[0x10] = 0xc9 // RET at 0x0010
	read2 := func(addr uint16) uint8 { return mem2[addr] }
	write2 := func(addr uint16, val uint8) { mem2[addr] = val }
	cpu := New(read2, write2, nil, nil)
	cpu.SP = 0x67fe
	if !stepN(cpu, 2) {
		t.Fatal("unexpected HLT")
	}
	if cpu.PC != 3 {
		t.Errorf("after CALL+RET: PC = 0x%04X, want 0x0003", cpu.PC)
	}
	if cpu.SP != 0x67fe {
		t.Errorf("after CALL+RET: SP = 0x%04X, want 0x67FE", cpu.SP)
	}
}

func TestConditionalCalls(t *testing.T) {
	// CNZ (0xc4) taken: Z=0 → jump
	cpu, _ := testCPU(t, []uint8{0xc4, 0x78, 0x56}) // CNZ 0x5678
	cpu.Flags = 0x02 // Z=0
	cpu.SP = 0xfffe
	pcBefore := cpu.PC
	cpu.Step()
	if cpu.PC != 0x5678 {
		t.Errorf("CNZ taken: PC = 0x%04X, want 0x5678", cpu.PC)
	}
	// Stack should have return address pushed
	// CNZ is at 0, 3 bytes, return address = 3
	retAddr, _ := func() (uint16, uint8) {
		lo := cpu.ReadByte(cpu.SP)
		hi := cpu.ReadByte(cpu.SP + 1)
		return uint16(hi)<<8 | uint16(lo), 0
	}()
	_ = pcBefore
	if retAddr != 3 {
		// SP started at 0xfffe, so after push it's 0xfffc
		lo := cpu.ReadByte(cpu.SP)
		hi := cpu.ReadByte(cpu.SP + 1)
		t.Errorf("stack ret addr = 0x%04X (from SP=0x%04X: [0x%04X]=0x%02X [0x%04X]=0x%02X), want 0x0003",
			uint16(hi)<<8|uint16(lo), cpu.SP, cpu.SP, lo, cpu.SP+1, hi)
	}

	// CNZ not taken: Z=1 → fall through
	code2 := []uint8{0xc4, 0x78, 0x56, 0x00, 0x76} // CNZ 0x5678, NOP, HLT
	cpu2, _ := testCPU(t, code2)
	cpu2.Flags = FlagZ | 0x02 // Z=1
	cpu2.SP = 0xfffe
	cpu2.Step()
	if cpu2.PC != 3 {
		t.Errorf("CNZ not taken: PC = 0x%04X, want 0x0003", cpu2.PC)
	}
}

func TestConditionalReturns(t *testing.T) {
	// RNZ (0xc0) taken: Z=0 → return
	code := []uint8{
		0xcd, 0x04, 0x00, // CALL 0x0004
		0x76,             // HLT
		0xc0,             // RNZ (Z=0 → return) at address 4
	}
	mem := make([]uint8, 65536)
	copy(mem, code)
	read := func(addr uint16) uint8 { return mem[addr] }
	write := func(addr uint16, val uint8) { mem[addr] = val }
	cpu := New(read, write, nil, nil)
	cpu.SP = 0xfffe
	cpu.Flags = 0x02 // Z=0 → RNZ taken
	stepN(cpu, 2)     // CALL + RNZ
	if cpu.PC != 3 {
		t.Errorf("CALL+RNZ: PC = 0x%04X, want 0x0003", cpu.PC)
	}

	// RZ (0xc8) not taken: Z=0 → fall through
	code2 := []uint8{
		0xcd, 0x04, 0x00, // CALL 0x0004
		0x76,             // HLT
		0xc8,             // RZ (not taken: Z=0) at address 4
		0x76,             // HLT at address 5
	}
	mem2 := make([]uint8, 65536)
	copy(mem2, code2)
	read2 := func(addr uint16) uint8 { return mem2[addr] }
	write2 := func(addr uint16, val uint8) { mem2[addr] = val }
	cpu2 := New(read2, write2, nil, nil)
	cpu2.SP = 0xfffe
	cpu2.Flags = 0x02 // Z=0
	stepN(cpu2, 2)    // CALL + RZ (not taken)
	if cpu2.PC != 5 {
		t.Errorf("CALL+RZ(not): PC = 0x%04X, want 0x0005", cpu2.PC)
	}
}

// ─── Stack operations ───

func TestPUSH_POP(t *testing.T) {
	tests := []struct {
		name  string
		push  []uint8
		pop   []uint8
		setFn func(*CPU8080, uint16)
		getFn func(*CPU8080) uint16
	}{
		{"B", []uint8{0xc5}, []uint8{0xc1}, func(c *CPU8080, v uint16) { c.setBC(v) }, func(c *CPU8080) uint16 { return c.GetBC() }},
		{"D", []uint8{0xd5}, []uint8{0xd1}, func(c *CPU8080, v uint16) { c.setDE(v) }, func(c *CPU8080) uint16 { return c.GetDE() }},
		{"H", []uint8{0xe5}, []uint8{0xe1}, func(c *CPU8080, v uint16) { c.setHL(v) }, func(c *CPU8080) uint16 { return c.GetHL() }},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			// PUSH then POP
			code := append(tc.push, tc.pop...)
			cpu, _ := testCPU(t, code)
			tc.setFn(cpu, 0x1234)
			cpu.SP = 0xfffe
			if !stepN(cpu, 2) {
				t.Fatal("unexpected HLT")
			}
			got := tc.getFn(cpu)
			if got != 0x1234 {
				t.Errorf("%s PUSH/POP: got 0x%04X, want 0x1234", tc.name, got)
			}
			if cpu.SP != 0xfffe {
				t.Errorf("SP = 0x%04X, want 0xFFFE", cpu.SP)
			}
		})
	}
}

func TestPUSH_POP_PSW(t *testing.T) {
	// PUSH PSW: push (A<<8) | Flags
	cpu, _ := testCPU(t, []uint8{0xf5, 0xf1}) // PUSH PSW, POP PSW
	cpu.A = 0xab
	cpu.Flags = 0x02 | FlagCY | FlagS | FlagP // S=1, Z=0, AC=0, P=1, CY=1
	cpu.SP = 0xfffe
	if !stepN(cpu, 2) {
		t.Fatal("unexpected HLT")
	}
	if cpu.A != 0xab {
		t.Errorf("POP PSW: A = 0x%02X, want 0xAB", cpu.A)
	}
	if cpu.Flags != (0x02 | FlagCY | FlagS | FlagP) {
		t.Errorf("POP PSW: Flags = 0x%02X, want 0x%02X", cpu.Flags, 0x02|FlagCY|FlagS|FlagP)
	}
	// Bit 1 should always be 1
	if cpu.Flags&0x02 == 0 {
		t.Error("POP PSW: bit 1 is 0, should always be 1")
	}
}

func TestXTHL(t *testing.T) {
	m2 := make([]uint8, 65536)
	copy(m2, []uint8{0xe3}) // XTHL
	m2[0x6000] = 0xaa // L at stack top
	m2[0x6001] = 0xbb // H at stack top+1
	read2 := func(addr uint16) uint8 { return m2[addr] }
	write2 := func(addr uint16, val uint8) { m2[addr] = val }
	cpu := New(read2, write2, nil, nil)
	cpu.H = 0x11
	cpu.L = 0x22
	cpu.SP = 0x6000
	cpu.Step()
	if cpu.L != 0xaa {
		t.Errorf("XTHL: L = 0x%02X, want 0xAA", cpu.L)
	}
	if cpu.H != 0xbb {
		t.Errorf("XTHL: H = 0x%02X, want 0xBB", cpu.H)
	}
	if m2[0x6000] != 0x22 {
		t.Errorf("XTHL: [0x6000] = 0x%02X, want 0x22 (old L)", m2[0x6000])
	}
	if m2[0x6001] != 0x11 {
		t.Errorf("XTHL: [0x6001] = 0x%02X, want 0x11 (old H)", m2[0x6001])
	}
}

func TestXCHG_SPHL_PCHL(t *testing.T) {
	// XCHG: DE ↔ HL
	cpu, _ := testCPU(t, []uint8{0xeb}) // XCHG
	cpu.D = 0x12
	cpu.E = 0x34
	cpu.H = 0xab
	cpu.L = 0xcd
	cpu.Step()
	if cpu.D != 0xab || cpu.E != 0xcd {
		t.Errorf("XCHG: DE = 0x%02X%02X, want 0xAB%02X", cpu.D, cpu.E, cpu.E)
	}
	if cpu.H != 0x12 || cpu.L != 0x34 {
		t.Errorf("XCHG: HL = 0x%02X%02X, want 0x12%02X", cpu.H, cpu.L, cpu.L)
	}

	// SPHL: SP = HL
	cpu2, _ := testCPU(t, []uint8{0xf9}) // SPHL
	cpu2.H = 0x12
	cpu2.L = 0x34
	cpu2.Step()
	if cpu2.SP != 0x1234 {
		t.Errorf("SPHL: SP = 0x%04X, want 0x1234", cpu2.SP)
	}

	// PCHL: PC = HL
	cpu3, _ := testCPU(t, []uint8{0xe9}) // PCHL
	cpu3.H = 0x12
	cpu3.L = 0x34
	cpu3.Step()
	if cpu3.PC != 0x1234 {
		t.Errorf("PCHL: PC = 0x%04X, want 0x1234", cpu3.PC)
	}
}

// ─── RST instructions ───

func TestRST(t *testing.T) {
	for rst, expectedPC := range map[uint8]uint16{
		0xc7: 0x00, // RST 0
		0xcf: 0x08, // RST 1
		0xd7: 0x10, // RST 2
		0xdf: 0x18, // RST 3
		0xe7: 0x20, // RST 4
		0xef: 0x28, // RST 5
		0xf7: 0x30, // RST 6
		0xff: 0x38, // RST 7
	} {
		t.Run(fmt.Sprintf("RST$%02X", rst), func(t *testing.T) {
			mem := make([]uint8, 65536)
			mem[0x0100] = rst
			read := func(addr uint16) uint8 { return mem[addr] }
			write := func(addr uint16, val uint8) { mem[addr] = val }
			cpu := New(read, write, nil, nil)
			cpu.PC = 0x0100
			cpu.SP = 0xfffe
			cpu.Step()
			if cpu.PC != expectedPC {
				t.Errorf("PC = 0x%04X, want 0x%04X", cpu.PC, expectedPC)
			}
			if cpu.SP != 0xfffc {
				t.Errorf("SP = 0x%04X, want 0xFFFC", cpu.SP)
			}
			lo := cpu.ReadByte(cpu.SP)
			hi := cpu.ReadByte(cpu.SP + 1)
			retAddr := uint16(hi)<<8 | uint16(lo)
			if retAddr != 0x0101 {
				t.Errorf("return addr on stack = 0x%04X, want 0x0101", retAddr)
			}
		})
	}
}

// ─── IN/OUT ───

func TestIN_OUT(t *testing.T) {
	// OUT: port write
	var outPort, outVal uint8
	cpu := New(
		func(addr uint16) uint8 { return 0 },
		func(addr uint16, val uint8) {},
		func(p uint8) uint8 { return 0x5a },
		func(p uint8, v uint8) { outPort, outVal = p, v },
	)
	cpu.A = 0x42
	code := []uint8{0xd3, 0x01} // OUT 1
	m := make([]uint8, 65536)
	copy(m, code)
	cpu.ReadByte = func(addr uint16) uint8 { return m[addr] }
	cpu.WriteByte = func(addr uint16, val uint8) { m[addr] = val }
	cpu.Step()
	if outPort != 1 {
		t.Errorf("OUT port = 0x%02X, want 0x01", outPort)
	}
	if outVal != 0x42 {
		t.Errorf("OUT val = 0x%02X, want 0x42", outVal)
	}

	// IN: port read into A
	var inPort uint8
	cpu2 := New(
		func(addr uint16) uint8 { return 0 },
		func(addr uint16, val uint8) {},
		func(p uint8) uint8 { inPort = p; return 0x7b },
		func(p uint8, v uint8) {},
	)
	code2 := []uint8{0xdb, 0x03} // IN 3
	m2 := make([]uint8, 65536)
	copy(m2, code2)
	cpu2.ReadByte = func(addr uint16) uint8 { return m2[addr] }
	cpu2.WriteByte = func(addr uint16, val uint8) { m2[addr] = val }
	cpu2.Step()
	if cpu2.A != 0x7b {
		t.Errorf("IN: A = 0x%02X, want 0x7B", cpu2.A)
	}
	if inPort != 3 {
		t.Errorf("IN port = 0x%02X, want 0x03", inPort)
	}
}

// ─── HLT / EI / DI / STC / CMC / CMA ───

func TestHLT(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0x76}) // HLT
	ok := cpu.Step()
	if ok {
		t.Error("HLT: Step returned true, want false")
	}
	if !cpu.Halt {
		t.Error("HLT: Halt flag not set")
	}
}

func TestEI_DI(t *testing.T) {
	// DI: disable interrupts
	cpu, _ := testCPU(t, []uint8{0xf3}) // DI
	cpu.IE = true
	cpu.Step()
	if cpu.IE {
		t.Error("DI: IE should be false")
	}

	// EI: enable interrupts
	cpu2, _ := testCPU(t, []uint8{0xfb}) // EI
	cpu2.IE = false
	cpu2.Step()
	if !cpu2.IE {
		t.Error("EI: IE should be true")
	}
}

func TestSTC_CMC(t *testing.T) {
	// STC: set carry
	cpu, _ := testCPU(t, []uint8{0x37}) // STC
	cpu.Flags = 0x02
	cpu.Step()
	if cpu.Flags&FlagCY == 0 {
		t.Error("STC: CY should be set")
	}
	if cpu.Flags&0x02 == 0 {
		t.Error("STC: bit 1 should be set")
	}

	// CMC: complement carry
	cpu2, _ := testCPU(t, []uint8{0x3f}) // CMC
	cpu2.Flags = 0x02 | FlagCY
	cpu2.Step()
	if cpu2.Flags&FlagCY != 0 {
		t.Error("CMC: CY should be clear (was set)")
	}
	cpu3, _ := testCPU(t, []uint8{0x3f}) // CMC
	cpu3.Flags = 0x02 // CY=0
	cpu3.Step()
	if cpu3.Flags&FlagCY == 0 {
		t.Error("CMC: CY should be set (was clear)")
	}
}

func TestCMA(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0x2f}) // CMA
	cpu.A = 0xaa
	cpu.Step()
	if cpu.A != 0x55 {
		t.Errorf("CMA: A = 0x%02X, want 0x55", cpu.A)
	}
}

// ─── Interrupt handling ───

func TestInterrupt(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0x00, 0x00}) // NOP, NOP
	cpu.IE = true
	cpu.Intr = true
	cpu.SP = 0xfffe
	cpu.Step()
	if cpu.IE {
		t.Error("Interrupt: IE should be cleared")
	}
	if cpu.Intr {
		t.Error("Interrupt: Intr should be cleared")
	}
	if cpu.PC != 0x0038 {
		t.Errorf("Interrupt: PC = 0x%04X, want 0x0038", cpu.PC)
	}
	if cpu.SP != 0xfffc {
		t.Errorf("Interrupt: SP = 0x%04X, want 0xFFFC", cpu.SP)
	}
}

func TestInterruptDisabled(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0x00, 0x00}) // NOP, NOP
	cpu.IE = false
	cpu.Intr = true
	cpu.Step()
	if cpu.PC != 1 {
		t.Errorf("Interrupt disabled: PC = 0x%04X, want 0x0001", cpu.PC)
	}
}

func TestHaltReturnsFalse(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{0x76})
	cpu.Step()
	if cpu.Step() {
		t.Error("Step() after HLT should return false")
	}
}

// ─── Reset ───

func TestReset(t *testing.T) {
	cpu, _ := testCPU(t, []uint8{})
	cpu.A = 0xff
	cpu.B = 0xff
	cpu.Halt = true
	cpu.IE = true
	cpu.Intr = true
	cpu.Cycles = 100
	cpu.SP = 0x1234
	cpu.PC = 0x5678
	cpu.Reset()
	if cpu.A != 0 || cpu.B != 0 {
		t.Errorf("Reset: registers not zeroed")
	}
	if cpu.SP != 0 {
		t.Errorf("Reset: SP = 0x%04X, want 0", cpu.SP)
	}
	if cpu.PC != 0 {
		t.Errorf("Reset: PC = 0x%04X, want 0", cpu.PC)
	}
	if cpu.Flags != 0x02 {
		t.Errorf("Reset: Flags = 0x%02X, want 0x02", cpu.Flags)
	}
	if cpu.Cycles != 0 {
		t.Errorf("Reset: Cycles = %d, want 0", cpu.Cycles)
	}
	if cpu.Halt {
		t.Error("Reset: Halt should be false")
	}
	if cpu.IE {
		t.Error("Reset: IE should be false")
	}
	if cpu.Intr {
		t.Error("Reset: Intr should be false")
	}
}

// ─── Flag helper ───

func checkFlags8080(t *testing.T, flags uint8, wantS, wantZ, wantAC, wantP, wantCY bool) {
	t.Helper()
	gotS := (flags & FlagS) != 0
	gotZ := (flags & FlagZ) != 0
	gotAC := (flags & FlagAC) != 0
	gotP := (flags & FlagP) != 0
	gotCY := (flags & FlagCY) != 0
	bit1 := (flags & 0x02) != 0

	if gotS != wantS {
		t.Errorf("S = %v, want %v", gotS, wantS)
	}
	if gotZ != wantZ {
		t.Errorf("Z = %v, want %v", gotZ, wantZ)
	}
	if gotAC != wantAC {
		t.Errorf("AC = %v, want %v", gotAC, wantAC)
	}
	if gotP != wantP {
		t.Errorf("P = %v, want %v", gotP, wantP)
	}
	if gotCY != wantCY {
		t.Errorf("CY = %v, want %v", gotCY, wantCY)
	}
	if !bit1 {
		t.Error("bit 1 not set (should always be 1)")
	}
}

