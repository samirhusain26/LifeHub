import SwiftUI

struct SleepConsistencyView: View {
    let sleepConsistency: (wake: Double, duration: Double)
    let definition: String = "This metric shows the standard deviation of your wake-up times and sleep durations over the last 7 days. Lower numbers indicate better consistency."

    @State private var isShowingPopover = false
    @Namespace private var glassNamespace

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            isShowingPopover = true
        }) {
            GlassEffectContainer(spacing: 16.0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wake up consistency")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("±\(Int(round(sleepConsistency.wake)))m")
                                .font(.system(size: 32, weight: .bold))
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .glassEffect(.regular.tint(.blue.opacity(0.1)), in: .rect(cornerRadius: 12))
                        .glassEffectID("wake", in: glassNamespace)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration consistency")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("±\(Int(round(sleepConsistency.duration)))m")
                                .font(.system(size: 32, weight: .bold))
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .glassEffect(.regular.tint(.purple.opacity(0.1)), in: .rect(cornerRadius: 12))
                        .glassEffectID("duration", in: glassNamespace)
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.glassCard)
        .glassEffect(.regular.tint(.indigo.opacity(0.05)).interactive(), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep Consistency: Wake up ±\(Int(round(sleepConsistency.wake))) minutes, Duration ±\(Int(round(sleepConsistency.duration))) minutes")
        .accessibilityHint("Double tap for more information")
        .popover(isPresented: $isShowingPopover) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
                .padding(20)
            }
            .frame(maxWidth: 340)
            .frame(maxHeight: 300)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    SleepConsistencyView(sleepConsistency: (wake: 25, duration: 45))
        .padding()
}
