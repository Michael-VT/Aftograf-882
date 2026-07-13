/// Disassembler — builds from CPU opcode table
#[derive(Clone)]
pub struct DisasmInsn {
    pub addr: u16,
    pub bytes: Vec<u8>,
    pub mnemonic: String,
    pub operands: String,
    pub annotation: String,
    pub size: u8,
}

pub struct Disassembler;

impl Disassembler {
    /// Disassemble one instruction at addr
    pub fn disasm_instruction(mmu: &impl Fn(u16) -> u8, addr: u16, optable: &[(u8, &str, u8, u8)]) -> DisasmInsn {
        let opcode = mmu(addr);
        let info = optable[opcode as usize];
        let size = info.2;
        let mnem_full = info.1;

        let mut bytes = Vec::with_capacity(size as usize);
        for i in 0..size {
            bytes.push(mmu(addr.wrapping_add(i as u16)));
        }

        // Parse mnemonic and operands from table entry
        let (mnem, table_operands) = Self::parse_mnemonic(mnem_full);

        // Format operand bytes based on instruction size
        let operands = if size >= 3 {
            // 3-byte instruction: address operand (low, high)
            let low = bytes[1] as u16;
            let high = bytes[2] as u16;
            let target = low | (high << 8);
            if table_operands.is_empty() {
                format!("$0x{target:04X}")
            } else {
                format!("{table_operands},$0x{target:04X}")
            }
        } else if size == 2 {
            // 2-byte instruction: immediate byte
            let imm = bytes[1];
            if table_operands.is_empty() {
                format!("$0x{imm:02X}")
            } else {
                format!("{table_operands},$0x{imm:02X}")
            }
        } else {
            // 1-byte instruction: operands are from table
            table_operands.to_string()
        };
        let annotation = Self::build_annotation(mnem, &operands, mmu);

        DisasmInsn {
            addr,
            bytes,
            mnemonic: mnem.to_string(),
            operands: operands.to_string(),
            annotation,
            size,
        }
    }

    fn parse_mnemonic(full: &str) -> (&str, &str) {
        if let Some(pos) = full.find(' ') {
            let mnem = &full[..pos];
            let oper = full[pos+1..].trim();
            (mnem, oper)
        } else {
            (full, "")
        }
    }

    fn build_annotation(mnem: &str, operands: &str, mmu: &impl Fn(u16) -> u8) -> String {
        let jmp_call = ["JMP","CALL","JNZ","JZ","JNC","JC","JPO","JPE","JP","JM",
                        "CNZ","CZ","CNC","CC","CPO","CPE","CP","CM"];
        let load_store = ["LDA","STA","LHLD","SHLD"];

        if jmp_call.contains(&mnem) && !operands.is_empty() {
            if let Ok(addr) = u16::from_str_radix(operands.trim_start_matches("$0x"), 16) {
                let b = mmu(addr);
                return format!("; → ${addr:04X} (${b:02X})");
            }
        }
        if load_store.contains(&mnem) && !operands.is_empty() {
            if let Ok(_addr) = u16::from_str_radix(operands.trim_start_matches("$0x"), 16) {
                return format!("; [{operands}]");
            }
        }
        String::new()
    }

    /// Format bytes as hex string
    pub fn format_bytes(bytes: &[u8]) -> String {
        bytes.iter()
            .map(|b| format!("{b:02X}"))
            .collect::<Vec<_>>()
            .join(" ")
    }
}

