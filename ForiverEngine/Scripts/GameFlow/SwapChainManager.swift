import Metal
import MetalKit

final class SwapChainManager {
    private weak var metalView: MTKView?

    init(metalView: MTKView) {
        self.metalView = metalView
    }

    func createCurrentRenderTargetContext() -> RenderTargetContext? {
        guard
            let metalView,
            let renderPassDescriptor = metalView.currentRenderPassDescriptor
        else {
            return nil
        }

        return RenderTargetContext(
            drawable: metalView.currentDrawable,
            renderPassDescriptor: renderPassDescriptor
        )
    }

    func present() {
        // MetalUtils.draw 側で commandBuffer.present(drawable) しているなら不要
        // D3D12版との対応用に残すだけ
    }
}
