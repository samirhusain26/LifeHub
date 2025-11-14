import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let iconName: String
    var definition: String? = nil
    var rawData: String? = nil

    @State private var isShowingPopover = false

    var body: some View {
        Button(action: {
            if definition != nil || rawData != nil {
                HapticFeedback.light()
                isShowingPopover = true
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        }
        .buttonStyle(.glassCard)
        .glassEffect(.regular.tint(.accentColor.opacity(0.05)).interactive(), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(definition != nil ? "Double tap for more information" : "")
        .popover(isPresented: $isShowingPopover) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let definition = definition {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Definition")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(definition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let rawData = rawData {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Raw Data")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(rawData)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: 340)
            .frame(maxHeight: 400)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    MetricCardView(
        title: "Active Days",
        value: "5/7 Days",
        iconName: "figure.run",
        definition: "This shows the number of days in the last 14 where you met your activity goal.",
        rawData: "Last 7 Days: 5, Previous 7 Days: 3"
    )
    .padding()
}
