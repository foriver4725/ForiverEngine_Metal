import simd
import Metal

struct VertexDataQuad {
    var position: SIMD4<Float>
    var uv: SIMD2<Float>
}

struct MeshQuad {
    var vertices: [VertexDataQuad]
    var indices: [UInt32]

    static func createFullSized() -> MeshQuad {
        MeshQuad(
            vertices: [
                VertexDataQuad(position: SIMD4<Float>(-1, -1, 0, 1), uv: SIMD2<Float>(0, 1)),
                VertexDataQuad(position: SIMD4<Float>(-1,  1, 0, 1), uv: SIMD2<Float>(0, 0)),
                VertexDataQuad(position: SIMD4<Float>( 1, -1, 0, 1), uv: SIMD2<Float>(1, 1)),
                VertexDataQuad(position: SIMD4<Float>( 1,  1, 0, 1), uv: SIMD2<Float>(1, 0)),
            ],
            indices: [
                0, 1, 2,
                2, 1, 3
            ]
        )
    }
}

extension MeshQuad {
    func createMetalBuffers(device: MTLDevice) -> MeshBuffers {
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<VertexDataQuad>.stride * vertices.count,
            options: []
        ) else {
            fatalError("Failed to create vertex buffer")
        }

        guard let indexBuffer = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt32>.stride * indices.count,
            options: []
        ) else {
            fatalError("Failed to create index buffer")
        }

        return MeshBuffers(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: indices.count
        )
    }
}
