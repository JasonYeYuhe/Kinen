# Kinen v1.0 (build 9) — App Store Rejection Fix Plan

**Submission ID:** f5b499dd-6398-403b-99db-7617d8d091cf
**Review date:** 2026-04-24
**Platform:** macOS 26.4 (MacBook Pro 14" Nov 2024)
**Previously rejected build:** 1.0 (8)

---

## Apple Review Feedback (verbatim)

### Guideline 2.1(a) — Performance (crash)
> The app crashed on Mac running macOS 26.4 when we:
> 1. Launched the app
> 2. Clicked on "Write Now"
> 3. Clicked on the microphone icon
> 4. Enabled microphone
> 5. App crashed. No crash log was generated.

### Guideline 5.2.5 — Apple Weather attribution
> The app displays Apple weather data but does not include the required Apple Weather attribution. Apps that support WeatherKit must clearly display the Apple Weather trademark (Weather) and legal source link (https://weatherkit.apple.com/legal-attribution.html).

---

## Root cause #1 — missing macOS sandbox microphone entitlement

**File:** `Resources/Kinen-macOS.entitlements`

Current entitlements for the macOS target:
```
com.apple.developer.weatherkit = true
com.apple.security.app-sandbox = true
com.apple.security.network.client = true
com.apple.security.personal-information.location = true
```

**Missing:** `com.apple.security.device.audio-input`

For a hardened-runtime + sandboxed macOS app, `NSMicrophoneUsageDescription` in Info.plist is necessary but not sufficient. The sandbox additionally requires `com.apple.security.device.audio-input` (the modern macOS entitlement key for microphone access; `com.apple.security.device.microphone` is the legacy alias and both work, but audio-input is the canonical one). Without it:

1. The system permission prompt may still appear (because the usage-description string is present)
2. After the user clicks "OK", `AVAudioEngine.inputNode` sandbox-checks and the process is killed with SIGKILL
3. SIGKILL from the sandbox produces **no crash log** — exactly matching the reviewer's observation ("No crash log was generated")

This is the canonical "silent crash right after mic permission grant" on sandboxed macOS apps. It repros only on first-time permission grant because on subsequent runs the system caches the denial and the engine never starts.

**Why build 8 wasn't caught locally:** The developer's machine had already granted microphone permission out-of-sandbox (likely during an ad-hoc `xcodebuild run` before the entitlement was finalized), so the cached TCC grant masked the missing entitlement. Apple's reviewer hit the first-grant path.

## Root cause #2 — WeatherKit attribution absent

Weather string is displayed in two places:
- [Sources/Views/Screens/EntryDetailScreen.swift:47](Sources/Views/Screens/EntryDetailScreen.swift:47) — `MetadataBadge(icon: "cloud.sun.fill", text: weather, ...)`
- [Sources/Views/Screens/SettingsView.swift:513](Sources/Views/Screens/SettingsView.swift:513) — `"\(loc) · \(weather)"` in location status text

Neither shows the "Weather" trademark nor the required link to https://weatherkit.apple.com/legal-attribution.html. This is a clear 5.2.5 violation.

---

## Fix design

### Fix 1 — macOS microphone entitlement

**Edit `Resources/Kinen-macOS.entitlements`:** add
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

**Edit `project.yml` macOS target entitlements properties (line 44–50):** add
```yaml
com.apple.security.device.audio-input: true
```

so subsequent `xcodegen generate` runs keep the file in sync.

### Fix 2 — macOS pre-flight + defensive guard in VoiceRecorderButton

Even with the entitlement added, we harden `beginRecordingSession()` on macOS so any residual edge case (no input device, user revoked mid-session) degrades gracefully instead of crashing. The iOS branch already has belt-and-suspenders checks (availableInputs, currentRoute, sampleRate). On macOS we add equivalent checks using `AVCaptureDevice` (sandbox-safe on macOS with the audio-input entitlement):

```swift
#if os(macOS)
guard AVCaptureDevice.default(for: .audio) != nil else {
    errorMessage = String(localized: "voice.error.noInputDevice")
    return
}
// AVCaptureDevice.authorizationStatus(for: .audio) must be .authorized
let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
if authStatus == .notDetermined {
    let granted = await AVCaptureDevice.requestAccess(for: .audio)
    guard granted else { showPermissionAlert = true; return }
} else if authStatus != .authorized {
    showPermissionAlert = true
    return
}
#endif
```

**Placement:** this block belongs in `startRecording()` (not `beginRecordingSession()`) — it mirrors the iOS mic-permission block that was previously `#if os(iOS)`-only. On macOS, `SFSpeechRecognizer.requestAuthorization` alone does not trigger the mic permission prompt; we need `AVCaptureDevice.requestAccess(for: .audio)` to surface the system dialog.

The existing ObjC exception catcher around `engine.inputNode` stays — it's the last line of defense.

### Fix 3 — Apple Weather attribution UI

Create a new reusable view `Sources/Views/Components/WeatherAttribution.swift`:

```swift
struct WeatherAttribution: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "apple.logo") // Apple logo + "Weather" wordmark
            Text("Weather")
                .font(.caption2)
            Link("Legal", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .accessibilityLabel("Apple Weather attribution")
    }
}
```

**Apple guidance nuance:** Apple's WeatherKit attribution doc (§ "Display the Apple Weather trademark") requires:
- The exact wordmark " Weather" (Apple logo + word "Weather") — we use SF Symbol `apple.logo` to render the logo glyph, which is allowed by the HIG for attribution contexts
- A visible hyperlink whose destination is `https://weatherkit.apple.com/legal-attribution.html`. Apple calls this the "legal link" — its visible label doesn't have to be the full URL; "Legal" / "Other data sources" is acceptable per the doc

Display in both places weather is shown:
- `SettingsView` location-status section (after the status text, line ~513)
- `EntryDetailScreen` metadata row (beneath the weather badge, line ~50)

Embed only when weather is actually displayed — if `entry.weather == nil` we omit the attribution (Apple's rule is "when Weather data is shown").

### Fix 4 — build number bump

- `project.yml` → `CURRENT_PROJECT_VERSION: "9"` (was "8")
- MARKETING_VERSION stays "1.0"

### Fix 5 — regression tests

Add a minimal unit test that asserts the `Kinen-macOS.entitlements` file contains `com.apple.security.device.audio-input` — guards against future regressions.

```swift
func testMacOSEntitlementsIncludeAudioInput() throws {
    let url = Bundle.main.url(forResource: "Kinen-macOS", withExtension: "entitlements")
    // ... parse plist, assert key present
}
```

Actually — the entitlements file isn't bundled at runtime. Better: the test reads it from the repo via `#file` path resolution. Low priority — the main guard is project.yml being the source of truth.

---

## Verification plan

1. `xcodegen generate` → confirm project.xcodeproj regenerated with new entitlement
2. `xcodebuild build -scheme Kinen -destination 'platform=macOS'` → clean build
3. `xcodebuild test -scheme Kinen -destination 'platform=macOS'` → all tests pass
4. **Manual repro in a fresh VM / after `tccutil reset Microphone com.jasonye.kinen`:**
   - Launch app
   - Click "Write Now"
   - Click mic icon
   - System prompt appears → click "OK"
   - Confirm recording starts (pulse animation on stop button) — **no crash**
5. **Manual WeatherKit check:**
   - Grant location
   - Open an entry with weather data
   - Verify " Weather — Legal" row visible, link opens weatherkit.apple.com/legal-attribution.html in browser
6. `xcodebuild -exportArchive` → sign with Developer ID, upload via `altool` / `xcrun notarytool` (actually for App Store: upload via `xcrun altool --upload-app` or Transporter)
7. In App Store Connect: select build 9, fill "what's new" with both fixes, resubmit

## "What to tell Apple" note (ASC resubmit message)

> Build 9 fixes both issues in submission f5b499dd:
>
> 1. **2.1(a) mic crash:** The sandbox was missing `com.apple.security.device.audio-input`. With the entitlement present, the mic prompt now grants correctly and recording starts without crashing. We additionally added `AVCaptureDevice`-based pre-flight checks on macOS so a missing/removed input device surfaces a user-visible error instead of terminating the app.
>
> 2. **5.2.5 WeatherKit attribution:** Every place that displays weather data (entry detail view, settings location status) now shows the Apple Weather wordmark and a link to https://weatherkit.apple.com/legal-attribution.html.

---

## Risk assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Entitlement added but Xcode caches old signing profile → reviewer sees same crash | Low | Bump build number to 9; clean build folder; `xcodegen generate` from scratch |
| `AVCaptureDevice.requestAccess` doesn't surface the standard mic prompt under hardened runtime | Very low — this is the documented macOS API | If the prompt doesn't appear, `authorizationStatus` check still gates entry, so no crash |
| WeatherKit attribution placement conflicts with existing layout | Low | Attribution is a one-line HStack; fits in existing VStack |
| New mic-permission code path breaks iOS flow | Medium | iOS path is wrapped in its own `#if os(iOS)`; macOS path is additive, not replacing |

---

## Out of scope (not addressing in this build)

- Visual polish on WeatherKit attribution — minimal viable is enough for 5.2.5 compliance
- Refactoring VoiceRecorderButton into an MVVM separation — works, don't touch
- Adding CloudKit / Watch / Widget fixes — separate review gates
