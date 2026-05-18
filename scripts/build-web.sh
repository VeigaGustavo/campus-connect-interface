#!/usr/bin/env bash
# Build web para GitHub Actions → Vercel. A URL da API é resolvida em runtime (ApiConfig).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEFINE_ARGS=()
if [[ -n "${APP_USER_ROLE:-}" ]]; then
  DEFINE_ARGS+=(--dart-define="APP_USER_ROLE=${APP_USER_ROLE}")
fi

flutter pub get
flutter build web --release "${DEFINE_ARGS[@]}" "$@"

cp config/vercel-spa.json build/web/vercel.json

echo "Saída em: ${ROOT}/build/web"
