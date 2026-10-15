# BigBack Design System

_Owner direction (2026-10-15):_
- simple but fun;
- Apple iOS design best practices;
- **British racing green** as the accent;
- minimalism with good motion;
- a BeReal-like camera;
- everything chosen so the app is accepted by the App Store.

## 1. Principles
1. **Native first.** Built from SwiftUI system components, following the Human Interface Guidelines:
   - SF Pro and SF Symbols;
   - system colours for surfaces and text;
   - native navigation, sheets, menus and haptics.

   The app should feel like it shipped with the iPhone. Native components also get Dynamic Type, Dark Mode, VoiceOver and new OS visuals (e.g. Liquid Glass) for free, and App Review expects them.
2. **Content is the colour.** Food photos carry the energy. The UI stays quiet: neutral surfaces, one green accent, lots of space.
3. **Fun lives in motion and copy, not decoration.** Springy transitions, a satisfying swipe, a score that counts up, a playful one-liner. No gradients, glows or clutter.
4. **One primary action per screen.** Every screen has one obvious thing to do (snap, rate, go, RSVP), in green.
5. **Respect the person.**
   - Dark Mode and Dynamic Type up to accessibility sizes.
   - Reduce Motion and Reduce Transparency honoured.
   - 44 pt minimum tap targets.
   - Colour is never the only signal.

## 2. Colour

### Brand
| Token | Light | Dark | Use |
|---|---|---|---|
| `accent` | **#004225** (British racing green) | **#3FA46E** | Primary buttons, selected states, links, app tint |
| `accentPressed` | #00301B | #2F8A5A | Pressed state |
| `accentSoft` | #E4F0E8 | #12291E | Tinted backgrounds (selected chip, toast) |
| `onAccent` | #FFFFFF | #04140C | Text/icons on `accent` (contrast ≥ 7:1 light, ≥ 4.5:1 dark) |
| `celebrate` | #E9A83B | #F2B95A | Used sparingly: streak flame, new #1, confetti |

### Surfaces and text: iOS system colours only
| Use | Token |
|---|---|
| Screen background | `systemBackground` (feed and camera use pure black) |
| Grouped background | `systemGroupedBackground` (Settings-style lists: You, Activity) |
| Cards | `secondarySystemGroupedBackground` |
| Text | `label`, `secondaryLabel`, `tertiaryLabel` |
| Separators | `separator` |
| Destructive | `systemRed` (delete, report) |

### Reaction tiers
Each tier is told apart by **label, fill and colour**, never colour alone:

| Tier | Badge | Light | Dark |
|---|---|---|---|
| Loved it · 8–10 | Filled | `accent` + white text | `accent` + dark text |
| Good · 6–7.9 | Tinted | `accentSoft` + `accent` text | same |
| Mid · 4–5.9 | Outline | `systemGray5` + `label` | same |
| Nah · 0–3.9 | Outline, dashed | `systemGray6` + `secondaryLabel` | same |

Contrast targets: body text ≥ 4.5:1, large text and icons ≥ 3:1. Every pairing above meets WCAG AA in both modes.

## 3. Typography
- **SF Pro** through Dynamic Type text styles only (`.largeTitle` … `.caption2`), so text scales with the user's setting.
- **SF Pro Rounded** (`.fontDesign(.rounded)`) for the fun layer: large titles, scores, counts and the wordmark. It's friendly, not childish (Apple Fitness uses the same approach).
- Scores: `.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()`, animated with `.contentTransition(.numericText())`.
- Weights: Regular for body, Semibold for headlines, Bold only for scores and titles.
- Line length: at most about 60 characters for notes and captions.

| Role | Style |
|---|---|
| Screen title | `.largeTitle` rounded, bold (collapses to inline on scroll: native) |
| Place name on a card | `.title2` rounded, semibold |
| Section header | `.headline` |
| Body / notes | `.body` |
| Meta (distance, time, friends) | `.subheadline` `secondaryLabel` |
| Chips, badges | `.footnote` semibold |

