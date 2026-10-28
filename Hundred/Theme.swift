import SwiftUI

/// A slowly drifting mesh gradient behind every screen. Liquid Glass refracts
/// whatever is underneath it, so the glass only comes alive over moving color.
struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: Self.points(at: t), colors: Self.colors)
        }
        .ignoresSafeArea()
    }

    private static let colors: [Color] = [
        Color(red: 0.06, green: 0.05, blue: 0.16), Color(red: 0.20, green: 0.10, blue: 0.42), Color(red: 0.04, green: 0.12, blue: 0.24),
        Color(red: 0.30, green: 0.08, blue: 0.40), Color(red: 0.06, green: 0.30, blue: 0.42), Color(red: 0.42, green: 0.10, blue: 0.28),
        Color(red: 0.02, green: 0.03, blue: 0.08), Color(red: 0.05, green: 0.28, blue: 0.30), Color(red: 0.08, green: 0.05, blue: 0.14),
    ]

    /// `t` stays a Double: seconds since 2001 are too large for Float to animate smoothly.
    private static func points(at t: TimeInterval) -> [SIMD2<Float>] {
        let centerX = Float(0.5 + 0.18 * sin(t * 0.21))
        let centerY = Float(0.5 + 0.14 * cos(t * 0.17))
        let top = Float(0.5 + 0.2 * sin(t * 0.13))
        let bottom = Float(0.5 + 0.2 * cos(t * 0.11))
        return [
            [0, 0], [top, 0], [1, 0],
            [0, 0.5], [centerX, centerY], [1, 0.5],
            [0, 1], [bottom, 1], [1, 1],
        ]
    }
}

/// A titled Liquid Glass panel. Controls inside use plain fills, not more glass.
struct GlassCard<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
    }
}

struct IconBadge: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.callout.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.18), in: .circle)
    }
}
