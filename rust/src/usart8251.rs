/// КР580ВВ51А (i8251) — USART with terminal I/O and XOn-XOff.
///
/// RX buffer — данные от терминала к CPU
/// TX buffer — данные от CPU к терминалу
/// XOn/XOff: при заполнении RX буфера > 200 байт шлём XOff (0x13),
/// при освобождении < 50 байт — XOn (0x11).
#[derive(Clone)]
pub struct USART8251 {
    pub data: u8,
    pub status: u8,     // bit 0 = TXRDY, bit 1 = RXRDY
    pub ctrl: u8,
    pub rx_buffer: Vec<u8>,
    pub rx_max: usize,
    pub tx_buffer: Vec<u8>,
    pub xon_sent: bool,
    pub xoff_sent: bool,
    pub xon_threshold: usize,
    pub xoff_threshold: usize,
    pub on_tx_byte: Option<fn(u8)>,
    pub on_rx_interrupt: Option<fn()>,
}

impl USART8251 {
    pub fn new() -> Self {
        USART8251 {
            data: 0,
            status: 0x01, // TXRDY = 1
            ctrl: 0,
            rx_buffer: Vec::new(),
            rx_max: 256,
            tx_buffer: Vec::new(),
            xon_sent: true,
            xoff_sent: false,
            xon_threshold: 50,
            xoff_threshold: 200,
            on_tx_byte: None,
            on_rx_interrupt: None,
        }
    }

    pub fn read(&mut self, reg: u8) -> u8 {
        match reg {
            0 => {
                // Read data — pop from RX buffer
                if !self.rx_buffer.is_empty() {
                    self.data = self.rx_buffer.remove(0);
                }
                // Update RXRDY
                if self.rx_buffer.is_empty() {
                    self.status &= !0x02; // RXRDY = 0
                } else {
                    self.status |= 0x02; // RXRDY = 1
                }
                // XOn check — if we were in XOff and now below threshold, send XOn
                if self.xoff_sent && self.rx_buffer.len() < self.xon_threshold {
                    self.xoff_sent = false;
                    self.xon_sent = true;
                    // The host would send XOn — external handler
                }
                self.data
            }
            1 => self.status, // Status register
            _ => 0xFF,
        }
    }

    pub fn write(&mut self, reg: u8, val: u8) {
        match reg {
            0 => {
                // Write data — push to TX buffer
                self.data = val;
                self.tx_buffer.push(val);
                if let Some(cb) = self.on_tx_byte {
                    cb(val);
                }
            }
            1 => {
                // Control register
                self.ctrl = val;
            }
            _ => {}
        }
    }

    /// Receive byte from external source (terminal/HPGL)
    pub fn receive_byte(&mut self, byte: u8) {
        if self.rx_buffer.len() >= self.rx_max {
            return; // Buffer full, drop
        }
        self.rx_buffer.push(byte);
        self.status |= 0x02; // RXRDY = 1

        // XOn-XOff flow control
        if self.rx_buffer.len() > self.xoff_threshold && !self.xoff_sent {
            self.xoff_sent = true;
            self.xon_sent = false;
            // Insert XOff (0x13) into TX buffer for host
            self.tx_buffer.push(0x13);
            if let Some(cb) = self.on_tx_byte {
                cb(0x13);
            }
        }

        // Trigger interrupt
        if let Some(cb) = self.on_rx_interrupt {
            cb();
        }
    }



}
