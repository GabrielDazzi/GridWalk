# Grid Walk

Race weekend countdown for macOS and iPhone. Free, open source, private by default.

**App Store subtitle:** Race weekend countdown

## What it does

- Menu bar countdown to the next session (macOS), with the full weekend in your local time
- Big countdown on iPhone plus the weekend session list
- Local alerts 15 minutes before Qualifying, Sprint and Race (configurable)
- One tap to add the weekend to Calendar

No accounts. No tracking. No backend of our own. Schedule data comes from the public Jolpica feed and is cached on device so the countdown keeps working offline.

## Private by default

Everything runs on your Mac or iPhone. Session times are stored in Application Support. Alert preferences stay in UserDefaults. Notifications and Calendar access are optional and local only.

## Platforms

| Platform | How you get it |
| --- | --- |
| macOS | Menu bar app (App Store later; DMG / Homebrew planned) |
| iPhone | App Store / TestFlight |

## Develop

Requirements: Xcode 16+, macOS 14+ / iOS 17+.

```bash
# Package tests (no Xcode UI needed)
cd GridWalkKit && swift test

# App
open "Grid Walk.xcodeproj"
```

Shared logic lives in `GridWalkKit`. The app targets stay thin (SwiftUI only).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Translations (English + Portuguese) are a great first PR.

## Trademark

"Grid Walk" and the app icon are protected — see [TRADEMARKS.md](TRADEMARKS.md). Do not use the name or logo in a way that implies official affiliation with any championship, team, or series.

## Donations

Every feature stays free. Tips help keep the lights on:

- Ko-fi: _(coming soon)_
- Buy Me a Coffee: _(coming soon)_

Donation links stay in the README and Mac builds shipped outside the App Store — not in App Store builds.

## License

[MIT](LICENSE)
