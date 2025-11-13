import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 4)

            Spacer()

            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(.accentColor)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MetricCardView(title: "Active Days", value: "5/7 Days", iconName: "figure.run")
        .padding()
        .background(Color.gray.opacity(0.2))
}
