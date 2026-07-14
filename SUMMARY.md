# Aftograf-882 — Project Summary

**Version:** v1.0.10  
**Build:** `cargo build` ✅ | `cargo clippy -- -D warnings` ✅ | `cargo test` 37/37 ✅  
**Last commit:** `bb809e4` — 2026-07-14  
**Remote:** https://github.com/Michael-VT/Aftograf-882

---

## What Works

### CPU Emulation (rust/src/cpu.rs)
- Full Intel 8080 / K580IK80A — all 256 opcodes
- Registers: A, B, C, D, E, H, L, SP, PC
- Flags: S, Z, AC, P, CY
- Interrupt handling (INTR with RST vector)
- Cycle counter
- 28 unit tests passing

### Memory / MMU (rust/src/memory.rs)
- ROM 24KB ($0000–$5FFF) from embedded firmware.bin
- RAM 2KB ($6000–$67FF) — readable/writable
- Memory-mapped I/O: PPI1 ($E000), PPI2 ($E400), PIT ($E800), USART ($EC00)
- Poke (byte editing via double-click in memory viewer)
- 9 unit tests passing

### I/O Devices
- PPI‑8255 (K580VV55A) — 3 ports × 2 chips
- PIT‑8253 (K580VI53) — 3 counters, timer IRQ
- USART‑8251 (K580VV51A) — UART with TX/RX buffering

### Disassembler (rust/src/disasm.rs)
- Full 8080 disassembly table
- Memory region coloring (ROM brown, RAM gold, I/O devices)
- Follow PC with centered current instruction
- Breakpoints (click to toggle)
- Address search with ◀▶ navigation

### HPGL Parser (rust/src/hpgl.rs)
- Commands: IN, SP, PU, PD, PA, PR
- Preview mode: direct canvas drawing
- Step mode: ▶ Next / ▶▶ All / ⟲ Reset
- Progress bar + active line highlight

### Plotter (rust/src/plotter.rs)
- XY position tracking + pen up/down + pen number
- A4 canvas with 1:√2 aspect ratio
- Pen color rendering (6 pens)
- Grid overlay, pen cursor indicator

### READMEs
- 6 languages: EN, RU, UA, PT, FR, DE
- Top: original device photo (Автограф_882.01-1990.jpg)
- After Features: Rust debugger screenshot (Avtograf8445-sh003.png)
- Browser section: JS debugger screenshot (Aftograf-882-Debuger.png)
- Version: 1.0.10

---

## What Still Doesn't Work (Persistent Bugs)

### 1. Plotter Canvas Scale Changes on Mouse Hover

**Status:** NOT FIXED (survived 4 attempts)

**Symptom:** HPGL file draws correctly, but moving the mouse cursor over the plotter canvas immediately changes the zoom/scale of the drawing.

**Attempted fixes:**
- `Sense::click()` → `Sense::hover()` on canvas allocation
- Added/removed `auto_shrink([false; 2])` on controls ScrollArea
- The scale still jumps when mouse enters/leaves the canvas rect

**Suspect root cause:** `ui.available_width()` returns different values depending on mouse hover state. Possible causes:
- `SidePanel::right("right_panel").resizable(true)` — panel border hover detection changes available width
- The controls ScrollArea below the canvas influences parent layout on hover
- egui `Sense` on the canvas triggers repaint/layout recalculation that changes `available_width`

**Current code location:**
```rust
// rust/src/app.rs:1130-1134
let cw = ui.available_width() as u32;
let ch = ((cw as f32) * std::f32::consts::SQRT_2) as u32;
let (rect, _) = ui.allocate_exact_size(
    egui::vec2(cw.max(100) as f32, ch.max(100) as f32),
    egui::Sense::hover(),  // Changed from click() — didn't help
);
```

`paint_plotter()` at line 1192 calculates scale from `rect.width()` and `rect.height()`.

**Possible solution directions:**
- Remove `Sense` entirely from canvas allocation (empty Sense struct?)
- Capture the rect ONCE and cache it, don't recalculate every frame
- Lock the canvas aspect ratio using `ui.allocate_exact_size` with a fixed reference width
- Move canvas allocation OUTSIDE the SidePanel and use a fixed-size widget

---

### 2. Memory Viewer Goes Empty on Go / HL Click

**Status:** NOT FIXED (survived 3 attempts)

**Symptom:** Clicking HL (or BC/DE/SP) register labels, or typing an address (e.g. "6000") and pressing Go, causes the memory viewer to become empty (no rows rendered).

**Attempted fixes:**
1. `show_viewport()` with spacer fix: `space = (first_visible * ROW_H - viewport.min.y).max(0.0)`
2. `show_viewport()` with `mem_scroll_to_row` → `scroll_to_rect`
3. `show()` with `clip_rect()` instead of `show_viewport()`
4. Register clicks: `mem_view_ver` → `mem_scroll_to_row`

None worked. The viewer still shows empty after Go/HL.

**Suspect root cause:** `ui.scroll_to_rect()` inside the ScrollArea closure scrolls to the WRONG position:
- In `show_viewport()`: child Ui starts at viewport offset, `scroll_to_rect` translates rect by current scroll offset → double-scrolls past content end
- In `show()`: `set_min_height(73728)` might interact with `scroll_to_rect` — the scroll happens before the content height is established, so egui can't scroll to a position beyond the initial (0) content height

**Current code location:**
```rust
// rust/src/app.rs:1017-1029
egui::ScrollArea::vertical()
    .id_source("mem_scroll_64kb")
    .show(ui, |ui| {
        ui.set_min_height(total_height);  // 73728 px

        if let Some(target_row) = scroll_to {
            let target_y = target_row as f32 * ROW_H;
            ui.scroll_to_rect(
                egui::Rect::from_min_size(egui::pos2(0.0, target_y), ...),
                Some(egui::Align::TOP),
            );
        }
```

**Possible solution directions:**
- Use `ctx.request_repaint_after()` + persistent scroll state to scroll in a SEPARATE frame from the content update
- Instead of `scroll_to_rect`, use `ScrollArea`
- Use `egui::Area` or manual state management for scroll position
- Drop virtual scrolling and render all 4096 rows (check performance)
- Use a simple paged view (◀▶ scrolls pages, no smooth scrollbar) — remove `show_viewport`/`show` complexity entirely

---

### 3. Minor / Cosmetic

- Memory field title text missing (might be related to bug #2)
- Extra blank lines in some READMEs after image repositioning
- git push requires manual authentication (HTTPS credentials)

---

## Build & Run

```bash
cd rust
cargo run --release           # Run the GUI
cargo test -- --test-threads=1  # Run tests (single-threaded)
cargo clippy -- -D warnings   # Lint check
```

## Push

```bash
cd ~/work/Antigravity/github/aftograf && git push
```
