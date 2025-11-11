import Foundation
import SwiftData

@Model
class DailyHealthMetric {
    var date: Date
    var weight: Double?
    var steps: Int?
    var activeCalories: Double?
    var sleepDurationMinutes: Double?
    var sleepStartTime: Date?
    var sleepWakeTime: Date?

    init(date: Date, weight: Double? = nil, steps: Int? = nil, activeCalories: Double? = nil, sleepDurationMinutes: Double? = nil, sleepStartTime: Date? = nil, sleepWakeTime: Date? = nil) {
        self.date = date
        self.weight = weight
        self.steps = steps
        self.activeCalories = activeCalories
        self.sleepDurationMinutes = sleepDurationMinutes
        self.sleepStartTime = sleepStartTime
        self.sleepWakeTime = sleepWakeTime
    }
}
