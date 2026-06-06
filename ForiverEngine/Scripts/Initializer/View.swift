import MetalKit

final class View: MTKView {
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)
        window?.acceptsMouseMovedEvents = true

        InputHelper.setCursorActive(false)
        warpMouseToCenter()
        InputHelper.clearMouseDelta()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let newTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .activeAlways,
                .mouseMoved,
                .enabledDuringMouseDrag,
                .inVisibleRect,
            ],
            owner: self,
            userInfo: nil
        )

        addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }

    override func flagsChanged(with event: NSEvent) {
        let key = InputHelper.convertNSEventToKey(event)

        switch key {
        case .lShift, .rShift:
            updateModifierKey(key, flag: .shift, event: event)

        case .lCtrl, .rCtrl:
            updateModifierKey(key, flag: .control, event: event)

        case .lAlt, .rAlt:
            updateModifierKey(key, flag: .option, event: event)

        default:
            break
        }
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

    private func updateModifierKey(
        _ key: Key,
        flag: NSEvent.ModifierFlags,
        event: NSEvent
    ) {
        if event.modifierFlags.contains(flag) {
            InputHelper.onPressed(key)
        } else {
            InputHelper.onReleased(key)
        }
    }

    // NOTE: This results to large mouse delta.
    private func warpMouseToCenter() {
        guard let window else {
            return
        }

        let centerInWindow = CGPoint(
            x: bounds.midX,
            y: bounds.midY
        )

        let centerOnScreen = convert(
            centerInWindow,
            to: nil
        )

        let screenPoint = window.convertPoint(
            toScreen: centerOnScreen
        )

        CGWarpMouseCursorPosition(screenPoint)
    }

    func initKeyTable() {
        InputHelper.initKeyTable()
    }
}
