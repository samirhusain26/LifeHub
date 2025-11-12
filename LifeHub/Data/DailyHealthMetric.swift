import Foundation
import SwiftData

@Model
class DailyHealthMetric: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case date, weight, steps, activeCalories, sleepDurationMinutes, sleepStartTime, sleepWakeTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        steps = try container.decodeIfPresent(Int.self, forKey: .steps)
        activeCalories = try container.decodeIfPresent(Double.self, forKey: .activeCalories)
        sleepDurationMinutes = try container.decodeIfPresent(Double.self, forKey: .sleepDurationMinutes)
        sleepStartTime = try container.decodeIfPresent(Date.self, forKey: .sleepStartTime)
        sleepWakeTime = try container.decodeIfPresent(Date.self, forKey: .sleepWakeTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(steps, forKey: .steps)
        try container.encodeIfPresent(activeCalories, forKey: .activeCalories)
        try container.encodeIfPresent(sleepDurationMinutes, forKey: .sleepDurationMinutes)
        try container.encodeIfPresent(sleepStartTime, forKey: .sleepStartTime)
        try container.encodeIfPresent(sleepWakeTime, forKey: .sleepWakeTime)
    }
}
