#![allow(clippy::upper_case_acronyms)]
mod cpu;
mod memory;
mod ppi8255;
mod pit8253;
mod usart8251;
mod plotter;
mod disasm;
mod hpgl;
mod settings;
mod app;

use eframe::egui;
use app::AftografApp;

fn main() -> eframe::Result<()> {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("Aftograf-882 Debuger v1.0.8")
            .with_inner_size([1400.0, 900.0])
            .with_fullscreen(false),
        ..Default::default()
    };

    eframe::run_native(
        "Aftograf-882 Debuger v1.0.8",
        options,
        Box::new(|_cc| Box::new(AftografApp::new())),
    )
}
