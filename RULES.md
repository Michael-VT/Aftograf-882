# Aftograf-882 Architecture Rules

Эти правила обязательны к соблюдению при любой доработке эмулятора.
Нарушение правил приводит к регрессиям.

## 1. Дизассемблер: линейный sweep, а не фиксированные строки

**Правило:** 8080 имеет команды длиной 1–3 байта. Дизассемблер НЕ должен
использовать строки фиксированного размера (ни 2 байта, ни 1 байт).

**Реализация:** `disasm.BuildInsnIndex()` выполняет линейный sweep от адреса 0,
декодируя каждую команду последовательно. Результат — `[]uint16` с адресами
начала каждой инструкции. Количество записей = количество инструкций (~32768).

```go
// disasm.go
func BuildInsnIndex(readByte func(uint16) uint8) []uint16
```

**Запрещено:**
- `uint16(id) * 2` как адрес строки
- `func() int { return 32768 }` или `return 65536` для количества строк
- Поиск `isPC` по диапазону адресов (`pc >= addr && pc < addr+len`)

**Разрешено:**
- `func() int { return len(a.insnIndex) }`
- `addr := a.insnIndex[id]` для получения адреса по индексу
- `isPC := int(id) == a.pcInsnIdx` — точное сравнение индексов

## 2. Подсветка текущей команды: только одна строка

**Правило:** ровно одна строка в дизассемблере получает `→` и голубой цвет.
Никакого перекрытия, никаких диапазонов.

**Реализация:** `a.pcInsnIdx` вычисляется один раз в `refreshDisasm()`:
```go
a.pcInsnIdx = disasm.InsnIndexForAddr(a.insnIndex, a.CPU.PC)
```
В updateItem: `isPC := int(id) == a.pcInsnIdx`

**Запрещено:**
- Сканирование `insns[0..2]` в поисках PC
- Сравнение `pc >= ins.Address && pc < ins.Address+ins.Length`

## 3. syncUI(): обновлять всё синхронно

**Правило:** После каждого Step() или в цикле Run() ВСЕ отображаемые значения
должны обновляться из одного вызова, чтобы избежать рассинхронизации.

**Реализация:** В `syncUI()` обновляются:
- Кнопки BC/DE/HL/SP (парные значения)
- Entry-поля A/B/C/D/E/SP (индивидуальные регистры)
- Флаги, LED, PC, Cycles, статус
- Вызов `refreshDisasm()`, `refreshMem()`, `refreshStack()`

**Запрещено:**
- Обновлять только парные кнопки, но не entry-поля
- Обновлять entry-поля в одном месте, а кнопки в другом

## 4. Инструкции CPU: полное покрытие тестами

**Правило:** Каждая инструкция 8080 должна быть проверена тестом с верификацией
всех флагов (S, Z, AC, P, CY).

**Реализация:** `go/pkg/cpu/cpu_test.go` — 35 тестов, проверяющих:
- Арифметику: ADD/ADC/ADI/ACI/SUB/SUI/SBB/SBI
- Логику: ANA/ANI/XRA/XRI/ORA/ORI/CMP/CPI
- Пересылку: MOV/LXI/LDAX/STAX/STA/LDA/SHLD/LHLD
- Стек: PUSH/POP/PSW/XTHL
- Управление: JMP/Jcc/CALL/Ccc/RET/Rcc/RST 0-7
- Флаги: INR/DCR/INX/DCX/DAD/ротаты/DAA/STC/CMC/CMA
- Систему: HLT/EI/DI/IN/OUT/INTERRUPT/RESET

## 5. Тесты: только свежий прогон

**Правило:** `go test` всегда с флагом `-count=1`, чтобы исключить
кешированные результаты.

**Реализация:** `go/trygo.sh`:
```bash
if go test -count=1 ./... 2>&1; then
    echo "✓ ВСЕ ТЕСТЫ ПРОШЛИ УСПЕШНО"
else
    echo "✗ ТЕСТЫ НЕ ПРОШЛИ"
    exit $rc
fi
```

## 6. Версионирование

**Правило:** Версия Go-реализации обновляется при каждом значимом изменении.
Текущая версия: **v1.0.18**.

Места обновления:
- `go/pkg/app/app.go:const appVersion`
- `go/cmd/aftograf/main.go:window title`
- `README.md:заголовок`
- `CHECKPOINT.md:версия и статус`
- `SUMMARY.md:версия`
- `HANDOFF.md:заголовок секции`

## 7. Регистры: парные и индивидуальные — синхронно

**Правило:** `GetBC()` отображает `(B<<8)|C`. Если отображается B и C
по отдельности, их значения должны совпадать с GetBC().

**Реализация:** В `syncUI()`:
```go
a.regBCb.SetText(fmt.Sprintf("BC:%04X", a.CPU.GetBC()))
if a.regEdit[1] != nil { a.regEdit[1].SetText(fmt.Sprintf("%02X", a.CPU.B)) }
if a.regEdit[2] != nil { a.regEdit[2].SetText(fmt.Sprintf("%02X", a.CPU.C)) }
```

## 8. Memory viewer: ScrollTo без смещения

**Правило:** `memJump` вызывает `ScrollTo(id)` без вычитания/добавления.
Целевой адрес должен быть виден.

**Реализация:**
```go
a.memList.ScrollTo(widget.ListItemID(a.memAddr / 16))
```

**Запрещено:** `id -= N` перед ScrollTo.
