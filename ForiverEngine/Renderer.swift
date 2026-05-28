import Metal
import MetalKit

struct Vertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
}

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let texture: MTLTexture
    private let samplerState: MTLSamplerState
    
    private let vertexCount: Int
    private let indexCount: Int
    
    init(metalView: MTKView) {
        guard let device = metalView.device else {
            fatalError("Device is nil")
        }

        self.device = device

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }

        self.commandQueue = commandQueue

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }

        guard let vertexFunction = library.makeFunction(name: "vertex_main") else {
            fatalError("Failed to load vertex_main")
        }

        guard let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            fatalError("Failed to load fragment_main")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
        
        let mesh = Renderer.createSquareMesh(device)
        self.vertexBuffer = mesh.vertexBuffer
        self.indexBuffer = mesh.indexBuffer
        self.vertexCount = mesh.vertexCount
        self.indexCount = mesh.indexCount
        
        self.texture = Renderer.createTexture(device)
        self.samplerState = Renderer.createSamplerState(device)
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    private static func createSquareMesh(_ device: MTLDevice)
    -> (vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, vertexCount: Int, indexCount: Int)
    {
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-0.5, -0.5), uv: SIMD2<Float>(0.0, 1.0)),
            Vertex(position: SIMD2<Float>( 0.5, -0.5), uv: SIMD2<Float>(1.0, 1.0)),
            Vertex(position: SIMD2<Float>( 0.5,  0.5), uv: SIMD2<Float>(1.0, 0.0)),
            Vertex(position: SIMD2<Float>(-0.5,  0.5), uv: SIMD2<Float>(0.0, 0.0))
        ]

        let indices: [UInt16] = [
            0, 1, 2,
            0, 2, 3
        ]

        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<Vertex>.stride * vertices.count,
            options: []
        ) else {
            fatalError("Failed to create vertex buffer")
        }

        guard let indexBuffer = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt16>.stride * indices.count,
            options: []
        ) else {
            fatalError("Failed to create index buffer")
        }

        return (
            vertexBuffer,
            indexBuffer,
            vertices.count,
            indices.count
        )
    }
    
    private static func createTexture(_ device: MTLDevice) -> MTLTexture {
        let loader = MTKTextureLoader(device: device)
        
        do {
           return try loader.newTexture(
               name: "Texture1",
               scaleFactor: 1.0,
               bundle: .main,
               options: [
                   .SRGB: false,
                   .origin: MTKTextureLoader.Origin.topLeft
               ]
           )
        } catch {
           fatalError("Failed to load texture: \(error)")
        }
    }
    
    private static func createSamplerState(_ device: MTLDevice) -> MTLSamplerState
    {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            fatalError("Failed to create sampler state")
        }

        return samplerState
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        ) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
