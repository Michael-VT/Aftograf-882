/// КР580ВВ55А (i8255) — Programmable Peripheral Interface
/// 3 ports (A, B, C) + control register.
#[derive(Clone)]
pub struct PPI8255 {
    #[allow(dead_code)]
    pub name: String,
    pub port_a: u8,
    pub port_b: u8,
    pub port_c: u8,
    pub ctrl: u8,
    pub mode: u8,
    pub mode_set: bool,
    pub on_read_port_a: Option<fn() -> u8>,
    pub on_read_port_b: Option<fn() -> u8>,
}

impl PPI8255 {
    pub fn new(name: &str) -> Self {
        PPI8255 {
            name: name.to_string(),
            port_a: 0,
            port_b: 0,
            port_c: 0,
            ctrl: 0,
            mode: 0,
            mode_set: false,
            on_read_port_a: None,
            on_read_port_b: None,
        }
    }

    pub fn read(&mut self, reg: u8) -> u8 {
        match reg {
            0 => {
                if let Some(cb) = self.on_read_port_a {
                    cb()
                } else {
                    self.port_a
                }
            }
            1 => {
                if let Some(cb) = self.on_read_port_b {
                    cb()
                } else {
                    self.port_b
                }
            }
            2 => self.port_c,
            3 => self.ctrl,
            _ => 0xFF,
        }
    }

    pub fn write(&mut self, reg: u8, val: u8) {
        match reg {
            0 => self.port_a = val,
            1 => self.port_b = val,
            2 => self.port_c = val,
            3 => {
                self.ctrl = val;
                if val & 0x80 != 0 {
                    self.mode_set = true;
                    self.mode = (val >> 5) & 0x03;
                }
            }
            _ => {}
        }
    }
}
