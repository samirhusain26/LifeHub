# Quick Reference Guide - LifeHub

A quick reference for common tasks, calculations, and configurations in the LifeHub app.

---

## 📊 Metric Calculations - Quick Reference

### 1. Active Days Ratio
**Location**: `DashboardViewModel.swift` → `calculateActiveDayRatio()`
```swift
// Count days with >8,000 steps in last 7 days
let activeDays = metrics.filter { ($0.steps ?? 0) > 8000 }.count
return "\(activeDays)/7 Days"
```
**To Customize**: Change `8000` to your desired threshold

---

### 2. Energy Week-over-Week
**Location**: `DashboardViewModel.swift` → `calculateEnergyWoW()`
```swift
// Compare last 7 days to previous 7 days
percentChange = ((recent - previous) / previous) * 100
return "\(Int(recent)) Kcal (▲\(Int(percentChange))%)"
```
**Formula**: `((Current - Previous) / Previous) × 100`

---

### 3. Sleep Consistency
**Location**: `DashboardViewModel.swift` → `calculateSleepConsistency()`
```swift
// Standard deviation of wake times and durations
stdDev = sqrt(Σ(x - mean)² / (n - 1))
return (wakeStdDev, durationStdDev)  // in minutes
```
**Interpretation**: Lower = more consistent sleep

---

### 4. Delivery Spend Trends
**Location**: `DashboardViewModel.swift` → `calculateDeliverySpendTrends()`
```swift
// 30-day vs previous 30-day
let last30d = orders.filter { $0.date >= 30DaysAgo }.sum()
let prev30d = orders.filter { $0.date >= 60DaysAgo && < 30DaysAgo }.sum()
return "$\(last30d) (\(percentChange)) • $\(yearly) (\(yoyChange))"
```

---

### 5. Clean Eating Streak
**Location**: `DashboardViewModel.swift` → `calculateCleanStreak()`
```swift
// Days since last food order
let days = Date() - lastOrderDate
return "\(days)"  // Returns "∞" if no orders
```

---

### 6. Weight Trend (45 days)
**Location**: `DashboardViewModel.swift` → `calculateWeightTrend()`
```swift
// Difference from highest weight in last 45 days
let maxWeight = metrics.filter { 45DaysRange }.max(\.weight)
let diff = currentWeight - maxWeight
return "\(diff) lbs from high"
```

---

### 7. Weight Goal
**Location**: `DashboardViewModel.swift` → `calculateWeightGap()`
```swift
// Distance to goal weight (200 lbs)
let gap = currentWeight - 200.0
return "\(gap) lbs to go"
```
**To Customize**: Change `200.0` to your target weight

---

## ⚙️ Configuration Quick Reference

### Google Sheets CSV URL
**Location**: `DataModelActor.swift` line ~25
```swift
let urlString = "YOUR_GOOGLE_SHEETS_CSV_URL"
```
**Required Columns**: `date`, `amount`, `messageid`

---

### Chart Display Settings
**Location**: `HealthStackChart.swift` properties
```swift
var colorScheme: Color = Color(red: 0.4, green: 0.7, blue: 1.0)
var cornerRadius: CGFloat = 20
var height: CGFloat = 200
var animation: Animation = .smooth(duration: 0.4)
```

---

### Date Ranges
| Metric | Days | Location |
|--------|------|----------|
| Chart Display | 14 | `DashboardViewModel.calculateMetrics()` |
| Active Days | 7 | `calculateActiveDayRatio()` |
| Energy WoW | 14 | `calculateEnergyWoW()` |
| Sleep Consistency | 7 | `calculateSleepConsistency()` |
| Food Trends (30d) | 60 | `calculateDeliverySpendTrends()` |
| Food Trends (yearly) | 730 | `calculateDeliverySpendTrends()` |
| Weight Trend | 45 | `calculateWeightTrend()` |
| HealthKit Fetch | 365 | `HealthKitService.fetchHealthData()` |

