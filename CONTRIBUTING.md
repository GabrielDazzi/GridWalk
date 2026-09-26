# Contributing to Grid Walk

Thanks for helping. Keep the app free, private, and trademark-safe.

## Rules

- Never use "F1", "Formula 1" or team logos in branding, the app name, asset names or identifiers. Prefer race / session / weekend. Driver codes, driver names and team standings from the data feed are fine.
- No third-party dependencies unless agreed in an issue first.
- Logic lives in `GridWalkKit` (testable). Views stay thin.
- Every new user-facing string: English **and** Portuguese (`Localizable.xcstrings`).
- PR titles: `type(scope): phrase` (e.g. `feat(kit): cache season offline`).
- Link issues with `Refs #123`.

## Setup

```bash
cd GridWalkKit && swift test
open "../Grid Walk.xcodeproj"
```

## Formatting

The repo uses the `swift format` tool that ships with Xcode. Rules live in `.swift-format`. From the repo root:

```bash
# fix in place
swift format format --in-place --recursive --parallel "Grid Walk" "Grid Walk Widget" GridWalkKit/Sources GridWalkKit/Tests GridWalkKit/Package.swift
# what CI runs
swift format lint --strict --recursive --parallel "Grid Walk" "Grid Walk Widget" GridWalkKit/Sources GridWalkKit/Tests GridWalkKit/Package.swift
```

## Strings

There are three String Catalogs: the app, the widget, and `GridWalkKit/Sources/GridWalkKit/Resources`. Kit code uses `String(localized: "...", bundle: .module)`. After adding strings, build the Mac and iOS targets, then pull the new keys into the catalogs and add the Portuguese values:

```bash
scripts/sync-strings.sh   # reads build/dd by default; pass another DerivedData path if needed
```

`swift test` fails if any string is missing Portuguese.

## Pull requests

Use the PR template. Include:

1. **Summary** — what and why
2. **Verification** — exact commands you ran (`swift test`, `xcodebuild …`)
3. **Test plan** — checklist for reviewers

## Good first issues

- Portuguese / English string coverage
- Accessibility labels on session rows
- Docs and screenshots
