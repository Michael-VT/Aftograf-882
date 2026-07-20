# Aftograf-882 — Project Summary

**Version:** v1.0.18 (Go) / v1.0.11 (Rust)
**Go:** `go build` ✅ | `go vet` ✅ | `go test -count=1 ./...` ✅ | `go test -race ./pkg/app` ✅
**Rust:** `cargo build` ✅ | `cargo clippy -- -D warnings` ✅ | `cargo test` 37/37 ✅  
**Last code commit:** `0f87cfd` — peripheral access breakpoints and explanations
**Documentation baseline:** 2026-07-20
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

### Go (go/) — Stable GUI/debugger baseline, actively developed
- Full Intel 8080 / K580IK80A — all 256 opcodes, covered by package tests
- MMU: ROM 24KB + RAM 2KB + memory-mapped I/O (all 4 devices), covered by package tests
- I/O: PPI-8255 (2 chips), PIT-8253 (3 counters), USART-8251 (UART)
- Disassembler with breakpoints, follow-PC, address search, copy-to-clipboard
- HPGL parser + step/preview mode
- XY plotter with A4 canvas + auto-scaling
- Memory viewer with color coding (ROM brown, RAM gold, I/O purple) + byte editing
- USART terminal with hex send and RX log
- CPU register editing (A/B/C/D/E/SP hex entries)
- Keyboard shortcuts (Space/Step, R/Reset, F5/RunPause, B/Breakpoint, ?/Help)
- Session save/load (JSON via dialog)
- Hardware tab with live 6×2 keyboard matrix, X/Y limit switches, DIP inputs and PPI1.C2–C5 LED indicators
- Optional stop on peripheral access with READ/WRITE, device, register and value details
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

The three implementations share the CPU, memory map and plotter model, but their GUI layouts and diagnostic controls are intentionally not identical. The live Hardware tab and peripheral-access breakpoint described above are Go-specific features at this checkpoint.

---

## Build & Run

```bash
cd rust && cargo run --release
cd go   && ./trygo.sh
```

For non-GUI Go checks use `go test -count=1 ./...`, `go test -race ./pkg/app`, `go vet ./...` and `go build ./cmd/aftograf`.

## Push

```bash
cd ~/work/Antigravity/github/aftograf && git push
```