---

## 🎨 iOS 26 Liquid Glass - Quick Reference

### Glass Effect Container
```swift
GlassEffectContainer(spacing: 20.0) {
    // Your content
}
.glassEffect(.regular.tint(.blue.opacity(0.1)), in: .rect(cornerRadius: 20))
```

### Interactive Glass Button
```swift
Button(action: { }) {
    // Content
}
.buttonStyle(.glass)
.glassEffect(.regular.interactive())
```

### Glass with Morphing
```swift
@Namespace private var glassNamespace

view1.glassEffectID("uniqueID1", in: glassNamespace)
view2.glassEffectID("uniqueID2", in: glassNamespace)
```

### Color-Coded Tints
| Component | Tint | Opacity |
|-----------|------|---------|
| Chart | Orange | 0.1 |
| Food Indicators | Green | 0.3 |
| Sleep (Wake) | Blue | 0.1 |
| Sleep (Duration) | Purple | 0.1 |
| Food Orders (30d) | Orange | 0.1 |
| Food Orders (Yearly) | Red | 0.1 |
| Clean Streak | Green | 0.1 |

---

## 🔐 HealthKit Permissions

**Location**: `HealthKitService.swift` → `requestAuthorization()`

**Read Access Requested**:
- ✅ Body Mass (weight)
- ✅ Step Count
- ✅ Active Energy Burned
- ✅ Sleep Analysis

**Info.plist Key**:
```xml
<key>NSHealthShareUsageDescription</key>
<string>LifeHub needs access to your health data to display your activity, sleep, and weight metrics.</string>
```

---

## 🗂 File Structure Quick Reference

```
LifeHub/
├── Models/
│   ├── DailyHealthMetric.swift      # Health data model
│   └── FoodOrder.swift               # Food order model
│
├── Services/
│   ├── HealthKitService.swift        # HealthKit queries
│   ├── FoodOrderFetcher.swift        # CSV import
│   └── DataModelActor.swift          # Data persistence
│
├── ViewModels/
│   └── DashboardViewModel.swift      # Business logic
│
├── Views/
│   ├── DashboardView.swift           # Main screen
│   ├── HealthStackChart.swift        # Chart component
│   ├── MetricCardView.swift          # Metric cards
│   ├── SleepConsistencyView.swift    # Sleep card
│   └── FoodOrderMetricsView.swift    # Food card
│
├── Components/
│   ├── SharedComponents.swift        # Reusable UI
│   └── SharedButtonStyles.swift      # Button styles
│
└── LifeDashboardApp.swift            # App entry
```

---

## 🧪 Testing Quick Commands

### Run All Tests
```bash
cmd + U
```

### Run Specific Test
Right-click test method → "Run Test"

### View Test Coverage
```bash
cmd + shift + 9  # Show Test Navigator
```

---

## 🐛 Common Issues & Solutions

### Issue: HealthKit not working
**Solution**: 
1. Check device supports HealthKit (not iPad)
2. Verify capability added in Xcode
3. Confirm Info.plist has usage description
4. Check user granted permissions

### Issue: No data showing
**Solution**:
1. Trigger manual refresh (Actions → Refresh)
2. Check HealthKit has data for selected periods
3. Verify CSV URL is accessible
4. Check network connection

### Issue: Chart not updating
**Solution**:
1. Toggle annotation settings
2. Tap refresh in Actions menu
3. Pull-to-refresh on dashboard
4. Check @Observable is working

---

## 📱 UI Interaction Reference

### Chart Interactions
- **Tap bar**: Show detailed metrics for that day
- **Tap again**: Hide details
- **Long press**: (Future enhancement)

### Actions Menu
- **Refresh Data**: Fetch from HealthKit and CSV
- **Copy Data as JSON**: Export last 14 days
- **Show/Hide Annotations**: Toggle food indicators
- **Show/Hide Details**: Toggle metric details

