import Foundation

struct FoodOrder: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let appName: String
}

@MainActor
final class FoodOrderFetcher: ObservableObject {
    @Published var orders: [FoodOrder] = []
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    func fetch(from url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let csvString = String(data: data, encoding: .utf8) {
            orders = parse(csv: csvString)
        }
    }

    func daysSinceLastOrder(from date: Date = Date()) -> Int {
        guard let last = orders.sorted(by: { $0.date > $1.date }).first else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: last.date, to: date).day ?? 0
    }

    func longestStreak() -> Int {
        let sorted = orders.sorted(by: { $0.date < $1.date })
        var maxStreak = 0
        var lastDate: Date?
        var currentStreak = 0
        for order in sorted {
            if let last = lastDate {
                let days = Calendar.current.dateComponents([.day], from: last, to: order.date).day ?? 0
                if days > currentStreak { currentStreak = days }
                if days > maxStreak { maxStreak = days }
            }
            lastDate = order.date
        }
        return maxStreak
    }

    private func parse(csv: String) -> [FoodOrder] {
        var results: [FoodOrder] = []
        for line in csv.split(separator: "\n") {
            let parts = line.split(separator: ",")
            if parts.count >= 3,
               let date = dateFormatter.date(from: String(parts[0])),
               let amount = Double(parts[1]) {
                let appName = String(parts[2])
                results.append(FoodOrder(date: date, amount: amount, appName: appName))
            }
        }
        return results
    }
}
