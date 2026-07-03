#!/usr/bin/env python3
"""
8080 Disassembler for Autograf-882 firmware.
Three D2764A EPROMs → contiguous 24KB image at $0000-$5FFF.
CPU: Intel 8080A / К580ИК80

Features:
- Recursive descent + linear sweep hybrid
- Auto-labeling of function/reset vectors
- I/O port annotation
- RAM variable naming
- Font table detection
"""

import struct
import sys
import os

# ─── Intel 8080 Instruction Table ───────────────────────────────────────────

REG_NAMES = ["B", "C", "D", "E", "H", "L", "M", "A"]
COND_NAMES = ["NZ", "Z", "NC", "C", "PO", "PE", "P", "M"]


def build_opcode_table():
    """Build complete 256-entry opcode table.
    Returns: dict { opcode: (mnemonic, size, category, operands_fmt, extra) }
      category: 'branch' (jumps/calls), 'data' (STA/LDA/LHLD/SHLD), 
                'io' (IN/OUT), 'norm' (normal instruction)
      operands_fmt: template string with {} for addr/data
      extra: extra context string
    """
    op = {}
    
    def add(b, mnem, size, cat, fmt, extra=""):
        op[b] = (mnem, size, cat, fmt, extra)
    
    # ── Initial definitions ──
    add(0x00, "NOP", 1, "norm", "")
    add(0x01, "LXI", 3, "norm", "B,${:04x}")
    add(0x02, "STAX", 1, "norm", "B")
    add(0x03, "INX", 1, "norm", "B")
    add(0x04, "INR", 1, "norm", "B")
    add(0x05, "DCR", 1, "norm", "B")
    add(0x06, "MVI", 2, "norm", "B,${:02x}")
    add(0x07, "RLC", 1, "norm", "")
    add(0x08, "NOP", 1, "norm", "")
    add(0x09, "DAD", 1, "norm", "B")
    add(0x0A, "LDAX", 1, "norm", "B")
    add(0x0B, "DCX", 1, "norm", "B")
    add(0x0C, "INR", 1, "norm", "C")
    add(0x0D, "DCR", 1, "norm", "C")
    add(0x0E, "MVI", 2, "norm", "C,${:02x}")
    add(0x0F, "RRC", 1, "norm", "")
    add(0x10, "NOP", 1, "norm", "")
    add(0x11, "LXI", 3, "norm", "D,${:04x}")
    add(0x12, "STAX", 1, "norm", "D")
    add(0x13, "INX", 1, "norm", "D")
    add(0x14, "INR", 1, "norm", "D")
    add(0x15, "DCR", 1, "norm", "D")
    add(0x16, "MVI", 2, "norm", "D,${:02x}")
    add(0x17, "RAL", 1, "norm", "")
    add(0x18, "NOP", 1, "norm", "")
    add(0x19, "DAD", 1, "norm", "D")
    add(0x1A, "LDAX", 1, "norm", "D")
    add(0x1B, "DCX", 1, "norm", "D")
    add(0x1C, "INR", 1, "norm", "E")
    add(0x1D, "DCR", 1, "norm", "E")
    add(0x1E, "MVI", 2, "norm", "E,${:02x}")
    add(0x1F, "RAR", 1, "norm", "")
    add(0x20, "NOP", 1, "norm", "")  # RIM on 8085
    add(0x21, "LXI", 3, "norm", "H,${:04x}")
    add(0x22, "SHLD", 3, "data", "${:04x}")
    add(0x23, "INX", 1, "norm", "H")
    add(0x24, "INR", 1, "norm", "H")
    add(0x25, "DCR", 1, "norm", "H")
    add(0x26, "MVI", 2, "norm", "H,${:02x}")
    add(0x27, "DAA", 1, "norm", "")
    add(0x28, "NOP", 1, "norm", "")
    add(0x29, "DAD", 1, "norm", "H")
    add(0x2A, "LHLD", 3, "data", "${:04x}")
    add(0x2B, "DCX", 1, "norm", "H")
    add(0x2C, "INR", 1, "norm", "L")
    add(0x2D, "DCR", 1, "norm", "L")
    add(0x2E, "MVI", 2, "norm", "L,${:02x}")
    add(0x2F, "CMA", 1, "norm", "")
    add(0x30, "NOP", 1, "norm", "")
    add(0x31, "LXI", 3, "norm", "SP,${:04x}")
    add(0x32, "STA", 3, "data", "${:04x}")
    add(0x33, "INX", 1, "norm", "SP")
    add(0x34, "INR", 1, "norm", "M")
    add(0x35, "DCR", 1, "norm", "M")
    add(0x36, "MVI", 2, "norm", "M,${:02x}")
    add(0x37, "STC", 1, "norm", "")
    add(0x38, "NOP", 1, "norm", "")
    add(0x39, "DAD", 1, "norm", "SP")
    add(0x3A, "LDA", 3, "data", "${:04x}")
    add(0x3B, "DCX", 1, "norm", "SP")
    add(0x3C, "INR", 1, "norm", "A")
    add(0x3D, "DCR", 1, "norm", "A")
    add(0x3E, "MVI", 2, "norm", "A,${:02x}")
    add(0x3F, "CMC", 1, "norm", "")
    
    # MOV r1,r2 (40-7F) + HLT at 76
    for dst_idx in range(8):
        for src_idx in range(8):
            b = 0x40 | (dst_idx << 3) | src_idx
            dst = REG_NAMES[dst_idx]
            src = REG_NAMES[src_idx]
            if b == 0x76:
                add(b, "HLT", 1, "norm", "")
            elif dst == src:
                add(b, "NOP", 1, "norm", "")
            else:
                add(b, "MOV", 1, "norm", f"{dst},{src}")
    
    # ADD r (80-87)
    for i in range(8):
        add(0x80 + i, "ADD", 1, "norm", REG_NAMES[i])
    # ADC r (88-8F)
    for i in range(8):
        add(0x88 + i, "ADC", 1, "norm", REG_NAMES[i])
    # SUB r (90-97)
    for i in range(8):
        add(0x90 + i, "SUB", 1, "norm", REG_NAMES[i])
    # SBB r (98-9F)
    for i in range(8):
        add(0x98 + i, "SBB", 1, "norm", REG_NAMES[i])
    # ANA r (A0-A7)
    for i in range(8):
        add(0xA0 + i, "ANA", 1, "norm", REG_NAMES[i])
    # XRA r (A8-AF)
    for i in range(8):
        add(0xA8 + i, "XRA", 1, "norm", REG_NAMES[i])
    # ORA r (B0-B7)
    for i in range(8):
        add(0xB0 + i, "ORA", 1, "norm", REG_NAMES[i])
    # CMP r (B8-BF)
    for i in range(8):
        add(0xB8 + i, "CMP", 1, "norm", REG_NAMES[i])
    
    # Conditional returns (C0, C8, D0, D8, E0, E8, F0, F8)
    for i in range(8):
        add(0xC0 | (i << 3), f"R{COND_NAMES[i]}", 1, "branch", "")
    
    add(0xC1, "POP", 1, "norm", "B")
    add(0xC2, "JNZ", 3, "branch", "${:04x}")
    add(0xC3, "JMP", 3, "branch", "${:04x}")
    add(0xC4, "CNZ", 3, "branch", "${:04x}")
    add(0xC5, "PUSH", 1, "norm", "B")
    add(0xC6, "ADI", 2, "norm", "${:02x}")
    add(0xC7, "RST", 1, "branch", "0")
    
    # C8 = RZ
    add(0xC9, "RET", 1, "branch", "")
    add(0xCA, "JZ", 3, "branch", "${:04x}")
    add(0xCB, "JMP", 3, "branch", "${:04x}")  # alias
    add(0xCC, "CZ", 3, "branch", "${:04x}")
    add(0xCD, "CALL", 3, "branch", "${:04x}")
    add(0xCE, "ACI", 2, "norm", "${:02x}")
    add(0xCF, "RST", 1, "branch", "1")
    
    add(0xD0, "RNC", 1, "branch", "")
    add(0xD1, "POP", 1, "norm", "D")
    add(0xD2, "JNC", 3, "branch", "${:04x}")
    add(0xD3, "OUT", 2, "io", "${:02x}")
    add(0xD4, "CNC", 3, "branch", "${:04x}")
    add(0xD5, "PUSH", 1, "norm", "D")
    add(0xD6, "SUI", 2, "norm", "${:02x}")
    add(0xD7, "RST", 1, "branch", "2")
    
    add(0xD8, "RC", 1, "branch", "")
    add(0xD9, "RET", 1, "branch", "")  # alias
    add(0xDA, "JC", 3, "branch", "${:04x}")
    add(0xDB, "IN", 2, "io", "${:02x}")
    add(0xDC, "CC", 3, "branch", "${:04x}")
    add(0xDD, "NOP", 1, "norm", "")
    add(0xDE, "SBI", 2, "norm", "${:02x}")
    add(0xDF, "RST", 1, "branch", "3")
    
    add(0xE0, "RPO", 1, "branch", "")
    add(0xE1, "POP", 1, "norm", "H")
    add(0xE2, "JPO", 3, "branch", "${:04x}")
    add(0xE3, "XTHL", 1, "norm", "")
    add(0xE4, "CPO", 3, "branch", "${:04x}")
    add(0xE5, "PUSH", 1, "norm", "H")
    add(0xE6, "ANI", 2, "norm", "${:02x}")
    add(0xE7, "RST", 1, "branch", "4")
    
    add(0xE8, "RPE", 1, "branch", "")
    add(0xE9, "PCHL", 1, "branch", "")
    add(0xEA, "JPE", 3, "branch", "${:04x}")
    add(0xEB, "XCHG", 1, "norm", "")
    add(0xEC, "CPE", 3, "branch", "${:04x}")
    add(0xED, "NOP", 1, "norm", "")
    add(0xEE, "XRI", 2, "norm", "${:02x}")
    add(0xEF, "RST", 1, "branch", "5")
    add(0xF0, "RP", 1, "branch", "")
    add(0xF1, "POP", 1, "norm", "PSW")
    add(0xF2, "JP", 3, "branch", "${:04x}")
    add(0xF3, "DI", 1, "norm", "")
    add(0xF4, "CP", 3, "branch", "${:04x}")
    add(0xF5, "PUSH", 1, "norm", "PSW")
    add(0xF6, "ORI", 2, "norm", "${:02x}")
    add(0xF7, "RST", 1, "branch", "6")
    
    add(0xF8, "RM", 1, "branch", "")
    add(0xF9, "SPHL", 1, "norm", "")
    add(0xFA, "JM", 3, "branch", "${:04x}")
    add(0xFB, "EI", 1, "norm", "")
    add(0xFC, "CM", 3, "branch", "${:04x}")
    add(0xFD, "NOP", 1, "norm", "")
    add(0xFE, "CPI", 2, "norm", "${:02x}")
    add(0xFF, "RST", 1, "branch", "7")
    
    return op


