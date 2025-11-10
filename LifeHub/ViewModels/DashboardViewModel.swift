import Foundation
import Combine
import UIKit

class DashboardViewModel: ObservableObject {
    @Published var lastSyncTime: Date?
    @Published var healthData: [HealthData] = []

    private var healthKitManager = HealthKitManager.shared
    private var persistenceController = PersistenceController.shared

    func syncData() {
        healthKitManager.requestAuthorization { [weak self] success, error in
            if success {
                self?.healthKitManager.fetchHealthData { healthData in
                    self?.persistenceController.saveHealthData(healthData: healthData)
                    DispatchQueue.main.async {
                        self?.healthData = healthData
                        self?.lastSyncTime = Date()
                    }
                }
            } else {
                // Handle error
            }
        }
    }

    func getCSVFileURL() -> URL? {
        let healthData = persistenceController.fetchHealthData()
        let csvString = generateCSV(from: healthData)

        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = "LifeHub_Export.csv"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV file: \(error)")
            return nil
        }
    }

    private func generateCSV(from data: [HealthData]) -> String {
        var csvString = "date,step_count,weight,sleep_start,sleep_end,sleep_duration\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for item in data {
            let date = dateFormatter.string(from: item.date)
            let stepCount = item.stepCount ?? 0
            let weight = item.weight ?? 0
            let sleepStart = item.sleepStart.map { dateFormatter.string(from: $0) } ?? ""
            let sleepEnd = item.sleepEnd.map { dateFormatter.string(from: $0) } ?? ""
            let sleepDuration = item.sleepDuration ?? 0
            csvString.append("\(date),\(stepCount),\(weight),\(sleepStart),\(sleepEnd),\(sleepDuration)\n")
        }
        return csvString
    }
}

struct HealthData: Identifiable {
    let id = UUID()
    let date: Date
    let stepCount: Int?
    let weight: Double?
    let sleepStart: Date?
    let sleepEnd: Date?
    let sleepDuration: TimeInterval?
}
