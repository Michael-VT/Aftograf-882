#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Компиляция ==="
go build ./... 2>&1

echo ""
echo "=== Тестирование ==="
go test ./... 2>&1

echo ""
echo "=== Запуск ==="
echo "Закрой окно программы, чтобы вернуться в терминал."
echo ""
go run ./cmd/aftograf/ 2>&1
