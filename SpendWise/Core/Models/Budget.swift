import Foundation

/// Budget model for category-based spending limits
struct Budget: Identifiable, Equatable, Hashable {
    let id: UUID
    var category: Category
    var limit: Decimal
    var period: BudgetPeriod
    var spent: Decimal
    
    init(
        id: UUID = UUID(),
        category: Category,
        limit: Decimal,
        period: BudgetPeriod = .monthly,
        spent: Decimal = 0
    ) {
        self.id = id
        self.category = category
        self.limit = limit
        self.period = period
        self.spent = spent
    }
    
    /// Progress percentage (0.0 to 1.0+)
    var progress: Double {
        guard limit > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }
    
    /// Remaining budget amount
    var remaining: Decimal {
        max(limit - spent, 0)
    }
    
    /// Whether budget is exceeded
    var isExceeded: Bool {
        spent > limit
    }
    
    /// Whether budget is near limit (80% or more)
    var isNearLimit: Bool {
        progress >= 0.8 && !isExceeded
    }
}

// MARK: - Budget Period
enum BudgetPeriod: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

// MARK: - Sample Data
extension Budget {
    static func sample(
        category: Category = .food,
        limit: Decimal = 500,
        spent: Decimal = 250
    ) -> Budget {
        Budget(category: category, limit: limit, spent: spent)
    }
    
    static var sampleData: [Budget] {
        [
            Budget(category: .food, limit: 500, spent: 320),
            Budget(category: .transport, limit: 200, spent: 120),
            Budget(category: .entertainment, limit: 300, spent: 285),
            Budget(category: .bills, limit: 1000, spent: 800),
            Budget(category: .shopping, limit: 400, spent: 450)
        ]
    }
}
