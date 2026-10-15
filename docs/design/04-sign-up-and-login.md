# Sign up, log in and email verification

_Added 2026-10-15. Prototype: the first screens of `prototype/Main.dc.html`. Log out and Delete account are in You._

## Decisions
- **One flow for sign-up and log-in: an emailed 6-digit code.** No passwords for students. Typing the code
  proves the student owns the `@uwaterloo.ca` address, so it *is* the email verification.
- **A code, never a link.** UW mail runs on Microsoft 365, whose Safe Links scanner opens links in incoming mail
  before the student does, which can use up a one-time sign-in link. A typed code can't be consumed that way.
- **UW-only at sign-up**, enforced on the server by `hook_before_user_created`, which rejects any other domain.
  The app also checks the domain as you type, for an instant message.
- **Passwords exist only for test and App Review accounts** (`signup_allowlist`), behind "Use a password instead"
  on the log-in screen.
- **No Sign in with Apple, Google, etc.** They can't prove UW enrolment, and with no third-party login,
  guideline 4.8 doesn't require Sign in with Apple.

## Screens
| # | Screen | What happens |
|---|---|---|
| 1 | **Welcome** | Wordmark, "Where Waterloo eats.", a playful stack of meal cards. **Sign up with your UW email** (primary) · **I have an account · Log in** · "For University of Waterloo students." |
| 2 | **Email** | "What's your UW email?" (sign-up) or "Welcome back" (log-in). One field, `textContentType(.emailAddress)`. **Send code**. Privacy Policy link. On log-in only: "Use a password instead". |
| 3 | **Code** | "Check your email": 6 boxes with `textContentType(.oneTimeCode)`, so iOS offers the code from Mail above the keyboard. Verifies automatically on the 6th digit. **Open Mail**, "Send a new code" after a 30 s countdown, "Wrong email? Change it". |
| 4 | **Make it yours** (new accounts only) | Optional photo (PhotosPicker, no library permission); name and username prefilled from the email; live username check; a **terms checkbox** (required). **Continue** stays grey until all three are valid. |
| 5 | **Find your people** (new accounts only) | Suggested UW students with Follow buttons; optional "Find friends from contacts" (hashed, never stored). **Done** or **Skip for now**. |

Returning users go from step 3 straight into the app. A user who signed up but never finished step 4 (no
`onboarded_at`) is sent back to step 4 on next launch. Permissions (location, notifications, camera) are asked
later, in context, never during sign-up.

### Messages
| Situation | Copy |
|---|---|
| Empty email | "Enter your UW email to continue." |
| Not an email | "That doesn't look like an email address." |
| Not UW (client check, or the server hook's 403) | "BigBack is only for UW students right now. Use your @uwaterloo.ca email." |
| Wrong or expired code | "That code didn't work. Check your latest email, or send a new code." |
| Too many requests (Auth rate limit, 429) | "Too many tries. Wait a minute and try again." |
| Username taken | "@maya is taken. Try another." |
| Username format | "3–24 letters, numbers, _ or ." |
| Offline | "You're offline. We'll send the code when you're back." |

Error text uses the accessible system red (#D70015) with an icon, so colour is never the only signal.

## How it talks to the backend
```swift
// Step 2: send the code (creates the account on first use; the server hook rejects non-UW emails)
try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: mode == .signUp)

// Step 3: verify. A session comes back; the Supabase SDK stores it in the Keychain
try await supabase.auth.verifyOTP(email: email, token: code, type: .email)

// Step 4: username check while typing (debounced 300 ms), then save everything in one call
try await supabase.rpc("is_handle_available", params: ["p_handle": handle]).execute()
try await supabase.rpc("complete_onboarding",
  params: ["p_display_name": name, "p_handle": handle, "p_terms_version": "2026-10"]).execute()

// Log-in with a password (allowlisted test / App Review accounts only)
try await supabase.auth.signIn(email: email, password: password)
```
- **Log-in mode** passes `shouldCreateUser: false`, so a typo on the log-in screen doesn't create an account.
- **Sessions:** the access token refreshes automatically; the refresh token lives in the Keychain. Log out calls
  `auth.signOut()` and clears local caches (SwiftData, image cache, upload queue).
- **Terms changes:** when `terms_version` in `app_config` is newer than the profile's, the app shows the new terms
  once and calls `accept_terms`.
- **Delete account** (Settings → Delete account, 2 taps plus a confirm) calls the `delete-account` Edge Function.

## Email delivery (needed before real students can sign up)
Supabase's built-in email sender is for testing only. It delivers **only to members of your Supabase team** and
just a few emails an hour. Real sign-ups need a **custom SMTP provider**, which needs a **domain you own** (to prove
the emails are really from BigBack).

**Recommended:** Resend. It's simple to set up, has a Supabase integration and a free tier that covers testing,
and costs about $20 a month at launch volume (check current pricing). Postmark (excellent deliverability for this
kind of security email) and Amazon SES (cheapest at scale, more setup) are good alternatives.

### Setup steps
1. **Buy the domain** (see the architecture doc, decision 7).
2. **Add it in Resend.** Use a sending subdomain such as `mail.<domain>` and add the DNS records Resend shows:
   SPF (TXT), DKIM (TXT) and a DMARC record (`_dmarc` TXT, start with `p=none`). These records are what keep the
   codes out of UW's junk folder.
3. **Turn off open and click tracking** in Resend. It rewrites links and adds pixels, which security filters dislike.
4. **Supabase → Auth → Emails → SMTP settings** (or the Resend integration):

   | Setting | Value |
   |---|---|
   | Host / port | `smtp.resend.com` / `465` |
   | Username | `resend` |
   | Password | a Resend API key, entered in the dashboard only, never in the repo |
   | Sender | `BigBack <codes@mail.<domain>>` |
5. **Supabase → Auth → Emails → Templates:** paste `supabase/templates/confirmation.html` into **Confirm sign
   up** and `supabase/templates/magic_link.html` into **Magic link**. The subject for both is
   `{{ .Token }} is your BigBack code`.
6. **Supabase → Auth → Providers → Email:** Email enabled · Confirm email **on** · Email OTP length **6** · Email OTP
   expiration **600** seconds (10 minutes) · Secure email change **on**.
7. **Supabase → Auth → Rate limits:** raise "emails sent per hour" from 30 to about 200 for launch week. Keep the
   per-user OTP limits as they are.
8. **Supabase → Auth → Hooks:** enable **Before User Created** → `public.hook_before_user_created` (UW-only).
9. **Test with a real `@uwaterloo.ca` inbox:** confirm the email lands in the Inbox (not Junk), shows the code in the
   notification, and that iOS offers it above the keyboard.

## App Store notes
- **Guideline 1.2 (user-generated content):** sign-up requires agreeing to Terms of Use that say there is no
  tolerance for objectionable content or abusive users. The checkbox is stored as `terms_accepted_at` and
  `terms_version`.
- **Guideline 2.1 (reviewer access):** App Review can't receive a UW email. The demo account signs in with
  "Use a password instead". Credentials and a one-line explanation go in the review notes.
- **Guideline 5.1.1(v):** Delete account is in You → Account.
- **Privacy:** the email is used only to sign in and confirm enrolment. Contacts are optional and hashed. No
  tracking, so no ATT prompt.
