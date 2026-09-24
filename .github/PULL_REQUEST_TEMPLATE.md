## Summary
<!-- What changed and why. -->

## Verification
```bash
cd GridWalkKit && swift test
# and/or
xcodebuild -scheme "Grid Walk" -destination 'platform=macOS' build
```

## Test plan
- [ ] Menu bar / iOS countdown shows the next session
- [ ] Weekend list uses local time; sprint weekends marked
- [ ] Refresh does not hammer the network
- [ ] Alert toggles reschedule notifications
- [ ] No "F1" / team names / logos in UI or asset names
- [ ] New strings exist in English and Portuguese
