import SwiftUI
import Charts

// Private helper view for the annotation to simplify the chart body
private struct FoodAnnotationView: View {
    let spend: Double?

    var body: some View {
        if let spend = spend, spend > 0 {
            VStack(spacing: 2) {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text("$\(Int(spend))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(4)
            .background(Color.white.opacity(0.5))
            .clipShape(Capsule())
        }
    }
}

struct HealthStackChart: View {
    let healthData: [DailyHealthMetric]
    let foodData: [FoodOrder]
    var onRefresh: (() -> Void)? = nil
    var onCopyJson: (() async -> String)? = nil

    private struct ChartDataPoint: Identifiable, Codable {
        var id: Date { date }
        let date: Date
        let activeCalories: Double
        let sleepHours: Double
        let foodOrderSpend: Double?
    }

    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let dataMap = Dictionary(grouping: healthData, by: { calendar.startOfDay(for: $0.date) })
        let foodMap = Dictionary(grouping: foodData, by: { calendar.startOfDay(for: $0.date) })

        return dataMap.map { date, metrics -> ChartDataPoint in
            let dayMetrics = metrics.first // Should only be one per day
            let sleepInHours = (dayMetrics?.sleepDurationMinutes ?? 0) / 60.0
            let spend = foodMap[date]?.first?.totalSpend
            
            return ChartDataPoint(
                date: date,
                activeCalories: dayMetrics?.activeCalories ?? 0,
                sleepHours: sleepInHours,
                foodOrderSpend: spend
            )
        }.sorted(by: { $0.date < $1.date })
    }
    
    private var secondaryYAxisDomain: ClosedRange<Double> {
        let maxSleep = chartData.map { $0.sleepHours }.max() ?? 8 // Default to 8 hours
        return 0...(maxSleep * 1.2)
    }
    
    private var lastUpdatedDate: Date? {
        chartData.max(by: { $0.date < $1.date })?.date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Health Stack")
                    .font(.headline)
                Spacer()
                if let onRefresh = onRefresh {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                if let onCopyJson = onCopyJson {
                    Button(action: {
                        Task {
                            let jsonString = await onCopyJson()
                            UIPasteboard.general.string = jsonString
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding([.leading, .trailing, .top])
            
            ZStack {
                Chart {
                    ForEach(chartData) { point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Calories", point.activeCalories)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .annotation(position: .top, alignment: .center) {
                            FoodAnnotationView(spend: point.foodOrderSpend)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue) kcal")
                            }
                        }
                    }
                }

                Chart {
                    ForEach(chartData) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Sleep", point.sleepHours)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: secondaryYAxisDomain)
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(dash: [2, 4]))
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(String(format: "%.1f", doubleValue)) hr")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine() // Keep grid lines for alignment
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 250)
            .padding(.horizontal)

            if let lastUpdatedDate = lastUpdatedDate {
                Text("Last updated: \(lastUpdatedDate, formatter: Self.dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    // Create some mock data for preview
    let today = Date()
    let healthData: [DailyHealthMetric] = (0..<14).map { i in
        let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
        return DailyHealthMetric(
            date: date,
            steps: 8000 + Int.random(in: -3000...3000),
            activeCalories: 500 + Double.random(in: -200...200),
            sleepDurationMinutes: 450 + Double.random(in: -90...90)
        )
    }
    let foodData: [FoodOrder] = [
        FoodOrder(date: Calendar.current.date(byAdding: .day, value: -2, to: today)!, totalSpend: 25.50, orderCount: 1),
        FoodOrder(date: Calendar.current.date(byAdding: .day, value: -5, to: today)!, totalSpend: 42.10, orderCount: 2)
    ]
    
    return HealthStackChart(healthData: healthData, foodData: foodData)
        .padding()
        .background(Color.gray.opacity(0.2))
}