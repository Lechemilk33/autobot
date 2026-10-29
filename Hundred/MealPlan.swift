import SwiftUI

/// The fixed daily menu and the weekly grocery list it implies. Every day is the
/// same five meals, so there is nothing to choose or calculate.

enum Meal: String, CaseIterable, Identifiable {
    case morning, lunch, smoothie, dinner, evening

    var id: String { rawValue }

    /// Default reminder time, in minutes after midnight.
    var defaultMinutes: Int {
        switch self {
        case .morning: 8 * 60
        case .lunch: 12 * 60 + 30
        case .smoothie: 15 * 60 + 30
        case .dinner: 19 * 60
        case .evening: 21 * 60
        }
    }
}

struct PlannedMeal: Identifiable {
    let meal: Meal
    let when: String
    let name: String
    let symbol: String
    let color: Color
    let items: [String]
    let kcal: Int
    let protein: Int

    var id: Meal { meal }
}

struct MacroTotals {
    let kcal: Int
    let protein: Int
}

struct GroceryItem: Identifiable {
    let id: String
    let name: String
    let amount: String
    var note: String? = nil
}

struct GrocerySection: Identifiable {
    let title: String
    let items: [GroceryItem]

    var id: String { title }
}

enum MealPlan {
    /// Ground beef is at lunch because it cooks fast; chicken takes longer, so it's dinner.
    static let meals: [PlannedMeal] = [
        PlannedMeal(meal: .morning, when: "Morning", name: "Coffee + eggs", symbol: "cup.and.saucer.fill", color: .orange,
                    items: ["2 Keurig coffees, 2 tbsp creamer each", "3 eggs, cooked in butter"],
                    kcal: 390, protein: 19),
        PlannedMeal(meal: .lunch, when: "Lunch", name: "Beef + rice", symbol: "fork.knife", color: .yellow,
                    items: ["Half a 1 lb pack of 90/10 ground beef, taco seasoning, cooked in butter. "
                                + "Cook the whole pack and save the other half for tomorrow's lunch.",
                            "1½ cups cooked white rice"],
                    kcal: 751, protein: 51),
        PlannedMeal(meal: .smoothie, when: "Afternoon", name: "Smoothie", symbol: "takeoutbag.and.cup.and.straw.fill", color: .pink,
                    items: ["1½ cups 2% milk", "1 scoop ISO100 Fruity Pebbles", "1½ cups frozen strawberry-banana blend",
                            "2 tbsp peanut butter", "A handful of spinach"],
                    kcal: 640, protein: 47),
        PlannedMeal(meal: .dinner, when: "Dinner", name: "Chicken + rice", symbol: "frying.pan.fill", color: .red,
                    items: ["1 chicken breast (about 8 oz raw), lemon pepper, cooked in butter", "1½ cups cooked white rice"],
                    kcal: 623, protein: 59),
        PlannedMeal(meal: .evening, when: "Evening", name: "Milk + granola", symbol: "moon.stars.fill", color: .indigo,
                    items: ["1 cup Fairlife chocolate milk", "½ cup granola"],
                    kcal: 360, protein: 18),
    ]

    static let target = meals.reduce(MacroTotals(kcal: 0, protein: 0)) {
        MacroTotals(kcal: $0.kcal + $1.kcal, protein: $0.protein + $1.protein)
    }

    static let groceries: [GrocerySection] = [
        GrocerySection(title: "Every week", items: [
            GroceryItem(id: "chicken", name: "Chicken breasts", amount: "7", note: "About 3.5 lb. One breast per dinner"),
            GroceryItem(id: "beef", name: "90/10 ground beef, 1 lb packs", amount: "4 packs",
                        note: "One pack covers 2 lunches. Have one at home already? Buy 3"),
            GroceryItem(id: "eggs", name: "Eggs", amount: "2 dozen"),
            GroceryItem(id: "milk", name: "2% milk, any brand", amount: "1 gallon"),
            GroceryItem(id: "fairlife", name: "Fairlife chocolate milk", amount: "52 oz"),
            GroceryItem(id: "fruit", name: "Frozen strawberry-banana blend", amount: "3.5 lb"),
            GroceryItem(id: "granola", name: "Granola", amount: "12 oz bag"),
            GroceryItem(id: "creamer", name: "Coffee creamer", amount: "16 oz"),
        ]),
        GrocerySection(title: "Restock when low", items: [
            GroceryItem(id: "rice", name: "White rice", amount: "10 lb bag", note: "Lasts about 3½ weeks"),
            GroceryItem(id: "iso100", name: "ISO100 Fruity Pebbles", amount: "21.5 oz tub", note: "Lasts about 3 weeks"),
            GroceryItem(id: "pb", name: "Peanut butter", amount: "16 oz jar", note: "Lasts about 2 weeks"),
            GroceryItem(id: "kcups", name: "K-cups", amount: "24-count", note: "Lasts about 12 days"),
            GroceryItem(id: "spinach", name: "Spinach, kept frozen", amount: "10 oz bag", note: "Lasts about 10 days"),
            GroceryItem(id: "butter", name: "Butter", amount: "1 lb", note: "Lasts about 4½ weeks"),
            GroceryItem(id: "seasoning", name: "Lemon pepper + taco seasoning", amount: "1 each", note: "Lasts months"),
        ]),
    ]
}
