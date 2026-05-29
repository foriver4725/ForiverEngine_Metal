import simd

extension Quaternion {
    static let zero = Quaternion(ix: 0, iy: 0, iz: 0, r: 0)
    static let identity = Quaternion(ix: 0, iy: 0, iz: 0, r: 1)

    static func * (lhs: Quaternion, rhs: Vector3) -> Vector3 {
        lhs.act(rhs)
    }
}
