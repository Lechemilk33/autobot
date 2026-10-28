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
- Yes/No: Worked out, Gallon of water, Drank alcohol, Smoked weed, Had sex,
  Fight or argument (a short note field appears when Yes)
- Weight in lb
- "Sober" = no alcohol **and** no weed (`isSober` is nil until both are answered)

Not tracked on purpose: food, exact water amount, sleep (the Oura ring already has it).

## Files

| File | What's in it |
|---|---|
| `Hundred/HundredApp.swift` | App entry, `RootView` (Today + Progress tabs), `Challenge` helpers. Day 1 date is a `UserDefaults` double under key `challengeStart`. |
| `Hundred/DayEntry.swift` | SwiftData model, one per day (`@Attribute(.unique) var day`), plus `answeredCount` / `isSober`. |
| `Hundred/CheckInView.swift` | Today tab: the check-in form, "Day N / 100" header, completion ring. |
| `Hundred/Controls.swift` | 1–10 `RatingRow`, `YesNoRow` (mint when on track, orange when not). Tapping the selected answer clears it back to nil. |
| `Hundred/ProgressScreen.swift` | Sober streak / totals tiles, 10×10 grid of the 100 days (tap a day to edit it), Day 1 picker. |
| `Hundred/Theme.swift` | Animated `MeshGradient` background, `GlassCard`, `IconBadge`. |

**Design rule:** glass is for cards, the ring, tiles and bars only. Controls *inside* a card use
solid fills (`Color.white.opacity(0.08)`) — no glass on glass.

`DayEntry.questionCount` is 10 and must stay in sync with `answeredCount`, or the completion
ring never fills.

## How the user wants to work

- Keep it a quick checklist, under a minute a day. No food logging. Don't overbuild.
- **Ask before adding new questions or features.**
- They know their way around code; keep explanations short.

## Later list — don't start these until asked

- Daily face selfie + body photo, taken in the app, stored privately in SwiftData (not the camera roll)
- Sleep from the Oura ring automatically: Apple Health (HealthKit may need the paid dev account) or Oura's API
- Charts of mood/energy over time
- Daily reminder notification (check in + photos)
- Backup/export, since data lives only on the phone
- An app icon (Liquid Glass style)

## Repo

- `https://github.com/Lechemilk33/autobot`, working branch `claude/friendly-cerf-itx61q`.
- The repo's **default branch is an old, unrelated tax-calculator project** — ignore it.
  An old tax site is also still served from the `gh-pages` branch.
