# Core experiences: Decide · Capture · Rank

_The three moments where BigBack has to beat Beli outright. Companion to [../VISION.md](../VISION.md)._
_Social model (decided 2026-10-15): the feed shows only people you follow, and every Meal is visible to all your followers._

---

## A. DECIDE: "Where do we eat?"

Beli's answer is a search box and a list of scores. It assumes you already know where you're going, and it does
nothing for a group. BigBack treats choosing a place as the product itself, because it's the moment students hit
every day.

### A1. The Tonight screen (solo)

Opens with a ranked stack of **picks for right now**. Each pick has a big photo and **one line explaining why**:

> **Kinkaku Izakaya** · 🤤 8.9 *predicted for you*
> "Maya and Ari loved it this week · On your Want-to-Try · 9 min walk · open till 11"

How picks are ranked:
- **Open now / soon.** Places that are closed are hidden by default.
- **Predicted score for you** (see C5).
- **Social proof** from people you follow: recency × their score × taste match with you.
- **Your Want-to-Try** gets a boost, and a bigger one if a friend saved it too.
- **Distance** from where you are now (walk or transit time).
- **Novelty vs. safe bet:** a slider. "Somewhere new" leans to unvisited places, "Old faithful" to your top-ranked ones.

**Craving chips** narrow the stack in one tap: 🍜 Noodles · 🌯 Shawarma · 🍕 Pizza · 🧋 Bubble tea · 🌙 Late night ·
💸 Under $15 · 📚 Study spot · 🥂 Date night.

**Can't decide?** Shake the phone (or tap 🎲) and BigBack picks one from the current filters with a slot-machine animation.

### A2. "Let's eat": group decide (Tinder for the group chat)

1. Tap **Let's eat** → pick friends or a saved **Crew** (roommates, co-op team, club) → optionally set a time,
   budget or craving.
2. BigBack builds a stack of **8–10 candidates tuned to the whole group**:
   - It aims for the highest average predicted score with **"no one miserable"**: a place drops out if anyone's
     prediction is below 5.
   - Places that are on several people's Want-to-Try lists come first.
3. Everyone swipes. Non-users swipe on the **web link**, no app needed. This is the main invite loop.
4. **First place everyone likes = "It's a match!"** If there's no unanimous match within 10 minutes (or when the
   host taps Decide), the place with the most votes wins.
5. The match becomes a **Plan**: place, time, guest list with emoji RSVPs (Partiful-style), and a "What to order"
   preview. Reminders go out 1 hour and 15 minutes before.

**Crews** are saved groups. Each Crew has a shared Want-to-Try list, history ("places the roommates have hit") and
a Crew Top 10. They're a reason to come back as a group, not just alone.

### A3. Other ways into a plan (no app-wide invite wall)
- **"Go here"** on any feed post or place page → pick a time → invite.
- **"Who's down?"** on a Want-to-Try place → pings followers who saved the same place.
- **Tag at the table** (B4). Tagging people you're already with counts as a plan after the fact.

---

## B. CAPTURE: before and during the meal

Beli gives you nothing to do in the app while you're actually at the restaurant. BigBack makes the meal itself
**live**, so photos and thoughts get captured in the moment instead of rebuilt from memory.

### B1. Starting a Meal (any of these)
- Tap the **center camera button**. The place is suggested from your location (on-device), otherwise type 2 letters.
- **Arrival nudge** (opt-in): if you arrive at a planned place or a Want-to-Try place, you get a notification
  "At Kinkaku? Start your meal 📸". Built on iOS region monitoring for those places only, never continuous tracking.
- **Lock screen / Control Center button** (iOS 18 LockedCameraCapture) opens the BigBack camera without unlocking.
- **From a Plan:** when the plan starts, the Meal goes live for everyone who RSVP'd.

### B2. The Live Meal

While the Meal is live it's a **Live Activity** on the lock screen and Dynamic Island:
`Kinkaku · 0:42 · 4 snaps · Maya, Ari`, with a one-tap **Snap**.

The camera is **dual by default**. Back camera on the food, front camera on you, both captured at once
(`AVCaptureMultiCamSession`), BeReal-style, **no timer**. Tap to swap which one is large. Hold the shutter for a
3-second clip.

**Moment prompts** turn one photo into a story. Each one is optional and appears as a light chip at the right time:

