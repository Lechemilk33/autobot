import SwiftUI

/// The Groceries tab: one week of the meal plan as a checklist for the store.
struct GroceriesView: View {
    /// Comma-separated ids of the items already in the cart.
    @AppStorage("groceriesChecked") private var checkedRaw = ""
    @State private var confirmingClear = false

    private var checked: Set<String> {
        Set(checkedRaw.split(separator: ",").map(String.init))
    }

    var body: some View {
        let sections = MealPlan.groceries
        let items = sections.flatMap(\.items)
        let inCart = items.filter { checked.contains($0.id) }.count

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(inCart) of \(items.count) in the cart")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                        ChallengeBar(progress: Double(inCart) / Double(max(items.count, 1)))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                    ForEach(sections) { section in
                        GlassCard(section.title) {
                            ForEach(section.items) { item in
                                GroceryRow(item: item, isChecked: checked.contains(item.id)) {
                                    toggle(item.id)
                                }
                            }
                        }
                    }

                    Button("Clear for next week", systemImage: "arrow.counterclockwise") {
                        confirmingClear = true
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .disabled(inCart == 0)
                    .confirmationDialog("Uncheck every item?", isPresented: $confirmingClear, titleVisibility: .visible) {
                        Button("Clear the list", role: .destructive) {
                            withAnimation(.snappy) { checkedRaw = "" }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .animation(.snappy, value: inCart)
            }
            .background { AmbientBackground() }
            .navigationTitle("Groceries")
        }
        .sensoryFeedback(.selection, trigger: checkedRaw)
    }

    private func toggle(_ id: String) {
        var next = checked
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        withAnimation(.snappy) { checkedRaw = next.sorted().joined(separator: ",") }
    }
}

struct GroceryRow: View {
    let item: GroceryItem
    let isChecked: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.mint : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .strikethrough(isChecked)
                        .foregroundStyle(isChecked ? Color.secondary : Color.primary)
                    if let note = item.note {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Text(item.amount)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isChecked ? Color.secondary : Color.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}
