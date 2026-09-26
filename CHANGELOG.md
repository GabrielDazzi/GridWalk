# Changelog

All notable changes to Grid Walk are documented here.

## Unreleased

### Added

- Direct Mac builds can check GitHub for a newer release and replace the app in place. App Store copies update from the store.
- Menu bar modes (v1.1): countdown, my driver, title fight, my team, last race, auto
- Ticker rotation and compact menu bar style
- Favorite driver / team pickers; spoiler-free hides last-race label
- Standings + last-results fetch (race-aware refresh, separate from schedule)
- Widgets (Mac desktop + iPhone home/lock screen) with live countdown timer
- iPhone Live Activity / Dynamic Island when the next session is within 6 hours
- App Group `group.com.gabrieldazzi.gridwalk` shared season cache + widget snapshot
- GridWalkKit: season fetch, Application Support/App Group cache (12h), `ScheduleStore`
- macOS menu bar countdown and weekend panel
- iOS next-session screen with countdown and weekend list
- Local session alerts (15 minutes before) with per-category toggles
- Add weekend to Calendar (EventKit write-only)
- "Grid at night" theme
- `GridWalkDesign` package target: night grid tokens, contrast-tested light palette, session tags with text labels, Liquid Glass cards on OS 26 with solid fallback
- Redesigned Mac popover: hero countdown, weekend timeline with past sessions dimmed, favorites snippet, settings gear
- iPhone tabs: Countdown, Weekend (with season list), Standings (drivers / teams), Settings
- First-launch onboarding: favorite driver and team, menu bar mode, optional alerts
- Loading, empty, offline, error and off-season states with "last updated" on every screen
- VoiceOver labels like "Qualifying in 1 day 4 hours", Dynamic Type and Reduce Motion support
- Widgets and Live Activity use the same tokens
- English + Portuguese string catalog (starter set)
- Ko-fi / Buy Me a Coffee donation links in README and FUNDING.yml
