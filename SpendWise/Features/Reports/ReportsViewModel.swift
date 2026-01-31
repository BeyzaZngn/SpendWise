import Foundation
import Combine

// MARK: - Chart Data Models

struct CategoryChartData: Identifiable {
    let id = UUID()
    let category: Category
    let total: Decimal
    let percentage: Double
    
    static var sampleData: [CategoryChartData] {
        [
            CategoryChartData(category: .food, total: 450, percentage: 30),
            CategoryChartData(category: .transport, total: 200, percentage: 13),
            CategoryChartData(category: .entertainment, total: 300, percentage: 20),
            CategoryChartData(category: .bills, total: 350, percentage: 23),
            CategoryChartData(category: .shopping, total: 200, percentage: 14)
        ]
    }
}

struct DailyChartData: Identifiable {
    let id = UUID()
    let date: Date
    let income: Decimal
    let expense: Decimal
    
    static var sampleData: [DailyChartData] {
        let calendar = Calendar.current
        return (0..<14).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            return DailyChartData(
                date: date,
                income: Decimal(Int.random(in: 0...200)),
                expense: Decimal(Int.random(in: 50...300))
            )
        }.reversed()
    }
}

// MARK: - Reports ViewModel

@MainActor
final class ReportsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var previousPeriodTransactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    
    // MARK: - Initialization
    init(repository: TransactionRepositoryProtocol? = nil) {
        self.repository = repository ?? TransactionRepository()
    }
    
    // MARK: - Load Data
    
    func loadData(for period: ReportPeriod) async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let now = Date()
        
        let (startDate, previousStartDate, previousEndDate): (Date, Date, Date) = {
            switch period {
            case .week:
                let start = calendar.date(byAdding: .day, value: -7, to: now)!
                let prevStart = calendar.date(byAdding: .day, value: -14, to: now)!
                return (start, prevStart, start)
            case .month:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                let prevStart = calendar.date(byAdding: .month, value: -2, to: now)!
                return (start, prevStart, start)
            case .year:
                let start = calendar.date(byAdding: .year, value: -1, to: now)!
                let prevStart = calendar.date(byAdding: .year, value: -2, to: now)!
                return (start, prevStart, start)
            }
        }()
        
        do {
            async let currentTask = repository.fetch(from: startDate, to: now)
            async let previousTask = repository.fetch(from: previousStartDate, to: previousEndDate)
            
            let (current, previous) = try await (currentTask, previousTask)
            transactions = current
            previousPeriodTransactions = previous
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var totalIncome: Decimal {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var savings: Decimal {
        totalIncome - totalExpenses
    }
    
    var previousPeriodExpenses: Decimal {
        previousPeriodTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var categoryData: [CategoryChartData] {
        let expenses = transactions.filter { $0.type == .expense }
        var categoryTotals: [Category: Decimal] = [:]
        
        for transaction in expenses {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        let total = categoryTotals.values.reduce(0, +)
        
        return categoryTotals
            .map { category, amount in
                let percentage = total > 0
                    ? NSDecimalNumber(decimal: (amount / total) * 100).doubleValue
                    : 0
                return CategoryChartData(
                    category: category,
                    total: amount,
                    percentage: percentage
                )
            }
            .sorted { $0.total > $1.total }
    }
    
    var dailyData: [DailyChartData] {
        let calendar = Calendar.current
        var dailyTotals: [Date: (income: Decimal, expense: Decimal)] = [:]
        
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            var totals = dailyTotals[day] ?? (income: 0, expense: 0)
            
            if transaction.type == .income {
                totals.income += transaction.amount
            } else {
                totals.expense += transaction.amount
            }
            
            dailyTotals[day] = totals
        }
        
        return dailyTotals
            .map { DailyChartData(date: $0.key, income: $0.value.income, expense: $0.value.expense) }
            .sorted { $0.date < $1.date }
    }
}
