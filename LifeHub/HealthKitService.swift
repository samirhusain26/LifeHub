import Foundation
import HealthKit
import SwiftData

/// Service class for interacting with Apple's HealthKit framework
///
/// This service:
/// - Requests authorization for health data access
/// - Fetches historical health data (steps, calories, sleep, weight)
/// - Aggregates data by day for consistency
/// - Handles errors gracefully
///
/// **Supported Data Types:**
/// - Body Mass (weight in pounds)
/// - Step Count (daily total)
/// - Active Energy Burned (calories)
/// - Sleep Analysis (duration and timing)
///
/// **Usage:**
/// ```swift
/// let service = HealthKitService()
/// try await service.requestAuthorization()
/// let metrics = try await service.fetchHealthData(for: 30)
/// ```
class HealthKitService {
    // MARK: - Properties
    
    /// The HealthKit store for querying health data
    let healthStore = HKHealthStore()

    // MARK: - Authorization
    
    /// Requests user authorization to read health data
    ///
    /// This method:
    /// 1. Checks if HealthKit is available on the device
    /// 2. Creates quantity/category types for each metric
    /// 3. Requests read permission from the user
    ///
    /// - Throws: NSError if HealthKit is unavailable or types can't be created
    ///
    /// **Required Permissions:**
    /// - Body Mass (read)
    /// - Step Count (read)
    /// - Active Energy Burned (read)
    /// - Sleep Analysis (read)
    func requestAuthorization() async throws {
        // Check if HealthKit is available (not available on iPad)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "com.example.LifeHub", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."])
        }

        // Create quantity types for numeric health data
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw NSError(domain: "com.example.LifeHub", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create HealthKit types."])
        }

        // Define which types we want to read (no write access needed)
        let typesToRead: Set<HKObjectType> = [
            bodyMassType,
            stepCountType,
            activeEnergyType,
            sleepAnalysisType
        ]

        // Request authorization (shows permission dialog to user)
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    // MARK: - Data Fetching
    
    /// Fetches health data for a specified number of days
    ///
    /// This method:
    /// 1. Calculates date range (today back N days)
    /// 2. Fetches each metric type concurrently using async/await
    /// 3. Combines results into DailyHealthMetric objects
    /// 4. Returns array sorted by date
    ///
    /// - Parameter days: Number of days to fetch (e.g., 30, 90, 365)
    /// - Returns: Array of DailyHealthMetric objects, one per day
    /// - Throws: NSError if date calculation fails or queries error
    ///
    /// **Performance:** Uses concurrent fetching with async let for faster results
    func fetchHealthData(for days: Int) async throws -> [DailyHealthMetric] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        
        // Calculate start date by going back N days
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw NSError(domain: "com.example.LifeHub", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not calculate start date."])
        }

        var metrics: [DailyHealthMetric] = []

        // Iterate through each day in the range
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            // Fetch all metrics for this day concurrently
            async let weight = fetchLatestBodyMass(for: date)
            async let steps = fetchCumulativeSum(for: .stepCount, unit: .count(), for: date)
            async let calories = fetchCumulativeSum(for: .activeEnergyBurned, unit: .kilocalorie(), for: date)
            async let sleep = fetchSleepAnalysis(for: date)

            // Wait for all async operations to complete
            let (weightResult, stepsResult, caloriesResult, sleepResult) = try await (weight, steps, calories, sleep)

            // Create metric object with fetched data
            let newMetric = DailyHealthMetric(
                date: date,
                weight: weightResult,
                steps: Int(stepsResult),
                activeCalories: caloriesResult,
                sleepDurationMinutes: sleepResult.totalSleep / 60,  // Convert seconds to minutes
                sleepStartTime: sleepResult.sleepStart,
                sleepWakeTime: sleepResult.wakeTime
            )
            metrics.append(newMetric)
        }
        
        return metrics
    }

    // MARK: - Private Helper Methods
    
    /// Fetches the most recent body mass (weight) measurement for a given day
    ///
    /// - Parameter date: The date to fetch weight for
    /// - Returns: Weight in pounds, or nil if no data available
    /// - Throws: HKError if query fails (except for no data)
    ///
    /// **Behavior:** Returns the last recorded weight during the day
    private func fetchLatestBodyMass(for date: Date) async throws -> Double? {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        // Query for samples within this day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    // Handle "no data" error gracefully
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
                // Convert to pounds
                continuation.resume(returning: sample.quantity.doubleValue(for: .pound()))
            }
            healthStore.execute(query)
        }
    }

    /// Fetches the cumulative sum of a quantity type for a given day
    ///
    /// Used for metrics that accumulate throughout the day (steps, calories).
    ///
    /// - Parameters:
    ///   - quantityTypeIdentifier: The type of data to fetch (e.g., stepCount)
    ///   - unit: The unit to return the value in (e.g., count, kilocalorie)
    ///   - date: The date to fetch data for
    /// - Returns: Cumulative sum for the day, or 0 if no data
    /// - Throws: HKError if query fails (except for no data)
    internal func fetchCumulativeSum(for quantityTypeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, for date: Date) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: quantityTypeIdentifier) else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        // Query for samples within this day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    // Handle "no data" error gracefully
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

    /// Fetches sleep analysis data for a given night
    ///
    /// Sleep tracking typically starts the evening before and ends in the morning.
    /// This method queries from 6 PM the previous day to 6 PM the target day.
    ///
    /// - Parameter date: The date to fetch sleep for (morning of wake-up)
    /// - Returns: Tuple containing total sleep time (seconds), start time, and wake time
    /// - Throws: HKError if query fails (except for no data)
    ///
    /// **Sleep Stages Counted:**
    /// - Core Sleep
    /// - Deep Sleep
    /// - REM Sleep
    ///
    /// **Excluded:**
    /// - Awake time
    /// - In Bed but not asleep
    private func fetchSleepAnalysis(for date: Date) async throws -> (totalSleep: TimeInterval, sleepStart: Date?, wakeTime: Date?) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, nil, nil)
        }

        let calendar = Calendar.current
        
        // Query from 6 PM yesterday to 6 PM today to capture full sleep cycle
        guard let startOfNight = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: date)!),
              let endOfNight = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) else {
            return (0, nil, nil)
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfNight, end: endOfNight, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    // Handle "no data" error gracefully
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

                // Sum up only actual sleep stages (exclude awake/in-bed)
                let totalSleep = sleepSamples.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                }.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                // Find first sleep start time (could be "in bed" or actual sleep)
                let sleepStart = sleepSamples.first(where: { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue || $0.value >= HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue })?.startDate
                
                // Last sample's end date is wake time
                let wakeTime = sleepSamples.last?.endDate

                continuation.resume(returning: (totalSleep, sleepStart, wakeTime))
            }
            healthStore.execute(query)
        }
    }
}
