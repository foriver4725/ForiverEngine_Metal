import Metal

protocol MeshBase {
    associatedtype VertexDataType: BitwiseCopyable

    var vertices: [VertexDataType] { get }
    var indices: [UInt32] { get }
}
extension MeshBase {
    func createMetalBuffers(device: MTLDevice) -> MeshBuffers {
        guard !vertices.isEmpty else {
            fatalError("Vertices is empty")
        }

        guard !indices.isEmpty else {
            fatalError("Indices is empty")
        }

        let vertexBuffer = vertices.withUnsafeBytes { rawBufferPointer in
            device.makeBuffer(
                bytes: rawBufferPointer.baseAddress!,
                length: rawBufferPointer.count,
                options: []
            )
        }

        guard let vertexBuffer else {
            fatalError("Failed to create vertex buffer")
        }

        let indexBuffer = indices.withUnsafeBytes { rawBufferPointer in
            device.makeBuffer(
                bytes: rawBufferPointer.baseAddress!,
                length: rawBufferPointer.count,
                options: []
            )
        }

        guard let indexBuffer else {
            fatalError("Failed to create index buffer")
        }

        return MeshBuffers(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: indices.count
        )
    }
}
