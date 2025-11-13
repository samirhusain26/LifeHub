import Foundation
import SwiftData
import TabularData

// New Codable struct to hold raw data for JSON serialization
public struct RawDataPayload: Codable {
    let foodOrders: [FoodOrder]
    let healthMetrics: [DailyHealthMetric]
}

@ModelActor
actor DataModelActor {
    
    private let foodOrderFetcher = FoodOrderFetcher()
    private let healthKitService = HealthKitService()

    func fetchAllData() async throws {
        try await healthKitService.requestAuthorization()
        
        // Fetch and save health data
        let healthMetrics = try await healthKitService.fetchHealthData(for: 365)
        try saveHealthData(metrics: healthMetrics)
        
        // Fetch and save food orders
        let urlString = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQDoNEE-pV_G7CiDV9EPBNB4tKUU5nT0PJlnETrEVsJnxyiW__Et0IqU7UkOWGvLfy3jg8rc-EEBgXE/pub?gid=0&single=true&output=csv"
        let foodOrders = try await foodOrderFetcher.fetchFoodOrders(from: urlString)
        try upsertFoodOrders(orders: foodOrders)
    }

    private func upsertFoodOrders(orders: [Date: FoodOrderFetcher.OrderData]) throws {
        for (date, data) in orders {
            let fetchDescriptor = FetchDescriptor<FoodOrder>(
                predicate: #Predicate { $0.date == date }
            )

            if let existingOrder = try modelContext.fetch(fetchDescriptor).first {
                existingOrder.totalSpend = data.totalSpend
                existingOrder.orderCount = data.messageIds.count
            } else {
                let newOrder = FoodOrder(date: date, totalSpend: data.totalSpend, orderCount: data.messageIds.count)
                modelContext.insert(newOrder)
            }
        }
        try modelContext.save()
    }
    
    func calculateDaysSinceLastFoodOrder() -> Int {
        let descriptor = FetchDescriptor<FoodOrder>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            let orders = try modelContext.fetch(descriptor)
            if let lastOrder = orders.first {
                return Calendar.current.dateComponents([.day], from: lastOrder.date, to: Date()).day ?? 0
            }
        } catch {
            print("Failed to fetch food orders: \(error)")
        }
        return 0
    }

    func calculateLongestStreakNoOrders12Mo() -> Int {
        let twelveMonthsAgo = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let descriptor = FetchDescriptor<FoodOrder>(
            predicate: #Predicate { $0.date >= twelveMonthsAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let orders = try modelContext.fetch(descriptor)
            guard !orders.isEmpty else {
                return 365 // Or calculate days since 12 months ago
            }

            var longestStreak = 0
            
            // Streak from 12 months ago to the first order
            var lastDate = twelveMonthsAgo
            if let firstOrder = orders.first {
                longestStreak = Calendar.current.dateComponents([.day], from: lastDate, to: firstOrder.date).day ?? 0
                lastDate = firstOrder.date
            }

            // Streaks between orders
            for order in orders.dropFirst() {
                let streak = Calendar.current.dateComponents([.day], from: lastDate, to: order.date).day ?? 0
                if streak > longestStreak {
                    longestStreak = streak
                }
                lastDate = order.date
            }

            // Streak from the last order to today
            let finalStreak = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if finalStreak > longestStreak {
                longestStreak = finalStreak
            }
            
            return longestStreak
        } catch {
            print("Failed to fetch food orders for streak calculation: \(error)")
            return 0
        }
    }

    func calculateWeightLostFromHeaviest12Mo() -> Double {
        let twelveMonthsAgo = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let descriptor = FetchDescriptor<DailyHealthMetric>(
            predicate: #Predicate { $0.date >= twelveMonthsAgo && $0.weight != nil }
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            let weights = metrics.compactMap { $0.weight }
            guard let heaviest = weights.max() else { return 0 }
            
            // Find most recent weight
            let recentDescriptor = FetchDescriptor<DailyHealthMetric>(
                predicate: #Predicate { $0.weight != nil },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let recentMetrics = try modelContext.fetch(recentDescriptor)
            if let mostRecentWeight = recentMetrics.first?.weight {
                return heaviest - mostRecentWeight
            }
        }
        catch {
            print("Failed to fetch health metrics for weight calculation: \(error)")
        }
        return 0
    }

    func calculateAverageStepsLast7Days() -> Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let descriptor = FetchDescriptor<DailyHealthMetric>(
            predicate: #Predicate { $0.date >= sevenDaysAgo }
        )
        
        do {
            let metrics = try modelContext.fetch(descriptor)
            let totalSteps = metrics.reduce(0) { $0 + ($1.steps ?? 0) }
            return metrics.isEmpty ? 0 : totalSteps / metrics.count
        } catch {
            print("Failed to fetch health metrics for step calculation: \(error)")
        }
        return 0
    }
    
    func generateRawDataJson() -> String {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        let foodOrdersDescriptor = FetchDescriptor<FoodOrder>(
            predicate: #Predicate { $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let healthMetricsDescriptor = FetchDescriptor<DailyHealthMetric>(
            predicate: #Predicate { $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let foodOrders = try modelContext.fetch(foodOrdersDescriptor)
            let healthMetrics = try modelContext.fetch(healthMetricsDescriptor)
            
            let payload = RawDataPayload(foodOrders: foodOrders, healthMetrics: healthMetrics)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let jsonData = try encoder.encode(payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            else {
                return "Failed to generate raw data JSON."
            }
        } catch {
            return "Error generating raw data: \(error.localizedDescription)"
        }
    }
    
    func saveHealthData(metrics: [DailyHealthMetric]) throws {
        let sortedMetrics = metrics.sorted { $0.date < $1.date }

        var lastKnownWeight: Double?
        if let firstDate = sortedMetrics.first?.date {
            let descriptor = FetchDescriptor<DailyHealthMetric>(
                predicate: #Predicate { $0.date < firstDate && $0.weight != nil },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            lastKnownWeight = try modelContext.fetch(descriptor).first?.weight
        }

        for metric in sortedMetrics {
            if metric.weight == nil {
                metric.weight = lastKnownWeight
            } else {
                lastKnownWeight = metric.weight
            }

            let startOfDay = Calendar.current.startOfDay(for: metric.date)
            let fetchDescriptor = FetchDescriptor<DailyHealthMetric>(
                predicate: #Predicate { $0.date == startOfDay }
            )

            if let existingMetric = try modelContext.fetch(fetchDescriptor).first {
                existingMetric.weight = metric.weight ?? existingMetric.weight
                existingMetric.steps = metric.steps ?? existingMetric.steps
                existingMetric.activeCalories = metric.activeCalories ?? existingMetric.activeCalories
                existingMetric.sleepDurationMinutes = metric.sleepDurationMinutes ?? existingMetric.sleepDurationMinutes
                existingMetric.sleepStartTime = metric.sleepStartTime ?? existingMetric.sleepStartTime
                existingMetric.sleepWakeTime = metric.sleepWakeTime ?? existingMetric.sleepWakeTime
            } else {
                modelContext.insert(metric)
            }
        }

        try modelContext.save()
    }

    // MARK: - Test Helpers
    
    func insertMetric(_ metric: DailyHealthMetric) {
        modelContext.insert(metric)
    }
    
    func fetchMetrics(descriptor: FetchDescriptor<DailyHealthMetric>) throws -> [DailyHealthMetric] {
        try modelContext.fetch(descriptor)
    }
    
    func save() throws {
        try modelContext.save()
    }
}
