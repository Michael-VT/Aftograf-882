# Aftograf-882 — Project Summary

**Version:** v1.0.15 (Go) / v1.0.11 (Rust)  
**Go:** `go build` ✅ | `go vet` ✅ | `go test` 2 packages ✅  
**Rust:** `cargo build` ✅ | `cargo clippy -- -D warnings` ✅ | `cargo test` 37/37 ✅  
**Last commit:** WIP — 2026-07-16  
**Remote:** https://github.com/Michael-VT/Aftograf-882

---

## Implementations

### Rust (rust/) — Primary, feature-complete
- Full Intel 8080 / K580IK80A — all 256 opcodes, 28 unit tests
- MMU: ROM 24KB + RAM 2KB + memory-mapped I/O (PPI1/PPI2/PIT/USART)
- I/O: PPI-8255 (2 chips), PIT-8253 (3 counters), USART-8251 (UART)
- Full 8080 disassembly table with breakpoints, follow-PC, address search
- HPGL parser (IN, SP, PU, PD, PA, PR) + step/preview mode
- XY plotter with A4 canvas, pen colors, grid overlay
- Session save/load, theme system, help overlay, settings panel
- 6-language READMEs

### Go (go/) — Near-feature-complete, actively developed
- Full Intel 8080 / K580IK80A — all 256 opcodes, 0 additional tests
- MMU: ROM 24KB + RAM 2KB + memory-mapped I/O (all 4 devices), 28 tests
- I/O: PPI-8255 (2 chips), PIT-8253 (3 counters), USART-8251 (UART)
- Disassembler with breakpoints, follow-PC, address search, copy-to-clipboard
- HPGL parser + step/preview mode
- XY plotter with A4 canvas + auto-scaling
- Memory viewer with color coding (ROM brown, RAM gold, I/O purple) + byte editing
- USART terminal with hex send and RX log
- CPU register editing (A/B/C/D/E/SP hex entries)
- Keyboard shortcuts (Space/Step, R/Reset, F5/RunPause, B/Breakpoint, ?/Help)
- Session save/load (JSON via dialog)
- GUI framework: Fyne v2.5.3

### Browser (sim/) — Legacy
- JavaScript-based, 143 unit tests
- Full 8080 CPU + memory + plotter + disassembler
- Older, less maintained

---

## What's Missing in Go vs Rust

| Feature | Rust | Go |
|---------|------|----|
| Plotter canvas with Retina support | ✅ | ⚠️ basic raster |
| Zoom/scale controls for plotter | ✅ | ❌ |
| Theme switcher (dark/light) | ✅ | ❌ |
| Help overlay (rich HTML) | ✅ | ⚠️ simple dialog |
| Settings panel UI | ✅ | ❌ (struct exists) |
| Session save in Rust | ✅ | ✅ JSON |
| Keyboard shortcuts | ✅ | ✅ |
| Step-back / undo | ❌ | ❌ |
| Conditional breakpoints | ❌ | ❌ |
| Export trace | ❌ | ❌ |
| I/O timing accuracy | ❌ | ❌ |
| Font table viewer | ❌ | ❌ |
| Assembly export | ❌ | ❌ |

---

## Build & Run

```bash
cd rust && cargo run --release
cd go   && go run ./cmd/aftograf
```

## Push

```bash
cd ~/work/Antigravity/github/aftograf && git push
```
