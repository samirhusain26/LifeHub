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

    struct OrderData {
        var totalSpend: Double = 0.0
        var messageIds: Set<String> = []
    }

    func fetchFoodOrders(from urlString: String) async throws -> [Date: OrderData] {
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
        
        // Process header
        let header = lines.removeFirst().split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)).lowercased() }
        
        guard let dateIndex = header.firstIndex(of: "date"),
              let amountIndex = header.firstIndex(of: "amount"),
              let messageIdIndex = header.firstIndex(of: "messageid") else {
            throw FoodOrderFetcherError.parsingError("CSV header is missing required columns: date, amount, messageid.")
        }

        var aggregatedData: [Date: OrderData] = [:]

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            
            if parts.count != header.count {
                // Log a warning for mismatched column count, but continue processing other lines
                print("Warning: Row \(index + 2) has \(parts.count) columns, expected \(header.count).")
                continue
            }
            
            guard let date = dateFormatter.date(from: parts[dateIndex]) else {
                print("Warning: Invalid date format in row \(index + 2).")
                continue
            }
            
            guard let amount = Double(parts[amountIndex]) else {
                print("Warning: Invalid amount format in row \(index + 2).")
                continue
            }
            
            let messageId = parts[messageIdIndex]
            let startOfDay = Calendar.current.startOfDay(for: date)
            
            var orderData = aggregatedData[startOfDay, default: OrderData()]
            orderData.totalSpend += amount
            orderData.messageIds.insert(messageId)
            aggregatedData[startOfDay] = orderData
        }
        
        return aggregatedData
    }
}
