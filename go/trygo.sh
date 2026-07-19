#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Keep build artifacts in a writable, project-independent cache. This also
# makes the script work in restricted macOS/sandbox environments where the
# user's global Go cache is not writable.
export GOCACHE="${GOCACHE:-${TMPDIR:-/tmp}/aftograf-go-cache}"

echo "=== Компиляция ==="
bin="$(mktemp "${TMPDIR:-/tmp}/aftograf-go.XXXXXX")"
build_log="$(mktemp "${TMPDIR:-/tmp}/aftograf-build.XXXXXX")"
trap 'rm -f "$bin" "$build_log"' EXIT
if go build -o "$bin" ./cmd/aftograf >"$build_log" 2>&1; then
	# macOS may print this harmless cgo linker warning for Fyne. Do not hide
	# any other compiler or linker diagnostics.
	sed \
		-e "/ld: warning: ignoring duplicate libraries: '-lobjc'/d" \
		-e '/^# github\.com\/.*\/cmd\/aftograf$/d' \
		"$build_log"
else
	cat "$build_log"
	exit 1
fi
echo ""
echo "=== Unit-тесты (verbose) ==="
test_packages="$(go list ./... | rg -v '/cmd/aftograf$' || true)"
if [ -z "$test_packages" ]; then
	echo "Нет пакетов с unit-тестами"
	status=0
elif go test -count=1 -v -timeout=2m $test_packages 2>&1; then
	status=0
else
	status=$?
fi

if [ "$status" -eq 0 ]; then
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  ✓ ВСЕ ОБНАРУЖЕННЫЕ UNIT-ТЕСТЫ ПРОШЛИ"
	echo "  GUI entrypoint: проверен сборкой и GUI smoke-тестом pkg/app"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  ✗ ТЕСТЫ НЕ ПРОШЛИ (код: $status)"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	exit "$status"
fi
echo ""
echo "=== Запуск ==="
echo "Бинарник собран: $bin"
echo "Если окно не появилось, процесс всё ещё ждёт в ShowAndRun; нажми Ctrl-C."
echo ""
"$bin" 2>&1
