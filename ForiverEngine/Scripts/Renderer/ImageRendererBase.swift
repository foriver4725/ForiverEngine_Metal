import Metal
import MetalKit

final class ImageRendererBase {
    private struct VertexUniforms: BitwiseCopyable {
        // 今回は未使用
        var dummy: UInt32 = 0
    }

    private struct FragmentUniforms: BitwiseCopyable {
        var isDrawEnabled: UInt32
    }

    private var pipelineState: MTLRenderPipelineState!
    private var samplerState: MTLSamplerState!
    private var texture: MTLTexture!
    private var renderMeshContext: RenderMeshContext!

    private var vertexUniforms = VertexUniforms()
    private var fragmentUniforms = FragmentUniforms(isDrawEnabled: 1)

    func initialize(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2,
        imageName: String,
        position: Vector2,
        size: Vector2,
        zOrder: UInt16 = 0,
        useDSV: Bool,
        useAlphaBlend: Bool,
        initDrawEnabled: Bool
    ) {
        pipelineState = MetalUtils.createGraphicsPipelineState(
            device: renderContext.device,
            metalView: metalView,
            vertexFunctionName: "QuadImage_VSMain",
            fragmentFunctionName: "QuadImage_PSMain",
            vertexDescriptor:
                VertexDescriptorFactory.createVertexDataQuadDescriptor(),
            useDSV: useDSV,
            useAlphaBlend: useAlphaBlend
        )

        samplerState = MetalUtils.createSamplerState(
            device: renderContext.device
        )

        texture = TextureLoader.load(
            device: renderContext.device,
            name: imageName,
            isSRGB: false
        )

        var mesh = MeshQuad.createFullSized()

        for i in mesh.vertices.indices {
            mesh.vertices[i].position.x *= size.x / windowSize.x
            mesh.vertices[i].position.y *= size.y / windowSize.y

            mesh.vertices[i].position.x +=
                2.0 * position.x / windowSize.x - 1.0

            mesh.vertices[i].position.y +=
                -2.0 * position.y / windowSize.y + 1.0

            mesh.vertices[i].position.z =
                Float(zOrder) / Float(UInt16.max)
        }

        let meshBuffers = mesh.createMetalBuffers(
            device: renderContext.device
        )

        renderMeshContext = RenderMeshContext(
            meshBuffersList: [meshBuffers]
        )

        fragmentUniforms.isDrawEnabled = initDrawEnabled ? 1 : 0
    }

    func getDrawEnabled() -> Bool {
        fragmentUniforms.isDrawEnabled != 0
    }

    func setDrawEnabled(_ enabled: Bool) {
        fragmentUniforms.isDrawEnabled = enabled ? 1 : 0
    }

    func reUploadTexture(
        renderContext: RenderContext,
        texture newTexture: MTLTexture
    ) {
        texture = newTexture
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext
    ) {
        guard fragmentUniforms.isDrawEnabled != 0 else {
            return
        }

        for meshBuffers in renderMeshContext.meshBuffersList {
            var vertexUniforms = self.vertexUniforms
            var fragmentUniforms = self.fragmentUniforms

            MetalUtils.draw(
                commandQueue: renderContext.commandQueue,
                renderPassDescriptor: renderTargetContext.renderPassDescriptor,
                drawable: renderTargetContext.drawable,
                pipelineState: pipelineState,
                depthState: nil,
                vertexBuffer: meshBuffers.vertexBuffer,
                indexBuffer: meshBuffers.indexBuffer,
                indexCount: meshBuffers.indexCount,
                textures: [texture],
                samplerState: samplerState,
                vertexUniforms: &vertexUniforms,
                fragmentUniforms: &fragmentUniforms
            )
        }
    }
}
