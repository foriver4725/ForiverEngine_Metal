import Metal
import MetalKit
import simd

final class PostProcessRenderer {
    private struct CBData0: BitwiseCopyable {
        var windowSize: SIMD2<UInt32>
        var limitLuminance: Float
        var aaPower: Float
    }

    private let base = OffscreenRendererBase()

    private var cbData0: CBData0

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) {
        self.cbData0 = CBData0(
            windowSize: SIMD2<UInt32>(
                UInt32(windowSize.x),
                UInt32(windowSize.y)
            ),
            limitLuminance: 0.5,
            aaPower: 8.0
        )

        base.initialize(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize,
            textures: [],
            vertexFunctionName: "PP_VSMain",
            fragmentFunctionName: "PP_PSMain",
            useDepth: true
        )
    }

    func createRenderTargetContext() -> RenderTargetContext {
        base.createRenderTargetContext()
    }

    func getRenderTexture() -> MTLTexture {
        base.getRenderTexture()
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext
    ) {
        var vertexUniforms: UInt32 = 0
        var fragmentUniforms = cbData0

        base.draw(
            renderContext: renderContext,
            renderTargetContext: renderTargetContext,
            vertexUniforms: &vertexUniforms,
            fragmentUniforms: &fragmentUniforms
        )
    }
}
