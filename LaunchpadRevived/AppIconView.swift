import AppKit
import SwiftUI

/// Single app icon cell. Hit target is icon + label only (LAY-10). Focus uses the
/// system keyboard-focus indicator color (LAY-12). Badge stays `nil` in Slice 1 (B-10).
struct AppIconView: View {
    let app: DiscoveredApp
    var badge: Int? = nil
    let iconSize: CGFloat
    var isFocused: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: app.icon(size: iconSize))
                        .resizable()
                        .interpolation(.none)
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
            // Intrinsic size only — do not expand to the cell (LAY-10).
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(nsColor: .keyboardFocusIndicatorColor), lineWidth: 3)
                        .padding(-4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func badgeText(_ value: Int) -> String {
        value > 99 ? "99+" : "\(value)"
    }
}
