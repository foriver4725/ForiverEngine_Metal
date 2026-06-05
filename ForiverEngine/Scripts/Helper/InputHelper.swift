import Cocoa

enum Key: UInt8, CaseIterable {
    case unknown = 0

    case lMouse, rMouse, mMouse

    case n0, n1, n2, n3, n4, n5, n6, n7, n8, n9
    case np0, np1, np2, np3, np4, np5, np6, np7, np8, np9

    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z

    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case f13, f14, f15, f16, f17, f18, f19, f20, f21, f22, f23, f24

    case up, down, left, right

    case space
    case tab
    case enter
    case backspace
    case delete
    case escape

    case lShift, rShift
    case lCtrl, rCtrl
    case lAlt, rAlt

    case count
}

struct KeyInfo {
    var pressed: Bool = false
    var released: Bool = false

    var pressedNow: Bool = false
    var releasedNow: Bool = false
}

enum InputHelper {
    private static var keyTable: [KeyInfo] =
        Array(
            repeating: KeyInfo(released: true),
            count: Int(Key.count.rawValue)
        )

    private static var mouseWheelDelta: Float = 0
    private static var mouseDelta: Vector2 = .zero

    private static var isCursorHidden: Bool = false

    static func initKeyTable() {
        for i in keyTable.indices {
            keyTable[i] = KeyInfo(
                pressed: false,
                released: true,
                pressedNow: false,
                releasedNow: false
            )
        }

        mouseWheelDelta = 0
        mouseDelta = .zero
    }

    static func onEveryFrame() {
        for i in keyTable.indices {
            keyTable[i].pressedNow = false
            keyTable[i].releasedNow = false
        }

        mouseWheelDelta = 0
        mouseDelta = .zero
    }

    static func onPressed(_ key: Key) {
        guard key != .unknown else {
            return
        }

        let index = Int(key.rawValue)

        if !keyTable[index].pressed {
            keyTable[index].pressed = true
            keyTable[index].released = false
            keyTable[index].pressedNow = true
        }
    }

    static func onReleased(_ key: Key) {
        guard key != .unknown else {
            return
        }

        let index = Int(key.rawValue)

        if !keyTable[index].released {
            keyTable[index].pressed = false
            keyTable[index].released = true
            keyTable[index].releasedNow = true
        }
    }

    static func onMouseWheelDelta(_ delta: Float) {
        mouseWheelDelta += delta
    }

    static func onMouseDelta(_ delta: Vector2) {
        mouseDelta += delta
    }

    static func setCursorActive(_ active: Bool) {
        if active && isCursorHidden {
            CGAssociateMouseAndMouseCursorPosition(boolean_t(truncating: true))
            NSCursor.unhide()
            isCursorHidden = false
        } else if !active && !isCursorHidden {
            CGAssociateMouseAndMouseCursorPosition(boolean_t(truncating: false))
            NSCursor.hide()
            isCursorHidden = true
        }
    }

    // Manual clear
    static func clearMouseDelta() {
        mouseDelta = .zero
    }

    static func getKeyInfo(_ key: Key) -> KeyInfo {
        keyTable[Int(key.rawValue)]
    }

    static func getMouseWheelDelta() -> Float {
        mouseWheelDelta
    }

    static func getMouseDelta() -> Vector2 {
        Vector2(x: mouseDelta.x, y: -mouseDelta.y)  // Up is positive
    }

    static func getAsAxis1D(
        positiveKey: Key,
        negativeKey: Key
    ) -> Float {
        var value: Float = 0

        if getKeyInfo(positiveKey).pressed {
            value += 1
        }

        if getKeyInfo(negativeKey).pressed {
            value -= 1
        }

        return MathUtils.clamp(value, -1, 1)
    }

    static func getAsAxis2D(
        upKey: Key,
        downKey: Key,
        leftKey: Key,
        rightKey: Key
    ) -> Vector2 {
        var value = Vector2.zero

        if getKeyInfo(upKey).pressed {
            value.y += 1
        }

        if getKeyInfo(downKey).pressed {
            value.y -= 1
        }

        if getKeyInfo(leftKey).pressed {
            value.x -= 1
        }

        if getKeyInfo(rightKey).pressed {
            value.x += 1
        }

        return value.normed
    }

    static func convertNSEventToKey(_ event: NSEvent) -> Key {
        switch event.keyCode {
        case 0: return .a
        case 11: return .b
        case 8: return .c
        case 2: return .d
        case 14: return .e
        case 3: return .f
        case 5: return .g
        case 4: return .h
        case 34: return .i
        case 38: return .j
        case 40: return .k
        case 37: return .l
        case 46: return .m
        case 45: return .n
        case 31: return .o
        case 35: return .p
        case 12: return .q
        case 15: return .r
        case 1: return .s
        case 17: return .t
        case 32: return .u
        case 9: return .v
        case 13: return .w
        case 7: return .x
        case 16: return .y
        case 6: return .z

        case 29: return .n0
        case 18: return .n1
        case 19: return .n2
        case 20: return .n3
        case 21: return .n4
        case 23: return .n5
        case 22: return .n6
        case 26: return .n7
        case 28: return .n8
        case 25: return .n9

        case 82: return .np0
        case 83: return .np1
        case 84: return .np2
        case 85: return .np3
        case 86: return .np4
        case 87: return .np5
        case 88: return .np6
        case 89: return .np7
        case 91: return .np8
        case 92: return .np9

        case 122: return .f1
        case 120: return .f2
        case 99: return .f3
        case 118: return .f4
        case 96: return .f5
        case 97: return .f6
        case 98: return .f7
        case 100: return .f8
        case 101: return .f9
        case 109: return .f10
        case 103: return .f11
        case 111: return .f12

        case 126: return .up
        case 125: return .down
        case 123: return .left
        case 124: return .right

        case 49: return .space
        case 48: return .tab
        case 36, 76: return .enter
        case 51: return .backspace
        case 117: return .delete
        case 53: return .escape

        case 56: return .lShift
        case 60: return .rShift
        case 59: return .lCtrl
        case 62: return .rCtrl
        case 58: return .lAlt
        case 61: return .rAlt

        default:
            return .unknown
        }
    }
}
