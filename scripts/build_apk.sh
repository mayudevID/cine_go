#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

fvm flutter build apk

APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  printf 'Build completed, but APK was not found at %s\n' "$APK_PATH" >&2
  exit 1
fi

printf 'APK created: %s\n' "$APK_PATH"
