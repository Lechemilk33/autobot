import Foundation
import SwiftData

/// One check-in per calendar day. Every answer starts as nil ("not answered")
/// so a skipped question never gets counted as a "no".
@Model
final class DayEntry {
    @Attribute(.unique) var day: Date

    // 1–10
    var mood: Int? = nil
    var energy: Int? = nil
    var sexDrive: Int? = nil

    // Pounds
    var weight: Double? = nil

    // Yes / no
    var workedOut: Bool? = nil
    var drankGallonOfWater: Bool? = nil
    var drankAlcohol: Bool? = nil
    var smokedWeed: Bool? = nil
    var hadSex: Bool? = nil
    var fought: Bool? = nil

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
    }
}
