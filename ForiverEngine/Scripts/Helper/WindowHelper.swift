import Cocoa

enum WindowHelper {
    private static let windowSize = NSSize(width: 1344, height: 756)

    static var windowRect: NSRect {
        NSRect(
            x: 0,
            y: 0,
            width: windowSize.width,
            height: windowSize.height
        )
    }
}
