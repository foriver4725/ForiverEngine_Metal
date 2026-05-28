import simd

struct CameraTransform {
    var transform: Transform

    var nearClip: Float
    var farClip: Float

    var isPerspective: Bool = true
    var fov: Float
    var aspectRatio: Float

    static func perspective(
        position: SIMD3<Float>,
        rotation: simd_quatf,
        fov: Float,
        aspectRatio: Float,
        near: Float = 0.1,
        far: Float = 1000
    ) -> CameraTransform {
        CameraTransform(
            transform: Transform(
                position: position,
                rotation: rotation,
                scale: SIMD3<Float>(1, 1, 1)
            ),
            nearClip: near,
            farClip: far,
            isPerspective: true,
            fov: fov,
            aspectRatio: aspectRatio
        )
    }

    func viewMatrix() -> simd_float4x4 {
        transform.modelMatrix().inverse
    }

    func projectionMatrix() -> simd_float4x4 {
        let halfFov = fov * 0.5
        let zRangeRcp = 1.0 / (farClip - nearClip)

        if isPerspective {
            let xScale = 1.0 / (aspectRatio * tan(halfFov))
            let yScale = 1.0 / tan(halfFov)
            let zScale = farClip * zRangeRcp
            let zTranslate = -farClip * nearClip * zRangeRcp

            return simd_float4x4(columns: (
                SIMD4<Float>(xScale, 0, 0, 0),
                SIMD4<Float>(0, yScale, 0, 0),
                SIMD4<Float>(0, 0, zScale, 1),
                SIMD4<Float>(0, 0, zTranslate, 0)
            ))
        } else {
            fatalError("Orthographic is not implemented yet")
        }
    }

    func vpMatrix() -> simd_float4x4 {
        projectionMatrix() * viewMatrix()
    }
}
