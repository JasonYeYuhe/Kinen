# Kinen Audit Handoff

## Goal

This document hands off the current project audit to another coding agent for implementation.
The target is not another review pass. The target is to make concrete code changes that fix the most important verified issues without disturbing unrelated work already present in the repo.

## Project Snapshot

- Project: `Kinen`
- Type: SwiftUI + SwiftData + XcodeGen
- Platforms: macOS 15+, iOS 18+
- Workspace root: `/Users/jason/Documents/Kinen`
- Current date of audit: `2026-04-11`
- Current App Store status file says iOS + macOS are `Waiting for Review`

## Current Verified Build Status

Commands run during the audit:

```bash
xcodegen generate
xcodebuild build -scheme Kinen -destination 'platform=macOS'
xcodebuild build -scheme KinenIOS -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme Kinen -destination 'platform=macOS'
```

Observed results:

- `xcodegen generate`: passed
- `xcodebuild build -scheme Kinen -destination 'platform=macOS'`: passed
- `xcodebuild build -scheme KinenIOS -destination 'platform=iOS Simulator,name=iPhone 17'`: passed
- `xcodebuild test -scheme Kinen -destination 'platform=macOS'`: failed

Test failure cause:

- `KinenTests` target is missing `Info.plist` configuration in `project.yml`
- Current failure message says code signing cannot proceed because the test target has no `Info.plist` and one is not generated automatically

## Important Workspace Constraint

The git worktree is dirty.
There are existing user changes in App Store assets and entitlements.
Do not revert or overwrite unrelated local changes.

Known existing modified/untracked areas at audit time:

- `APP_STORE_STATUS.md`
- `Resources/Assets.xcassets/AppIcon.appiconset/*`
- `Resources/Kinen-macOS.entitlements`
- `appstore/screenshots/`

## Highest Priority Verified Issues

### 1. Test target is misconfigured

Evidence:

- `project.yml` defines `KinenTests` without `INFOPLIST_FILE`
- `xcodebuild test` currently fails

Required fix:

- Update `project.yml` so `KinenTests` can build and run tests
- Regenerate the project if needed
- Confirm `xcodebuild test -scheme Kinen -destination 'platform=macOS'` passes

Acceptance criteria:

- The macOS unit test command succeeds

### 2. AI auto-analysis default behavior is inconsistent with UI defaults

Evidence:

- `Sources/Views/Screens/SettingsView.swift` uses `@AppStorage(..., default true)` style state for:
  - `enableAutoSentiment`
  - `enableAutoTags`
- `Sources/Features/AI/AIJournalingLoop.swift` reads the same keys via:

```swift
UserDefaults.standard.bool(forKey: "enableAutoSentiment")
UserDefaults.standard.bool(forKey: "enableAutoTags")
```

- `bool(forKey:)` returns `false` when the key is unset
- That means new installs may silently skip AI analysis until the user visits settings

Required fix:

- Make the default behavior consistent
- New users should get the intended default AI behavior immediately

Acceptance criteria:

- Auto sentiment and auto tags behave according to product default even before settings are manually opened
- Add or update tests if reasonable

### 3. Template-based entry editing is broken or incomplete

Evidence:

- `EntryEditorSheet` initializes `content`, `title`, `mood`, `template`, `photoData`, `entryTags`
- It does not initialize `templateResponses` from an existing template entry
- Save logic for template entries reconstructs content only from `templateResponses`
- Existing template entries therefore cannot round-trip correctly through edit mode

Relevant file:

- `Sources/Views/Screens/EntryEditorSheet.swift`

Required fix:

- Make existing template-based entries editable without losing structured content
- Preserve current behavior for new entries

Acceptance criteria:

- Existing template entry opens with editable values
- Saving does not blank or silently destroy content

### 4. “Backup & Restore” is incomplete and currently misleading

Evidence:

- `SettingsView` exposes `Backup & Restore`
- UI only creates backups, there is no restore flow
- `BackupService.restoreBackup(...)` imports entries, but does not restore:
  - entry-to-tag relationships from `tagNames`
  - insights from `insights`

Relevant files:

- `Sources/Views/Screens/SettingsView.swift`
- `Sources/Features/Settings/BackupService.swift`

Required fix:

- Either complete the restore flow end-to-end or reduce misleading UX
- Minimum acceptable implementation:
  - restore UI entry point
  - restore operation wiring
  - tag relationships restored
  - insights restored

