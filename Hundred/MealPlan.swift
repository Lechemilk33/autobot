import SwiftUI

/// The fixed daily menu and the weekly grocery list it implies. The food never
/// changes; the only weekly choice is which meat goes in lunch and dinner.

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

/// Which meat goes in lunch and dinner this week.
enum ProteinPlan: String, CaseIterable, Identifiable {
    case both, chicken, beef

    static let storageKey = "proteinPlan"

    static var current: ProteinPlan {
        ProteinPlan(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .both
    }

    var id: String { rawValue }

    var label: String {
        switch self {
        case .both: "Both"
        case .chicken: "Chicken"
        case .beef: "Beef"
        }
    }

    var summary: String {
        switch self {
        case .both: "Chicken at lunch, beef at dinner, and beef for Sunday lunch. 4 one-pound packs of beef, 3 lb of chicken."
        case .chicken: "Chicken at lunch and dinner. 7 lb."
        case .beef: "Ground beef at lunch and dinner. 7 one-pound packs, one a day."
        }
    }

    /// With both meats, Sunday's lunch is beef so the 1 lb packs split evenly into 8 meals.
    fileprivate func lunch(on day: Date) -> Protein {
        switch self {
        case .chicken: .chicken
        case .beef: .beef
        case .both: Calendar.current.component(.weekday, from: day) == 1 ? .beef : .chicken
        }
    }
    fileprivate var dinner: Protein { self == .chicken ? .chicken : .beef }
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

private enum Protein {
    case chicken, beef

    func meal(_ meal: Meal, when: String, symbol: String, color: Color) -> PlannedMeal {
        switch self {
        case .chicken:
            PlannedMeal(meal: meal, when: when, name: "Chicken + rice", symbol: symbol, color: color,
                        items: ["8 oz raw chicken breast (about 6 oz cooked), lemon pepper, cooked in butter",
                                "1½ cups cooked white rice"],
                        kcal: 623, protein: 59)
        case .beef:
            PlannedMeal(meal: meal, when: when, name: "Beef + rice", symbol: symbol, color: color,
                        items: ["Half a 1 lb pack of 90/10 ground beef, taco seasoning, cooked in butter",
                                "1½ cups cooked white rice"],
                        kcal: 751, protein: 51)
        }
    }
}

enum MealPlan {
    static func meals(for plan: ProteinPlan, on day: Date = .now) -> [PlannedMeal] {
        [
            PlannedMeal(meal: .morning, when: "Morning", name: "Coffee + eggs", symbol: "cup.and.saucer.fill", color: .orange,
                        items: ["2 Keurig coffees, 2 tbsp creamer each", "3 eggs, cooked in butter"],
                        kcal: 390, protein: 19),
            plan.lunch(on: day).meal(.lunch, when: "Lunch", symbol: "fork.knife", color: .yellow),
            PlannedMeal(meal: .smoothie, when: "Afternoon", name: "Smoothie", symbol: "takeoutbag.and.cup.and.straw.fill", color: .pink,
                        items: ["1½ cups 2% milk", "1 scoop ISO100 Fruity Pebbles", "1½ cups frozen strawberry-banana blend",
                                "2 tbsp peanut butter", "A handful of spinach"],
                        kcal: 640, protein: 47),
            plan.dinner.meal(.dinner, when: "Dinner", symbol: "frying.pan.fill", color: .red),
            PlannedMeal(meal: .evening, when: "Evening", name: "Milk + granola", symbol: "moon.stars.fill", color: .indigo,
                        items: ["1 cup Fairlife chocolate milk", "½ cup granola"],
                        kcal: 360, protein: 18),
        ]
    }

    static func target(for plan: ProteinPlan, on day: Date = .now) -> MacroTotals {
        meals(for: plan, on: day).reduce(MacroTotals(kcal: 0, protein: 0)) {
            MacroTotals(kcal: $0.kcal + $1.kcal, protein: $0.protein + $1.protein)
        }
    }

    static func groceries(for plan: ProteinPlan) -> [GrocerySection] {
        let meat: [GroceryItem] = switch plan {
        case .both: [GroceryItem(id: "chicken", name: "Chicken breast", amount: "3 lb", note: "6 lunches, 8 oz each"),
                     GroceryItem(id: "beef", name: "90/10 ground beef", amount: "4 × 1 lb packs",
                                 note: "Each pack is 2 meals: 7 dinners + Sunday lunch")]
        case .chicken: [GroceryItem(id: "chicken", name: "Chicken breast", amount: "7 lb")]
        case .beef: [GroceryItem(id: "beef", name: "90/10 ground beef", amount: "7 × 1 lb packs",
                                 note: "One pack a day: half at lunch, half at dinner")]
        }
        return [
            GrocerySection(title: "Every week", items: meat + [
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
}
