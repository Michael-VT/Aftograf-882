use std::cell::Cell;
use crate::cpu::CPU8080;
use crate::memory::MMU;
use crate::ppi8255::PPI8255;
use crate::pit8253::PIT8253;
use crate::usart8251::USART8251;
use crate::plotter::{Plotter, PEN_COLORS};
use crate::disasm::{Disassembler, DisasmInsn, build_optable};
use crate::hpgl::HPGL;
use crate::settings::Settings;
use std::collections::HashSet;
use eframe::egui;

// Include firmware embedded at build time
include!(concat!(env!("OUT_DIR"), "/firmware.rs"));
// Silence unused-constant warning for FIRMWARE_SIZE
#[allow(unused)]
const _: usize = FIRMWARE_SIZE;

// ── Context pointers for CPU callbacks ──
// Single-threaded: set before each step(), cleared after.
// This avoids self-referencing struct issues with fn pointers.
thread_local! {
    static CTX_MMU: Cell<*const MMU> = const { Cell::new(std::ptr::null()) };
    static CTX_MMU_MUT: Cell<*mut MMU> = const { Cell::new(std::ptr::null_mut()) };
    static CTX_UART: Cell<*const USART8251> = const { Cell::new(std::ptr::null()) };
    static CTX_UART_MUT: Cell<*mut USART8251> = const { Cell::new(std::ptr::null_mut()) };
    static CTX_CPU: Cell<*mut CPU8080> = const { Cell::new(std::ptr::null_mut()) };
}

unsafe fn with_mmu<R>(f: impl FnOnce(&MMU) -> R) -> R {
    f(&*CTX_MMU.with(|c| c.get()))
}
unsafe fn with_mmu_mut<R>(f: impl FnOnce(&mut MMU) -> R) -> R {
    f(&mut *CTX_MMU_MUT.with(|c| c.get()))
}
unsafe fn with_uart<R>(f: impl FnOnce(&USART8251) -> R) -> R {
    f(&*CTX_UART.with(|c| c.get()))
}
unsafe fn with_uart_mut<R>(f: impl FnOnce(&mut USART8251) -> R) -> R {
    f(&mut *CTX_UART_MUT.with(|c| c.get()))
}

fn cpu_read_byte(addr: u16) -> u8 {
    unsafe { with_mmu_mut(|mmu| mmu.read_byte(addr)) }
}
fn cpu_write_byte(addr: u16, val: u8) {
    unsafe { with_mmu_mut(|mmu| mmu.write_byte(addr, val)) }
}
fn cpu_in_port(port: u8) -> u8 {
    unsafe { with_uart(|uart| with_mmu(|mmu| {
        match port {
            0x19 => uart.data,
            0x28 => if uart.rx_buffer.is_empty() { 0x01 } else { 0x03 },
            _ => mmu.peek(0xE000 | port as u16),
        }
    }))}
}
fn cpu_out_port(port: u8, val: u8) {
    unsafe { with_uart_mut(|uart| with_mmu_mut(|mmu| {
        match port {
            0x19 => uart.data = val,
            0x28 => uart.ctrl = val,
            _ => { mmu.write_byte(0xE000 | port as u16, val); }
        }
    }))}
}

pub struct AftografApp {
    // Core emulator
    pub ppi1: PPI8255,
    pub ppi2: PPI8255,
    pub pit: PIT8253,
    pub uart: USART8251,
    pub mmu: MMU,
    pub cpu: CPU8080,
    pub plotter: Plotter,

    // State
    pub running: bool,
    pub paused: bool,
    pub rom_loaded: bool,
    pub breakpoints: HashSet<u16>,
    pub speed_idx: usize,
    pub follow_pc: bool,

    // Disassembler
    pub disasm_addr: u16,
    pub asm_hover_addr: Option<u16>,

    // Memory viewer
    pub mem_scroll_addr: u16,
    pub mem_edit_addr: Option<u16>,
    pub mem_view_ver: u64,
    pub mem_edit_buf: String,
    pub hl_addr: u16,

    // USART
    pub usart_hex_input: String,
    pub usart_log: String,

    // HPGL
    pub hpgl: HPGL,

    // Settings
    pub settings: Settings,
    pub show_settings: bool,
    pub show_help: bool,
    pub theme: String,

    // Keyboard state (6 rows × 2 columns)
    pub key_state: [[bool; 2]; 6],

    // Counter for runtime updates
    pub frame_counter: u64,
    pub rom_offset: u16,

    // Optable for disasm
    pub optable: Vec<(u8, &'static str, u8, u8)>,

    // Register edit buffers
    pub reg_edit_a: String,
    pub reg_edit_b: String,
    pub reg_edit_c: String,
    pub reg_edit_d: String,
    pub reg_edit_e: String,
    pub reg_edit_h: String,
    pub reg_edit_l: String,
    pub reg_edit_sp: String,
    pub reg_edit_pc: String,
    pub mem_warning: String,
    pub mem_invalid_write: Option<u16>,

    // Address search edit buffers
    pub disasm_search: String,
    pub mem_search: String,
    // Trace buffer (circular, max 100 entries)
    pub trace_buffer: Vec<String>,
    // HPGL draw up to this line
    pub hpgl_until: String,
}

impl AftografApp {
    pub fn new() -> Self {
        let mut ppi1 = PPI8255::new("PPI1");
        ppi1.write(3, 0x92);
        let mut ppi2 = PPI8255::new("PPI2");
        ppi2.write(3, 0x80);
        let pit = PIT8253::new();
        let uart = USART8251::new();
        let mmu = MMU::new(ppi1.clone(), ppi2.clone(), pit.clone(), uart.clone());

        let optable = build_optable();

        let mut app = AftografApp {
            ppi1, ppi2, pit, uart,
            mmu,
            cpu: CPU8080::new(cpu_read_byte, cpu_write_byte, cpu_in_port, cpu_out_port),
            plotter: Plotter::new(),
            running: false,
            paused: false,
            rom_loaded: false,
            breakpoints: HashSet::new(),
            speed_idx: 0,
            follow_pc: true,
            disasm_addr: 0,
            asm_hover_addr: None,
            mem_scroll_addr: 0,
            mem_view_ver: 0,
            mem_edit_addr: None,
            mem_edit_buf: String::new(),
            hl_addr: 0,
            usart_hex_input: String::new(),
            usart_log: String::new(),
            hpgl: HPGL::new(),
            settings: Settings::new(),
            show_settings: false,
            show_help: false,
            theme: "dark".to_string(),
            key_state: [[false; 2]; 6],
            frame_counter: 0,
            rom_offset: 0,
            optable,
            reg_edit_a: format!("${:02X}", 0u8),
            reg_edit_b: format!("${:02X}", 0u8),
            reg_edit_c: format!("${:02X}", 0u8),
            reg_edit_d: format!("${:02X}", 0u8),
            reg_edit_e: format!("${:02X}", 0u8),
            reg_edit_h: format!("${:02X}", 0u8),
            reg_edit_l: format!("${:02X}", 0u8),
            reg_edit_sp: format!("${:04X}", 0u16),
            reg_edit_pc: format!("${:04X}", 0u16),
            mem_warning: String::new(),
            mem_invalid_write: None,
            mem_search: String::new(),
            trace_buffer: Vec::new(),
            disasm_search: String::new(),
            hpgl_until: String::from("0"),
        };

        // Wire USART callbacks
        app.uart.on_tx_byte = Some(Self::usart_on_tx_byte);
        app.uart.on_rx_interrupt = Some(Self::usart_on_rx_int);

        // Auto-load firmware from embedded binary
        app.load_rom_data(&FIRMWARE);

        app
    }

