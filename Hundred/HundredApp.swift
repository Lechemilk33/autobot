import SwiftUI
import SwiftData

@main
struct HundredApp: App {
    init() {
        // Day 1 is the first day the app is opened; it can be changed in History.
        if UserDefaults.standard.object(forKey: Challenge.startKey) == nil {
            UserDefaults.standard.set(Calendar.current.startOfDay(for: .now).timeIntervalSince1970,
                                      forKey: Challenge.startKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView()
                    .tabItem { Label("Today", systemImage: "checkmark.circle") }
                HistoryView()
                    .tabItem { Label("History", systemImage: "calendar") }
            }
        }
        .modelContainer(for: DayEntry.self)
    }
}

enum Challenge {
    static let length = 100
    static let startKey = "challengeStart"

    /// 1 on the start date, 2 the day after, and so on.
    static func dayNumber(of date: Date, start: Double) -> Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: Date(timeIntervalSince1970: start))
        let to = calendar.startOfDay(for: date)
        return (calendar.dateComponents([.day], from: from, to: to).day ?? 0) + 1
    }

    static func title(for date: Date, start: Double) -> String {
        let day = dayNumber(of: date, start: start)
        return day >= 1 ? "Day \(day) of \(length)" : "Before Day 1"
    }
}
