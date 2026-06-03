import GameplayKit
import simd

enum Noise {
    private static let source = GKPerlinNoiseSource(
        frequency: 1.0,
        octaveCount: 1,
        persistence: 0.5,
        lacunarity: 2.0,
        seed: 0
    )

    private static let noise = GKNoise(source)

    @inlinable
    static func simplex1D(_ x: Float) -> Float {
        noise.value(
            atPosition: Vector2(x, 0)
        )
    }

    @inlinable
    static func simplex2D(
        _ x: Float,
        _ y: Float
    ) -> Float {
        noise.value(
            atPosition: Vector2(x, y)
        )
    }

    @inlinable
    static func simplex3D(
        _ x: Float,
        _ y: Float,
        _ z: Float
    ) -> Float {
        // GKNoiseは2Dしか取れない
        // とりあえず z を混ぜる
        noise.value(
            atPosition: Vector2(
                x + z * 17.31,
                y + z * 31.73
            )
        )
    }
}
