# App Store Readiness

_Owner direction (2026-10-15): every decision must support getting BigBack accepted on the App Store.
This maps the App Review Guidelines that apply to a social, user-generated-content, location-aware
camera app onto our design. Re-check against the live guidelines before submitting: Apple updates them
every year._

## Rejection risks we've designed out

| Risk | Guideline | Our answer | Status |
|---|---|---|---|
| **Reviewer can't log in.** Sign-up is limited to @uwaterloo.ca by email code | 2.1 App Completeness: demo account required | `signup_allowlist` lets a reviewer email sign up and sign in **with a password**. Credentials go in the App Review notes. The demo account is flagged `is_demo` and kept out of stats | DB done; add a "Use password" sign-in option for allowlisted accounts in the app |
| **Reviewer sees an empty app.** They're in Cupertino, far from Waterloo, with no friends | 2.1 / 4.2 Minimum Functionality | The demo account's school is UW. Tonight uses the user's real location (students rank anywhere: home, co-op, trips). Only when we have nothing near them does it fall back to the campus centre, with a banner ("Nothing rated near you yet · Showing Waterloo") and a button to switch back. The demo account follows 3–5 seeded demo users with real posts at real Waterloo places | Seed demo content once places are imported |
| UGC without moderation | 1.2 User-Generated Content | Report (post, comment, profile, place) → `reports` table + moderation queue; Block (`blocks`, hides everything both ways); filtering of objectionable text in comments and captions; published contact info in the app and on the support page | DB done; build the report/block UI and a basic word filter; set up a moderation inbox |
| No account deletion | 5.1.1(v) | Settings → Delete account → the `delete-account` Edge Function removes Storage files and the auth user, cascading to all data | Edge Function to build |
| Permissions without clear purpose | 5.1.1 | Pre-permission explainer screens in context, plus specific `Info.plist` purpose strings (camera, microphone for clips, location when-in-use, optional Always, photo library add-only, contacts optional) | Copy in the design system §10 |
| Requiring permissions to use the app | 5.1.1(iv) | Everything works without location, contacts, notifications or photos access. The camera is needed only to snap; library import is the alternative | By design |
| Contacts used beyond finding friends | 5.1.2 | Contacts are optional, hashed on device, matched server-side, and never stored or messaged | Build as specified |
| Tracking without ATT | 5.1.2 / App Tracking Transparency | No IDFA, no ad SDKs, no cross-app tracking. Analytics are first-party (PostHog, no tracking), so no ATT prompt is needed. The privacy label must match | Keep it that way |
| Privacy label mismatch | 5.1.1 / App Privacy | The privacy "nutrition label" must list: email (account), photos (UGC), coarse location (app functionality, not linked to tracking), user content, identifiers (user ID), diagnostics (Sentry) | Fill in App Store Connect |
| Missing privacy manifest | Required-reason APIs | `PrivacyInfo.xcprivacy` in the app and extensions, declaring required-reason APIs (UserDefaults, file timestamps, system boot time, disk space) and the data collected. Also the SDK manifests (Sentry, PostHog, Supabase) | Add when creating the project |
| Sign in with Apple | 4.8 Login Services | Only required if we add third-party logins (Google, etc.). Email OTP alone doesn't require it. If social logins are ever added, add Sign in with Apple at the same time | Noted |
| Location "Always" | 5.1.1, 2.5.4 | Always is optional, asked only after the user opts into arrival nudges, explained in context; the app works fully with When-in-use. No background location mode beyond region monitoring | By design |
| Background modes misuse | 2.5.4 | Only what's needed: background `URLSession` uploads (no special mode), remote notifications, Live Activities | By design |
| Objectionable name or copy | 1.1 | "BigBack" humour stays about appetite, never body shaming. Metadata and screenshots avoid it too | Copy guidelines in the design system §10 |
| Using competitors' names | 2.3.7 / 5.2 | No "Beli", "BeReal", "Partiful" or similar in metadata, keywords or screenshots | Noted |
| Third-party content (maps, reviews) | 5.2.2 | MapKit attribution stays visible. External reviews are links only (Google/Yelp). We never display their content we aren't licensed to use. Open-data attribution (Foursquare/Overture/OSM) is shown in About → Data sources | By design |
| AI feature content | 1.1 / 5.1.2 | Ask BigBack returns only real places from our database. The prompt is user text sent to Anthropic, and the privacy policy discloses that | Disclose in the policy |
| Age rating | Age ratings | UGC + social → choose the rating Apple's questionnaire produces (likely 13+ or higher with user-generated content and messaging). School emails imply 16+ in practice | Answer the questionnaire honestly |
| Incomplete features at review | 2.1 | Ship with fast-follow features hidden behind `app_config` flags, never "coming soon" buttons | Flags exist in `app_config` |
| Live Activities misuse | HIG / 2.5 | Only for a real ongoing meal; ends on its own after 3 h; no advertising | By design |
| Push notifications required | 4.5.4 | Notifications are optional; no marketing pushes without opt-in | By design |
| Reservations through third parties | 5.2.2 | Deep links to OpenTable/Resy only (their own apps and sites). No scraping or unofficial APIs | By design |

## Submission checklist
- [ ] Privacy policy URL (public web page) and support URL with a contact email.
- [ ] App Privacy questionnaire matches what the app actually collects (see above).
- [ ] `PrivacyInfo.xcprivacy` for the app and every extension; third-party SDK manifests present.
- [ ] Demo account in review notes, plus a one-paragraph explanation:
  - "Campus-only social food app. Sign up needs a school email; use this demo account."
  - "Location outside Waterloo shows Waterloo content."
- [ ] Screenshots from real app screens (no misleading mockups), in every required device size.
- [ ] Built with the current Xcode / iOS SDK Apple requires for new submissions; tested on the oldest supported iOS (18) and the latest.
- [ ] Report and Block reachable from every post, comment and profile.
- [ ] Delete account reachable in Settings within 2 taps.
- [ ] Every permission requested in context with a purpose string; the app works if each one is denied.
- [ ] Dark Mode, Dynamic Type and VoiceOver pass on the core flows.
- [ ] No placeholder content, no "beta" wording, no dead buttons.
- [ ] TestFlight external beta with real UW students before submitting (the external beta also goes through a short review, which is a useful early check).
