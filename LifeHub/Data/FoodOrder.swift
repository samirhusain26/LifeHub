import Foundation
import SwiftData

@Model
class FoodOrder: Codable {
    var date: Date
    var totalSpend: Double
    var orderCount: Int

    init(date: Date, totalSpend: Double, orderCount: Int) {
        self.date = date
        self.totalSpend = totalSpend
        self.orderCount = orderCount
    }
    
    enum CodingKeys: String, CodingKey {
        case date, totalSpend, orderCount
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        totalSpend = try container.decode(Double.self, forKey: .totalSpend)
        orderCount = try container.decode(Int.self, forKey: .orderCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(totalSpend, forKey: .totalSpend)
        try container.encode(orderCount, forKey: .orderCount)
    }
}
