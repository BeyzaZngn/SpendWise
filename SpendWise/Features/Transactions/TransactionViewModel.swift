import Foundation
import Combine

@MainActor
final class TransactionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    
    // MARK: - Initialization
    init(repository: TransactionRepositoryProtocol? = nil) {
        self.repository = repository ?? TransactionRepository()
    }
    
    // MARK: - Public Methods
    
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
    
    func addTransaction(_ transaction: Transaction) async {
        do {
            try await repository.save(transaction)
            await loadTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        do {
            try await repository.update(transaction)
            await loadTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        do {
            try await repository.delete(transaction)
            transactions.removeAll { $0.id == transaction.id }
        } catch {
            errorMessage = error.localizedDescription
        }
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
    
    var balance: Decimal {
        totalIncome - totalExpenses
    }
}
