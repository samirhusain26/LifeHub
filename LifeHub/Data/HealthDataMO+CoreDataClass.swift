import Foundation
import CoreData

@objc(HealthDataMO)
public class HealthDataMO: NSManagedObject {

}

extension HealthDataMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthDataMO> {
        return NSFetchRequest<HealthDataMO>(entityName: "HealthDataMO")
    }

    @NSManaged public var date: Date?
    @NSManaged public var stepCount: Int64
    @NSManaged public var weight: Double
    @NSManaged public var sleepStart: Date?
    @NSManaged public var sleepEnd: Date?
    @NSManaged public var sleepDuration: Double

}

extension HealthDataMO : Identifiable {

}
