import SwiftUI
import Charts

/// Interactive health chart displaying 14 days of health metrics with food order overlays
///
/// This view creates a stacked visualization combining:
/// - Bar chart for active calories (primary metric)
/// - Line chart for sleep hours (secondary metric)
/// - Food order indicators (bottom annotations)
/// - Tap-to-reveal detailed data point information
///
/// **Design Features:**
/// - iOS 26 Liquid Glass design language
/// - Smooth animations and transitions
/// - Interactive gestures with haptic feedback
/// - Accessibility support for VoiceOver
///
/// **Data Flow:**
/// 1. Receives health and food data arrays
/// 2. Transforms into unified `ChartDataPoint` model
/// 3. Renders interactive chart with Swift Charts
/// 4. Handles user interactions for data exploration
struct HealthStackChart: View {
    // MARK: - Properties
    
    /// Array of daily health metrics (steps, calories, sleep, weight)
    let healthData: [DailyHealthMetric]
    
    /// Array of food orders aggregated by date
    let foodData: [FoodOrder]
    
    /// Controls visibility of all chart annotations and indicators
    @Binding var showAnnotationView: Bool
    
    /// Controls visibility of detailed metrics in annotation bubbles
    @Binding var showDataPointView: Bool

    /// Currently selected data point for detailed view (nil = none selected)
    @State private var selectedDataPoint: ChartDataPoint?
    
    /// Namespace for coordinating glass effect morphing animations
    @Namespace private var glassNamespace
    
    // MARK: - Customization Properties
    
    /// Primary color scheme for the chart container (soft blue by default)
    var colorScheme: Color = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    /// Corner radius for the glass effect container
    var cornerRadius: CGFloat = 20
    
    /// Horizontal padding for chart elements
    var padding: CGFloat = 8
    
    /// Chart title (currently unused but available for customization)
    var title: String = "14-Day Activity"
    
    /// Font size for chart labels (currently unused)
    var fontSize: Font = .headline
    
    /// Fixed height of the chart area
    var height: CGFloat = 200
    
    /// Animation style for all chart interactions
    var animation: Animation = .smooth(duration: 0.4)

    // MARK: - Computed Properties
    
    /// Transforms raw health and food data into unified chart data points
    ///
    /// **Process:**
    /// 1. Groups health metrics by start of day
    /// 2. Groups food orders by start of day
    /// 3. Combines into single data point per day
    /// 4. Converts sleep minutes to hours for better visualization
    /// 5. Sorts chronologically
    ///
    /// - Returns: Array of `ChartDataPoint` objects sorted by date
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        
        // Group health data by date (one entry per day expected)
        let dataMap = Dictionary(grouping: healthData, by: { calendar.startOfDay(for: $0.date) })
        
        // Group food data by date (one entry per day expected)
        let foodMap = Dictionary(grouping: foodData, by: { calendar.startOfDay(for: $0.date) })

