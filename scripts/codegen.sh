#!/usr/bin/env bash
set -euo pipefail

# ITER MVP — OpenAPI Codegen Pipeline
# Required tools: cargo, (jq OR python3)
# Optional tools: npx (for openapi-generator-cli), dart, flutter
# Partial-block note: F0.5 fully completes only after F0.1 (Flutter scaffold) lands.
# This script degrades gracefully: it ALWAYS emits openapi.json from the Rust
# server; Dart/Flutter steps are conditional on those toolchains being present.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_DIR="$PROJECT_ROOT/server"
APP_DIR="$PROJECT_ROOT/app"
OPENAPI_JSON="$PROJECT_ROOT/openapi.json"
DART_OUTPUT="$APP_DIR/lib/api"

# --- memory gate ---
MEM_FREE_MB=$(free -m | awk '/^Mem:/ {print $7}')
if [ "$MEM_FREE_MB" -lt 4096 ]; then
  echo "❌ memory gate: only ${MEM_FREE_MB} MB available (<4096 MB) — aborting" >&2
  exit 1
fi
echo "✅ memory gate: ${MEM_FREE_MB} MB available"

# --- Step 1: Rust → openapi.json ---
echo "🔧 Generating OpenAPI spec from Rust server..."
( cd "$SERVER_DIR" && cargo run --quiet --bin iter-server -- --emit-openapi ) > "$OPENAPI_JSON"

# Validate the JSON.
if command -v jq >/dev/null 2>&1; then
  jq -e '.openapi' "$OPENAPI_JSON" >/dev/null \
    || { echo "❌ openapi.json missing .openapi field" >&2; exit 1; }
  echo "✅ openapi.json validated via jq"
else
  python3 -c "import json,sys; d=json.load(open('$OPENAPI_JSON')); assert 'openapi' in d, 'missing openapi field'" \
    || { echo "❌ openapi.json validation failed (python3)" >&2; exit 1; }
  echo "✅ openapi.json validated via python3"
fi

# --- Step 2: Dart client generation (conditional on app/ present + npx) ---
if [ ! -d "$APP_DIR" ]; then
  echo "[skip] app/ not present (F0.1 blocked) — skipping Dart client generation"
  RAN_DART_CLIENT=0
elif ! command -v npx >/dev/null 2>&1; then
  echo "[skip] npx not installed — skipping Dart client generation"
  RAN_DART_CLIENT=0
else
  echo "📱 Generating Dart client via npx openapi-generator-cli..."
  mkdir -p "$DART_OUTPUT"
  npx --yes @openapitools/openapi-generator-cli generate \
    -i "$OPENAPI_JSON" \
    -g dart-dio \
    -o "$DART_OUTPUT"
  RAN_DART_CLIENT=1
fi

# --- Step 3: Dart formatting (conditional) ---
if [ "${RAN_DART_CLIENT:-0}" -eq 1 ] && command -v dart >/dev/null 2>&1; then
  echo "✨ Formatting generated Dart code..."
  ( cd "$APP_DIR" && dart format lib/api/ )
  RAN_DART_FORMAT=1
else
  if [ "${RAN_DART_CLIENT:-0}" -eq 1 ]; then
    echo "[skip] dart not installed — generated client is unformatted"
  fi
  RAN_DART_FORMAT=0
fi

# --- Step 4: build_runner (conditional) ---
if [ "${RAN_DART_CLIENT:-0}" -eq 1 ] && command -v flutter >/dev/null 2>&1; then
  echo "🔨 Running build_runner..."
  ( cd "$APP_DIR" && flutter pub run build_runner build --delete-conflicting-outputs )
  RAN_BUILD_RUNNER=1
else
  if [ "${RAN_DART_CLIENT:-0}" -eq 1 ]; then
    echo "[skip] flutter not installed — build_runner skipped"
  fi
  RAN_BUILD_RUNNER=0
fi

# --- Summary ---
echo ""
echo "=== codegen summary ==="
echo "openapi.json:        ✅ $(wc -c <"$OPENAPI_JSON") bytes"
echo "Dart client gen:     $([ "${RAN_DART_CLIENT:-0}" -eq 1 ] && echo '✅ ran' || echo '⏭  skipped')"
echo "Dart format:         $([ "${RAN_DART_FORMAT:-0}" -eq 1 ] && echo '✅ ran' || echo '⏭  skipped')"
echo "build_runner:        $([ "${RAN_BUILD_RUNNER:-0}" -eq 1 ] && echo '✅ ran' || echo '⏭  skipped')"
echo "======================="
