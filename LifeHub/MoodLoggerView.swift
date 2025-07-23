import SwiftUI

struct MoodLoggerView: View {
    @AppStorage("gymCheckIn") private var gymCheckIn = Date()
    @AppStorage("meditationDone") private var meditationDone = false
    @AppStorage("unhealthyMeal") private var unhealthyMeal = false
    @State private var selectedTags: Set<String> = []

    private let moodTags = ["anxious", "calm", "focused", "lonely"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activities")) {
                    DatePicker("Gym Check-In", selection: $gymCheckIn, displayedComponents: .date)
                    Toggle("Meditation Completed", isOn: $meditationDone)
                    Toggle("Unhealthy Meal", isOn: $unhealthyMeal)
                }

                Section(header: Text("Mood Tags")) {
                    ForEach(moodTags, id: \.self) { tag in
                        MultipleSelectionRow(title: tag, isSelected: selectedTags.contains(tag)) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log")
        }
    }
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
    MoodLoggerView()
}
