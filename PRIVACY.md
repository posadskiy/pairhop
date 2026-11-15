# PairHop Privacy Policy

Last updated: 15 November 2026

PairHop moves Bluetooth accessories between your Macs. It has no account, no
ads and no analytics, and it does not send your data to the developer or to
any third party.

## What PairHop stores on your Mac

- **Your device list.** The names and Bluetooth addresses of the accessories
  you choose, and the other Mac's name and address if you link two Macs. This
  stays in PairHop's settings folder on your Mac.
- **Your pairing code.** Stored in the macOS Keychain.
- **A log file.** PairHop's own log of recent activity, kept on your Mac to
  help fix problems. You can clear it in Settings → Troubleshooting.
- **Your preferences,** such as Launch at Login and shortcuts.

## What PairHop shares, and with whom

When you link two Macs, they exchange the device list and switch requests
directly with each other, over your local network or over Bluetooth. This
traffic is encrypted with a key made from your pairing code. It goes only to
the other Mac you linked, never to a server.

## Diagnostics and bug reports

**Save Diagnostics…** writes a text file to a place you choose. It contains
PairHop's log and Bluetooth system messages for your accessories, including
their names and addresses. PairHop never sends this file anywhere. If you
choose to attach it to a bug report, it becomes public on GitHub, so look it
over first.

**Report…** opens a GitHub page in your browser with your PairHop and macOS
versions filled in. Nothing is sent until you submit the form yourself, and
then GitHub's privacy policy applies.

## Updates

- **Mac App Store version:** updated by the App Store. PairHop itself makes no
  update requests.
- **Version downloaded from GitHub:** checks GitHub Releases about once a day
  for a new version, using Sparkle. Like any web request, this lets GitHub see
  your IP address. PairHop sends no other information with it.

## Permissions PairHop asks for

- **Bluetooth,** to connect and disconnect your accessories.
- **Local Network,** to find and talk to your other Mac.
- **Notifications** (optional), to tell you when a handoff fails.

## Children

PairHop does not collect any personal information from anyone, including
children.

## Changes to this policy

If PairHop ever collects data, this policy and the App Store privacy details
will be updated first, and the change will be listed in the release notes.

## Contact

Dimitri Posadskiy — support@posadskiy.com
Source code and issues: https://github.com/posadskiy/pairhop
