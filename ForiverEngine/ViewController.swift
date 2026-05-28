import Cocoa
import Metal
import MetalKit

final class ViewController: NSViewController {
    private var metalView: MTKView!
    private var renderer: Renderer!

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 450))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float

        view.addSubview(metalView)

        renderer = Renderer(metalView: metalView)
        metalView.delegate = renderer
    }
}
