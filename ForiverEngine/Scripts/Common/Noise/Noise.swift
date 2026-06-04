enum Noise {
    static func simplex1D(_ x: Float) -> Float {
        FE_Noise_Simplex1D(x)
    }

    static func simplex2D(_ x: Float, _ y: Float) -> Float {
        FE_Noise_Simplex2D(x, y)
    }

    static func simplex3D(_ x: Float, _ y: Float, _ z: Float) -> Float {
        FE_Noise_Simplex3D(x, y, z)
    }
}
