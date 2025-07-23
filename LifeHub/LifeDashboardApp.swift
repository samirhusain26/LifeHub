import SwiftUI

@main
struct LifeDashboardApp: App {
    init() {
        HealthKitManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "house") }
                MoodLoggerView()
                    .tabItem { Label("Log", systemImage: "square.and.pencil") }
                Text("Food Orders")
                    .tabItem { Label("Food Orders", systemImage: "cart") }
                Text("Settings")
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
        }
    }
}
