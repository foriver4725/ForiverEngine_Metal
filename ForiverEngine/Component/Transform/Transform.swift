import simd

struct Transform {
    var position: Vector3
    var rotation: Quaternion
    var scale: Vector3

    static var identity: Transform {
        Transform(position: .zero, rotation: .identity, scale: .one)
    }

    var right: Vector3 {
        rotation * Vector3.right
    }

    var up: Vector3 {
        rotation * Vector3.up
    }

    var forward: Vector3 {
        rotation * Vector3.forward
    }

    func calculateModelMatrix() -> Matrix4x4 {
        let s = Matrix4x4.scale(scale)
        let r = Matrix4x4.rotate(rotation)
        let t = Matrix4x4.translate(position)

        return t * r * s
    }

    func calculateModelMatrixInversed() -> Matrix4x4 {
        let sInv = Matrix4x4.scale(
            Vector3(1 / scale.x, 1 / scale.y, 1 / scale.z)
        )
        let rInv = Matrix4x4.rotate(rotation.conjugate)
        let tInv = Matrix4x4.translate(-position)

        return sInv * rInv * tInv
    }
}
