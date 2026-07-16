# Autograf-882 Debug Simulator v1.0.15

![Autograf-882 — Dispositivo Original](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*O plotter Autograf-882 original*

## Recursos

### Emulação de CPU (Rust & Go)
- Emulação completa do K580IK80A / Intel 8080 — todos os 256 opcodes
- Registradores: A, B, C, D, E, H, L, SP, PC (editáveis em hex)
- Flags: S, Z, AC, P, CY (clicáveis)
- Interrupções (INTR com vetor RST 7)
- Contador de ciclos no painel da CPU
- Multiplicador de velocidade: 1x/10x/100x/1Kx/10Kx/100Kx (Go)

### Memória
- ROM: 24 KB em `$0000–$5FFF` (três D2764A)
- RAM: 2 KB em `$6000–$67FF` (K537RU10)
- I/O mapeado em memória: PPI1 em `$E000`, PPI2 em `$E400`, PIT em `$E800`, USART em `$EC00`

### Desmontador (Rust & Go)
- Baseado na tabela de opcodes da CPU
- Breakpoints (clique para ativar/desativar)
- **Follow PC** — instrução centralizada
- Barra de pesquisa + navegação ◀▶
- Clique no endereço → salta para o visualizador de memória
- Copiar faixa visível para a área de transferência (Go)

### Visualizador de Memória (Rust & Go)
- 32 linhas × 16 bytes = 512 B visíveis (Go); 64 linhas (Rust)
- Navegação: barra de endereço, Go, ◀▶, botão HL
- Clique em BC:/DE:/HL:/SP: — salta para o endereço
- Cores por região: ROM (marrom), RAM (dourado), I/O (roxo) — Go
- Edição de byte por clique (Enter para confirmar)
- Coluna ASCII à direita

### Periféricos (Rust & Go)
- **K580VV55A (PPI8255)**: dois chips, 3 portas + registrador de controle
- **K580VI53 (PIT8253)**: 3 contadores de 16 bits
- **K580VV51A (USART8251)**: buffers RX/TX, envio hex, registro

### Plotter (Rust & Go)
- Motores de passo XY simulados a partir das fases PPI
- 7 cores de caneta
- Tela A4 com escala automática
- Carregamento de arquivos HPGL, execução passo a passo

### HPGL
- Comandos: IN, SP, PU, PD, PA, PR
- Modo de pré-visualização: desenhar todos os segmentos
- Modo passo a passo: ▶ Seguinte / ▶▶ Todos / ⟲ Reiniciar
- Barra de progresso

### Terminal USART (Go)
- Campo de entrada hexadecimal para enviar à CPU
- Registro de recepção (últimas 20 entradas)
- Indicadores TXRDY/RXRDY

### Diagnóstico
- Painel da CPU com contador de ciclos
- Pilha (8 palavras em Go)
- LEDs DIP (porta A do PPI1)
- Salvar/carregar sessão em JSON (Go)
- Atalhos de teclado: Espaço/→ passo, R reset, F5 executar/pausar, B breakpoint, ? ajuda

## Compilar e executar

### Rust (versão principal)

```bash
cd rust
cargo run --release
```

Testes:

```bash
cd rust
cargo test -- --test-threads=1
```

### Go (em desenvolvimento ativo)

```bash
cd go
go run ./cmd/aftograf
```

A versão Go usa Fyne v2.5 para GUI. Requer um servidor de exibição (X11/macOS/Wayland).

Testes:

```bash
cd go
go test ./...
```

### Versão para navegador

`sim/` — versão antiga para navegador:

```bash
python3 -m http.server 8080
# Abra http://localhost:8080/sim/
```

## Estrutura do projeto

```
├── rust/                  ← Versão principal (Rust)
│   ├── Cargo.toml
│   └── src/ (cpu, memory, disasm, plotter, hpgl, ppi8255, pit8253, usart8251, settings, session)
├── go/                    ← Versão Go (Fyne)
│   ├── go.mod / go.sum
│   ├── cmd/aftograf/main.go
│   └── pkg/ (app, cpu, memory, disasm, plotter, hpgl, ppi8255, pit8253, usart8251, settings)
├── sim/                   ← Versão navegador
├── docs/                  ← Documentação
└── images/                ← Capturas de tela
```

## Atalhos de teclado

| Tecla | Ação |
|-------|------|
| `Espaço` / `→` | Passo |
| `R` | Reset da CPU |
| `F5` | Executar / Pausar |
| `B` | Breakpoint |
| `?` | Ajuda |

---

**Outros idiomas:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
