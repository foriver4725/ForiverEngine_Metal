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
        // Since we draw via post-process, this value is not used. So set temporary to black.
        metalView.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1
        )
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
