import Cocoa

final class EscWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            NSApp.terminate(nil)
            return
        }

        super.keyDown(with: event)
    }
}