        return dataMap.map { date, metrics -> ChartDataPoint in
            // Should only be one metric per day, but use .first to be safe
            let dayMetrics = metrics.first
            
            // Convert sleep duration from minutes to hours for better readability
            let sleepInHours = (dayMetrics?.sleepDurationMinutes ?? 0) / 60.0
            
            // Extract food spending for this day (if any)
            let spend = foodMap[date]?.first?.totalSpend
            
            return ChartDataPoint(
                date: date,
                activeCalories: dayMetrics?.activeCalories ?? 0,
                sleepHours: sleepInHours,
                steps: Double(dayMetrics?.steps ?? 0),
                foodOrderSpend: spend
            )
        }.sorted(by: { $0.date < $1.date })
    }
    
    /// Scales sleep hours to match the calorie scale for better visual representation
    ///
    /// Sleep typically ranges from 6-9 hours, while calories range from 200-800.
    /// This function maps sleep hours to a comparable scale so both metrics
    /// can be displayed on the same chart without the sleep line being too small.
    ///
    /// **Formula:** sleepHours * 50
    /// - Example: 8 hours → 400 (middle of calorie range)
    /// - Example: 6 hours → 300 (lower range)
    /// - Example: 9 hours → 450 (upper-middle range)
    ///
    /// - Parameter sleepHours: Actual sleep duration in hours
    /// - Returns: Scaled value suitable for chart display alongside calories
    private func scaledSleepValue(_ sleepHours: Double) -> Double {
        // Map 0-12 hours to 0-600 calories range
        return sleepHours * 50
    }
    
    /// Most recent date from the health data for "last updated" display
    /// - Returns: The date of the most recent health metric, or nil if no data
    private var lastUpdatedDate: Date? {
        healthData.max(by: { $0.date < $1.date })?.date
    }

    // MARK: - Body
    
    var body: some View {
        // Main glass container wrapping all chart content
        GlassEffectContainer(spacing: 20.0) {
            VStack(alignment: .leading, spacing: 12) {
                // MARK: Chart Definition
                Chart(chartData) { point in
                    // --- Bar Chart for Active Calories ---
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Calories", point.activeCalories)
                    )
                    .foregroundStyle(
                        // Gradient from bottom (darker) to top (lighter)
                        .linearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                Color(red: 0.5, green: 0.8, blue: 1.0).opacity(0.6)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)  // Rounded top corners for bars

                    // --- Line Chart for Sleep Hours ---
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Sleep", scaledSleepValue(point.sleepHours))
                    )
                    .foregroundStyle(.indigo.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)  // Smooth curve

                    // --- Invisible Point Mark for Tap Target ---
                    // Creates a larger invisible tap target for the selected data point
                    if let selectedDataPoint, selectedDataPoint.id == point.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Calories", point.activeCalories)
                        )
                        .foregroundStyle(.clear)
                        .symbolSize(200)  // Large tap target
                    }
                }
                // Hide axes for cleaner appearance
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                
                // MARK: Tap Gesture Handling
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                withAnimation(animation) {
                                    updateSelection(at: location, proxy: proxy, geometry: geo)
                                }
                            }
                    }
                }
                
                // MARK: Annotation Overlay
                .chartOverlay { proxy in
                    // Overlay for selection bubble only
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(chartData) { point in
                                // Only show annotation for selected point
                                if let plotFrame = proxy.plotFrame,
                                   let xPosition = proxy.position(forX: point.date),
                                   let yPosition = proxy.position(forY: point.activeCalories),
                                   let selectedDataPoint, selectedDataPoint.id == point.id, showAnnotationView {
                                    
                                    // Calculate absolute position in view
                                    let xCoordinate = geometry[plotFrame].origin.x + xPosition
                                    let yCoordinate = geometry[plotFrame].origin.y + yPosition
                                    
                                    // Show annotation bubble above the data point
                                    AnnotationView(dataPoint: point, showDataPointView: showDataPointView)
                                        .position(x: xCoordinate, y: max(yCoordinate - 100, 70))
                                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                            }
                        }
                        // Animate changes smoothly
                        .animation(.smooth(duration: 0.3), value: selectedDataPoint)
                        .animation(.smooth(duration: 0.3), value: showAnnotationView)
                        .animation(.smooth(duration: 0.3), value: showDataPointView)
                    }
                }
                // Accessibility
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Health activity chart showing 14 days of data")
                .frame(height: height)
                .padding(.horizontal, padding)
                
                // MARK: Food Order Indicators
                // Icons below chart showing which days had food orders
                if showAnnotationView {
                    HStack(spacing: 0) {
                        ForEach(chartData) { point in
                            ZStack {
                                // Only show icon if there was spending on this day
                                if let spend = point.foodOrderSpend, spend > 0 {
                                    FoodAnnotationView(spend: spend)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .frame(maxWidth: .infinity)  // Evenly distribute icons
                        }
                    }
                    .frame(height: 20)
                    .padding(.horizontal, padding)
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 8)
        }
        // Apply glass effect to entire container
        .glassEffect(.regular.tint(colorScheme.opacity(0.1)), in: .rect(cornerRadius: cornerRadius))
    }
    
    // MARK: - Helper Methods
    
    /// Updates the selected data point based on tap location
    ///
    /// This method:
    /// 1. Converts tap location to chart coordinates
    /// 2. Finds the nearest data point by date
    /// 3. Toggles selection if same point tapped twice
    /// 4. Updates the selected point state
    ///
    /// - Parameters:
    ///   - location: The tap location in view coordinates
    ///   - proxy: Chart proxy for coordinate conversion
    ///   - geometry: Geometry proxy for frame calculations
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        
        // Convert tap x-position to chart x-coordinate
        let xPosition = location.x - geometry[plotFrame].origin.x
        
        // Get the date value at this x-position
        guard let date: Date = proxy.value(atX: xPosition) else {
            return
        }
        
        // Find the closest data point to the tapped date
        var minDistance: TimeInterval = .infinity
        var closestDataPoint: ChartDataPoint? = nil
        
        for point in chartData {
            let distance = abs(point.date.timeIntervalSince(date))
            if distance < minDistance {
                minDistance = distance
                closestDataPoint = point
            }
        }
        
        // Toggle selection: if same point is tapped again, deselect it
        if selectedDataPoint?.id == closestDataPoint?.id {
            selectedDataPoint = nil
        } else {
            selectedDataPoint = closestDataPoint
        }
    }
    
    /// Shared date formatter for consistent date display
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Supporting Data Structures

/// Internal data model representing a single day's combined health and food metrics
///
/// This structure unifies health data (calories, sleep, steps) with food order data
/// for display in the chart. Each point represents one day.
///
/// **Identifiable:** Uses date as unique identifier
/// **Codable:** Can be serialized to JSON for export
/// **Equatable:** Supports comparison for chart updates
private struct ChartDataPoint: Identifiable, Codable, Equatable {
    /// Unique identifier (the date)
    var id: Date { date }
    
