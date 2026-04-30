# Fix Plan v2 — App Store Rejection 2026-04-29 (Kinen 1.0 / Build 11)

Submission ID: `f5b499dd-6398-403b-99db-7617d8d091cf`
Review date: 2026-04-29
Review device: MacBook Air (15-inch, M3, 2024)
Issues:
- **Guideline 2.1(a)** — Information Needed (no populated content for review)
- **Guideline 5.1.1(i) / 5.1.2(i)** — Privacy / data sent to third-party AI service

> **Author:** Claude (full authority per user). **Reviewed by Codex and Gemini 3.1 Pro on 2026-04-30.**
> **v2 changes** (post-review): killed production "demo" buttons; separated sample data from WeatherKit verification; added `isSampleData: Bool` field; updated PrivacyInfo.xcprivacy; realistic sample content; rewrote reviewer reply.

---

## 1. Deep audit — what the reviewer actually saw

### 1.1 Issue A: 2.1(a) "populated demo mode" / WeatherKit access
Reviewer quote: *"we need a populated demo mode that shows real content on all pages for us to review your app content and features, such as WeatherKit application in app's services."*

**Root cause:**
1. First-launch is empty. `JournalListScreen` shows empty-state CTA only ("Tap + to write your first journal entry"). Reviewer has nothing to look at.
2. WeatherKit is gated behind 4 sequential user steps (Settings toggle → location prompt → Fetch now button → create entry), each of which can fail silently on a reviewer machine where Location Services are off at the OS level.
3. Map / Insights / Recap each have their own empty-states; none of them render meaningfully without ≥7 entries spread over a week.

**Conclusion:** the app needs (a) realistic sample content available on first launch and (b) a WeatherKit verification path that either succeeds live or fails gracefully — never a fake fallback that a reviewer might mistake for a faked WeatherKit response.

