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
# Generated Dart client lives at project root (sibling to app/, server/, infra/).
# Not under app/lib/ or app/packages/ — Flutter recursively analyzes everything
# under the app/ tree and would otherwise flag the generated package's warnings.
# See ADR-007.
DART_OUTPUT="$PROJECT_ROOT/packages/openapi"

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
  # Clean stale generated output. The generator writes new files but does NOT
  # delete obsolete ones — e.g. renaming /me → /users/me leaves an orphan
  # auth_api.dart that breaks `dart test`. Wipe what's deterministically
  # regenerated; preserve pubspec.yaml + .gitignore + .dart_tool.
  if [ -d "$DART_OUTPUT" ]; then
    rm -rf "$DART_OUTPUT/lib" "$DART_OUTPUT/test" "$DART_OUTPUT/doc" \
           "$DART_OUTPUT/.openapi-generator" \
           "$DART_OUTPUT/.openapi-generator-ignore"
  fi
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
  ( cd "$DART_OUTPUT" && dart format . )
  RAN_DART_FORMAT=1
else
  if [ "${RAN_DART_CLIENT:-0}" -eq 1 ]; then
    echo "[skip] dart not installed — generated client is unformatted"
  fi
  RAN_DART_FORMAT=0
fi

# --- Step 4: build_runner (run from inside the generated package, not from app/) ---
# The generated package has its own pubspec.yaml with build_runner +
# built_value_generator as dev_dependencies. We pub-get + run build_runner from
# THAT directory using `dart`, not `flutter`, since openapi is a pure Dart pkg.
if [ "${RAN_DART_CLIENT:-0}" -eq 1 ] && command -v dart >/dev/null 2>&1; then
  echo "📦 dart pub get (in $DART_OUTPUT)..."
  ( cd "$DART_OUTPUT" && dart pub get )
  echo "🔨 Running build_runner..."
  ( cd "$DART_OUTPUT" && dart run build_runner build --delete-conflicting-outputs )
  RAN_BUILD_RUNNER=1
else
  if [ "${RAN_DART_CLIENT:-0}" -eq 1 ]; then
    echo "[skip] dart not installed — build_runner skipped"
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
