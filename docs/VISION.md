# BigBack — Product Vision

_Living doc. Last updated 2026-10-11. Research behind it: [research/01-beli-teardown.md](research/01-beli-teardown.md)._

## Premise

**Beli is a form you fill out after the meal. BigBack is part of the meal.**

BigBack is a social food app for Gen Z and college students: eat with friends, capture it live, rank it fast, and
discover where to go next through a feed that's actually fun to scroll. We keep what people love about Beli (honest
relative rankings, friends over strangers, a food diary, light gamification) and fix what makes it a chore (slow
ranking, after-the-fact posting, invite walls, static UI, no way to get friends to the table).

"Big back" is slang for someone who loves to eat. The brand is playful, a little self-roasting, never snobby.

## Who it's for

- **Launch: University of Waterloo students.** Verify with a `@uwaterloo.ca` email. Seed through clubs, residences,
  and friend groups first; win the Plaza, Uptown, King St and Kitchener before anywhere else.
- **Why Waterloo works:** dense campus, a strong student food scene, and **co-op**. Every term, thousands of students
  move to Toronto, SF, NYC and Seattle and come back. BigBack travels with them: "where Waterloo eats in SF" is a
  built-in expansion path no other campus gives us.
- **Then:** peer Canadian schools (UofT, McMaster, Western, Laurier next door) and the co-op cities.

## Product principles

1. **In the moment beats after the fact.** Capturing happens at the table; writing can happen later.
2. **Fast by default, deep if you want.** Every step has a 10-second path. Notes, dish tags and full ranking are optional.
3. **Better with friends, but never gated.** No invite walls, no contact harvesting. Growth comes from invites people
   actually want to accept.
4. **Places, not people.** We share where you ate, never a live location. Location features are off by default.
5. **Fun is a feature.** Full-bleed photos, motion, haptics, a voice with personality.

## Core objects

| Object | What it is |
|---|---|
| **Place** | A restaurant, café, bar, bakery, dessert spot, food truck. |
| **Table** | A meal with people. Started **on the spot** ("I'm at Lazeez, pull up") or **planned** ahead (a Partiful-style invite with RSVP). Anyone can join with a link, even before they have the app. |
| **Drop** | A BeReal-style front-and-back photo taken *during* the meal. Several per meal is fine (apps, mains, dessert, the table). Marked **live** because it was captured in-app at the place. |
| **Visit** | One person's meal at a Place. It collects that person's Drops, then becomes their review. Can belong to a Table or be solo. |
| **Recap** | The review, written whenever: pick favourite drops, tag dishes, add notes, choose a vibe, rank. |
| **Ranking** | Your personal ordered list per vibe, built by quick head-to-head swipes and turned into a 0–10 score. |

## The core loop

```
 TABLE ───────▶ DROP ───────▶ RECAP + RANK ───────▶ FEED / MAP ─┐
 on the spot    live photos   later: write, tag,    friends see,  │
 or planned     during the    swipe to rank         save "Want to │
                meal                                 Try"          │
   ▲─────────────────────────────────────────────────────────────┘
                    a saved spot becomes the next Table
```

### 1. Table: get people there
- **On the spot:** tap **+** → "Start a table" → pick the place (nearby places pre-filled) → share a link or QR, or
  ping friends who are close by and opted in. Done in about 5 seconds.
- **Planned:** pick a place (or let the group swipe to choose; mutual likes win), date and time → invite link →
  emoji RSVPs, visible guest list, a group thread, reminders.
- People without the app open the link on the web, RSVP and see who's coming. Joining the app comes later; this is
  the main growth loop.

### 2. Drop: capture the moment
- When a planned Table starts, everyone at it gets a "🍽️ Time to drop" nudge. On-the-spot tables open straight to the camera.
- Front and back camera at once. No caption needed. Each Drop attaches to your Visit automatically.
- Table members see each other's drops live. Friends see a **"Live now"** rail at the top of the feed
  ("4 friends eating at Mozy's"), shown at venue level only and only if you allow it.
- You can still add camera-roll photos to a Visit, but they don't get the live badge.

### 3. Recap and rank: whenever you want
- After the meal, the Visit lands in your **To recap** tray with its drops already attached.
- Recap in under 30 seconds: pick a cover drop → one-tap reaction (🔥 / 👍 / 😐 / 👎) → choose a vibe
  (Cheap Eats, Date Night, Late Night, Coffee, Dessert…) → **swipe to rank**: 2–3 head-to-heads against places in
  the same vibe, shown with *your own photos* from each visit → score.
- Optional deeper fields: notes, dish tags ("the butter chicken poutine"), price per person, who you were with.
- At a Table, everyone's rankings stay hidden until everyone submits, then the **Table reveal** shows each
  person's score side by side. That reveal is shareable.

### 4. Feed, Map and Explore: discover where to go next
- **Friends feed:** full-screen, vertical, swipeable posts made from recaps (drops + score + short note), with
  reactions, comments and **double-tap to save** to Want to Try.
- **Explore:** public posts and trends for your city or campus: "Trending at UW this week", top Cheap Eats near
  you, new openings, top lists.
- **Map:** your places and your friends' places by score, plus a heatmap of what's hot. Includes a "% of Waterloo eaten"
  stat for collectors.
- Saving a place adds a "Start a table here" shortcut, which closes the loop.

## Social model
- Profiles are **public or private** (your choice). Private means only approved followers see your posts.
- Follow model (not mutual friends only) so Explore and food creators work. Close friends see your "Live now".
- Every Visit has its own visibility setting: public, followers, table only, or just me.

## Gamification (light, never paywalled)
- **Weekly streak:** a new spot each week, with freezes. Not daily.
- **Campus leaderboard:** most places, best photos, most-saved recs.
- **Badges:** "Plaza Completionist", "Shawarma Sommelier", "Late Night Legend".
- **Term Wrapped** at the end of each Waterloo term: top spots, taste profile, your "food twin", built to share.

## MVP scope (v1, Waterloo launch)
**In:**
- Waterloo email verification, profiles (public or private), follows
- Place search (Apple Maps on the device) and our own place records
- Tables: on the spot and planned, with link and QR invites, plus a web RSVP page
- Drops (dual camera, live badge), Visits, To recap tray
- Recap with reaction, vibe, swipe ranking, notes and dish tags
- Friends feed (full screen) and a basic Explore (trending at UW)
- Want to Try list, personal ranked lists, a simple map
- Push notifications: table invites, drop nudges, reactions

**Later:**
- Group swipe to pick a place
- Live now rail and heatmap
- Table reveal animations
- Streaks, badges, leaderboards, Term Wrapped
- Home-screen widget
- Co-op city expansion
- Reservation deep links
- Taste match %

## Open questions
- Who sees Drops in real time beyond the Table: close friends only, or all followers?
- Does a recap become public in the feed automatically, or does the user choose each time? (Leaning toward: default
  set in settings, overridable per post.)
- Should Explore be campus-only at launch, or city-wide (Waterloo Region)?
- Monetization (not v1): restaurant partnerships and student deals, rather than paywalls or streak restores.
