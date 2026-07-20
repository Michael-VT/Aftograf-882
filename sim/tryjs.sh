#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Сборка bundle.js ==="
node build.js 2>&1

echo ""
echo "=== Тестирование ==="
node hpgl.test.mjs
echo "Откройте в браузере: http://localhost:8080/sim/"
echo ""
echo "=== Запуск HTTP-сервера ==="
if command -v python3 &>/dev/null; then
	echo "python3 -m http.server 8080 (Ctrl+C to stop)"
	python3 -m http.server 8080 2>&1
elif command -v python &>/dev/null; then
	echo "python -m http.server 8080 (Ctrl+C to stop)"
	python -m http.server 8080 2>&1
else
	echo "Python не найден. Запустите HTTP-сервер в корне проекта:"
	echo "  python3 -m http.server 8080"
	echo "и откройте http://localhost:8080/sim/"
	exit 1
fi
