import MetalKit

final class ViewDelegate: NSObject, MTKViewDelegate {
    private let main: MainProtocol!

    init(metalView: MTKView) {
        main = Main(metalView)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // The application's window is not resizable, so we don't need to handle this event.
    }

    func draw(in view: MTKView) {
        main.onEveryFrame(view)
    }

    func onQuit() {
        main.onQuit()
    }
}
