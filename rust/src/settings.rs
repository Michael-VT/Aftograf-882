/// Settings Manager — stores configuration
#[derive(Clone)]
pub struct Settings {
    pub chip_offsets: [u16; 3],
    pub var_addrs: std::collections::HashMap<String, u16>,
    pub custom_vars: Vec<CustomVar>,
    pub theme: String,
    pub dip: [bool; 4],
    #[allow(dead_code)]
    pub sound: String,
}

#[derive(Clone)]
#[allow(dead_code)]
pub struct CustomVar {
    pub name: String,
    pub addr: u16,
    pub size: u8,
    pub var_type: String,
    pub id: u64,
}

impl Settings {
    pub fn new() -> Self {
        let mut var_addrs = std::collections::HashMap::new();
        var_addrs.insert("X_POS_LO".to_string(), 0x6180);
        var_addrs.insert("X_POS_HI".to_string(), 0x6181);
        var_addrs.insert("Y_POS_LO".to_string(), 0x6186);
        var_addrs.insert("Y_POS_HI".to_string(), 0x6187);
        var_addrs.insert("PEN_STATE".to_string(), 0x63F0);
        var_addrs.insert("PEN_COLOR".to_string(), 0x61E8);

        Settings {
            chip_offsets: [0x0000, 0x2000, 0x4000],
            var_addrs,
            custom_vars: Vec::new(),
            theme: "dark".to_string(),
            dip: [false, false, false, false],
            sound: "visual".to_string(),
        }
    }

    pub fn get_addr(&self, key: &str) -> u16 {
        self.var_addrs.get(key).copied().unwrap_or(0x6180)
    }

    pub fn set_addr(&mut self, key: &str, addr: u16) {
        self.var_addrs.insert(key.to_string(), addr);
    }

    pub fn add_custom(&mut self, name: &str, addr: u16, size: u8, var_type: &str) {
        use std::time::{SystemTime, UNIX_EPOCH};
        let id = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos() as u64;
        self.custom_vars.push(CustomVar {
            name: name.to_string(),
            addr,
            size,
            var_type: var_type.to_string(),
            id,
        });
    }

    pub fn remove_custom(&mut self, id: u64) {
        self.custom_vars.retain(|v| v.id != id);
    }
}
