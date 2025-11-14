import Foundation
import SwiftData
import Observation

@Observable
class DashboardViewModel {
    // MARK: - Metrics
    var activeDayRatio: String = "0/7 Days"
    var energyWoW: String = "0 Kcal (0%)"
    var sleepConsistency: (wake: Double, duration: Double) = (0,0)
    var deliverySpendTrends: String = "30d: $0 (0%) • Yr: $0"
    var cleanStreak: String = "0 Days Clean"
    var weightTrend: String = "-0 lbs from high"
    var weightGap: String = "0 lbs to go"

    // MARK: - Chart Data
    var chartHealthData: [DailyHealthMetric] = []
    var chartFoodData: [FoodOrder] = []

    private var healthData: [DailyHealthMetric] = []
    private var foodData: [FoodOrder] = []
    
    private let modelContainer: ModelContainer
    private var dataModelActor: DataModelActor
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.dataModelActor = DataModelActor(modelContainer: modelContainer)
    }
    
    @MainActor
    func fetchAllData() async throws {
        // Use a descriptor to fetch all data, sorted by date
        let healthDescriptor = FetchDescriptor<DailyHealthMetric>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let foodDescriptor = FetchDescriptor<FoodOrder>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        
        let fetchedHealthData = try modelContainer.mainContext.fetch(healthDescriptor)
        let fetchedFoodData = try modelContainer.mainContext.fetch(foodDescriptor)
        
        self.healthData = fetchedHealthData
        self.foodData = fetchedFoodData
        self.calculateMetrics()
    }

    func refreshMetrics() async throws {
        try await dataModelActor.fetchAllData()
        try await fetchAllData()
    }

    func getRawJson() async -> String {
        await dataModelActor.generateRawDataJson()
    }

    private func calculateMetrics() {
        // Chart Data
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date().startOfDay)!
        self.chartHealthData = healthData.filter { $0.date >= fourteenDaysAgo }
        self.chartFoodData = foodData.filter { $0.date >= fourteenDaysAgo }

        // Metric Calculations
        self.activeDayRatio = calculateActiveDayRatio()
        self.energyWoW = calculateEnergyWoW()
        self.sleepConsistency = calculateSleepConsistency()
        self.deliverySpendTrends = calculateDeliverySpendTrends()
        self.cleanStreak = calculateCleanStreak()
        self.weightTrend = calculateWeightTrend()
        self.weightGap = calculateWeightGap()
    }

    // MARK: - Metric Calculation Functions

    private func calculateActiveDayRatio() -> String {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date().startOfDay)!
        let recentMetrics = healthData.filter { $0.date >= sevenDaysAgo }
        let activeDays = recentMetrics.filter { ($0.steps ?? 0) > 8000 }.count
        return "\(activeDays)/7 Days"
    }

    private func calculateEnergyWoW() -> String {
        let today = Date().startOfDay
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!

        let recentWeekEnergy = healthData
            .filter { $0.date >= sevenDaysAgo && $0.date < today }
            .reduce(0) { $0 + ($1.activeCalories ?? 0) }

        let previousWeekEnergy = healthData
            .filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo }
            .reduce(0) { $0 + ($1.activeCalories ?? 0) }
        
        let percentageChange = calculatePercentageChange(current: recentWeekEnergy, previous: previousWeekEnergy)
        return "\(Int(recentWeekEnergy)) Kcal (\(percentageChange))"
    }

    private func calculateSleepConsistency() -> (wake: Double, duration: Double) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date().startOfDay)!
        let validSleepData = healthData.filter { $0.date >= sevenDaysAgo && ($0.sleepDurationMinutes ?? 0) > 0 }

        guard !validSleepData.isEmpty else { return (0, 0) }

        let wakeTimesInMinutes = validSleepData.compactMap { metric -> Double? in
            guard let wakeTime = metric.sleepWakeTime else { return nil }
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
            return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
        }

        let sleepDurations = validSleepData.compactMap { $0.sleepDurationMinutes }

        let wakeStdDev = wakeTimesInMinutes.standardDeviation()
        let durationStdDev = sleepDurations.standardDeviation()

        return (wakeStdDev, durationStdDev)
    }

    private func calculateDeliverySpendTrends() -> String {
        let today = Date().startOfDay
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: today)!
        let yearAgo = Calendar.current.date(byAdding: .day, value: -365, to: today)!
        let twoYearsAgo = Calendar.current.date(byAdding: .day, value: -730, to: today)!

        let last30dSpend = foodData.filter { $0.date >= thirtyDaysAgo && $0.date < today }.reduce(0) { $0 + $1.totalSpend }
        let prev30dSpend = foodData.filter { $0.date >= sixtyDaysAgo && $0.date < thirtyDaysAgo }.reduce(0) { $0 + $1.totalSpend }

        let last365dSpend = foodData.filter { $0.date >= yearAgo && $0.date < today }.reduce(0) { $0 + $1.totalSpend }
        // Note: This is a simplification. A true YoY would be more complex.
        // This is comparing last 365 days to the 365 days before that.
        let prev365dSpend = foodData.filter { $0.date >= twoYearsAgo && $0.date < yearAgo }.reduce(0) { $0 + $1.totalSpend }

        let momChange = calculatePercentageChange(current: last30dSpend, previous: prev30dSpend)
        let yoyChange = calculatePercentageChange(current: last365dSpend, previous: prev365dSpend)

        return "$\(Int(last30dSpend)) (\(momChange)) • $\(Int(last365dSpend)) (\(yoyChange))"
    }

    private func calculateCleanStreak() -> String {
        guard let lastOrderDate = foodData.max(by: { $0.date < $1.date })?.date else {
            // If no orders, maybe return days since app start or a large number
            return "∞"
        }
        let days = Calendar.current.dateComponents([.day], from: lastOrderDate.startOfDay, to: Date().startOfDay).day ?? 0
        return "\(days)"
    }

    private func calculateWeightTrend() -> String {
        let fortyFiveDaysAgo = Calendar.current.date(byAdding: .day, value: -45, to: Date().startOfDay)!
        let recentMetrics = healthData.filter { $0.date >= fortyFiveDaysAgo && $0.weight != nil }
        
        guard let maxWeight = recentMetrics.compactMap({ $0.weight }).max() else { return "No Weight Data" }
        
        if let currentWeight = healthData.first(where: { $0.weight != nil })?.weight {
            let diff = currentWeight - maxWeight
            return String(format: "%.1f lbs from high", diff)
        }
        
        return "N/A"
    }

    private func calculateWeightGap() -> String {
        if let currentWeight = healthData.first(where: { $0.weight != nil })?.weight {
            let gap = currentWeight - 200.0
            return String(format: "%.1f lbs to go", gap)
        }
        return "N/A"
    }
    
    // MARK: - Helpers

    private func calculatePercentageChange(current: Double, previous: Double) -> String {
        guard previous > 0 else { return "N/A" }
        let change = ((current - previous) / previous) * 100
        let symbol = change >= 0 ? "▲" : "▼"
        return "\(symbol)\(String(format: "%.0f", abs(change)))%"
    }
}

// MARK: - Utility Extensions

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

extension Collection where Element: BinaryFloatingPoint {
    func standardDeviation() -> Element {
        let n = Element(self.count)
        guard n > 1 else { return 0 }
        let mean = self.reduce(0, +) / n
        let sumOfSquaredDeviations = self.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        return sqrt(sumOfSquaredDeviations / (n - 1))
    }
}