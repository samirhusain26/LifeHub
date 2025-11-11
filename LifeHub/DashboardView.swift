import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var jsonOutput: String = "JSON output will appear here..."
    
    private let healthKitService = HealthKitService()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Summary Metrics Display
                VStack(alignment: .leading, spacing: 15) {
                    Text("Summary Metrics")
                        .font(.title2).bold()
                    
                    MetricView(label: "Days Since Last Food Order:", value: "\(viewModel.daysSinceLastFoodOrder)")
                    MetricView(label: "Longest Streak (No Orders, 12 Mo):", value: "\(viewModel.longestStreakNoOrders12Mo) days")
                    MetricView(label: "Weight Lost (from heaviest, 12 Mo):", value: String(format: "%.1f kg", viewModel.weightLostFromHeaviest12Mo))
                    MetricView(label: "Average Steps (Last 7 Days):", value: "\(viewModel.averageStepsLast7Days)")
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // JSON Output
                ScrollView {
                    Text(jsonOutput)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                VStack(spacing: 15) {
                    Button("Refresh Metrics") {
                        viewModel.calculateSummaryMetrics(context: modelContext)
                    }
                    .buttonStyle(.bordered)

                    Button("Generate JSON") {
                        if let json = viewModel.generateDashboardPayload() {
                            self.jsonOutput = json
                        } else {
                            self.jsonOutput = "Failed to generate JSON."
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Fetch Health Data (Last 30 Days)") {
                        Task {
                            do {
                                try await healthKitService.requestAuthorization()
                                try await healthKitService.fetchAndSaveHealthData(for: 30, context: modelContext)
                                print("Health data fetched and saved.")
                                // Recalculate metrics after fetching new data
                                viewModel.calculateSummaryMetrics(context: modelContext)
                            } catch {
                                print("Error fetching or saving health data: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("LifeHub Dashboard")
            .onAppear {
                viewModel.calculateSummaryMetrics(context: modelContext)
            }
        }
    }
}

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}


#Preview {
    DashboardView()
        .modelContainer(for: [DailyHealthMetric.self, FoodOrder.self, DailyLog.self], inMemory: true)
}
