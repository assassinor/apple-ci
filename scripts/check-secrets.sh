#!/usr/bin/env bash
set -euo pipefail

private_key_pattern='BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'
apple_key_pattern='AuthKey_[A-Z0-9]{8,12}\.p8'

if git grep -nI -E "$private_key_pattern|$apple_key_pattern" -- . ':!scripts/check-secrets.sh'; then
  echo "Potential private credential material found in tracked files." >&2
  exit 1
fi

for extension in p8 p12 cer mobileprovision; do
  if git ls-files "*.${extension}" | grep -q .; then
    echo "Tracked credential file detected: *.${extension}" >&2
    exit 1
  fi
done

echo "No tracked Apple or private-key credential material detected."