    fn usart_on_tx_byte(_byte: u8) {
    }

    fn usart_on_rx_int() {
        // Signal interrupt to CPU via thread-local
        CTX_CPU.with(|c| {
            let ptr = c.get();
            if !ptr.is_null() {
                unsafe { (*ptr).intr = true; }
            }
        });
    }

    pub fn step_cpu(&mut self) {
        if !self.rom_loaded || self.cpu.halt { return; }
        self.paused = true;
        self.running = false;

        // Set context pointers for CPU callbacks
        CTX_MMU.with(|c| c.set(&self.mmu as *const MMU));
        CTX_MMU_MUT.with(|c| c.set(&mut self.mmu as *mut MMU));
        CTX_UART.with(|c| c.set(&self.uart as *const USART8251));
        CTX_UART_MUT.with(|c| c.set(&mut self.uart as *mut USART8251));
        CTX_CPU.with(|c| c.set(&mut self.cpu as *mut CPU8080));

        self.record_trace();
        self.cpu.step();

        // Clear context
        CTX_UART.with(|c| c.set(std::ptr::null()));
        CTX_UART_MUT.with(|c| c.set(std::ptr::null_mut()));
        CTX_CPU.with(|c| c.set(std::ptr::null_mut()));
        if self.follow_pc {
            self.disasm_addr = self.cpu.pc.saturating_sub(30);
        }

        self.sync_plotter();
        self.update_all();
    }
    fn record_trace(&mut self) {
        let insn = Disassembler::disasm_instruction(&|a| self.mmu.peek(a), self.cpu.pc, &self.optable);
        let trace = if insn.operands.is_empty() {
            format!("${:04X} {}", insn.addr, insn.mnemonic)
        } else {
            format!("${:04X} {} {}", insn.addr, insn.mnemonic, insn.operands)
        };
        self.trace_buffer.push(trace);
        if self.trace_buffer.len() > 100 {
            self.trace_buffer.remove(0);
        }
    }
    fn sync_plotter(&mut self) {
        // Don't sync firmware segments when HPGL is loaded (would change canvas scale)
        if self.hpgl.total_coords > 0 { return; }

        let x_lo = self.mmu.peek(self.settings.get_addr("X_POS_LO"));
        let x_hi = self.mmu.peek(self.settings.get_addr("X_POS_HI"));
        let y_lo = self.mmu.peek(self.settings.get_addr("Y_POS_LO"));
        let y_hi = self.mmu.peek(self.settings.get_addr("Y_POS_HI"));
        let p_state = self.mmu.peek(self.settings.get_addr("PEN_STATE"));
        let p_color = self.mmu.peek(self.settings.get_addr("PEN_COLOR"));

        let mem_x = ((x_hi as u16) << 8) | x_lo as u16;
        let mem_y = ((y_hi as u16) << 8) | y_lo as u16;
        let mem_pen_down = (p_state & 0x01) != 0;
        let mem_color = p_color & 0x07;

        self.plotter.sync_from_memory(mem_x as i32, mem_y as i32, mem_pen_down, mem_color);
        self.plotter.update_stepper('x', self.ppi1.port_a);
        self.plotter.update_stepper('y', self.ppi1.port_b);
        self.plotter.set_pen(self.ppi2.port_c);
        self.plotter.update_position();
        self.plotter.check_limits();
    }

    fn sync_keyboard(&mut self) {
        // Keyboard matrix: 6 rows × 2 columns
        // PPI2 port A (0xE400) = column select
        // PPI2 port B (0xE401) = row bits for selected column
        let column = self.ppi2.port_a & 0x3F;
        let mut rows: u8 = 0;
        if column != 0 {
            let col = column.trailing_zeros() as usize;
            for c in 0..2 {
                if self.key_state[col][c] {
                    rows |= 1 << c;
                }
            }
        }
        self.ppi2.port_b = rows;
    }
    fn update_all(&mut self) {
        self.sync_reg_buffers();
        self.sync_keyboard();
        self.hl_addr = self.cpu.get_hl();
        self.mem_invalid_write = None;
    }

    fn apply_hpgl_until(&mut self) {
        if let Ok(n) = self.hpgl_until.trim().parse::<usize>() {
            let n = n.min(self.hpgl.generated_segments.len());
            self.plotter.lines.clear();
            self.hpgl.current = 0;
            for i in 0..n {
                self.plotter.lines.push(self.hpgl.generated_segments[i]);
            }
            self.hpgl.current = n;
        }
    }
    #[inline]
    fn disasm_insns(&self, start: u16, count: usize) -> Vec<DisasmInsn> {
        let mut result = Vec::with_capacity(count);
        let mut a = start;
        for _ in 0..count {
            let insn = Disassembler::disasm_instruction(&|addr| self.mmu.peek(addr), a, &self.optable);
            let size = insn.size;
            result.push(insn);
            a = a.wrapping_add(size as u16);
        }
        result
    }

    fn sync_reg_buffers(&mut self) {
        self.reg_edit_a = format!("${:02X}", self.cpu.a);
        self.reg_edit_b = format!("${:02X}", self.cpu.b);
        self.reg_edit_c = format!("${:02X}", self.cpu.c);
        self.reg_edit_d = format!("${:02X}", self.cpu.d);
        self.reg_edit_e = format!("${:02X}", self.cpu.e);
        self.reg_edit_h = format!("${:02X}", self.cpu.h);
        self.reg_edit_l = format!("${:02X}", self.cpu.l);
        self.reg_edit_sp = format!("${:04X}", self.cpu.sp);
        self.reg_edit_pc = format!("${:04X}", self.cpu.pc);
    }

    fn load_rom_data(&mut self, data: &[u8]) {
        if data.len() <= 2048 {
            // Sequential load — append at current offset
            let offset = self.rom_offset as usize;
            if offset + data.len() <= 0x6000 {
                self.mmu.load_rom(data, offset);
                self.rom_offset = (offset + data.len()) as u16;
            }
        } else {
            // Full ROM replacement
            self.rom_offset = 0;
            let mut ppi1 = PPI8255::new("PPI1");
            ppi1.write(3, 0x92);
            let mut ppi2 = PPI8255::new("PPI2");
            ppi2.write(3, 0x80);
            let pit = PIT8253::new();
            let uart = USART8251::new();

            self.ppi1 = ppi1.clone();
            self.ppi2 = ppi2.clone();
            self.pit = pit.clone();
            self.uart = uart.clone();

            self.mmu = MMU::new(ppi1, ppi2, pit, uart);
            self.mmu.load_rom(data, 0);

            // Wire USART callbacks (no captures — fn pointers)
            self.uart.on_tx_byte = Some(|_| {});
            self.uart.on_rx_interrupt = Some(|| {});
        }

        self.rom_loaded = true;
        self.cpu.pc = 0;
        self.disasm_addr = 0;
        self.update_all();
    }
}

impl eframe::App for AftografApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.frame_counter += 1;

        // Apply theme
        let mut style = (*ctx.style()).clone();
        if self.theme == "light" {
            style.visuals = egui::Visuals::light();
            style.visuals.widgets.inactive.bg_fill = egui::Color32::from_rgb(240, 240, 240);
            style.visuals.widgets.hovered.bg_fill = egui::Color32::from_rgb(220, 220, 220);
            style.visuals.window_fill = egui::Color32::from_rgb(250, 250, 250);
            style.visuals.panel_fill = egui::Color32::from_rgb(245, 245, 245);
        } else {
            style.visuals = egui::Visuals::dark();
            // Tokyo Night palette
            style.visuals.window_fill = egui::Color32::from_rgb(26, 27, 38);
            style.visuals.panel_fill = egui::Color32::from_rgb(26, 27, 38);
            style.visuals.widgets.inactive.bg_fill = egui::Color32::from_rgb(40, 42, 54);
            style.visuals.widgets.hovered.bg_fill = egui::Color32::from_rgb(60, 62, 74);
            style.visuals.hyperlink_color = egui::Color32::from_rgb(125, 207, 255);
            style.visuals.selection.bg_fill = egui::Color32::from_rgb(65, 72, 104);
        }
        ctx.set_style(style);

