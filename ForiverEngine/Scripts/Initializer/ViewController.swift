import Cocoa
import MetalKit

final class ViewController: NSViewController {
    private var metalView: MTKView!
    private var delegate: ViewDelegate!

    override func loadView() {
        self.view = NSView(frame: WindowHelper.windowRect)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }

        let view = View(frame: view.bounds, device: device)
        view.autoresizingMask = [.width, .height]
        // Since we draw via post-process, this value is not used. So set temporary to black.
        view.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1
        )
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond = 60

        self.view.addSubview(view)

        delegate = ViewDelegate(metalView: view)
        view.delegate = delegate

        // Initialize the inputs.
        view.initKeyTable()

        metalView = view
    }

    func onQuit() {
        delegate.onQuit()
    }
}
