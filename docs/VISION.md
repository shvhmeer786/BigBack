# BigBack — Product Vision (v2)

_Living doc. Last updated 2026-10-15. Research: [research/01-beli-teardown.md](research/01-beli-teardown.md).
v1 (Table → Drop → Recap) was dropped: too many new nouns, and it made inviting a step you had to do before posting._

## 1. The diagnosis: why Beli is a chore

Beli's basic unit is **"rank a restaurant"**: a form you fill out after the meal, with a payoff that comes much later
(scores after 10 ranks, recommendations after ~15, Beli Rank after 100). So people open Beli in only two moments:
right after eating, if they remember, and occasionally to look up a place. Everything we heard in the research
comes back to that:

| Beli problem (research) | Root cause |
|---|---|
| Ranking fatigue, "mandatory ranking" (#1 complaint) | Ranking is the *only* way to log a meal, and it never ends |
| Taco truck vs. Michelin comparisons | One list for every kind of eating |
| Photos dug out of the camera roll, dish names forgotten | Logging happens after the meal, from memory |
| Feed reads like a log ("Judy ranked X · 9.2") | Posts are records, not content |
| Invite walls, contact harvesting | Growth was forced, not earned |
| Static, cluttered, text-heavy UI with locks and tooltips | Built like a database, not a social app |
| No group planning | Assumes you already know where you're going |
| Mainly opened after eating | Doesn't help with the daily "where should we eat?" question |

## 2. The BigBack answer in one line

**BigBack is where you decide where to eat, capture the meal while you're there, and rank it in three swipes. Your
friends' meals are the best feed on your phone.**

Three moments, each one better than Beli:

| Moment | Beli today | BigBack |
|---|---|---|
| **Before:** "where should we eat?" | Search a list of scores | **Tonight** screen: friends' recent spots, your Want-to-Try that's open now, what's trending on campus; invite friends in two taps |
| **During:** at the restaurant | Nothing to do in the app | **The meal is live:** front-and-back camera snaps, "what to order here" from friends, tag who you're with |
| **After:** logging it | Seven-row form plus endless comparisons | **Rate in about 10 seconds:** reaction → 3 photo swipes → posted. Writing is optional, any time later |

## 3. The core object: a Meal

There's one noun to learn. A **Meal** is you, eating somewhere, maybe with people.

```
  START ────────────▶ LIVE ─────────────────▶ RATE ──────────────▶ POSTED
  tap camera,         at the restaurant:       reaction + up to      shows in friends'
  or "I'm here",      snap front/back photos   3 This-or-That        feed; notes/dish tags
  or from an invite   (no timer), tag friends,  swipes → score        can be added later
                      see what to order
```

- **Starting a Meal:** tap the center camera button anywhere in the app. If location is on, the place is suggested
  automatically; otherwise it's a two-letter search. No invite, no setup.
- **During the Meal:**
  - The Meal shows as an iOS **Live Activity** on the lock screen and Dynamic Island ("At Lazeez · 3 snaps · 📸").
    One tap snaps another photo without digging through the app.
  - **Dual camera:** back camera on the food, front camera on you. Taken together, BeReal-style, with no countdown.
    Snap as many times as you want (starter, mains, dessert, the table).
  - **"What to order":** the Meal screen shows the top dishes here from friends and campus, with photos. That's a
    reason to open the app *at* the restaurant, and it doubles as the dish list for tagging (no remembering names).
  - **Tag who you're with:** tagged friends get the Meal in their app to rate too. Non-users get a text link, which is
    a natural invite.
- **Rating** (right there or later; unrated Meals wait in a **To rate** tray, with a gentle nudge the next morning):
  1. One-tap reaction: 🤤 Loved it · 👍 Good · 😐 Mid · 👎 Nah. That alone gives you a **score right away**; no
     waiting for 10 places.
  2. **This or That** (Tinder-style): up to 3 swipe matchups against places in the *same vibe* (Cheap Eats, Date
     Night, Late Night, Coffee, Dessert, Sit-down). Each card shows *your own photo* from that visit. Swipe toward the
     winner, with haptics. "Too close" is allowed. The score is refined.
  3. Post. Notes, dish tags, price per person and a cover photo can be added now or any time later.
- **Group Meals:** when several tagged friends rate the same Meal, everyone's score is revealed together as a
  **Table Verdict** card ("Sam 9.1 · Maya 4.2 · Ari 7.8"). Disagreement gets people talking.

## 4. Invites: built into the loop, never required

Invites appear wherever wanting to go together happens naturally. You never have to invite someone before you can post.

| Where | What happens |
|---|---|
| Friend's post → **"Go here"** | Pick a time → choose friends → Partiful-style invite link with emoji RSVPs and visible guest list. Non-users RSVP on the web |
| Tonight screen → **"Let's eat"** | Start a group: everyone swipes through a short stack of options; the first mutual match wins (Tinder Double Date for food) |
| At the restaurant → **tag friends** | They get the Meal; non-users get a link |
| Want-to-Try → **"Who's down?"** | Asks friends who saved the same place ("Maya also wants to try Kinkaku") |

When a planned meal starts, the Meal goes live for everyone who RSVP'd, and the loop continues as normal.

## 5. Why people come back (the hook)

The main internal trigger is **hunger**, and students feel it every day. Beli waits until after you've eaten;
BigBack is the app you open when you're deciding. That's the daily habit. Everything else layers on top of it:

| How often | Trigger | Reward |
|---|---|---|
| **Daily** | "Where should we eat?" | Tonight screen: open-now picks from friends, campus trending, your Want-to-Try |
| **Daily** | A friend posts a Meal | Full-screen photo feed, reactions, "you'd rate this 8.4" prediction |
| **Event** | Tagged in a Meal, invited, RSVPs come in | Social pull |
| **Event** | A friend goes somewhere on your Want-to-Try | "Maya just went to Kinkaku: 8.7, ordered the tonkotsu" |
| **Event** | Your #1 gets challenged | "Your top shawarma just got outranked by 3 friends. Defend it?" (an optional This-or-That) |
| **Weekly** | **Sunday Bites**: a recap of what your friends ate this week | A Retro/Locket-style dump plus your weekly streak (one new spot a week, with freezes) |
| **Each term** | **Term Wrapped** and campus leaderboard seasons | Waterloo terms (Fall/Winter/Spring) reset the leaderboard, so anyone can win; Wrapped is built to share |
| **Always** | **% of Waterloo eaten** map | Collecting places, badges ("Plaza Completionist") |

**Investment:** every Meal improves your rankings, taste profile and recommendations, and fills a food diary you
don't want to lose. Your Want-to-Try list becomes plans.

## 6. Navigation

```
 [ Feed ]   [ Tonight ]   [ ◉ Camera ]   [ Activity ]   [ You ]
```
- **Feed:** people you follow. Full-screen vertical posts: the dual-cam photo
  (food big, selfie inset), score badge, place, who you were with, reactions (including selfie reactions), **Save**
  (double-tap), **Go here**.
- **Tonight:** an **Ask BigBack** prompt bar (plain-language "where should we eat?", see design/02-ai-features.md), plus a map and list combined. Open-now, friends' spots, Want-to-Try nearby, trending at UW, search, "Let's
  eat" group pick.
- **Camera:** starts a Meal (or adds a snap to the one already live).
- **Activity:** invites and RSVPs, To-rate tray, tags, reactions, challenges.
- **You:** your rankings by vibe, Want-to-Try, map (% eaten), stats, streak, badges, settings and privacy.

## 7. UI principles (Beli's weakest area)

1. **Photos first, text second.** Full-bleed images, a big colorful score badge, minimal grey rows.
2. **Motion and haptics everywhere they mean something:** swiping, the reveal, a new #1.
3. **Nothing locked.** No invite walls, no "rank 100 to unlock", no paid streak restores.
4. **Teach by doing, not tooltips.** Onboarding *is* the product (below).
5. **Fun voice:** "certified big back", "mid", "who's down?". Self-roasting, never snobby.
6. **Fast paths everywhere:** every core action takes under 10 seconds; depth is optional.

## 8. Onboarding: value in 60 seconds, no invites

1. Verify `@uwaterloo.ca` email (or join a waitlist if you're at another school).
2. **Waterloo Starter Pack:** swipe through ~25 famous local spots: ➡️ Been · ⬅️ Never · ⬆️ Want to try.
3. **Quick This-or-That** on the ones you've been to, giving you an instant personal Top 10 and recommendations.
4. Find friends: optional contacts, or by handle or QR. You can skip.
5. Land on Tonight, already personalized.

## 9. Privacy and safety
- Public or private profile; per-Meal visibility (public / followers / tagged people / only me).
- No live location sharing, ever. Places are shown after the fact, at venue level. Location use is on-device and
  opt-in, only to suggest the place you're at.
- Tagging requires the tagged person to accept before the Meal appears on their profile.

## 10. MVP (Waterloo launch)
**In:**
- Waterloo email auth, profiles, follows
- Place search with Apple Maps plus our own place records
- Meals: dual camera, live state, Live Activity, To-rate tray
- Rating: reaction plus This-or-That by vibe
- Friends feed (full screen), save to Want-to-Try
- Tonight (open-now, friends' spots, Want-to-Try, trending)
- Tagging friends
- "Go here" invites with a web RSVP page
- Starter Pack onboarding
- AI (small, Haiku-tier): Ask BigBack prompt bar only
- Push notifications

**Fast follow:**
- "What to order" dish rankings
- Table Verdict
- "Let's eat" group swipe
- Sunday Bites and weekly streak
- Challenges

**Later:**
- Term Wrapped and seasons
- % eaten map and badges
- Home-screen widget
- Co-op city expansion
- Reservation deep links

## 11. Open questions
- ~~Feed scope~~ Decided: the feed shows people you follow; all followers see your Meals. Discovery happens in Tonight, place pages and Food Fights.

