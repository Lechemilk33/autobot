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
