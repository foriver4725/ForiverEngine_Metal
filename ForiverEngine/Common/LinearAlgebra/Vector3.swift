import simd

extension Vector3 {
    static let zero = Vector3(0, 0, 0)
    static let one = Vector3(1, 1, 1)
    static let right = Vector3(1, 0, 0)
    static let left = Vector3(-1, 0, 0)
    static let up = Vector3(0, 1, 0)
    static let down = Vector3(0, -1, 0)
    static let forward = Vector3(0, 0, 1)
    static let backward = Vector3(0, 0, -1)

    var len: Float {
        simd_length(self)
    }

    var lenSq: Float {
        simd_length_squared(self)
    }

    var normed: Vector3 {
        simd_normalize(self)
    }
}
