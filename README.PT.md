# Autograf-882 Debug Simulator v1.0.18

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

### GUI Go: hardware ao vivo e depuração de E/S
- A aba `Debug` reúne CPU, pilha e breakpoints
- A aba `I/O` mostra PPI1/PPI2, PIT, USART e hardware externo em colunas
- A aba `Hardware` contém matriz de teclado 6×2, quatro fins de curso X/Y, quatro entradas DIP e LEDs PPI1.C2–C5
- Teclas, fins de curso e DIP podem ser alterados durante a execução da CPU
- `Stop on peripheral access` interrompe o Go depois de uma instrução que acesse PPI, PIT ou USART
- A linha do evento mostra `READ/WRITE`, endereço ou porta direta, valor, dispositivo e função do registrador
- O botão `?` na aba I/O explica o mapa de endereços dos periféricos

![Go: CPU, disassembler, memória e plotter A4](images/Autograf-882-Debugger_CPU_Go_Shattle.png)

![Go: estado de E/S e evento periférico](images/Autograf-882-Debugger_PIO_Go_Shattle.png)

### Diagnóstico
- Painel da CPU com contador de ciclos
- Pilha (8 palavras em Go)
- LEDs do plotter em PPI1.C2–C5 (Go)
- Simulação do teclado 6×2, fins de curso X/Y e entradas DIP (Go)
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

### Go (baseline GUI estável)

```bash
cd go
./trygo.sh
```

`trygo.sh` compila o GUI, executa os unit-tests em modo verbose, mostra o resultado do smoke-test e inicia o simulador. Feche a janela para terminar o script. Para iniciar diretamente, use `go run ./cmd/aftograf`. A versão Go usa Fyne v2.5 e requer um servidor de exibição (X11/macOS/Wayland).

Testes:

```bash
cd go
go test -count=1 ./...
go test -race ./pkg/app
go vet ./...
```

### Versão para navegador

`sim/` — versão antiga para navegador:

Versão atual do navegador: `v0.0.7`.

```bash
cd sim && ./tryjs.sh
# Ou manualmente:
python3 -m http.server 8080
# Abra http://localhost:8080/sim/
```

`tryjs.sh` recompila o bundle, executa testes de regressão HPGL para `PU/PD`, `PA` e `PR` e inicia o servidor local.

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

Na aba Go `I/O`, ative `Stop on peripheral access` para parar depois da instrução que fizer uma leitura ou escrita de periférico. O último evento mostra a operação, o endereço ou porta, o valor, o dispositivo e a função do registrador.

---

**Outros idiomas:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
