import SwiftUI

/// Single app icon cell. Accepts an optional badge that is always `nil` in Slice 1 (B-10).
struct AppIconView: View {
    let app: DiscoveredApp
    var badge: Int? = nil
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: app.icon(size: iconSize))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: iconSize, height: iconSize)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                    if let badge {
                        Text(badgeText(badge))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.red))
                            .offset(x: 6, y: -6)
                    }
                }

                Text(app.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: iconSize + 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(.plain)
    }

    private func badgeText(_ value: Int) -> String {
        value > 99 ? "99+" : "\(value)"
    }
}