Acceptance criteria:

- Backup/restore wording matches actual capability
- Restored data is materially complete

### 5. Localization wiring is incomplete and inconsistent

Evidence:

- `Resources/en.lproj/Localizable.strings` and `Resources/zh-Hans.lproj/Localizable.strings` use namespaced keys such as:
  - `mood.terrible`
  - `template.freeWrite`
- But code still uses raw strings in many places
- `Mood.label` uses `String(localized: "Terrible")` instead of key-based lookup
- `JournalTemplate` also uses raw English phrases rather than the namespaced keys already defined
- There are still many hard-coded UI strings across screens and components
- `project.yml` only lists `[en, zh-Hans]`
- Phase 4 planning docs mention `zh-Hant` and `ja`, but those resources do not exist in the repo

Required fix:

- Choose one localization approach and make it consistent
- Prefer stable key-based localization rather than using display strings as keys
- Fix the most user-visible strings first

Acceptance criteria:

- Existing string resources are actually used by code
- Critical user-facing screens no longer rely heavily on hard-coded English

### 6. Product/privacy messaging is contradictory

Evidence:

- Settings UI offers iCloud sync
- Privacy copy says “No cloud sync”
- Marketing page strongly promotes “Zero cloud”
- Paywall lists iCloud sync as a Pro feature
- App behavior and messaging are not aligned

Relevant files:

- `Sources/Views/Screens/SettingsView.swift`
- `Sources/App/KinenApp.swift`
- `Sources/Views/Screens/ProPaywallView.swift`
- `Sources/Views/Components/ProGate.swift`
- `docs/index.html`

Required fix:

- Align actual product behavior with product copy
- Do not leave contradictory claims in app UI and website

Acceptance criteria:

- Local app copy and website copy tell the same story
- If sync remains supported, remove “zero cloud / no cloud sync” claims where false

## Secondary Issues Worth Fixing If Time Allows

### 7. Release asset warnings

Evidence:

- Both macOS and iOS builds warn that `AppIcon` has 7 unassigned children
- Repo contains duplicated icon files like `icon_1024 2.png`

Required fix:

- Clean up duplicated/unassigned icon files or `Contents.json`
- Remove asset catalog warnings if possible without disturbing user’s current asset work

### 8. macOS entitlements deserve a sanity check

Evidence:

- `Resources/Kinen-macOS.entitlements` is currently effectively empty

Required action:

- Check whether current macOS capabilities and App Store assumptions still match actual entitlements
- Do not change blindly if user is actively editing this file elsewhere

## Recommended Implementation Order

1. Fix `KinenTests` target so tests can run
2. Fix AI default settings mismatch
3. Fix template entry edit round-trip
4. Complete or narrow backup/restore behavior
5. Clean up localization wiring on the most visible screens
6. Resolve privacy/sync/product messaging contradictions
7. Address icon asset warnings if low-risk

## Files Most Likely To Change

- `/Users/jason/Documents/Kinen/project.yml`
- `/Users/jason/Documents/Kinen/Sources/Features/AI/AIJournalingLoop.swift`
- `/Users/jason/Documents/Kinen/Sources/Views/Screens/EntryEditorSheet.swift`
- `/Users/jason/Documents/Kinen/Sources/Features/Settings/BackupService.swift`
- `/Users/jason/Documents/Kinen/Sources/Views/Screens/SettingsView.swift`
- `/Users/jason/Documents/Kinen/Sources/Models/Mood.swift`
- `/Users/jason/Documents/Kinen/Sources/Models/JournalTemplate.swift`
- `/Users/jason/Documents/Kinen/Sources/Views/Screens/ContentView.swift`
- `/Users/jason/Documents/Kinen/Sources/Views/Screens/ProPaywallView.swift`
- `/Users/jason/Documents/Kinen/docs/index.html`

## Verification Requirements

After making changes, run at least:

```bash
xcodegen generate
xcodebuild test -scheme Kinen -destination 'platform=macOS'
xcodebuild build -scheme Kinen -destination 'platform=macOS'
xcodebuild build -scheme KinenIOS -destination 'platform=iOS Simulator,name=iPhone 17'
```

If a command cannot be run, explain exactly why.

## Deliverable Format Expected From The Implementing Agent

The implementing agent should return:

1. What was changed
2. Which issues were fully fixed
3. Which issues were only partially addressed
4. Exact verification commands run and their outcomes
5. Any remaining risks
