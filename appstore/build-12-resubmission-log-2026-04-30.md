# Build 12 Resubmission Log — 2026-04-30

Submission ID being resolved: `f5b499dd-6398-403b-99db-7617d8d091cf` (macOS rejection 2026-04-29)

## Apple's stated rejection reasons (2026-04-29)

1. **Guideline 2.1(a)** — populated content for review (could not access app features, especially WeatherKit)
2. **Guideline 5.1.1(i) / 5.1.2(i)** — suspected user data shared with a third-party AI service

Ground truth: app uses **zero** third-party AI services. All on-device via Apple NaturalLanguage. Reviewer's privacy concern was a misperception driven by description metadata heavy with "AI" wording but the on-device qualifier buried.

## Plan & review

- Plan: [appstore/fix-plan-2026-04-29-rejection.md](fix-plan-2026-04-29-rejection.md)
- Reviewed by: Codex (codex-rescue agent) + Gemini 3.1 Pro — both critiques incorporated into v2 of the plan before any code was written.

## Implementation summary (Build 12)

| Sprint | Output | Commit |
|--------|--------|--------|
| A — Sample Journal | `JournalEntry.isSampleData` + `SampleDataLoader` (30 realistic entries, 5 cities, 6 weather strings, all 8 templates) + onboarding final page + Settings → Sample Journal section + 9 unit tests | `01d8cf7` |
| B — Test Apple WeatherKit | Settings → Journal → "Test Apple WeatherKit" row with live verification path. Apple Weather attribution shown ONLY on real WeatherKit responses, never on samples. | `01d8cf7` |
| C — Privacy Inspector | New `PrivacyInspectorScreen` with explicit "no third-party AI" enumeration. Settings privacy row converted to NavigationLink. Onboarding privacy page strengthened. `docs/privacy.html` Section 4 rewritten. | `01d8cf7` |
| D — Privacy manifest | `Resources/PrivacyInfo.xcprivacy` + `NSPrivacyAccessedAPICategoryDiskSpace E174.1`. Verified Apple's privacy-manifest schema does NOT include a CoreLocation category (Gemini's recommendation overruled — location is governed by purpose strings + entitlement, not the manifest). | `01d8cf7` |
| E — App Store metadata | `appstore/description-en.txt` + `description-zh.txt`: subtitle moved to "Your thoughts stay on your device. No servers. No third-party AI." as the first line. New `appstore/review-notes-2026-04-29.md` for ASC review-notes field + reviewer reply. | `01d8cf7` |

Build number 11 → 12, no new entitlements, no schema migration risk.

Verified locally: macOS BUILD SUCCEEDED, iOS BUILD SUCCEEDED, **524 tests pass**, 9 of which are new SampleDataLoader tests.

## Deployment timeline (2026-04-30)

| Time (JST) | Action | Result |
|------------|--------|--------|
| 15:33 | xcodebuild test (macOS) | 524 pass / 0 fail |
| 15:42 | `git commit 01d8cf7` (15 files: +1989 / -36) | committed |
| 15:43 | `git push origin main` | privacy.html refreshed on jasonyeyuhe.github.io |
| 16:27 | `xcodebuild archive` (macOS, Build 12) | succeeded |
| 16:31 | `xcodebuild -exportArchive` (macOS upload to ASC) | Upload succeeded |
| 16:30 | `xcodebuild archive` (iOS, Build 12, with `-allowProvisioningUpdates` to refresh stale WeatherKit profile) | succeeded |
| 16:41 | `xcodebuild -exportArchive` (iOS upload to ASC) | Upload succeeded |
| 16:43 | ASC macOS Version 1.0 → set Promotional Text + Description + App Review Notes (via Chrome MCP + JS) | Saved (✓) |
| 16:45 | ASC App Information → set Subtitle "Private journal · on-device AI" | Saved (✓) |
| 16:48 | ASC iOS Version 1.0 → set same metadata | Saved (✓) |
| 16:51 | ASC macOS Resolution Center → reviewer reply (2909 chars) | Reply sent |
| 16:55 | ASC session expired (Chrome MCP login required for next step) | — |
| 17:33 | Jason re-login + select Build 12 + click Resubmit (iOS + macOS) | **Waiting for Review** |

## Status

Build 1.0 (12) is now in Apple's review queue for both iOS and macOS.
Apple's typical first-pass response: 24–48 hours.

When the result comes back:
- **Approved (best case):** release will auto-publish (Automatically release this version is selected per macOS Version page).
- **Rejected:** new message will arrive in Resolution Center for `f5b499dd-6398-403b-99db-7617d8d091cf` (macOS) and the iOS submission. Re-engage from `appstore/fix-plan-2026-04-29-rejection.md` workflow.

## Field values written to ASC (for the record)

**Subtitle (App Information):**
> Private journal · on-device AI

**Promotional Text (both platforms):**
> Your thoughts stay on your device. No servers. No third-party AI. Mood analysis, CBT reflections, and pattern discovery — all on-device.

**Description first 4 lines (both platforms):**
> Kinen — Private Journal with On-Device AI
>
> Your thoughts stay on your device. No servers. No third-party AI.
>
> Kinen is a privacy-first journaling app with on-device AI that analyzes your mood, detects thought patterns, and helps you reflect deeper — without sending a single byte to any server.

**App Review Notes:** see `appstore/review-notes-2026-04-29.md` Section A–E (3742 chars; pasted to both iOS and macOS).

**Reviewer reply (Resolution Center, macOS submission `f5b499dd-...`):** sent via Chrome MCP at 2026-04-30 16:51 JST. Full text in `appstore/review-notes-2026-04-29.md` under "## Reviewer reply".

## Files of record

- Plan: `appstore/fix-plan-2026-04-29-rejection.md`
- Notes: `appstore/review-notes-2026-04-29.md`
- This log: `appstore/build-12-resubmission-log-2026-04-30.md`
- Code commit: `01d8cf7`
- Local archives: `build/Kinen-macOS.xcarchive`, `build/Kinen-iOS.xcarchive`
- Privacy policy live at: <https://jasonyeyuhe.github.io/Kinen/privacy.html> (Last updated 2026-04-30)
