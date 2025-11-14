import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showAnnotationView = true
    @State private var showDataPointView = true
    @State private var isCopying = false
    
    init(modelContainer: ModelContainer) {
        _viewModel = State(initialValue: DashboardViewModel(modelContainer: modelContainer))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Liquid Glass title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LifeHub")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            HStack(alignment: .center, spacing: 12) {
                                Text("Your Health Dashboard")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                // Actions Dropdown Menu
                                Menu {
                                    Button(action: {
                                        Task {
                                            isRefreshing = true
                                            do {
                                                try await viewModel.refreshMetrics()
                                            } catch {
                                                errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                                                showingError = true
                                            }
                                            isRefreshing = false
                                        }
                                    }) {
                                        Label("Refresh Data", systemImage: "arrow.clockwise")
                                    }
                                    .disabled(isRefreshing)
                                    
                                    Button(action: {
                                        Task {
                                            isCopying = true
                                            let jsonString = await viewModel.getRawJson()
                                            #if os(iOS)
                                            UIPasteboard.general.string = jsonString
                                            #endif
                                            
                                            // Add haptic feedback
                                            HapticFeedback.success()
                                            
                                            isCopying = false
                                        }
                                    }) {
                                        Label(isCopying ? "Copying..." : "Copy Data as JSON", systemImage: "doc.on.doc")
                                    }
                                    .disabled(isCopying)
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        withAnimation(.smooth(duration: 0.3)) {
                                            showAnnotationView.toggle()
                                        }
                                    }) {
                                        Label(
                                            showAnnotationView ? "Hide Annotations" : "Show Annotations",
                                            systemImage: showAnnotationView ? "eye.slash" : "eye"
                                        )
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.smooth(duration: 0.3)) {
                                            showDataPointView.toggle()
                                        }
                                    }) {
                                        Label(
                                            showDataPointView ? "Hide Data Details" : "Show Data Details",
                                            systemImage: showDataPointView ? "chart.bar.xaxis.ascending" : "chart.bar.xaxis.ascending.badge.clock"
                                        )
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Actions")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .imageScale(.small)
                                    }
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1), in: .capsule)
                                }
                            }
                            if let lastUpdated = viewModel.chartHealthData.max(by: { $0.date < $1.date })?.date {
                                Text("Last updated: \(lastUpdated, formatter: Self.dateFormatter)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Health Stack Chart
                    HealthStackChart(
                        healthData: viewModel.chartHealthData,
                        foodData: viewModel.chartFoodData,
                        showAnnotationView: $showAnnotationView,
                        showDataPointView: $showDataPointView
                    )
                    .padding(.horizontal, 20)

                    // Metrics Grid with Glass Effect Container
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        MetricCardView(
                            title: "Active Days (L14D)",
                            value: viewModel.activeDayRatio,
                            iconName: "figure.run",
                            definition: "An 'active day' is any day where you exceed 8,000 steps. This metric shows the number of active days in the last 14 days."
                        )
                        
                        MetricCardView(
                            title: "Energy WoW",
                            value: viewModel.energyWoW,
                            iconName: "flame.fill",
                            definition: "This metric compares the average daily active energy burn of the last 7 days to the 7 days prior."
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    SleepConsistencyView(sleepConsistency: viewModel.sleepConsistency)
                        .padding(.horizontal, 20)
                    
                    FoodOrderMetricsView(
                        deliverySpendTrends: viewModel.deliverySpendTrends,
                        cleanStreak: viewModel.cleanStreak
                    )
                    .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        MetricCardView(
                            title: "Weight Trend (L45D)",
                            value: viewModel.weightTrend,
                            iconName: "chart.line.downtrend.xyaxis",
                            definition: "This metric shows the weight trend over the last 45 days, indicating progress from the highest recorded weight in that period."
                        )
                        
                        MetricCardView(
                            title: "Weight Goal",
                            value: viewModel.weightGap,
                            iconName: "scalemass",
                            definition: "This metric shows the difference between your current weight and your target weight of 200 lbs."
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.systemBackground).opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .refreshable {
                do {
                    try await viewModel.fetchAllData()
                } catch {
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                    showingError = true
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
                Button("Retry") {
                    Task {
                        do {
                            try await viewModel.refreshMetrics()
                        } catch {
                            errorMessage = "Retry failed: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .overlay(alignment: .top) {
                if isRefreshing {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: .capsule)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.smooth(duration: 0.3), value: isRefreshing)
                }
            }
        }
        .task {
            do {
                try await viewModel.fetchAllData()
            } catch {
                errorMessage = "Failed to load initial data: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    @Previewable @State var container = {
        let container = try! ModelContainer(
            for: DailyHealthMetric.self, FoodOrder.self, 
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        // Add some mock data for a better preview
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
        
        return container
    }()
    
    DashboardView(modelContainer: container)
        .modelContainer(container)
}