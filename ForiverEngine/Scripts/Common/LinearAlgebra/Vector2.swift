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

    static func dot(_ lhs: Vector2, _ rhs: Vector2) -> Float {
        simd_dot(lhs, rhs)
    }

    static func cross(_ lhs: Vector2, _ rhs: Vector2) -> Float {
        lhs.x * rhs.y - lhs.y * rhs.x
    }

    static func lerp(_ from: Vector2, _ to: Vector2, _ t: Float) -> Vector2 {
        let _t = Clamp(t, 0.0, 1.0)
        return from + (to - from) * _t
    }

    static func slerp(_ from: Vector2, _ to: Vector2, _ t: Float) -> Vector2 {
        let _t = Clamp(t, 0.0, 1.0)
        let dot = dot(from.normed, to.normed)
        let clampedDot = Clamp(dot, -1.0, 1.0)
        let theta = acos(clampedDot) * _t
        let relativeVec = (to - from * dot).normed
        return (from * cos(theta)) + (relativeVec * sin(theta))
    }

    static func reflect(_ vector: Vector2, _ normal: Vector2) -> Vector2 {
        let _normal = normal.normed
        let dot = dot(vector, _normal)
        return vector - 2.0 * dot * _normal
    }
}
