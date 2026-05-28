enum Text {
    static let invalidFontTextureIndex: UInt8 = 0xff
    static let defaultColor = Color.black

    struct Data {
        var color: Color
        var fontTextureIndex: UInt8

        static func createDefault() -> Data {
            Data(
                color: Text.defaultColor,
                fontTextureIndex: Text.invalidFontTextureIndex
            )
        }
    }

    static func convertToFontTextureIndex(_ char: Character) -> UInt8 {
        switch char.lowercased() {
        case "a": return 0
        case "b": return 1
        case "c": return 2
        case "d": return 3
        case "e": return 4
        case "f": return 5
        case "g": return 6
        case "h": return 7
        case "i": return 8
        case "j": return 9
        case "k": return 10
        case "l": return 11
        case "m": return 12
        case "n": return 13
        case "o": return 14
        case "p": return 15
        case "q": return 16
        case "r": return 17
        case "s": return 18
        case "t": return 19
        case "u": return 20
        case "v": return 21
        case "w": return 22
        case "x": return 23
        case "y": return 24
        case "z": return 25
        case ":": return 26
        case "!": return 27
        case "?": return 28
        case ".": return 29
        case ",": return 30
        case "~": return 31
        case "0": return 32
        case "1": return 33
        case "2": return 34
        case "3": return 35
        case "4": return 36
        case "5": return 37
        case "6": return 38
        case "7": return 39
        case "8": return 40
        case "9": return 41
        default: return invalidFontTextureIndex
        }
    }
}
