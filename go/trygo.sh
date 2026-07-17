#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Компиляция ==="
go build ./... 2>&1
echo ""
echo "=== Тестирование ==="
if go test -count=1 ./... 2>&1; then
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  ✓ ВСЕ ТЕСТЫ ПРОШЛИ УСПЕШНО"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
	rc=$?
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  ✗ ТЕСТЫ НЕ ПРОШЛИ (код: $rc)"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	exit $rc
fi
echo ""
echo "=== Запуск ==="
echo "Закрой окно программы, чтобы вернуться в терминал."
echo ""
go run ./cmd/aftograf 2>&1
