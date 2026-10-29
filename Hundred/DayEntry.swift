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
    /// How good the workout was, 1-10. Only meaningful when `workedOut` is true.
    var workoutScore: Int? = nil
    var drankGallonOfWater: Bool? = nil
    var drankAlcohol: Bool? = nil
    var smokedWeed: Bool? = nil
    var hadSex: Bool? = nil
    var fought: Bool? = nil
    var fightNote = ""

    // The daily minimum: 50 pushups, 50 situps, 25 leg lifts. One checklist item
    // made of three parts, so it can't be ticked off until all three are done.
    var pushups: Bool? = nil
    var situps: Bool? = nil
    var legLifts: Bool? = nil

    // Caffeine, counted. 0 means "none today"; nil still means unanswered.
    var coffeeCups: Int? = nil
    var energyDrinks: Int? = nil

    // Taken in the app and kept in this database, never in the camera roll.
    // .externalStorage keeps the JPEG bytes in files beside the store rather
    // than inside its rows, so loading a day's answers stays cheap.
    @Attribute(.externalStorage) var facePhoto: Data? = nil
    @Attribute(.externalStorage) var bodyPhoto: Data? = nil

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
    }
}

extension DayEntry {
    /// 3 ratings + 6 yes/no + the daily sets + 2 caffeine counts + weight + 2 photos,
    /// and on a day you worked out, the workout score as well. It varies per day, so
    /// the ring can still reach full on a rest day.
    var questionCount: Int { 15 + (workedOut == true ? 1 : 0) }

    var answeredCount: Int {
        let ratings = [mood, energy, sexDrive].compactMap { $0 }.count
        let answers = [workedOut, drankGallonOfWater, drankAlcohol, smokedWeed, hadSex, fought].compactMap { $0 }.count
        let caffeine = [coffeeCups, energyDrinks].compactMap { $0 }.count
        let score = (workedOut == true && workoutScore != nil) ? 1 : 0
        let sets = didDailySets ? 1 : 0
        return ratings + answers + caffeine + score + sets + (weight == nil ? 0 : 1) + photoCount
    }

    var photoCount: Int { [facePhoto, bodyPhoto].compactMap { $0 }.count }

    /// The daily sets only count once all three are done — that's the whole point
    /// of them being one item, so there is no way to tick it off part-finished.
    var didDailySets: Bool { pushups == true && situps == true && legLifts == true }

    /// True with no alcohol and no weed, false if either was a yes, nil until both are answered.
    var isSober: Bool? {
        if drankAlcohol == true || smokedWeed == true { return false }
        if drankAlcohol == false && smokedWeed == false { return true }
        return nil
    }
}
