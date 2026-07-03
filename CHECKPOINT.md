# Autograf-882 Disassembly — Checkpoint

## Состояние на 2026-07-03

### Файлы

| Файл | Описание |
|------|----------|
| `Autograf-882-CPU_Board-On_Top-Small-Chip01-FromLeft-D2764A-NearOfHeatsink.bin` | 8KB, $0000-$1FFF |
| `Autograf-882-CPU_Board-On_Top-Small-Chip02-FromLeft-D2764A-InMiddle.bin` | 8KB, $2000-$3FFF |
| `Autograf-882-CPU_Board-On_Top-Small-Chip03-FromLeft-D2764A-FarOfHeatsink.bin` | 8KB, $4000-$5FFF |
| `disasm8080.py` | Дизассемблер Intel 8080 на Python, рекурсивный обход |
| `autograf-882-disassembly.asm` | Полный листинг, 17792 строки |

### Карта памяти

```
$0000-$1FFF  Chip 1 — ресет, инициализация, низкоуровневые подпрограммы
$2000-$3FFF  Chip 2 — основная логика
$4000-$5FFF  Chip 3 — подпрограммы плоттера + таблицы шрифтов
$6000-$63FF  RAM (стек SP=$6140, рабочие переменные)
$E000-$E3FF  I/O (STA/LDA к портам 8255 PPI и 8253 PIT)
```

### Статистика дизассемблирования

- Инструкций: 9693
- Меток: 736 (формат: `F_L_XXXX` / `F_M_XXXX` / `F_P_XXXX`)
- Областей данных (шрифты): 512 байт
- Инструкций RET: 209
- Инструкций CALL/JMP/переходов: ~1680
- OUT/IN: 3 (основной I/O через memory-mapped STA/LDA)

### Как продолжить

**Запуск дизассемблера:**
```bash
python3 disasm8080.py
```

**Типичные следующие шаги:**
1. Переименовать метки в осмысленные имена (по анализу кода)
2. Добавить комментарии к ключевым функциям
3. Разобрать структуру данных (таблицы шрифтов в $5E00-$5FFF)
4. Сопоставить порты I/O с реальной периферией
5. Восстановить исходный .asm для ресборки (crasm/asm8080)

### Формат меток

- `RESET` — вектор ресета ($0000)
- `F_L_XXXX` — Chip 1 ($0000-$1FFF)
- `F_M_XXXX` — Chip 2 ($2000-$3FFF)
- `F_P_XXXX` — Chip 3 ($4000-$5FFF)

### Git

```
d4d7151 First commit disasemley Aftograph I8080
143fad1 8080 disassembler for Autograf-882 firmware
```
