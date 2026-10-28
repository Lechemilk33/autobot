# 100 Days

A personal iPhone app for a 100-day challenge: a quick daily check-in, all stored on the phone.
Built with SwiftUI + SwiftData (iOS 17+), no third-party dependencies.

## Daily check-in

| Question                | Answer |
|-------------------------|--------|
| Mood                    | 1–10   |
| Energy                  | 1–10   |
| Sex drive               | 1–10   |
| Work out                | Yes/No |
| Drink a gallon of water | Yes/No |
| Drink alcohol           | Yes/No |
| Smoke weed              | Yes/No |
| Have sex                | Yes/No |
| Fight or argue          | Yes/No |
| Weight                  | lb     |

Not tracked on purpose: food, exact water amount, sleep (already tracked by the Oura ring).

Unanswered questions stay blank (–) instead of counting as "No".
The **Today** tab has a date picker for filling in a missed day; **History** lists every day and sets which date was Day 1.

## Run it on your iPhone (free Apple ID)

1. On the Mac, install Xcode 16 or newer from the App Store, then clone this repo and open `Hundred.xcodeproj`.
2. Xcode → Settings → Accounts → add your Apple ID.
3. Select the **Hundred** target → **Signing & Capabilities** → set **Team** to your Personal Team.
   If Xcode says the bundle ID is taken, change `com.lechemilk33.hundred` to anything unique.
4. Plug in the iPhone, pick it as the run destination, press ▶︎.
   First time only: enable Settings → Privacy & Security → **Developer Mode**, and trust the developer certificate under Settings → General → VPN & Device Management.

With a free account the install expires after 7 days — plug in and press ▶︎ again.
Your data is kept as long as you **don't delete the app**.

## Later (not built yet)

- Daily photos: a quick face selfie and a body photo, taken in the app with the camera.
  Stored privately inside the app (SwiftData, same on-phone database as the check-ins), not in the camera roll
- Sleep pulled in from the Oura ring automatically, no typing — via Apple Health
  (Oura syncs there; reading it may need the paid developer account) or Oura's own API
- Streaks and totals (sober days, workouts this week)
- Charts of mood/energy over time
- A daily reminder notification (check in + take photos)
- Backup/export, since everything lives only on the phone
- More questions
