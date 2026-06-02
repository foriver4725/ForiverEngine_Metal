import simd

extension Matrix3x3 {
    static let identity = Matrix3x3(
        Vector3(1, 0, 0),
        Vector3(0, 1, 0),
        Vector3(0, 0, 1)
    )

    static let zero = Matrix3x3(
        Vector3(0, 0, 0),
        Vector3(0, 0, 0),
        Vector3(0, 0, 0)
    )

    static func scale(_ scale: Vector3) -> Matrix3x3 {
        Matrix3x3(
            Vector3(scale.x, 0, 0),
            Vector3(0, scale.y, 0),
            Vector3(0, 0, scale.z)
        )
    }
}
