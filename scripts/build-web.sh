#!/usr/bin/env bash
# Build web para Vercel. API sempre em campus.veigagustavo.com.br (não no domínio .vercel.app).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-https://campus.veigagustavo.com.br}"

DEFINE_ARGS=(
  --dart-define="API_BASE_URL=${API_BASE_URL}"
)
if [[ -n "${APP_USER_ROLE:-}" ]]; then
  DEFINE_ARGS+=(--dart-define="APP_USER_ROLE=${APP_USER_ROLE}")
fi

flutter pub get
flutter build web --release "${DEFINE_ARGS[@]}" "$@"

cp config/vercel-spa.json build/web/vercel.json

echo "Build web → API_BASE_URL=${API_BASE_URL}"
echo "Saída em: ${ROOT}/build/web"
