import simd

@inlinable
func Clamp(
    _ value: Float,
    _ min: Float,
    _ max: Float
) -> Float {
    simd_clamp(value, min, max)
}
