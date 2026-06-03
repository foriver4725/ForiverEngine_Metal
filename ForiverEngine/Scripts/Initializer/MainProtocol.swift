import MetalKit

protocol MainProtocol {
    init(_ view: MTKView)
    func onEveryFrame(_ view: MTKView)
    func onQuit()
}