### 1.2 Issue B: 5.1.1(i) / 5.1.2(i) "third-party AI service"
**Codebase audit confirms:** zero third-party AI vendors. All AI uses `NaturalLanguage.NLTagger` ([SentimentAnalyzer.swift:2](Sources/Features/AI/SentimentAnalyzer.swift#L2), [SemanticSearch.swift:2](Sources/Features/AI/SemanticSearch.swift#L2)) and deterministic Swift pattern matching ([CBTReflection.swift:4](Sources/Features/AI/CBTReflection.swift#L4)). Network entitlement is used only for Apple WeatherKit, Apple's reverse-geocoder, Apple StoreKit, and opening external URLs in the system browser.

**Why the reviewer concluded otherwise:**
1. App Store description leads with "AI Journal" and uses "AI" 7 times in the headline before "on-device" appears in paragraph 2 ([description-en.txt:1, :10](appstore/description-en.txt)).
2. Reviewer could not reach the in-app onboarding `aiPage` or the Settings `"settings.ai.local"` caption because of issue A.
3. Privacy row in `SettingsView` is static text, not a navigation link ([SettingsView.swift:273](Sources/Views/Screens/SettingsView.swift#L273)) — there's no in-app artifact a reviewer can tap to verify the privacy claim.
4. Previous App Review Notes addressed only WeatherKit, never third-party AI.

---

## 2. Strategy

| Issue | Approach |
|-------|----------|
| 2.1(a) — populated content | **Onboarding choice:** add a final onboarding screen offering *"Start with sample journal"* vs *"Start empty"*. Sample option seeds 30 days of realistic entries with weather strings, locations, mood, tags, insights. Treats this as a normal product feature, not a "demo mode". Also exposed in Settings → Sample Journal section for users who skipped onboarding. |
| 2.1(a) — WeatherKit | **Separate path.** Add a "Test Apple WeatherKit" row in Settings → Journal section. Tapping it requests location permission if needed, calls `WeatherService.shared.weather(for:)`, and either (a) shows the live result with Apple Weather attribution + offers to insert into a new entry, or (b) shows an explicit failure message with the reason ("Location Services are off in System Settings", "Permission denied", etc.). **Never** falls back to fake data. |
| 5.1.1(i) / 5.1.2(i) | (a) Reply to reviewer in Resolution Center, helpful tone, both rejections covered, explicit Build 12 vs 11 diff. (b) Update App Review Notes in ASC. (c) Add a **Privacy Inspector** screen accessible from Settings → Privacy (NavigationLink). (d) Update App Store description headline + subtitle. (e) Add "Privacy" link from onboarding privacy page to the Inspector. |

**Build number:** 11 → 12. **Marketing version stays 1.0.** Zero new entitlements.

---

## 3. Implementation plan

### Sprint A — Sample Journal (renamed from "Demo Mode")

#### A.1 Schema change: add `isSampleData: Bool = false` to `JournalEntry`

```swift
// Sources/Models/JournalEntry.swift
var isSampleData: Bool = false
```
Default value satisfies SwiftData lightweight migration. Used as the single source of truth for "this entry came from the sample data loader." Avoids the failed `__sample` tag approach (which the v1 plan falsely claimed was hidden — it would have appeared in `EntryDetailScreen` tag rows).

If CloudKit sync is enabled in a future build, the sync predicate will exclude `isSampleData == true` (notes for v1.1 — out of scope here, since `cloudKitDatabase: .none` today per [KinenApp.swift:41](Sources/App/KinenApp.swift#L41)).

#### A.2 New file `Sources/Features/Settings/SampleDataLoader.swift`

```swift
@MainActor
struct SampleDataLoader {
    /// Inserts ≈30 days of realistic synthetic entries. Idempotent: if any
    /// `isSampleData == true` entry exists, returns 0.
    static func loadSampleEntries(into context: ModelContext) -> Int

    /// Removes every entry where `isSampleData == true` and any tags/insights
    /// that became orphaned. Real user entries are untouched.
    static func clearSampleEntries(from context: ModelContext) -> Int

    /// Returns the count of `isSampleData == true` entries currently in the context.
    static func sampleEntryCount(in context: ModelContext) -> Int
}
```

**Sample entries: realistic, feature-rich content** (per Gemini critique):
- 30 entries spread over the last 30 days, with 4 days deliberately skipped to make streak insights non-trivial
- `content`: 80–280 word entries in EN with markdown formatting (bold, lists, headings) — no lorem ipsum, no "This is a sample" copy. Topics rotate across realistic journaling territory: gratitude, work-stress reflection, exercise, family check-in, creative project progress, sleep quality, travel anecdote, CBT three-column on a real-feeling situation
- `mood`: weighted distribution (10× great, 12× good, 5× neutral, 2× bad, 1× terrible) so insights screen shows a realistic positive-skewed mood trend
- `weather`: rotated through 6 strings with emoji + temperature ("☀️ Sunny, 72°F", "⛅️ Partly Cloudy, 65°F", "🌧 Light Rain, 55°F", "❄️ Light Snow, 28°F", "🌫 Foggy, 60°F", "🌤 Mostly Sunny, 68°F"). **Stored as plain string in `JournalEntry.weather`** — this field is just a label, no claim of provenance. Apple Weather attribution is shown ONLY by `WeatherAttributionView` which is rendered ONLY for live WeatherKit responses (live `weatherAttribution` non-nil) — never for sample entries.
- `location` + `latitude`/`longitude`: rotated through 5 cities with real coordinates (San Francisco 37.7749/-122.4194, Tokyo 35.6762/139.6503, NYC 40.7128/-74.0060, Seattle 47.6062/-122.3321, Lisbon 38.7223/-9.1393) so the Map screen has 5 visible clusters
- `tags`: each entry gets 2–4 tags from a vocabulary of 12 (`work`, `family`, `gratitude`, `morning`, `evening`, `exercise`, `creative`, `reflection`, `travel`, `sleep`, `goals`, `mindfulness`). Tags are real auto-generated `Tag` rows so `TagManagementSheet` and the filter bar show usable data.
- `insights`: each entry gets 1–2 `EntryInsight` rows (`type: .sentiment` or `.topicExtraction` or `.pattern` — using only the cases that exist in `InsightType` per [EntryInsight.swift:21](Sources/Models/EntryInsight.swift#L21)) with realistic localized text drawn from existing `Localizable.strings` keys (`"ai.insight.positive"`, `"ai.insight.topics"`, etc.) so they're consistent with what the user would see from real entries
- `template`: variety using existing `JournalTemplate` cases (`.cbtThreeColumn` for the CBT entry, `.gratitude`, `.dailyReview`, `.freeWrite`, `.morningPages`, `.weeklyReview`)
- `wordCount`: computed from content
- `writingDuration`: 90–600 seconds (varied)
- `isPinned`: 1 entry pinned (exercises the pinned section UI)
- `isBookmarked`: 3 entries bookmarked (exercises the filter bar bookmark toggle)
- `isSampleData`: **all** sample entries `true`
- `photoData`: nil (cannot ship copyrighted photos; binary size matters)
- `audioFilename`: nil

EN-only sample text in v1.0. zh-Hans variants deferred to v1.1 (documented decision, not an oversight).

#### A.3 Onboarding entry point — replaces production "Demo" buttons (per Codex + Gemini)

Add a new final onboarding page `samplePage` after `disclaimerPage`:

```
Header: "Start with a sample journal?"
Body:   "Want to see what Kinen looks like with a few weeks of entries?
         We'll add 30 sample journal entries so you can explore Insights,
         the Calendar heatmap, the Map view, and Recap.
         You can clear sample entries any time in Settings → Sample Journal."

Buttons:
  • "Start with sample entries"  → SampleDataLoader.loadSampleEntries; hasSeenOnboarding=true
  • "Start empty"                → hasSeenOnboarding=true
```

Both buttons feel like normal first-run choices, not test/dev features. Wording deliberately uses neutral product language ("sample journal", "explore"). No "demo", "review", "test", "developer" anywhere user-facing.

`OnboardingView`'s tab count goes from 5 to 6 (welcome → privacy → ai → sync → disclaimer → sample). The `disclaimerPage` "I Understand" button becomes "Continue" and advances to the sample page instead of finishing onboarding.

#### A.4 Settings entry point — for users who skip onboarding or run a fresh build

Replace plan v1's "Sample Data (for review & demo)" section title with **`settings.sample.section.title` = "Sample Journal"**.

Layout:
```
Section "Sample Journal"
  ┌ if sampleCount > 0:
  │   ┌ Row: "30 sample entries are loaded"   (caption: gray)
  │   └ Button: "Clear sample journal"        (destructive)
  └ else:
      ┌ Button: "Load sample journal (30 entries)"
      └ Caption: "Adds 30 sample entries so you can explore Kinen's
                 features. Real entries you create stay separate. You
                 can clear sample entries any time."
```

**iCloud guard.** Today CloudKit is disabled at storage layer (`cloudKitDatabase: .none` in [KinenApp.swift:41](Sources/App/KinenApp.swift#L41)) so sample entries cannot sync. The `iCloudSyncEnabled` toggle in Settings is currently a UI-only flag that does nothing on disk (it gates the onboarding text). **No iCloud guard is needed for v1.0.** When CloudKit is wired in v1.1, the sync predicate will filter `isSampleData == false`. Documented in code comment.

#### A.5 No hidden launch argument

Per Codex review item #5, the `-LoadSampleData` argument from plan v1 is dropped. The two real entry points (onboarding final page + Settings) cover all real cases; the launch argument was a workaround for a problem we don't have. Adding it to App Review Notes would invite suspicion of a review-only path.

#### A.6 Tests `Tests/SampleDataLoaderTests.swift`

- `testLoadInsertsThirtyEntries` — count == 30
- `testLoadIsIdempotent` — second call returns 0 inserted
- `testClearRemovesOnlySampleEntries` — pre-existing real entry survives, sample count goes to 0
- `testSampleEntriesHaveRequiredFields` — every sample has mood, weather, location, latitude+longitude, ≥2 tags, ≥1 insight, isSampleData==true
- `testSampleEntriesUseExistingInsightTypes` — every insight's `type` is a member of `InsightType` (compile-checked but explicit assertion catches refactor drift)
- `testSampleDataCountAfterPartialDelete` — delete one sample entry, sampleEntryCount drops by 1
- `testRealEntryHasIsSampleDataFalse` — `JournalEntry(content:)` initialiser returns `isSampleData == false`

### Sprint B — WeatherKit verification (separate path)

**Why:** Codex review item #1: bundling sample-weather strings with a "Test WeatherKit" button is the biggest 2.1(a) risk because Apple cannot tell whether weather data shown is real or fake. Separate the two surfaces completely.

#### B.1 Settings → Journal section, add row "Test Apple WeatherKit" (separate from sample journal)

```swift
Button("Test Apple WeatherKit") {
    Task { await testWeatherKit() }
}
.disabled(testingWeatherKit)
```

`testWeatherKit()` semantics:
1. If `enableLocationWeather == false`: prompt user to enable it first (open the toggle).
2. If location authorization is `.notDetermined`: call `requestPermission()`. Wait up to 5s.
3. If status becomes `.denied` or `.restricted`: show inline error: *"Location Services are off or denied. Open System Settings → Privacy & Security → Location Services to enable, then retry."* (Provide a button to open System Settings on macOS.)
4. If authorized: call `LocationWeatherService.shared.fetchLocationAndWeather()`. On success, show an inline result panel with: live city, live weather string, **WeatherAttributionView with the live `weatherAttribution` object** (Apple Weather logo + legal link). Offer a "Save as new entry" button that creates a journal entry with the live weather data.
5. On WeatherKit error: show explicit error text: *"WeatherKit fetch failed. Reason: [error]"*. Do **not** insert a fallback string.

This makes the button a real WeatherKit verifier — it never lies about the source of the data. If it can't run, it says so honestly with a path to fix it.

#### B.2 No fallback weather injection anywhere

The plan v1 idea of "if location unavailable, insert an entry with hard-coded Cupertino weather and pretend the WeatherKit attribution UI works" is killed. Apple Weather attribution will only render when the live `WeatherAttribution` object is present (existing logic in [WeatherAttributionView.swift:33-51](Sources/Views/Components/WeatherAttributionView.swift#L33)). Sample journal entries display only their plain `weather` string with no attribution — they look like a string label, not a WeatherKit response.

### Sprint C — Privacy Inspector + disclosure hardening

#### C.1 New file `Sources/Views/Screens/PrivacyInspectorScreen.swift`

Content (localized EN + zh-Hans, key prefix `privacy.inspector.*`):

```
Where your data goes

✓ Journal text, mood, tags, insights
   Stored on this device only (Apple SwiftData).
   Apple iCloud (CloudKit) ONLY if you toggle iCloud Sync ON.
   Never sent to any other server.

✓ AI analysis (sentiment, topics, CBT patterns, themes)
   100% on-device, using Apple's NaturalLanguage framework
   (NLTagger) and Apple's NLEmbedding for semantic similarity.
   Zero network calls. Zero model downloads.
   No third-party AI service is used (no OpenAI, no Anthropic,
   no Google Gemini, no Hugging Face, no Cohere, no other vendor).

✓ Location (only if "Auto-record location & weather" is ON)
   Apple CoreLocation gets your GPS fix on this device.
   Apple's reverse-geocoder turns it into a city name (one
   network call to Apple's geocoder).
   Stored locally with the entry.

✓ Weather (only if "Auto-record location & weather" is ON)
   Apple WeatherKit, querying your current coordinates.
   One network call per new entry to Apple. No third party.

✓ HealthKit (only if you grant permission in Settings)
   Read-only access on this device. Never written, never sent.

✓ App Store purchases
   StoreKit (Apple). No payment data ever passes through us.

What we never do

✗ Send your journal text to a server
✗ Use third-party AI services (OpenAI, Anthropic, Gemini, etc.)
✗ Show ads
✗ Run analytics SDKs (no Firebase, no Sentry, no Mixpanel)
✗ Track you across other apps

[Read the full Privacy Policy →]    (Link to docs/privacy.html)
```

#### C.2 Hook up Settings privacy row as a NavigationLink

[SettingsView.swift:273-286](Sources/Views/Screens/SettingsView.swift#L273) currently shows the privacy summary as static text. Replace with a NavigationLink to `PrivacyInspectorScreen`. Visible from any Settings screen.

#### C.3 Onboarding privacy page strengthening

Replace existing description copy with a list-style version that names what is and isn't done. Add a "Privacy details →" link under the description that opens `PrivacyInspectorScreen`. The privacy onboarding page becomes the second guaranteed surface that mentions "no third-party AI" — reviewer cannot miss it.

#### C.4 Privacy policy refresh (`docs/privacy.html`)

- Bump "Last updated" to 2026-04-30.
- Add a new top-level section **"4. AI processing (on-device only)"** with explicit framework list (NLTagger, NLEmbedding) and an explicit statement: *"Kinen does not integrate with any third-party AI service. We do not use OpenAI, Anthropic, Google Gemini, Hugging Face, Cohere, or any other AI vendor. The app's network entitlement is used solely for Apple WeatherKit, Apple's reverse-geocoder, and Apple StoreKit."*
- Commit + push to gh-pages branch before resubmission so the live URL serves the new copy.

#### C.5 App Store description rewrite (EN + zh-Hans)

Move the privacy claim to the headline. New first lines:

```
Kinen — Private Journal with On-Device AI
Your thoughts stay on your device. No servers. No third-party AI.
```

Keep all existing marketing benefits in the body. Update both `appstore/description-en.txt` and `appstore/description-zh.txt`.

### Sprint D — PrivacyInfo.xcprivacy update (per Gemini #2)

Current `Resources/PrivacyInfo.xcprivacy` declares:
- UserDefaults (CA92.1)
- File timestamp (C617.1)

Both are correct. **Missing:** location API category. WeatherKit + CoreLocation usage requires:

```xml
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>CA92.1</string></array>
</dict>
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>C617.1</string></array>
</dict>
<!-- NEW: -->
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>E174.1</string></array>
</dict>
```

**Note on location:** Apple's privacy manifest API category list (as of 2024 v1) does NOT include CoreLocation as an accessed-API category — location is governed by purpose-strings (`NSLocationWhenInUseUsageDescription`) and the `personal-information.location` entitlement, not the privacy manifest. Gemini's recommendation to add `NSPrivacyAccessedAPICategoryLocation` and code `C86F.1` is incorrect — these don't exist in Apple's published manifest spec. **Verified:** privacy manifest covers UserDefaults / file timestamp / disk space / system boot time / active keyboards. Location is declared via `Info.plist` purpose strings + entitlement, both already present.

**Action:** add only `NSPrivacyAccessedAPICategoryDiskSpace / E174.1` (BackupService writes to disk and reads file size) which is genuinely missing today. Do NOT invent a non-existent location category.

### Sprint E — Build, App Review Notes, reviewer reply

#### E.1 `project.yml`: bump `CURRENT_PROJECT_VERSION` 11 → 12

#### E.2 Build & test

```
xcodegen generate
xcodebuild build -scheme Kinen -destination 'platform=macOS'
xcodebuild test -scheme Kinen -destination 'platform=macOS'
```

#### E.3 New file `appstore/review-notes-2026-04-29.md`

Replaces `appstore/review-notes-weatherkit.md`. Tone: helpful and concrete (per Gemini #5). Content separates sample-data path from WeatherKit verification path so the reviewer cannot conflate them.

```
KINEN APP REVIEW NOTES — Build 1.0 (12)

A. WHAT'S NEW IN BUILD 12 vs BUILD 11

  • New onboarding final page lets you populate the app with 30
    realistic sample journal entries on first launch. This addresses
    the "populated content" feedback from the prior review by giving
    you a journal that exercises every screen (list, search,
    Calendar heatmap, Insights, Recap, Map, tag filters).
  • Settings → "Sample Journal" lets you load or clear the same
    sample entries any time.
  • Settings → Journal → "Test Apple WeatherKit" runs a one-tap
    live verification of the WeatherKit integration with Apple
    Weather attribution displayed on success.
  • Settings → Privacy → tap the privacy row to open the new
    "Privacy Inspector" screen, which lists every external endpoint
    the app contacts and explicitly confirms no third-party AI
    service is used.
  • Privacy policy at jasonyeyuhe.github.io/Kinen/privacy.html has
    been refreshed (2026-04-30) with an explicit on-device AI
    section.

B. RECOMMENDED REVIEW PATH

  1. Launch Kinen.
  2. Walk through onboarding. On the final page, choose
     "Start with sample entries". Onboarding completes and the
     Journal list shows 30 sample entries, ready to explore.
  3. Tap any entry → see entry detail with mood, weather string,
     location, tags, and AI-generated insights (all derived
     on-device).
  4. Switch to Insights → mood trend, streaks, and theme cards
     are populated.
  5. Switch to Calendar → heatmap shows colored cells for the
     last 30 days.
  6. Switch to Recap → last week's recap renders.
  7. Switch to Map → 5 city clusters of geotagged entries.

C. VERIFYING APPLE WEATHERKIT (live, separate from sample data)

  1. Open Settings → Journal.
  2. Toggle "Auto-record location & weather" ON.
  3. Approve the macOS Location prompt when it appears.
     (If your review machine has Location Services disabled in
      System Settings → Privacy & Security → Location Services,
      please enable them; the app cannot mock this.)
  4. Tap "Test Apple WeatherKit". The app calls Apple WeatherKit
     for the current coordinates and shows the live result with
     the Apple Weather logo and legal-attribution link.
  5. Tap "Save as new entry" to insert a real journal entry
     populated with live WeatherKit data and Apple attribution.

  IMPORTANT: sample journal entries (from step B) display only a
  plain string in the weather field — they do NOT show the Apple
  Weather attribution. The Apple Weather attribution is shown ONLY
  for live WeatherKit responses, so you can always tell whether
  weather data on a screen came from a live WeatherKit fetch or
  from the sample loader.

D. PRIVACY (guidelines 5.1.1(i), 5.1.2(i))

  Kinen does NOT send user data to any third-party AI service.
  No data is shared with OpenAI, Anthropic, Google Gemini,
  Hugging Face, Cohere, or any other AI vendor.

  All AI analysis — sentiment, topics, CBT patterns, themes,
  recaps — runs 100% on-device using Apple's NaturalLanguage
  framework (NLTagger + NLEmbedding). No model weights are
  downloaded; no inference servers are contacted.

  Network entitlement is used SOLELY for:
    • Apple WeatherKit
    • Apple's reverse-geocoder (CoreLocation)
    • Apple StoreKit purchases
    • Opening external URLs (privacy policy, GitHub, crisis
      helplines) in the system browser

  Verify in-app: Settings → Privacy → tap the privacy row to open
  the Privacy Inspector. The screen lists every external endpoint
  and explicitly confirms no third-party AI is used.

  Verify in policy: jasonyeyuhe.github.io/Kinen/privacy.html,
  section 4 "AI processing (on-device only)".

E. CRISIS / MENTAL HEALTH RESOURCES

  Kinen is a journaling app, not a medical device. The CBT
  reflection feature uses on-device pattern matching to surface
  common cognitive distortions; results are advisory and labeled
  as such. A crisis-resource list is shown if entry text contains
  explicit self-harm language; the list is region-aware (US 988
  Lifeline, UK Samaritans, Australia Lifeline, etc.). Onboarding
  includes the medical disclaimer.

If anything is unclear, please reply to this submission and we
will respond same-day.
```

#### E.4 Reviewer reply (paste into Resolution Center)

```
Hello,

Thank you for the detailed feedback. We have addressed both
points in build 1.0 (12), now uploaded for review. Brief summary
of what changed; full step-by-step navigation is in the App
Review Information notes for build 12.

────────────── Guideline 2.1(a) ──────────────

In build 11 the empty first-launch state made it hard to see
Kinen's features unless you typed entries by hand. Build 12 adds
a final onboarding page where you can choose to populate the
journal with 30 realistic sample entries (or start empty). The
same option lives in Settings → "Sample Journal" so you can
reload or clear sample entries at any time.

The 30 sample entries exercise every screen — Journal list,
Calendar heatmap, Insights, Recap, Map (geotagged across 5
cities), tag filters — so you can review the full app without
needing to type your own data.

For the WeatherKit feature specifically, Settings → Journal now
contains a "Test Apple WeatherKit" button that runs a one-tap
live verification, displays the live result with Apple Weather
attribution, and lets you save the result as a journal entry.
This path is separate from sample data and never falls back to
synthetic weather: if Location Services are off on the review
device, the button shows an explicit "enable Location Services"
message rather than fake content.

────────────── Guidelines 5.1.1(i) / 5.1.2(i) ──────────────

We want to clarify directly: Kinen does NOT use any third-party
AI service. No user data is sent to OpenAI, Anthropic, Google
Gemini, Hugging Face, Cohere, or any other AI vendor.

All AI features — sentiment scoring, topic extraction, CBT
distortion detection, mood themes, weekly recaps — run 100%
on-device using Apple's NaturalLanguage framework (NLTagger and
NLEmbedding). No model weights are downloaded; no inference
servers are contacted. The app's network entitlement is used
solely for Apple WeatherKit, Apple's reverse-geocoder, Apple
StoreKit, and opening external URLs in the system browser.

Build 12 makes this verifiable two ways:

  1. In-app: Settings → Privacy → tap the privacy row to open the
     new "Privacy Inspector" screen, which lists every external
     endpoint the app contacts and explicitly confirms no third-
     party AI service is used.

  2. In the privacy policy at
     https://jasonyeyuhe.github.io/Kinen/privacy.html (updated
     2026-04-30), section 4 "AI processing (on-device only)"
     names every framework used and the explicit absence of any
     third-party AI vendor.

The App Review Information notes for build 12 lead with the same
statement so it is the first thing reviewers see.

We confirm:
  ✓ The data Kinen handles is described in the privacy policy.
  ✓ No third-party AI service receives any user data.
  ✓ The app does not need additional consent flows for third-
    party AI sharing because no such sharing occurs.

If anything is unclear, please let us know and we will respond
same-day.

Thank you,
Jason Ye
yyyyy.yeyuhe@gmail.com
```

### Sprint F — Local verification

| Step | Expected |
|------|----------|
| Cold launch (no prior data) | Onboarding plays through 6 pages, last page offers Sample / Empty |
| Choose "Start with sample entries" | 30 entries appear; insights/recap/calendar/map all populated |
| Open Settings → Sample Journal | Shows "30 sample entries are loaded" + "Clear" button |
| Tap Clear | Entries removed; section flips to "Load sample journal" |
| Cold launch + choose "Start empty" | List shows the existing empty-state CTA, no sample data anywhere |
| Settings → Privacy → tap privacy row | Privacy Inspector renders with all 6 sections |
| Settings → Journal → Test Apple WeatherKit (location off) | Inline error: "Location Services are off..." with Open System Settings button |
| Settings → Journal → Test Apple WeatherKit (location granted) | Inline result with live city + weather + Apple Weather attribution + "Save as new entry" |
| Save as new entry | New journal entry inserted with live weather + visible Apple Weather attribution in entry detail |
| Existing real entry | Untouched by sample-load and sample-clear |
| `xcodebuild test -scheme Kinen -destination 'platform=macOS'` | All existing tests + new SampleDataLoader tests pass |
| `scripts/verify-entitlements.sh --source` | macOS entitlements unchanged |
| Light/dark + EN/zh-Hans | Privacy Inspector and onboarding sample page render correctly in both |

---

## 4. Files to be touched

**New (4):**
- `Sources/Features/Settings/SampleDataLoader.swift`
- `Sources/Views/Screens/PrivacyInspectorScreen.swift`
- `Tests/SampleDataLoaderTests.swift`
- `appstore/review-notes-2026-04-29.md` (replaces `review-notes-weatherkit.md`)

**Edited (≈11):**
- `project.yml` (build 11 → 12)
- `Sources/Models/JournalEntry.swift` (add `isSampleData: Bool = false`)
- `Sources/Views/Screens/OnboardingView.swift` (add 6th sample page; strengthen privacy page copy + link to Inspector)
- `Sources/Views/Screens/SettingsView.swift` (Sample Journal section; Test Apple WeatherKit row; Privacy NavigationLink to Inspector)
- `Sources/Features/Journal/LocationWeatherService.swift` (no functional change; small public helper for explicit error reporting if needed by Test button)
- `Resources/PrivacyInfo.xcprivacy` (add disk-space API E174.1)
- `Resources/en.lproj/Localizable.strings` (~50 new keys)
- `Resources/zh-Hans.lproj/Localizable.strings` (~50 new keys)
- `docs/privacy.html` (date + AI section + third-party disclaimer)
- `appstore/description-en.txt` (subtitle + reordered first paragraph)
- `appstore/description-zh.txt` (subtitle + reordered first paragraph)

**Untouched (deliberately):**
- All entitlements files (no new capabilities)
- Sources/Features/AI/* (zero behavior change required for either rejection)
- WeatherKit integration (correct on the user side; the Test button is purely UI)

---

## 5. Risks & mitigations (v2)

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Reviewer ignores onboarding sample option and rejects again on 2.1(a) | Low | Same option in Settings → "Sample Journal"; App Review Notes lead with "Choose Start with sample entries" instruction |
| Apple flags "Sample Journal" as a developer/test feature (2.5) | Low | Wording is product-neutral, accessible to all users, idempotent, fully clearable. No "demo", "review", "test", "developer" anywhere. |
| Reviewer mistakes sample weather string for live WeatherKit data | Very low | Sample entries display plain string only; Apple Weather attribution renders ONLY for live WeatherKit responses. Reviewer reply explicitly explains this. |
| Test Apple WeatherKit still fails on reviewer machine | Medium | Failure path shows explicit, actionable error and "Open System Settings" button. App is honest: reviewer cannot blame the app for system-level Location being off. |
| Schema migration | None | New field has default value; SwiftData lightweight migration. |
| Adding `isSampleData` breaks existing tests | Low | Default false; existing initialiser unchanged. Run full test suite before submission. |
| New SampleDataLoader tests slow the suite | None | 30 inserts in an in-memory container; <0.5s. |
| Privacy manifest update rejected | None | Adding only the legitimate disk-space API; UserDefaults + file-timestamp entries unchanged. |
| Reviewer reply tone too defensive | Low | v2 reply is helpful, concrete, leads with what changed. |
| ASC description change triggers metadata re-review | Low | Subtitle and first paragraph only — both factual statements about the product. Existing keywords / categories / age rating unchanged. |

---

## 6. Implementation order (final)

1. **Sprint A** — schema field + SampleDataLoader + onboarding page + Settings section + tests
2. **Sprint B** — Test Apple WeatherKit button (separate from samples)
3. **Sprint C** — Privacy Inspector + onboarding privacy strengthening + privacy.html + ASC description
4. **Sprint D** — PrivacyInfo.xcprivacy
5. **Sprint E** — build 12 + new App Review Notes + reviewer reply text
6. **Sprint F** — local verification matrix (xcodegen + xcodebuild test + manual smoke test)
7. **User-driven submission** — Jason archives, uploads via Xcode, pastes ASC review notes + reviewer reply, submits

I will execute steps 1–6. Step 7 is for Jason because it requires Xcode UI + ASC web UI.

---

*End of plan v2. Reviewed by Codex + Gemini, both critiques incorporated. Implementation starts now.*
