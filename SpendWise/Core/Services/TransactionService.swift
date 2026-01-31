import Foundation
import Combine

/// Protocol for transaction data operations - enables dependency injection and testing
protocol TransactionRepositoryProtocol {
    func fetchAll() async throws -> [Transaction]
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Transaction]
    func fetchByCategory(_ category: Category) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
}

/// Service for managing transactions with async/await support
@MainActor
final class TransactionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    
    // MARK: - Initialization
    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Load all transactions
    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            transactions = try await repository.fetchAll()
            transactions.sort { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Load transactions within a date range
    func loadTransactions(from startDate: Date, to endDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            transactions = try await repository.fetch(from: startDate, to: endDate)
            transactions.sort { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Add a new transaction
    func addTransaction(_ transaction: Transaction) async {
        do {
            try await repository.save(transaction)
            await loadTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Update an existing transaction
    func updateTransaction(_ transaction: Transaction) async {
        do {
            try await repository.update(transaction)
            await loadTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Delete a transaction
    func deleteTransaction(_ transaction: Transaction) async {
        do {
            try await repository.delete(transaction)
            transactions.removeAll { $0.id == transaction.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Statistics
    
    /// Total income for current transactions
    var totalIncome: Decimal {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total expenses for current transactions
    var totalExpenses: Decimal {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Net balance (income - expenses)
    var balance: Decimal {
        totalIncome - totalExpenses
    }
    
    /// Group transactions by category with totals
    func expensesByCategory() -> [(category: Category, total: Decimal)] {
        let expenses = transactions.filter { $0.type == .expense }
        var categoryTotals: [Category: Decimal] = [:]
        
        for transaction in expenses {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        return categoryTotals
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
    
    /// Get transactions for today
    func todayTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return transactions.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    /// Get transactions for this week
    func thisWeekTransactions() -> [Transaction] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        return transactions.filter { $0.date >= weekStart }
    }
    
    /// Get transactions for this month
    func thisMonthTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let monthStart = calendar.date(from: components) else {
            return []
        }
        return transactions.filter { $0.date >= monthStart }
    }
}
