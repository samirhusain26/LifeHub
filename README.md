# LifeHub - Personal Health & Food Tracking Dashboard

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

**A comprehensive iOS health tracking app that combines HealthKit data with food order tracking to provide actionable insights into your wellness journey.**

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Data Models](#-data-models)
- [Calculation Logic](#-calculation-logic)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [iOS 26 Modernization](#-ios-26-modernization)
- [Privacy & Permissions](#-privacy--permissions)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**LifeHub** is a modern iOS application built with SwiftUI that provides a unified dashboard for tracking health metrics and food ordering habits. The app seamlessly integrates with Apple's HealthKit to fetch health data and combines it with external food delivery data to give users a complete picture of their lifestyle choices.

### Key Highlights

- 🏃 **Health Tracking**: Steps, active calories, sleep patterns, and weight
- 🍔 **Food Analytics**: Track delivery spending and eating habits
- 📊 **Interactive Charts**: Beautiful 14-day visualization with drill-down details
- 🎨 **Modern Design**: iOS 26 Liquid Glass design language
- 🔒 **Privacy First**: All data stored locally with SwiftData
- ♿ **Accessible**: Full VoiceOver support and Dynamic Type

---

## ✨ Features

### Health Data Integration

- **HealthKit Sync**: Automatic sync with Apple Health for:
  - Daily step count
  - Active energy burned (calories)
  - Sleep duration and wake times
  - Body weight tracking
- **365-Day History**: Fetch and store up to one year of health data
- **Smart Defaults**: Forward-fill weight data to maintain continuity

### Food Order Tracking

- **CSV Import**: Import food delivery data from Google Sheets
- **Automatic Aggregation**: Group orders by date and calculate totals
- **Spending Analysis**: Track 30-day and yearly spending trends
- **Clean Eating Streak**: Monitor days without food delivery orders

### Calculated Metrics

#### 1. **Active Days Ratio (Last 14 Days)**
- Counts days with >8,000 steps
- Displays as ratio (e.g., "5/7 Days")
- Helps track activity consistency

#### 2. **Energy Week-over-Week (WoW)**
- Compares average active calories between last 7 days and previous 7 days
- Shows percentage change with up/down indicators
- Format: "500 Kcal (▲10%)"

#### 3. **Sleep Consistency**
- **Wake Time Consistency**: Standard deviation of wake times (in minutes)
- **Duration Consistency**: Standard deviation of sleep duration
- Lower values indicate better consistency
- Format: "±25m" for wake time, "±45m" for duration

#### 4. **Delivery Spend Trends**
- **30-Day Comparison**: Current 30 days vs previous 30 days
- **Yearly Comparison**: Last 365 days vs previous 365 days
- Shows spending amount and percentage change
- Format: "$150 (▲10%) • $2500 (▼5%)"

#### 5. **Clean Eating Streak**
- Days since last food delivery order
- Shows "∞" if no orders exist
- Motivational metric for healthy eating

#### 6. **Weight Trend (Last 45 Days)**
- Shows weight change from highest recorded weight in 45 days
- Format: "-5.2 lbs from high"
- Helps track weight loss progress

#### 7. **Weight Goal**
- Distance to target weight (200 lbs)
- Format: "10.5 lbs to go"
- Simple goal tracking

### Interactive Chart

- **14-Day View**: Bar chart for active calories with sleep overlay
- **Tap to Explore**: Tap any day to see detailed metrics
- **Food Indicators**: Icons show days with food orders
- **Smooth Animations**: Fluid transitions and interactions
- **Accessibility**: Full VoiceOver support

### Data Export

- **JSON Export**: Copy last 14 days of data as formatted JSON
- **Easy Sharing**: Share with health professionals or backup
- **ISO8601 Dates**: Standard date format for compatibility

---

## 📱 Screenshots

> *Add your app screenshots here showing:*
> - Main dashboard with chart
> - Metric cards
> - Detail popovers
> - Chart interactions

---

## 🏗 Architecture

### App Structure

```
LifeHub/
├── Models/
│   ├── DailyHealthMetric.swift       # Health data model (SwiftData)
│   └── FoodOrder.swift                # Food order model (SwiftData)
│
├── Services/
│   ├── HealthKitService.swift         # HealthKit data fetching
│   ├── FoodOrderFetcher.swift         # CSV parsing & food data
│   └── DataModelActor.swift           # SwiftData actor for concurrency
│
├── ViewModels/
│   └── DashboardViewModel.swift       # Main view model with calculations
│
├── Views/
│   ├── DashboardView.swift            # Main dashboard container
│   ├── HealthStackChart.swift         # Interactive chart component
│   ├── MetricCardView.swift           # Reusable metric card
│   ├── SleepConsistencyView.swift     # Sleep metrics card
│   └── FoodOrderMetricsView.swift     # Food order metrics card
│
├── Components/
│   ├── SharedComponents.swift         # Reusable UI components
│   └── SharedButtonStyles.swift       # Button styles
│
└── LifeDashboardApp.swift             # App entry point
```

### Design Patterns

- **MVVM Architecture**: Clear separation between views and business logic
- **Actor Pattern**: Thread-safe data access with `@ModelActor`
- **Observable Pattern**: SwiftUI's `@Observable` for reactive UI
- **Dependency Injection**: ModelContainer injected through views
- **Async/Await**: Modern Swift concurrency throughout

### Technology Stack

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Declarative UI framework |
| **SwiftData** | Local persistence and data modeling |
| **HealthKit** | Health data integration |
| **Swift Charts** | Data visualization |
| **Swift Concurrency** | Async/await, actors for concurrency |
| **Combine** | Reactive programming (minimal use) |

---

## 📊 Data Models

### DailyHealthMetric

Stores daily health data fetched from HealthKit.

```swift
@Model
class DailyHealthMetric {
    var date: Date                      // Start of day
    var weight: Double?                 // Body weight in pounds
    var steps: Int?                     // Step count
    var activeCalories: Double?         // Active energy burned (kcal)
    var sleepDurationMinutes: Double?   // Total sleep time
    var sleepStartTime: Date?           // When sleep began
    var sleepWakeTime: Date?            // When sleep ended
}
```

**Key Features:**
- One entry per day (unique by date)
- All fields optional except date
- Weight forward-fills when missing
- Codable for JSON export
- SwiftData `@Model` macro for persistence

### FoodOrder

Tracks food delivery orders aggregated by day.

```swift
@Model
class FoodOrder {
    var date: Date           // Order date (start of day)
    var totalSpend: Double   // Total amount spent
    var orderCount: Int      // Number of orders
}
```

**Key Features:**
- Aggregates multiple orders per day
- Tracks unique message IDs to prevent duplicates
- CSV import from Google Sheets
- Codable for JSON export

---

## 🧮 Calculation Logic

### 1. Active Days Ratio

**Formula:**
```
Active Days = Count(days where steps > 8,000)
Ratio = Active Days / 7
```

**Implementation:**
```swift
private func calculateActiveDayRatio() -> String {
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date().startOfDay)!
    let recentMetrics = healthData.filter { $0.date >= sevenDaysAgo }
    let activeDays = recentMetrics.filter { ($0.steps ?? 0) > 8000 }.count
    return "\(activeDays)/7 Days"
}
```

### 2. Energy Week-over-Week

**Formula:**
```
Recent Week Energy = Sum(activeCalories for last 7 days)
Previous Week Energy = Sum(activeCalories for days 8-14)
Percentage Change = ((Recent - Previous) / Previous) * 100
```

**Implementation:**
```swift
private func calculateEnergyWoW() -> String {
    let today = Date().startOfDay
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
    let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!

    let recentWeekEnergy = healthData
        .filter { $0.date >= sevenDaysAgo && $0.date < today }
        .reduce(0) { $0 + ($1.activeCalories ?? 0) }

    let previousWeekEnergy = healthData
        .filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo }
        .reduce(0) { $0 + ($1.activeCalories ?? 0) }
    
    let percentageChange = calculatePercentageChange(current: recentWeekEnergy, previous: previousWeekEnergy)
    return "\(Int(recentWeekEnergy)) Kcal (\(percentageChange))"
}
```

### 3. Sleep Consistency

**Formula:**
```
Standard Deviation = sqrt(Σ(x - mean)² / (n - 1))
```

**Implementation:**
```swift
private func calculateSleepConsistency() -> (wake: Double, duration: Double) {
    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date().startOfDay)!
    let validSleepData = healthData.filter { 
        $0.date >= sevenDaysAgo && ($0.sleepDurationMinutes ?? 0) > 0 
    }

    // Convert wake times to minutes since midnight
    let wakeTimesInMinutes = validSleepData.compactMap { metric -> Double? in
        guard let wakeTime = metric.sleepWakeTime else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    let sleepDurations = validSleepData.compactMap { $0.sleepDurationMinutes }

    let wakeStdDev = wakeTimesInMinutes.standardDeviation()
    let durationStdDev = sleepDurations.standardDeviation()

    return (wakeStdDev, durationStdDev)
}
```

### 4. Delivery Spend Trends

**Formula:**
```
30-Day Spend = Sum(totalSpend for last 30 days)
Previous 30-Day Spend = Sum(totalSpend for days 31-60)
30-Day Change = ((Current - Previous) / Previous) * 100

Yearly Spend = Sum(totalSpend for last 365 days)
Previous Year Spend = Sum(totalSpend for days 366-730)
Yearly Change = ((Current - Previous) / Previous) * 100
```

**Implementation:**
```swift
private func calculateDeliverySpendTrends() -> String {
    let today = Date().startOfDay
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
    let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: today)!
    let yearAgo = Calendar.current.date(byAdding: .day, value: -365, to: today)!
    let twoYearsAgo = Calendar.current.date(byAdding: .day, value: -730, to: today)!

    let last30dSpend = foodData
        .filter { $0.date >= thirtyDaysAgo && $0.date < today }
        .reduce(0) { $0 + $1.totalSpend }
    
    let prev30dSpend = foodData
        .filter { $0.date >= sixtyDaysAgo && $0.date < thirtyDaysAgo }
        .reduce(0) { $0 + $1.totalSpend }

    let last365dSpend = foodData
        .filter { $0.date >= yearAgo && $0.date < today }
        .reduce(0) { $0 + $1.totalSpend }
    
    let prev365dSpend = foodData
        .filter { $0.date >= twoYearsAgo && $0.date < yearAgo }
        .reduce(0) { $0 + $1.totalSpend }

    let momChange = calculatePercentageChange(current: last30dSpend, previous: prev30dSpend)
    let yoyChange = calculatePercentageChange(current: last365dSpend, previous: prev365dSpend)

    return "$\(Int(last30dSpend)) (\(momChange)) • $\(Int(last365dSpend)) (\(yoyChange))"
}
```

### 5. Clean Eating Streak

**Formula:**
```
Days Since Last Order = Current Date - Last Order Date
```

**Implementation:**
```swift
private func calculateCleanStreak() -> String {
    guard let lastOrderDate = foodData.max(by: { $0.date < $1.date })?.date else {
        return "∞"  // No orders = infinite streak
    }
    let days = Calendar.current.dateComponents([.day], 
        from: lastOrderDate.startOfDay, 
        to: Date().startOfDay).day ?? 0
    return "\(days)"
}
```

### 6. Weight Trend

**Formula:**
```
Max Weight (45 days) = Max(weight for last 45 days)
Current Weight = Most recent weight entry
Weight Change = Current Weight - Max Weight
```

**Implementation:**
```swift
private func calculateWeightTrend() -> String {
    let fortyFiveDaysAgo = Calendar.current.date(byAdding: .day, value: -45, to: Date().startOfDay)!
    let recentMetrics = healthData.filter { 
        $0.date >= fortyFiveDaysAgo && $0.weight != nil 
    }
    
    guard let maxWeight = recentMetrics.compactMap({ $0.weight }).max() else { 
        return "No Weight Data" 
    }
    
    if let currentWeight = healthData.first(where: { $0.weight != nil })?.weight {
        let diff = currentWeight - maxWeight
        return String(format: "%.1f lbs from high", diff)
    }
    
    return "N/A"
}
```

### 7. Weight Goal

**Formula:**
```
Goal Weight = 200 lbs (hardcoded)
Current Weight = Most recent weight entry
Gap = Current Weight - Goal Weight
```

**Implementation:**
```swift
private func calculateWeightGap() -> String {
    if let currentWeight = healthData.first(where: { $0.weight != nil })?.weight {
        let gap = currentWeight - 200.0
        return String(format: "%.1f lbs to go", gap)
    }
    return "N/A"
}
```

### Helper Functions

#### Standard Deviation Calculation

```swift
extension Collection where Element: BinaryFloatingPoint {
    func standardDeviation() -> Element {
        let n = Element(self.count)
        guard n > 1 else { return 0 }
        
        let mean = self.reduce(0, +) / n
        let sumOfSquaredDeviations = self.reduce(0) { 
            $0 + ($1 - mean) * ($1 - mean) 
        }
        
        return sqrt(sumOfSquaredDeviations / (n - 1))
    }
}
```

#### Percentage Change Calculation

```swift
private func calculatePercentageChange(current: Double, previous: Double) -> String {
    guard previous > 0 else { return "N/A" }
    
    let change = ((current - previous) / previous) * 100
    let symbol = change >= 0 ? "▲" : "▼"
    
    return "\(symbol)\(String(format: "%.0f", abs(change)))%"
}
```

---

## 🚀 Installation

### Prerequisites

- macOS 14.0 or later
- Xcode 16.0 or later
- iOS 18.0+ device or simulator
- Apple Developer Account (for HealthKit entitlements)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/lifehub.git
   cd lifehub
   ```

2. **Open in Xcode**
   ```bash
   open LifeHub.xcodeproj
   ```

3. **Configure Signing**
   - Select your project in the navigator
   - Go to "Signing & Capabilities"
   - Select your team
   - Ensure "Automatically manage signing" is checked

4. **Add HealthKit Capability**
   - In "Signing & Capabilities", click "+ Capability"
   - Add "HealthKit"
   - Configure the types you need to read

5. **Update Info.plist**
   Add the HealthKit usage description:
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>LifeHub needs access to your health data to display your activity, sleep, and weight metrics.</string>
   ```

6. **Configure Food Order CSV URL**
   In `DataModelActor.swift`, update the CSV URL:
   ```swift
   let urlString = "YOUR_GOOGLE_SHEETS_CSV_URL"
   ```

7. **Build and Run**
   - Select your target device
   - Press Cmd+R to build and run

---

## ⚙️ Configuration

### Google Sheets Setup

To import food order data, set up a Google Sheet with the following columns:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `date` | Date | Order date (YYYY-MM-DD) | 2024-01-15 |
| `amount` | Number | Order total | 25.50 |
| `messageid` | String | Unique order identifier | MSG123456 |

**Steps:**
1. Create a Google Sheet with the above columns
2. Publish to web: File → Share → Publish to web
3. Select "Comma-separated values (.csv)" format
4. Copy the published URL
5. Update `fetchAllData()` in `DataModelActor.swift`

### Weight Goal Customization

To change the target weight (default: 200 lbs):

In `DashboardViewModel.swift`:
```swift
private func calculateWeightGap() -> String {
    if let currentWeight = healthData.first(where: { $0.weight != nil })?.weight {
        let goalWeight = 200.0  // Change this value
        let gap = currentWeight - goalWeight
        return String(format: "%.1f lbs to go", gap)
    }
    return "N/A"
}
```

### Active Day Threshold

To change the step threshold for "active days" (default: 8,000 steps):

In `DashboardViewModel.swift`:
```swift
private func calculateActiveDayRatio() -> String {
    let threshold = 8000  // Change this value
    let activeDays = recentMetrics.filter { ($0.steps ?? 0) > threshold }.count
    return "\(activeDays)/7 Days"
}
```

---

## 📖 Usage

### First Launch

1. **Grant HealthKit Permissions**
   - On first launch, you'll be prompted to authorize HealthKit access
   - Select the health data types you want to share
   - Tap "Allow" to grant permissions

2. **Initial Data Sync**
   - The app will automatically fetch 365 days of health data
   - This may take a few moments depending on data volume
   - Progress is shown with a loading indicator

3. **View Dashboard**
   - Once loaded, you'll see the main dashboard with:
     - 14-day interactive chart
     - 6 metric cards
     - Pull-to-refresh capability

### Refreshing Data

**Manual Refresh:**
- Tap the "Actions" dropdown
- Select "Refresh Data"
- Wait for the refresh to complete

**Pull-to-Refresh:**
- Pull down on the dashboard
- Release to trigger refresh

### Exploring Chart Details

1. **Tap any day** on the chart to see detailed metrics:
   - Date
   - Active calories
   - Steps
   - Sleep hours
   - Food order spending (if applicable)

2. **Tap again** on the same day to dismiss details

3. **Toggle annotations:**
   - Actions → Hide/Show Annotations
   - Actions → Hide/Show Data Details

### Viewing Metric Definitions

Tap any metric card to see:
- **Definition**: Explanation of how the metric is calculated
- **Raw Data**: Additional context (if available)

### Exporting Data

1. Tap "Actions" dropdown
2. Select "Copy Data as JSON"
3. Data is copied to clipboard
4. Paste into any text editor or share with others

**JSON Format:**
```json
{
  "foodOrders": [...],
  "healthMetrics": [...]
}
```

---

## 🎨 iOS 26 Modernization

LifeHub has been fully modernized with iOS 26's **Liquid Glass** design language, creating a fluid, immersive user experience.

### Liquid Glass Features

#### What is Liquid Glass?

Liquid Glass is a dynamic material that:
- **Blurs content** behind it for depth
- **Reflects color and light** from surrounding elements
- **Reacts to touch** with interactive animations
- **Morphs between shapes** during transitions

#### Implementation Highlights

##### 1. Glass Effect Containers

All UI components use `GlassEffectContainer` for optimal rendering:

```swift
GlassEffectContainer(spacing: 20.0) {
    // Content with multiple glass effects
    HStack {
        view1.glassEffect()
        view2.glassEffect()
    }
}
.glassEffect(.regular, in: .rect(cornerRadius: 20))
```

##### 2. Interactive Glass Buttons

Buttons use glass styling with touch feedback:

```swift
Button(action: { }) {
    // Content
}
.buttonStyle(.glass)
.glassEffect(.regular.interactive())
```

##### 3. Color-Coded Tints

Each component has a semantic color tint:

| Component | Tint | Purpose |
|-----------|------|---------|
| Chart | Orange 0.1 | Data visualization |
| Food Icons | Green 0.3 | Positive actions |
| Sleep (Wake) | Blue 0.1 | Morning metrics |
| Sleep (Duration) | Purple 0.1 | Night metrics |
| Food Orders (30d) | Orange 0.1 | Short-term |
| Food Orders (Yearly) | Red 0.1 | Long-term |
| Clean Streak | Green 0.1 | Achievement |

##### 4. Glass Effect Morphing

Related elements can blend together using namespaces:

```swift
@Namespace private var glassNamespace

view1.glassEffectID("wake", in: glassNamespace)
view2.glassEffectID("duration", in: glassNamespace)
```

##### 5. Smooth Animations

All interactions use fluid animations:

```swift
.animation(.smooth(duration: 0.4), value: selectedDataPoint)
```

### Animation System

Centralized animation constants in `SharedComponents.swift`:

```swift
enum AnimationConstants {
    static var quick: Animation { .smooth(duration: 0.2) }
    static var standard: Animation { .smooth(duration: 0.3) }
    static var slow: Animation { .smooth(duration: 0.4) }
    static var spring: Animation { .spring(response: 0.3, dampingFraction: 0.7) }
    static var bouncy: Animation { .spring(response: 0.4, dampingFraction: 0.6) }
}
```

### Haptic Feedback

Consistent haptic feedback across the app:

```swift
struct HapticFeedback {
    static func light()      // Subtle taps
    static func medium()     // Standard interactions
    static func heavy()      // Significant actions
    static func success()    // Successful operations
    static func warning()    // Warning states
    static func error()      // Error conditions
    static func selection()  // Selection changes
}
```

---

## 🔒 Privacy & Permissions

### HealthKit Permissions

The app requests read-only access to:

- ✅ **Body Mass** (Weight tracking)
- ✅ **Step Count** (Activity tracking)
- ✅ **Active Energy Burned** (Calorie tracking)
- ✅ **Sleep Analysis** (Sleep metrics)

**Privacy Guarantees:**
- ✅ No data sent to external servers
- ✅ All data stored locally with SwiftData
- ✅ No write access to HealthKit
- ✅ User controls all permissions

### Data Storage

- **Local Only**: All data stored in SwiftData on-device
- **Secure**: Encrypted with iOS system protections
- **User-Controlled**: Can be deleted at any time
- **No Cloud Sync**: No iCloud or external backup

### Food Order Data

- **CSV Import**: Only imports from URL you configure
- **No Credentials**: No login or authentication stored
- **Public Data**: Assumes publicly shared Google Sheet
- **No Tracking**: No analytics or usage tracking

---

## 🧪 Testing

### Unit Tests

Run unit tests with:
```bash
cmd + U
```

**Test Coverage:**
- ✅ Data model encoding/decoding
- ✅ Calculation logic
- ✅ CSV parsing
- ✅ Date utilities
- ✅ Standard deviation calculations

### UI Tests

Run UI tests with:
```bash
cmd + U (with UI Test target selected)
```

**Test Scenarios:**
- ✅ Dashboard loads correctly
- ✅ Chart interactions work
- ✅ Metric cards are tappable
- ✅ Refresh functionality
- ✅ JSON export

### Manual Testing Checklist

- [ ] HealthKit authorization prompts correctly
- [ ] Data refreshes without errors
- [ ] Chart displays 14 days of data
- [ ] Tap interactions show/hide details
- [ ] All metric cards display values
- [ ] Metric card popovers show definitions
- [ ] JSON export copies to clipboard
- [ ] Pull-to-refresh works
- [ ] Actions menu functions correctly
- [ ] Smooth animations throughout
- [ ] VoiceOver navigation works
- [ ] Dynamic Type scales properly
- [ ] Light and Dark mode both look good

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Standards

- ✅ Follow Swift API Design Guidelines
- ✅ Use SwiftUI best practices
- ✅ Add comments for complex logic
- ✅ Include unit tests for new features
- ✅ Maintain accessibility features
- ✅ Test on multiple device sizes

### Commit Messages

Use conventional commit format:
```
feat: add new metric for water intake
fix: correct weight trend calculation
docs: update installation instructions
style: apply liquid glass to new component
refactor: simplify CSV parsing logic
test: add tests for sleep consistency
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Apple** - For SwiftUI, HealthKit, and Swift Charts frameworks
- **SwiftData** - For modern data persistence
- **iOS 26** - For Liquid Glass design inspiration
- **Community** - For feedback and contributions

---

## 📞 Support

For questions, issues, or feature requests:

- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/lifehub/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/lifehub/discussions)
- 📧 **Email**: your.email@example.com
- 🐦 **Twitter**: [@yourusername](https://twitter.com/yourusername)

---

## 🗺 Roadmap

### Version 2.0 (Planned)

- [ ] Apple Watch companion app
- [ ] Home Screen widgets
- [ ] 3D chart visualizations
- [ ] Machine learning health insights
- [ ] Export to PDF reports
- [ ] Social sharing features
- [ ] Custom goal setting
- [ ] Medication tracking
- [ ] Water intake monitoring
- [ ] Mood tracking

### Version 1.1 (In Progress)

- [ ] iPad optimization
- [ ] Landscape mode support
- [ ] Chart customization options
- [ ] More metric types
- [ ] Notification reminders

---

## 📊 Project Stats

- **Languages**: Swift 100%
- **Lines of Code**: ~2,500
- **Files**: 15
- **Dependencies**: 0 (uses only Apple frameworks)
- **Minimum iOS**: 18.0
- **Supported Devices**: iPhone, iPad
- **Supported Orientations**: Portrait, Landscape

---

<div align="center">

**Built with ❤️ using SwiftUI**

⭐ Star this repo if you find it helpful!

</div>
