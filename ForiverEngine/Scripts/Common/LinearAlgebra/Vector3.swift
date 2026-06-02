import simd

extension Vector3 {
    static let zero = Vector3(0, 0, 0)
    static let one = Vector3(1, 1, 1)
    static let right = Vector3(1, 0, 0)
    static let left = Vector3(-1, 0, 0)
    static let up = Vector3(0, 1, 0)
    static let down = Vector3(0, -1, 0)
    static let forward = Vector3(0, 0, 1)
    static let backward = Vector3(0, 0, -1)

    var len: Float {
        simd_length(self)
    }

    var lenSq: Float {
        simd_length_squared(self)
    }

    var normed: Vector3 {
        simd_normalize(self)
    }

    static func dot(_ lhs: Vector3, _ rhs: Vector3) -> Float {
        simd_dot(lhs, rhs)
    }

    static func cross(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        Vector3(
            lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.x * rhs.y - lhs.y * rhs.x
        )
    }

    static func lerp(_ from: Vector3, _ to: Vector3, _ t: Float) -> Vector3 {
        let _t = Clamp(t, 0.0, 1.0)
        return from + (to - from) * _t
    }

    static func slerp(_ from: Vector3, _ to: Vector3, _ t: Float) -> Vector3 {
        let _t = Clamp(t, 0.0, 1.0)
        let dot = dot(from.normed, to.normed)
        let theta = acos(Clamp(dot, -1.0, 1.0)) * _t
        let relativeVec = (to - from * dot).normed
        return (from * cos(theta)) + (relativeVec * sin(theta))
    }

    static func reflect(_ vector: Vector3, _ normal: Vector3) -> Vector3 {
        let _normal = normal.normed
        let dot = dot(vector, _normal)
        return vector - 2.0 * dot * _normal
    }
}
