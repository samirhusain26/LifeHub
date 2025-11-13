import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var jsonOutput: String = "JSON output will appear here..."
    
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Summary Metrics Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        MetricCardView(
                            title: "Weight Loss",
                            value: String(format: "%.1f lbs", viewModel.weightLostFromHeaviest12Mo),
                            iconName: "scalemass.fill"
                        )
                        MetricCardView(
                            title: "Avg. Steps (7d)",
                            value: "\(viewModel.averageStepsLast7Days)",
                            iconName: "figure.walk"
                        )
                        MetricCardView(
                            title: "Days Since Order",
                            value: "\(viewModel.daysSinceLastFoodOrder)",
                            iconName: "cart.fill"
                        )
                        MetricCardView(
                            title: "Longest Streak",
                            value: "\(viewModel.longestStreakNoOrders12Mo) days",
                            iconName: "flame.fill"
                        )
                    }
                    .padding(.horizontal)

                    // JSON Output
                    ScrollView {
                        Text(jsonOutput)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 15) {
                        Button("Refresh All Data") {
                            viewModel.fetchAllDataAndRecalculateMetrics()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Generate JSON") {
                            Task {
                                if let json = await viewModel.encodePayload() {
                                    self.jsonOutput = json
                                    UIPasteboard.general.string = json
                                } else {
                                    self.jsonOutput = "Failed to generate JSON."
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("LifeHub Dashboard")
            .onAppear {
                viewModel.calculateSummaryMetrics()
            }
            .background(Color(.systemGroupedBackground)) // Use a grouped background for better contrast
        }
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(.accentColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


#Preview {
    let container = try! ModelContainer(for: DailyHealthMetric.self, FoodOrder.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = DashboardViewModel(modelContainer: container)
    DashboardView(viewModel: viewModel)
        .modelContainer(container)
}