/// Opcode table entry: (opcode, mnemonic, size, cycles)
pub fn build_optable() -> Vec<(u8, &'static str, u8, u8)> {
    let mut table = Vec::with_capacity(256);
    for opcode in 0..=255u8 {
        let entry = match opcode {
            0x00 => (0x00, "NOP", 1, 4),
            0x01 => (0x01, "LXI B", 3, 10),
            0x02 => (0x02, "STAX B", 1, 7),
            0x03 => (0x03, "INX B", 1, 5),
            0x04 => (0x04, "INR B", 1, 5),
            0x05 => (0x05, "DCR B", 1, 5),
            0x06 => (0x06, "MVI B", 2, 7),
            0x07 => (0x07, "RLC", 1, 4),
            0x08 => (0x08, "NOP", 1, 4),
            0x09 => (0x09, "DAD B", 1, 10),
            0x0a => (0x0a, "LDAX B", 1, 7),
            0x0b => (0x0b, "DCX B", 1, 5),
            0x0c => (0x0c, "INR C", 1, 5),
            0x0d => (0x0d, "DCR C", 1, 5),
            0x0e => (0x0e, "MVI C", 2, 7),
            0x0f => (0x0f, "RRC", 1, 4),

            0x10 => (0x10, "NOP", 1, 4),
            0x11 => (0x11, "LXI D", 3, 10),
            0x12 => (0x12, "STAX D", 1, 7),
            0x13 => (0x13, "INX D", 1, 5),
            0x14 => (0x14, "INR D", 1, 5),
            0x15 => (0x15, "DCR D", 1, 5),
            0x16 => (0x16, "MVI D", 2, 7),
            0x17 => (0x17, "RAL", 1, 4),
            0x18 => (0x18, "NOP", 1, 4),
            0x19 => (0x19, "DAD D", 1, 10),
            0x1a => (0x1a, "LDAX D", 1, 7),
            0x1b => (0x1b, "DCX D", 1, 5),
            0x1c => (0x1c, "INR E", 1, 5),
            0x1d => (0x1d, "DCR E", 1, 5),
            0x1e => (0x1e, "MVI E", 2, 7),
            0x1f => (0x1f, "RAR", 1, 4),

            0x20 => (0x20, "NOP", 1, 4),
            0x21 => (0x21, "LXI H", 3, 10),
            0x22 => (0x22, "SHLD", 3, 16),
            0x23 => (0x23, "INX H", 1, 5),
            0x24 => (0x24, "INR H", 1, 5),
            0x25 => (0x25, "DCR H", 1, 5),
            0x26 => (0x26, "MVI H", 2, 7),
            0x27 => (0x27, "DAA", 1, 4),
            0x28 => (0x28, "NOP", 1, 4),
            0x29 => (0x29, "DAD H", 1, 10),
            0x2a => (0x2a, "LHLD", 3, 16),
            0x2b => (0x2b, "DCX H", 1, 5),
            0x2c => (0x2c, "INR L", 1, 5),
            0x2d => (0x2d, "DCR L", 1, 5),
            0x2e => (0x2e, "MVI L", 2, 7),
            0x2f => (0x2f, "CMA", 1, 4),

            0x30 => (0x30, "NOP", 1, 4),
            0x31 => (0x31, "LXI SP", 3, 10),
            0x32 => (0x32, "STA", 3, 13),
            0x33 => (0x33, "INX SP", 1, 5),
            0x34 => (0x34, "INR M", 1, 10),
            0x35 => (0x35, "DCR M", 1, 10),
            0x36 => (0x36, "MVI M", 2, 10),
            0x37 => (0x37, "STC", 1, 4),
            0x38 => (0x38, "NOP", 1, 4),
            0x39 => (0x39, "DAD SP", 1, 10),
            0x3a => (0x3a, "LDA", 3, 13),
            0x3b => (0x3b, "DCX SP", 1, 5),
            0x3c => (0x3c, "INR A", 1, 5),
            0x3d => (0x3d, "DCR A", 1, 5),
            0x3e => (0x3e, "MVI A", 2, 7),
            0x3f => (0x3f, "CMC", 1, 4),

            // MOV B,*
            0x40 => (0x40, "MOV B,B", 1, 5), 0x41 => (0x41, "MOV B,C", 1, 5),
            0x42 => (0x42, "MOV B,D", 1, 5), 0x43 => (0x43, "MOV B,E", 1, 5),
            0x44 => (0x44, "MOV B,H", 1, 5), 0x45 => (0x45, "MOV B,L", 1, 5),
            0x46 => (0x46, "MOV B,M", 1, 7), 0x47 => (0x47, "MOV B,A", 1, 5),
            // MOV C,*
            0x48 => (0x48, "MOV C,B", 1, 5), 0x49 => (0x49, "MOV C,C", 1, 5),
            0x4a => (0x4a, "MOV C,D", 1, 5), 0x4b => (0x4b, "MOV C,E", 1, 5),
            0x4c => (0x4c, "MOV C,H", 1, 5), 0x4d => (0x4d, "MOV C,L", 1, 5),
            0x4e => (0x4e, "MOV C,M", 1, 7), 0x4f => (0x4f, "MOV C,A", 1, 5),
            // MOV D,*
            0x50 => (0x50, "MOV D,B", 1, 5), 0x51 => (0x51, "MOV D,C", 1, 5),
            0x52 => (0x52, "MOV D,D", 1, 5), 0x53 => (0x53, "MOV D,E", 1, 5),
            0x54 => (0x54, "MOV D,H", 1, 5), 0x55 => (0x55, "MOV D,L", 1, 5),
            0x56 => (0x56, "MOV D,M", 1, 7), 0x57 => (0x57, "MOV D,A", 1, 5),
            // MOV E,*
            0x58 => (0x58, "MOV E,B", 1, 5), 0x59 => (0x59, "MOV E,C", 1, 5),
            0x5a => (0x5a, "MOV E,D", 1, 5), 0x5b => (0x5b, "MOV E,E", 1, 5),
            0x5c => (0x5c, "MOV E,H", 1, 5), 0x5d => (0x5d, "MOV E,L", 1, 5),
            0x5e => (0x5e, "MOV E,M", 1, 7), 0x5f => (0x5f, "MOV E,A", 1, 5),
            // MOV H,*
            0x60 => (0x60, "MOV H,B", 1, 5), 0x61 => (0x61, "MOV H,C", 1, 5),
            0x62 => (0x62, "MOV H,D", 1, 5), 0x63 => (0x63, "MOV H,E", 1, 5),
            0x64 => (0x64, "MOV H,H", 1, 5), 0x65 => (0x65, "MOV H,L", 1, 5),
            0x66 => (0x66, "MOV H,M", 1, 7), 0x67 => (0x67, "MOV H,A", 1, 5),
            // MOV L,*
            0x68 => (0x68, "MOV L,B", 1, 5), 0x69 => (0x69, "MOV L,C", 1, 5),
            0x6a => (0x6a, "MOV L,D", 1, 5), 0x6b => (0x6b, "MOV L,E", 1, 5),
            0x6c => (0x6c, "MOV L,H", 1, 5), 0x6d => (0x6d, "MOV L,L", 1, 5),
            0x6e => (0x6e, "MOV L,M", 1, 7), 0x6f => (0x6f, "MOV L,A", 1, 5),
            // MOV M,*
            0x70 => (0x70, "MOV M,B", 1, 7), 0x71 => (0x71, "MOV M,C", 1, 7),
            0x72 => (0x72, "MOV M,D", 1, 7), 0x73 => (0x73, "MOV M,E", 1, 7),
            0x74 => (0x74, "MOV M,H", 1, 7), 0x75 => (0x75, "MOV M,L", 1, 7),
            0x76 => (0x76, "HLT", 1, 7),       0x77 => (0x77, "MOV M,A", 1, 7),
            // MOV A,*
            0x78 => (0x78, "MOV A,B", 1, 5), 0x79 => (0x79, "MOV A,C", 1, 5),
            0x7a => (0x7a, "MOV A,D", 1, 5), 0x7b => (0x7b, "MOV A,E", 1, 5),
            0x7c => (0x7c, "MOV A,H", 1, 5), 0x7d => (0x7d, "MOV A,L", 1, 5),
            0x7e => (0x7e, "MOV A,M", 1, 7), 0x7f => (0x7f, "MOV A,A", 1, 5),
            // ADD r
            0x80 => (0x80, "ADD B", 1, 4),  0x81 => (0x81, "ADD C", 1, 4),
            0x82 => (0x82, "ADD D", 1, 4),  0x83 => (0x83, "ADD E", 1, 4),
            0x84 => (0x84, "ADD H", 1, 4),  0x85 => (0x85, "ADD L", 1, 4),
            0x86 => (0x86, "ADD M", 1, 7),  0x87 => (0x87, "ADD A", 1, 4),
            // ADC r
            0x88 => (0x88, "ADC B", 1, 4),  0x89 => (0x89, "ADC C", 1, 4),
            0x8A => (0x8A, "ADC D", 1, 4),  0x8B => (0x8B, "ADC E", 1, 4),
            0x8C => (0x8C, "ADC H", 1, 4),  0x8D => (0x8D, "ADC L", 1, 4),
            0x8E => (0x8E, "ADC M", 1, 7),  0x8F => (0x8F, "ADC A", 1, 4),
            // SUB r
            0x90 => (0x90, "SUB B", 1, 4),  0x91 => (0x91, "SUB C", 1, 4),
            0x92 => (0x92, "SUB D", 1, 4),  0x93 => (0x93, "SUB E", 1, 4),
            0x94 => (0x94, "SUB H", 1, 4),  0x95 => (0x95, "SUB L", 1, 4),
            0x96 => (0x96, "SUB M", 1, 7),  0x97 => (0x97, "SUB A", 1, 4),
            // SBB r
            0x98 => (0x98, "SBB B", 1, 4),  0x99 => (0x99, "SBB C", 1, 4),
            0x9A => (0x9A, "SBB D", 1, 4),  0x9B => (0x9B, "SBB E", 1, 4),
            0x9C => (0x9C, "SBB H", 1, 4),  0x9D => (0x9D, "SBB L", 1, 4),
            0x9E => (0x9E, "SBB M", 1, 7),  0x9F => (0x9F, "SBB A", 1, 4),
            // ANA r
            0xA0 => (0xA0, "ANA B", 1, 4),  0xA1 => (0xA1, "ANA C", 1, 4),
            0xA2 => (0xA2, "ANA D", 1, 4),  0xA3 => (0xA3, "ANA E", 1, 4),
            0xA4 => (0xA4, "ANA H", 1, 4),  0xA5 => (0xA5, "ANA L", 1, 4),
            0xA6 => (0xA6, "ANA M", 1, 7),  0xA7 => (0xA7, "ANA A", 1, 4),
            // XRA r
            0xA8 => (0xA8, "XRA B", 1, 4),  0xA9 => (0xA9, "XRA C", 1, 4),
            0xAA => (0xAA, "XRA D", 1, 4),  0xAB => (0xAB, "XRA E", 1, 4),
            0xAC => (0xAC, "XRA H", 1, 4),  0xAD => (0xAD, "XRA L", 1, 4),
            0xAE => (0xAE, "XRA M", 1, 7),  0xAF => (0xAF, "XRA A", 1, 4),
            // ORA r
            0xB0 => (0xB0, "ORA B", 1, 4),  0xB1 => (0xB1, "ORA C", 1, 4),
            0xB2 => (0xB2, "ORA D", 1, 4),  0xB3 => (0xB3, "ORA E", 1, 4),
            0xB4 => (0xB4, "ORA H", 1, 4),  0xB5 => (0xB5, "ORA L", 1, 4),
            0xB6 => (0xB6, "ORA M", 1, 7),  0xB7 => (0xB7, "ORA A", 1, 4),
            // CMP r
            0xB8 => (0xB8, "CMP B", 1, 4),  0xB9 => (0xB9, "CMP C", 1, 4),
            0xBA => (0xBA, "CMP D", 1, 4),  0xBB => (0xBB, "CMP E", 1, 4),
            0xBC => (0xBC, "CMP H", 1, 4),  0xBD => (0xBD, "CMP L", 1, 4),
            0xBE => (0xBE, "CMP M", 1, 7),  0xBF => (0xBF, "CMP A", 1, 4),
            // RET cond, JMP cond, CALL cond
            0xC0 => (0xC0, "RNZ", 1, 11), 0xC1 => (0xC1, "POP B", 1, 10),
            0xC2 => (0xC2, "JNZ", 3, 10), 0xC3 => (0xC3, "JMP", 3, 10),
            0xC4 => (0xC4, "CNZ", 3, 17), 0xC5 => (0xC5, "PUSH B", 1, 11),
            0xC6 => (0xC6, "ADI", 2, 7),  0xC7 => (0xC7, "RST 0", 1, 11),
            0xC8 => (0xC8, "RZ", 1, 11),  0xC9 => (0xC9, "RET", 1, 10),
            0xCA => (0xCA, "JZ", 3, 10),  0xCB => (0xCB, "NOP", 1, 4),
            0xCC => (0xCC, "CZ", 3, 17),  0xCD => (0xCD, "CALL", 3, 17),
            0xCE => (0xCE, "ACI", 2, 7),  0xCF => (0xCF, "RST 1", 1, 11),

            0xD0 => (0xD0, "RNC", 1, 11), 0xD1 => (0xD1, "POP D", 1, 10),
            0xD2 => (0xD2, "JNC", 3, 10), 0xD3 => (0xD3, "OUT", 2, 10),
            0xD4 => (0xD4, "CNC", 3, 17), 0xD5 => (0xD5, "PUSH D", 1, 11),
            0xD6 => (0xD6, "SUI", 2, 7),  0xD7 => (0xD7, "RST 2", 1, 11),
            0xD8 => (0xD8, "RC", 1, 11),  0xD9 => (0xD9, "NOP", 1, 4),
            0xDA => (0xDA, "JC", 3, 10),  0xDB => (0xDB, "IN", 2, 10),
            0xDC => (0xDC, "CC", 3, 17),  0xDD => (0xDD, "NOP", 1, 4),
            0xDE => (0xDE, "SBI", 2, 7),  0xDF => (0xDF, "RST 3", 1, 11),

            0xE0 => (0xE0, "RPO", 1, 11), 0xE1 => (0xE1, "POP H", 1, 10),
            0xE2 => (0xE2, "JPO", 3, 10), 0xE3 => (0xE3, "XTHL", 1, 18),
            0xE4 => (0xE4, "CPO", 3, 17), 0xE5 => (0xE5, "PUSH H", 1, 11),
            0xE6 => (0xE6, "ANI", 2, 7),  0xE7 => (0xE7, "RST 4", 1, 11),
            0xE8 => (0xE8, "RPE", 1, 11), 0xE9 => (0xE9, "PCHL", 1, 5),
            0xEA => (0xEA, "JPE", 3, 10), 0xEB => (0xEB, "XCHG", 1, 5),
            0xEC => (0xEC, "CPE", 3, 17), 0xED => (0xED, "NOP", 1, 4),
            0xEE => (0xEE, "XRI", 2, 7),  0xEF => (0xEF, "RST 5", 1, 11),

            0xF0 => (0xF0, "RP", 1, 11),  0xF1 => (0xF1, "POP PSW", 1, 10),
            0xF2 => (0xF2, "JP", 3, 10),  0xF3 => (0xF3, "DI", 1, 4),
            0xF4 => (0xF4, "CP", 3, 17),  0xF5 => (0xF5, "PUSH PSW", 1, 11),
            0xF6 => (0xF6, "ORI", 2, 7),  0xF7 => (0xF7, "RST 6", 1, 11),
            0xF8 => (0xF8, "RM", 1, 11),  0xF9 => (0xF9, "SPHL", 1, 5),
            0xFA => (0xFA, "JM", 3, 10),  0xFB => (0xFB, "EI", 1, 4),
            0xFC => (0xFC, "CM", 3, 17),  0xFD => (0xFD, "NOP", 1, 4),
            0xFE => (0xFE, "CPI", 2, 7),  0xFF => (0xFF, "RST 7", 1, 11),
        };
        table.push(entry);
    }
    table
}
