import SwiftUI
import SwiftData

/// The Meals tab: the day's five meals, each with a "Did you eat it?" answer.
struct MealsView: View {
    @State private var day = Date.now
    @State private var showingCalendar = false
    @State private var showingReminders = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            MealDayView(day: day)
                .id(Calendar.current.startOfDay(for: day))
                .toolbar {
                    if !Calendar.current.isDateInToday(day) {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Today") { day = .now }
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Reminders", systemImage: "bell") { showingReminders = true }
                        Button("Pick a day", systemImage: "calendar") { showingCalendar = true }
                    }
                }
                .sheet(isPresented: $showingCalendar) {
                    DatePicker("Day", selection: $day, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $showingReminders) {
                    RemindersSheet()
                }
        }
        // Jump back to today when the app is reopened, like the check-in.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { day = .now }
        }
        .onChange(of: day) { showingCalendar = false }
    }
}

/// Loads the meal log for one day, creating it the first time the day is opened.
struct MealDayView: View {
    let day: Date
    @Query private var matches: [MealLog]
    @Environment(\.modelContext) private var context

    init(day: Date) {
        let start = Calendar.current.startOfDay(for: day)
        self.day = start
        _matches = Query(filter: #Predicate<MealLog> { $0.day == start })
    }

    var body: some View {
        Group {
            if let log = matches.first {
                MealDayForm(log: log)
            } else {
                Color.clear
                    .onAppear {
                        MealLog.forDay(day, in: context)
                        try? context.save()
                    }
            }
        }
        .background { AmbientBackground() }
    }
}

struct MealDayForm: View {
    @Bindable var log: MealLog
    @AppStorage(ProteinPlan.storageKey) private var planRaw = ProteinPlan.both.rawValue
    @AppStorage(MealReminders.enabledKey) private var remindersOn = false

    var body: some View {
        let meals = MealPlan.meals(for: ProteinPlan(rawValue: planRaw) ?? .both)
        let eaten = meals.filter { log[$0.meal] == true }

        ScrollView {
            VStack(spacing: 20) {
                MealsHeader(day: log.day,
                            eaten: eaten,
                            target: MealPlan.target(for: ProteinPlan(rawValue: planRaw) ?? .both),
                            mealCount: meals.count)
                    .padding(.horizontal, 4)

                ForEach(meals) { planned in
                    MealCard(planned: planned, showsTime: remindersOn, answer: answer(for: planned.meal))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func answer(for meal: Meal) -> Binding<Bool?> {
        Binding(get: { log[meal] }, set: { log[meal] = $0 })
    }
}

/// Protein eaten so far is the headline number; calories and the meal ring sit beside it.
struct MealsHeader: View {
    let day: Date
    let eaten: [PlannedMeal]
    let target: MacroTotals
    let mealCount: Int

    var body: some View {
        let protein = eaten.reduce(0) { $0 + $1.protein }
        let kcal = eaten.reduce(0) { $0 + $1.kcal }

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(day, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(protein)")
                        .font(.system(size: 50, weight: .bold))
                        .contentTransition(.numericText())
                    Text("/ \(target.protein) g protein")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ChallengeBar(progress: Double(protein) / Double(target.protein))
                Text("\(kcal.formatted()) / \(target.kcal.formatted()) kcal")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            CompletionRing(answered: eaten.count, total: mealCount)
        }
        .animation(.snappy, value: protein)
    }
}

struct MealCard: View {
    let planned: PlannedMeal
    let showsTime: Bool
    @Binding var answer: Bool?

    private var title: String {
        guard showsTime else { return planned.when }
        let time = MealReminders.time(for: planned.meal).formatted(date: .omitted, time: .shortened)
        return "\(planned.when) · \(time)"
    }

    var body: some View {
        GlassCard(title) {
            YesNoRow(title: planned.name, symbol: planned.symbol, color: planned.color, goal: true, value: $answer)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(planned.items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•").foregroundStyle(planned.color)
                        Text(item)
                    }
                }
                Text("\(planned.kcal) kcal · \(planned.protein) g protein")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .padding(.top, 4)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            // Line the details up under the meal name, past the icon.
            .padding(.leading, 46)
        }
    }
}

struct RemindersSheet: View {
    @AppStorage(MealReminders.enabledKey) private var enabled = false
    @AppStorage(ProteinPlan.storageKey) private var planRaw = ProteinPlan.both.rawValue
    @State private var times: [Meal: Date] = Dictionary(uniqueKeysWithValues: Meal.allCases.map { ($0, MealReminders.time(for: $0)) })
    @State private var denied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Meal reminders", isOn: Binding(get: { enabled }, set: setEnabled))
                } footer: {
                    Text(denied
                         ? "Notifications are off for 100 Days. Turn them on in Settings → Notifications → 100 Days."
                         : "One notification per meal. Press and hold it to log Ate it or Skipped without opening the app.")
                }

                if enabled {
                    Section("Times") {
                        ForEach(MealPlan.meals(for: ProteinPlan(rawValue: planRaw) ?? .both)) { planned in
                            DatePicker(planned.when, selection: time(for: planned.meal), displayedComponents: .hourAndMinute)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func setEnabled(_ on: Bool) {
        guard on else {
            enabled = false
            MealReminders.reschedule()
            return
        }
        Task {
            let granted = await MealReminders.requestPermission()
            denied = !granted
            enabled = granted
            MealReminders.reschedule()
        }
    }

    private func time(for meal: Meal) -> Binding<Date> {
        Binding(
            get: { times[meal] ?? MealReminders.time(for: meal) },
            set: {
                times[meal] = $0
                MealReminders.setTime($0, for: meal)
            }
        )
    }
}
