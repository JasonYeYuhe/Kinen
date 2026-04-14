# Kinen Phase 6 Development Plan — "Polish & Delight"

**Version:** 0.3.0  
**Start:** 2026-04-14  
**Goal:** Elevate user experience with data safety, smart automation, visual refinements, and engagement features.

> **Reviewed by:** Claude deep audit + Codex architecture review  
> **Key revision:** Reordered sprints per Codex recommendation — data safety first, schema changes batched, 3 features deferred to Phase 7.

---

## Pre-Phase: Bug Fixes (Completed ✅)

All critical bugs from the deep audit have been resolved:

- [x] `BackupService.swift` — eliminated `baseAddress!` force unwrap crash risk
- [x] `JournalEntry.swift` — replaced `tags!.append` / `insights!.append` with safe optional chaining
- [x] `SyncStatusBadge.swift` — fixed `iCloudSyncEnabled` default value mismatch (`true` → `false`)
- [x] `SyncStatusBadge.swift` — localized hardcoded help text
- [x] `AIJournalingLoop.swift` — localized ~30 AI insight/experiment strings (EN + zh-Hans)
- [x] `RecapGenerator.swift` — localized ~10 growth notes and action items (EN + zh-Hans)
- [x] `BackupService.swift` — replaced 3x silent `try?` with proper error logging
- [x] Removed empty `Sources/Features/Insights/` placeholder directory
- [x] Build verified: macOS target compiles cleanly

---

## Sprint 6.1 — Data Safety & Schema Migration

**Focus:** Strengthen data protection and batch all SwiftData model changes into one migration pass.

> **Why first:** Codex identified that `JournalEntry` schema changes risk migration failures that drop to in-memory container (apparent data loss). Batching all model changes into one sprint with proper migration planning eliminates this risk for later sprints.

### 6.1.1 Batch Schema Migration
- Add `isPinned: Bool = false` to `JournalEntry`
- Add `previousContent: String?` to `JournalEntry`
- Add `longestStreak: Int = 0` to user-level `@AppStorage`
- All new fields have defaults → lightweight migration, no versioned schema needed
- Update `BackupEntry` to include `isPinned` and `previousContent` for backup/restore round-trip
- Update `ExportService` to include new fields in markdown/JSON output
- Test migration: install old build → update → verify data intact

### 6.1.2 Backup Password Strength Validation
- Minimum 6 characters required
- Strength indicator (weak/medium/strong) in backup UI:
  - Weak: 6-7 chars
  - Medium: 8-9 chars
  - Strong: 10+ chars with mixed character types
- Prevent backup creation with empty or too-short passwords
- Localize all feedback strings (EN + zh-Hans)

### 6.1.3 Auto-Backup Reminder
- If last backup >30 days ago AND user has >10 entries → show subtle banner in Settings
- Banner with "Backup Now" action, dismissable for 7 days
- Track via `@AppStorage("lastBackupDate")` (ISO 8601 string)

### 6.1.4 Entry Version History (Single Undo)
- Before each save, store current content into `previousContent`
- Add "Revert to Previous" action in entry detail (only if `previousContent != nil`)
- Confirmation alert before reverting
- Localize action labels

### 6.1.5 Improved Test Coverage
- `JournalEntryTests.swift` — model CRUD, addTag, addInsight, displayTitle, pinning
- `ExportServiceTests.swift` — markdown, JSON, plain text output verification
- `WidgetDataProviderTests.swift` — sync and data format
- Target: 7% → 15%+ test line coverage

**Files touched:** `JournalEntry.swift`, `BackupService.swift`, `ExportService.swift`, `EntryDetailScreen.swift`, `SettingsView.swift`, `Tests/` (3 new files), `Localizable.strings` (both)

**Gemini review checkpoint after this sprint.**

---

## Sprint 6.2 — Smart Journaling Enhancements

**Focus:** Make daily journaling faster and more intelligent.

### 6.2.1 Mood Suggestions from Text
- Analyze entry content with debounced `SentimentAnalyzer.analyzeSentiment(_:)` (NOT the mutating `processEntry`)
- Map sentiment score to 5-level mood: <-0.4=terrible, <-0.1=bad, <0.1=neutral, <0.4=good, ≥0.4=great
- Show as subtle chip below mood picker: "Feeling **Good**?" with tap-to-accept
- Debounce: 2 seconds after user stops typing, minimum 50 chars
- Localize suggestion text

### 6.2.2 Entry Pinning UI
- Swipe action + context menu "Pin to Top" / "Unpin" on journal entries
- Dedicated pinned section at top of `JournalListScreen` (separate from date-grouped entries)
- Max 3 pinned entries per journal notebook
- Pin icon indicator on `EntryRow`

### 6.2.3 Word Count Goal & Progress
- Optional daily word count goal (off by default, configurable in Settings: 100/250/500/1000)
- Progress ring overlay in `EntryEditorSheet` footer
- Celebrate when goal reached (confetti via `.sensoryFeedback` + haptic)
- Persist via `@AppStorage("dailyWordGoal")` (0 = disabled)

### 6.2.4 Duplicate Entry Detection
- Before saving, check for entries with >90% similar content created within last hour
- Compare normalized text (strip template markers `<!-- ... -->` and `**heading**` formatting first)
- Show "Similar entry exists — save anyway?" confirmation
- Simple character-level comparison on first 200 normalized chars

