import simd

extension Vector4 {
    var len: Float {
        simd_length(self)
    }

    var lenSq: Float {
        simd_length_squared(self)
    }

    var normed: Vector4 {
        simd_normalize(self)
    }

    static func dot(_ lhs: Vector4, _ rhs: Vector4) -> Float {
        simd_dot(lhs, rhs)
    }

    static func lerp(_ from: Vector4, _ to: Vector4, _ t: Float) -> Vector4 {
        let _t = Clamp(t, 0.0, 1.0)
        return from + (to - from) * _t
    }

    static func slerp(_ from: Vector4, _ to: Vector4, _ t: Float) -> Vector4 {
        let _t = Clamp(t, 0.0, 1.0)
        let dot = dot(from.normed, to.normed)
        let theta = acos(Clamp(dot, -1.0, 1.0)) * _t
        let relativeVec = (to - from * dot).normed
        return (from * cos(theta)) + (relativeVec * sin(theta))
    }
}
