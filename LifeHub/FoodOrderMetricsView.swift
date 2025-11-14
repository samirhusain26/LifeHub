import SwiftUI

struct FoodOrderMetricsView: View {
    let deliverySpendTrends: String
    let cleanStreak: String
    let definition: String = "This card shows your food order trends. '30-Day Orders' and 'Yearly Orders' compare spending to the previous period. 'Clean Eating Streak' is the number of days since your last food order."

    @State private var isShowingPopover = false
    @Namespace private var glassNamespace

    private var thirtyDayOrders: String {
        let parts = deliverySpendTrends.components(separatedBy: "•")
        return parts.first?.trimmingCharacters(in: .whitespaces) ?? "N/A"
    }

    private var yearlyOrders: String {
        let parts = deliverySpendTrends.components(separatedBy: "•")
        return parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : "N/A"
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            isShowingPopover = true
        }) {
            GlassEffectContainer(spacing: 20.0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        // Left Column
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("30-Day Orders")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(thirtyDayOrders)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular.tint(.orange.opacity(0.1)), in: .rect(cornerRadius: 12))
                            .glassEffectID("30day", in: glassNamespace)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Yearly Orders")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(yearlyOrders)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular.tint(.red.opacity(0.1)), in: .rect(cornerRadius: 12))
                            .glassEffectID("yearly", in: glassNamespace)
                        }
                        .frame(maxWidth: .infinity)

                        // Right Column
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Clean Eating Streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(cleanStreak)
                                .font(.system(size: 64, weight: .bold))
                                .minimumScaleFactor(0.6)
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.green)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 150)
                        .glassEffect(.regular.tint(.green.opacity(0.1)), in: .rect(cornerRadius: 12))
                        .glassEffectID("streak", in: glassNamespace)
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.glassCard)
        .glassEffect(.regular.tint(.green.opacity(0.05)).interactive(), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Food Orders: \(deliverySpendTrends), Clean Streak: \(cleanStreak) days")
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
    FoodOrderMetricsView(deliverySpendTrends: "$150 (▲10%) • $2500 (▼5%)", cleanStreak: "12")
        .padding()
}
