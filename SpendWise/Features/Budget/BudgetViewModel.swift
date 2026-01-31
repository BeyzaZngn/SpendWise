import Foundation
import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let budgetRepository: BudgetRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    
    // MARK: - Initialization
    init(
        budgetRepository: BudgetRepositoryProtocol? = nil,
        transactionRepository: TransactionRepositoryProtocol? = nil
    ) {
        self.budgetRepository = budgetRepository ?? BudgetRepository()
        self.transactionRepository = transactionRepository ?? TransactionRepository()
    }
    
    // MARK: - Load Data
    
    func loadBudgets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            var loadedBudgets = try await budgetRepository.fetchAll()
            
            // Calculate spent amounts from transactions
            let transactions = try await transactionRepository.fetchAll()
            let expenses = transactions.filter { $0.type == .expense }
            var categoryTotals: [Category: Decimal] = [:]
            
            for transaction in expenses {
                categoryTotals[transaction.category, default: 0] += transaction.amount
            }
            
            for index in loadedBudgets.indices {
                let category = loadedBudgets[index].category
                loadedBudgets[index].spent = categoryTotals[category] ?? 0
            }
            
            budgets = loadedBudgets.sorted { $0.progress > $1.progress }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - CRUD Operations
    
    func addBudget(_ budget: Budget) async {
        do {
            try await budgetRepository.save(budget)
            await loadBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateBudget(_ budget: Budget) async {
        do {
            try await budgetRepository.update(budget)
            await loadBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteBudget(_ budget: Budget) async {
        do {
            try await budgetRepository.delete(budget)
            budgets.removeAll { $0.id == budget.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var exceededBudgets: [Budget] {
        budgets.filter { $0.isExceeded }
    }
    
    var nearLimitBudgets: [Budget] {
        budgets.filter { $0.isNearLimit }
    }
    
    var totalLimit: Decimal {
        budgets.reduce(0) { $0 + $1.limit }
    }
    
    var totalSpent: Decimal {
        budgets.reduce(0) { $0 + $1.spent }
    }
    
    var overallProgress: Double {
        guard totalLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalSpent / totalLimit).doubleValue
    }
}
