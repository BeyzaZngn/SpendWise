@preconcurrency import CoreData

/// Manages Core Data stack and provides persistence functionality
final class CoreDataManager: @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = CoreDataManager()
    
    // MARK: - Preview Support
    static var preview: CoreDataManager = {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.viewContext
        
        // Add sample data for previews
        for transaction in Transaction.sampleData {
            let entity = TransactionEntity(context: context)
            entity.id = transaction.id
            entity.amount = NSDecimalNumber(decimal: transaction.amount)
            entity.type = transaction.type.rawValue
            entity.category = transaction.category.rawValue
            entity.date = transaction.date
            entity.note = transaction.note
            entity.isRecurring = transaction.isRecurring
        }
        
        for budget in Budget.sampleData {
            let entity = BudgetEntity(context: context)
            entity.id = budget.id
            entity.category = budget.category.rawValue
            entity.limit = NSDecimalNumber(decimal: budget.limit)
            entity.period = budget.period.rawValue
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Failed to save preview data: \(error)")
        }
        
        return manager
    }()
    
    // MARK: - Properties
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpendWise")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save
    func save(context: NSManagedObjectContext? = nil) async throws {
        let targetContext = context ?? viewContext
        
        guard targetContext.hasChanges else { return }
        
        try await targetContext.perform {
            try targetContext.save()
        }
    }
    
    // MARK: - Delete All
    func deleteAll<T: NSManagedObject>(_ type: T.Type, context: NSManagedObjectContext? = nil) async throws {
        let targetContext = context ?? viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        try await targetContext.perform {
            let result = try targetContext.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [self.viewContext]
                )
            }
        }
    }
}
