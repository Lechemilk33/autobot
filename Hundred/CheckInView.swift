import SwiftUI
import SwiftData

/// The Today tab: today's check-in, with a calendar to fill in a missed day.
struct TodayView: View {
    @State private var day = Date.now
    @State private var showingCalendar = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            CheckInView(day: day)
                .id(Calendar.current.startOfDay(for: day))
                .toolbar {
                    if !Calendar.current.isDateInToday(day) {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Today") { day = .now }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pick a day", systemImage: "calendar") { showingCalendar = true }
                    }
                }
                .sheet(isPresented: $showingCalendar) {
                    DatePicker("Day", selection: $day, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .presentationDetents([.medium])
                }
        }
        // Jump back to today when the app is reopened, so a check-in
        // never lands on yesterday by accident.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { day = .now }
        }
        .onChange(of: day) { showingCalendar = false }
    }
}

/// Loads the entry for one day, creating it the first time the day is opened.
struct CheckInView: View {
    let day: Date
    @Query private var matches: [DayEntry]
    @Environment(\.modelContext) private var context

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
                Color.clear
                    .onAppear(perform: createEntry)
            }
        }
        .background { AmbientBackground() }
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
    @AppStorage(Challenge.startKey) private var challengeStart: Double = 0
    @FocusState private var focus: Field?

    private enum Field { case weight, fightNote }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DayHeader(day: entry.day,
                          dayNumber: Challenge.dayNumber(of: entry.day, start: challengeStart),
                          answered: entry.answeredCount)
                    .padding(.horizontal, 4)

                GlassCard("How you feel") {
                    RatingRow(title: "Mood", symbol: "face.smiling", color: .purple, value: $entry.mood)
                    RatingRow(title: "Energy", symbol: "bolt.fill", color: .orange, value: $entry.energy)
                    RatingRow(title: "Sex drive", symbol: "flame.fill", color: .pink, value: $entry.sexDrive)
                }

                GlassCard("Checklist") {
                    YesNoRow(title: "Worked out", symbol: "figure.run", color: .red,
                             goal: true, value: $entry.workedOut)
                    YesNoRow(title: "Gallon of water", symbol: "drop.fill", color: .cyan,
                             goal: true, value: $entry.drankGallonOfWater)
                    YesNoRow(title: "Drank alcohol", symbol: "wineglass.fill", color: .purple,
                             goal: false, value: $entry.drankAlcohol)
                    YesNoRow(title: "Smoked weed", symbol: "leaf.fill", color: .green,
                             goal: false, value: $entry.smokedWeed)
                    YesNoRow(title: "Had sex", symbol: "heart.fill", color: .pink,
                             goal: nil, value: $entry.hadSex)
                    YesNoRow(title: "Fight or argument", symbol: "cloud.bolt.rain.fill", color: .yellow,
                             goal: false, value: $entry.fought)
                    if entry.fought == true {
                        TextField("What happened?", text: $entry.fightNote, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($focus, equals: .fightNote)
                            .padding(12)
                            .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 16))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                GlassCard("Photos") {
                    PhotoRow(face: $entry.facePhoto, body_: $entry.bodyPhoto)
                }

                GlassCard("Weight") {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        TextField("0.0", value: $entry.weight, format: .number.precision(.fractionLength(0...1)))
                            .font(.system(size: 44, weight: .bold))
                            .keyboardType(.decimalPad)
                            .focused($focus, equals: .weight)
                            .fixedSize()
                        Text("lb")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "scalemass.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { focus = .weight }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            // The decimal pad has no return key, so give the keyboard a way to close.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }
}

/// "Day 12 / 100", the challenge progress bar, and today's completion ring.
struct DayHeader: View {
    let day: Date
    let dayNumber: Int
    let answered: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(day, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(dayNumber >= 1 ? "Day \(dayNumber)" : "Day –")
                        .font(.system(size: 50, weight: .bold))
                    Text("/ \(Challenge.length)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ChallengeBar(progress: Double(dayNumber) / Double(Challenge.length))
            }
            Spacer(minLength: 0)
            CompletionRing(answered: answered, total: DayEntry.questionCount)
        }
    }
}

struct ChallengeBar: View {
    let progress: Double

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.12))
            .frame(maxWidth: 220)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(LinearGradient(colors: [.mint, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
            }
    }
}

struct CompletionRing: View {
    let answered: Int
    let total: Int

    private var isComplete: Bool { answered >= total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(answered) / CGFloat(total))
                .stroke(AngularGradient(colors: [.cyan, .mint, .cyan], center: .center),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.mint)
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 0) {
                    Text("\(answered)")
                        .font(.title3.weight(.bold))
                        .contentTransition(.numericText())
                    Text("of \(total)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 72, height: 72)
        .padding(10)
        .glassEffect(.regular, in: .circle)
        .animation(.snappy, value: answered)
        .sensoryFeedback(.success, trigger: isComplete) { _, done in done }
    }
}
