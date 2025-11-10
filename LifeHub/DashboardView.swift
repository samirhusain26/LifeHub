import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        viewModel.syncData()
                    }) {
                        Text("Sync Now")
                    }
                    .padding()

                    Spacer()

                    Button(action: {
                        self.showShareSheet = true
                    }) {
                        Text("Export Data")
                    }
                    .padding()
                }

                if let lastSyncTime = viewModel.lastSyncTime {
                    Text("Last sync: \(lastSyncTime, formatter: itemFormatter)")
                        .font(.footnote)
                } else {
                    Text("Not synced yet")
                        .font(.footnote)
                }

                List(viewModel.healthData) { data in
                    VStack(alignment: .leading) {
                        Text("Date: \(data.date, formatter: itemFormatter)")
                        Text("Steps: \(data.stepCount ?? 0)")
                        Text("Weight: \(data.weight ?? 0, specifier: "%.1f")")
                        Text("Sleep: \(data.sleepDuration ?? 0, specifier: "%.1f") hours")
                    }
                }
            }
            .navigationTitle("LifeHub")
            .onAppear {
                viewModel.syncData()
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = viewModel.getCSVFileURL() {
                    ActivityViewController(activityItems: [fileURL])
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

#Preview {
    DashboardView()
}
