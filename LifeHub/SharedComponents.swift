import SwiftUI

// MARK: - Haptic Feedback Helper

/// Centralized haptic feedback manager for consistent haptic usage across the app
struct HapticFeedback {
    
    /// Light impact haptic for subtle interactions (button taps, card selections)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact haptic for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact haptic for significant interactions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Success notification haptic
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification haptic
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification haptic
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Selection changed haptic
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Constants

/// Centralized animation constants for consistent animations across the app
enum AnimationConstants {
    static let quickDuration: Double = 0.2
    static let standardDuration: Double = 0.3
    static let slowDuration: Double = 0.4
    
    static var quick: Animation { .smooth(duration: quickDuration) }
    static var standard: Animation { .smooth(duration: standardDuration) }
    static var slow: Animation { .smooth(duration: slowDuration) }
    
    static var spring: Animation { .spring(response: 0.3, dampingFraction: 0.7) }
    static var bouncy: Animation { .spring(response: 0.4, dampingFraction: 0.6) }
}

// MARK: - Loading View

/// Reusable loading view with consistent styling
struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Empty State View

/// Reusable empty state view for when no data is available
struct EmptyStateView: View {
    var iconName: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticFeedback.light()
                    action()
                }) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue, in: .capsule)
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Error View

/// Reusable error view with retry functionality
struct ErrorView: View {
    var errorMessage: String
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(errorMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let retryAction = retryAction {
                Button(action: {
                    HapticFeedback.light()
                    retryAction()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: .capsule)
                    .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Previews

#Preview("Loading View") {
    LoadingView()
}

#Preview("Empty State View") {
    EmptyStateView(
        iconName: "chart.bar.xaxis",
        title: "No Data Available",
        message: "Start tracking your health metrics to see your progress here.",
        actionTitle: "Get Started",
        action: { print("Action tapped") }
    )
}

#Preview("Error View") {
    ErrorView(
        errorMessage: "Failed to load health data. Please check your connection and try again.",
        retryAction: { print("Retry tapped") }
    )
}
