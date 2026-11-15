#!/bin/bash
# Run once on the release Mac, before the first public Sparkle build.
# The private EdDSA key stays in the login keychain. This writes the public key to
# Config/SUPublicEDKey. Commit that file. Never export the private key into the repo.
# If the keychain already holds a Sparkle key (GrammarBar's), generate_keys prints that
# one and PairHop shares it. A later build signs appcast.xml with the keychain key, or with
# SPARKLE_ED_KEY_FILE if the key was exported for another machine (`generate_keys -x`).
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this on a Mac. Sparkle's generate_keys tool is macOS only." >&2
  exit 1
fi

swift build -c release --arch arm64 >/dev/null
tool=""
while IFS= read -r candidate; do
  tool="$candidate"
  break
done < <(find .build/artifacts -type f -path '*/bin/generate_keys' | sort)
if [[ -z "$tool" ]]; then
  echo "Sparkle's generate_keys is not in .build/artifacts." >&2
  exit 1
fi

out="$("$tool")"
printf '%s\n' "$out"
key="$(printf '%s\n' "$out" | sed -n 's:.*<string>\([A-Za-z0-9+/=]*\)</string>.*:\1:p' | head -1)"
if [[ -z "$key" ]]; then
  echo "generate_keys did not print a public key." >&2
  exit 1
fi

mkdir -p Config
printf '%s\n' "$key" > Config/SUPublicEDKey
echo "Wrote Config/SUPublicEDKey. Commit that file. The private key is in the login keychain."
