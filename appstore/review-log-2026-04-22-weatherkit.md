# App Store Review Log — 2026-04-22

## Context
- App: Kinen
- Platform affected: macOS
- Version under review: 1.0
- Review submission ID: `bb0f3ad5-24cd-4c11-86ce-b5516d35a6ee`
- Review date: 2026-04-20

## Apple message
- Guideline 2.1 - Information Needed
- Apple asked whether the app includes any `WeatherKit` functionality.
- If yes, Apple requested exact navigation steps to reach that functionality in the app.

## Root cause
- The app does include optional `WeatherKit` functionality for auto-recording location and weather on new journal entries.
- Project configuration was inconsistent:
- `WeatherKit` entitlement had been placed in `Info.plist`, which is not the correct signing location.
- Actual target entitlements did not declare `com.apple.developer.weatherkit`.
- This created avoidable confusion for review and broke the capability/signing path for a clean submission build.

## Fix applied
- Removed `com.apple.developer.weatherkit` from `Resources/Info.plist`.
- Added `com.apple.developer.weatherkit = true` to:
- `Resources/Kinen-macOS.entitlements`
- `Resources/Kinen-iOS.entitlements`
- Synced capability config in `project.yml` so regenerated Xcode project settings stay aligned.
- Updated `docs/privacy.html` wording to explicitly mention weather data source.
- Added reviewer-facing reply and Review Notes draft in `appstore/review-notes-weatherkit.md`.

## Files changed
- `Resources/Info.plist`
- `Resources/Kinen-macOS.entitlements`
- `Resources/Kinen-iOS.entitlements`
- `project.yml`
- `docs/privacy.html`
- `appstore/review-notes-weatherkit.md`

## Validation
- `plutil -lint` passed for:
- `Resources/Info.plist`
- `Resources/Kinen-macOS.entitlements`
- `Resources/Kinen-iOS.entitlements`
- Local macOS archive/export path was re-verified after the entitlement fix.
- A new macOS build with the fix was successfully produced and uploaded during verification work.

## Reviewer navigation path
1. Launch Kinen.
2. Open Settings from the sidebar.
3. In the Journal section, enable `Auto-record location & weather`.
4. Grant location permission when macOS prompts for it.
5. Return to the Journal screen.
6. Click the `New Entry` button in the toolbar.
7. When the editor opens, the app fetches current location and weather in the background.
8. Save the entry and inspect the saved metadata in the entry detail view.

## Notes
- The WeatherKit feature is optional and off by default.
- Weather data is only fetched after the user enables the setting above.
- This review issue is documentation/review-routing related, not a product behavior bug.

## Next manual steps
1. Upload/select the fixed macOS build in App Store Connect.
2. Paste the prepared text from `appstore/review-notes-weatherkit.md` into Review Notes.
3. Reply to App Review with the same WeatherKit explanation and navigation steps.
4. Resubmit macOS 1.0 for review.
