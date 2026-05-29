import simd

struct CameraTransform {
    var transform: Transform

    var nearClip: Float  // near > 0
    var farClip: Float  // far > near

    var isPerspective: Bool = true  // true: 透視投影, false: 平行投影
    var fov: Float  // 垂直視野角 (ラジアン)
    var aspectRatio: Float  // 幅 / 高さ

    static func perspective(
        position: Vector3,
        rotation: Quaternion,
        fov: Float,
        aspectRatio: Float,
        clipRangeZ: Vector2 = Vector2(0.1, 1000)
    ) -> CameraTransform {
        CameraTransform(
            transform: Transform(
                position: position,
                rotation: rotation,
                scale: .one
            ),
            nearClip: clipRangeZ.x,
            farClip: clipRangeZ.y,
            isPerspective: true,
            fov: fov,
            aspectRatio: aspectRatio
        )
    }

    static func orthographic(
        position: Vector3,
        rotation: Quaternion,
        clipSizeXY: Vector2,
        clipRangeZ: Vector2 = Vector2(0.1, 1000)
    ) -> CameraTransform {
        CameraTransform(
            transform: Transform(
                position: position,
                rotation: rotation,
                scale: .one
            ),
            nearClip: clipRangeZ.x,
            farClip: clipRangeZ.y,
            isPerspective: false,
            fov: atan2(clipSizeXY.y * 0.5, clipRangeZ.x) * 2.0,  // nearクリップ面で平行投影を始めると想定するので...
            aspectRatio: clipSizeXY.x / clipSizeXY.y
        )
    }

    func calculateViewMatrix() -> Matrix4x4 {
        let right = transform.right
        let up = transform.up
        let forward = transform.forward

        let rotateInversed = Matrix4x4(
            Vector4(right.x, up.x, forward.x, 0),
            Vector4(right.y, up.y, forward.y, 0),
            Vector4(right.z, up.z, forward.z, 0),
            Vector4(0, 0, 0, 1)
        )

        let translateInversed = Matrix4x4.translate(-transform.position)

        return rotateInversed * translateInversed
    }

    func calculateProjectionMatrix() -> Matrix4x4 {
        let halfFov = fov * 0.5
        let zRangeRcp = 1.0 / (farClip - nearClip)

        if isPerspective {
            let xScale = 1.0 / (aspectRatio * tan(halfFov))
            let yScale = 1.0 / tan(halfFov)
            let zScale = farClip * zRangeRcp
            let zTranslate = farClip * -nearClip * zRangeRcp

            return Matrix4x4(
                Vector4(xScale, 0, 0, 0),
                Vector4(0, yScale, 0, 0),
                Vector4(0, 0, zScale, 1),
                Vector4(0, 0, zTranslate, 0)
            )
        } else {
            // nearクリップ面で平行投影を始めると想定する
            let xScale = 1.0 / (nearClip * aspectRatio * tan(halfFov))
            let yScale = 1.0 / (nearClip * tan(halfFov))
            let zScale = zRangeRcp
            let zTranslate = -nearClip * zRangeRcp

            return Matrix4x4(
                Vector4(xScale, 0, 0, 0),
                Vector4(0, yScale, 0, 0),
                Vector4(0, 0, zScale, 0),
                Vector4(0, 0, zTranslate, 1)
            )
        }
    }

    func calculateVPMatrix() -> Matrix4x4 {
        let v = calculateViewMatrix()
        let p = calculateProjectionMatrix()

        return p * v
    }
}
