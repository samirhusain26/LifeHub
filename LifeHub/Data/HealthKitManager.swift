import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.example.LifeHub", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }

    func fetchHealthData(completion: @escaping ([HealthData]) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -12, to: endDate) else {
            completion([])
            return
        }

        let dispatchGroup = DispatchGroup()

        var dailyStepCounts: [Date: Int] = [:]
        var dailyWeights: [Date: Double] = [:]
        var dailySleepData: [Date: (Date, Date, TimeInterval)] = [:]

        // Fetch Step Count
        dispatchGroup.enter()
        fetchStepCount(startDate: startDate, endDate: endDate) { steps in
            dailyStepCounts = steps
            dispatchGroup.leave()
        }

        // Fetch Weight
        dispatchGroup.enter()
        fetchWeight(startDate: startDate, endDate: endDate) { weights in
            dailyWeights = weights
            dispatchGroup.leave()
        }

        // Fetch Sleep Data
        dispatchGroup.enter()
        fetchSleepData(startDate: startDate, endDate: endDate) { sleepData in
            dailySleepData = sleepData
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            let healthData = self.combineData(
                steps: dailyStepCounts,
                weights: dailyWeights,
                sleep: dailySleepData
            )
            completion(healthData)
        }
    }

    private func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping ([Date: Int]) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([:])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let interval = DateComponents(day: 1)

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                completion([:])
                return
            }

            var dailySteps: [Date: Int] = [:]
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let date = statistics.startDate
                    dailySteps[date] = Int(sum.doubleValue(for: .count()))
                }
            }
            completion(dailySteps)
        }

        healthStore.execute(query)
    }

    private func fetchWeight(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion([:])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample] else {
                completion([:])
                return
            }

            var dailyWeights: [Date: Double] = [:]
            for sample in samples {
                let date = Calendar.current.startOfDay(for: sample.endDate)
                if dailyWeights[date] == nil {
                    dailyWeights[date] = sample.quantity.doubleValue(for: .pound())
                }
            }
            completion(dailyWeights)
        }

        healthStore.execute(query)
    }

    private func fetchSleepData(startDate: Date, endDate: Date, completion: @escaping ([Date: (Date, Date, TimeInterval)]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([:])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                completion([:])
                return
            }

            var dailySleep: [Date: (Date, Date, TimeInterval)] = [:]
            var sessionStartDate: Date?
            var sessionEndDate: Date?
            var sessionDuration: TimeInterval = 0

            for sample in samples {
                let calendar = Calendar.current
                let date = calendar.startOfDay(for: sample.startDate)

                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    if sessionStartDate == nil {
                        sessionStartDate = sample.startDate
                    }
                    sessionDuration += sample.endDate.timeIntervalSince(sample.startDate)
                    sessionEndDate = sample.endDate
                } else {
                    if let startDate = sessionStartDate, let endDate = sessionEndDate {
                        let dayOfSleep = calendar.startOfDay(for: endDate)
                        let (_, _, existingDuration) = dailySleep[dayOfSleep] ?? (startDate, endDate, 0)
                        dailySleep[dayOfSleep] = (startDate, endDate, existingDuration + sessionDuration)
                    }
                    sessionStartDate = nil
                    sessionEndDate = nil
                    sessionDuration = 0
                }
            }
            completion(dailySleep)
        }

        healthStore.execute(query)
    }

    private func combineData(steps: [Date: Int], weights: [Date: Double], sleep: [Date: (Date, Date, TimeInterval)]) -> [HealthData] {
        var combinedData: [HealthData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else {
                continue
            }

            let stepCount = steps[date]
            let weight = weights[date]
            let sleepData = sleep[date]

            let healthDataItem = HealthData(
                date: date,
                stepCount: stepCount,
                weight: weight,
                sleepStart: sleepData?.0,
                sleepEnd: sleepData?.1,
                sleepDuration: sleepData?.2
            )
            combinedData.append(healthDataItem)
        }
        return combinedData
    }
}