        // Handle keyboard shortcuts
        self.handle_keyboard(ctx);

        // ── Top panel: Controls ──
        egui::TopBottomPanel::top("header_panel").show(ctx, |ui| {
            self.ui_header(ui);
        });

        // ── Left panel: CPU, Flags, Stack, I/O, USART ──
        egui::SidePanel::left("left_panel")
            .resizable(true)
            .default_width(220.0)
            .min_width(180.0)
            .show(ctx, |ui| {
                self.ui_left_panel(ui);
            });

        // ── Right panel: Plotter Canvas ──
        egui::SidePanel::right("right_panel")
            .resizable(true)
            .default_width(320.0)
            .min_width(250.0)
            .show(ctx, |ui| {
                self.ui_right_panel(ui);
            });

        // ── Center panel: Disassembler + Memory ──
        egui::CentralPanel::default().show(ctx, |ui| {
            self.ui_center_panel(ui);
        });

        // ── Settings overlay ──
        if self.show_settings {
            self.ui_settings(ctx);
        }

        // ── Help overlay ──
        if self.show_help {
            self.ui_help(ctx);
        }

        // Continuous repaint while running — execute next batch each frame
        if self.running {
            self.run_cpu();
            ctx.request_repaint();
        }
    }
}

// ── UI Methods ──
impl AftografApp {
    fn ui_header(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            ui.heading("Aftograf-882 Debuger");
            ui.label("v1.0.8".to_string());

            ui.separator();

            // Status
            let status = if self.cpu.halt {
                "HLT"
            } else if self.running {
                "RUNNING"
            } else if self.paused {
                "PAUSED"
            } else {
                "STOPPED"
            };
            let status_color = if self.running {
                egui::Color32::GREEN
            } else if self.cpu.halt {
                egui::Color32::RED
            } else {
                egui::Color32::GRAY
            };
            ui.colored_label(status_color, status);
            ui.label(format!("T-states: {}", self.cpu.cycles));

            ui.separator();

            ui.label(format!("PC: ${:04X}", self.cpu.pc));

            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                if ui.button("?").clicked() { self.show_help = !self.show_help; }
                if ui.button("⚙").clicked() { self.show_settings = !self.show_settings; }
            });
        });

        ui.horizontal(|ui| {
            let btn_h = 22.0;
            if ui.add_enabled(self.rom_loaded, egui::Button::new("↺ Reset").min_size([60.0, btn_h].into())).clicked() {
                self.reset();
            }
            if ui.add_enabled(self.rom_loaded && !self.running, egui::Button::new("→ Step").min_size([60.0, btn_h].into())).clicked() {
                self.step_cpu();
            }
            if !self.running {
                if ui.add_enabled(self.rom_loaded, egui::Button::new("▶ Run").min_size([60.0, btn_h].into())).clicked() {
                    self.run_cpu();
                }
            } else if ui.add(egui::Button::new("⏸ Pause").min_size([60.0, btn_h].into())).clicked() {
                self.pause_cpu();
            }
            ui.separator();

            // Speed slider
            ui.label("Speed:");
            let speeds = ["∞", "100Hz", "1KHz", "10KHz", "100KHz", "1MHz"];
            let speed_label = speeds[self.speed_idx];
            ui.add(egui::Slider::new(&mut self.speed_idx, 0..=5).text(speed_label));

            ui.separator();

            // Load ROM
            if ui.button("📂").clicked() {
                if let Some(path) = rfd::FileDialog::new()
                    .add_filter("ROM", &["bin", "rom"])
                    .pick_file()
                {
                    if let Ok(data) = std::fs::read(&path) {
                        self.load_rom_data(&data);
                    }
                }
            }
        });
    }

    fn ui_left_panel(&mut self, ui: &mut egui::Ui) {
        egui::ScrollArea::vertical()
            .id_source("left_scroll")
            .show(ui, |ui| {
                // ── Registers ──
                ui.collapsing("CPU", |ui| {
                    ui.horizontal(|ui| {
                        ui.label("A:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_a).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_a.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.a = v; }
                            self.reg_edit_a = format!("${:02X}", self.cpu.a);
                        }
                    });
                    ui.horizontal(|ui| {
                        if ui.add(egui::Label::new("BC:").sense(egui::Sense::click())).clicked() {
                            self.mem_scroll_addr = self.cpu.get_bc() & 0xFFF0;
                            self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                            self.mem_view_ver += 1;
                        }
                        ui.label("B:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_b).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_b.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.b = v; }
                            self.reg_edit_b = format!("${:02X}", self.cpu.b);
                        }
                        ui.label("C:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_c).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_c.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.c = v; }
                            self.reg_edit_c = format!("${:02X}", self.cpu.c);
                        }
                    });
                    ui.horizontal(|ui| {
                        if ui.add(egui::Label::new("DE:").sense(egui::Sense::click())).clicked() {
                            self.mem_scroll_addr = self.cpu.get_de() & 0xFFF0;
                            self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                            self.mem_view_ver += 1;
                        }
                        ui.label("D:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_d).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_d.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.d = v; }
                            self.reg_edit_d = format!("${:02X}", self.cpu.d);
                        }
                        ui.label("E:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_e).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_e.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.e = v; }
                            self.reg_edit_e = format!("${:02X}", self.cpu.e);
                        }
                    });
                    ui.horizontal(|ui| {
                        if ui.add(egui::Label::new("HL:").sense(egui::Sense::click())).clicked() {
                            self.mem_scroll_addr = self.cpu.get_hl() & 0xFFF0;
                            self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                            self.mem_view_ver += 1;
                        }
                        ui.label("H:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_h).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_h.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.h = v; }
                            self.reg_edit_h = format!("${:02X}", self.cpu.h);
                        }
                        ui.label("L:");
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_l).desired_width(30.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u8::from_str_radix(self.reg_edit_l.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.l = v; }
                            self.reg_edit_l = format!("${:02X}", self.cpu.l);
                        }
                    });
                    ui.horizontal(|ui| {
                        if ui.add(egui::Label::new("SP:").sense(egui::Sense::click())).clicked() {
                            self.mem_scroll_addr = self.cpu.sp & 0xFFF0;
                            self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                            self.mem_view_ver += 1;
                        }
                        let r = ui.add(egui::TextEdit::singleline(&mut self.reg_edit_sp).desired_width(50.0).font(egui::TextStyle::Monospace));
                        if r.lost_focus() {
                            if let Ok(v) = u16::from_str_radix(self.reg_edit_sp.trim_start_matches("$").trim_start_matches("0x"), 16) { self.cpu.sp = v; }
                            self.reg_edit_sp = format!("${:04X}", self.cpu.sp);
                        }
                    });
                    ui.horizontal(|ui| {
                        ui.label(format!("Cycles: {}", self.cpu.cycles));
                    });
                    ui.horizontal(|ui| {
                        ui.label("Stack:");
                        for i in 0..4 {
                            let addr = self.cpu.sp.wrapping_add(i * 2);
                            if !(0x6000..0xE000).contains(&addr) { continue; }
                            let lo = self.mmu.peek(addr) as u16;
                            let hi = self.mmu.peek(addr.wrapping_add(1)) as u16;
                            let val = lo | (hi << 8);
                            if val != 0 && val >= 0x100 {
                                ui.monospace(format!("${val:04X}"));
                            }
                        }
                    });
                });
                // ── Flags ──
                ui.collapsing("Flags", |ui| {
                    let s = self.cpu.get_state();
                    let f = s.flags;
                    ui.horizontal(|ui| {
                        let flag_labels = [("S", 0x80), ("Z", 0x40), ("AC", 0x10), ("P", 0x04), ("CY", 0x01)];
                        for (label, bit) in &flag_labels {
                            let active = f & bit != 0;
                            let btn = if active {
                                egui::Button::new(*label).fill(egui::Color32::from_rgb(80, 180, 80))
                            } else {
                                egui::Button::new(*label)
                            };
                            if ui.add_sized([28.0, 20.0], btn).clicked() {
                                self.cpu.flags ^= bit;
                                self.cpu.flags |= 0x02;
                            }
                        }
                    });
                });
                // ── Sensors (DIP switches + End stops) ──
                ui.collapsing("Sensors", |ui| {
                    ui.label("DIP (D7-D4)");
                    ui.horizontal(|ui| {
                        for bit in (4..=7).rev() {
                            let val = (self.ppi1.port_a >> bit) & 1;
                            let mut checked = val != 0;
                            if ui.toggle_value(&mut checked, format!("{}", bit - 3)).clicked() {
                                if checked { self.ppi1.port_a |= 1 << bit; }
                                else { self.ppi1.port_a &= !(1 << bit); }
                            }
                        }
                    });
                    ui.label("END (D3-D0)");
                    ui.horizontal(|ui| {
                        for bit in (0..=3).rev() {
                            let val = (self.ppi1.port_a >> bit) & 1;
                            let mut checked = val != 0;
                            if ui.toggle_value(&mut checked, format!("{bit}")).clicked() {
                                if checked { self.ppi1.port_a |= 1 << bit; }
                                else { self.ppi1.port_a &= !(1 << bit); }
                            }
                        }
                    });
                });

                // ── Current Instruction ──
                ui.collapsing("Current", |ui| {
                    let pc = self.cpu.pc;
                    let insn = Disassembler::disasm_instruction(&|a| self.mmu.peek(a), pc, &self.optable);
                    let bytes = insn.bytes.iter().map(|b| format!("{b:02X}")).collect::<Vec<_>>().join(" ");
                    ui.monospace(format!("{} {}", insn.mnemonic, insn.operands));
                    ui.label(format!("Bytes: {bytes}"));
                });

                // ── Stack (50 words) ──
                ui.collapsing("Stack", |ui| {
                    let sp = self.cpu.sp;
                    for i in 0..50 {
                        let addr = sp.wrapping_add((i * 2) as u16);
                        let lo = self.mmu.peek(addr);
                        let hi = self.mmu.peek(addr.wrapping_add(1));
                        let val = ((hi as u16) << 8) | lo as u16;
                        let marker = if i == 0 { "→SP" } else { "   " };
                        ui.horizontal(|ui| {
                            ui.label(marker);
                            ui.monospace(format!("${addr:04X}"));
                            ui.monospace(format!("${val:04X}"));
                        });
                    }
                });

                // ── Trace (last 30 instructions) ──
                if !self.trace_buffer.is_empty() {
                    ui.collapsing("Trace", |ui| {
                        egui::ScrollArea::vertical().max_height(120.0).show(ui, |ui| {
                            for entry in self.trace_buffer.iter().rev().take(30) {
                                ui.monospace(entry);
                            }
                        });
                    });
                }

                // ── Pointers ──
                ui.collapsing("Pointers", |ui| {
                    let s = self.cpu.get_state();
                    let hl = (s.h as u16) << 8 | s.l as u16;
                    let de = (s.d as u16) << 8 | s.e as u16;
                    let bc = (s.b as u16) << 8 | s.c as u16;
                    ui.monospace(format!("HL: ${:04X} → [${:04X}]", hl, (self.mmu.peek(hl.wrapping_add(1)) as u16) << 8 | self.mmu.peek(hl) as u16));
                    ui.monospace(format!("DE: ${:04X} → [${:04X}]", de, (self.mmu.peek(de.wrapping_add(1)) as u16) << 8 | self.mmu.peek(de) as u16));
                    ui.monospace(format!("BC: ${:04X} → [${:04X}]", bc, (self.mmu.peek(bc.wrapping_add(1)) as u16) << 8 | self.mmu.peek(bc) as u16));
                    ui.monospace(format!("SP: ${:04X} → [${:04X}]", s.sp, (self.mmu.peek(s.sp.wrapping_add(1)) as u16) << 8 | self.mmu.peek(s.sp) as u16));
                    ui.monospace(format!("PC: ${:04X}", s.pc));
                });

                // ── I/O Devices ──
                ui.collapsing("I/O Devices", |ui| {
                    ui.label("PPI1 (КР580ВВ55А #1)");
                    ui.monospace(format!("A: {:02X}  B: {:02X}  C: {:02X}", self.ppi1.port_a, self.ppi1.port_b, self.ppi1.port_c));
                    ui.label("PPI2 (КР580ВВ55А #2)");
                    ui.monospace(format!("A: {:02X}  B: {:02X}  C: {:02X}", self.ppi2.port_a, self.ppi2.port_b, self.ppi2.port_c));
                    ui.label("PIT (КР580ВИ53)");
                    for (i, ctr) in self.pit.counters.iter().enumerate() {
                        ui.monospace(format!("CNT{}: ${:04X} mode={}", i, ctr.val, ctr.mode));
                    }
                    ui.label("USART (КР580ВВ51А)");
                    let txrdy = if self.uart.status & 0x01 != 0 { "✓" } else { "✕" };
                    let rxrdy = if self.uart.status & 0x02 != 0 { "✓" } else { "✕" };
                    ui.monospace(format!("TXRDY:{} RXRDY:{} RX:{} TX:{}", txrdy, rxrdy, self.uart.rx_buffer.len(), self.uart.tx_buffer.len()));
                });

                // ── USART Terminal ──
                ui.collapsing("USART", |ui| {
                    ui.horizontal(|ui| {
                        let resp = ui.add(
                            egui::TextEdit::singleline(&mut self.usart_hex_input)
                                .hint_text("hex bytes (01 02 FF)")
                                .desired_width(120.0)
                        );
                        if resp.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter)) {
                            self.send_usart_bytes();
                        }
                        if ui.button("Send").clicked() { self.send_usart_bytes(); }
                    });
                    egui::ScrollArea::vertical().max_height(80.0).show(ui, |ui| {
                        ui.label(&self.usart_log);
                    });
                });

                // ── Keyboard Matrix ──
                ui.collapsing("Keyboard", |ui| {
                    ui.label("6×2 matrix");
                    for r in 0..6 {
                        ui.horizontal(|ui| {
                            ui.label(format!("Row{r}:"));
                            for c in 0..2 {
                                let label = format!("K{r}{c}");
                                let was = self.key_state[r][c];
                                if ui.selectable_label(was, label).clicked() {
                                    self.key_state[r][c] = !was;
                                }
                            }
                        });
                    }
                });

                ui.collapsing("Limits & LEDs", |ui| {
                    let led_on = |bit: u8| (self.ppi1.port_c & (1 << bit)) != 0;
                    ui.horizontal(|ui| {
                        for i in 2..=5 {
                            let color = if led_on(i) { egui::Color32::GREEN } else { egui::Color32::DARK_GRAY };
                            let (rect, _) = ui.allocate_exact_size(egui::vec2(14.0, 14.0), egui::Sense::hover());
                            ui.painter().circle_filled(rect.center(), 6.0, color);
                        }
                    });
                    ui.label(format!("Xmin:{}  Xmax:{}  Ymin:{}  Ymax:{}",
                        if self.plotter.limit_xmin { "●" } else { "○" },
                        if self.plotter.limit_xmax { "●" } else { "○" },
                        if self.plotter.limit_ymin { "●" } else { "○" },
                        if self.plotter.limit_ymax { "●" } else { "○" }));
                    ui.label(format!("PenUp:{}  PenDn:{}",
                        if self.plotter.limit_pen_up { "●" } else { "○" },
                        if self.plotter.limit_pen_dn { "●" } else { "○" }));
                });
                // ── HPGL Commands ──
                if !self.hpgl.hpgl_lines.is_empty() {
                    ui.collapsing("HPGL Команды", |ui| {
                        ui.label(format!("Всего строк: {}, сегментов: {}", 
                            self.hpgl.hpgl_lines.len(), self.hpgl.generated_segments.len()));
                        // Render mode toggle
                        ui.horizontal(|ui| {
                            ui.toggle_value(&mut self.hpgl.hpgl_render, "🎨").clicked();
                            ui.label(if self.hpgl.hpgl_render { "Preview" } else { "→ Sim" });
                        });
                        // Current line indicator
                        let done = self.hpgl.current.min(self.hpgl.generated_segments.len());
                        let total = self.hpgl.total_coords.max(1);
                        ui.label(format!("Строка: {}/{} ({:.0}%)", done, total, 
                            done as f32 / total as f32 * 100.0));
                        // Navigation + Load
                        ui.horizontal(|ui| {
                            if ui.button("▶ Next").clicked() && self.hpgl.current < self.hpgl.generated_segments.len() {
                                self.plotter.lines.push(self.hpgl.generated_segments[self.hpgl.current]);
                                self.hpgl.current += 1;
                            }
                            if ui.button("▶▶ All").clicked() {
                                for i in self.hpgl.current..self.hpgl.generated_segments.len() {
                                    self.plotter.lines.push(self.hpgl.generated_segments[i]);
                                }
                                self.hpgl.current = self.hpgl.generated_segments.len();
                            }
                            if ui.button("⟲ Reset").clicked() {
                                self.hpgl.current = 0;
                                self.plotter.lines.clear();
                            }
                            if ui.button("📂").clicked() {
                                if let Some(path) = rfd::FileDialog::new()
                                    .add_filter("HPGL", &["hpgl", "plt"])
                                    .pick_file()
                                {
                                    if let Ok(data) = std::fs::read_to_string(&path) {
                                        self.hpgl.parse(&data);
                                        self.plotter.lines.clear();
                                        self.hpgl.current = self.hpgl.generated_segments.len();
                                        self.hpgl.total_coords = self.hpgl.generated_segments.len();
                                        self.plotter.lines.extend(self.hpgl.generated_segments.clone());
                                    }
                                }
                            }
                        });
                        // "Draw up to line N"
                        ui.horizontal(|ui| {
                            ui.label("До:");
                            if ui.add(egui::TextEdit::singleline(&mut self.hpgl_until).desired_width(40.0).font(egui::TextStyle::Monospace)).lost_focus() {
                                self.apply_hpgl_until();
                            }
                            if ui.button("Go").clicked() {
                                self.apply_hpgl_until();
                            }
                        });
                        // Command list — focused around active line
                        egui::ScrollArea::vertical()
                            .id_source(("hpgl_cmds", self.hpgl.current))
                            .max_height(200.0)
                            .show(ui, |ui| {
                                let total = self.hpgl.hpgl_lines.len();
                                let mid = self.hpgl.current.min(total.saturating_sub(1));
                                let from = mid.saturating_sub(5);
                                let to = (mid + 6).min(total);
                                for i in from..to {
                                    let line = &self.hpgl.hpgl_lines[i];
                                    let is_active = i == self.hpgl.current && i < self.hpgl.generated_segments.len();
                                    ui.horizontal(|ui| {
                                        if is_active { 
                                            ui.colored_label(egui::Color32::YELLOW, line);
                                            ui.label(format!(" ← строка {i}"));
                                        } else {
                                            ui.monospace(line);
                                        }
                                    });
                                }
                            });
                    });
                }
            });
    }

    fn ui_center_panel(&mut self, ui: &mut egui::Ui) {
        let avail = ui.available_height();
        let disasm_height = (avail * 0.55).max(150.0);
        // ── Disassembler (top 55%) ──

        // ── Disassembler (top 55%) — fixed 60 lines, PC always centered ──
        ui.horizontal(|ui| {
            ui.label("Disassembler");
            if self.disasm_search.is_empty() {
                self.disasm_search = format!("{:04X}", self.disasm_addr);
            }
            if ui.add(egui::TextEdit::singleline(&mut self.disasm_search).desired_width(60.0).font(egui::TextStyle::Monospace)).lost_focus() {
                if let Ok(addr) = u16::from_str_radix(self.disasm_search.trim_start_matches("$").trim_start_matches("0x"), 16) {
                    self.disasm_addr = addr;
                }
            }
            if ui.button("Go").clicked() {
                if let Ok(addr) = u16::from_str_radix(self.disasm_search.trim_start_matches("$").trim_start_matches("0x"), 16) {
                    self.disasm_addr = addr;
                }
            }
            if ui.button("◀").clicked() {
                self.disasm_addr = self.disasm_addr.saturating_sub(0x10);
                self.disasm_search = format!("{:04X}", self.disasm_addr);
            }
            if ui.button("▶").clicked() {
                self.disasm_addr = self.disasm_addr.saturating_add(0x10);
                self.disasm_search = format!("{:04X}", self.disasm_addr);
            }
            if self.follow_pc {
                ui.colored_label(egui::Color32::GREEN, "●");
            }
            ui.checkbox(&mut self.follow_pc, "PC");
        });
        let pc = self.cpu.pc;

        const DISASM_LINES: usize = 60; // fits in available height, PC centered at line 30
        let insns = self.disasm_insns(self.disasm_addr, DISASM_LINES);

        egui::ScrollArea::vertical()
            .id_source(("disasm_scroll", self.disasm_addr, self.follow_pc))
            .max_height(disasm_height)
            .show(ui, |ui| {
                egui::Grid::new("disasm_grid")
                    .striped(true)
                    .min_col_width(20.0)
                    .show(ui, |ui| {
                        for insn in insns.iter() {
                            let is_current = insn.addr == pc;
                            let has_bp = self.breakpoints.contains(&insn.addr);

                            let bp_str = if has_bp { "●" } else { " " };
                            let bp_resp = ui.selectable_label(is_current, bp_str);
                            if bp_resp.clicked() {
                                if has_bp { self.breakpoints.remove(&insn.addr); }
                                else { self.breakpoints.insert(insn.addr); }
                            }
                            if bp_resp.hovered() || bp_resp.is_pointer_button_down_on() {
                                self.asm_hover_addr = Some(insn.addr);
                            }

                            let addr_str = format!("${:04X}", insn.addr);
                            let bytes_str = Disassembler::format_bytes(&insn.bytes);
                            let mnem = &insn.mnemonic;
                            let oper = &insn.operands;

                            if is_current {
                                ui.colored_label(egui::Color32::from_rgb(125, 207, 255), addr_str);
                                ui.colored_label(egui::Color32::from_rgb(125, 207, 255), &bytes_str);
                                ui.colored_label(egui::Color32::from_rgb(125, 207, 255), mnem);
                                ui.colored_label(egui::Color32::from_rgb(125, 207, 255), oper);
                            } else {
                                ui.monospace(addr_str);
                                ui.monospace(bytes_str);
                                ui.monospace(mnem);
                                ui.monospace(oper);
                            }

                            if !insn.annotation.is_empty() {
                                ui.colored_label(egui::Color32::GRAY, &insn.annotation);
                            } else {
                                ui.label("");
                            }

                            ui.end_row();
                        }
                    });
            });
        ui.separator();

        // ── Memory (bottom 45%) ──
        ui.horizontal(|ui| {
            ui.label("Memory");
            if self.mem_search.is_empty() {
                self.mem_search = format!("{:04X}", self.mem_scroll_addr);
            }
            if ui.add(egui::TextEdit::singleline(&mut self.mem_search).desired_width(60.0).font(egui::TextStyle::Monospace)).lost_focus() {
                if let Ok(addr) = u16::from_str_radix(self.mem_search.trim_start_matches("$").trim_start_matches("0x"), 16) {
                    self.mem_scroll_addr = addr & 0xFFF0;
                    self.mem_view_ver += 1;
                }
            }
            if ui.button("Go").clicked() {
                if let Ok(addr) = u16::from_str_radix(self.mem_search.trim_start_matches("$").trim_start_matches("0x"), 16) {
                    self.mem_scroll_addr = addr & 0xFFF0;
                    self.mem_view_ver += 1;
                }
            }
            if ui.button("◀").clicked() {
                self.mem_scroll_addr = self.mem_scroll_addr.saturating_sub(0x100);
                self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                self.mem_view_ver += 1;
            }
            if ui.button("▶").clicked() {
                self.mem_scroll_addr = self.mem_scroll_addr.saturating_add(0x100);
                self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                self.mem_view_ver += 1;
            }
            if ui.button("HL").clicked() {
                self.mem_scroll_addr = self.cpu.get_hl() & 0xFFF0;
                self.mem_search = format!("{:04X}", self.mem_scroll_addr);
                self.mem_view_ver += 1;
            }
            if ui.button("↺").clicked() { }
        });
        if !self.mem_warning.is_empty() {
            ui.colored_label(egui::Color32::RED, &self.mem_warning);
        }
        let num_rows = 64u16;
        let start_addr = self.mem_scroll_addr;
        egui::ScrollArea::vertical()
            .id_source(("mem_scroll", self.mem_view_ver >> 1))
            .show(ui, |ui| {
                for r in 0..num_rows {
                    let base = start_addr.wrapping_add(r * 16);
                    let addr_str = format!("${base:04X}");
                    let is_rom = base < 0x6000;
                    let is_ram = (0x6000..=0x67FF).contains(&base);
                    let addr_color = if is_rom { egui::Color32::from_rgb(101, 67, 33) }
                        else if is_ram { egui::Color32::from_rgb(210, 180, 40) }
                        else if (0xE000..0xE400).contains(&base) { egui::Color32::from_rgb(200, 100, 100) }
                        else if (0xE400..0xE800).contains(&base) { egui::Color32::from_rgb(100, 180, 200) }
                        else if (0xE800..0xEC00).contains(&base) { egui::Color32::from_rgb(180, 150, 80) }
                        else if (0xEC00..0xF000).contains(&base) { egui::Color32::from_rgb(150, 100, 200) }
                        else { egui::Color32::WHITE };
                    ui.horizontal(|ui| {
                        ui.colored_label(addr_color, addr_str);
                        for c in 0..16u16 {
                            let byte_addr = base.wrapping_add(c);
                            let v = self.mmu.peek(byte_addr);
                            let is_hl = byte_addr == self.hl_addr;
                            let byte_color = if is_hl { egui::Color32::from_rgb(255, 158, 100) }
                                else if (0xE000..0xE400).contains(&byte_addr) { egui::Color32::from_rgb(200, 100, 100) }
                                else if (0xE400..0xE800).contains(&byte_addr) { egui::Color32::from_rgb(100, 180, 200) }
                                else if (0xE800..0xEC00).contains(&byte_addr) { egui::Color32::from_rgb(180, 150, 80) }
                                else if (0xEC00..0xF000).contains(&byte_addr) { egui::Color32::from_rgb(150, 100, 200) }
                                else if (0x6000..=0x67FF).contains(&byte_addr) { egui::Color32::from_rgb(220, 200, 80) }
                                else if byte_addr < 0x6000 { egui::Color32::from_rgb(139, 90, 43) }
                                else { egui::Color32::WHITE };
                            let byte_str = format!("{v:02X}");
                            let resp = ui.add(egui::Label::new(
                                egui::RichText::new(&byte_str).color(byte_color).monospace()
                            ).sense(egui::Sense::click()));
                            if resp.double_clicked() {
                                self.mem_edit_addr = Some(byte_addr);
                                self.mem_edit_buf = byte_str.clone();
                            }
                            if self.mem_edit_addr == Some(byte_addr) {
                                let ted = ui.add(egui::TextEdit::singleline(&mut self.mem_edit_buf)
                                    .desired_width(18.0)
                                    .font(egui::TextStyle::Monospace)
                                    .char_limit(2));
                                if ted.lost_focus() || ui.input(|i| i.key_pressed(egui::Key::Enter)) {
                                    if (0x6000..=0x67FF).contains(&byte_addr) || (0xE000..=0xEFFF).contains(&byte_addr) {
                                        if let Ok(v) = u8::from_str_radix(self.mem_edit_buf.trim(), 16) {
                                            self.mmu.poke(byte_addr, v);
                                            self.mem_warning = String::new();
                                        }
                                    } else {
                                        let region = if byte_addr < 0x6000 { "ROM" } else { "свободная" };
                                        self.mem_warning = format!("⚠ Ошибка: {region} ${byte_addr:04X} — запись невозможна");
                                        self.mem_invalid_write = Some(byte_addr);
                                    }
                                    self.mem_edit_addr = None;
                                }
                            }
                        }
                        // ASCII
                        ui.label(" |");
                        let mut ascii_str = String::with_capacity(16);
                        for c in 0..16u16 {
                            let byte_addr = base.wrapping_add(c);
                            let v = self.mmu.peek(byte_addr);
                            ascii_str.push(if (32..=126).contains(&v) { v as char } else { '.' });
                        }
                        ui.add(egui::Label::new(egui::RichText::new(&ascii_str).monospace()));
                    });
                }
            });
    }

    fn ui_right_panel(&mut self, ui: &mut egui::Ui) {
        ui.heading("Plotter (A4)");
        
        // Canvas — integer pixel size, no floating drift
        let cw = ui.available_width() as u32;
        let ch = ((cw as f32) * std::f32::consts::SQRT_2) as u32;
        let (rect, _) = ui.allocate_exact_size(
            egui::vec2(cw.max(100) as f32, ch.max(100) as f32),
            egui::Sense::click(),
        );
        {
            let painter = ui.painter();
            self.paint_plotter(painter, rect);
        }
        
        // Info + controls — in ScrollArea if they overflow
        egui::ScrollArea::vertical()
            .id_source("plotter_controls")
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    let _c = PEN_COLORS[self.plotter.pen_num as usize];
                    ui.label(format!("X:{} Y:{}", self.plotter.x_pos, self.plotter.y_pos));
                });
                ui.horizontal(|ui| {
                    let pen_status = if self.plotter.pen_down { "↓" } else { "↑" };
                    ui.label(format!("Перо: {} #{}", pen_status, self.plotter.pen_num + 1));
                    let c = PEN_COLORS[self.plotter.pen_num as usize];
                    ui.colored_label(egui::Color32::from_rgb(
                        u8::from_str_radix(&c.1[1..3], 16).unwrap_or(0),
                        u8::from_str_radix(&c.1[3..5], 16).unwrap_or(0),
                        u8::from_str_radix(&c.1[5..7], 16).unwrap_or(0),
                    ), c.0);
                });
                if self.hpgl.total_coords > 0 {
                    let total = self.hpgl.total_coords;
                    let done = self.hpgl.current.min(total);
                    let pct = if total > 0 { done as f32 / total as f32 * 100.0 } else { 0.0 };
                    ui.horizontal(|ui| {
                        ui.add(egui::ProgressBar::new(pct / 100.0).text(format!("{pct:.0}%")));
                        ui.label(format!("{done}/{total}"));
                    });
                }
                ui.horizontal(|ui| {
                    if ui.button("🗑 Clear").clicked() {
                        self.plotter.lines.clear();
                        self.hpgl.current = 0;
                        self.hpgl.total_coords = 0;
                    }
                    if ui.button("📂 Load HPGL").clicked() {
                        if let Some(path) = rfd::FileDialog::new()
                            .add_filter("HPGL", &["hpgl", "plt"])
                            .pick_file()
                        {
                            if let Ok(data) = std::fs::read_to_string(&path) {
                                self.hpgl.parse(&data);
                                self.plotter.lines.clear();
                                self.hpgl.current = self.hpgl.generated_segments.len();
                                self.hpgl.total_coords = self.hpgl.generated_segments.len();
                                self.plotter.lines.extend(self.hpgl.generated_segments.clone());
                            }
                        }
                    }
                });
            });
    }

    fn paint_plotter(&self, painter: &egui::Painter, rect: egui::Rect) {
        let w = rect.width();
        let h = rect.height();

        // Background (paper)
        painter.rect_filled(rect, 0.0, egui::Color32::from_rgb(245, 240, 232));

        // Collect segments
        let all_segments = &self.plotter.lines;
        if all_segments.is_empty() {
            // Placeholder
            painter.text(
                rect.center(),
                egui::Align2::CENTER_CENTER,
                "Ожидание команд плоттера…",
                egui::FontId::proportional(14.0),
                egui::Color32::from_rgb(180, 170, 150),
            );
            return;
        }

        // Scale
        let mut min_x = i32::MAX; let mut max_x = i32::MIN;
        let mut min_y = i32::MAX; let mut max_y = i32::MIN;
        for seg in all_segments {
            min_x = min_x.min(seg.x1).min(seg.x2);
            max_x = max_x.max(seg.x1).max(seg.x2);
            min_y = min_y.min(seg.y1).min(seg.y2);
            max_y = max_y.max(seg.y1).max(seg.y2);
        }
        let range_x = ((max_x - min_x).max(1)) as f32;
        let range_y = ((max_y - min_y).max(1)) as f32;
        let margin = 30.0;
        let scale = ((w - 2.0 * margin) / range_x).min((h - 2.0 * margin) / range_y);
        let sx = |x: i32| rect.left() + margin + (x - min_x) as f32 * scale;
        let sy = |y: i32| rect.top() + h - margin - (y - min_y) as f32 * scale;

        // Grid
        let grid_color = egui::Color32::from_rgb(210, 200, 180);
        for i in 0..10 {
            let x = rect.left() + margin + (w - 2.0 * margin) * i as f32 / 10.0;
            let y_top = rect.top() + margin;
            let y_bot = rect.bottom() - margin;
            painter.line_segment([egui::pos2(x, y_top), egui::pos2(x, y_bot)], (0.5, grid_color));

            let y = rect.top() + margin + (h - 2.0 * margin) * i as f32 / 10.0;
            let x_l = rect.left() + margin;
            let x_r = rect.right() - margin;
            painter.line_segment([egui::pos2(x_l, y), egui::pos2(x_r, y)], (0.5, grid_color));
        }

        // Draw lines per pen color
        for seg in all_segments {
            let c = PEN_COLORS[seg.pen as usize].1;
            let r = u8::from_str_radix(&c[1..3], 16).unwrap_or(0);
            let g = u8::from_str_radix(&c[3..5], 16).unwrap_or(0);
            let b = u8::from_str_radix(&c[5..7], 16).unwrap_or(0);
            painter.line_segment(
                [egui::pos2(sx(seg.x1), sy(seg.y1)), egui::pos2(sx(seg.x2), sy(seg.y2))],
                (2.0, egui::Color32::from_rgb(r, g, b)),
            );
        }

        // Pen cursor
        let cx = sx(self.plotter.x_pos);
        let cy = sy(self.plotter.y_pos);
        let pen_c = PEN_COLORS[self.plotter.pen_num as usize].1;
        let pr = u8::from_str_radix(&pen_c[1..3], 16).unwrap_or(0);
        let pg = u8::from_str_radix(&pen_c[3..5], 16).unwrap_or(0);
        let pb = u8::from_str_radix(&pen_c[5..7], 16).unwrap_or(0);
        let pen_color = egui::Color32::from_rgb(pr, pg, pb);
        let alpha = if self.plotter.pen_down { 1.0 } else { 0.5 };

        painter.circle_filled(egui::pos2(cx, cy), 3.0, pen_color.linear_multiply(alpha));
    }

    fn ui_settings(&mut self, ctx: &egui::Context) {
        let mut open = self.show_settings;
        egui::Window::new("Настройки")
            .id(egui::Id::new("settings"))
            .anchor(egui::Align2::CENTER_CENTER, [0.0, 0.0])
            .resizable(true)
            .default_size([400.0, 400.0])
            .open(&mut open)
            .show(ctx, |ui| {
                ui.heading("Настройки");
                ui.separator();

                egui::ScrollArea::vertical().show(ui, |ui| {
                    // Watch variables
                    ui.label("Адреса переменных:");
                    let vars = [("X_POS_LO", 0x6180), ("X_POS_HI", 0x6181),
                                ("Y_POS_LO", 0x6186), ("Y_POS_HI", 0x6187),
                                ("PEN_STATE", 0x63F0), ("PEN_COLOR", 0x61E8)];
                    for (name, default) in &vars {
                        let addr = self.settings.get_addr(name);
                        let mut addr_str = format!("{addr:04X}");
                        ui.horizontal(|ui| {
                            ui.label(*name);
                            if ui.add(egui::TextEdit::singleline(&mut addr_str).desired_width(50.0)).changed() {
                                if let Ok(a) = u16::from_str_radix(&addr_str, 16) {
                                    self.settings.set_addr(name, a);
                                }
                            }
                            ui.monospace(format!("(default: ${default:04X})"));
                        });
                    }

                    ui.separator();

                    // DIP switches
                    ui.label("DIP-переключатели:");
                    for i in 0..4 {
                        let mut val = self.settings.dip[i];
                        if ui.checkbox(&mut val, format!("SW{}", i + 1)).changed() {
                            self.settings.dip[i] = val;
                        }
                    }

                    ui.separator();

                    // Theme
                    ui.horizontal(|ui| {
                        ui.label("Тема:");
                        let _themes = ["dark", "light"];
                        let mut theme_idx = if self.theme == "light" { 1 } else { 0 };
                        if ui.radio_value(&mut theme_idx, 0, "Тёмная").clicked() {
                            self.theme = "dark".to_string();
                            self.settings.theme = "dark".to_string();
                        }
                        if ui.radio_value(&mut theme_idx, 1, "Светлая").clicked() {
                            self.theme = "light".to_string();
                            self.settings.theme = "light".to_string();
                        }
                    });

                    ui.separator();

                    // ROM chip offsets
                    ui.label("ROM chip offsets:");
                    for i in 0..3 {
                        let offset = self.settings.chip_offsets[i];
                        let mut s = format!("{offset:04X}");
                        ui.horizontal(|ui| {
                            ui.label(format!("Chip {}:", i + 1));
                            if ui.add(egui::TextEdit::singleline(&mut s).desired_width(50.0)).changed() {
                                if let Ok(a) = u16::from_str_radix(&s, 16) {
                                    self.settings.chip_offsets[i] = a & 0xFFF0;
                                }
                            }
                        });
                    }

                    ui.separator();

                    // Custom variables
                    ui.label("Пользовательские переменные:");
                    for var in &self.settings.custom_vars.clone() {
                        ui.horizontal(|ui| {
                            ui.label(&var.name);
                            ui.monospace(format!("${:04X}", var.addr));
                            if ui.button("×").clicked() {
                                self.settings.remove_custom(var.id);
                            }
                        });
                    }
                    if ui.button("+ Add Custom").clicked() {
                        let count = self.settings.custom_vars.len() + 1;
                        self.settings.add_custom(&format!("var{count}"), 0x6000, 1, "uint8");
                    }

                    ui.separator();

                    // Load firmware button
                    if ui.button("📂 Load Firmware").clicked() {
                        if let Some(path) = rfd::FileDialog::new()
                            .add_filter("ROM", &["bin", "rom"])
                            .pick_file()
                        {
                            if let Ok(data) = std::fs::read(&path) {
                                self.load_rom_data(&data);
                            }
                        }
                    }
            });         // close ScrollArea.show()
            });         // close Window.show()
        self.show_settings = open;
    }

    fn ui_help(&mut self, ctx: &egui::Context) {
        egui::Window::new("Подсказка")
            .id(egui::Id::new("help"))
            .anchor(egui::Align2::CENTER_CENTER, [0.0, 0.0])
            .resizable(true)
            .default_size([350.0, 400.0])
            .open(&mut self.show_help)
            .show(ctx, |ui| {
                ui.heading("Подсказка");
                ui.separator();

                ui.label("Клавиатурные сокращения:");
                ui.label("Space/→ — Step");
                ui.label("R — Reset CPU");
                ui.label("F5 — Run/Pause");
                ui.label("B — Breakpoint на PC");
                ui.label("J — Jump PC к адресу под курсором");
                ui.label("? / / — Эта подсказка");
                ui.label("Esc — Закрыть");

                ui.separator();
                ui.label("Мышь:");
                ui.label("Клик по флагу — переключить");
                ui.label("Клик по строке дизассемблера — BP");
                ui.label("Клик по байту памяти — редактировать");

                ui.separator();
                ui.label("Цветовая легенда памяти:");
                ui.colored_label(egui::Color32::from_rgb(139, 90, 43), "██ ПЗУ (ROM) $0000-$5FFF");
                ui.colored_label(egui::Color32::from_rgb(220, 200, 80), "██ ОЗУ (RAM) $6000-$67FF");
                ui.colored_label(egui::Color32::from_rgb(200, 100, 100), "██ PPI1 $E000-$E3FF");
                ui.colored_label(egui::Color32::from_rgb(100, 180, 200), "██ PPI2 $E400-$E7FF");
                ui.colored_label(egui::Color32::from_rgb(180, 150, 80), "██ PIT $E800-$EBFF");
                ui.colored_label(egui::Color32::from_rgb(150, 100, 200), "██ USART $EC00-$EFFF");
                ui.colored_label(egui::Color32::WHITE, "██ Не используется (unmapped)");
                ui.colored_label(egui::Color32::RED, "██ Ошибка записи");

                ui.separator();
                ui.label("Советы:");
            });
    }

    fn handle_keyboard(&mut self, ctx: &egui::Context) {
        ctx.input_mut(|i| {
            for event in &i.events {
                if let egui::Event::Key { key, pressed: true, .. } = event {
                    match key {
                        egui::Key::Space | egui::Key::ArrowRight => {
                            self.step_cpu();
                        }
                        egui::Key::R => {
                            self.reset();
                        }
                        egui::Key::F5 => {
                            if self.running { self.pause_cpu(); }
                            else { self.run_cpu(); }
                        }
                        egui::Key::B => {
                            let pc = self.cpu.pc;
                            if self.breakpoints.contains(&pc) {
                                self.breakpoints.remove(&pc);
                            } else {
                                self.breakpoints.insert(pc);
                            }
                        }
                        egui::Key::J => {
                            if let Some(addr) = self.asm_hover_addr {
                                self.cpu.pc = addr;
                                self.update_all();
                            }
                        }
                        egui::Key::F1 => {
                            self.show_help = !self.show_help;
                        }
                        egui::Key::Slash | egui::Key::Questionmark => {
                        }
                        egui::Key::Escape => {
                            self.show_help = false;
                            self.show_settings = false;
                        }
                        _ => {}
                    }
                }
            }
        });
    }

    fn reset(&mut self) {
        self.paused = false;
        self.running = false;
        self.cpu.reset();
        self.plotter.reset();
        self.update_all();
    }

    fn run_cpu(&mut self) {
        if !self.rom_loaded { return; }
        self.running = true;
        self.paused = false;

        // Set context pointers for CPU callbacks
        CTX_MMU.with(|c| c.set(&self.mmu as *const MMU));
        CTX_MMU_MUT.with(|c| c.set(&mut self.mmu as *mut MMU));
        CTX_UART.with(|c| c.set(&self.uart as *const USART8251));
        CTX_UART_MUT.with(|c| c.set(&mut self.uart as *mut USART8251));
        CTX_CPU.with(|c| c.set(&mut self.cpu as *mut CPU8080));

        // Run a batch per frame
        let batch_size = match self.speed_idx {
            0 => 5000,    // max
            1 => 3,       // 100 Hz / 30fps ≈ 3
            2 => 33,      // 1 KHz / 30fps ≈ 33
            3 => 333,     // 10 KHz
            4 => 3333,    // 100 KHz
            _ => 33333,   // 1 MHz
        };
        for _ in 0..batch_size {
            // Wake from HLT — force IE so RST 7 is taken
            if self.cpu.halt {
                self.cpu.halt = false;
                self.cpu.intr = true;
                self.cpu.ie = true;
            }
            self.record_trace();
            self.cpu.step();
            self.sync_plotter();
            if self.breakpoints.contains(&self.cpu.pc) {
                self.pause_cpu();
                break;
            }
        }

        // Clear context
        CTX_MMU.with(|c| c.set(std::ptr::null()));
        CTX_MMU_MUT.with(|c| c.set(std::ptr::null_mut()));
        CTX_UART.with(|c| c.set(std::ptr::null()));
        CTX_UART_MUT.with(|c| c.set(std::ptr::null_mut()));
        CTX_CPU.with(|c| c.set(std::ptr::null_mut()));
        if self.follow_pc && !self.paused {
            self.disasm_addr = self.cpu.pc.saturating_sub(30);
        }
        if self.cpu.halt {
            self.pause_cpu();
        }
    }

    fn pause_cpu(&mut self) {
        self.running = false;
        self.paused = true;
        self.update_all();
    }

    fn send_usart_bytes(&mut self) {
        let raw = self.usart_hex_input.trim().to_string();
        if raw.is_empty() { return; }
        let parts: Vec<&str> = raw.split([' ', ',', ';']).collect();
        for p in parts {
            if let Ok(byte) = u8::from_str_radix(p, 16) {
                self.uart.receive_byte(byte);
                self.usart_log.push_str(&format!("→ ${byte:02X} "));
            }
        }
        self.usart_hex_input.clear();
    }
}
