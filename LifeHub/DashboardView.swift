import SwiftUI
import SwiftData

struct DashboardView: View {
    @State var viewModel: DashboardViewModel

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("LifeHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Health Stack Chart
                    HealthStackChart(
                        healthData: viewModel.chartHealthData,
                        foodData: viewModel.chartFoodData,
                        onRefresh: viewModel.refreshMetrics,
                        onCopyJson: viewModel.getRawJson
                    )
                    .padding(.horizontal)

                    // Metrics Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        MetricCardView(title: "Active Days (L7D)", value: viewModel.activeDayRatio, iconName: "figure.run")
                        MetricCardView(title: "Energy WoW", value: viewModel.energyWoW, iconName: "flame.fill")
                        MetricCardView(title: "Sleep Consistency", value: viewModel.sleepConsistency, iconName: "bed.double.fill")
                        MetricCardView(title: "Delivery Spend", value: viewModel.deliverySpendTrends, iconName: "fork.knife")
                        MetricCardView(title: "Clean Streak", value: viewModel.cleanStreak, iconName: "leaf.fill")
                        MetricCardView(title: "Weight Trend (L45D)", value: viewModel.weightTrend, iconName: "chart.line.downtrend.xyaxis")
                        MetricCardView(title: "Weight Goal", value: viewModel.weightGap, iconName: "scalemass")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                viewModel.fetchAllData()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: DailyHealthMetric.self, FoodOrder.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = DashboardViewModel(modelContainer: container)
    
    // Add some mock data for a better preview
    Task { @MainActor in
        let context = container.mainContext
        let today = Date()
        for i in 0..<90 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            let metric = DailyHealthMetric(
                date: date,
                weight: 210.0 - Double(i)/5.0,
                steps: 7000 + Int.random(in: -2000...5000),
                activeCalories: 600 + Double.random(in: -150...200),
                sleepDurationMinutes: 420 + Double.random(in: -80...60),
                sleepWakeTime: Calendar.current.date(byAdding: .minute, value: Int.random(in: -30...30), to: date.addingTimeInterval(8*60*60))
            )
            context.insert(metric)
        }
        for i in [3, 10, 25, 40, 50] {
             let order = FoodOrder(
                date: Calendar.current.date(byAdding: .day, value: -i, to: today)!,
                totalSpend: Double.random(in: 20...50),
                orderCount: 1
             )
            context.insert(order)
        }
        viewModel.fetchAllData()
    }
    
    return DashboardView(viewModel: viewModel)
        .modelContainer(container)
}