### Metric Cards
- **Tap card**: View definition and details
- **Scroll**: View more cards

---

## 🔧 Customization Quick Guide

### Change Step Threshold (Active Days)
1. Open `DashboardViewModel.swift`
2. Find `calculateActiveDayRatio()`
3. Change `8000` to desired value
4. Rebuild app

### Change Weight Goal
1. Open `DashboardViewModel.swift`
2. Find `calculateWeightGap()`
3. Change `200.0` to desired weight
4. Rebuild app

### Change Chart Colors
1. Open `HealthStackChart.swift`
2. Modify `colorScheme` property
3. Update gradient colors in `BarMark`
4. Rebuild app

### Modify Date Ranges
Each calculation method has date ranges:
```swift
// Example: Change from 7 to 14 days
let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())
```

---

## 📊 Data Export Format

### JSON Structure
```json
{
  "foodOrders": [
    {
      "date": "2025-11-13T00:00:00Z",
      "totalSpend": 42.50,
      "orderCount": 2
    }
  ],
  "healthMetrics": [
    {
      "date": "2025-11-13T00:00:00Z",
      "weight": 210.5,
      "steps": 8543,
      "activeCalories": 654.3,
      "sleepDurationMinutes": 456.0,
      "sleepWakeTime": "2025-11-13T07:30:00Z"
    }
  ]
}
```

### Export Steps
1. Tap Actions menu
2. Select "Copy Data as JSON"
3. Paste into text editor
4. Save with `.json` extension

---

## 🎯 Performance Tips

### Optimize Data Fetching
- HealthKit fetches 365 days (runs once)
- Chart displays 14 days (filtered from stored data)
- Use pull-to-refresh sparingly
- CSV import happens on refresh only

### Memory Management
- SwiftData handles persistence automatically
- Old data isn't automatically deleted
- Consider periodic cleanup for very old data

### Animation Performance
- Liquid Glass uses GPU acceleration
- Smooth animations target 60fps
- Reduce animation duration if sluggish

---

## 📚 Additional Resources

### Documentation Files
- **README.md** - Complete project documentation
- **DOCUMENTATION_SUMMARY.md** - Documentation coverage report
- **CHANGES_SUMMARY.md** - What was added/changed
- **QUICK_REFERENCE.md** - This file

### Code Documentation
- In-code comments in all major files
- MARK: comments for navigation
- Method documentation with examples
- Formula explanations inline

### External Resources
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [HealthKit Guide](https://developer.apple.com/documentation/healthkit)
- [Swift Charts](https://developer.apple.com/documentation/charts)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

---

## 🚀 Development Workflow

### Making Changes
1. Create feature branch
2. Make changes with comments
3. Update tests
4. Update documentation
5. Submit PR

### Testing Changes
1. Run unit tests (`cmd + U`)
2. Test manually on device
3. Check accessibility (VoiceOver)
4. Verify animations smooth
5. Test edge cases

### Releasing
1. Update version number
2. Update CHANGELOG
3. Tag release
4. Build archive
5. Submit to TestFlight/App Store

---

## 🔍 Debugging Tips

### Print Statements
```swift
print("DEBUG: chartData count = \(chartData.count)")
print("DEBUG: selectedDataPoint = \(String(describing: selectedDataPoint))")
```

### Xcode Debugging
- **Breakpoint**: Click line number
- **po variable**: Print object in console
- **View Hierarchy**: Debug → View Debugging
- **Memory Graph**: Debug → Memory Graph

### Common Debugging Points
- `fetchHealthData()` - HealthKit queries
- `calculateMetrics()` - Metric calculations
- `updateSelection()` - Chart interactions
- `fetchAllData()` - Data refresh

---

**Quick Reference Version**: 1.0
**Last Updated**: November 13, 2025
**For LifeHub**: v1.0+

---

*Keep this file updated as the project evolves!*
