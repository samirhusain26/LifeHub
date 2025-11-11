import Foundation

struct DashboardPayload: Codable {
    let lastUpdated: Date
    let daysSinceLastFoodOrder: Int
    let longestStreakNoOrders12Mo: Int
    let weightLostFromHeaviest12Mo: Double
    let averageStepsLast7Days: Int
}
