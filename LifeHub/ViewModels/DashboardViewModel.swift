import Foundation
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var daysSinceLastFoodOrder: Int = 0
    @Published var longestStreakNoOrders12Mo: Int = 0
    @Published var weightLostFromHeaviest12Mo: Double = 0.0
    @Published var averageStepsLast7Days: Int = 0
    @Published var statusMessage: String = ""
    
    private let dataModelActor: DataModelActor

    init(modelContainer: ModelContainer) {
        self.dataModelActor = DataModelActor(modelContainer: modelContainer)
    }

    func calculateSummaryMetrics() {
        Task {
            self.daysSinceLastFoodOrder = await dataModelActor.calculateDaysSinceLastFoodOrder()
            self.longestStreakNoOrders12Mo = await dataModelActor.calculateLongestStreakNoOrders12Mo()
            self.weightLostFromHeaviest12Mo = await dataModelActor.calculateWeightLostFromHeaviest12Mo()
            self.averageStepsLast7Days = await dataModelActor.calculateAverageStepsLast7Days()
        }
    }

    func fetchAllDataAndRecalculateMetrics() {
        Task {
            statusMessage = "Fetching all data..."
            do {
                try await dataModelActor.fetchAllData()
                statusMessage = "All data fetched and saved."
                calculateSummaryMetrics()
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
                print("Error fetching or saving data: \(error)")
            }
        }
    }

    func encodePayload() async -> String? {
        return await dataModelActor.generateRawDataJson()
    }
}
