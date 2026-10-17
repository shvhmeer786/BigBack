# web/: BigBack's public pages

Static pages for the domain. App Store Connect needs two of them: a **Privacy Policy URL** and a **Support URL**.

| Page | Use |
|---|---|
| `index.html` | Landing page |
| `privacy.html` | Privacy Policy. App Store Connect → App Privacy → Privacy Policy URL |
| `terms.html` | Terms of Use. Linked from the sign-up terms checkbox; includes the terms Apple requires in a custom EULA |
| `guidelines.html` | Community Guidelines (zero tolerance, 24-hour report review, as guideline 1.2 requires) |
| `support.html` | Support URL: contact, code-not-arriving help, delete account, safety |

## Before publishing
1. **Have a lawyer review** `privacy.html` and `terms.html`. They're drafts written to match how BigBack actually
   works (Canadian privacy law, US data storage, App Store requirements), but they aren't legal advice.
2. Replace every `[bracketed]` placeholder:
   - operator name and mailing address;
   - support email;
   - privacy officer;
   - effective date;
   - email, crash and analytics providers;
   - retention periods.
3. Check the UW Campus Special Constable Service number on `guidelines.html` and `support.html`.
4. Remove the yellow "Draft" notice at the top of each page once it's final.
5. Keep the version (`2026-10`) in sync with `terms_version`, which the app sends to `complete_onboarding`. When the
   terms change, bump both, and the app asks everyone to accept again.

## Hosting (free)
Any static host works. The simplest is **Cloudflare Pages** (free, works with a private repo):
1. Pages → Create → connect the GitHub repo.
2. Build command: none. Output directory: `web`.
3. Add the custom domain.

Later, the same domain also serves:
- `/.well-known/apple-app-site-association`: Universal Links, so invite links open the app. It needs the Apple Team
  ID from the developer account.
- `/p/…` and `/d/…`: invite pages, served by the `invite-web` Edge Function.
