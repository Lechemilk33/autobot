import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DayEntry.day, order: .reverse) private var entries: [DayEntry]
    @AppStorage(Challenge.startKey) private var challengeStart: Double = 0

    private var startDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: challengeStart) },
            set: { challengeStart = Calendar.current.startOfDay(for: $0).timeIntervalSince1970 }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Day 1 was", selection: startDate, displayedComponents: .date)
                }

                Section {
                    ForEach(entries) { entry in
                        NavigationLink {
                            CheckInView(day: entry.day)
                        } label: {
                            HistoryRow(entry: entry, title: Challenge.title(for: entry.day, start: challengeStart))
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct HistoryRow: View {
    let entry: DayEntry
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(entry.day, format: .dateTime.month().day())
                    .foregroundStyle(.secondary)
            }
            Text("Mood \(rating(entry.mood)) · Energy \(rating(entry.energy)) · Drive \(rating(entry.sexDrive)) · \(weight) lb")
            Text("Workout \(answer(entry.workedOut)) · Water \(answer(entry.drankGallonOfWater)) · Alcohol \(answer(entry.drankAlcohol)) · Weed \(answer(entry.smokedWeed)) · Sex \(answer(entry.hadSex)) · Fight \(answer(entry.fought))")
        }
        .font(.subheadline)
    }

    private var weight: String {
        entry.weight?.formatted(.number.precision(.fractionLength(0...1))) ?? "–"
    }

    private func rating(_ value: Int?) -> String {
        value.map(String.init) ?? "–"
    }

    private func answer(_ value: Bool?) -> String {
        switch value {
        case true?: "Y"
        case false?: "N"
        case nil: "–"
        }
    }
}