# ─── I/O Port Definitions ──────────────────────────────────────────────────
# Based on typical К580ВМ80A / i8255 PPI and i8253/i8254 PIT peripherals

IO_PORTS = {
    0xe0: "PPI_A_PORT",     # 8255 port A
    0xe1: "PPI_B_PORT",     # 8255 port B
    0xe2: "PPI_C_PORT",     # 8255 port C
    0xe3: "PPI_CTRL",       # 8255 control register
    0xe4: "PIT_CNTR0",      # 8253 counter 0
    0xe5: "PIT_CNTR1",      # 8253 counter 1
    0xe6: "PIT_CNTR2",      # 8253 counter 2
    0xe7: "PIT_CTRL",       # 8253 control register
}

# RAM variables (deduced from STA/LDA/SHLD/LHLD access patterns)
KNOWN_RAM = {
    0x5762: "SPEED_REG",
    0x5962: "SPEED_TEMP",
    0x5B62: "TEMP_SPEED",
    0x5C62: "TEMP_SPEED2",
    0x6363: "VARIABLE_1",
    0x6D63: "VARIABLE_2",
    0x6062: "STATUS_FLAGS",
}


class Dasm8080:
    def __init__(self, data, base=0x0000):
        self.data = data
        self.base = base
        self.end = base + len(data)
        self.op = build_opcode_table()
        
        # Results
        self.insns = {}        # addr -> (mnem, size, operands_text)
        self.as_data = set()   # addresses known to be data (not code)
        self.branch_targets = set()  # addresses used as code targets
        self.labels = {}       # addr -> label name
        self.comments = {}     # addr -> comment string
        
    def rb(self, addr):
        off = addr - self.base
        if 0 <= off < len(self.data):
            return self.data[off]
        return 0xFF
    
    def rw(self, addr):
        return self.rb(addr) | (self.rb(addr + 1) << 8)
    
    def disasm_at(self, addr):
        """Disassemble one instruction. Returns (address, mnemonic, operand_text, size)
        or None if address out of range."""
        if addr < self.base or addr >= self.end:
            return None
        
        b = self.rb(addr)
        if b not in self.op:
            return (addr, "DB", f"${b:02x}", 1)
        
        mnem, size, cat, fmt, extra = self.op[b]
        
        if not fmt:
            return (addr, mnem, extra, size)
        
        if "{:02x}" in fmt:
            val = self.rb(addr + 1)
            op_str = fmt.format(val)
        elif "{:04x}" in fmt:
            val = self.rw(addr + 1)
            op_str = fmt.format(val)
        else:
            op_str = fmt
        
        return (addr, mnem, op_str, size)
    
    def linear_sweep(self, start, end):
        """Linear sweep disassembly from start to end."""
        addr = start
        while addr < end:
            insn = self.disasm_at(addr)
            if insn is None:
                break
            self.insns[addr] = insn
            
            # Collect branch targets
            b = self.rb(addr)
            _, _, cat, fmt, _ = self.op.get(b, ("DB", 1, "norm", "", ""))
            if cat == "branch" and "{:04x}" in fmt:
                target = self.rw(addr + 1)
                if self.base <= target < self.end:
                    self.branch_targets.add(target)
            
            addr += insn[3]
            # Don't sweep past known data areas
            if addr in self.as_data:
                break
        return addr
    
    def analyze(self):
        """Full analysis with recursive descent from reset vector."""
        # Mark font tables at end of chip 3 as data
        self._mark_data_tables()
        
        # Start from reset vector ($0000)
        queue = [self.base]
        visited = set()
        
        while queue:
            addr = queue.pop(0)
            if addr in visited or addr < self.base or addr >= self.end:
                continue
            if addr in self.as_data:
                continue
            
            # Linear sweep from this address until we hit visited or data
            while addr < self.end and addr not in visited and addr not in self.as_data:
                insn = self.disasm_at(addr)
                if insn is None:
                    break
                
                self.insns[addr] = insn
                visited.add(addr)
                
                b = self.rb(addr)
                _, _, cat, fmt, _ = self.op.get(b, ("DB", 1, "norm", "", ""))
                
                if cat == "branch" and "{:04x}" in fmt:
                    target = self.rw(addr + 1)
                    if self.base <= target < self.end:
                        self.branch_targets.add(target)
                        if target not in visited:
                            queue.append(target)
                    
                    # Conditional branch: fall-through continues linear sweep
                    # Unconditional JMP: stop linear sweep
                    if b in (0xC3, 0xCB) or b in (0xE9,):  # JMP or PCHL
                        break
                    # RET and conditional returns: stop linear sweep
                    if b in (0xC9, 0xD9) or (0xC0 <= b <= 0xF8 and (b & 7) == 0):
                        break
                
                addr += insn[3]
        
        # Generate labels
        self._gen_labels()
    
    def _mark_data_tables(self):
        """Mark known data areas (font tables, lookup tables)."""
        # Last 512 bytes of chip 3: font tables, jump vectors, ASCII lookup tables
        for addr in range(0x5E00, self.end):
            self.as_data.add(addr)
    
    def _gen_labels(self):
        """Generate readable label names."""
        # Reset vector
        self.labels[0x0000] = "RESET"
        
        # RST handlers
        for i in range(8):
            addr = i * 8
            if addr in self.branch_targets:
                self.labels[addr] = f"RST{i}_HANDLER"
        
        # Sort branch targets and generate names
        targets = sorted(self.branch_targets)
        func_count = 0
        
        for addr in targets:
            if addr in self.labels:
                continue
            if addr in self.as_data:
                continue
            
            # Determine chip
            if addr < 0x2000:
                prefix = "L"  # Low routines
            elif addr < 0x4000:
                prefix = "M"  # Main
            else:
                prefix = "P"  # Plotter
            
            self.labels[addr] = f"F_{prefix}_{addr:04x}"
    
    def get_strings(self, addr, max_len=40):
        """Try to read a null-terminated string at addr. Return string or None."""
        s = []
        for i in range(max_len):
            b = self.rb(addr + i)
            if b == 0:
                return "".join(s)
            if 0x20 <= b < 0x7F:
                s.append(chr(b))
            else:
                return None
        return None
    
    def format_asm(self):
        """Generate the final assembly listing."""
        lines = []
        
        # Header
        lines.append("; ============================================================")
        lines.append("; Autograf-882 — Disassembly of firmware ROM")
        lines.append("; CPU: Intel 8080A (К580ИК80)")
        lines.append(";")
        lines.append("; Source: 3 × D2764A EPROM, 8KB each, contiguous in address space")
        lines.append(f"; Image size: {len(self.data)} bytes (${self.base:04X}-${self.end-1:04X})")
        lines.append(";")
        lines.append("; Memory Map:")
        lines.append(";   $0000-$1FFF = Chip 1 (NearOfHeatsink) — reset, init, low routines")
        lines.append(";   $2000-$3FFF = Chip 2 (InMiddle) — main program logic")
        lines.append(";   $4000-$5FFF = Chip 3 (FarOfHeatsink) — plotter routines, font tables")
        lines.append(";   $E000-$E3FF = I/O ports (8255 PPI ×? 8253 PIT)")
        lines.append("; ============================================================")
        lines.append("")
        lines.append("; I/O Ports:")
        for port, name in sorted(IO_PORTS.items(), key=lambda x: x[0]):
            lines.append(f";   ${port:02x}  = {name}")
        lines.append("")
        
        # Build ordered address list
        addrs = sorted(set(self.insns.keys()) | self.as_data)
        if not addrs:
            # Fallback: full range
            addrs = list(range(self.base, self.end))
        
        addr = self.base
        while addr < self.end:
            # Label
            if addr in self.labels:
                label = self.labels[addr]
                lines.append("")
                lines.append(f"{label}:")
            
            # Comment
            comment = self.comments.get(addr, "")
            
            if addr in self.as_data:
                # Data area — try to decode as font table or ASCII
                # Check for sequential ASCII
                s = self.get_strings(addr)
                if s:
                    db_bytes = []
                    for i, ch in enumerate(s):
                        db_bytes.append(f"'${ord(ch):02x}' ; '{ch}'")
                        self.as_data.discard(addr + i)
                    db_bytes.append("0 ; null")
                    line = f"  DB  {', '.join(db_bytes)}"
                    lines.append(f"${addr:04x}:  {line}")
                    addr += len(s) + 1
                    continue
                
                # Font table — try groups of 8 bytes
                is_font = False
                if addr >= 0x5C00:
                    is_font = True
                
                b = self.rb(addr)
                if comment:
                    lines.append(f"${addr:04x}:  {b:02x}           DB  ${b:02x}  {comment}")
                else:
                    lines.append(f"${addr:04x}:  {b:02x}           DB  ${b:02x}")
                addr += 1
                continue
            
            if addr in self.insns:
                insn = self.insns[addr]
                mnem, size, op_str = insn[1], insn[3], insn[2]
                b = self.rb(addr)
                
                # Format hex bytes
                hex_bytes = " ".join(f"{self.rb(addr+i):02x}" for i in range(size))
                
                # Build line
                if op_str:
                    asm_line = f"  {mnem:8s} {op_str}"
                else:
                    asm_line = f"  {mnem}"
                
                if comment:
                    asm_line += f"  {comment}"
                
                lines.append(f"${addr:04x}:  {hex_bytes:16s}  {asm_line}")
                addr += size
            else:
                # Uncovered address — raw data
                b = self.rb(addr)
                lines.append(f"${addr:04x}:  {b:02x}           DB  ${b:02x}")
                addr += 1
        
        return "\n".join(lines)
    
    def stats(self):
        """Return statistics."""
        return {
            "insns": len(self.insns),
            "labels": len(self.labels),
            "data_bytes": len(self.as_data),
        }


