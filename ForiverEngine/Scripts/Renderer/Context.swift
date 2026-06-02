import Metal
import MetalKit

// レンダリングで使うもの
struct RenderContext {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
}

// 何をレンダリングするか
struct RenderMeshContext {
    let meshBuffersList: [MeshBuffers]
}

// どこにレンダリングするか
struct RenderTargetContext {
    let drawable: CAMetalDrawable?
    let renderPassDescriptor: MTLRenderPassDescriptor
}
