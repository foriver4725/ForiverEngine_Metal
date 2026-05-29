import simd

extension Quaternion {
    static let zero = Quaternion(ix: 0, iy: 0, iz: 0, r: 0)
    static let identity = Quaternion(ix: 0, iy: 0, iz: 0, r: 1)

    static func fromAxisAngle(axis: Vector3, angleRad: Float) -> Quaternion {
        Quaternion(angle: angleRad, axis: axis.normed)
    }

    static func vectorToVector(from: Vector3, to: Vector3) -> Quaternion {
        Quaternion(from: from.normed, to: to.normed)
    }

    static func lerp(from: Quaternion, to: Quaternion, t: Float) -> Quaternion {
        let _from = from.vector
        let _to = to.vector
        let _t = Clamp(t, 0.0, 1.0)

        return Quaternion(
            ix: _from.x + (_to.x - _from.x) * _t,
            iy: _from.y + (_to.y - _from.y) * _t,
            iz: _from.z + (_to.z - _from.z) * _t,
            r: _from.w + (_to.w - _from.w) * _t
        ).normalized
    }

    static func slerp(from: Quaternion, to: Quaternion, t: Float) -> Quaternion
    {
        let _from = from.vector
        let _to = to.vector
        let _t = Clamp(t, 0.0, 1.0)

        var dot =
            _from.x * _to.x + _from.y * _to.y + _from.z * _to.z + _from.w
            * _to.w
        var to1 = _to
        if dot < 0.0 {
            dot = -dot
            to1 = -_to
        }
        if dot > 0.9995 {
            return lerp(from: from, to: Quaternion(vector: to1), t: _t)
        }
        let theta_0 = acos(dot)
        let theta = theta_0 * _t
        let sin_theta = sin(theta)
        let sin_theta_0 = sin(theta_0)
        let s0 = cos(theta) - dot * sin_theta / sin_theta_0
        let s1 = sin_theta / sin_theta_0
        return Quaternion(
            ix: (_from.x * s0) + (to1.x * s1),
            iy: (_from.y * s0) + (to1.y * s1),
            iz: (_from.z * s0) + (to1.z * s1),
            r: (_from.w * s0) + (to1.w * s1)
        ).normalized
    }

    static func * (lhs: Quaternion, rhs: Vector3) -> Vector3 {
        lhs.act(rhs)
    }
}
