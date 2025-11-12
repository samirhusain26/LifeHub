# Change Log

## [Unreleased]

### Fixed
- Resolved a critical crash occurring when refreshing health data. The `HealthKitService` no longer crashes due to incorrect unit conversion for step counts.
- Improved robustness of HealthKit authorization by replacing force unwraps with safe optional binding.
- Refactored health data fetching logic from `DashboardView` to `DashboardViewModel` to adhere to MVVM architectural patterns.

### Removed
- Removed unused `HealthKitManager.swift` file.
