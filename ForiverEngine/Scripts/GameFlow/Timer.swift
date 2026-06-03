final class Timer {
    private let durationSeconds: Float
    private var elapsedSeconds: Float = 0

    init(durationSeconds: Float) {
        self.durationSeconds = durationSeconds
    }

    func onEveryFrame(_ deltaSeconds: Float) {
        elapsedSeconds += deltaSeconds
        elapsedSeconds = min(max(elapsedSeconds, 0), durationSeconds)
    }

    func isFinished() -> Bool {
        elapsedSeconds >= durationSeconds
    }

    func reset() {
        elapsedSeconds = 0
    }

    func countToFinishImmediately() {
        elapsedSeconds = durationSeconds
    }
}
