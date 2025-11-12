import Foundation
import HealthKit
import SwiftData

class HealthKitService {
    let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "com.example.LifeHub", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."])
        }

        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw NSError(domain: "com.example.LifeHub", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create HealthKit types."])
        }

        let typesToRead: Set<HKObjectType> = [
            bodyMassType,
            stepCountType,
            activeEnergyType,
            sleepAnalysisType
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    func fetchHealthData(for days: Int) async throws -> [DailyHealthMetric] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw NSError(domain: "com.example.LifeHub", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not calculate start date."])
        }

        var metrics: [DailyHealthMetric] = []

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            async let weight = fetchLatestBodyMass(for: date)
            async let steps = fetchCumulativeSum(for: .stepCount, unit: .count(), for: date)
            async let calories = fetchCumulativeSum(for: .activeEnergyBurned, unit: .kilocalorie(), for: date)
            async let sleep = fetchSleepAnalysis(for: date)

            let (weightResult, stepsResult, caloriesResult, sleepResult) = try await (weight, steps, calories, sleep)

            let newMetric = DailyHealthMetric(
                date: date,
                weight: weightResult,
                steps: Int(stepsResult),
                activeCalories: caloriesResult,
                sleepDurationMinutes: sleepResult.totalSleep / 60,
                sleepStartTime: sleepResult.sleepStart,
                sleepWakeTime: sleepResult.wakeTime
            )
            metrics.append(newMetric)
        }
        
        return metrics
    }

    private func fetchLatestBodyMass(for date: Date) async throws -> Double? {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    if let hkError = error as? HKError, hkError.code == .errorNoData {
                        continuation.resume(returning: nil) // No data, return nil
                    } else {
                        continuation.resume(throwing: error) // Other error, throw it
                    }
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: .pound()))
            }
            healthStore.execute(query)
        }
    }

    internal func fetchCumulativeSum(for quantityTypeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, for date: Date) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
                            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                                if let error = error {
                                    // Check if the error is due to no data
                                    if let hkError = error as? HKError, hkError.code == .errorNoData {
                                        continuation.resume(returning: 0) // No data, return 0
                                    } else {
                                        continuation.resume(throwing: error) // Other error, throw it
                                    }
                                    return
                                }
                let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepAnalysis(for date: Date) async throws -> (totalSleep: TimeInterval, sleepStart: Date?, wakeTime: Date?) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, nil, nil)
        }

        let calendar = Calendar.current
        guard let startOfNight = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: date)!),
              let endOfNight = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) else {
            return (0, nil, nil)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfNight, end: endOfNight, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    if let hkError = error as? HKError, hkError.code == .errorNoData {
                        continuation.resume(returning: (0, nil, nil)) // No data, return default
                    } else {
                        continuation.resume(throwing: error) // Other error, throw it
                    }
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: (0, nil, nil))
                    return
                }

                let totalSleep = sleepSamples.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let sleepStart = sleepSamples.first(where: { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue || $0.value >= HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue })?.startDate
                let wakeTime = sleepSamples.last?.endDate

                continuation.resume(returning: (totalSleep, sleepStart, wakeTime))
            }
            healthStore.execute(query)
        }
    }
}
