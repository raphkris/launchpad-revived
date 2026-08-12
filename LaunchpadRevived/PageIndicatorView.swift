import SwiftUI

/// Page-dot indicator with no surface behind the dots (LAY-04, LAY-05).
struct PageIndicatorView: View {
    let pageCount: Int
    let currentPage: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .contentShape(Rectangle().size(CGSize(width: 20, height: 20)))
                    .onTapGesture {
                        onSelect(index)
                    }
                    .accessibilityLabel("Page \(index + 1)")
            }
        }
    }
}
