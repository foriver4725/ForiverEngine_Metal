final class DebugFrameTimeStats {
    private let recordCount: Int
    private var frameTimes: [Double]
    private var currentIndex: Int = 0

    init(recordCount: Int) {
        self.recordCount = recordCount
        self.frameTimes = Array(repeating: 0.0, count: recordCount)
    }

    func record(_ frameTime: Double) {
        frameTimes[currentIndex] = frameTime
        currentIndex = (currentIndex + 1) % recordCount
    }

    func calculateMean() -> Double {
        var sum = 0.0

        for frameTime in frameTimes {
            sum += frameTime
        }

        return sum / Double(recordCount)
    }
}
