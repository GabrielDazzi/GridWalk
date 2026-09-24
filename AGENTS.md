# Grid Walk

Free, open-source race weekend companion for macOS and iOS. Swift 6 + SwiftUI, no backend, no accounts, no tracking. MIT license.

## Rules
- Never use "F1", "Formula 1", team names or logos in UI strings, asset names or identifiers. Use neutral words: race, session, weekend.
- No third-party dependencies unless agreed in an issue first.
- Keep decisions out of views. Logic lives in GridWalkKit, where tests can reach it.
- Every new user-facing string is added in English and Portuguese.
- PR titles: `type(scope): phrase`. Link issues with `Refs #123`.
- PR body: Summary, Verification (exact commands), Test plan checklist.

## Layout
- `Grid Walk/App/` startup and scenes (macOS MenuBarExtra, iOS app)
- `Grid Walk/UI/` SwiftUI views only
- `Grid Walk Widget/` WidgetKit + Live Activity UI
- `GridWalkKit/` local Swift package
  - `Core/` models, preferences, App Group, snapshots
  - `Services/` data feed, cache, notifications, calendar, Live Activity
- Tests use Swift Testing (`swift test` in GridWalkKit).

## Data
- Schedule: https://api.jolpi.ca/ergast/f1/current.json?limit=100
- Session keys: FirstPractice, SecondPractice, ThirdPractice, SprintQualifying, Sprint, Qualifying; race date/time are top-level. Sprint weekends omit SecondPractice/ThirdPractice.
- Low rate limits: cache the season on device (App Group `group.com.gabrieldazzi.gridwalk`), refresh at most every 12 hours, work fully offline.

## Shared container
App and widget share season JSON + `widget_snapshot.json` via the App Group. The app refreshes the network; the widget only reads cache.

## Out of scope for now
WeatherKit, Apple Watch, Siri/Shortcuts, AlarmKit, predictions game, share cards, teammate battles, favorite driver/team.