def main():
    paths = [
        "Autograf-882-CPU_Board-On_Top-Small-Chip01-FromLeft-D2764A-NearOfHeatsink.bin",
        "Autograf-882-CPU_Board-On_Top-Small-Chip02-FromLeft-D2764A-InMiddle.bin",
        "Autograf-882-CPU_Board-On_Top-Small-Chip03-FromLeft-D2764A-FarOfHeatsink.bin"
    ]
    
    print("Loading ROM chips...")
    chips = []
    for p in paths:
        with open(p, "rb") as f:
            d = f.read()
            chips.append(d)
            print(f"  {p}: {len(d)} bytes")
    
    rom = b"".join(chips)
    print(f"\nConcatenated: {len(rom)} bytes (${len(rom):04X})")
    print()
    
    dasm = Dasm8080(rom, 0x0000)
    dasm.analyze()
    
    s = dasm.stats()
    print(f"Instructions: {s['insns']}")
    print(f"Labels: {s['labels']}")
    print(f"Data bytes: {s['data_bytes']}")
    
    asm = dasm.format_asm()
    out = "autograf-882-disassembly.asm"
    with open(out, "w") as f:
        f.write(asm)
    print(f"\nWritten: {out} ({len(asm)} bytes, {len(asm.splitlines())} lines)")
    
    # Preview
    print("\n" + "=" * 60)
    print("PREVIEW (first 60 lines):")
    print("=" * 60)
    for line in asm.split("\n")[:60]:
        print(line)


if __name__ == "__main__":
    main()
