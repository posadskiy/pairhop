#!/bin/bash
# Sign PairHop.app from the inside out with the hardened runtime, so Sparkle's helpers
# match the app's signature and notarization accepts the nested code.
#   scripts/sign-app.sh build/PairHop.app "Developer ID Application: Name (TEAMID)"
# PAIRHOP_NO_TIMESTAMP=1 skips Apple's timestamp for local builds that are not notarized.
set -euo pipefail

app="${1:?app path}"
identity="${2:?identity}"

if [[ ! -d "$app" ]]; then
  echo "No app at $app" >&2
  exit 1
fi

stamp="--timestamp"
if [[ -n "${PAIRHOP_NO_TIMESTAMP:-}" ]]; then
  stamp="--timestamp=none"
fi

sign() {
  codesign --force --options runtime "$stamp" --sign "$identity" "$1"
}

framework="$app/Contents/Frameworks/Sparkle.framework"
version="$framework/Versions/B"
if [[ ! -d "$version" ]]; then
  echo "Sparkle.framework is missing from $app" >&2
  exit 1
fi
while IFS= read -r nested; do
  sign "$nested"
done < <(find "$version/XPCServices" -name '*.xpc' -print | sort)
sign "$version/Autoupdate"
sign "$version/Updater.app"
sign "$framework"
sign "$app"

codesign --verify --deep --strict --verbose=2 "$app"
