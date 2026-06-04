import Foundation
import simd

extension Lattice2 {
    func toString() -> String {
        "(\(x),\(y))"
    }
}

extension Lattice3 {
    func toString() -> String {
        "(\(x),\(y),\(z))"
    }
}

extension Lattice4 {
    func toString() -> String {
        "(\(x),\(y),\(z),\(w))"
    }
}

extension Vector2 {
    func toString() -> String {
        String(
            format: "(%.2f,%.2f)",
            x,
            y
        )
    }
}

extension Vector3 {
    func toString() -> String {
        String(
            format: "(%.2f,%.2f,%.2f)",
            x,
            y,
            z
        )
    }
}

extension Vector4 {
    func toString() -> String {
        String(
            format: "(%.2f,%.2f,%.2f,%.2f)",
            x,
            y,
            z,
            w
        )
    }
}

extension Matrix2x2 {
    func toString() -> String {
        String(
            format:
                "[[%.2f,%.2f],[%.2f,%.2f]]",
            [0][0],
            [1][0],
            [0][1],
            [1][1]
        )
    }
}

extension Matrix3x3 {
    func toString() -> String {
        String(
            format:
                "[[%.2f,%.2f,%.2f],[%.2f,%.2f,%.2f],[%.2f,%.2f,%.2f]]",
            [0][0],
            [1][0],
            [2][0],
            [0][1],
            [1][1],
            [2][1],
            [0][2],
            [1][2],
            [2][2]
        )
    }
}

extension Matrix4x4 {
    func toString() -> String {
        String(
            format:
                "[[%.2f,%.2f,%.2f,%.2f],[%.2f,%.2f,%.2f,%.2f],[%.2f,%.2f,%.2f,%.2f],[%.2f,%.2f,%.2f,%.2f]]",
            [0][0],
            [1][0],
            [2][0],
            [3][0],
            [0][1],
            [1][1],
            [2][1],
            [3][1],
            [0][2],
            [1][2],
            [2][2],
            [3][2],
            [0][3],
            [1][3],
            [2][3],
            [3][3]
        )
    }
}

extension Quaternion {
    func toString() -> String {
        vector.toString()
    }
}
