import simd

extension Vector2 {
    static let zero = Vector2(0, 0)
    static let one = Vector2(1, 1)
    static let right = Vector2(1, 0)
    static let left = Vector2(-1, 0)
    static let up = Vector2(0, 1)
    static let down = Vector2(0, -1)

    var len: Float {
        simd_length(self)
    }

    var lenSq: Float {
        simd_length_squared(self)
    }

    var normed: Vector2 {
        simd_normalize(self)
    }
}
