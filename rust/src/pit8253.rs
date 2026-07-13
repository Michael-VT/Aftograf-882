/// КР580ВИ53 (i8253) — Programmable Interval Timer
/// 3 counters, each 16-bit, decrementing.
#[derive(Clone)]
pub struct CounterState {
    pub mode: u8,
    pub val: u16,
    pub initial: u16,
    pub latch: Option<u16>,
    pub latched: bool,
    pub bcd: bool,
}

#[derive(Clone)]
pub struct PIT8253 {
    pub ctrl: u8,
    pub counters: [CounterState; 3],
    pub access_mode: [u8; 3],
    pub write_toggle: [bool; 3],
    pub read_toggle: [bool; 3],
}

impl PIT8253 {
    pub fn new() -> Self {
        PIT8253 {
            ctrl: 0,
            counters: [
                CounterState { mode: 3, val: 0xFFFF, initial: 0xFFFF, latch: None, latched: false, bcd: false },
                CounterState { mode: 3, val: 0xFFFF, initial: 0xFFFF, latch: None, latched: false, bcd: false },
                CounterState { mode: 3, val: 0xFFFF, initial: 0xFFFF, latch: None, latched: false, bcd: false },
            ],
            access_mode: [2, 2, 2],
            write_toggle: [false; 3],
            read_toggle: [false; 3],
        }
    }

    pub fn read(&mut self, reg: u8) -> u8 {
        if reg < 3 {
            let idx = reg as usize;
            let ctr = &mut self.counters[idx];
            if ctr.latched {
                if let Some(l) = ctr.latch {
                    if !self.read_toggle[idx] {
                        self.read_toggle[idx] = true;
                        return (l & 0xFF) as u8;
                    } else {
                        self.read_toggle[idx] = false;
                        ctr.latched = false;
                        ctr.latch = None;
                        return ((l >> 8) & 0xFF) as u8;
                    }
                }
            }
            let val = ctr.val;
            match self.access_mode[idx] {
                0 => return (val & 0xFF) as u8,
                1 => return ((val >> 8) & 0xFF) as u8,
                _ => {
                    if !self.read_toggle[idx] {
                        self.read_toggle[idx] = true;
                        return (val & 0xFF) as u8;
                    } else {
                        self.read_toggle[idx] = false;
                        return ((val >> 8) & 0xFF) as u8;
                    }
                }
            }
        }
        0xFF
    }

    pub fn write(&mut self, reg: u8, val: u8) {
        if reg < 3 {
            let idx = reg as usize;
            let ctr = &mut self.counters[idx];
            match self.access_mode[idx] {
                0 => {
                    ctr.val = (ctr.val & 0xFF00) | val as u16;
                    ctr.initial = ctr.val;
                }
                1 => {
                    ctr.val = ((val as u16) << 8) | (ctr.val & 0x00FF);
                    ctr.initial = ctr.val;
                }
                _ => {
                    if !self.write_toggle[idx] {
                        self.write_toggle[idx] = true;
                        ctr.val = (ctr.val & 0xFF00) | val as u16;
                    } else {
                        self.write_toggle[idx] = false;
                        ctr.val = ((val as u16) << 8) | (ctr.val & 0x00FF);
                        ctr.initial = ctr.val;
                    }
                }
            }
        } else if reg == 3 {
            self.ctrl = val;
            let sel = ((val >> 6) & 0x03) as usize;
            if sel == 3 { return; } // illegal select
            if val & 0x80 != 0 {
                let ctr = &mut self.counters[sel];
                ctr.mode = (val >> 1) & 0x07;
                if ctr.mode > 5 { ctr.mode = 5; }
                ctr.bcd = (val & 1) != 0;
                let rl = (val >> 4) & 0x03;
                self.access_mode[sel] = rl;
                self.write_toggle[sel] = false;
                self.read_toggle[sel] = false;
            } else {
                // Latch command
                let ctr = &mut self.counters[sel];
                if !ctr.latched {
                    ctr.latch = Some(ctr.val);
                    ctr.latched = true;
                    self.read_toggle[sel] = false;
                }
            }
        }
    }

}
