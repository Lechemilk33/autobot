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
    var fightNote = ""

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
    /// Ratings + yes/no questions + weight + the two photos.
    static let questionCount = 12

    var answeredCount: Int {
        let ratings = [mood, energy, sexDrive].compactMap { $0 }.count
        let answers = [workedOut, drankGallonOfWater, drankAlcohol, smokedWeed, hadSex, fought].compactMap { $0 }.count
        return ratings + answers + (weight == nil ? 0 : 1) + photoCount
    }

    var photoCount: Int { [facePhoto, bodyPhoto].compactMap { $0 }.count }

    /// True with no alcohol and no weed, false if either was a yes, nil until both are answered.
    var isSober: Bool? {
        if drankAlcohol == true || smokedWeed == true { return false }
        if drankAlcohol == false && smokedWeed == false { return true }
        return nil
    }
}
