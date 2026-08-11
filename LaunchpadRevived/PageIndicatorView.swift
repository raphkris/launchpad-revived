import SwiftUI

/// Page-dot indicator; click a dot to jump pages (LAY-04, LAY-05).
struct PageIndicatorView: View {
    let pageCount: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .contentShape(Rectangle().size(CGSize(width: 20, height: 20)))
                    .onTapGesture {
                        currentPage = index
                    }
                    .accessibilityLabel("Page \(index + 1)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect()
    }
}
