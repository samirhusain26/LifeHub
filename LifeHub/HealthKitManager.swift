import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    @Published var currentWeight: Double?
    @Published var averageSteps: Double?
    @Published var caloriesBurned: Double?
    @Published var sleepHours: Double?

    private init() {}

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { _, _ in }
    }

    func fetchHealthData() {
        // Placeholder calls; real HealthKit queries would go here
    }
}
