import SwiftUI
import SwiftData

/// The Today tab: today's check-in, with a date picker to fill in a missed day.
struct TodayView: View {
    @State private var day = Date.now
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            CheckInView(day: day)
                .id(Calendar.current.startOfDay(for: day))
                .toolbar {
                    DatePicker("Day", selection: $day, in: ...Date.now, displayedComponents: .date)
                        .labelsHidden()
                }
        }
        // Jump back to today when the app is reopened, so a check-in
        // never lands on yesterday by accident.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { day = .now }
        }
    }
}

/// Loads the entry for one day, creating it the first time the day is opened.
struct CheckInView: View {
    let day: Date
    @Query private var matches: [DayEntry]
    @Environment(\.modelContext) private var context
    @AppStorage(Challenge.startKey) private var challengeStart: Double = 0

    init(day: Date) {
        let start = Calendar.current.startOfDay(for: day)
        self.day = start
        _matches = Query(filter: #Predicate<DayEntry> { $0.day == start })
    }

    var body: some View {
        Group {
            if let entry = matches.first {
                CheckInForm(entry: entry)
            } else {
                ProgressView()
                    .onAppear(perform: createEntry)
            }
        }
        .navigationTitle(Challenge.title(for: day, start: challengeStart))
    }

    private func createEntry() {
        // `day` is unique, so inserting over an existing entry would wipe its answers.
        let day = day
        let existing = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.day == day })
        guard (try? context.fetchCount(existing)) == 0 else { return }
        context.insert(DayEntry(day: day))
        try? context.save()
    }
}

struct CheckInForm: View {
    @Bindable var entry: DayEntry

    var body: some View {
        Form {
            Section {
                RatingPicker(title: "Mental health", value: $entry.mentalHealth)
                RatingPicker(title: "Energy", value: $entry.energy)
            } header: {
                Text(entry.day, format: .dateTime.weekday(.wide).month().day())
            }

            Section("Did I…") {
                YesNoPicker(title: "Work out", value: $entry.workedOut)
                YesNoPicker(title: "Drink", value: $entry.drank)
                YesNoPicker(title: "Smoke weed", value: $entry.smokedWeed)
                YesNoPicker(title: "Have sex", value: $entry.hadSex)
            }
        }
    }
}

struct RatingPicker: View {
    let title: String
    @Binding var value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            Picker(title, selection: $value) {
                ForEach(1...10, id: \.self) { n in
                    Text("\(n)").tag(Int?.some(n))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

struct YesNoPicker: View {
    let title: String
    @Binding var value: Bool?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: $value) {
                Text("Yes").tag(Bool?.some(true))
                Text("No").tag(Bool?.some(false))
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }
}
