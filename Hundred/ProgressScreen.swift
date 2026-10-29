import SwiftUI
import SwiftData

/// The Progress tab: running totals and the 100-day grid. Tap any past day to open it.
struct ProgressScreen: View {
    @Query private var entries: [DayEntry]
    @AppStorage(Challenge.startKey) private var challengeStart: Double = 0

    private var startDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: challengeStart) },
            set: { challengeStart = Calendar.current.startOfDay(for: $0).timeIntervalSince1970 }
        )
    }

    var body: some View {
        let byDay = Dictionary(entries.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        let dayNumber = Challenge.dayNumber(of: .now, start: challengeStart)

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StartDateCard(start: startDate)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                              spacing: 12) {
                        StatTile(value: Self.soberStreak(byDay), label: "Sober streak",
                                 symbol: "flame.fill", color: .mint)
                        StatTile(value: entries.filter { $0.answeredCount > 0 }.count, label: "Days logged",
                                 symbol: "checkmark.circle.fill", color: .purple)
                        StatTile(value: entries.filter { $0.workedOut == true }.count, label: "Workouts",
                                 symbol: "figure.run", color: .red)
                        StatTile(value: entries.filter { $0.drankGallonOfWater == true }.count, label: "Gallons of water",
                                 symbol: "drop.fill", color: .cyan)
                    }

                    GlassCard(dayNumber >= 1 ? "Day \(dayNumber) of \(Challenge.length)" : "\(Challenge.length) days") {
                        ChallengeGrid(start: startDate.wrappedValue, entries: byDay)
                        HStack(spacing: 16) {
                            LegendDot(color: .mint, label: "Sober")
                            LegendDot(color: .orange, label: "Drank or smoked")
                            LegendDot(color: Color.white.opacity(0.25), label: "Not logged")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background { AmbientBackground() }
            .navigationTitle("Progress")
            .navigationDestination(for: Date.self) { day in
                CheckInView(day: day)
            }
        }
    }

    /// Consecutive sober days ending today. Today only counts once it's answered,
    /// so the streak doesn't drop to zero just because you haven't checked in yet.
    private static func soberStreak(_ byDay: [Date: DayEntry]) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
        if byDay[day]?.isSober == nil {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        while byDay[day]?.isSober == true {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}

/// Which day the challenge starts from. It sits at the top of the tab because the
/// 100-day grid is taller than the screen, and below that this was unreachable.
struct StartDateCard: View {
    @Binding var start: Date

    private var isToday: Bool { Calendar.current.isDateInToday(start) }

    var body: some View {
        GlassCard("Day 1") {
            DatePicker("Starts on", selection: $start, displayedComponents: .date)
                .font(.body.weight(.medium))

            Button {
                withAnimation(.snappy) { start = Calendar.current.startOfDay(for: .now) }
            } label: {
                Text(isToday ? "Today is Day 1" : "Make today Day 1")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isToday ? Color.white.opacity(0.08) : Color.mint.opacity(0.22),
                                in: .rect(cornerRadius: 16))
                    .foregroundStyle(isToday ? Color.secondary : Color.mint)
            }
            .buttonStyle(.plain)
            .disabled(isToday)
            .sensoryFeedback(.success, trigger: isToday) { _, now in now }
        }
    }
}

struct StatTile: View {
    let value: Int
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
                .contentTransition(.numericText())
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}

/// A 10 × 10 grid, one dot per challenge day.
struct ChallengeGrid: View {
    let start: Date
    let entries: [Date: DayEntry]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 10)

    var body: some View {
        let first = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: .now)

        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(0..<Challenge.length, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: first) ?? first
                let dot = DayDot(color: color(for: date, today: today), isToday: date == today)
                    .accessibilityLabel("Day \(offset + 1)")
                if date > today {
                    dot
                } else {
                    NavigationLink(value: date) { dot }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func color(for date: Date, today: Date) -> Color {
        if date > today { return Color.white.opacity(0.05) }
        guard let entry = entries[date], entry.answeredCount > 0 else { return Color.white.opacity(0.15) }
        switch entry.isSober {
        case true?: return .mint
        case false?: return .orange
        case nil: return Color.white.opacity(0.45)
        }
    }
}

struct DayDot: View {
    let color: Color
    let isToday: Bool

    var body: some View {
        Circle()
            .fill(color)
            .overlay {
                if isToday {
                    Circle().strokeBorder(Color.white, lineWidth: 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
