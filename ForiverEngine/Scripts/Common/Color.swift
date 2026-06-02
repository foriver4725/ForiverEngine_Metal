struct Color {
    var r: Float
    var g: Float
    var b: Float
    var a: Float

    static let transparent = Color(r: 0, g: 0, b: 0, a: 0)
    static let black = Color(r: 0, g: 0, b: 0, a: 1)
    static let white = Color(r: 1, g: 1, b: 1, a: 1)
    static let red = Color(r: 1, g: 0, b: 0, a: 1)
    static let green = Color(r: 0, g: 1, b: 0, a: 1)
    static let blue = Color(r: 0, g: 0, b: 1, a: 1)
    static let yellow = Color(r: 1, g: 1, b: 0, a: 1)
    static let magenta = Color(r: 1, g: 0, b: 1, a: 1)
    static let cyan = Color(r: 0, g: 1, b: 1, a: 1)
}
