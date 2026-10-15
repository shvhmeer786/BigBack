# AI in BigBack

_Companion to [01-core-experiences.md](01-core-experiences.md). Drafted 2026-10-15._

## Principle: AI helps you decide and write. It never rates for you.

Rankings stay human. They're the most trusted part of Beli and they'll be the most trusted part of BigBack. Gen Z is
sceptical of AI food opinions (Yelp's Feb 2026 study found only 43% trust AI restaurant summaries). So every AI
output in BigBack is:
- **Grounded:** built only from our own data (places, your follows' scores and notes, dishes, hours). It never
  invents a restaurant, a dish or a quote. Every suggestion links to the place, post or person behind it.
- **Optional:** a shortcut, never a gate.
- **Editable:** anything written for you is a draft you can change. Nothing is posted automatically.

## The features

### 1. Ask BigBack: "where should we eat?" in plain words (MVP)
A prompt bar at the top of **Tonight**. Type or say what you want:

> "cheap spicy noodles near DC library, open after 11, 4 of us, one vegetarian"
> "somewhere to take my parents that Maya rated high"
> "best late-night thing within a 10 min walk that none of us have tried"

Claude reads the request, calls our tools to search *our* database, and returns 3–5 **place cards**, each with a
grounded reason ("Ari 9.2 last week · veg options tagged by 6 people · open till 1am · 7 min walk"). You can keep
refining ("cheaper", "closer", "not ramen"), then tap one of:
- **Go** (starts a plan),
- **Send to the group** (becomes the stack for "Let's eat"), or
- **Save**.

Tools the model can call (all read-only, all scoped to the requesting user through RLS):

| Tool | Returns |
|---|---|
| `search_places` | Places filtered by cuisine/craving, vibe, price, open-at time, distance from a point, dietary tags |
| `get_predicted_scores` | Predicted score for the user (or each group member) for a list of places |
| `get_follow_activity` | Recent scores, notes and dish ⭐ from people the user follows for given places |
| `get_want_to_try` | Want-to-Try lists for the user or group members |
| `get_dishes` | Top dishes per place, with tags (veg, spicy…) |

The output is a structured JSON list of `{place_id, reason, highlights[]}`. The app renders cards only for
`place_id`s that actually came back from the tools; anything else is dropped. That's the guard against made-up places.

### 2. Group asks (inside "Let's eat")
Each member can add a line ("I'm broke this week", "no seafood", "I had pizza yesterday"). BigBack merges everyone's
constraints into the group stack. When there's a match, it writes a one-line summary for the invite ("Kinkaku: fits
everyone's budget, 3 of you saved it, Sam's veg options covered").

### 3. Snap → dish suggestion (MVP)
After a food snap, Claude looks at the **back-camera photo only** (the selfie is never sent). It picks the most
likely dish from that place's known dish list, or proposes a new name. The suggestion appears as the first dish chip;
tapping it confirms. It runs asynchronously after upload, so it never slows down the camera.

### 4. Recap writer (MVP)
At rating time, your **quick takes** (text, plus voice notes transcribed on-device with Apple's Speech framework),
dish tags and reaction are turned into a short draft caption *in your voice*. The model learns your tone from your
last few posts. One tap to use it, edit it or ignore it.

### 5. Menu reader (fast follow)
Snap the menu at the table and get: "**Order this:** the dishes people you follow ⭐'d are highlighted, plus 2 picks
predicted for your taste." It also translates menus. This makes the in-restaurant experience something Beli simply
doesn't have.

### 6. "What people you follow say" (fast follow)
On a place page: a 2–3 line summary of your follows' notes, with every claim linked to the post it came from.

### 7. Taste profile & Term Wrapped copy (later)
"Spice-chasing noodle loyalist who never skips dessert." Generated once a term for everyone in one Batch API job (half
price), and used on profiles and in Wrapped.

## Architecture

```
iOS app ──(user JWT)──▶ Supabase Edge Function  ai-ask / ai-dish / ai-recap
                              │  Anthropic TypeScript SDK (@anthropic-ai/sdk)
                              │  tool calls → Postgres queries run with the user's JWT (RLS applies)
                              ▼
                         Claude API ──stream──▶ Edge Function ──SSE──▶ app
```

- **The API key lives only in Edge Function secrets.** It is never in the app.
- **Streaming** for Ask BigBack, so cards appear as they're decided.
- **Prompt caching:** the system prompt and tool definitions are a frozen prefix, so repeat requests mostly hit the cache.
- **Structured outputs** (`output_config.format`) for every response the app renders (cards, dish pick, caption).
- **Model: Claude Haiku 5.5 (`claude-haiku-5-5`), owner decision 2026-10-15.** $0.10 / $0.50 per million
  input / output tokens for prompts up to 100K tokens (every Ask BigBack request is far below that). Haiku 4.5 was
  $1 / $5, so this is about 10× cheaper for the same feature. The model ID lives in `app_config.ai.model`, so a
  future switch needs no app release.
- **How Haiku 5.5 is called** (it differs from Haiku 4.5 in ways that return errors if ignored):
  - `output_config: { effort: "low" }`. The default is `medium`; `low` is cheaper and faster, and is plenty for
    turning a short request into filters. Raise it only if an eval of real requests shows a quality gap.
  - No `temperature`, `top_p` or `top_k` (non-default values return a 400). Output is constrained with
    `strict: true` tools and structured outputs instead.
  - No assistant prefill (400). The request always ends with a user turn.
  - Thinking is on by default: read response blocks by `type`, never `content[0]`; give `max_tokens` room
    (about 2,000) so thinking can't crowd out the answer; pass thinking blocks back unchanged in the tool loop and
    keep the conversation append-only.
  - Refusals (`stop_reason: "refusal"`) have no server-side fallback on Haiku. The app then shows the regular
    Tonight results (`tonight_picks`), so the user is never stuck.
  - Haiku 5.5 counts the same text as about 30% more tokens than Haiku 4.5. Budgets and dashboards use counts
    measured on `claude-haiku-5-5`.
- **Guardrails:**
  - Per-user rate limit: 10 asks a day (`app_config.ai.daily_limit`).
  - The prompt treats user text as data, not instructions.
  - Tools are read-only.
  - Tool results are filtered to what the user is allowed to see.
  - Logs keep the request ID and token usage, not the photos.

## Rough cost (estimates to verify with real traffic)

One Ask BigBack request is roughly 6–10k input tokens across its tool rounds (system prompt, tool definitions, the
request and tool results) and under 1k output tokens. On Haiku 5.5 that's about **$0.001 per ask**.

| Volume | Claude Haiku 5.5 | (Haiku 4.5, for comparison) |
|---|---|---|
| 1k students × 10 asks / month = 10k asks | ~$10 / month | ~$100 |
| 10k students × 10 asks / month = 100k asks | ~$100 / month | ~$1,000 |

Caching the frozen prefix (system prompt + tools) lowers this further: cache reads cost a tenth of the input rate.
Check `usage.cache_read_input_tokens` to confirm the prefix is long enough to be cached. The per-user daily limit
(10 asks, logged in `ai_requests`) caps the worst case.

## Scope (owner decision 2026-10-15: AI stays small and cheap)
- **MVP:** Ask BigBack (solo) only, on Claude Haiku 5.5, with a tight daily limit per user.
- **Maybe later, if cheap and wanted:** dish suggestion from photos, recap writer.
- **Parked:** group asks, menu reader, follow summaries, taste profiles.
