import Foundation
import CoreData

/// Core Data implementation of TransactionRepositoryProtocol
final class TransactionRepository: TransactionRepositoryProtocol, @unchecked Sendable {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    convenience init() {
        self.init(coreDataManager: .shared)
    }
    
    // MARK: - Fetch
    
    func fetchAll() async throws -> [Transaction] {
        let context = coreDataManager.viewContext
        
        return try await context.perform {
            let request = TransactionEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { Self.mapToModel($0) }
        }
    }
    
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let context = coreDataManager.viewContext
        
        return try await context.perform {
            let request = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { Self.mapToModel($0) }
        }
    }
    
    func fetchByCategory(_ category: Category) async throws -> [Transaction] {
        let context = coreDataManager.viewContext
        
        return try await context.perform {
            let request = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { Self.mapToModel($0) }
        }
    }
    
    // MARK: - Save
    
    func save(_ transaction: Transaction) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let entity = TransactionEntity(context: context)
            Self.mapToEntity(transaction, entity: entity)
            try context.save()
        }
    }
    
    // MARK: - Update
    
    func update(_ transaction: Transaction) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let request = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
            
            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            Self.mapToEntity(transaction, entity: entity)
            try context.save()
        }
    }
    
    // MARK: - Delete
    
    func delete(_ transaction: Transaction) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let request = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
            
            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            context.delete(entity)
            try context.save()
        }
    }
    
    // MARK: - Mapping (Static to avoid actor isolation)
    
    private static func mapToModel(_ entity: TransactionEntity) -> Transaction? {
        guard let id = entity.id,
              let typeString = entity.type,
              let type = TransactionType(rawValue: typeString),
              let categoryString = entity.category,
              let category = Category(rawValue: categoryString),
              let date = entity.date else {
            return nil
        }
        
        let recurringInterval: RecurringInterval? = entity.recurringInterval.flatMap { RecurringInterval(rawValue: $0) }
        
        return Transaction(
            id: id,
            amount: entity.amount?.decimalValue ?? 0,
            type: type,
            category: category,
            date: date,
            note: entity.note ?? "",
            isRecurring: entity.isRecurring,
            recurringInterval: recurringInterval
        )
    }
    
    private static func mapToEntity(_ transaction: Transaction, entity: TransactionEntity) {
        entity.id = transaction.id
        entity.amount = NSDecimalNumber(decimal: transaction.amount)
        entity.type = transaction.type.rawValue
        entity.category = transaction.category.rawValue
        entity.date = transaction.date
        entity.note = transaction.note
        entity.isRecurring = transaction.isRecurring
        entity.recurringInterval = transaction.recurringInterval?.rawValue
    }
}

// MARK: - Repository Error

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found."
        case .saveFailed:
            return "Failed to save changes."
        }
    }
}
