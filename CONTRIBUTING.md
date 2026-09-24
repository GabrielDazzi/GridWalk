# Contributing to Grid Walk

Thanks for helping. Keep the app free, private, and trademark-safe.

## Rules

- Never use "F1", "Formula 1", team names, or logos in UI strings, asset names, or identifiers. Prefer race / session / weekend.
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

## Pull requests

Use the PR template. Include:

1. **Summary** — what and why
2. **Verification** — exact commands you ran (`swift test`, `xcodebuild …`)
3. **Test plan** — checklist for reviewers

## Good first issues

- Portuguese / English string coverage
- Accessibility labels on session rows
- Docs and screenshots
