# Autograf-882 Debug Simulator v1.0.10

![Autograf-882 — Originalgerät](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*Der originale Autograf-882 Flachbettplotter*

## Funktionen

### CPU-Emulation
- Vollständige K580IK80A / Intel 8080 Emulation — alle 256 Opcodes
- Register: A, B, C, D, E, H, L, SP, PC (editierbar)
- Flags: S, Z, AC, P, CY
- Interruptverarbeitung (INTR mit RST-Vektor)
- Taktzähler im CPU-Panel

### Speicher
- ROM: 24 KB bei `$0000–$5FFF` (drei D2764A)
- RAM: 2 KB bei `$6000–$67FF` (K537RU10)
- Speichergemappte E/A: PPI1 bei `$E000`, PIT bei `$E800`, USART bei `$EC00`

### Disassembler
- 256 Anweisungen pro Bildschirm, voller Zugriff auf 64 KB
- **Follow PC** — aktuelle Anweisung immer zentriert
- Adresssuche, ◀▶-Tasten
- Klick für Breakpoints

### Speicheranzeige
- 64 Zeilen × 16 Bytes = 1 KB sichtbar
- Navigation: Adressleiste + Go, ◀▶, HL
- Byte-Editierung per Doppelklick
- ASCII-Spalte rechts

### HPGL
- Befehle: IN, SP, PU, PD, PA, PR
- **Vorschau**: gesamte Datei zeichnen
- **Schrittmodus**: ▶ Next / ▶▶ All / ⟲ Reset
- **Bis N zeichnen**: Segmentnummer eingeben
- Fortschrittsbalken, aktive Zeile hervorgehoben

![Autograf-882 Debug Simulator](images/Avtograf8445-sh003.png)
*Debugger-Simulator in Aktion (Rust/egui)*


## Kompilieren und Ausführen

```bash
cd rust
cargo run --release
```

### Tests

```bash
cd rust
cargo test -- --test-threads=1
```

## Projektstruktur

```
├── rust/                  ← Hauptversion (Rust)
│   ├── Cargo.toml
│   ├── TESTS.md
│   └── src/
│       ├── main.rs
│       ├── app.rs
│       ├── cpu.rs
│       ├── memory.rs
│       ├── disasm.rs
│       ├── plotter.rs
│       ├── hpgl.rs
│       ├── ppi8255.rs
│       ├── pit8253.rs
│       ├── usart8251.rs
│       ├── settings.rs
│       └── session.rs
├── sim/                   ← Browser-Version
└── docs/                  ← Dokumentation
```

---

**Andere Sprachen:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
