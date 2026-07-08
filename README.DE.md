# Autograf-882 Debug-Simulator

Ein interaktiver, browserbasierter Debugger und Simulator für den **Autograf-882** — einen sowjetischen Flachbett-Plotter mit der **K580IK80A** CPU (einem Klon des Intel 8080).

Dieses Projekt bietet einen vollständigen digitalen Zwilling der Originalhardware: CPU-Emulation, speicherabbildende Ein-/Ausgabe, Disassembler, Plotter-Simulation, USART-Terminal und HPGL-Dateilader — alles im Browser ohne serverseitige Logik.

## Funktionen

### CPU-Emulation (cpu8080.js)
- Vollständige K580IK80A / Intel 8080 Emulation — alle 256 Opcodes
- Register: A, B, C, D, E, H, L, SP, PC
- Flags: S, Z, AC, P, CY (8080-Bitpositionen)
- Interrupt-Handling (INTR mit RST-Vektor)
- T-State-Zyklenzählung
- Geschwindigkeitsregler: von max (unbegrenzt) bis 100 Hz

### Speicher (memory.js)
- ROM: 24 KB bei `$0000–$5FFF` (drei D2764A-EPROMs)
- RAM: 1 KB bei `$6000–$63FF` (KR537RU10)
- Speicherabbildende E/A: PPI1 bei `$E000`, PPI2 bei `$E400`, PIT bei `$E800`, USART bei `$EC00`
- Ungemappte Lesevorgänge geben `$FF` zurück; Schreibzugriffe auf ROM/ungemappt werden protokolliert

### Disassembler
- Hybrider rekursiv-linearer Disassembler basierend auf der CPU-Opcode-Tabelle
- 6 Spalten: Breakpoint, Adresse, Rohbytes, Mnemonic, Operanden, Annotation
- Follow-PC-Modus hebt den aktuellen Befehl hervor
- Virtuelles Scrollen durch den gesamten 64-KB-Adressraum
- Klicken zum Umschalten von Breakpoints, Doppelklicken zum Springen der PC
- Adresssuche (Taste `J` springt zur Zeile unter dem Cursor)

### Speicheransicht
- Virtuell scrollbare Anzeige des gesamten 64-KB-Adressraums
- Farbcodierte Bereiche: ROM (grau), RAM (gelb), E/A (violett)
- Inline-Byte-Bearbeitung — Klick auf Byte, Hex-Bearbeitung, Tab zum nächsten
- Hervorhebung des HL-Zeigers mit orangefarbener Markierung
- Adressleiste für schnelle Navigation

### Plotter-Simulation
- Simulation der XY-Schrittmotoren aus den PPI-Port-Phasen
- 7 Stiftfarben (aus der Firmware-Analyse)
- A4-Hochformat-Canvas (1:√2) mit Retina-Unterstützung
- Raster mit automatischer Skalierung, aktueller Positionscursor
- Schaltflächen zum Löschen und automatischen Anpassen

### HPGL-Lader
- Laden von HPGL-Dateien: Befehle `IN`, `SP`, `PU`, `PD`
- **Direkter Modus**: Parsen und Zeichnen auf dem Canvas mit Animation
- **UART-Modus**: Zeichenweises Senden von HPGL-Text an den USART
- Fortschrittsanzeige und Pause/Fortsetzen

### USART-Terminal
- Hex-Eingabefeld zum Senden von Bytes an die CPU
- Dateiupload mit XOn-XOff-gesteuerter Übertragung
- Übertragungsprotokoll mit darstellbaren Zeichen und Hex-Fallback
- TXRDY/RXRDY-Statusanzeige

### Sitzungen
- Vollständige Sicherung des CPU-Zustands, RAM, Breakpoints und Plotter-Linien
- Speichern als JSON-Datei mit Zeitstempel
- Wiederherstellen aus einer zuvor gespeicherten Sitzung

### Hilfe
- `?`-Button und `?`/`/`-Tastenkürzel öffnen ein Hilfefenster
- Tabelle der Tastaturkürzel
- Mausinteraktionsanleitung
- Dateiformatübersicht

### Themen
- Dunkles Thema (Standard) — Tokyo Night-Palette
- Helles Thema — saubere helle Palette für den Tagesgebrauch
- Umschaltung im Einstellungsfenster, persistent in `localStorage`

## Ausführen

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
```

Öffne `http://localhost:8080/sim/` im Browser.

Die Firmware (`firmware.bin`, 24 KB) wird automatisch geladen.  
Falls nicht vorhanden, nutze den 📂-Button oder Einstellungen → Firmware laden.

## Tastaturkürzel

| Taste | Aktion |
|---|---|
| `Leertaste` / `→` | Einzelschritt (ein Befehl) |
| `R` | CPU-Reset |
| `F5` | Start / Pause |
| `B` | Breakpoint an PC umschalten |
| `J` | PC zur Adresse unter dem Cursor springen |
| `?` / `/` | Hilfe öffnen |
