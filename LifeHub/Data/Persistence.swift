import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LifeHub")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func saveHealthData(healthData: [HealthData]) {
        let context = container.newBackgroundContext()
        context.perform {
            for data in healthData {
                // Use the generated NSManagedObject subclass for type safety
                let healthDataRecord = HealthDataMO(context: context)
                healthDataRecord.date = data.date
                healthDataRecord.stepCount = Int64(data.stepCount ?? 0)
                healthDataRecord.weight = data.weight ?? 0.0
                healthDataRecord.sleepStart = data.sleepStart
                healthDataRecord.sleepEnd = data.sleepEnd
                healthDataRecord.sleepDuration = data.sleepDuration ?? 0.0
            }

            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func fetchHealthData() -> [HealthData] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<HealthDataMO> = HealthDataMO.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            return results.map {
                HealthData(
                    date: $0.date ?? Date(),
                    stepCount: Int($0.stepCount),
                    weight: $0.weight,
                    sleepStart: $0.sleepStart,
                    sleepEnd: $0.sleepEnd,
                    sleepDuration: $0.sleepDuration
                )
            }
        } catch {
            print("Failed to fetch health data: \(error)")
            return []
        }
    }
}
