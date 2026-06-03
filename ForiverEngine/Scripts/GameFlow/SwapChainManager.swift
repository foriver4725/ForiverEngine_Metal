import Metal
import MetalKit

final class SwapChainManager {
    private weak var metalView: MTKView?

    init(metalView: MTKView) {
        self.metalView = metalView
    }

    func createCurrentRenderTargetContext(
        useDepth: Bool
    ) -> RenderTargetContext? {
        guard
            let metalView,
            let drawable = metalView.currentDrawable,
            let descriptor = metalView.currentRenderPassDescriptor
        else {
            return nil
        }

        if !useDepth {
            descriptor.depthAttachment.texture = nil
            descriptor.depthAttachment.loadAction = .dontCare
            descriptor.depthAttachment.storeAction = .dontCare
        }

        return RenderTargetContext(
            drawable: drawable,
            renderPassDescriptor: descriptor
        )
    }

    func present() {
        // MetalUtils.draw 側で commandBuffer.present(drawable) しているなら不要
        // D3D12版との対応用に残すだけ
    }
}
