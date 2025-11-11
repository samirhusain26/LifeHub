import Foundation
import SwiftData

@Model
class FoodOrder {
    var date: Date
    var totalSpend: Double
    var orderCount: Int

    init(date: Date, totalSpend: Double, orderCount: Int) {
        self.date = date
        self.totalSpend = totalSpend
        self.orderCount = orderCount
    }
}
