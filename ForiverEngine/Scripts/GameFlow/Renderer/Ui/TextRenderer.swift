import Metal
import MetalKit
import simd

final class TextRenderer {
    private struct CBData0: BitwiseCopyable {
        var fontTextureSize: SIMD2<UInt32>
        var textUiDataSize: SIMD2<UInt32>
        var invalidFontTextureIndex: UInt32
        var fontTextureTextLength: UInt32
    }

    private let base = OffscreenRendererBase()

    var data: TextUiData

    private var cbData0: CBData0

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) {
        self.data = TextUiData.createEmpty(
            dataSize: Lattice2(
                Int(windowSize.x) / TextUiData.fontTextureTextLength,
                Int(windowSize.y) / TextUiData.fontTextureTextLength
            )
        )

        let fontTexture = TextureLoader.load(
            device: renderContext.device,
            name: "font",
            isSRGB: false
        )!

        let textDataTexture = data.createTexture(
            device: renderContext.device
        )

        self.cbData0 = CBData0(
            fontTextureSize: SIMD2<UInt32>(
                UInt32(fontTexture.width),
                UInt32(fontTexture.height)
            ),
            textUiDataSize: SIMD2<UInt32>(
                UInt32(textDataTexture.width),
                UInt32(textDataTexture.height)
            ),
            invalidFontTextureIndex: UInt32(Text.invalidFontTextureIndex),
            fontTextureTextLength: UInt32(TextUiData.fontTextureTextLength)
        )

        base.initialize(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize,
            textures: [
                fontTexture,  // t1 相当
                textDataTexture,  // t2 相当
            ],
            vertexFunctionName: "Text_VSMain",
            fragmentFunctionName: "Text_PSMain"
        )
    }

    func updateDataAtGPU(
        renderContext: RenderContext
    ) {
        let textDataTexture = data.createTexture(
            device: renderContext.device
        )

        // OffscreenRendererBase は textures[0] = renderTexture
        // sourceTextures[0] が textures[1] = t1
        // sourceTextures[1] が textures[2] = t2
        base.reUploadTexture(
            textDataTexture,
            shaderRegister: 2
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
