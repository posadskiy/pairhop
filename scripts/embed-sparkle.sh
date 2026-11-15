#!/bin/bash
# Put Sparkle into an assembled PairHop.app: the framework, the update feed, and the public key.
#   scripts/embed-sparkle.sh build/PairHop.app
# Run it before signing. The feed is the appcast.xml attached to the latest GitHub release.
set -euo pipefail
cd "$(dirname "$0")/.."

app="${1:?app path}"
plist="$app/Contents/Info.plist"
feed="https://github.com/posadskiy/pairhop/releases/latest/download/appcast.xml"

/usr/libexec/PlistBuddy -c "Delete :SUFeedURL" "$plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :SUFeedURL string $feed" "$plist"

# scripts/sparkle-keys.sh writes the public key once. Without it Sparkle cannot verify an update,
# and publish.sh refuses to publish.
/usr/libexec/PlistBuddy -c "Delete :SUPublicEDKey" "$plist" 2>/dev/null || true
if [[ -s Config/SUPublicEDKey ]]; then
  key="$(tr -d '[:space:]' < Config/SUPublicEDKey)"
  if [[ ! "$key" =~ ^[A-Za-z0-9+/=]+$ ]]; then
    echo "Config/SUPublicEDKey is not a base64 EdDSA public key." >&2
    exit 1
  fi
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $key" "$plist"
else
  echo "No Config/SUPublicEDKey. This build cannot verify Sparkle updates."
fi

framework=""
while IFS= read -r candidate; do
  framework="$candidate"
  break
done < <(find .build/artifacts -type d -path '*/macos-arm64_x86_64/Sparkle.framework' | sort)
if [[ -z "$framework" ]]; then
  echo "Sparkle.framework is not in .build/artifacts. Run swift build first." >&2
  exit 1
fi
mkdir -p "$app/Contents/Frameworks"
rm -rf "$app/Contents/Frameworks/Sparkle.framework"
ditto "$framework" "$app/Contents/Frameworks/Sparkle.framework"

# SwiftPM links Sparkle as @rpath, and the build directory is not the app bundle.
exe="$app/Contents/MacOS/PairHop"
if ! otool -l "$exe" | grep -q '@executable_path/../Frameworks'; then
  install_name_tool -add_rpath @executable_path/../Frameworks "$exe"
fi
