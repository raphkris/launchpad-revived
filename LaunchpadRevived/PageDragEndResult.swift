/// Outcome of releasing a background page drag (LAY-09).
enum PageDragEndResult: Sendable {
    case dismiss
    case springBack
    case committed
}
