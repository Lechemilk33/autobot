import SwiftUI

/// A 1–10 scale. Tapping the selected number again clears it.
struct RatingRow: View {
    let title: String
    let symbol: String
    let color: Color
    @Binding var value: Int?
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(symbol: symbol, color: color)
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Text(value.map { "\($0)" } ?? "–")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(value == nil ? Color.secondary : color)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 0) {
                ForEach(1...10, id: \.self) { n in
                    Button {
                        withAnimation(.snappy) { value = value == n ? nil : n }
                    } label: {
                        Text("\(n)")
                            .font(.callout.weight(value == n ? .bold : .medium))
                            .foregroundStyle(value == n ? Color.white : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background {
                                if value == n {
                                    Capsule()
                                        .fill(color.gradient)
                                        .matchedGeometryEffect(id: "selection", in: selection)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(n)")
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.08), in: .capsule)
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}

/// Yes / No pills. The selected pill turns mint when the answer keeps the
/// challenge on track and orange when it doesn't. Tapping it again clears it.
struct YesNoRow: View {
    let title: String
    let symbol: String
    let color: Color
    /// The on-track answer, or nil when neither answer is better.
    let goal: Bool?
    @Binding var value: Bool?

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, color: color)
            Text(title)
                .font(.body.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                choice(true, label: "Yes")
                choice(false, label: "No")
            }
        }
        .sensoryFeedback(.selection, trigger: value)
    }

    private func choice(_ answer: Bool, label: String) -> some View {
        let isSelected = value == answer
        let tint = goal.map { $0 == answer ? Color.mint : Color.orange } ?? color
        return Button {
            withAnimation(.snappy) { value = isSelected ? nil : answer }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(width: 54, height: 34)
                .background(isSelected ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.white.opacity(0.08)),
                            in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

/// A small 0–N counter, for things you have a number of rather than a rating.
/// Tapping the selected number again clears it back to unanswered.
struct CountRow: View {
    let title: String
    let unit: String
    let symbol: String
    let color: Color
    var range: ClosedRange<Int> = 0...6
    @Binding var value: Int?
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(symbol: symbol, color: color)
                Text(title)
                    .font(.body.weight(.medium))
                Spacer()
                Text(value.map { "\($0) \(unit)\($0 == 1 ? "" : "s")" } ?? "–")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(value == nil ? Color.secondary : color)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 0) {
                ForEach(range, id: \.self) { n in
                    Button {
                        withAnimation(.snappy) { value = value == n ? nil : n }
                    } label: {
                        Text("\(n)")
                            .font(.callout.weight(value == n ? .bold : .medium))
                            .foregroundStyle(value == n ? Color.white : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background {
                                if value == n {
                                    Capsule()
                                        .fill(color.gradient)
                                        .matchedGeometryEffect(id: "selection", in: selection)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(n)")
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.08), in: .capsule)
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}

/// The daily minimum as a single checklist item: 50 pushups, 50 situps, 25 leg lifts.
/// The one check can't be tapped — it fills itself in only once all three are done,
/// so the item can never be marked off while part of the work is still owed.
struct DailySetsRow: View {
    @Binding var pushups: Bool?
    @Binding var situps: Bool?
    @Binding var legLifts: Bool?

    private var done: Bool { pushups == true && situps == true && legLifts == true }
    private var count: Int { [pushups, situps, legLifts].filter { $0 == true }.count }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(symbol: "figure.cooldown", color: .orange)
                Text("Daily sets")
                    .font(.body.weight(.medium))
                Spacer(minLength: 8)
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.mint)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Shows the gate rather than an empty circle, so it reads as
                    // "still owed", not "forgot to answer".
                    Text("\(count) of 3")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }

            VStack(spacing: 10) {
                SetToggle(title: "50 pushups", value: $pushups)
                SetToggle(title: "50 situps", value: $situps)
                SetToggle(title: "25 leg lifts", value: $legLifts)
            }
            .padding(.leading, 46)
        }
        .animation(.snappy, value: count)
        .sensoryFeedback(.success, trigger: done) { _, isDone in isDone }
    }
}

/// One of the three sets. Tapping a done set clears it again, like every other answer.
private struct SetToggle: View {
    let title: String
    @Binding var value: Bool?

    var body: some View {
        let on = value == true
        Button {
            withAnimation(.snappy) { value = on ? nil : true }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(on ? Color.mint : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                Text(title)
                    .strikethrough(on)
                    .foregroundStyle(on ? Color.secondary : Color.primary)
                Spacer(minLength: 0)
            }
            .font(.subheadline.weight(.medium))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