    /// The date for this data point (start of day)
    let date: Date
    
    /// Active calories burned (kilocalories)
    let activeCalories: Double
    
    /// Sleep duration in hours (converted from minutes)
    let sleepHours: Double
    
    /// Total step count
    let steps: Double
    
    /// Optional food order spending for this day (nil if no orders)
    let foodOrderSpend: Double?
}

// MARK: - Food Annotation View

/// Small icon indicator showing food orders below the chart
///
/// Displays a food/drink icon when spending occurred on a given day.
/// Uses hierarchical symbol rendering for a subtle appearance.
private struct FoodAnnotationView: View {
    /// Optional spending amount for this day
    let spend: Double?

    var body: some View {
        // Only show icon if there was actual spending
        if let spend = spend, spend > 0 {
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange.opacity(0.8))
                .symbolRenderingMode(.hierarchical)  // iOS 15+ rendering mode
        }
    }
}

// MARK: - Annotation Bubble View

/// Detailed data annotation that appears above selected chart points
///
/// Shows comprehensive metrics when user taps a data point:
/// - Date (month and day)
/// - Active calories
/// - Steps
/// - Sleep hours
/// - Food spending (if applicable)
///
/// Uses compact grid layout to fit multiple metrics in small space.
private struct AnnotationView: View {
    /// The data point to display information for
    let dataPoint: ChartDataPoint
    
    /// Whether to show detailed metrics (can be toggled off)
    var showDataPointView = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // MARK: Date Header
            // Compact date display with calendar icon
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(dataPoint.date, format: .dateTime.month().day())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            // MARK: Metrics Grid
            // Show detailed metrics if enabled
            if showDataPointView {
                Divider()
                    .background(.white.opacity(0.3))
                
                // Compact 2-column grid layout with tighter spacing
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    // Calories metric
                    CompactDataPointView(
                        iconName: "flame.fill",
                        value: "\(Int(dataPoint.activeCalories))",
                        unit: "kcal"
                    )
                    
                    // Steps metric
                    CompactDataPointView(
                        iconName: "figure.walk",
                        value: "\(Int(dataPoint.steps))",
                        unit: "steps"
                    )
                    
                    // Sleep metric
                    CompactDataPointView(
                        iconName: "bed.double.fill",
                        value: String(format: "%.1f", dataPoint.sleepHours),
                        unit: "hr"
                    )
                    
                    // Food spending (only if exists)
                    if let spend = dataPoint.foodOrderSpend, spend > 0 {
                        CompactDataPointView(
                            iconName: "fork.knife",
                            value: String(format: "$%.0f", spend),
                            unit: ""
                        )
                    }
                }
            }
        }
        .padding(6)
        .frame(width: 130)
        .background(.ultraThinMaterial)  // iOS 15+ material
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            // Subtle border for definition
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Legacy Data Point View (Unused)

/// Legacy data point view with horizontal layout
///
/// Note: This view is currently unused in favor of CompactDataPointView
/// Kept for potential future use or reference.
private struct DataPointView: View {
    let label: String
    let value: String
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
}

// MARK: - Compact Data Point View

/// Compact vertical metric display for annotation bubbles
///
/// Displays a single metric in a space-efficient vertical layout:
/// - Icon (top)
/// - Value (middle, bold)
/// - Unit (bottom, small)
///
/// Optimized for 2-column grid display in small annotation bubbles.
private struct CompactDataPointView: View {
    /// SF Symbol name for the metric icon
    let iconName: String
    
    /// The metric value (formatted string)
    let value: String
    
    /// Unit of measurement (e.g., "kcal", "steps", "hr")
    let unit: String

    var body: some View {
        VStack(spacing: 1) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            
            // Value
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
            
            // Unit label (hide if empty)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showDataPoints = true
    @Previewable @State var showAnnotations = true
    
    // Create some mock data for preview
    let today = Date()
    
    // Generate 14 days of mock health data with realistic variation
    let healthData: [DailyHealthMetric] = (0..<14).map { i in
        let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
        return DailyHealthMetric(
            date: date,
            steps: 8000 + Int.random(in: -3000...3000),  // 5,000 - 11,000 steps
            activeCalories: 500 + Double.random(in: -200...200),  // 300 - 700 kcal
            sleepDurationMinutes: 450 + Double.random(in: -90...90)  // 6 - 9 hours
        )
    }
    
    // Mock food orders on a few days
    let foodData: [FoodOrder] = [
        FoodOrder(date: Calendar.current.date(byAdding: .day, value: -2, to: today)!, totalSpend: 25.50, orderCount: 1),
        FoodOrder(date: Calendar.current.date(byAdding: .day, value: -5, to: today)!, totalSpend: 42.10, orderCount: 2)
    ]
    
    return HealthStackChart(
        healthData: healthData,
        foodData: foodData,
        showAnnotationView: $showAnnotations,
        showDataPointView: $showDataPoints
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
