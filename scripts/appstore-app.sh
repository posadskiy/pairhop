#!/usr/bin/env bash
# Build the Mac App Store edition: sandboxed, with no Sparkle (the store does the updating).
#   scripts/appstore-app.sh            build/PairHop-AppStore.app, sandboxed and signed with the
#                                      Developer ID, to try on this Mac. Not for upload.
#   scripts/appstore-app.sh package    build/PairHop-AppStore.pkg, signed for App Store Connect.
#
# package needs three things from developer.apple.com / App Store Connect:
#   MAS_APP_IDENTITY="Apple Distribution: Name (TEAMID)"   (or "3rd Party Mac Developer Application: ...")
#   MAS_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Name (TEAMID)"   (or "Mac Installer Distribution: ...")
#   MAS_PROVISION_PROFILE=path/to/PairHop.provisionprofile   (Mac App Store profile for com.posadskiy.pairhop)
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-local}"
export PAIRHOP_APPSTORE=1
scratch=".build-appstore"

swift build -c release --arch arm64 --scratch-path "$scratch"
bin="$(swift build -c release --arch arm64 --scratch-path "$scratch" --show-bin-path)"

app="build/PairHop-AppStore.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/PairHop" "$app/Contents/MacOS/PairHop"
cp "Sources/PairHop/Info.plist" "$app/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
cp "THIRD_PARTY_LICENSES.md" "$app/Contents/Resources/THIRD_PARTY_LICENSES.md"
cp "Resources/PrivacyInfo.xcprivacy" "$app/Contents/Resources/PrivacyInfo.xcprivacy"

plist="$app/Contents/Info.plist"
for key in SUEnableAutomaticChecks SUAutomaticallyUpdate SUScheduledCheckInterval SUScheduledImpatientCheckInterval; do
  /usr/libexec/PlistBuddy -c "Delete :$key" "$plist"
done
/usr/libexec/PlistBuddy -c "Add :LSApplicationCategoryType string public.app-category.utilities" "$plist"

if otool -L "$app/Contents/MacOS/PairHop" | grep -qi sparkle; then
  echo "The App Store build still links Sparkle." >&2
  exit 1
fi

entitlements="Resources/PairHop-AppStore.entitlements"
if [[ "$mode" == "package" ]]; then
  : "${MAS_APP_IDENTITY:?Set MAS_APP_IDENTITY}"
  : "${MAS_INSTALLER_IDENTITY:?Set MAS_INSTALLER_IDENTITY}"
  : "${MAS_PROVISION_PROFILE:?Set MAS_PROVISION_PROFILE}"
  profile_plist="$(mktemp)"
  trap 'rm -f "$profile_plist"' EXIT
  security cms -D -i "$MAS_PROVISION_PROFILE" > "$profile_plist"
  app_id="$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.application-identifier" "$profile_plist")"
  team_id="$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" "$profile_plist")"
  cp "$MAS_PROVISION_PROFILE" "$app/Contents/embedded.provisionprofile"
  # A profile saved from a browser carries com.apple.quarantine, and App Store Connect rejects
  # any file in the app that has it (error 91109). Clear every extended attribute.
  xattr -cr "$app"
  signed="$(mktemp)"
  cp "$entitlements" "$signed"
  /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $app_id" "$signed"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team_id" "$signed"
  codesign --force --timestamp --options runtime --entitlements "$signed" --sign "$MAS_APP_IDENTITY" "$app"
  rm -f "$signed"
  codesign --verify --deep --strict --verbose=2 "$app"
  rm -f build/PairHop-AppStore.pkg
  productbuild --component "$app" /Applications --sign "$MAS_INSTALLER_IDENTITY" build/PairHop-AppStore.pkg
  echo "Wrote build/PairHop-AppStore.pkg. Upload it with Transporter or: xcrun altool --upload-app -f build/PairHop-AppStore.pkg -t macos"
else
  # shellcheck source=scripts/developer-id.sh
  source scripts/developer-id.sh
  identity="$(resolve_developer_id)"
  codesign --force --options runtime --entitlements "$entitlements" --sign "$identity" "$app"
  codesign --verify --strict --verbose=2 "$app"
  codesign -d --entitlements - "$app" 2>/dev/null | grep -c "app-sandbox" | sed 's/^/sandbox entitlement present: /'
  echo "Built $app (sandboxed, signed with the Developer ID, not for upload)"
fi
