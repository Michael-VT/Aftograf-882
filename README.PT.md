# Autograf-882 Debug Simulator v1.0.10

![Autograf-882 — Dispositivo Original](images/%D0%90%D0%B2%D1%82%D0%BE%D0%B3%D1%80%D0%B0%D1%84_882.01-1990.jpg)
*O plotter Autograf-882 original*

![Autograf-882 Debug Simulator](images/Avtograf8445-sh003.png)
*Simulador debugger em ação (Rust/egui)*


## Recursos

### Emulação de CPU
- Emulação completa do K580IK80A / Intel 8080 — todos os 256 opcodes
- Registradores: A, B, C, D, E, H, L, SP, PC (editáveis)
- Flags: S, Z, AC, P, CY
- Interrupções (INTR com vetor RST)
- Contador de ciclos no painel da CPU

### Memória
- ROM: 24 KB em `$0000–$5FFF` (três D2764A)
- RAM: 2 KB em `$6000–$67FF` (K537RU10)
- I/O mapeado em memória: PPI1 em `$E000`, PIT em `$E800`, USART em `$EC00`

### Desmontador
- 256 instruções por tela, acesso total a 64 KB
- **Follow PC** — instrução atual sempre centralizada
- Busca por endereço, botões ◀▶
- Clique para breakpoints

### Visualizador de Memória
- 64 linhas × 16 bytes = 1 KB visível
- Navegação: barra de endereços + Go, ◀▶, HL
- Edição inline por duplo clique
- Coluna ASCII à direita

### HPGL
- Comandos: IN, SP, PU, PD, PA, PR
- **Preview**: desenhar arquivo completo
- **Modo passo**: ▶ Next / ▶▶ All / ⟲ Reset
- **Desenhar até N**: inserir número do segmento
- Barra de progresso, linha ativa destacada

## Compilar e Executar

```bash
cd rust
cargo run --release
```

### Testes

```bash
cd rust
cargo test -- --test-threads=1
```

## Estrutura do Projeto

```
├── rust/                  ← Versão principal (Rust)
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
├── sim/                   ← Versão para navegador
└── docs/                  ← Documentação
```

---

**Outros idiomas:** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
