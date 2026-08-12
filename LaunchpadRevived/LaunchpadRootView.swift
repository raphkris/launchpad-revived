import SwiftUI

/// Root SwiftUI content hosted in the Launchpad window (PRJ-02).
///
/// Owns keyboard focus, ⌘-arrow / arrow handling (LAY-05, LAY-08), scroll page
/// turns (LAY-06), and background click-drag pagination (LAY-09).
struct LaunchpadRootView: View {
    @Bindable var viewModel: LaunchpadViewModel
    var onBackgroundClick: () -> Void
    var onSelectApp: (DiscoveredApp) -> Void

    @FocusState private var isSurfaceFocused: Bool
    @State private var scrollTurner: ScrollWheelPageTurner?

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width

            ZStack {
                WallpaperBackgroundView(image: viewModel.wallpaper)

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(backgroundDragGesture(pageWidth: pageWidth))

                AppGridView(
                    viewModel: viewModel,
                    onSelect: onSelectApp
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focused($isSurfaceFocused)
        .onAppear {
            isSurfaceFocused = true
            let vm = viewModel
            let turner = ScrollWheelPageTurner { [weak vm] direction in
                guard let vm else { return }
                if direction < 0 {
                    vm.goToPreviousPage()
                } else {
                    vm.goToNextPage()
                }
            }
            scrollTurner = turner
            turner.start()
        }
        .onDisappear {
            scrollTurner?.stop()
            scrollTurner = nil
        }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow], phases: .down) {
            keyPress in
            handleArrowKey(keyPress)
        }
        .onKeyPress(.return, phases: .down) { _ in
            launchFocused()
        }
        .onKeyPress(
            KeyEquivalent(" "),
            phases: .down
        ) { _ in
            launchFocused()
        }
    }

    private func backgroundDragGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                // Icon hits never reach this gesture — dragging an icon does nothing (INT-03).
                viewModel.pageDragOffset = value.translation.width
            }
            .onEnded { value in
                let result = viewModel.endPageDrag(
                    translation: value.translation.width,
                    velocity: value.velocity.width,
                    pageWidth: pageWidth
                )
                switch result {
                case .dismiss:
                    onBackgroundClick()
                case .springBack, .committed:
                    isSurfaceFocused = true
                }
            }
    }

    private func handleArrowKey(_ keyPress: KeyPress) -> KeyPress.Result {
        if keyPress.modifiers.contains(.command) {
            switch keyPress.key {
            case .leftArrow:
                viewModel.goToPreviousPage()
                return .handled
            case .rightArrow:
                viewModel.goToNextPage()
                return .handled
            default:
                return .ignored
            }
        }

        switch keyPress.key {
        case .leftArrow:
            viewModel.moveFocus(.left)
        case .rightArrow:
            viewModel.moveFocus(.right)
        case .upArrow:
            viewModel.moveFocus(.up)
        case .downArrow:
            viewModel.moveFocus(.down)
        default:
            return .ignored
        }
        return .handled
    }

    private func launchFocused() -> KeyPress.Result {
        guard let app = viewModel.focusedApp() else { return .ignored }
        onSelectApp(app)
        return .handled
    }
}
