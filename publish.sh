#!/usr/bin/env bash
# Attach the build to the GitHub release for the version in Info.plist.
#   ./build.sh && ./publish.sh
#
# Uploads PairHop.dmg for the first download, PairHop-<version>.zip for Sparkle, and
# appcast.xml last, so the app never announces a version whose archive is missing.
# Installed copies read https://github.com/posadskiy/pairhop/releases/latest/download/appcast.xml.
# The release is created if the Release workflow has not made it yet.
set -euo pipefail
cd "$(dirname "$0")"

repo="posadskiy/pairhop"
version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Sources/PairHop/Info.plist)"
tag="v$version"
files=(build/PairHop.dmg "build/PairHop-$version.zip" build/appcast.xml)

if [[ ! -s Config/SUPublicEDKey ]]; then
  echo "Run scripts/sparkle-keys.sh and commit Config/SUPublicEDKey before a public build." >&2
  exit 1
fi
for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing $file. Run ./build.sh for $version first." >&2
    exit 1
  fi
done
if ! grep -q "releases/download/$tag/PairHop-$version.zip" build/appcast.xml; then
  echo "build/appcast.xml is not for $version. Run ./build.sh again." >&2
  exit 1
fi

if ! gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
  gh release create "$tag" --repo "$repo" --title "$tag" --generate-notes \
    --notes "Notarized build. Open PairHop.dmg and drag PairHop to Applications."
fi
gh release upload "$tag" --repo "$repo" --clobber build/PairHop.dmg "build/PairHop-$version.zip"
gh release upload "$tag" --repo "$repo" --clobber build/appcast.xml
echo "Published $tag: https://github.com/$repo/releases/tag/$tag"
