# ios/: the BigBack iPhone app

SwiftUI, iOS 18+, Swift 6. The Xcode project is generated from `project.yml` with XcodeGen, so it never
conflicts in Git.

## Run it on your Mac
1. Install Xcode (latest) from the Mac App Store, then `brew install xcodegen`.
2. `cd ios && xcodegen generate && open BigBack.xcodeproj`
3. Pick an iPhone simulator and press Run. To run on your own iPhone, set your Team in Signing & Capabilities.
   A free Apple ID works for a few days at a time; the paid developer account removes that limit.

## Layout
| Path | What |
|---|---|
| `BigBack/App` | App entry, composition root (`AppEnvironment`), root switch, tabs, You → Account |
| `BigBack/Resources` | Asset catalog (accent colour, placeholder icon), `PrivacyInfo.xcprivacy` |
| `Config/` | `Supabase.xcconfig` (URL + publishable key), `App.xcconfig` (legal pages base URL) |
| `Packages/BigBackKit` | `BigBackCore` (rules, service protocols) · `DesignSystem` (tokens, components) · `BigBackData` (Supabase) · `Onboarding` (sign-up and log-in) |

Features depend on `BigBackCore` protocols and `DesignSystem`, never on Supabase directly (architecture doc §2.2).

## What works today
- **Sign up / log in:** Welcome, then UW email, then the 6-digit code (iOS offers it from Mail). Then "Make it
  yours" for new accounts: name, live username check, required terms checkbox.
- **Four-tab shell:** Feed · Tonight · Activity · You, with placeholders for the screens still to build.
- **You → Account:** Log out, and Delete account (calls the `delete-account` Edge Function).

Real sign-up emails need custom SMTP first (docs/design/04-sign-up-and-login.md). Until then, Supabase only emails
members of the Supabase team.

## CI
`.github/workflows/ios.yml` runs on every push that touches `ios/`. It runs the `BigBackKit` tests on an iPhone
simulator, then builds the app.

## Before the first TestFlight build
- Confirm the bundle ID (`app.bigback.ios` in `project.yml`). It can't change once the app exists in App Store Connect.
- Set `DEVELOPMENT_TEAM`, and `LEGAL_BASE_URL` in `Config/App.xcconfig`, to the real domain.
- Replace the placeholder app icon.
