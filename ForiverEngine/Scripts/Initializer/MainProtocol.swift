import MetalKit

protocol MainProtocol {
    init(_ view: MTKView)
    func onEveryFrame(_ view: MTKView) -> Bool  // Quit if returns false.
    func onQuit()
}
