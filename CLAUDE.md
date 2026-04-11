# Kinen (記念) — AI Local Diary + Insights

## Project Overview
A privacy-first journaling app with on-device AI that analyzes mood trends, discovers life patterns, and provides personal insights. All data stays on the user's device.

## Tech Stack
- **Language:** Swift 6.0 + SwiftUI + SwiftData
- **Platforms:** macOS 15+, iOS 18+ (shared codebase)
- **AI:** Apple NaturalLanguage framework (sentiment/NER) + MLX (optional deep analysis)
- **Storage:** SwiftData (local + optional iCloud sync via CloudKit)
- **Build:** XcodeGen (project.yml)
- **Bundle ID:** com.jasonye.kinen
- **Team ID:** KHMK6Q3L3K

## Architecture
```
Sources/
  App/            — App entry point, multiplatform setup
  Models/         — SwiftData models (Entry, Mood, Tag, Insight)
  Features/
    Journal/      — Entry creation, editing, list
    Insights/     — Mood trends, heatmap, streaks, patterns
    AI/           — NL sentiment analysis, pattern detection, suggestions
    Settings/     — Preferences, export, privacy
  Views/
    Components/   — Reusable UI (MoodPicker, CalendarHeatmap, etc.)
    Screens/      — Main screens
Resources/        — Assets, Info.plist, Localizable
Tests/            — Unit + UI tests
```

## Conventions
- SwiftData for all persistence, no Core Data
- Swift concurrency (async/await) for AI processing
- Apple NaturalLanguage for lightweight sentiment (no model downloads needed)
- All AI runs on-device, zero network calls
- Prefer value types, use OSLog for logging
- Multiplatform: shared SwiftUI views with platform-specific adaptations via #if os()

## Commands
- Build: `xcodegen generate && open Kinen.xcodeproj`
- Test: `xcodegen generate && xcodebuild test -scheme Kinen -destination 'platform=macOS'`

## Phase 0 Scope (Mac + iOS)
Must have:
- [ ] Create/edit/delete journal entries with rich text
- [ ] Mood picker (emoji-based 5-level scale + custom moods)
- [ ] Auto sentiment analysis via NaturalLanguage
- [ ] Tag system (auto-suggested + manual)
- [ ] Calendar heatmap view (mood over time)
- [ ] Mood trend charts (weekly/monthly)
- [ ] Streak tracking (journaling consistency)
- [ ] Full-text search across entries
- [ ] Dark mode support
- [ ] Bilingual (EN/中文)

Must NOT have (Phase 1+):
- CloudKit sync
- Apple Watch
- Widgets
- MLX deep analysis
- Export/import
- Cross-platform (Android/Windows)
