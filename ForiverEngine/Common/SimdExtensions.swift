import simd
import Darwin

extension simd_float4x4 {
    static func translate(_ v: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(v.x, v.y, v.z, 1)
        ))
    }

    static func scale(_ v: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(columns: (
            SIMD4<Float>(v.x, 0, 0, 0),
            SIMD4<Float>(0, v.y, 0, 0),
            SIMD4<Float>(0, 0, v.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }

    static func rotateX(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle)
        let s = sin(angle)

        return simd_float4x4(columns: (
            SIMD4<Float>(1, 0,  0, 0),
            SIMD4<Float>(0, c,  s, 0),
            SIMD4<Float>(0, -s, c, 0),
            SIMD4<Float>(0, 0,  0, 1)
        ))
    }

    static func rotateY(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle)
        let s = sin(angle)

        return simd_float4x4(columns: (
            SIMD4<Float>( c, 0, -s, 0),
            SIMD4<Float>( 0, 1,  0, 0),
            SIMD4<Float>( s, 0,  c, 0),
            SIMD4<Float>( 0, 0,  0, 1)
        ))
    }
}
