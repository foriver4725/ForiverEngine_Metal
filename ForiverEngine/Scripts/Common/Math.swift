import simd

enum MathUtils {
    @inlinable
    static func isInRange<T: Comparable>(
        _ value: T,
        _ begin: T,
        _ end: T
    ) -> Bool {
        begin <= value && value < end
    }

    @inlinable
    static func clamp(
        _ value: Float,
        _ min: Float,
        _ max: Float
    ) -> Float {
        simd_clamp(value, min, max)
    }
}
