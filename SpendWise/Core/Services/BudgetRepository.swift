import Foundation
import CoreData

/// Core Data implementation of BudgetRepositoryProtocol
final class BudgetRepository: BudgetRepositoryProtocol, @unchecked Sendable {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    convenience init() {
        self.init(coreDataManager: .shared)
    }
    
    // MARK: - Fetch
    
    func fetchAll() async throws -> [Budget] {
        let context = coreDataManager.viewContext
        
        return try await context.perform {
            let request = BudgetEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \BudgetEntity.category, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.compactMap { Self.mapToModel($0) }
        }
    }
    
    func fetch(for category: Category) async throws -> Budget? {
        let context = coreDataManager.viewContext
        
        return try await context.perform {
            let request = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category.rawValue)
            request.fetchLimit = 1
            
            let entity = try context.fetch(request).first
            return entity.flatMap { Self.mapToModel($0) }
        }
    }
    
    // MARK: - Save
    
    func save(_ budget: Budget) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let entity = BudgetEntity(context: context)
            Self.mapToEntity(budget, entity: entity)
            try context.save()
        }
    }
    
    // MARK: - Update
    
    func update(_ budget: Budget) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let request = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", budget.id as CVarArg)
            
            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            Self.mapToEntity(budget, entity: entity)
            try context.save()
        }
    }
    
    // MARK: - Delete
    
    func delete(_ budget: Budget) async throws {
        let context = coreDataManager.viewContext
        
        try await context.perform {
            let request = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", budget.id as CVarArg)
            
            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            context.delete(entity)
            try context.save()
        }
    }
    
    // MARK: - Mapping (Static to avoid actor isolation)
    
    private static func mapToModel(_ entity: BudgetEntity) -> Budget? {
        guard let id = entity.id,
              let categoryString = entity.category,
              let category = Category(rawValue: categoryString),
              let periodString = entity.period,
              let period = BudgetPeriod(rawValue: periodString) else {
            return nil
        }
        
        return Budget(
            id: id,
            category: category,
            limit: entity.limit?.decimalValue ?? 0,
            period: period,
            spent: 0 // Spent is calculated from transactions
        )
    }
    
    private static func mapToEntity(_ budget: Budget, entity: BudgetEntity) {
        entity.id = budget.id
        entity.category = budget.category.rawValue
        entity.limit = NSDecimalNumber(decimal: budget.limit)
        entity.period = budget.period.rawValue
    }
}
