import SwiftUI

/// Custom button style for glass card buttons with press animation
struct GlassCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.smooth(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCardButtonStyle {
    static var glassCard: GlassCardButtonStyle {
        GlassCardButtonStyle()
    }
}
