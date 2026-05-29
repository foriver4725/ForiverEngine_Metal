import simd

extension Vector4 {
    var len: Float {
        simd_length(self)
    }

    var lenSq: Float {
        simd_length_squared(self)
    }

    var normed: Vector4 {
        simd_normalize(self)
    }
}
