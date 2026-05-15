#!/usr/bin/env bash
set -euo pipefail

# ITER MVP — OpenAPI Codegen Pipeline
# This script runs the Rust server with --emit-openapi flag,
# then uses openapi-generator to create the Dart client.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_DIR="$PROJECT_ROOT/server"
APP_DIR="$PROJECT_ROOT/app"
OPENAPI_JSON="$PROJECT_ROOT/openapi.json"
DART_OUTPUT="$APP_DIR/lib/api"

echo "🔧 Generating OpenAPI spec from Rust server..."
cd "$SERVER_DIR"
cargo run --bin iter_server -- --emit-openapi > "$OPENAPI_JSON"

echo "📱 Generating Dart client from OpenAPI spec..."
docker run --rm \
  -v "$OPENAPI_JSON:/openapi.json" \
  -v "$DART_OUTPUT:/output" \
  openapitools/openapi-generator-cli:latest \
  generate -i /openapi.json -g dart-dio -o /output

echo "✨ Formatting generated Dart code..."
cd "$APP_DIR"
dart format lib/api/
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Codegen complete!"
echo "📝 Generated files: $DART_OUTPUT/*.dart"
