import Foundation
import UserNotifications

/// One daily notification per meal. Long-pressing it offers "Ate it" and
/// "Skipped", which log the answer without opening the app.
enum MealReminders {
    static let enabledKey = "mealRemindersOn"
    static let categoryID = "MEAL"
    static let ateAction = "ATE"
    static let skippedAction = "SKIPPED"

    static func registerActions() {
        let ate = UNNotificationAction(identifier: ateAction, title: "Ate it", options: [])
        let skipped = UNNotificationAction(identifier: skippedAction, title: "Skipped", options: [])
        let category = UNNotificationCategory(identifier: categoryID, actions: [ate, skipped],
                                              intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Minutes after midnight.
    static func minutes(for meal: Meal) -> Int {
        UserDefaults.standard.object(forKey: timeKey(meal)) as? Int ?? meal.defaultMinutes
    }

    static func time(for meal: Meal) -> Date {
        let total = minutes(for: meal)
        return Calendar.current.date(bySettingHour: total / 60, minute: total % 60, second: 0, of: .now) ?? .now
    }

    static func setTime(_ date: Date, for meal: Meal) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set((parts.hour ?? 0) * 60 + (parts.minute ?? 0), forKey: timeKey(meal))
        reschedule()
    }

    /// Replaces every pending meal reminder with the current times and menu.
    static func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Meal.allCases.map(\.rawValue))
        guard UserDefaults.standard.bool(forKey: enabledKey) else { return }

        for planned in MealPlan.meals(for: .current) {
            let content = UNMutableNotificationContent()
            content.title = planned.when
            content.body = "\(planned.name). Did you eat it?"
            content.sound = .default
            content.categoryIdentifier = categoryID
            content.userInfo = ["meal": planned.meal.rawValue]

            let total = minutes(for: planned.meal)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: total / 60, minute: total % 60), repeats: true)
            center.add(UNNotificationRequest(identifier: planned.meal.rawValue, content: content, trigger: trigger))
        }
    }

    private static func timeKey(_ meal: Meal) -> String { "mealTime." + meal.rawValue }
}

/// Shows meal reminders while the app is open, and saves "Ate it" / "Skipped"
/// straight from the notification.
final class MealNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MealNotificationHandler()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let ate: Bool
        switch response.actionIdentifier {
        case MealReminders.ateAction: ate = true
        case MealReminders.skippedAction: ate = false
        default:
            completionHandler()
            return
        }
        guard let raw = response.notification.request.content.userInfo["meal"] as? String,
              let meal = Meal(rawValue: raw) else {
            completionHandler()
            return
        }
        let day = response.notification.date

        Task { @MainActor in
            let context = HundredApp.container.mainContext
            let log = MealLog.forDay(day, in: context)
            log[meal] = ate
            try? context.save()
            completionHandler()
        }
    }
}
