import XCTest
import SwiftData
@testable import LifeHub

class DataModelActorTests: XCTestCase {

    var modelContainer: ModelContainer!
    var dataModelActor: DataModelActor!

    @MainActor
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: DailyHealthMetric.self, FoodOrder.self, configurations: config)
        dataModelActor = DataModelActor(modelContainer: modelContainer)
    }

    override func tearDown() {
        modelContainer = nil
        dataModelActor = nil
    }

    @MainActor
    func testWeightCarryOver() async throws {
        // 1. Setup initial data with a known weight
        let calendar = Calendar.current
        let day1 = calendar.date(byAdding: .day, value: -3, to: Date())!
        let metric1 = DailyHealthMetric(date: day1, weight: 150.0, steps: nil, activeCalories: nil, sleepDurationMinutes: nil, sleepStartTime: nil, sleepWakeTime: nil)
        await dataModelActor.insertMetric(metric1)
        try await dataModelActor.save()

        // 2. Prepare new metrics with missing weights
        let day2 = calendar.date(byAdding: .day, value: -2, to: Date())!
        let day3 = calendar.date(byAdding: .day, value: -1, to: Date())!
        let day4 = Date()

        let newMetrics = [
            DailyHealthMetric(date: day2, weight: nil, steps: 1000, activeCalories: 100, sleepDurationMinutes: nil, sleepStartTime: nil, sleepWakeTime: nil),
            DailyHealthMetric(date: day3, weight: 152.0, steps: 2000, activeCalories: 200, sleepDurationMinutes: nil, sleepStartTime: nil, sleepWakeTime: nil),
            DailyHealthMetric(date: day4, weight: nil, steps: 3000, activeCalories: 300, sleepDurationMinutes: nil, sleepStartTime: nil, sleepWakeTime: nil)
        ]

        // 3. Run the function to be tested
        try await dataModelActor.saveHealthData(metrics: newMetrics)

        // 4. Assert the results
        let descriptor = FetchDescriptor<DailyHealthMetric>(sortBy: [SortDescriptor(\.date)])
        let savedMetrics = try await dataModelActor.fetchMetrics(descriptor: descriptor)

        XCTAssertEqual(savedMetrics.count, 4)

        // Find metrics for each day and assert their weights
        let metricForDay2 = savedMetrics.first { calendar.isDate($0.date, inSameDayAs: day2) }
        XCTAssertEqual(metricForDay2?.weight, 150.0, "Day 2 weight should be carried over from day 1")

        let metricForDay3 = savedMetrics.first { calendar.isDate($0.date, inSameDayAs: day3) }
        XCTAssertEqual(metricForDay3?.weight, 152.0, "Day 3 should have its own recorded weight")

        let metricForDay4 = savedMetrics.first { calendar.isDate($0.date, inSameDayAs: day4) }
        XCTAssertEqual(metricForDay4?.weight, 152.0, "Day 4 weight should be carried over from day 3")
    }
}