## 4. Layout, shape, materials
- **Grid:** 4 pt base. Screen margins 16 pt (20 pt on Max sizes, via `.contentMargins`). Spacing between groups: 8 / 12 / 16 / 24.
- **Corners:** always continuous (`RoundedRectangle(style: .continuous)`):
  - 12 pt for chips and thumbnails;
  - 20 pt for cards;
  - 28 pt for the camera preview and full-bleed post media (concentric with the device corners).
- **Materials:**
  - System materials and Liquid Glass (iOS 26+) for floating controls: the tab bar, the camera button accessory, overlays on photos.
  - On iOS 18, fall back to `.ultraThinMaterial`.
  - Never put text on a raw photo without a material or scrim behind it.
- **Icons:** SF Symbols only, hierarchical rendering, tinted `accent` when selected. Custom glyphs (the wordmark) are drawn to SF Symbol metrics.
- **Imagery:** food photos are full-bleed with no frames. The selfie inset is a 28 pt-radius rounded rectangle with a 2 pt white stroke (BeReal-style).

## 5. Navigation (HIG-compliant)
- **Tab bar** (native `TabView`), 4 tabs: **Feed · Tonight · Activity · You**. Per the HIG, tabs are for navigation, not actions.
- **The camera is an action, not a tab.** It's a prominent green **Snap** button in the tab view's bottom accessory (`tabViewBottomAccessory` on iOS 26+; a floating glass capsule above the tab bar on iOS 18). While a meal is live, the same accessory becomes the **Live meal** pill ("Kinkaku · 0:42 · 3 snaps"), like Music's mini player. One tap opens the camera.
- **Full-screen flows** (`.fullScreenCover`): camera, rate flow, Let's eat.
- **Sheets with detents** (`.presentationDetents([.medium, .large])`): plan details, What to order, place quick-look, filters.
- **Context menus and `Menu`** for secondary actions on posts: Save, Share, Go here, **Report**, **Block**.
- **Large titles** collapse on scroll. Swipe-back works everywhere: no custom back buttons.

## 6. Motion
Motion explains what happened, never just decorates, and every animation is interruptible.

| Token | SwiftUI | Use |
|---|---|---|
| `snap` | `.snappy(duration: 0.25)` | Chip selection, toggles, small state changes |
| `smooth` | `.smooth(duration: 0.35)` | Sheet content, list reorder, tab content |
| `bouncy` | `.bouncy(duration: 0.5, extraBounce: 0.1)` | Celebration only: new #1, It's a match!, streak |
| `reveal` | `.spring(response: 0.55, dampingFraction: 0.82)` | Table Verdict reveal, score count-up |

**Signature moments:**
- **Shutter:**
  - The white ring compresses on press (scale 0.92).
  - A soft flash fades from 40% white over 150 ms.
  - The front-camera inset "drops" into its corner with `snap`.
  - Haptic: `.impact(weight: .medium)`.
- **This-or-That:**
  - Cards follow the finger with slight rotation (max 8°) and a green or grey edge glow showing which side is winning.
  - Release past 35% of the width = choose. The winner card scales 1.04, the loser slides away.
  - Haptic: `.selection` on crossing the threshold, `.impact` on choose.
- **Payoff:**
  - `matchedGeometryEffect` flies the winning card into its slot in the ranked list.
  - The neighbouring rows shift with `smooth`.
  - The score counts up with `.numericText()`.
  - The "New #2 in Late Night" title arrives with `bouncy`.
