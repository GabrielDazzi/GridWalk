# Grid Walk

Free, open-source race weekend companion for macOS and iOS. Swift 6 + SwiftUI, no backend, no accounts, no tracking. MIT license.

## Rules
- Never use "F1", "Formula 1" or team logos in branding, the app name, asset names or identifiers. Use neutral words: race, session, weekend. Showing driver codes, driver names and team standings from the data feed is fine; that's the feature.
- No third-party dependencies unless agreed in an issue first.
- Keep decisions out of views. Logic lives in GridWalkKit, where tests can reach it.
- Every new user-facing string is added in English and Portuguese.
- PR titles: `type(scope): phrase`. Link issues with `Refs #123`.
- PR body: Summary, Verification (exact commands), Test plan checklist.

## Status
- **v1 done:** menu bar countdown, weekend view, session alerts, Calendar, widgets, Live Activity.
- **Next:** menu bar modes (driver / title fight / team / last race / auto / ticker / compact).

## Layout
- `Grid Walk/App/` startup and scenes (macOS MenuBarExtra, iOS app)
- `Grid Walk/UI/` SwiftUI views only
- `Grid Walk Widget/` WidgetKit + Live Activity UI
- `GridWalkKit/` local Swift package
  - `Core/` models, preferences, App Group, snapshots, menu bar formatting
  - `Services/` data feed, cache, notifications, calendar, Live Activity, standings
- Tests use Swift Testing (`swift test` in GridWalkKit).

## Data
- Schedule: https://api.jolpi.ca/ergast/f1/current.json?limit=100
- Driver standings: https://api.jolpi.ca/ergast/f1/current/driverStandings.json
- Constructor standings: https://api.jolpi.ca/ergast/f1/current/constructorStandings.json
- Last race results: https://api.jolpi.ca/ergast/f1/current/last/results.json
- Session keys: FirstPractice, SecondPractice, ThirdPractice, SprintQualifying, Sprint, Qualifying; race date/time are top-level. Sprint weekends omit SecondPractice/ThirdPractice.
- Schedule refresh: at most every 12 hours. Standings refresh after each race (not on the 12h timer, never per ticker tick).
- Cache on device (App Group `group.com.gabrieldazzi.gridwalk`); work fully offline.

## Shared container
App and widget share season JSON + `widget_snapshot.json` via the App Group. The app refreshes the network; the widget only reads cache.

## Out of scope for now
WeatherKit, Apple Watch, Siri/Shortcuts, AlarmKit, predictions game, share cards, teammate battles.
