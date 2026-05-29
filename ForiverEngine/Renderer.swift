import Darwin
import Metal
import MetalKit
import simd

struct Uniforms {
    var matrixMVP: Matrix4x4
    var matrixMIT: Matrix4x4
}

struct FragmentUniforms {
    var selectingBlockWorldPosition: SIMD3<Int32>
    var isSelectingBlock: UInt32
    var selectColor: Vector4

    var directionalLightDirection: Vector3
    var _padding0: Float = 0

    var directionalLightColor: Vector4
    var ambientLightColor: Vector4
}

final class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState

    private let meshBuffers: MeshBuffers
    private let textureArray: MTLTexture
    private let samplerState: MTLSamplerState

    private var cubeTransform: Transform = Transform(
        position: .zero,
        rotation: Quaternion(
            angle: Float.pi * 3,
            axis: Vector3(1, 5, 1.5).normed
        ),
        scale: .one
    )
    private var cameraTransform: CameraTransform = .perspective(
        position: Vector3(0, 0, -5),
        rotation: .identity,
        fov: Float.pi / 3,
        aspectRatio: 800.0 / 450.0
    )

    init(metalView: MTKView) {
        guard let device = metalView.device else {
            fatalError("Device is nil")
        }

        self.device = device

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }
        self.commandQueue = commandQueue

        guard let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "vertex_main"),
            let fragmentFunction = library.makeFunction(name: "fragment_main")
        else {
            fatalError("Failed to load shader functions")
        }

        let vertexDescriptor = MTLVertexDescriptor()

        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = MemoryLayout<VertexData>.offset(
            of: \.position
        )!
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<VertexData>.offset(
            of: \.uv
        )!
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset = MemoryLayout<VertexData>.offset(
            of: \.normal
        )!
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].offset = MemoryLayout<VertexData>.offset(
            of: \.centerWorldPosition
        )!
        vertexDescriptor.attributes[3].bufferIndex = 0

        vertexDescriptor.attributes[4].format = .uint
        vertexDescriptor.attributes[4].offset = MemoryLayout<VertexData>.offset(
            of: \.textureIndex
        )!
        vertexDescriptor.attributes[4].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<VertexData>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        descriptor.depthAttachmentPixelFormat =
            metalView.depthStencilPixelFormat

        do {
            self.pipelineState = try device.makeRenderPipelineState(
                descriptor: descriptor
            )
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true

        guard
            let depthState = device.makeDepthStencilState(
                descriptor: depthDescriptor
            )
        else {
            fatalError("Failed to create depth state")
        }
        self.depthState = depthState

        //TODO: fix textureIndex as the textureArray load error is fixed
        let mesh = Mesh.createCube(
            centerWorldPosition: .zero,
            textureIndex: 2
        )
        self.meshBuffers = mesh.createMetalBuffers(device: device)

        self.textureArray = Renderer.createTextureArray(device)
        self.samplerState = Renderer.createSamplerState(device)

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    private static func createTextureArray(_ device: MTLDevice) -> MTLTexture {
        let loader = MTKTextureLoader(device: device)

        let names = [
            //            "air_invalid", //TODO: Cannot load somewhat
            "dirt_sand",
            "grass_stone",
        ]

        let sourceTextures: [MTLTexture] = names.map { name in
            do {
                return try loader.newTexture(
                    name: name,
                    scaleFactor: 1.0,
                    bundle: .main,
                    options: [.SRGB: false]
                )
            } catch {
                fatalError("Failed to load texture: \(name), \(error)")
            }
        }

        guard let first = sourceTextures.first else {
            fatalError("Texture array is empty")
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: first.pixelFormat,
            width: first.width,
            height: first.height,
            mipmapped: false
        )

        descriptor.textureType = .type2DArray
        descriptor.arrayLength = sourceTextures.count
        descriptor.usage = [.shaderRead]

        guard let textureArray = device.makeTexture(descriptor: descriptor)
        else {
            fatalError("Failed to create texture array")
        }

        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let blit = commandBuffer.makeBlitCommandEncoder()!

        for (slice, texture) in sourceTextures.enumerated() {
            blit.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(
                    width: texture.width,
                    height: texture.height,
                    depth: 1
                ),
                to: textureArray,
                destinationSlice: slice,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
        }

        blit.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureArray
    }

    private static func createSamplerState(_ device: MTLDevice)
        -> MTLSamplerState
    {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat

        guard let sampler = device.makeSamplerState(descriptor: descriptor)
        else {
            fatalError("Failed to create sampler state")
        }

        return sampler
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
            )
        else {
            return
        }

        let deltaTime: Float = 1.0 / 60.0

        cubeTransform.rotation =
            Quaternion(
                angle: Float.pi * deltaTime,
                axis: .up
            )
            * cubeTransform.rotation

        var uniforms = Uniforms(
            matrixMVP: cameraTransform.calculateVPMatrix()
                * cubeTransform.calculateModelMatrix(),
            matrixMIT: cubeTransform.calculateModelMatrixInversed().transpose
        )

        var fragmentUniforms = FragmentUniforms(
            selectingBlockWorldPosition: SIMD3<Int32>(0, 0, 0),
            isSelectingBlock: 0,
            selectColor: Vector4(1, 1, 1, 0.35),

            directionalLightDirection: Vector3(0, -1, 0),
            directionalLightColor: Vector4(1, 1, 1, 1),
            ambientLightColor: Vector4(0.4, 0.4, 0.4, 1)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)

        encoder.setVertexBuffer(meshBuffers.vertexBuffer, offset: 0, index: 0)

        // vertex shader: [[buffer(1)]]
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: 1
        )

        // fragment shader: [[buffer(0)]]
        encoder.setFragmentBytes(
            &fragmentUniforms,
            length: MemoryLayout<FragmentUniforms>.stride,
            index: 0
        )

        // fragment shader: [[texture(0)]], [[sampler(0)]]
        encoder.setFragmentTexture(textureArray, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)

        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: meshBuffers.indexCount,
            indexType: .uint32,
            indexBuffer: meshBuffers.indexBuffer,
            indexBufferOffset: 0
        )

        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
