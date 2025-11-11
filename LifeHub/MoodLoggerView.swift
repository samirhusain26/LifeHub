import SwiftUI
import SwiftData

struct MoodLoggerView: View {
    var date: Date
    
    @Environment(\.modelContext) private var modelContext
    @State private var dailyLog: DailyLog?

    private let moodTags = ["anxious", "calm", "focused", "lonely"]

    var body: some View {
        NavigationView {
            if let dailyLog = dailyLog {
                Form {
                    Section(header: Text("Activities")) {
                        Toggle("Gym Check-In", isOn: Binding(
                            get: { dailyLog.didVisitGym },
                            set: { dailyLog.didVisitGym = $0 }
                        ))
                        Toggle("Meditation Completed", isOn: Binding(
                            get: { dailyLog.didMeditate },
                            set: { dailyLog.didMeditate = $0 }
                        ))
                        Toggle("Unhealthy Meal", isOn: Binding(
                            get: { dailyLog.hadUnhealthyMeal },
                            set: { dailyLog.hadUnhealthyMeal = $0 }
                        ))
                    }

                    Section(header: Text("Mood Tags")) {
                        ForEach(moodTags, id: \.self) { tag in
                            MultipleSelectionRow(title: tag, isSelected: dailyLog.moodTags.contains(tag)) {
                                if dailyLog.moodTags.contains(tag) {
                                    dailyLog.moodTags.removeAll { $0 == tag }
                                } else {
                                    dailyLog.moodTags.append(tag)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(date, formatter: DateFormatter.shortDate)
            } else {
                Text("Loading...")
                    .onAppear(perform: setupDailyLog)
            }
        }
    }
    
    private func setupDailyLog() {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let fetchDescriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            let results = try modelContext.fetch(fetchDescriptor)
            if let existingLog = results.first {
                dailyLog = existingLog
            } else {
                let newLog = DailyLog(date: startOfDay, moodTags: [], didMeditate: false, didVisitGym: false, hadUnhealthyMeal: false)
                modelContext.insert(newLog)
                dailyLog = newLog
            }
        } catch {
            print("Failed to fetch or create daily log: \(error)")
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}


struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected { Image(systemName: "checkmark") }
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: DailyLog.self, configurations: .init(inMemory: true))
        return MoodLoggerView(date: Date())
            .modelContainer(container)
    } catch {
        return Text("Failed to create container: \(error.localizedDescription)")
    }
}
