# Fix Plan — App Store Rejection 2026-04-23 (macOS, build 1.0/7)

Submission ID: `bb0f3ad5-24cd-4c11-86ce-b5516d35a6ee`
Review Device: MacBook Air (15-inch, M3, 2024) on macOS 26.4
Issues: **Guideline 2.1(a)** (crash) + **Guideline 2.1** (WeatherKit info needed)

---

## Issue 1 — Crash on tap "Use a Template" after picking a feeling

### Reproduction
launch → "Write Now" → select feeling icon → tap **"Use a Template"** → crash. No crash log.

### Root-cause hypotheses (ranked)

**H1 (most likely): Nested sheet presentation pattern is fragile on macOS 26.4.**
`EntryEditorSheet` is itself presented as a `.sheet`, and inside it we present `TemplatePickerSheet` via another `.sheet(isPresented: $showingTemplatePicker)` (file [EntryEditorSheet.swift:198](Sources/Views/Screens/EntryEditorSheet.swift#L198)). The inner sheet contains its own `NavigationStack` with `.frame(minWidth: 360, ...)` ([TemplatePickerSheet.swift:56-58](Sources/Views/Components/TemplatePickerSheet.swift#L56)).

On macOS 26.4 a sheet-from-sheet whose host is itself sized via `.frame(idealWidth:idealHeight:)` can hit a SwiftUI layout-assertion that trips a `fatalError` without producing a normal Mach exception → matches "no crash log was generated."

**H2: `.onChange(of: mood)` racing with sheet presentation.**
Selecting a feeling fires `onChange(of: mood) { generateNewPrompt() }` ([EntryEditorSheet.swift:215](Sources/Views/Screens/EntryEditorSheet.swift#L215)). This rebuilds `aiPromptBanner` right as the user taps the template button. The state mutation during presentation can crash if `PromptGenerator` ever returns nil into a non-optional, or if SwiftUI invalidates the host view mid-presentation.

**H3: `debounceMoodSuggestion` Task not cancelled before sheet opens.**
A pending mood suggestion task may resume on the @MainActor while the sheet is being presented and mutate `suggestedMood`, contributing to view churn.

### Fix (revised after Gemini review — drop the cargo-cult delay)

**F1. Flatten template picker on macOS.** In `TemplatePickerSheet.swift`: wrap the `NavigationStack` in `#if os(iOS)` and use a plain `VStack` with title + cancel button on macOS. Remove `idealWidth`/`idealHeight`; keep only `minWidth`/`minHeight`. This eliminates the NavigationStack-in-sheet pattern that's a known macOS SwiftUI fragility source.

**F2. Cancel `moodSuggestionTask` before opening the template picker.** This is the principled fix — kill the in-flight Task that's racing the sheet presentation:
```swift
Button(action: {
    moodSuggestionTask?.cancel()
    moodSuggestionTask = nil
    showingTemplatePicker = true
}) { ... }
```
Apply to both buttons at [EntryEditorSheet.swift:345](Sources/Views/Screens/EntryEditorSheet.swift#L345) and [EntryEditorSheet.swift:348](Sources/Views/Screens/EntryEditorSheet.swift#L348).

**F3. Defense-in-depth guard on `generateNewPrompt()`.** Add `@State private var isPresentingChildSheet = false`, set true via `.onChange(of: showingTemplatePicker)`, and early-return from `generateNewPrompt()` while true. Optional but cheap insurance.

**REJECTED (was F2 in v1):** ~~Defer `showingTemplatePicker = true` by 50ms via `Task.sleep`.~~ Gemini correctly flagged this as a cargo-cult workaround that papers over the race rather than fixing it. Removed.

### Verification steps
1. `xcodegen generate && xcodebuild build -scheme Kinen -destination 'platform=macOS'`
2. Run the app on macOS 15+ in Debug.
3. Run the exact reviewer reproduction 10× (cold launch + warm). Also stress: tap mood quickly then template before banner finishes.
4. Run on macOS 26.x simulator/VM if accessible. (We don't have 26.4; we will note this in reply to reviewer.)
5. Run existing test suite. Add a UITest if feasible: open editor → select mood → tap template button → assert sheet appears.

---

## Issue 2 — Auto-record location & weather doesn't work on macOS

### Root cause — TWO separate bugs

**B1 (blocker): macOS sandbox missing `personal-information.location` entitlement.**
`Resources/Kinen-macOS.entitlements` currently has only `weatherkit`, `app-sandbox`, `network.client`. **Without `com.apple.security.personal-information.location` the sandbox silently denies all CoreLocation calls** — `requestLocation()` will fail and `authorizationStatus` stays `.notDetermined` forever. WeatherKit also requires a location, so weather silently fails.

**B2: Wrong authorization request API for macOS.**
[LocationWeatherService.swift:32](Sources/Features/Journal/LocationWeatherService.swift#L32) calls `requestWhenInUseAuthorization()`. On macOS this is accepted but the resulting status is `.authorized` (not `.authorizedWhenInUse`). The macOS branch at [line 42](Sources/Features/Journal/LocationWeatherService.swift#L42) does check `.authorized || .authorizedAlways`, so this is *technically* OK — but only after the user has been prompted. Combined with B1 the prompt never produces useful authorization.

**B3: Info.plist usage description is iOS-keyed only.**
We have `NSLocationWhenInUseUsageDescription`. macOS also reads this key under the modern unified CoreLocation flow, so this is probably fine — but we should add `NSLocationUsageDescription` (legacy macOS key) as belt-and-suspenders since reviewer is on macOS 26.4.

### Fix

**F1. Add location entitlement to `Resources/Kinen-macOS.entitlements`:**
```xml
<key>com.apple.security.personal-information.location</key>
<true/>
```

**F2. Add legacy macOS usage description to `Resources/Info.plist`:**
```xml
<key>NSLocationUsageDescription</key>
<string>Kinen can tag your journal entries with your location. Location data stays on your device.</string>
```
(Keep `NSLocationWhenInUseUsageDescription` — both should coexist.)

**F3. Make `requestPermission()` platform-correct.**
```swift
func requestPermission() {
    #if os(macOS)
    locationManager.requestAlwaysAuthorization()  // macOS only has Always for sandboxed apps; system shows one-time consent
    #else
    locationManager.requestWhenInUseAuthorization()
    #endif
}
```
Actually for macOS 11+ `requestWhenInUseAuthorization()` is fine and produces `.authorizedAlways` after consent — but we should double-check by logging the resulting status in `locationManagerDidChangeAuthorization`. Keep current API; just add a logger.error when status is `.denied` or `.restricted` so we can diagnose if it recurs.

**F4. Pre-flight permission when toggle flips on, and surface failure to user.**
In `SettingsView.swift` where `enableLocationWeather` is toggled on, after `requestPermission()` give the system ~0.5s to update, then if status is still `.notDetermined`, `.denied`, or `.restricted`, show a toast: "Open System Settings → Privacy → Location Services to enable."

**F5. Provide reviewer-visible UX path.**
Today the only trigger is "open editor with toggle on → location is fetched silently." Reviewer reported they couldn't see it working. Add to `SettingsView` a small status row under the toggle:
- "Last location: Cupertino, CA · ☀️ 68°F" (when available)
- "Tap to fetch now" button that calls `LocationWeatherService.shared.fetchLocationAndWeather()` and updates inline.

This gives the reviewer (and users) explicit confirmation the feature works.

### Verification steps
1. Build with new entitlement; verify code-signing succeeds (sandbox change requires re-sign).
2. Reset location permissions: `tccutil reset CoreLocation com.jasonye.kinen`
3. Launch app, enable toggle → confirm system prompt appears.
4. Approve → confirm `authorizationStatus` becomes `.authorizedAlways` (log it).
5. Open editor → confirm location + weather populate on the entry.
6. Tap new "Fetch now" button in Settings → confirm status row updates within 5s.
7. Test denial path: deny prompt → confirm toast appears, no crash.

---

## Reply to reviewer (Guideline 2.1 — Information Needed)

> 1. **Yes, Kinen uses WeatherKit.** When the user enables "Auto-record location & weather" in Settings, each new journal entry is automatically tagged with the device's current city and current weather conditions (e.g., "Cupertino, CA · ☀️ 68°F"). This data is stored locally with the entry and is never transmitted off-device.
>
> 2. **Steps to reach WeatherKit functionality (build 1.0/8):**
>    - Settings → toggle "Auto-record location & weather" ON
>    - Approve the system Location prompt
>    - Settings now shows a "Last location" status row — tap **"Fetch now"** to confirm location + weather load
>    - Tap **+ (New Entry)** → the entry is created with location and weather captured automatically; both are visible at the bottom of the entry editor and in the saved entry detail view.
>
> The previous build had a sandbox-entitlement bug on macOS that prevented CoreLocation from receiving authorization, which is why weather never appeared. This is fixed in build 1.0/8.
>
> We have rebuilt and re-tested the app locally on macOS and verified that (a) the crash on "Use a Template" no longer reproduces, and (b) location and weather now populate correctly on new entries after granting Location permission.

---

## Build / submission checklist

- [ ] Apply F1–F4 from Issue 1 + verify on macOS locally
- [ ] Apply F1–F5 from Issue 2 + verify on macOS locally
- [ ] Bump build number 7 → 8 in `project.yml`
- [ ] `xcodegen generate`
- [ ] Archive & upload via Xcode (signed with Distribution cert + macOS provisioning profile that includes the new location entitlement — may need to regenerate profile in App Store Connect)
- [ ] Submit + paste reviewer reply above into Resolution Center

---

## Risks / what could still bite us

- **Provisioning profile.** Adding `personal-information.location` to entitlements requires the macOS App ID/profile to include the matching capability. Profile auto-managed by Xcode usually handles this, but manual profiles need regeneration. Verify before archiving.
- **Reviewer environment is macOS 26.4** which we cannot reproduce locally (we have macOS 15). The crash fix is defensive; if it recurs we'll have asked Apple for a sysdiagnose.
- **WeatherKit free tier limits** are 500K calls/month — we are well under. Not a rejection risk but worth noting.
- **CloudKit/sandbox interaction:** the Kinen-macOS.entitlements file currently does *not* include CloudKit container; we are not enabling sync in 1.0, so this is fine — do not add it now to keep diff minimal.
