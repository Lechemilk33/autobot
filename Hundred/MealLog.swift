import Foundation
import SwiftData

/// Whether each planned meal was eaten, one log per calendar day.
/// nil means not answered yet, so a forgotten meal never counts as skipped.
@Model
final class MealLog {
    @Attribute(.unique) var day: Date

    var morning: Bool? = nil
    var lunch: Bool? = nil
    var smoothie: Bool? = nil
    var dinner: Bool? = nil
    var evening: Bool? = nil

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
    }
}

extension MealLog {
    subscript(meal: Meal) -> Bool? {
        get {
            switch meal {
            case .morning: morning
            case .lunch: lunch
            case .smoothie: smoothie
            case .dinner: dinner
            case .evening: evening
            }
        }
        set {
            switch meal {
            case .morning: morning = newValue
            case .lunch: lunch = newValue
            case .smoothie: smoothie = newValue
            case .dinner: dinner = newValue
            case .evening: evening = newValue
            }
        }
    }

    /// The log for `date`, created if it doesn't exist yet. `day` is unique,
    /// so inserting a second log for a day would wipe the first one's answers.
    @discardableResult
    static func forDay(_ date: Date, in context: ModelContext) -> MealLog {
        let day = Calendar.current.startOfDay(for: date)
        let existing = FetchDescriptor<MealLog>(predicate: #Predicate { $0.day == day })
        if let log = try? context.fetch(existing).first {
            return log
        }
        let log = MealLog(day: day)
        context.insert(log)
        return log
    }
}
