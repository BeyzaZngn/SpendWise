import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedPeriod: TimePeriod = .month
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let transactionRepository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    
    // MARK: - Initialization
    init(
        transactionRepository: TransactionRepositoryProtocol? = nil,
        budgetRepository: BudgetRepositoryProtocol? = nil
    ) {
        self.transactionRepository = transactionRepository ?? TransactionRepository()
        self.budgetRepository = budgetRepository ?? BudgetRepository()
    }
    
    // MARK: - Load Data
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let transactionsTask = transactionRepository.fetchAll()
            async let budgetsTask = budgetRepository.fetchAll()
            
            let (loadedTransactions, loadedBudgets) = try await (transactionsTask, budgetsTask)
            
            transactions = loadedTransactions.sorted { $0.date > $1.date }
            budgets = calculateBudgetSpending(loadedBudgets)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var balance: Decimal {
        totalIncome - totalExpenses
    }
    
    var totalIncome: Decimal {
        filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .day:
            return transactions.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return []
            }
            return transactions.filter { $0.date >= weekStart }
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: components) else {
                return []
            }
            return transactions.filter { $0.date >= monthStart }
        }
    }
    
    var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }
    
    var categoryExpenses: [(category: Category, total: Decimal)] {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        var totals: [Category: Decimal] = [:]
        
        for transaction in expenses {
            totals[transaction.category, default: 0] += transaction.amount
        }
        
        return totals
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
    
    // MARK: - Budget Properties
    
    var overallBudgetProgress: Double {
        guard totalBudgetLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalBudgetSpent / totalBudgetLimit).doubleValue
    }
    
    var totalBudgetLimit: Decimal {
        budgets.reduce(0) { $0 + $1.limit }
    }
    
    var totalBudgetSpent: Decimal {
        budgets.reduce(0) { $0 + $1.spent }
    }
    
    // MARK: - Private Methods
    
    private func calculateBudgetSpending(_ budgets: [Budget]) -> [Budget] {
        let expenses = transactions.filter { $0.type == .expense }
        var categoryTotals: [Category: Decimal] = [:]
        
        for transaction in expenses {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        return budgets.map { budget in
            var updated = budget
            updated.spent = categoryTotals[budget.category] ?? 0
            return updated
        }
    }
}
