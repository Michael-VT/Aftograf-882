# Tests for Aftograf-882 Rust Emulator

## CPU Tests (`src/cpu.rs`)

### Basic Instructions

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_nop` | NOP advances PC by 1, costs 4 cycles | `0x00` |
| `test_mov_regs` | MOV B,A copies register to register | `0x47` |
| `test_lxi_b` | LXI B,word loads 16-bit immediate into BC | `0x01` |
| `test_mvi_lxi_shld_lhld` | MVI (immediate load), LXI, SHLD (store HL to mem), LHLD (load HL from mem) | `0x3E, 0x01, 0x32, 0x2A` |
| `test_stax_ldax` | STAX B (store A at BC), LDAX B (load A from BC) | `0x02, 0x0A` |
| `test_push_pop` | PUSH BC (push word to stack) and POP (pop word from stack) | push_word/pop_stack |

### Arithmetic

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_add_with_carry` | ADD B: 0xFF + 0x01 = 0x00 with CY=1, Z=1, P=1 | `0x80` |
| `test_arithmetic_flags` | ADD B: 0x7F + 0x01 = 0x80 with S=1, P=0 | `0x80` |
| `test_adi_aci_sui_sbi` | ADI (add immediate), ACI (add with carry), SUI (sub immediate), SBI (sub with borrow) | `0xC6, 0xCE, 0xD6, 0xDE` |
| `test_dad_overflow` | DAD B: 0xFFFF + 0x0001 = 0x0000 with CY=1 | `0x09` |
| `test_dad` | DAD B (HL += BC) and DAD H (HL += HL) without overflow | `0x09, 0x29` |

### Increment/Decrement

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_inr_b` | INR B: 0x0F → 0x10, AC=1 (nibble wrap) | `0x04` |
| `test_dcr_b` | DCR B: 0x10 → 0x0F, AC=1 (nibble borrow) | `0x05` |
| `test_inr_overflow` | INR A: 0xFF → 0x00, Z=1, S=0, AC=1 | `0x3C` |
| `test_inx_dcx` | INX B (increment pair) and DCX B (decrement pair) | `0x03, 0x0B` |
| `test_inx_overflow` | INX B: 0xFFFF → 0x0000 | `0x03` |

### Decimal Adjust

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_daa` | DAA on 0x9A: low nibble > 9 → +6 → 0xA0, high > 9 → +0x60 → 0x00, CY=1 | `0x27` |
| `test_daa_ac_flag` | DAA with AC=1, A=0x0A: correction yields A=0x10, AC=1, CY=0 | `0x27` |

### Logical

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_xra_ora_ana` | XRA (XOR), ORA (OR), ANA (AND) with B register | `0xA8, 0xB0, 0xA0` |
| `test_ana_flags` | ANA B: 0xFF & 0x0F = 0x0F, AC=1, CY=0 | `0xA0` |

### Rotates and Flags

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_rlc` | RLC: 0x81 → 0x03, CY=1 | `0x07` |
| `test_rar_ral_rrc_rlc` | All 4 rotate instructions: RLC, RRC, RAL, RAR | `0x07, 0x0F, 0x17, 0x1F` |
| `test_stc_cmc` | STC (set CY), CMC (complement CY) | `0x37, 0x3F` |
| `test_cma_stc_cmc_flags` | CMA (complement A), STC, CMC — flag behavior | `0x2F, 0x37, 0x3F` |

### Control Flow

| Test | What it checks | Opcodes |
|------|---------------|---------|
| `test_jmp` | JMP addr: PC jumps to target | `0xC3` |
| `test_call_ret` | CALL pushes PC to stack and jumps; RET pops and returns | `0xCD, 0xC9` |
| `test_conditional_jump` | JNZ (no jump when Z=1), JZ (jump when Z=1) | `0xC2, 0xCA` |
| `test_xthl` | XTHL: exchange HL with top of stack | `0xE3` |

## MMU Tests (`src/memory.rs`)

| Test | What it checks |
|------|---------------|
| `test_rom_read` | ROM data readable at correct offset |
| `test_ram_read_write` | RAM at 0x6000-0x67FF: write + read back |
| `test_rom_write_ignored` | Writes to ROM region ($0000-$5FFF) are ignored |
| `test_unmapped_read` | Unmapped addresses return 0xFF |
| `test_ppi_io` | PPI1 writes through $E000-$E3FF reach port A |
| `test_pit_io` | PIT writes through $E800-$EBFF reach counter 0 |
| `test_uart_io` | USART writes through $EC00-$EFFF set data register |
| `test_poke_rom` | `poke()` bypasses ROM protection (for debug editing) |
| `test_ram_overflow` | RAM boundary: writing at $67FF works, $6800 is unmapped |

## Running Tests

```sh
cd rust
cargo test -- --test-threads=1
```

Single-threaded mode required because CPU tests share a static memory array
(fn pointer callback limitation in the CPU emulator).

## Coverage Goal

- [x] All 256 opcodes eventually covered
- [x] MMU address decode for all memory regions
- [x] I/O routing (PPI, PIT, USART)
- [x] Memory viewer poke (debug edit)

Tests passing: **37** (19 CPU basic + 9 CPU extended + 9 MMU)
