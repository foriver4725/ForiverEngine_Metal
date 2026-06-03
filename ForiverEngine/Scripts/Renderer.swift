import Darwin
import Metal
import MetalKit
import simd

struct Uniforms: BitwiseCopyable {
    var matrixMVP: Matrix4x4
    var matrixMIT: Matrix4x4
}

struct FragmentUniforms: BitwiseCopyable {
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
        let standardObjects =
            MetalUtils.createStandardObjects(metalView: metalView)

        self.device = standardObjects.device
        self.commandQueue = standardObjects.commandQueue

        self.pipelineState = MetalUtils.createGraphicsPipelineState(
            device: device,
            metalView: metalView,
            vertexFunctionName: "Basic_VSMain",
            fragmentFunctionName: "Basic_PSMain",
            vertexDescriptor:
                VertexDescriptorFactory.createVertexDataDescriptor(),
            useDSV: true
        )

        self.depthState = MetalUtils.createDepthStencilState(device: device)

        self.samplerState = MetalUtils.createSamplerState(device: device)

        self.textureArray = TextureLoader.loadAsArray(
            device: device,
            names: [
                "air_invalid",
                "dirt_sand",
                "grass_stone",
            ],
            isSRGB: false
        )!

        let mesh = Mesh.createCube(
            centerWorldPosition: .zero,
            textureIndex: 4
        )

        self.meshBuffers = mesh.createMetalBuffers(device: device)

        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        cameraTransform = .perspective(
            position: Vector3(0, 0, -5),
            rotation: .identity,
            fov: Float.pi / 3,
            aspectRatio: Float(size.width / size.height)
        )
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return
        }

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

        MetalUtils.draw(
            commandQueue: commandQueue,
            renderPassDescriptor: renderPassDescriptor,
            drawable: drawable,
            pipelineState: pipelineState,
            depthState: depthState,
            vertexBuffer: meshBuffers.vertexBuffer,
            indexBuffer: meshBuffers.indexBuffer,
            indexCount: meshBuffers.indexCount,
            textures: [textureArray],
            samplerState: samplerState,
            vertexUniforms: &uniforms,
            fragmentUniforms: &fragmentUniforms
        )
    }
}
