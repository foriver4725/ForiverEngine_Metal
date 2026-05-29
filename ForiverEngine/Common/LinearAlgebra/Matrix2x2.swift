import simd

extension Matrix2x2 {
    static let identity = Matrix2x2(
        Vector2(1, 0),
        Vector2(0, 1)
    )

    static let zero = Matrix2x2(
        Vector2(0, 0),
        Vector2(0, 0)
    )

    static func scale(_ scale: Vector2) -> Matrix2x2 {
        Matrix2x2(
            Vector2(scale.x, 0),
            Vector2(0, scale.y)
        )
    }
}
