import Metal
import simd

struct VertexData {
    var position: Vector4
    var uv: Vector2
    var normal: Vector3
    var centerWorldPosition: Vector3
    var textureIndex: UInt32
}

struct Mesh {
    var vertices: [VertexData] = []
    var indices: [UInt32] = []

    static func createCube(
        centerWorldPosition: Vector3,
        textureIndex: UInt32
    ) -> Mesh {
        var mesh = Mesh()

        mesh.vertices = [
            // Up
            VertexData(
                position: Vector4(-0.5, 0.5, -0.5, 1),
                uv: Vector2(0.00, 0.50),
                normal: .up,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, 0.5, 0.5, 1),
                uv: Vector2(0.00, 0.25),
                normal: .up,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, -0.5, 1),
                uv: Vector2(0.25, 0.50),
                normal: .up,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, 0.5, 1),
                uv: Vector2(0.25, 0.25),
                normal: .up,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),

            // Down
            VertexData(
                position: Vector4(-0.5, -0.5, 0.5, 1),
                uv: Vector2(0.25, 0.50),
                normal: .down,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, -0.5, -0.5, 1),
                uv: Vector2(0.25, 0.25),
                normal: .down,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, -0.5, 0.5, 1),
                uv: Vector2(0.50, 0.50),
                normal: .down,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, -0.5, -0.5, 1),
                uv: Vector2(0.50, 0.25),
                normal: .down,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),

            // Right
            VertexData(
                position: Vector4(0.5, -0.5, -0.5, 1),
                uv: Vector2(0.25, 0.25),
                normal: .right,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, -0.5, 1),
                uv: Vector2(0.25, 0.00),
                normal: .right,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, -0.5, 0.5, 1),
                uv: Vector2(0.50, 0.25),
                normal: .right,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, 0.5, 1),
                uv: Vector2(0.50, 0.00),
                normal: .right,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),

            // Left
            VertexData(
                position: Vector4(-0.5, -0.5, 0.5, 1),
                uv: Vector2(0.00, 0.25),
                normal: .left,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, 0.5, 0.5, 1),
                uv: Vector2(0.00, 0.00),
                normal: .left,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, -0.5, -0.5, 1),
                uv: Vector2(0.25, 0.25),
                normal: .left,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, 0.5, -0.5, 1),
                uv: Vector2(0.25, 0.00),
                normal: .left,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),

            // Forward
            VertexData(
                position: Vector4(0.5, -0.5, 0.5, 1),
                uv: Vector2(0.75, 0.25),
                normal: .forward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, 0.5, 1),
                uv: Vector2(0.75, 0.00),
                normal: .forward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, -0.5, 0.5, 1),
                uv: Vector2(1.00, 0.25),
                normal: .forward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, 0.5, 0.5, 1),
                uv: Vector2(1.00, 0.00),
                normal: .forward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),

            // Backward
            VertexData(
                position: Vector4(-0.5, -0.5, -0.5, 1),
                uv: Vector2(0.50, 0.25),
                normal: .backward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(-0.5, 0.5, -0.5, 1),
                uv: Vector2(0.50, 0.00),
                normal: .backward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, -0.5, -0.5, 1),
                uv: Vector2(0.75, 0.25),
                normal: .backward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
            VertexData(
                position: Vector4(0.5, 0.5, -0.5, 1),
                uv: Vector2(0.75, 0.00),
                normal: .backward,
                centerWorldPosition: centerWorldPosition,
                textureIndex: textureIndex
            ),
        ]

        mesh.indices = [
            0, 1, 2, 2, 1, 3,
            4, 5, 6, 6, 5, 7,
            8, 9, 10, 10, 9, 11,
            12, 13, 14, 14, 13, 15,
            16, 17, 18, 18, 17, 19,
            20, 21, 22, 22, 21, 23,
        ]

        return mesh
    }
}

extension Mesh {
    func createMetalBuffers(device: MTLDevice) -> MeshBuffers {
        guard
            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<VertexData>.stride * vertices.count,
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
