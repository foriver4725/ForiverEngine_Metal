import simd

extension Matrix4x4 {
    static let identity = Matrix4x4(
        Vector4(1, 0, 0, 0),
        Vector4(0, 1, 0, 0),
        Vector4(0, 0, 1, 0),
        Vector4(0, 0, 0, 1)
    )

    static let zero = Matrix4x4(
        Vector4(0, 0, 0, 0),
        Vector4(0, 0, 0, 0),
        Vector4(0, 0, 0, 0),
        Vector4(0, 0, 0, 0)
    )

    static func scale(_ scale: Vector3) -> Matrix4x4 {
        Matrix4x4(
            Vector4(scale.x, 0, 0, 0),
            Vector4(0, scale.y, 0, 0),
            Vector4(0, 0, scale.z, 0),
            Vector4(0, 0, 0, 1)
        )
    }

    static func rotate(_ quaternion: Quaternion) -> Matrix4x4 {
        Matrix4x4(quaternion)
    }

    static func translate(_ translation: Vector3) -> Matrix4x4 {
        Matrix4x4(
            Vector4(1, 0, 0, 0),
            Vector4(0, 1, 0, 0),
            Vector4(0, 0, 1, 0),
            Vector4(translation.x, translation.y, translation.z, 1)
        )
    }
}
