# Kinen — App Review Notes (Build 1.0/12)

> Replaces `appstore/review-notes-weatherkit.md`. Paste sections A–E into the
> "App Review Information → Notes" field in App Store Connect.

---

## A. WHAT'S NEW IN BUILD 12 vs BUILD 11

- New onboarding final page lets you populate the app with 30 realistic sample
  journal entries on first launch. This addresses the "populated content"
  feedback from the prior review by giving you a journal that exercises every
  screen (list, search, Calendar heatmap, Insights, Recap, Map, tag filters).
- Settings → "Sample Journal" lets you load or clear the same sample entries
  any time.
- Settings → Journal → "Test Apple WeatherKit" runs a one-tap live verification
  of the WeatherKit integration with Apple Weather attribution displayed on
  success.
- Settings → Privacy → tap the privacy row to open the new "Privacy Inspector"
  screen, which lists every external endpoint the app contacts and explicitly
  confirms no third-party AI service is used.
- Privacy policy at https://jasonyeyuhe.github.io/Kinen/privacy.html has been
  refreshed (2026-04-30) with an explicit on-device AI section.
- App Store description and subtitle have been updated to lead with
  "Private Journal with On-Device AI / Your thoughts stay on your device.
  No servers. No third-party AI."

## B. RECOMMENDED REVIEW PATH

1. Launch Kinen.
2. Walk through onboarding. On the final page, choose **Start with sample
   entries**. Onboarding completes and the Journal list shows 30 sample
   entries, ready to explore.
3. Tap any entry → see entry detail with mood, weather string, location, tags,
   and AI-generated insights (all derived on-device).
4. Switch to Insights → mood trend, streaks, and theme cards are populated.
5. Switch to Calendar → heatmap shows colored cells for the last 30 days.
6. Switch to Recap → last week's recap renders.
7. Switch to Map → 5 city clusters of geotagged entries (San Francisco, NYC,
   Tokyo, Seattle, Lisbon).

## C. VERIFYING APPLE WEATHERKIT (live, separate from sample data)

1. Open Settings → Journal.
2. Toggle **Auto-record location & weather** ON.
3. Approve the macOS Location prompt when it appears. (If your review machine
   has Location Services disabled in **System Settings → Privacy & Security →
   Location Services**, please enable them; the app cannot mock this.)
4. Tap **Test Apple WeatherKit**. The app calls Apple WeatherKit for the
   current coordinates and shows the live result with the Apple Weather logo
   and legal-attribution link.
5. Tap **Save as new entry** to insert a real journal entry populated with
   live WeatherKit data and Apple attribution.

**Important:** sample journal entries (from step B) display only a plain
string in the weather field — they do NOT show the Apple Weather attribution.
The Apple Weather attribution is shown ONLY for live WeatherKit responses, so
you can always tell whether weather data on a screen came from a live
WeatherKit fetch or from the sample loader.

## D. PRIVACY (guidelines 5.1.1(i), 5.1.2(i))

Kinen does **NOT** send user data to any third-party AI service. No data is
shared with OpenAI, Anthropic, Google Gemini, Hugging Face, Cohere, or any
other AI vendor.

All AI analysis — sentiment, topics, CBT patterns, themes, recaps — runs 100%
on-device using Apple's NaturalLanguage framework (`NLTagger` + `NLEmbedding`).
No model weights are downloaded; no inference servers are contacted.

Network entitlement is used SOLELY for:
- Apple WeatherKit
- Apple's reverse-geocoder (CoreLocation)
- Apple StoreKit purchases
- Opening external URLs (privacy policy, GitHub, crisis helplines) in the
  system browser

Verify in-app: Settings → Privacy → tap the privacy row to open the Privacy
Inspector. The screen lists every external endpoint and explicitly confirms
no third-party AI is used.

Verify in policy: https://jasonyeyuhe.github.io/Kinen/privacy.html, section 4
"AI processing (on-device only)".

## E. CRISIS / MENTAL HEALTH RESOURCES

Kinen is a journaling app, not a medical device. The CBT reflection feature
uses on-device pattern matching to surface common cognitive distortions;
results are advisory and labeled as such. A crisis-resource list is shown if
entry text contains explicit self-harm language; the list is region-aware
(US 988 Lifeline, UK Samaritans, Australia Lifeline, etc.). Onboarding
includes the medical disclaimer.

If anything is unclear, please reply to this submission and we will respond
same-day.

---

## Reviewer reply (paste into Resolution Center)

Hello,

Thank you for the detailed feedback. We have addressed both points in build
1.0 (12), now uploaded for review. Brief summary of what changed; full
step-by-step navigation is in the App Review Information notes for build 12.

────────────── Guideline 2.1(a) ──────────────

In build 11 the empty first-launch state made it hard to see Kinen's features
unless you typed entries by hand. Build 12 adds a final onboarding page where
you can choose to populate the journal with 30 realistic sample entries (or
start empty). The same option lives in Settings → "Sample Journal" so you can
reload or clear sample entries at any time.

The 30 sample entries exercise every screen — Journal list, Calendar heatmap,
Insights, Recap, Map (geotagged across 5 cities), tag filters — so you can
review the full app without needing to type your own data.

For the WeatherKit feature specifically, Settings → Journal now contains a
"Test Apple WeatherKit" button that runs a one-tap live verification, displays
the live result with Apple Weather attribution, and lets you save the result
as a journal entry. This path is separate from sample data and never falls
back to synthetic weather: if Location Services are off on the review device,
the button shows an explicit "enable Location Services" message rather than
fake content.

────────────── Guidelines 5.1.1(i) / 5.1.2(i) ──────────────

We want to clarify directly: Kinen does NOT use any third-party AI service.
No user data is sent to OpenAI, Anthropic, Google Gemini, Hugging Face,
Cohere, or any other AI vendor.

All AI features — sentiment scoring, topic extraction, CBT distortion
detection, mood themes, weekly recaps — run 100% on-device using Apple's
NaturalLanguage framework (NLTagger and NLEmbedding). No model weights are
downloaded; no inference servers are contacted. The app's network entitlement
is used solely for Apple WeatherKit, Apple's reverse-geocoder, Apple StoreKit,
and opening external URLs in the system browser.

Build 12 makes this verifiable two ways:

1. In-app: Settings → Privacy → tap the privacy row to open the new
   "Privacy Inspector" screen, which lists every external endpoint the app
   contacts and explicitly confirms no third-party AI service is used.

2. In the privacy policy at
   https://jasonyeyuhe.github.io/Kinen/privacy.html (updated 2026-04-30),
   section 4 "AI processing (on-device only)" names every framework used and
   the explicit absence of any third-party AI vendor.

The App Review Information notes for build 12 lead with the same statement so
it is the first thing reviewers see.

We confirm:
- The data Kinen handles is described in the privacy policy.
- No third-party AI service receives any user data.
- The app does not need additional consent flows for third-party AI sharing
  because no such sharing occurs.

If anything is unclear, please let us know and we will respond same-day.

Thank you,
Jason Ye
yyyyy.yeyuhe@gmail.com
