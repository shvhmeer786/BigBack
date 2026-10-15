# Auth email templates

BigBack signs people in with a **6-digit code**, never a link. UW email runs on Microsoft 365, whose link
scanner (Safe Links) opens links in incoming mail before the student does, which can use up a one-time sign-in
link. A code can't be consumed that way.

| Supabase template (Auth → Emails → Templates) | Subject | Body |
|---|---|---|
| **Confirm sign up**: sent the first time an email signs in | `{{ .Token }} is your BigBack code` | `confirmation.html` |
| **Magic link**: sent to returning users | `{{ .Token }} is your BigBack code` | `magic_link.html` |

Both bodies contain `{{ .Token }}` and no `{{ .ConfirmationURL }}`, which makes Supabase send a code. The code in
the subject lets students read it straight from the notification. Keep the templates free of links and tracking
(turn off click and open tracking at the email provider) so they read as a plain security email.
