import MetalKit

final class View: MTKView {
    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        InputHelper.onPressed(
            InputHelper.convertNSEventToKey(event)
        )
    }

    override func keyUp(with event: NSEvent) {
        InputHelper.onReleased(
            InputHelper.convertNSEventToKey(event)
        )
    }

    override func mouseDown(with event: NSEvent) {
        InputHelper.onPressed(.lMouse)
    }

    override func mouseUp(with event: NSEvent) {
        InputHelper.onReleased(.lMouse)
    }

    override func rightMouseDown(with event: NSEvent) {
        InputHelper.onPressed(.rMouse)
    }

    override func rightMouseUp(with event: NSEvent) {
        InputHelper.onReleased(.rMouse)
    }

    override func otherMouseDown(with event: NSEvent) {
        if event.buttonNumber == 2 {
            InputHelper.onPressed(.mMouse)
        }
    }

    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            InputHelper.onReleased(.mMouse)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        InputHelper.onMouseDelta(
            Vector2(
                Float(event.deltaX),
                Float(-event.deltaY)
            )
        )
    }

    override func mouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }

    override func otherMouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }

    override func scrollWheel(with event: NSEvent) {
        InputHelper.onMouseWheelDelta(Float(event.scrollingDeltaY))
    }

    func initKeyTable() {
        InputHelper.initKeyTable()
    }
}
