use crate::pit8253::PIT8253;
use crate::ppi8255::PPI8255;
use crate::usart8251::USART8251;

/// System Memory — Autograf-882 memory map
///
/// $0000-$1FFF  ROM1 (D2764A)
/// $2000-$3FFF  ROM2 (D2764A)
/// $4000-$5FFF  ROM3 (D2764A)
/// $6000-$63FF  RAM (КР537РУ10, 1024 bytes)
/// $E000-$E3FF  PPI1 (КР580ВВ55А #1)
/// $E400-$E7FF  PPI2 (КР580ВВ55А #2)
/// $E800-$EBFF  PIT  (КР580ВИ53)
/// $EC00-$EFFF  USART (КР580ВВ51А)
pub struct MMU {
    pub rom: [u8; 0x6000],
    pub ram: [u8; 0x0800],
    pub ppi1: PPI8255,
    pub ppi2: PPI8255,
    pub pit: PIT8253,
    pub uart: USART8251,
    pub last_write_addr: u16,
    pub on_invalid_write: Option<fn(u16, u8)>,
}

impl MMU {
    pub fn new(ppi1: PPI8255, ppi2: PPI8255, pit: PIT8253, uart: USART8251) -> Self {
        MMU {
            rom: [0xFF; 0x6000],
            ram: [0; 0x0800],
            ppi1,
            ppi2,
            pit,
            uart,
            last_write_addr: 0,
            on_invalid_write: None,
        }
    }


    pub fn load_rom(&mut self, data: &[u8], offset: usize) {
        let len = data.len().min(0x6000usize.saturating_sub(offset));
        self.rom[offset..offset + len].copy_from_slice(&data[..len]);
    }

    

    /// Read byte — full address decode, mutable to update I/O state
    pub fn read_byte(&mut self, addr: u16) -> u8 {
        match addr {
            0x0000..=0x5FFF => self.rom[addr as usize],
            0x6000..=0x67FF => self.ram[(addr - 0x6000) as usize],
            0xE000..=0xE3FF => self.ppi1.read((addr & 3) as u8),
            0xE400..=0xE7FF => self.ppi2.read((addr & 3) as u8),
            0xE800..=0xEBFF => self.pit.read((addr & 3) as u8),
            0xEC00..=0xEFFF => self.uart.read((addr & 1) as u8),
            _ => 0xFF,
        }
    }

    /// Write byte — route to RAM or I/O
    pub fn write_byte(&mut self, addr: u16, val: u8) {
        match addr {
            0x0000..=0x5FFF => {
                // ROM write — warn and skip
                if let Some(cb) = self.on_invalid_write {
                    cb(addr, val);
                }
            }
            0x6000..=0x67FF => {
                self.ram[(addr - 0x6000) as usize] = val;
                self.last_write_addr = addr;
            }
            0x6800..=0xDFFF | 0xF000..=0xFFFF => {
                // Unmapped — allow write silently
            }
            0xE000..=0xE3FF => self.ppi1.write((addr & 3) as u8, val),
            0xE400..=0xE7FF => self.ppi2.write((addr & 3) as u8, val),
            0xE800..=0xEBFF => self.pit.write((addr & 3) as u8, val),
            0xEC00..=0xEFFF => self.uart.write((addr & 1) as u8, val),
        }
    }

    /// Read-only peek — immutable borrow, disasm/memory view
    pub fn peek(&self, addr: u16) -> u8 {
        match addr {
            0x0000..=0x5FFF => self.rom[addr as usize],
            0x6000..=0x67FF => self.ram[(addr - 0x6000) as usize],
            // I/O peek always returns 0xFF for read-only
            _ => 0xFF,
        }
    }

    /// Debug poke — bypass I/O, write anywhere
    #[allow(dead_code)]
    pub fn poke(&mut self, addr: u16, val: u8) {
        match addr {
            0x0000..=0x5FFF => { self.rom[addr as usize] = val; }
            0x6000..=0x67FF => { self.ram[(addr - 0x6000) as usize] = val; }
            _ => {}
        }
    }
    

}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_mmu() -> MMU {
        MMU::new(
            PPI8255::new("PPI1"),
            PPI8255::new("PPI2"),
            PIT8253::new(),
            USART8251::new(),
        )
    }

    #[test]
    fn test_rom_read() {
        let mut mmu = test_mmu();
        mmu.load_rom(&[0xAA, 0xBB, 0xCC], 0x1000);
        assert_eq!(mmu.read_byte(0x1000), 0xAA);
        assert_eq!(mmu.read_byte(0x1001), 0xBB);
        assert_eq!(mmu.read_byte(0x1002), 0xCC);
    }

    #[test]
    fn test_ram_read_write() {
        let mut mmu = test_mmu();
        mmu.write_byte(0x6000, 0x42);
        assert_eq!(mmu.read_byte(0x6000), 0x42);
        // Write to next byte
        mmu.write_byte(0x6001, 0x24);
        assert_eq!(mmu.read_byte(0x6001), 0x24);
        // Original unchanged
        assert_eq!(mmu.read_byte(0x6000), 0x42);
    }

    #[test]
    fn test_rom_write_ignored() {
        let mut mmu = test_mmu();
        mmu.load_rom(&[0x10], 0x0000);
        mmu.write_byte(0x0000, 0xFF); // should be ignored
        assert_eq!(mmu.read_byte(0x0000), 0x10);
    }

    #[test]
    fn test_unmapped_read() {
        let mmu = test_mmu();
        assert_eq!(mmu.peek(0x7000), 0xFF);
        assert_eq!(mmu.peek(0xFFFF), 0xFF);
        assert_eq!(mmu.peek(0xF000), 0xFF);
    }

    #[test]
    fn test_ppi_io() {
        let mut mmu = test_mmu();
        // Write to PPI1 port A (0xE000)
        mmu.write_byte(0xE000, 0xA5);
        assert_eq!(mmu.ppi1.port_a, 0xA5);
        // Read back
        assert_eq!(mmu.read_byte(0xE000), 0xA5);
    }

    #[test]
    fn test_pit_io() {
        let mut mmu = test_mmu();
        // Write to PIT counter 0 (0xE800)
        mmu.write_byte(0xE800, 0x78);
        assert_eq!(mmu.pit.counters[0].val & 0xFF, 0x78);
    }

    #[test]
    fn test_uart_io() {
        let mut mmu = test_mmu();
        // Write to USART data (0xEC00)
        mmu.write_byte(0xEC00, 0x55);
        assert_eq!(mmu.uart.data, 0x55);
    }

    #[test]
    fn test_poke_rom() {
        let mut mmu = test_mmu();
        mmu.load_rom(&[0x00], 0x0000);
        mmu.poke(0x0000, 0x99);
        assert_eq!(mmu.peek(0x0000), 0x99);
    }

    #[test]
    fn test_ram_overflow() {
        let mut mmu = test_mmu();
        mmu.write_byte(0x67FF, 0x77);
        assert_eq!(mmu.read_byte(0x67FF), 0x77);
        // Beyond RAM
        assert_eq!(mmu.peek(0x6800), 0xFF);
    }
}
