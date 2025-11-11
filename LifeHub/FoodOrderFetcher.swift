import Foundation
import SwiftData

enum FoodOrderFetcherError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case dataNotFound
}

class FoodOrderFetcher {
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    func fetchAndUpsertFoodOrders(from urlString: String, context: ModelContext) async throws {
        guard let url = URL(string: urlString) else {
            throw FoodOrderFetcherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FoodOrderFetcherError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }
        
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw FoodOrderFetcherError.parsingError("Could not decode data into UTF-8 string.")
        }

        var lines = csvString.split(separator: "\n").map { String($0) }

        if lines.isEmpty {
            throw FoodOrderFetcherError.dataNotFound
        }
        
        // Remove header row
        lines.removeFirst()

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            
            guard parts.count == 3 else {
                throw FoodOrderFetcherError.parsingError("Invalid number of columns in row \(index + 2).")
            }
            
            guard let date = dateFormatter.date(from: parts[0]) else {
                throw FoodOrderFetcherError.parsingError("Invalid date format in row \(index + 2).")
            }
            
            guard let totalSpend = Double(parts[1]) else {
                throw FoodOrderFetcherError.parsingError("Invalid totalSpend format in row \(index + 2).")
            }
            
            guard let orderCount = Int(parts[2]) else {
                throw FoodOrderFetcherError.parsingError("Invalid orderCount format in row \(index + 2).")
            }
            
            let startOfDay = Calendar.current.startOfDay(for: date)
            let fetchDescriptor = FetchDescriptor<FoodOrder>(
                predicate: #Predicate { $0.date == startOfDay }
            )

            if let existingOrder = try context.fetch(fetchDescriptor).first {
                existingOrder.totalSpend = totalSpend
                existingOrder.orderCount = orderCount
            } else {
                let newOrder = FoodOrder(date: startOfDay, totalSpend: totalSpend, orderCount: orderCount)
                context.insert(newOrder)
            }
        }
        
        try context.save()
    }
}
