import Metal

enum VertexDescriptorFactory {
    static func createVertexDataDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()

        descriptor.attributes[0].format = .float4
        descriptor.attributes[0].offset =
            MemoryLayout<VertexData>.offset(of: \.position)!
        descriptor.attributes[0].bufferIndex = 0

        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].offset =
            MemoryLayout<VertexData>.offset(of: \.uv)!
        descriptor.attributes[1].bufferIndex = 0

        descriptor.attributes[2].format = .float3
        descriptor.attributes[2].offset =
            MemoryLayout<VertexData>.offset(of: \.normal)!
        descriptor.attributes[2].bufferIndex = 0

        descriptor.attributes[3].format = .float3
        descriptor.attributes[3].offset =
            MemoryLayout<VertexData>.offset(of: \.centerWorldPosition)!
        descriptor.attributes[3].bufferIndex = 0

        descriptor.attributes[4].format = .uint
        descriptor.attributes[4].offset =
            MemoryLayout<VertexData>.offset(of: \.textureIndex)!
        descriptor.attributes[4].bufferIndex = 0

        descriptor.layouts[0].stride =
            MemoryLayout<VertexData>.stride
        descriptor.layouts[0].stepFunction = .perVertex

        return descriptor
    }

    static func createVertexDataQuadDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()

        descriptor.attributes[0].format = .float4
        descriptor.attributes[0].offset =
            MemoryLayout<VertexDataQuad>.offset(of: \.position)!
        descriptor.attributes[0].bufferIndex = 0

        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].offset =
            MemoryLayout<VertexDataQuad>.offset(of: \.uv)!
        descriptor.attributes[1].bufferIndex = 0

        descriptor.layouts[0].stride =
            MemoryLayout<VertexDataQuad>.stride
        descriptor.layouts[0].stepFunction = .perVertex

        return descriptor
    }
}
