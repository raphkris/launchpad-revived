import AppKit

/// Turns pages from trackpad and mouse `.scrollWheel` events (LAY-06).
///
/// Accumulates `scrollingDeltaX`, commits one page turn past a threshold, then
/// ignores the rest of that gesture including momentum so one flick = one page.
@MainActor
final class ScrollWheelPageTurner {
    private var monitor: Any?
    private var accumulated: CGFloat = 0
    private var ignoringRestOfGesture = false

    private let onTurn: (Int) -> Void

    init(onTurn: @escaping (Int) -> Void) {
        self.onTurn = onTurn
    }

    func start() {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        accumulated = 0
        ignoringRestOfGesture = false
    }

    private func handle(_ event: NSEvent) {
        // Vertical delta is ignored for pagination (LAY-06).
        let raw = event.scrollingDeltaX
        guard raw != 0 || !event.phase.isEmpty || !event.momentumPhase.isEmpty else { return }

        let delta = event.hasPreciseScrollingDeltas ? raw : raw * 10
        let phase = event.phase
        let momentum = event.momentumPhase

        if phase == .began {
            accumulated = 0
            ignoringRestOfGesture = false
        }

        if ignoringRestOfGesture {
            if isGestureFinished(phase: phase, momentum: momentum) {
                ignoringRestOfGesture = false
                accumulated = 0
            }
            return
        }

        // Discrete mouse-wheel notches: one notch, one page.
        if !event.hasPreciseScrollingDeltas {
            if abs(delta) > 0 {
                // Positive deltaX → content moves right → previous page.
                onTurn(delta > 0 ? -1 : 1)
            }
            return
        }

        accumulated += delta
        if abs(accumulated) >= GridLayout.pageScrollThreshold {
            onTurn(accumulated > 0 ? -1 : 1)
            ignoringRestOfGesture = true
            accumulated = 0
        }

        if isGestureFinished(phase: phase, momentum: momentum) {
            accumulated = 0
        }
    }

    private func isGestureFinished(phase: NSEvent.Phase, momentum: NSEvent.Phase) -> Bool {
        if phase == .ended || phase == .cancelled { return true }
        if momentum == .ended || momentum == .cancelled { return true }
        return false
    }
}
