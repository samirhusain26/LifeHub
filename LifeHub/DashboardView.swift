import SwiftUI

struct DashboardView: View {
    @ObservedObject private var health = HealthKitManager.shared
    @StateObject private var orderFetcher = FoodOrderFetcher()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Weight: \(health.currentWeight ?? 0, specifier: "%.1f")")
                    Text("Average Steps: \(health.averageSteps ?? 0, specifier: "%.0f")")
                    Text("Sleep Hours: \(health.sleepHours ?? 0, specifier: "%.1f")")
                    Text("Days since last order: \(orderFetcher.daysSinceLastOrder())")
                    Text("Longest healthy streak: \(orderFetcher.longestStreak()) days")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            health.fetchHealthData()
        }
        .task {
            // Replace with your sheet URL
            if let url = URL(string: "https://example.com/orders.csv") {
                try? await orderFetcher.fetch(from: url)
            }
        }
    }
}

#Preview {
    DashboardView()
}
