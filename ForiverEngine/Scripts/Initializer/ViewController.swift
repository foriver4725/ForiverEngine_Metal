import Cocoa
import MetalKit

final class ViewController: NSViewController {
    private var metalView: MTKView!
    private var main: Main!

    override func loadView() {
        self.view = NSView(frame: WindowHelper.windowRect)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        metalView.clearColor = TerrainRenderer.skyColor
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.preferredFramesPerSecond = 60

        view.addSubview(metalView)

        main = Main(metalView: metalView)
        metalView.delegate = main
    }

    func saveWorld() {
        main?.saveWorld()
    }
}
