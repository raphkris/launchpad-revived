import AppKit

/// Turns pages from trackpad and mouse `.scrollWheel` events (LAY-06, LAY-14).
///
/// Precise (trackpad) events feed `pageDragOffset` 1:1, then settle through the
/// shared page-transition model. Non-precise (wheel) events pick the larger of
/// X/Y as the page axis and turn one page per notch.
@MainActor
final class ScrollWheelPageTurner {
    private var monitor: Any?
    private var gestureOffset: CGFloat = 0
    private var velocity: CGFloat = 0
    private var lastTimestamp: TimeInterval = 0
    /// Finger-up is not the end of the gesture; momentum may still follow (LAY-14).
    private var ignoringRestOfGesture = false

    private let onOffsetChanged: (CGFloat) -> Void
    private let onGestureEnded: (CGFloat, CGFloat) -> Void
    private let onDiscreteTurn: (Int) -> Void

    init(
        onOffsetChanged: @escaping (CGFloat) -> Void,
        onGestureEnded: @escaping (CGFloat, CGFloat) -> Void,
        onDiscreteTurn: @escaping (Int) -> Void
    ) {
        self.onOffsetChanged = onOffsetChanged
        self.onGestureEnded = onGestureEnded
        self.onDiscreteTurn = onDiscreteTurn
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
        resetGesture()
        ignoringRestOfGesture = false
    }

    private func handle(_ event: NSEvent) {
        if !event.hasPreciseScrollingDeltas {
            handleDiscrete(event)
            return
        }

        let phase = event.phase
        let momentum = event.momentumPhase

        // Momentum never paginates. Finger-up already settled; leftover stream is ignored.
        if !momentum.isEmpty {
            if ignoringRestOfGesture, isGestureFinished(phase: phase, momentum: momentum) {
                ignoringRestOfGesture = false
                resetGesture()
            }
            return
        }

        if phase == .began || ignoringRestOfGesture {
            resetGesture()
            ignoringRestOfGesture = false
        }

        let delta = event.scrollingDeltaX
        if phase == .began || phase == .changed || phase == .stationary || phase == .ended {
            gestureOffset += delta
            noteVelocity(delta: delta, timestamp: event.timestamp)
            onOffsetChanged(gestureOffset)
        }

        if phase == .ended {
            onGestureEnded(gestureOffset, velocity)
            ignoringRestOfGesture = true
            resetGesture()
            return
        }

        if phase == .cancelled {
            onGestureEnded(0, 0)
            ignoringRestOfGesture = true
            resetGesture()
        }
    }

    private func handleDiscrete(_ event: NSEvent) {
        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        let axis = abs(dx) >= abs(dy) ? dx : dy
        guard axis != 0 else { return }
        // Positive delta → content moves toward the previous page, matching drag.
        onDiscreteTurn(axis > 0 ? -1 : 1)
    }

    /// A gesture is not finished at `phase == .ended`: that fires before momentum.
    private func isGestureFinished(phase: NSEvent.Phase, momentum: NSEvent.Phase) -> Bool {
        if phase == .cancelled { return true }
        if momentum == .ended || momentum == .cancelled { return true }
        return false
    }

    private func noteVelocity(delta: CGFloat, timestamp: TimeInterval) {
        let dt = timestamp - lastTimestamp
        lastTimestamp = timestamp
        guard dt > 0, dt < 0.05 else { return }
        let instant = delta / CGFloat(dt)
        velocity = velocity * 0.6 + instant * 0.4
    }

    private func resetGesture() {
        gestureOffset = 0
        velocity = 0
        lastTimestamp = 0
    }
}
