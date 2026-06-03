import Metal
import MetalKit

final class OffscreenRendererBase {
    private var pipelineState: MTLRenderPipelineState!
    private var samplerState: MTLSamplerState!

    private var renderTexture: MTLTexture!
    private var depthTexture: MTLTexture?
    private var renderMeshContext: RenderMeshContext!

    private var textures: [MTLTexture] = []

    private var cbCount: Int = 0
    private var srCount: Int = 0

    func initialize(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2,
        textures sourceTextures: [MTLTexture],
        vertexFunctionName: String,
        fragmentFunctionName: String,
        useDepth: Bool = false
    ) {
        cbCount = 0
        srCount = sourceTextures.count

        renderTexture = Self.createRenderTexture(
            device: renderContext.device,
            pixelFormat: metalView.colorPixelFormat,
            width: Int(windowSize.x),
            height: Int(windowSize.y)
        )

        if useDepth {
            depthTexture = Self.createDepthTexture(
                device: renderContext.device,
                pixelFormat: metalView.depthStencilPixelFormat,
                width: Int(windowSize.x),
                height: Int(windowSize.y)
            )
        }

        pipelineState = MetalUtils.createGraphicsPipelineState(
            device: renderContext.device,
            metalView: metalView,
            vertexFunctionName: vertexFunctionName,
            fragmentFunctionName: fragmentFunctionName,
            vertexDescriptor:
                VertexDescriptorFactory.createVertexDataQuadDescriptor(),
            useDSV: false
        )

        samplerState = MetalUtils.createSamplerState(
            device: renderContext.device
        )

        let mesh = MeshQuad.createFullSized()
        let meshBuffers = mesh.createMetalBuffers(
            device: renderContext.device
        )

        renderMeshContext = RenderMeshContext(
            meshBuffersList: [meshBuffers]
        )

        // D3D12版の t0 = RT/SR に相当
        textures = [renderTexture]
        textures.append(contentsOf: sourceTextures)
    }

    func createRenderTargetContext() -> RenderTargetContext {
        let descriptor = MTLRenderPassDescriptor()

        descriptor.colorAttachments[0].texture = renderTexture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        if let depthTexture {
            descriptor.depthAttachment.texture = depthTexture
            descriptor.depthAttachment.loadAction = .clear
            descriptor.depthAttachment.storeAction = .dontCare
            descriptor.depthAttachment.clearDepth = 1.0
        }

        return RenderTargetContext(
            drawable: nil,
            renderPassDescriptor: descriptor
        )
    }

    func reUploadTexture(
        _ texture: MTLTexture,
        shaderRegister: Int
    ) {
        let index = shaderRegister

        guard index >= 0 else {
            fatalError("Invalid shader register")
        }

        while textures.count <= index {
            textures.append(renderTexture)
        }

        textures[index] = texture
    }

    func draw<
        TVertexUniforms: BitwiseCopyable,
        TFragmentUniforms: BitwiseCopyable
    >(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext,
        vertexUniforms: inout TVertexUniforms,
        fragmentUniforms: inout TFragmentUniforms
    ) {
        for meshBuffers in renderMeshContext.meshBuffersList {
            MetalUtils.draw(
                commandQueue: renderContext.commandQueue,
                renderPassDescriptor: renderTargetContext.renderPassDescriptor,
                drawable: renderTargetContext.drawable,
                pipelineState: pipelineState,
                depthState: nil,
                vertexBuffer: meshBuffers.vertexBuffer,
                indexBuffer: meshBuffers.indexBuffer,
                indexCount: meshBuffers.indexCount,
                textures: textures,
                samplerState: samplerState,
                vertexUniforms: &vertexUniforms,
                fragmentUniforms: &fragmentUniforms
            )
        }
    }

    func getRenderTexture() -> MTLTexture {
        renderTexture
    }

    private static func createRenderTexture(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int
    ) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )

        descriptor.usage = [
            .renderTarget,
            .shaderRead,
        ]

        descriptor.storageMode = .private

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Failed to create offscreen render texture")
        }

        return texture
    }

    private static func createDepthTexture(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int
    ) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )

        descriptor.usage = [.renderTarget]
        descriptor.storageMode = .private

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Failed to create offscreen depth texture")
        }

        return texture
    }
}
