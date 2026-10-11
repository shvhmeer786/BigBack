# Research 01 — Beli teardown & the BigBack opportunity

_Compiled 2026-10-11. Sources: Mobbin screen library (Beli, Partiful, BeReal iOS), press coverage, App Store / Google Play
review excerpts, student press, design critiques. Caveat: web pages were read via search excerpts (direct fetch was
blocked from the research sandbox) and no Reddit threads could be retrieved — verify any number before quoting it
externally. Company-reported numbers are marked (co)._

---

## 1. Beli in one page

| | |
|---|---|
| Founded | 2021, NYC — Judy Thelen (CEO) & Eliot Frost |
| Funding | ~$5.3M (Nov 2023, Goodwater lead); no 2025–26 round found |
| Scale | 120M+ ratings across ~2M venues (Aug 2026, co). ~80% of users under 35 (co). No MAU published |
| Strongholds | NYC, Chicago, SF, Boston, DC; spreading on campuses (Northwestern, Harvard, Syracuse, Vanderbilt) |
| Store rating | iOS 4.8–4.9 (~15K), Google Play 4.2–4.3 (~1.8K) |
| Money | Free core; paid streak restores, creator Guide subscriptions, invite-only Supper Club (~$75–100/yr) |

**Core mechanic.** Pick a list (Restaurants / Coffee & Tea / Bars…) → "How was it?" (liked / fine / didn't like) →
repeated "Which do you prefer?" head-to-heads against places already on your list → position becomes a personal 0–10
score. Scores only appear after 10 places in a category; your "Beli Rank" unlocks at 100.

**Everything else.** Been / Want to Try / Recs / Playlists lists, score-pin map, place page with Rec Score + Friend
Score + Average, OpenTable slots, friend feed, leaderboards (Been / Influence / Notes / Photos, with % match), weekly
streaks, yearly challenge, Taste Profile, "Beli Plated" year-end recap, school leaderboards.

## 2. What the UI actually looks like (Mobbin)

Observed directly from Beli's iOS screens:

- **Ranking cards are text-only.** The "Which do you prefer?" step shows two white boxes with restaurant names in serif
  type — no photos, no dish, no memory cue. Buttons: Undo / Too tough / Skip.
  ([screen](https://mobbin.com/screens/e1f1992f-825a-4006-af91-f08208bdca41))
- **Posting is a form.** After ranking, a sheet of rows: Who did you go with? / Add labels / Add notes / Add favorite
  dishes / Add photos / Add visit date / Stealth mode → Okay. Photos are one row among seven, added after the fact.
  ([flow](https://mobbin.com/flows/08b43844-b0d6-4238-87ef-7a6c9bf07bbb))
- **Feed is a log, not a feed.** Cards read "Judy ranked SOOTHR with Jesse, Allie, Eliot Frost · 9.2", then a small
  photo strip and a paragraph of notes. Above it: an invite-gate module ("You have 3 invites left! Unlock features as
  friends join (4/5)" — Average Scores, Dish Search, Stealth Mode, Social Links, Res Priority).
  ([screen](https://mobbin.com/screens/fa5ae271-1fb8-4e3e-b3e7-929b58eb444b))
- **Lists are spreadsheets.** Numbered rows, price/cuisine/neighborhood, score in a circle, filter chips. Map view =
  colored score pins. ([screen](https://mobbin.com/screens/f010dc98-7330-44ed-a9a3-bf64214f204c))
- **Lots of locks and tooltips.** Progress bars to "unlock" recs, modal explainers ("Your Beli Rank: rate 100 places to
  unlock"), coach-marks on nearly every first visit.
- **Visual language.** White + muted teal, serif headlines, thin grey rows. Calm and tasteful — and static. Nothing
  moves, nothing is full-bleed, no video, no camera-first moment.

## 3. Weaknesses (ranked by how often they come up)

1. **Ranking fatigue.** The #1 complaint. "It's slow and inconvenient to do multiple pairwise comparisons every time I
   add a new place" (Google Play). "I wish I could opt out of it completely" (App Store).
2. **Apples-to-oranges comparisons.** Forced to compare a taco truck with a Michelin dinner; "the expectation is
   different" (App Store). Pratt's 2026 critique proposes cheap eats / casual / fine dining sub-lists.
3. **Scores feel arbitrary and drift.** Relative to your list, so "a 7.4 isn't comparable across people or time"; users
   override because "realistically I'd give it an 8." Match % called "extremely inaccurate."
4. **Invite walls & contact harvesting.** Features locked behind inviting friends; "I want to see if I even like the
   app and I don't want to share my contacts" (Google Play).
5. **After-the-fact posting.** You rank later, from memory; photos dug out of the camera roll; captions want dish names
   that 4/5 surveyed users forget.
6. **Boring, cluttered UI.** "Featuritis"; competing prompts and promos; new users unsure how to proceed.
7. **No group planning.** No "where should we eat tonight" or invite-to-dinner feature at all — biggest open gap.
8. **Data gaps.** New/cheap spots take a week+ to be added, some never; wrong cities; bugs and slow loads.
9. **Elitism / hype skew.** Lists skew to overhyped, expensive NYC spots; Supper Club for power users only.
10. **Public by default.** Some users just want a private list.

**What people love — keep it:** honest relative scores (vs. 4-star inflation), friends > strangers, a food diary that
replaces the Notes app, gamification (streaks, leaderboards, map unlocks, year-end recap), Rec Score / Match %, handles
as social identity.

## 4. Borrowed mechanics — what transfers

| App | Mechanic that works | What happened | Steal for BigBack |
|---|---|---|---|
| **BeReal** | Dual camera, 2-min window, post-to-see, RealMojis | DAU fell ~15M → ~6M in 2023; random prompt got stale; sold to Voodoo 2024 | The *moment* is the magic — but trigger it from a real event (the meal / the plan), not a random daily ping |
| **Partiful** | Link invites, RSVP without an account, emoji RSVPs, visible guest list, text blasts, photo album after | Google Play Best App 2024; MAU +400% YoY; Apple Invites didn't dent it | Every dinner plan is a link anyone can RSVP to — the invite *is* acquisition. Visible guest list = FOMO |
| **Luma** | Calendars you subscribe to, approval gating, QR check-in | Small team, steady growth | Recurring food clubs; check-in proves you went |
| **Snap Map** | Friends on a map, heatmap, Ghost Mode, Footsteps "% of city explored" | 400M monthly Map users; Instagram's 2025 clone hit a stalking backlash | Friends' *places* on a map + "% of campus eaten". Share venues, not live people; off by default |
| **Tinder** | Card stack, match moment | Solo swiping declining; Double Date (group) is the Gen Z win | Swipe is great for finite decisions: ranking and group "where do we eat" matching |
| **Locket / Retro** | Home-screen widget; weekly photo dump | Locket 9M DAU (co); Retro 7M downloads | Widget of friends' latest bites; weekly "what we ate" dump |
| **Lapse** | Forced invites to unlock | 218K/day downloads → −70% in weeks | Don't gate on invites — Beli's weakness is a known trap |
| **Strava / Duolingo / Wrapped** | Clubs, kudos, forgiving streaks, annual recap | Strava clubs ~4x in 2025; Wrapped 500M+ shares | Weekly (not daily) streak with freezes; semester-end "BigBack Wrapped" |

**Gen Z context 2025–26:** public posting is falling ("posting zero"); activity is moving to group chats, Close
Friends and small graphs; IRL-meetup apps (Timeleft, Strava clubs, Tinder Double Date) are growing. Campus playbook
that keeps working: saturate one campus behind a .edu gate, seed tight groups first (clubs, Greek life, dorm floors),
then expand to peer schools.

## 5. The BigBack answer (draft concept)

**One loop, built around the meal itself:**

```
 PLAN ──────────▶ DROP ──────────▶ RANK ──────────▶ FEED / MAP
 (Partiful/Luma)  (BeReal)         (Tinder)          (TikTok / Snap Map)
 invite link,     plan start time  swipe vs. photo   full-screen friend
 RSVP w/o app,    pings the table: cards, ≤3 swipes, posts, saves to
 group "where     2-min dual-cam   scoped to vibe,   Want to Try → seeds
 do we eat" swipe drop, together   group reveal      the next PLAN
```

| Beli weakness | BigBack design response |
|---|---|
| Ranking fatigue | Max ~3 swipes; ranking can be skipped and done later from a "to rank" tray |
| Text-only comparisons | Comparison cards show *your own photos* from that visit |
| Cross-category comparisons | Rank inside a vibe: Cheap Eats / Date Night / Late Night / Coffee / Dessert (user picks one tap) |
| After-the-fact posting | The Drop: dual-camera at the table, timed to the plan; dish names optional |
| Invite wall | Nothing gated. Growth comes from plan links non-users can RSVP to |
| Boring static UI | Full-bleed photos, motion, haptics, a playful "big back" voice |
| No group planning | Plans + group swipe to choose the spot (overlap = match) |
| Data gaps | Anyone can add a place instantly (user-sourced row, cleaned up later) |
| Elitism | Student-price filters, campus leaderboards, cheap-eats as a first-class vibe |
| Public by default | Choose private or public profile; location sharing off by default, venue-level only |

## 6. Restaurant data — recommendation

- **On device: Apple MapKit** (`MKLocalSearch`, POI filter for restaurants/cafes/bakeries/nightlife, Place Card,
  Look Around). Free; no server key.
- **Persist Apple's Place ID** (`MKMapItem.Identifier`, iOS 18+) — Apple explicitly allows persisting it. Apple's
  license (DPLA Att. 6 §2.2/§2.5) forbids storing Apple's names/addresses/coordinates in our own database and showing
  them without an Apple map. So:
- **Canonical place fields from Foursquare OS Places** (Apache 2.0, 100M+ POIs, monthly updates). Load the Dining &
  Drinking categories for launch cities into Supabase; match Apple results to FSQ rows server-side (name similarity
  + ~75 m radius) when a place is first ranked/posted. No match → user-sourced row.
- **Google Places: optional, later.** Store only `place_id` (free IDs-only lookups) for "Open in Google Maps". Never
  put Google data on an Apple map; full Google search would cost ~$12k/mo at 10k MAU.
- **Reservations:** no public Resy/OpenTable APIs — store a `reservation_url` and deep-link.
- **Cost at MVP scale:** ≈ $25–60/mo (Supabase) at 10k MAU; ≈ $150–400/mo at 100k MAU.

_Get a lawyer's read on the Apple-data/FSQ matching approach before launch._
