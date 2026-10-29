# 100 Days

A personal iPhone app for a 100-day challenge: a quick daily check-in, all stored on the phone.
Built with SwiftUI + SwiftData and Apple's Liquid Glass design (iOS 26+), no third-party dependencies.

## Daily check-in

| Question                | Answer |
|-------------------------|--------|
| Mood                    | 1–10   |
| Energy                  | 1–10   |
| Sex drive               | 1–10   |
| 50 pushups, 50 situps, 25 leg lifts | one check, and only once all three are done |
| Work out                | Yes/No |
| How was the workout     | 1–10, only if you worked out |
| Drink a gallon of water | Yes/No |
| Drink alcohol           | Yes/No |
| Smoke weed              | Yes/No |
| Have sex                | Yes/No |
| Fight or argue          | Yes/No, short note if yes |
| Coffee                  | cups   |
| Energy drinks           | cans   |
| Weight                  | lb     |
| Face photo              | camera |
| Body photo              | camera |

Photos are taken in the app and kept inside it — they never reach the camera roll, and they
are downscaled before being saved so 100 days of them stay small.

Not tracked on purpose: exact water amount, sleep (already tracked by the Oura ring).
Food isn't *logged* either — the meal plan below is fixed, so meals get checked off, not written down.

Unanswered questions stay blank (–) instead of counting as "No".
**Today** is the check-in, with a calendar button for filling in a missed day.
**Progress** shows the sober streak, totals, and a 100-day grid (tap any day to open it), and sets which date was Day 1.

## Meal plan

The same five meals every day (≈ 2,757 kcal, ≈ 193 g protein), defined in `Hundred/MealPlan.swift`.

- **Meals** lists each meal with exactly what's in it and a checkmark to tap once it's eaten, with protein and calories so far.
  Optional notifications, one per meal: press and hold one and tap **Ate it** to check the meal off without opening the app.
- **Groceries** is one week of the plan as a checklist, split into "every week" and "restock when low".
- Every day is identical: ground beef at lunch (one 1 lb pack covers two lunches), chicken at dinner.

## Run it on your iPhone (free Apple ID)

1. On the Mac, install Xcode 26 or newer from the App Store (the iPhone needs iOS 26+), then clone this repo and open `Hundred.xcodeproj`.
2. Xcode → Settings → Accounts → add your Apple ID.
3. Select the **Hundred** target → **Signing & Capabilities** → set **Team** to your Personal Team.
   If Xcode says the bundle ID is taken, change `com.lechemilk33.hundred` to anything unique.
4. Plug in the iPhone, pick it as the run destination, press ▶︎.
   First time only: enable Settings → Privacy & Security → **Developer Mode**, and trust the developer certificate under Settings → General → VPN & Device Management.

With a free account the install expires after 7 days — plug in and press ▶︎ again.
Your data is kept as long as you **don't delete the app**.

## Later (not built yet)

- Sleep pulled in from the Oura ring automatically, no typing — via Apple Health
  (Oura syncs there; reading it may need the paid developer account) or Oura's own API
- Charts of mood/energy over time
- A daily reminder for the check-in and photos
- Backup/export, since everything lives only on the phone
- More questions
