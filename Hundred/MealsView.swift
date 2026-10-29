import SwiftUI
import SwiftData

/// The Meals tab: the day's five meals, each checked off once it's eaten.
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

    var body: some View {
        let meals = MealPlan.meals
        let eaten = meals.filter { log[$0.meal] == true }

        ScrollView {
            VStack(spacing: 20) {
                MealsHeader(day: log.day,
                            eaten: eaten,
                            target: MealPlan.target,
                            mealCount: meals.count)
                    .padding(.horizontal, 4)

                ForEach(meals) { planned in
                    MealCard(planned: planned, ate: ate(planned.meal))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func ate(_ meal: Meal) -> Binding<Bool> {
        Binding(get: { log[meal] == true }, set: { log[meal] = $0 ? true : nil })
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

/// One meal. Tap its top row to check it off, or again to uncheck it.
struct MealCard: View {
    let planned: PlannedMeal
    @Binding var ate: Bool

    var body: some View {
        GlassCard(planned.when) {
            Button {
                withAnimation(.snappy) { ate.toggle() }
            } label: {
                HStack(spacing: 12) {
                    IconBadge(symbol: planned.symbol, color: planned.color)
                    Text(planned.name)
                        .font(.body.weight(.medium))
                    Spacer(minLength: 8)
                    Image(systemName: ate ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30))
                        .foregroundStyle(ate ? Color.mint : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: ate)
            .accessibilityAddTraits(ate ? .isSelected : [])

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
                         : "One notification per meal. Press and hold it and tap Ate it to check the meal off without opening the app.")
                }

                if enabled {
                    Section("Times") {
                        ForEach(MealPlan.meals) { planned in
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
