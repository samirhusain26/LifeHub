import Foundation
import SwiftData

/// Represents food delivery orders aggregated by day
///
/// This SwiftData model tracks food ordering habits including:
/// - Total spending per day
/// - Number of individual orders
/// - Unique message identifiers to prevent duplicates
///
/// **Data Source:**
/// - Imported from CSV (Google Sheets)
/// - Multiple orders per day are aggregated
/// - Tracks unique message IDs during import
///
/// **Usage:**
/// ```swift
/// let order = FoodOrder(
///     date: Date(),
///     totalSpend: 42.50,
///     orderCount: 2
/// )
/// ```
@Model
class FoodOrder: Codable {
    // MARK: - Properties
    
    /// The date for this order (normalized to start of day)
    var date: Date
    
    /// Total amount spent on food orders this day (in dollars)
    var totalSpend: Double
    
    /// Number of individual orders placed this day
    var orderCount: Int

    // MARK: - Initialization
    
    /// Creates a new food order record
    ///
    /// - Parameters:
    ///   - date: The date of the orders (will be normalized to start of day)
    ///   - totalSpend: Total amount spent in dollars
    ///   - orderCount: Number of individual orders
    init(date: Date, totalSpend: Double, orderCount: Int) {
        self.date = date
        self.totalSpend = totalSpend
        self.orderCount = orderCount
    }
    
    // MARK: - Codable Implementation
    
    /// Coding keys for JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case date, totalSpend, orderCount
    }

    /// Decodes a FoodOrder from JSON
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        totalSpend = try container.decode(Double.self, forKey: .totalSpend)
        orderCount = try container.decode(Int.self, forKey: .orderCount)
    }

    /// Encodes a FoodOrder to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(totalSpend, forKey: .totalSpend)
        try container.encode(orderCount, forKey: .orderCount)
    }
}
