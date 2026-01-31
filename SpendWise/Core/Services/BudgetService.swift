import Foundation
import Combine

/// Protocol for budget data operations
protocol BudgetRepositoryProtocol {
    func fetchAll() async throws -> [Budget]
    func fetch(for category: Category) async throws -> Budget?
    func save(_ budget: Budget) async throws
    func update(_ budget: Budget) async throws
    func delete(_ budget: Budget) async throws
}

/// Service for managing budgets
@MainActor
final class BudgetService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository: BudgetRepositoryProtocol
    private let transactionService: TransactionService
    
    // MARK: - Initialization
    init(repository: BudgetRepositoryProtocol, transactionService: TransactionService) {
        self.repository = repository
        self.transactionService = transactionService
    }
    
    // MARK: - Public Methods
    
    /// Load all budgets and calculate spent amounts
    func loadBudgets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            var loadedBudgets = try await repository.fetchAll()
            
            // Calculate spent amounts from transactions
            let categoryExpenses = transactionService.expensesByCategory()
            for index in loadedBudgets.indices {
                let category = loadedBudgets[index].category
                if let expense = categoryExpenses.first(where: { $0.category == category }) {
                    loadedBudgets[index].spent = expense.total
                }
            }
            
            budgets = loadedBudgets
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Add a new budget
    func addBudget(_ budget: Budget) async {
        do {
            try await repository.save(budget)
            await loadBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Update an existing budget
    func updateBudget(_ budget: Budget) async {
        do {
            try await repository.update(budget)
            await loadBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Delete a budget
    func deleteBudget(_ budget: Budget) async {
        do {
            try await repository.delete(budget)
            budgets.removeAll { $0.id == budget.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Budget Analysis
    
    /// Get budgets that are exceeded
    var exceededBudgets: [Budget] {
        budgets.filter { $0.isExceeded }
    }
    
    /// Get budgets that are near limit (80%+)
    var nearLimitBudgets: [Budget] {
        budgets.filter { $0.isNearLimit }
    }
    
    /// Total budget limit across all categories
    var totalBudgetLimit: Decimal {
        budgets.reduce(0) { $0 + $1.limit }
    }
    
    /// Total spent across all budgeted categories
    var totalSpent: Decimal {
        budgets.reduce(0) { $0 + $1.spent }
    }
    
    /// Overall budget progress
    var overallProgress: Double {
        guard totalBudgetLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalSpent / totalBudgetLimit).doubleValue
    }
    
    /// Check if a category has exceeded its budget
    func isCategoryExceeded(_ category: Category) -> Bool {
        budgets.first { $0.category == category }?.isExceeded ?? false
    }
    
    /// Get remaining budget for a category
    func remainingBudget(for category: Category) -> Decimal? {
        budgets.first { $0.category == category }?.remaining
    }
}
