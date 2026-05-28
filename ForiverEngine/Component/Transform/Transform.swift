import Foundation
import simd
import Metal

struct Transform {
    var position: SIMD3<Float> = .zero
    var rotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    var scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)

    static var identity: Transform {
        Transform()
    }

    var right: SIMD3<Float> {
        rotation.act(SIMD3<Float>(1, 0, 0))
    }

    var up: SIMD3<Float> {
        rotation.act(SIMD3<Float>(0, 1, 0))
    }

    var forward: SIMD3<Float> {
        rotation.act(SIMD3<Float>(0, 0, 1))
    }

    func modelMatrix() -> simd_float4x4 {
        let s = simd_float4x4.scale(scale)
        let r = simd_float4x4(rotation)
        let t = simd_float4x4.translate(position)

        return t * r * s
    }

    func inverseModelMatrix() -> simd_float4x4 {
        modelMatrix().inverse
    }
}
