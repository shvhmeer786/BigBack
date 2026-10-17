# BigBack

A social food app for Gen Z students: decide where to eat, capture the meal while you're there
(BeReal-style front + back camera), rank it in three swipes, and discover spots through the people you
follow. Launching at the University of Waterloo.

## Docs
| | |
|---|---|
| Product vision | [docs/VISION.md](docs/VISION.md) |
| Beli teardown & research | [docs/research/01-beli-teardown.md](docs/research/01-beli-teardown.md) |
| Core experiences: Decide · Capture · Rank (incl. scoring model) | [docs/design/01-core-experiences.md](docs/design/01-core-experiences.md) |
| AI (Ask BigBack, Claude Haiku 5.5) | [docs/design/02-ai-features.md](docs/design/02-ai-features.md) |
| **Design system** (HIG, British racing green, motion, camera) | [docs/design/03-design-system.md](docs/design/03-design-system.md) |
| **Sign up, log in, email verification** | [docs/design/04-sign-up-and-login.md](docs/design/04-sign-up-and-login.md) |
| **Technical architecture** | [docs/architecture/01-technical-architecture.md](docs/architecture/01-technical-architecture.md) |
| **Database design** | [docs/architecture/02-database-design.md](docs/architecture/02-database-design.md) |
| **App Store readiness** | [docs/architecture/03-app-store-readiness.md](docs/architecture/03-app-store-readiness.md) |
| Database status / migration log | [docs/handoff/db-status.md](docs/handoff/db-status.md) |
| Clickable prototype (source) | [prototype/Main.dc.html](prototype/Main.dc.html) · design board [prototype/DesignSystem.dc.html](prototype/DesignSystem.dc.html) |

## Code
| | |
|---|---|
| iPhone app (SwiftUI, iOS 18+) | [ios/](ios/README.md): sign up / log in, profile setup, tab shell; CI builds every push |
| Database | [supabase/](supabase/README.md): migrations, smoke test, generated types, email templates |
| Server functions | `supabase/functions/` (`delete-account` is deployed) |
| Public pages | [web/](web/README.md): privacy policy, terms, community guidelines, support (drafts) |

## Backend
| | |
|---|---|
| Supabase project | `big-back` |
| Project ref | `iefchnylrxolydtulmgt` (us-east-1) |
| API URL | `https://iefchnylrxolydtulmgt.supabase.co` |
| Client key | Publishable key in `ios/Config/Supabase.xcconfig` |
| Migrations | `supabase/migrations/` (all applied; see [supabase/README.md](supabase/README.md)) |
| Smoke test | `supabase/tests/smoke_test.sql` (22 checks, passing) |
| Sign-up | `@uwaterloo.ca` only at launch, by emailed 6-digit code; students can rank restaurants anywhere |
| Email templates | `supabase/templates/` (sign-up and log-in codes) |

The publishable key is safe to ship in the app. Every table has Row Level Security enabled, and
access rules are documented in the database design doc. Secret/service-role keys, APNs keys and the AI
API key live only in Supabase secrets, never in this repo.
