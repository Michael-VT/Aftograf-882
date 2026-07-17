#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Компиляция ==="
cargo build 2>&1

echo ""
echo "=== Тестирование CPU + Memory ==="
cargo test --quiet 2>&1

echo ""
echo "=== Запуск ==="
echo "Закрой окно программы, чтобы вернуться в терминал."
echo ""
cargo run --release 2>&1
