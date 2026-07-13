use std::fs;

fn main() {
    // Emit the firmware data path for use with include_bytes!
    let firmware_path = "assets/firmware.bin";
    let data = fs::read(firmware_path).unwrap_or_else(|_| vec![0xFFu8; 0x6000]);
    let len = data.len();
    let dest_path = std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).join("firmware.rs");
    let code = format!(
        "pub const FIRMWARE_SIZE: usize = {len};\npub static FIRMWARE: [u8; {len}] = {data:?};"
    );
    fs::write(&dest_path, &code).expect("Failed to write firmware.rs");
    println!("cargo:rerun-if-changed=assets/firmware.bin");
}
