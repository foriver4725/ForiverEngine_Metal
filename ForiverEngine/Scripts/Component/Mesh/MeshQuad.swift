import Metal
import simd

struct MeshQuad: MeshBase {
    typealias VertexDataType = VertexDataQuad

    var vertices: [VertexDataQuad]
    var indices: [UInt32]

    static func createFullSized() -> MeshQuad {
        MeshQuad(
            vertices: [
                VertexDataQuad(
                    position: Vector4(-1, -1, 0, 1),
                    uv: Vector2(0, 1)
                ),
                VertexDataQuad(
                    position: Vector4(-1, 1, 0, 1),
                    uv: Vector2(0, 0)
                ),
                VertexDataQuad(
                    position: Vector4(1, -1, 0, 1),
                    uv: Vector2(1, 1)
                ),
                VertexDataQuad(
                    position: Vector4(1, 1, 0, 1),
                    uv: Vector2(1, 0)
                ),
            ],
            indices: [
                0, 1, 2,
                2, 1, 3,
            ]
        )
    }
}
