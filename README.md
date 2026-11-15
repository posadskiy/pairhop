# PairHop

[![Build](https://github.com/posadskiy/pairhop/actions/workflows/build.yml/badge.svg)](https://github.com/posadskiy/pairhop/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/posadskiy/pairhop)](https://github.com/posadskiy/pairhop/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey)](#requirements)

Menu bar app for moving a Bluetooth keyboard, trackpad, or mouse from one
Mac to another. macOS's Universal Control covers this only if both Macs are
signed into the same Apple ID and nearby each other — for anything else
(different accounts, work + personal Macs, one of them not around), you're
digging through System Settings to unpair and re-pair by hand, or buying a
paid utility. PairHop connects the accessory to the Mac you're using.

## Features

- **Menu bar only** — no Dock icon, no windows to manage
- **Use here** — brings the selected devices to this Mac. If the other Mac is awake it lets go first; if it's asleep, this Mac connects directly. A device already on this Mac is left alone
- **Hand off** — disconnects the devices so the other Mac can take them. Each row has its own Use here and Hand off
- **Keeps the bond when it can** — a device that remembers both Macs is reconnected, and the old pairing is forgotten only if the accessory is actually in range and still refuses
- **Linked Macs** — a pairing code both Macs share, so a stranger on the network can't release your keyboard. A Mac that fails the code five times is ignored for fifteen minutes. If the other Mac's identity changes, switching waits until you tap Trust
- **Shortcuts and links** — Settings records Use here, Hand off, and Toggle. `pairhop://switch?direction=take` does the same from another app. A checked display takes the devices when it connects
- **Updates itself** — checks GitHub Releases once a day and installs in the background; Check for Updates… in About asks right away
- **Nothing else to install** — Bluetooth is handled in the app, no Homebrew or helper tools
- **Apple Silicon** — the release build is arm64

## Install

Download `PairHop.dmg`, open it, and drag PairHop to Applications.

The disk image is signed with a Developer ID and notarized, so Gatekeeper
opens it on double-click. macOS will ask for Bluetooth access the first time
you scan for or switch devices — grant it in the prompt, or in
**System Settings → Privacy & Security → Bluetooth** if you missed it.

PairHop updates itself with [Sparkle](https://sparkle-project.org), reading the
`appcast.xml` attached to the latest GitHub release. Copies of 0.3.0 and earlier
do not have it, so install the next release by hand once.

## Usage

**First run** — click the menu bar icon. Devices already connected to this
Mac show up automatically — select the keyboard, trackpad, mouse, or
whatever else you want to move between Macs, then Save. In Settings, set
the same pairing code on both Macs so they can find each other.

**Use here** — click the menu bar icon → "Use here". The Mac that has the
devices disconnects them, and this Mac connects. If the other Mac is
asleep, this Mac tries on its own. It pages the accessory by address,
or pairs that address directly when this Mac has no bond. Turn the
accessory off and on only if that connection does not come up.

**Hand off** — disconnects the devices from this Mac and leaves them for
the other one. On the Mac you want to use, click "Use here". Each device
row has the same two buttons, for moving one accessory at a time.

**Without opening the menu** — Settings can record shortcuts for Use here,
Hand off, and Toggle. Another app can open
`pairhop://switch?direction=take` (or `send` or `toggle`). Add
`peripheral=Magic%20Keyboard` to name one device. Checking a display under
"Dock a display" takes the devices when that display connects. If a device
drops while it should be on this Mac, PairHop keeps trying for about two
minutes, including after you turn it off and on.

**Changing devices** — "Edit Devices…" re-runs the same scan/select flow.

**Settings** — the gear icon in the popover has:
- **Launch at Login**
- **Show device addresses** — off by default; shows each device's MAC
  address under its name in Edit Devices, for troubleshooting.
- **Pairing code** — the same code on both Macs. "Generate" fills one in;
  type it on the other Mac. The short code beside it should match.
- **Other Mac's address** — optional. Fill this in when the network
  blocks discovery. Each Mac also tells the other its current address
  every few seconds.
- **Trust** — if the other Mac's advertised identity no longer matches,
  switching pauses until you tap Trust.
- **Shortcuts** — Use here, Hand off, and Toggle.
- **Dock a display** — take the devices when that display connects.

Config is stored at `~/Library/Application Support/PairHop/config.json`.
The pairing code is stored in the Keychain.

## Requirements

- macOS 26 (Tahoe) or later, on an Apple Silicon Mac
- A Bluetooth keyboard, trackpad, mouse, or other HID accessory

## Building from source

```bash
git clone https://github.com/posadskiy/pairhop.git
cd pairhop
export NOTARY_KEYCHAIN_PROFILE="grammarbar-notary"
./build.sh
open build/PairHop.app
```

`build.sh` compiles a release arm64 binary, signs it with the Developer ID
already in the login keychain, notarizes it, and writes `build/PairHop.dmg`.
That disk image is what gets shared. The same Apple Developer team that signs
GrammarBar signs PairHop; no separate app record is required. The script
needs the network so Apple can timestamp the signature and notarize the image.

For quick iteration you can also run it unbundled — this shows a Dock icon
though, since `Info.plist`'s `LSUIElement` only applies inside a real `.app`
bundle:

```bash
swift run
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for more.

### Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Sources/PairHop/Info.plist`.
   Sparkle compares `CFBundleVersion`, so it has to go up every release. Merging to `main`
   makes the Release workflow tag `v<version>` and open the release.
2. Once per Mac, run `scripts/sparkle-keys.sh`. It keeps the Sparkle private key in the login
   keychain and writes the public key to `Config/SUPublicEDKey`, which is committed. If the
   keychain already has a Sparkle key, PairHop shares it.
3. `./build.sh` writes `build/PairHop.dmg`, `build/PairHop-<version>.zip` and a signed
   `build/appcast.xml`. `./publish.sh` attaches them to the release, the feed last.
   Installed copies read `releases/latest/download/appcast.xml`.

## Contributing

Bug reports, feature requests, and PRs are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). Please follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

## Acknowledgments

- [IOBluetooth](https://developer.apple.com/documentation/iobluetooth) — the macOS Bluetooth framework PairHop uses to connect and pair accessories.

## License

[MIT](LICENSE)
