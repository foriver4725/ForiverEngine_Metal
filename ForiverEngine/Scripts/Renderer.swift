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
        rotation: Quaternion.fromAxisAngle(
            axis: Vector3(1, 5, 1.5).normed,
            angleRad: Float.pi * 3
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
        let standardObjects = MetalUtils.createStandardObjects(metalView: metalView)
        self.device = standardObjects.device
        self.commandQueue = standardObjects.commandQueue

        let vertexDescriptor = VertexDescriptorFactory.createVertexDataDescriptor()

        self.pipelineState = MetalUtils.createGraphicsPipelineState(
            device: device,
            metalView: metalView,
            vertexFunctionName: "vertex_main",
            fragmentFunctionName: "fragment_main",
            vertexDescriptor: vertexDescriptor,
            useDSV: true
        )

        self.depthState = MetalUtils.createDepthStencilState(device: device)

        self.samplerState = MetalUtils.createSamplerState(device: device)

        self.textureArray = MetalUtils.loadTexture(
            device: device,
            names: [
                "dirt_sand",
                "grass_stone",
            ],
            isSRGB: false
        )

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
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
        let deltaTime: Float = 1.0 / 60.0

        cubeTransform.rotation =
            Quaternion.fromAxisAngle(
                axis: .up,
                angleRad: Float.pi * deltaTime
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

        MetalUtils.drawIndexed(
            view: view,
            commandQueue: commandQueue,
            pipelineState: pipelineState,
            depthState: depthState,
            meshBuffers: meshBuffers,
            textureArray: textureArray,
            samplerState: samplerState,
            uniforms: &uniforms,
            fragmentUniforms: &fragmentUniforms
        )
    }
}
