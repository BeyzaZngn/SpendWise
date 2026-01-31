import Foundation

/// Represents a financial transaction (income or expense)
struct Transaction: Identifiable, Equatable, Hashable {
    let id: UUID
    var amount: Decimal
    var type: TransactionType
    var category: Category
    var date: Date
    var note: String
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType,
        category: Category,
        date: Date = Date(),
        note: String = "",
        isRecurring: Bool = false,
        recurringInterval: RecurringInterval? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.note = note
        self.isRecurring = isRecurring
        self.recurringInterval = recurringInterval
    }
}

// MARK: - Transaction Type
enum TransactionType: String, CaseIterable, Codable {
    case income = "Income"
    case expense = "Expense"
    
    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Recurring Interval
enum RecurringInterval: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

// MARK: - Sample Data
extension Transaction {
    static func sample(
        amount: Decimal = 25.00,
        type: TransactionType = .expense,
        category: Category = .food
    ) -> Transaction {
        Transaction(
            amount: amount,
            type: type,
            category: category,
            date: Date(),
            note: "Sample transaction"
        )
    }
    
    static var sampleData: [Transaction] {
        [
            Transaction(amount: 5000, type: .income, category: .other, note: "Salary"),
            Transaction(amount: 45.50, type: .expense, category: .food, note: "Groceries"),
            Transaction(amount: 120, type: .expense, category: .transport, note: "Monthly transit pass"),
            Transaction(amount: 85, type: .expense, category: .entertainment, note: "Concert tickets"),
            Transaction(amount: 200, type: .expense, category: .bills, note: "Electricity bill"),
            Transaction(amount: 150, type: .expense, category: .shopping, note: "New shoes"),
            Transaction(amount: 50, type: .expense, category: .health, note: "Pharmacy"),
            Transaction(amount: 300, type: .expense, category: .education, note: "Online course")
        ]
    }
}
