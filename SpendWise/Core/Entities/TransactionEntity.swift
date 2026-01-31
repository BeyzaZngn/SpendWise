import CoreData

@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var type: String?
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringInterval: String?
}

extension TransactionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        return NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }
}
