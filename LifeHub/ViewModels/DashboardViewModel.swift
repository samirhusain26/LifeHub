import Foundation
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var daysSinceLastFoodOrder: Int = 0
    @Published var longestStreakNoOrders12Mo: Int = 0
    @Published var weightLostFromHeaviest12Mo: Double = 0.0
    @Published var averageStepsLast7Days: Int = 0
    @Published var statusMessage: String = ""
    
    private let healthKitService = HealthKitService()

    func calculateSummaryMetrics(context: ModelContext) {
        Task {
            self.daysSinceLastFoodOrder = await calculateDaysSinceLastFoodOrder(context: context)
            self.longestStreakNoOrders12Mo = await calculateLongestStreakNoOrders12Mo(context: context)
            self.weightLostFromHeaviest12Mo = await calculateWeightLostFromHeaviest12Mo(context: context)
            self.averageStepsLast7Days = await calculateAverageStepsLast7Days(context: context)
        }
    }

    private func calculateDaysSinceLastFoodOrder(context: ModelContext) async -> Int {
        let descriptor = FetchDescriptor<FoodOrder>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            let orders = try context.fetch(descriptor)
            if let lastOrder = orders.first {
                return Calendar.current.dateComponents([.day], from: lastOrder.date, to: Date()).day ?? 0
            }
        } catch {
            print("Failed to fetch food orders: \(error)")
        }
        return 0
    }

    private func calculateLongestStreakNoOrders12Mo(context: ModelContext) async -> Int {
        let twelveMonthsAgo = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let descriptor = FetchDescriptor<FoodOrder>(
            predicate: #Predicate { $0.date >= twelveMonthsAgo },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let orders = try context.fetch(descriptor)
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

    private func calculateWeightLostFromHeaviest12Mo(context: ModelContext) async -> Double {
        let twelveMonthsAgo = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let descriptor = FetchDescriptor<DailyHealthMetric>(
            predicate: #Predicate { $0.date >= twelveMonthsAgo && $0.weight != nil }
        )
        
        do {
            let metrics = try context.fetch(descriptor)
            let weights = metrics.compactMap { $0.weight }
            guard let heaviest = weights.max() else { return 0 }
            
            // Find most recent weight
            let recentDescriptor = FetchDescriptor<DailyHealthMetric>(
                predicate: #Predicate { $0.weight != nil },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let recentMetrics = try context.fetch(recentDescriptor)
            if let mostRecentWeight = recentMetrics.first?.weight {
                return heaviest - mostRecentWeight
            }
        } catch {
            print("Failed to fetch health metrics for weight calculation: \(error)")
        }
        return 0
    }

    private func calculateAverageStepsLast7Days(context: ModelContext) async -> Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let descriptor = FetchDescriptor<DailyHealthMetric>(
            predicate: #Predicate { $0.date >= sevenDaysAgo }
        )
        
        do {
            let metrics = try context.fetch(descriptor)
            let totalSteps = metrics.reduce(0) { $0 + ($1.steps ?? 0) }
            return metrics.isEmpty ? 0 : totalSteps / metrics.count
        } catch {
            print("Failed to fetch health metrics for step calculation: \(error)")
        }
        return 0
    }
    func fetchHealthData(context: ModelContext) {
        Task {
            do {
                try await healthKitService.requestAuthorization()
                statusMessage = "Fetching data..."
                try await healthKitService.fetchAndSaveHealthData(for: 30, context: context)
                statusMessage = "Health data fetched and saved."
                // Recalculate metrics after fetching new data
                calculateSummaryMetrics(context: context)
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
                print("Error fetching or saving health data: \(error)")
            }
        }
    }

    func encodePayload() -> String? {
        let payload = DashboardPayload(
            lastUpdated: Date(),
            daysSinceLastFoodOrder: self.daysSinceLastFoodOrder,
            longestStreakNoOrders12Mo: self.longestStreakNoOrders12Mo,
            weightLostFromHeaviest12Mo: self.weightLostFromHeaviest12Mo,
            averageStepsLast7Days: self.averageStepsLast7Days
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(payload)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to encode dashboard payload: \(error)")
            return nil
        }
    }
}
