import CoreData

@objc(BudgetEntity)
public class BudgetEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var limit: NSDecimalNumber?
    @NSManaged public var period: String?
}

extension BudgetEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BudgetEntity> {
        return NSFetchRequest<BudgetEntity>(entityName: "BudgetEntity")
    }
}
