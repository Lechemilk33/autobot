import SwiftUI
import SwiftData
import UserNotifications

@main
struct HundredApp: App {
    /// Shared with the notification handler, which logs meals from a reminder
    /// without opening the app. Same default store as before, so existing data carries over.
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: DayEntry.self, MealLog.self)
        } catch {
            fatalError("Couldn't open the data store: \(error)")
        }
    }()

    init() {
        // Day 1 is the first day the app is opened; it can be changed on the Progress tab.
        if UserDefaults.standard.object(forKey: Challenge.startKey) == nil {
            UserDefaults.standard.set(Calendar.current.startOfDay(for: .now).timeIntervalSince1970,
                                      forKey: Challenge.startKey)
        }
        UNUserNotificationCenter.current().delegate = MealNotificationHandler.shared
        MealReminders.registerActions()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Self.container)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "checkmark.circle.fill") {
                TodayView()
            }
            Tab("Meals", systemImage: "fork.knife") {
                MealsView()
            }
            Tab("Groceries", systemImage: "cart.fill") {
                GroceriesView()
            }
            Tab("Progress", systemImage: "circle.grid.3x3.fill") {
                ProgressScreen()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.mint)
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
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
}

#Preview {
    RootView()
        .modelContainer(for: [DayEntry.self, MealLog.self], inMemory: true)
}
