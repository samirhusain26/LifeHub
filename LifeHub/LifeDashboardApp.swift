import SwiftUI
import SwiftData

@main
struct LifeDashboardApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: DailyHealthMetric.self, FoodOrder.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: DashboardViewModel(modelContainer: modelContainer))
        }
        .modelContainer(modelContainer)
    }
}
