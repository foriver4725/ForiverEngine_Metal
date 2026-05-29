import Metal
import simd

struct VertexDataQuad {
    var position: Vector4
    var uv: Vector2
}

struct MeshQuad {
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

extension MeshQuad {
    func createMetalBuffers(device: MTLDevice) -> MeshBuffers {
        guard
            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<VertexDataQuad>.stride * vertices.count,
                options: []
            )
        else {
            fatalError("Failed to create vertex buffer")
        }

        guard
            let indexBuffer = device.makeBuffer(
                bytes: indices,
                length: MemoryLayout<UInt32>.stride * indices.count,
                options: []
            )
        else {
            fatalError("Failed to create index buffer")
        }

        return MeshBuffers(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: indices.count
        )
    }
}
