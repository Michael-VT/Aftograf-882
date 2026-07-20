# Autograf-882 Debug Simulator v1.0.18

![Autograf-882 — Originalgerät](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*Der originale Autograf-882 Flachbettplotter*

## Funktionen

### CPU-Emulation (Rust & Go)
- Vollständige K580IK80A / Intel 8080 Emulation — alle 256 Opcodes
- Register: A, B, C, D, E, H, L, SP, PC (hex-editierbar)
- Flags: S, Z, AC, P, CY (anklickbar)
- Interruptverarbeitung (INTR mit RST-7-Vektor)
- Taktzähler im CPU-Panel
- Geschwindigkeitsmultiplikator: 1x/10x/100x/1Kx/10Kx/100Kx (Go)

### Speicher
- ROM: 24 KB bei `$0000–$5FFF` (drei D2764A)
- RAM: 2 KB bei `$6000–$67FF` (K537RU10)
- Speichergemappte E/A: PPI1 bei `$E000`, PPI2 bei `$E400`, PIT bei `$E800`, USART bei `$EC00`

### Disassembler (Rust & Go)
- Tabellengesteuerter Disassembler aus der CPU-Opcodetabelle
- Breakpoints (Klick zum Setzen/Löschen)
- **Follow PC** — aktuelle Anweisung zentriert
- Adresssuche + Navigation ◀▶
- Klick auf Adresse → Sprung zum Speicherbetrachter
- Kopieren des sichtbaren Bereichs in die Zwischenablage (Go)

### Speicherbetrachter (Rust & Go)
- 32 Zeilen × 16 Bytes = 512 Byte sichtbar (Go); 64 Zeilen (Rust)
- Navigation: Adressleiste, Go, ◀▶, HL-Button
- Klick auf BC:/DE:/HL:/SP: — Sprung zur Adresse
- Farbkodierung: ROM (braun), RAM (gold), I/O (lila) — Go
- Byte-Editierung per Klick (Enter zum Bestätigen)
- ASCII-Spalte rechts

### Peripherie (Rust & Go)
- **K580VV55A (PPI8255)**: zwei Chips, 3 Ports + Steuerregister
- **K580VI53 (PIT8253)**: 3 × 16-Bit-Zähler
- **K580VV51A (USART8251)**: RX/TX-Puffer, Hex-Sendung, Protokoll

### Plotter (Rust & Go)
- XY-Schrittmotorsimulation aus PPI-Phasen
- 7 Stiftfarben
- A4-Leinwand mit automatischer Skalierung
- HPGL-Dateiladung und schrittweise Ausführung

### HPGL
- Befehle: IN, SP, PU, PD, PA, PR
- Vorschaumodus: alle Segmente zeichnen
- Schrittmodus: ▶ Nächstes / ▶▶ Alle / ⟲ Zurücksetzen
- Fortschrittsbalken

### USART-Terminal (Go)
- Hex-Eingabefeld zum Senden an die CPU
- Empfangsprotokoll (letzte 20 Einträge)
- TXRDY/RXRDY-Statusanzeigen

### Go-GUI: Live-Hardware und E/A-Debugging
- Der Tab `Debug` enthält CPU, Stack und Breakpoints
- Der Tab `I/O` zeigt PPI1/PPI2, PIT, USART und externe Hardware in Spalten
- Der Tab `Hardware` enthält eine 6×2-Tastaturmatrix, vier X/Y-Endschalter, vier DIP-Eingänge und die LEDs PPI1.C2–C5
- Tasten, Endschalter und DIP-Eingänge können während der CPU-Ausführung geändert werden
- `Stop on peripheral access` hält Go nach einer Instruktion an, die PPI, PIT oder USART verwendet
- Die Ereigniszeile zeigt `READ/WRITE`, Adresse oder direkten Port, Wert, Gerät und Registerfunktion
- Die Schaltfläche `?` im I/O-Tab erklärt die Peripherie-Adresskarte

![Go: CPU, Disassembler, Speicher und A4-Plotter](images/Autograf-882-Debugger_CPU_Go_Shattle.png)

![Go: I/O-Zustand und Peripherieereignis](images/Autograf-882-Debugger_PIO_Go_Shattle.png)

### Diagnose
- CPU-Panel mit Taktzähler
- Stack (8 Wörter in Go)
- Plotter-LEDs auf PPI1.C2–C5 (Go)
- Simulation von 6×2-Tastatur, X/Y-Endschaltern und DIP-Eingängen (Go)
- Sitzung speichern/laden als JSON (Go)
- Tastaturkürzel: Leertaste/→ Schritt, R Reset, F5 Start/Pause, B Breakpoint, ? Hilfe

## Build & Ausführung

### Rust (Hauptversion)

```bash
cd rust
cargo run --release
```

Tests:

```bash
cd rust
cargo test -- --test-threads=1
```

### Go (in aktiver Entwicklung)

```bash
cd go
./trygo.sh
```

`trygo.sh` baut die GUI, führt Unit- und GUI-Smoke-Tests aus und startet danach den Simulator. Für einen direkten Start: `go run ./cmd/aftograf`. Die Go-Version verwendet Fyne v2.5 und benötigt einen Anzeigeserver (X11/macOS/Wayland).

Tests:

```bash
cd go
go test -count=1 ./...
go test -race ./pkg/app
go vet ./...
```

### Browserversion

`sim/` — ältere Browserversion:

Aktuelle Browser-Version: `v0.0.7`.

```bash
cd sim && ./tryjs.sh
# Oder manuell:
python3 -m http.server 8080
# Öffne http://localhost:8080/sim/
```

`tryjs.sh` baut das Bundle neu, führt HPGL-Regressionstests für `PU/PD`, `PA` und `PR` aus und startet danach den lokalen Server.

## Projektstruktur

```
├── rust/                  ← Hauptversion (Rust)
│   ├── Cargo.toml
│   └── src/ (cpu, memory, disasm, plotter, hpgl, ppi8255, pit8253, usart8251, settings, session)
├── go/                    ← Go-Version (Fyne)
│   ├── go.mod / go.sum
│   ├── cmd/aftograf/main.go
│   └── pkg/ (app, cpu, memory, disasm, plotter, hpgl, ppi8255, pit8253, usart8251, settings)
├── sim/                   ← Browserversion
├── docs/                  ← Dokumentation
└── images/                ← Screenshots
```

## Tastaturkürzel

| Taste | Aktion |
|-------|--------|
| `Leertaste` / `→` | Schritt |
| `R` | CPU-Reset |
| `F5` | Start / Pause |
| `B` | Breakpoint |
| `?` | Hilfe |

Im Go-Tab `I/O` aktiviert `Stop on peripheral access` den Halt nach dem aktuellen Peripherie-Lese- oder Schreibzugriff. Die Beschreibung des letzten Zugriffs bleibt sichtbar.

---

**Andere Sprachen:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
