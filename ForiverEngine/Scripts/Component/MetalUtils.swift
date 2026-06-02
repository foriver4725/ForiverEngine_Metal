import Metal
import MetalKit

enum MetalUtils {
    static func createStandardObjects(
        metalView: MTKView
    ) -> (device: MTLDevice, commandQueue: MTLCommandQueue) {
        guard let device = metalView.device else {
            fatalError("Device is nil")
        }

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }

        return (device, commandQueue)
    }

    static func createGraphicsPipelineState(
        device: MTLDevice,
        metalView: MTKView,
        vertexFunctionName: String,
        fragmentFunctionName: String,
        vertexDescriptor: MTLVertexDescriptor,
        useDSV: Bool
    ) -> MTLRenderPipelineState {
        guard let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: vertexFunctionName),
            let fragmentFunction = library.makeFunction(
                name: fragmentFunctionName
            )
        else {
            fatalError("Failed to load shader functions")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        if useDSV {
            descriptor.depthAttachmentPixelFormat =
                metalView.depthStencilPixelFormat
        }

        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    static func createDepthStencilState(
        device: MTLDevice,
        depthCompareFunction: MTLCompareFunction = .less,
        isDepthWriteEnabled: Bool = true
    ) -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = depthCompareFunction
        descriptor.isDepthWriteEnabled = isDepthWriteEnabled

        guard
            let depthState = device.makeDepthStencilState(
                descriptor: descriptor
            )
        else {
            fatalError("Failed to create depth state")
        }

        return depthState
    }

    static func createSamplerState(
        device: MTLDevice
    ) -> MTLSamplerState {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat

        guard let sampler = device.makeSamplerState(descriptor: descriptor)
        else {
            fatalError("Failed to create sampler state")
        }

        return sampler
    }

    static func loadTexture(
        device: MTLDevice,
        names: [String],
        isSRGB: Bool = false
    ) -> MTLTexture {
        guard !names.isEmpty else {
            fatalError("Texture paths are empty")
        }

        if names.count == 1 {
            guard
                let texture = TextureLoader.load(
                    device: device,
                    name: names[0],
                    isSRGB: isSRGB
                )
            else {
                fatalError("Failed to load texture")
            }

            return texture
        }

        guard
            let textureArray = TextureLoader.loadAsArray(
                device: device,
                names: names,
                isSRGB: isSRGB
            )
        else {
            fatalError("Failed to load texture array")
        }

        return textureArray
    }

    static func draw<
        TVertexUniforms: BitwiseCopyable,
        TFragmentUniforms: BitwiseCopyable
    >(
        commandQueue: MTLCommandQueue,
        renderPassDescriptor: MTLRenderPassDescriptor,
        drawable: CAMetalDrawable?,
        pipelineState: MTLRenderPipelineState,
        depthState: MTLDepthStencilState?,
        vertexBuffer: MTLBuffer,
        indexBuffer: MTLBuffer,
        indexCount: Int,
        textures: [MTLTexture],
        samplerState: MTLSamplerState?,
        vertexUniforms: inout TVertexUniforms,
        fragmentUniforms: inout TFragmentUniforms
    ) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
            )
        else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)

        if let depthState {
            encoder.setDepthStencilState(depthState)
        }

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        withUnsafeBytes(of: &vertexUniforms) {
            encoder.setVertexBytes(
                $0.baseAddress!,
                length: $0.count,
                index: 1
            )
        }

        withUnsafeBytes(of: &fragmentUniforms) {
            encoder.setFragmentBytes(
                $0.baseAddress!,
                length: $0.count,
                index: 0
            )
        }

        for (index, texture) in textures.enumerated() {
            encoder.setFragmentTexture(texture, index: index)
        }

        if let samplerState {
            encoder.setFragmentSamplerState(samplerState, index: 0)
        }

        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )

        encoder.endEncoding()

        if let drawable {
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}
