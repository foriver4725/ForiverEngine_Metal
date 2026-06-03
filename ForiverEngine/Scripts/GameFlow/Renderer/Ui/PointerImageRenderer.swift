import Metal
import MetalKit

final class PointerImageRenderer {
    private let base = ImageRendererBase()

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) {
        base.initialize(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize,
            imageName: "pointer",
            position: windowSize / 2,
            size: Vector2(24, 24)
        )
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext
    ) {
        base.draw(
            renderContext: renderContext,
            renderTargetContext: renderTargetContext
        )
    }
}
