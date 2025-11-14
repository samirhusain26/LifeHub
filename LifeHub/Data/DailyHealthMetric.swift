import Foundation
import SwiftData

/// Represents a single day's health metrics from HealthKit
///
/// This SwiftData model stores daily aggregated health data including:
/// - Physical activity (steps, calories)
/// - Sleep patterns (duration, timing)
/// - Body measurements (weight)
///
/// **Storage:**
/// - One entry per day (unique by date)
/// - All fields optional except date
/// - Weight forward-fills when missing
///
/// **Usage:**
/// ```swift
/// let metric = DailyHealthMetric(
///     date: Date(),
///     steps: 10000,
///     activeCalories: 550,
///     sleepDurationMinutes: 480
/// )
/// ```
@Model
class DailyHealthMetric: Codable {
    // MARK: - Properties
    
    /// The date for this metric (normalized to start of day)
    var date: Date
    
    /// Body weight in pounds (forward-filled when nil)
    var weight: Double?
    
    /// Total step count for the day
    var steps: Int?
    
    /// Active energy burned in kilocalories
    var activeCalories: Double?
    
    /// Total sleep duration in minutes
    var sleepDurationMinutes: Double?
    
    /// Time when sleep began (for consistency tracking)
    var sleepStartTime: Date?
    
    /// Time when sleep ended (for consistency tracking)
    var sleepWakeTime: Date?

    // MARK: - Initialization
    
    /// Creates a new daily health metric
    ///
    /// - Parameters:
    ///   - date: The date for this metric (will be normalized to start of day)
    ///   - weight: Optional body weight in pounds
    ///   - steps: Optional step count
    ///   - activeCalories: Optional active calories burned
    ///   - sleepDurationMinutes: Optional sleep duration in minutes
    ///   - sleepStartTime: Optional sleep start time
    ///   - sleepWakeTime: Optional sleep wake time
    init(date: Date, weight: Double? = nil, steps: Int? = nil, activeCalories: Double? = nil, sleepDurationMinutes: Double? = nil, sleepStartTime: Date? = nil, sleepWakeTime: Date? = nil) {
        self.date = date
        self.weight = weight
        self.steps = steps
        self.activeCalories = activeCalories
        self.sleepDurationMinutes = sleepDurationMinutes
        self.sleepStartTime = sleepStartTime
        self.sleepWakeTime = sleepWakeTime
    }
    
    // MARK: - Codable Implementation
    
    /// Coding keys for JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case date, weight, steps, activeCalories, sleepDurationMinutes, sleepStartTime, sleepWakeTime
    }

    /// Decodes a DailyHealthMetric from JSON
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

    /// Encodes a DailyHealthMetric to JSON
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