| Moment | Prompt | Why it's fun |
|---|---|---|
| 🚶 Arrival | "The walk-in" / the line / the sign | Sets the scene |
| 📜 Order | Menu or "what we ordered" | Feeds "What to order" for others |
| 🍽️ Food | Each dish as it lands | The main event |
| 👯 Crew | The table, everyone in it | Social proof, tags |
| 🧹 Damage report | The empty plates | On-brand "big back" humour; counts toward the 🧹 Clean Plate badge |

**Dish tags, no remembering required.** After each food snap, chips show this place's known dishes (from other
people's tags and the menu). Tap one, or type a new one. This fixes the problem where 4 in 5 Beli users forget dish names.

**Quick takes.** A 1-line text or 10-second voice note at any time ("the garlic noodles are insane"). It's saved to
the Meal and shows up later as a caption for the recap.

### B3. "What to order", at the table
The Live Meal screen shows **this place's top dishes**:
- Ranked by people you follow first, then campus.
- Each with a photo and a 👍 rate ("Ari: get the karaage").
- Personalized: "people with your taste loved the tonkotsu".

This gives people a reason to open the app *during* the meal, which Beli has nothing for.

### B4. Group meals
- **Tag who you're with** (or they join by scanning your Meal QR). Tagged people accept, and the Meal shows up in
  their app too. Non-users get a text link.
- **Shared album:** everyone's snaps from the table pool into one album (Partiful photo-dump energy). Each person's
  post can use any photo from it.

### B5. Reliability
- Capture works offline (restaurant basements, bad signal). Uploads queue and retry in the background.
- Photos are compressed on the device (HEIC → ~1600px JPEG/WebP plus a thumbnail) before upload. Originals are kept
  locally until uploaded.
- A Meal ends automatically after 3 hours or when you leave (geofence exit), then moves to **To rate**.

---

## C. RANK: post-meal rankings and comparisons

Beli's ranking is its best idea and its biggest complaint. The problems: too many comparisons, comparisons across
different kinds of places, text-only cards, scores that drift and feel arbitrary, scores locked until 10 places,
and a toast as the only payoff. BigBack keeps the honesty of head-to-heads and fixes each of those.

### C1. The rating flow (about 10 seconds)

1. **Reaction → instant score.** 🤤 Loved it · 👍 Good · 😐 Mid · 👎 Nah. You get a score immediately, even for
   your very first place.
2. **Vibe** (pre-selected from the place type, tap to change): Cheap Eats · Sit-down · Date Night · Late Night ·
   Café · Dessert · Drinks.
