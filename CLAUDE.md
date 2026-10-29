# 100 Days — project context

A personal iPhone app: a 100-day challenge tracker (exercise, sobriety, etc.) with a quick
daily check-in. All data lives on the phone. SwiftUI + SwiftData, iOS 26, no third-party
dependencies. Dark-only Liquid Glass design.

## Build

- Xcode 26+ required (iOS 26 for Liquid Glass). Target/scheme: `Hundred`.
- Bundle ID: `com.lechemilk33.hundred`. Deployment target iOS 26.0, iPhone only, portrait only.
- `Hundred.xcodeproj` is hand-written and uses Xcode 16+ synchronized folders
  (`PBXFileSystemSynchronizedRootGroup`), so **any file added under `Hundred/` is compiled
  automatically** — no pbxproj edit needed. If Xcode ever can't open the project, recreate a
  fresh SwiftUI App project named `Hundred` and drop the `Hundred/` files in.

```sh
xcodebuild -project Hundred.xcodeproj -scheme Hundred -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Device installs use free Personal Team signing (7-day expiry; re-run from Xcode to renew).
Deleting the app deletes the data — there is no backup yet.

## Daily check-in

Every answer is optional. **nil = unanswered and never counts as "No"** — this matters in
`answeredCount`, `isSober`, and the grid colors; don't collapse optionals to `false`.

- 1–10: Mood, Energy, Sex drive
- Daily sets, as **one** checklist item: 50 pushups, 50 situps, 25 leg lifts. The single
  check has no Yes/No and can't be tapped — it fills in only once all three are ticked, so
  the item can never be marked done while part of the work is still owed. It counts as one
  question in the ring, and only once all three are done.
- Yes/No: Worked out, Gallon of water, Drank alcohol, Smoked weed, Had sex,
  Fight or argument (a short note field appears when Yes)
- Workout score 1-10 ("How was it"), shown only when Worked out is Yes. Answering No or
  clearing it wipes the score, so a score never outlives the workout it described.
- Caffeine counts: Coffee (cups) and Energy drinks (cans), 0-6 each.
  These are the only two caffeine sources worth tracking - don't add more.
  **0 means "none today" and is a real answer; nil is still unanswered.**
- Weight in lb
- Two photos: Face (front camera) and Body (rear camera)
- "Sober" = no alcohol **and** no weed (`isSober` is nil until both are answered)

Not tracked on purpose: exact water amount, sleep (the Oura ring already has it).
Food is **planned, not logged** — see below. There is still no logging of what was eaten,
no calorie counting and no portion entry; a meal is one checkmark against a fixed menu.

## Meals and groceries

The same five meals every day, so there is nothing to choose, weigh or calculate:
coffee + eggs, beef + rice, a smoothie, chicken + rice, milk + granola
(~2,757 kcal, ~193 g protein). Ground beef is lunch because it cooks fast; chicken is
dinner because it takes longer. One 1 lb beef pack covers two lunches.

- **The plan is fixed.** `MealPlan.swift` is the single source for the menu, the macros and
  the grocery list. Change a meal there and the Meals tab, the totals and the shopping list
  all follow. Don't add meal choices, swaps or a food database.
- **No spinach** — the user doesn't eat it. Removed from the smoothie and the grocery list.
- `MealLog` mirrors `DayEntry`: one row per day, `true` means eaten, nil means unchecked.
- **Reminders are opt-in**, one per meal, off until the Reminders sheet is toggled on.
  "Ate it" on the notification checks the meal off without opening the app, which is why
  `HundredApp.container` is a static the notification handler can reach.
- Grocery checkmarks are a comma-joined id list in `UserDefaults`, not SwiftData —
  the list is a weekly scratch pad, not history worth keeping.

## Files

| File | What's in it |
|---|---|
| `Hundred/HundredApp.swift` | App entry, `RootView` (Today, Meals, Groceries, Progress tabs), `Challenge` helpers. Day 1 date is a `UserDefaults` double under key `challengeStart`. Holds the shared `ModelContainer` (`DayEntry` + `MealLog`) as a static so the notification handler can write without the app being open. |
| `Hundred/DayEntry.swift` | SwiftData model, one per day (`@Attribute(.unique) var day`), plus `answeredCount` / `isSober`. |
| `Hundred/CheckInView.swift` | Today tab: the check-in form, "Day N / 100" header, completion ring. |
| `Hundred/Controls.swift` | 1–10 `RatingRow`, `YesNoRow` (mint when on track, orange when not), 0–N `CountRow` for the caffeine counts. Tapping the selected answer clears it back to nil. |
| `Hundred/ProgressScreen.swift` | `StartDateCard` (Day 1 picker + "Make today Day 1"), sober streak / totals tiles, 10×10 grid of the 100 days (tap a day to edit it). |
| `Hundred/PhotoRow.swift` | The Photos card: two tappable slots. Long-press a filled slot to retake or remove. |
| `Hundred/PhotoCapture.swift` | `CameraPicker` (a `UIImagePickerController` wrapper) plus the JPEG downscaling. |
| `Hundred/MealPlan.swift` | The fixed menu, its macros, and the weekly grocery list. Edit meals here and everything else follows. |
| `Hundred/MealLog.swift` | SwiftData model, one per day: which meals were checked off. |
| `Hundred/MealsView.swift` | Meals tab: the five meals, protein/calories so far, and the Reminders sheet. |
| `Hundred/GroceriesView.swift` | Groceries tab: one week of the plan as a store checklist. |
| `Hundred/MealReminders.swift` | Scheduling the per-meal notifications and handling "Ate it". |
| `Hundred/Theme.swift` | Animated `MeshGradient` background, `GlassCard`, `IconBadge`. |

**Design rule:** glass is for cards, the ring, tiles and bars only. Controls *inside* a card use
solid fills (`Color.white.opacity(0.08)`) — no glass on glass.

`DayEntry.questionCount` must stay in sync with `answeredCount`, or the completion ring never
fills. It is **per entry, not a constant**: 14 normally (3 ratings + 6 yes/no + 2 caffeine +
weight + 2 photos + the daily sets), and 16 on a day you worked out, when the workout score joins
them. That
way the ring still reaches full on a rest day.

**The Day 1 card stays at the top of the Progress tab.** It used to sit below the 100-day
grid, which is taller than the screen, so in practice nobody could reach it — the user
couldn't work out how to make today Day 1. The "Make today Day 1" button is there so
setting the start needs one tap instead of a calendar. Don't move it back down.

**Before Day 1** the header reads "Starts tomorrow" / "Starts in N days" instead of a day
number, and the day stays editable so it can be used for a trial run. `Challenge.dayNumber`
returns 0 the day before Day 1 and goes negative before that.

**Photos:** stored as `@Attribute(.externalStorage) Data?` on `DayEntry`, downscaled to 1600px
JPEG at 0.8 quality before saving — full-resolution captures would run to hundreds of MB over
100 days. They live only in the app's SwiftData store, never the camera roll. The camera needs
`INFOPLIST_KEY_NSCameraUsageDescription` (set in both build configs). The **simulator has no
camera**, so `CameraPicker` falls back to the photo library there; that fallback is a
development convenience, not a feature.

## How the user wants to work

- Keep it a quick checklist, under a minute a day. Don't overbuild.
- No food *logging*. The meal plan is a fixed menu you tick off, which is why it fits
  that rule — don't turn it into calorie tracking or a food diary.
- **Ask before adding new questions or features.**
- They know their way around code; keep explanations short.

## Later list — don't start these until asked

- Sleep from the Oura ring automatically: Apple Health (HealthKit may need the paid dev account) or Oura's API
- Charts of mood/energy over time
- Daily reminder notification (check in + photos)
- Backup/export, since data lives only on the phone
- An app icon (Liquid Glass style)

## Repo

- `https://github.com/Lechemilk33/autobot`, working branch `claude/friendly-cerf-itx61q`.
- The repo's **default branch is an old, unrelated tax-calculator project** — ignore it.
  An old tax site is also still served from the `gh-pages` branch.
