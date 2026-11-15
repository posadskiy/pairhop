#!/usr/bin/env bash
# Build a Developer ID signed, notarized PairHop.dmg for GitHub Releases.
#   ./build.sh
#
# The app lands in build/PairHop.app and the disk image in build/PairHop.dmg. The Sparkle
# update archive (build/PairHop-<version>.zip) and its signed feed (build/appcast.xml) sit next
# to them. ./publish.sh attaches all three to the GitHub release.
#
# Run scripts/sparkle-keys.sh once first and commit Config/SUPublicEDKey. Sparkle signs the
# feed with the key in the login keychain, or with SPARKLE_ED_KEY_FILE.
# Apple Silicon only. The macOS 27 SDK deprecates x86_64 for this deployment target.
#
# The certificate is the only Developer ID Application identity in the login keychain, or
# DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)".
# The same certificate that signs GrammarBar signs this app. Nothing new is created
# on the Apple Developer site.
#
# Notarize with the same stored notarytool profile GrammarBar uses:
#   export NOTARY_KEYCHAIN_PROFILE="grammarbar-notary"
# or an App Store Connect API key:
#   export NOTARY_KEY_PATH="$HOME/.private_keys/AuthKey_XXXXXXXXXX.p8"
#   export NOTARY_KEY_ID="XXXXXXXXXX"
#   export NOTARY_ISSUER_ID="00000000-0000-0000-0000-000000000000"
#
# Store a notary profile once, with an app-specific password from appleid.apple.com:
#   xcrun notarytool store-credentials "grammarbar-notary" \
#     --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
#
# Signing and notarization ask Apple for a timestamp, so this needs the network.
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this on a Mac. It needs swift, hdiutil, codesign, and notarytool." >&2
  exit 1
fi

# shellcheck source=scripts/developer-id.sh
source scripts/developer-id.sh
identity="$(resolve_developer_id)"

profile="${NOTARY_KEYCHAIN_PROFILE:-}"
key_path="${NOTARY_KEY_PATH:-}"
key_id="${NOTARY_KEY_ID:-}"
issuer_id="${NOTARY_ISSUER_ID:-}"
notarize=()
if [[ -n "$profile" ]]; then
  notarize=(--keychain-profile "$profile")
elif [[ -n "$key_path$key_id$issuer_id" ]]; then
  if [[ -z "$key_path" || -z "$key_id" || -z "$issuer_id" ]]; then
    echo "Set all of NOTARY_KEY_PATH, NOTARY_KEY_ID, and NOTARY_ISSUER_ID." >&2
    exit 1
  fi
  if [[ ! -f "$key_path" ]]; then
    echo "No App Store Connect key at $key_path" >&2
    exit 1
  fi
  notarize=(--key "$key_path" --key-id "$key_id" --issuer "$issuer_id")
else
  echo "Set NOTARY_KEYCHAIN_PROFILE, or NOTARY_KEY_PATH, NOTARY_KEY_ID, and NOTARY_ISSUER_ID." >&2
  echo "The GrammarBar profile is NOTARY_KEYCHAIN_PROFILE=grammarbar-notary." >&2
  echo "Customers' Macs block a disk image Apple has not notarized." >&2
  exit 1
fi

if [[ -z "${PAIRHOP_SKIP_TEST:-}" ]]; then
  swift test
fi

echo "==> Building (release, arm64)..."
swift build -c release --arch arm64
bin="$(swift build -c release --arch arm64 --show-bin-path)"

app="build/PairHop.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/PairHop" "$app/Contents/MacOS/PairHop"
cp "Sources/PairHop/Info.plist" "$app/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
cp "THIRD_PARTY_LICENSES.md" "$app/Contents/Resources/THIRD_PARTY_LICENSES.md"

bash scripts/embed-sparkle.sh "$app"

if ! lipo -archs "$app/Contents/MacOS/PairHop" | grep -qx "arm64"; then
  echo "$app is not an arm64 build: $(lipo -archs "$app/Contents/MacOS/PairHop")" >&2
  exit 1
fi

echo "==> Signing with $identity..."
bash scripts/sign-app.sh "$app" "$identity"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Staple the ticket onto the app before it goes inside the disk image. Sparkle installs the
# app from a zip, so the staple has to be on the app itself.
notarize_zip="$work/PairHop-notarize.zip"
ditto -c -k --keepParent "$app" "$notarize_zip"
echo "==> Notarizing the app..."
xcrun notarytool submit "$notarize_zip" "${notarize[@]}" --wait
xcrun stapler staple "$app"
xcrun stapler validate "$app"

# The update archive and its signed feed. publish.sh attaches them to the GitHub release.
version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Sources/PairHop/Info.plist)"
rm -f build/PairHop-*.zip build/appcast.xml
updates="$work/updates"
mkdir -p "$updates"
ditto -c -k --keepParent "$app" "$updates/PairHop-$version.zip"
tool=""
while IFS= read -r candidate; do
  tool="$candidate"
  break
done < <(find .build/artifacts -type f -path '*/bin/generate_appcast' | sort)
if [[ -z "$tool" ]]; then
  echo "Sparkle's generate_appcast is not in .build/artifacts." >&2
  exit 1
fi
appcast_args=(
  --download-url-prefix "https://github.com/posadskiy/pairhop/releases/download/v$version/"
  --link "https://github.com/posadskiy/pairhop/releases/tag/v$version"
)
if [[ -n "${SPARKLE_ED_KEY_FILE:-}" ]]; then
  appcast_args=(--ed-key-file "$SPARKLE_ED_KEY_FILE" "${appcast_args[@]}")
fi
if ! "$tool" "${appcast_args[@]}" -o "$updates/appcast.xml" "$updates"; then
  echo "generate_appcast failed. Signing uses the keychain key from scripts/sparkle-keys.sh, or SPARKLE_ED_KEY_FILE." >&2
  exit 1
fi
cp "$updates/PairHop-$version.zip" "$updates/appcast.xml" build/

stage="$work/dmg"
mkdir -p "$stage"
ditto "$app" "$stage/PairHop.app"
ln -s /Applications "$stage/Applications"

dmg="build/PairHop.dmg"
echo "==> Creating $dmg..."
hdiutil create -volname "PairHop" -srcfolder "$stage" -ov -format UDZO "$dmg"
# Gatekeeper checks the disk image signature. The signed app inside is not enough.
codesign --force --timestamp --sign "$identity" "$dmg"
codesign --verify --verbose=2 "$dmg"

echo "==> Notarizing the disk image..."
xcrun notarytool submit "$dmg" "${notarize[@]}" --wait
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg"

echo "Wrote $dmg ($(shasum -a 256 "$dmg" | cut -d' ' -f1))"
echo "Update archive: build/PairHop-$version.zip and build/appcast.xml"
echo "Publish them with ./publish.sh"
echo "Signed app: $app"
echo "Install over the existing copy:"
echo "  osascript -e 'quit app \"PairHop\"' || true"
echo "  ditto \"$PWD/$app\" /Applications/PairHop.app"