- **Save:** bookmark `symbolEffect(.bounce)`, with `.success` haptic on first save.
- **It's a match!:** the two candidate cards converge, then a `celebrate`-coloured confetti burst (`PhaseAnimator`, 600 ms, about 20 particles), with `.success` haptic.
- **Tab/screen changes:** system defaults only. Don't fight the platform.
- **Reduce Motion:**
  - springs become 200 ms crossfades;
  - confetti and card rotation are off;
  - the numeric content transition stays (it isn't vestibular).

## 7. Haptics (`.sensoryFeedback`)
| Moment | Feedback |
|---|---|
| Shutter | `.impact(weight: .medium)` |
| Swipe crosses the decision threshold | `.selection` |
| Choice made / RSVP | `.impact(weight: .light)` |
| New #1, match, streak | `.success` |
| Error (offline, failed upload) | `.error` |

Haptics are never fired on scroll or for passive updates.

## 8. Components
| Component | Spec |
|---|---|
| **Primary button** | Capsule, 50 pt high, `accent` fill, `.headline` `onAccent`; full-width in flows. iOS 26: `.buttonStyle(.glassProminent)` tinted `accent`. |
| **Secondary button** | `.bordered`, tinted `accent` |
| **Chip** | 32 pt, capsule, `.footnote` semibold. Unselected: `tertiarySystemFill`; selected: `accent` / `onAccent` with `snap` |
| **Score badge** | Rounded rect 12 pt, rounded bold digits, tier fill per §2, plus a tier label underneath for accessibility |
| **Post (feed)** | Full-bleed 4:5 photo with the selfie inset top-left; place, score badge and author on a glass bar at the bottom; actions in a trailing vertical stack (Save, Go here, Comment), each 44 pt |
| **Pick card (Tonight)** | Card 20 pt: photo 16:9, then name (`title3` rounded), one reason line, meta line, and a trailing **Go** button |
| **List row (rankings)** | Native `List` row: rank (rounded, secondary), thumbnail 44 pt, name/meta, score badge; drag to reorder (`.onMove`) |
| **Empty states** | `ContentUnavailableView` with an SF Symbol, one sentence and one action |
| **Toasts** | Small glass capsule at the top, 2 s, VoiceOver-announced |

## 9. The camera (BeReal-style)
- **Canvas:** pure black, status bar hidden.
- **Top bar:**
  - leading close button (`xmark`, 44 pt);
  - centre: the "BigBack" wordmark in rounded bold, and below it the live pill "● Kinkaku Izakaya · 0:42";
  - trailing: tagged friends' avatars.
- **Preview:**
  - Rear camera at 3:4, full width minus 8 pt margins, 28 pt continuous corners.
  - Front camera inset top-left, 30% width, 2 pt white stroke. Draggable to any corner, where it snaps; tap to swap which camera is big.
- **Bottom controls:**
  - centre: an 80 pt white-ring shutter;
  - left: flash (`bolt.slash`);
  - right: flip (`arrow.triangle.2.circlepath.camera`).
  - **No countdown timer** (owner decision).
- **Moments** are a single quiet row of chips above the shutter: Walk-in · Order · Food · Crew · Damage report.
- **After the snap:**
  - The dual photo appears with the inset.
  - **Dish chips** slide up ("What's that?") from the place's menu.
  - Then **Keep** (green) / **Retake**.
- **Capture rules:**
  - Simultaneous dual capture on supported devices; elsewhere a quick back-then-front sequence with a 200 ms flip animation.
  - Never sound-free in regions that legally require a shutter sound: use the system capture APIs, which handle this.
- **Library import:** allowed for non-live photos (no live badge), via `PhotosPicker`. No full photo-library permission is needed.

## 10. Voice and copy
- **Short, warm, a bit cheeky:** "Big back behaviour.", "Who's down?", "That's a match.", "Clean plate. Respect."
- **Jokes are about appetite and food, never bodies or weight.** This keeps the brand inclusive and avoids content-policy trouble.
- **Permission prompts use plain benefits:**
  - Camera: "BigBack uses the camera to snap your meal and your face at the same time."
  - Location: "Shows how far spots are and suggests the place you're at. Your location is never shared with other people."

## 11. Accessibility checklist (every screen)
- [ ] Dynamic Type through AX5: layouts reflow, no truncated scores.
- [ ] VoiceOver:
  - [ ] every image has a label ("Photo of tonkotsu ramen by Maya");
  - [ ] the swipe deck has accessibility actions ("Choose Kinkaku", "Choose Gol's", "Too close").
- [ ] Reduce Motion and Reduce Transparency respected.
- [ ] Contrast meets AA in light and dark.
- [ ] Hit targets ≥ 44 × 44 pt.
- [ ] No information by colour alone.
