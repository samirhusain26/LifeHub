import SwiftUI
import SwiftData

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: [DailyHealthMetric.self, FoodOrder.self, DailyLog.self])
    }
}