**Files touched:** `EntryEditorSheet.swift`, `JournalListScreen.swift`, `EntryRow.swift`, `SentimentAnalyzer.swift`, `SettingsView.swift`, `Localizable.strings` (both)

**Gemini review checkpoint after this sprint.**

---

## Sprint 6.3 — Visual & UX Polish

**Focus:** Refined aesthetics and smoother interactions.

### 6.3.1 Appearance Mode Toggle
- Explicit dark/light/system toggle in Settings
- `@AppStorage("appearanceMode")` — 0=system, 1=light, 2=dark
- Apply `.preferredColorScheme()` on **both** `WindowGroup` and macOS `Settings` scene in `KinenApp.swift`
- Localize labels

### 6.3.2 Statistics Dashboard Cards
- Redesign `InsightsScreen` top section with card-based layout
- Add "most productive day of week" insight
- Animated counters for total entries / total words / current streak
- Use `JournalEntry.writingDuration` (single source of truth, not `WritingSession`)

### 6.3.3 Pull-to-Refresh / Toolbar Refresh
- iOS: `.refreshable` on `JournalListScreen` → trigger widget data sync
- macOS: toolbar refresh button (`.refreshable` not available on macOS `NavigationSplitView`)
- Light haptic on iOS completion
- Platform-appropriate via `#if os()`

### 6.3.4 Entry Card Animations
- Smooth mood emoji scale animation on selection in `MoodPicker`
- Entry card appear/disappear transitions in list (`.transition(.move(edge: .leading))`)
- Keep simple — no matched geometry (deferred per Codex: macOS NavigationSplitView incompatible)

**Files touched:** `KinenApp.swift`, `SettingsView.swift`, `InsightsScreen.swift`, `JournalListScreen.swift`, `MoodPicker.swift`, `Localizable.strings` (both)

**Gemini review checkpoint after this sprint.**

---

## Sprint 6.4 — Engagement & Retention

**Focus:** Features that reward consistent journaling.

### 6.4.1 Streaks 2.0
- Add "freeze" mechanism: allow 1 missed day without breaking streak
- Track longest-ever streak alongside current streak
- Centralize streak logic into new `StreakCalculator` utility (currently duplicated in `InsightsScreen`, `RecapGenerator`, `WidgetDataProvider`)
- Achievement milestones: 7, 30, 100, 365 days with badge icons
- Store milestones as comma-separated string in `@AppStorage("achievedMilestones")`

### 6.4.2 Weekly Recap Share Sheet
- Add `ShareLink` button to `RecapScreen`
- Use existing `RecapGenerator.formatForExport()` for share content
- Works with Messages, Mail, Notes, etc.
- Low risk — leverages existing formatter

### 6.4.3 "On This Day" Notifications
- If entries exist from exactly 1 year ago, send morning notification
- "1 year ago today, you wrote about..." with entry preview
- Configurable toggle in Settings (default: on)
- Uses existing `OnThisDayCard` data logic

### 6.4.4 Batch Delete Old Xcodeproj Files
- Clean up `Kinen 2~6.xcodeproj` (5 stale projects)
- Remove from git tracking
- Add to `.gitignore`

**Files touched:** `RecapScreen.swift`, `InsightsScreen.swift`, `WidgetDataProvider.swift`, `ReminderService.swift`, `SettingsView.swift`, new `StreakCalculator.swift`, `Localizable.strings` (both)

**Gemini review checkpoint after this sprint.**

---

## Deferred to Phase 7 (per Codex recommendation)

| Feature | Reason |
|---------|--------|
| **User-Created Templates** | Current `JournalTemplate` is an enum — needs new shared model + cross-target storage strategy. macOS lacks app-group entitlement. |
| **Focus Mode Integration** | iOS-only API (`INFocusStatusCenter`), no existing Intents/Focus wiring. Would break macOS builds without careful `#if` gating. |
| **Matched Geometry Transitions** | macOS uses `NavigationSplitView`, iOS uses tab/push — cross-platform matched geometry is high-risk for limited UX gain. |

---

## Implementation Rules

1. **Every sprint** must pass `xcodebuild build` for macOS before moving on
2. **Every sprint** must have Gemini Pro review via MCP bridge before proceeding
3. **All user-facing strings** must be localized in both EN and zh-Hans
4. **All new model properties** must have default values (CloudKit + lightweight migration compatibility)
5. **No force unwraps** — use guard let / optional chaining / nil coalescing
6. **Tests** for all new logic (not just UI)
7. **Accessibility labels** for all new interactive elements
8. **Version bump** to 0.3.0 after all sprints complete

---

## Summary

| Sprint | Theme | Key Features | Risk |
|--------|-------|-------------|------|
| 6.1 | Data Safety | Schema migration, backup validation, version history, tests | Medium (migration) |
| 6.2 | Smart Journaling | Mood suggestion, pinning UI, word goal, dedup | Low |
| 6.3 | Visual Polish | Dark mode toggle, stats cards, refresh, animations | Low |
| 6.4 | Engagement | Streaks 2.0, share recap, On This Day notifications, cleanup | Low |

**New localization keys (estimated):** ~45 (EN + zh-Hans)  
**New test cases (estimated):** ~25  
**New Swift files:** ~4 (StreakCalculator, 3 test files)  
**Risk level:** Low-Medium — schema changes batched in Sprint 6.1 with migration testing
