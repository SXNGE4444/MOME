#!/usr/bin/env bash
set -euo pipefail

echo "==> MOME release preflight"

required=(LICENSE SECURITY.md CONTRIBUTING.md CHANGELOG.md README.md Package.swift scripts/build-app.sh scripts/create-dmg.sh scripts/notarize.sh)
for file in "${required[@]}"; do
  test -f "$file" || { echo "Missing required release file: $file"; exit 2; }
done

echo "==> Checking for common committed-secret patterns"
if git grep -nE '(-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9_-]{20,}|hf_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' -- . ':!scripts/preflight.sh'; then
  echo "Potential secret detected in tracked content."
  exit 3
fi

echo "==> Checking forbidden credential files"
if git ls-files | grep -E '(\.p12$|\.p8$|\.mobileprovision$|\.cer$|(^|/)\.env$)' ; then
  echo "Credential-like file is tracked."
  exit 4
fi

echo "==> Building and testing"
swift build -c debug
swift test

echo "==> Building app bundle"
bash scripts/build-app.sh
codesign --verify --deep --strict --verbose=2 dist/MOME.app

echo "==> Preflight passed"