3. **This or That**, up to 3 matchups.
   - Full-screen cards with **your own photo** from each visit (or the place's top photo if you have none).
   - Swipe toward the winner, with haptics. "Too close" and "Skip" are always available.
   - Opponents are only from **the same reaction tier and the same vibe**, so you're never asked to compare a
     taco truck with a tasting menu.
4. **The payoff screen.** Your list animates and the new place slides into its slot: **"New #3 in Late Night 🌙"**.
   Then the comparison card:
   > You **8.9** · People you follow **7.6** · UW **8.2** · Maya **4.2** 👀
5. Post. Notes, dish 👍/👎, price per person and the cover photo can be added now or any time later.

### C2. The scoring model

**Tiers give scores a fixed meaning.** Each reaction owns a band, and a place can never drift out of its band:

| Reaction | Band |
|---|---|
| 🤤 Loved it | 8.0 – 10.0 |
| 👍 Good | 6.0 – 7.9 |
| 😐 Mid | 4.0 – 5.9 |
| 👎 Nah | 0.0 – 3.9 |

Because of this, an 8+ always means "loved it", across people and over time. That fixes "we don't know what score
means good" and makes Friend and Campus scores comparable.

**Within a tier: one ordered list per user.** It covers all vibes, but comparisons only look at same-vibe entries.
- A new place is placed by **binary insertion over the same-vibe items in that tier**, capped at 3 comparisons. That
  finds the exact position among up to 7 items, or a narrow window when there are more.
- If the cap leaves a window, the place goes in the middle of it and is marked *unsettled*. Unsettled places are
  quietly refined later (C4).
- It's then inserted into the tier's overall list between its same-vibe neighbours.
- "Too close" counts as a tie: the place goes right next to that opponent.

**Score from position:** `score = band_low + band_width × (1 − (rank + 0.5) / n_in_tier)`, shown to one decimal.
Adding places can only move a score *within its band*, so drift is bounded and explainable.

**Repeat visits** take one tap, not a full re-rank: "vs. last time? ⬆️ Better · ➡️ Same · ⬇️ Worse". Better or Worse
moves the place one comparison step. Going ⬇️ from the bottom of a tier offers to change the reaction.

**Direct control:** in your list, press and drag to reorder (Gen Z expects direct manipulation). Moving a place
across a tier boundary asks to confirm the new reaction.

### C3. Dish rankings
- Every tagged dish gets 👍 / 👎, plus an optional ⭐ **"Best thing I ate"**.
- **Per place:** "What to order" = dishes ranked by ⭐ and 👍 share, weighted toward people you follow and people
  with similar taste.
- **Per person, later:** dish-type lists ("My ramen bowls") with the same This-or-That, so "best spicy vodka rigatoni
  at UW" becomes possible. Beli doesn't do dish-level rankings at all.

### C4. Comparisons as a game you come back to, not a chore
- **Settle it:** when you open the app with unsettled places, an optional card offers 1 matchup ("Quick one: Lazeez
  or Shawarma Plus?"). One swipe and it's done. Never more than 1 a day, and never blocking.
- **Defend your #1:** when 3 or more people you follow rank something above your #1 in the same vibe, you get a
  challenge card. Swipe to defend it or switch.
- **Food Fights** (campus):
  - A weekly bracket, e.g. "Best shawarma at UW".
  - Only people with a logged Meal at **both** places can vote on a matchup, so the results come from people who
    actually went.
  - Results build the **UW Top 50**, a head-to-head campus ranking that's more credible than Beli's average score.
  - Brackets are shareable to Instagram Stories.

### C5. Scores you see on a place
| Score | How it's computed | Shown as |
|---|---|---|
| **Yours** | Your tier + position (C2) | Big colored badge |
| **Predicted for you** | Weighted average of other users' scores, weighted by taste similarity, shrunk toward the campus score when there's little data | "Predicted 8.4 for you" |
| **People you follow** | Average of your follows' scores, weighted by taste match, with a count | "7.6 · 6 people" |
| **UW** | Bayesian average `(C·m + Σs)/(C + n)`, C = 5, m = campus mean, so one rating can't make a 10 | "8.2 · 140 Waterloo eaters" |
| **Head-to-head** | From Food Fights or pairwise data among follows | "62% of people you follow prefer it over Shawarma Plus" |

**Taste Match %** between two people = correlation of their scores on places they've both rated (needs 5 or more in
common), shown on profiles ("You and Maya: 87% match") and used for weighting in the scores above.

### C6. Fixing each Beli ranking complaint
| Beli complaint | BigBack fix |
|---|---|
| "Slow… every time I add a new place" | 3 comparisons maximum, skip anytime, one tap for repeat visits |
| Taco truck vs. Michelin | Opponents from the same tier *and* vibe only |
| Text-only cards, can't remember the meal | Cards show your own photos from that visit |
| Scores drift and feel arbitrary | Fixed tier bands: drift only within the band, and 8+ always means loved |
| Nothing until 10 places | Score from the very first reaction |
| "Can't explain 8.2 vs 8.3" | Drag to reorder; the score follows your order |
| Only a toast as the payoff | Animated list slot + you-vs-friends comparison card |
| Inaccurate match % | Correlation on shared places, needs 5+, shown with its sample size |
| Average score can be gamed or inflated | Bayesian campus score + head-to-head Food Fights from people who went to both |

---

## D. Data this implies (input to the architecture doc)
- `meals` (user, place, started_at, ended_at, status: live/unrated/posted, visibility = followers)
- `meal_media` (meal, back_url, front_url, moment, dish_id, taken_at, is_live)
- `meal_tags` (meal, tagged_user, status) · `quick_takes` (meal, text / audio_url)
- `rankings` (user, place, tier, vibe, position, score, settled bool, updated_at)
- `comparisons` (user, winner_place, loser_place, tie bool, source: rate/settle/defend/fight)
- `dishes` (place, name) · `dish_ratings` (user, dish, meal, thumb, best bool)
- `plans`, `plan_members` (rsvp emoji), `crews`, `crew_members`, `decide_sessions`, `decide_votes`
- `follows` · `saves` (want-to-try) · `food_fights`, `fight_matchups`, `fight_votes`
