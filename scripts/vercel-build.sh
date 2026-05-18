#!/usr/bin/env bash
# Fallback: build na Vercel (opção A). Com opção B, use só deploy-vercel.yml no GitHub.
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter-sdk}"
  if [[ ! -x "${FLUTTER_HOME}/bin/flutter" ]]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_HOME}"
  fi
  export PATH="${FLUTTER_HOME}/bin:${PATH}"
  flutter config --enable-web
  flutter precache --web
fi

"$(dirname "$0")/build-web.sh"
