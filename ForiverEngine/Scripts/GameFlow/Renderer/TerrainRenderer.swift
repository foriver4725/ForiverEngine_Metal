import Metal
import MetalKit
import simd

final class TerrainRenderer {
    static let skyColor = MTLClearColor(
        red: 60.0 / 255.0,
        green: 150.0 / 255.0,
        blue: 210.0 / 255.0,
        alpha: 1.0
    )

    static let blockTextureNames = [
        "air_invalid",
        "grass_stone",
        "dirt_sand",
    ]

    private struct CBData0: BitwiseCopyable {
        var matrixMVP: Matrix4x4
        var matrixMIT: Matrix4x4
    }

    struct CBData1: BitwiseCopyable {
        var selectingBlockWorldPosition: SIMD3<Int32>
        var isSelectingBlock: UInt32
        var selectColor: Vector4

        var directionalLightDirection: Vector3
        var pad0: Float = 0

        var directionalLightColor: Vector4
        var ambientLightColor: Vector4
    }

    private var pipelineState: MTLRenderPipelineState!
    private var depthState: MTLDepthStencilState!
    private var samplerState: MTLSamplerState!
    private var textureArray: MTLTexture!

    private var matrixMCached: Matrix4x4

    private var cbData0: CBData0
    private var cbData1: CBData1

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) {
        let transform = Transform.identity

        self.matrixMCached = transform.calculateModelMatrix()

        self.cbData0 = CBData0(
            matrixMVP: .identity,
            matrixMIT:
                transform
                .calculateModelMatrixInversed()
                .transpose
        )

        self.cbData1 = CBData1(
            selectingBlockWorldPosition: SIMD3<Int32>(0, 0, 0),
            isSelectingBlock: 0,
            selectColor: Vector4(1, 1, 0, 48.0 / 255.0),

            directionalLightDirection: Vector3(1, -1, 1).normed,
            directionalLightColor: Vector4(1.2, 1.2, 1.2, 1),
            ambientLightColor: Vector4(0.5, 0.5, 0.5, 1)
        )

        self.pipelineState = MetalUtils.createGraphicsPipelineState(
            device: renderContext.device,
            metalView: metalView,
            vertexFunctionName: "VSMain",
            fragmentFunctionName: "PSMain",
            vertexDescriptor:
                VertexDescriptorFactory
                .createVertexDataDescriptor(),
            useDSV: true
        )

        self.depthState = MetalUtils.createDepthStencilState(
            device: renderContext.device
        )

        self.samplerState = MetalUtils.createSamplerState(
            device: renderContext.device
        )

        self.textureArray = TextureLoader.loadAsArray(
            device: renderContext.device,
            names: Self.blockTextureNames,
            isSRGB: false
        )
    }

    func onPlayerCameraMatrixChanged(
        _ playerCameraVPMatrix: Matrix4x4
    ) {
        cbData0.matrixMVP = playerCameraVPMatrix * matrixMCached
    }

    func getCBData1() -> CBData1 {
        cbData1
    }

    func setCBData1(_ value: CBData1) {
        cbData1 = value
    }

    func setSelectingBlock(
        position: SIMD3<Int32>,
        enabled: Bool
    ) {
        cbData1.selectingBlockWorldPosition = position
        cbData1.isSelectingBlock = enabled ? 1 : 0
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext,
        renderMeshContext: RenderMeshContext
    ) {
        for meshBuffers in renderMeshContext.meshBuffersList {
            var vertexUniforms = cbData0
            var fragmentUniforms = cbData1

            MetalUtils.draw(
                commandQueue: renderContext.commandQueue,
                renderPassDescriptor: renderTargetContext.renderPassDescriptor,
                drawable: renderTargetContext.drawable,
                pipelineState: pipelineState,
                depthState: depthState,
                vertexBuffer: meshBuffers.vertexBuffer,
                indexBuffer: meshBuffers.indexBuffer,
                indexCount: meshBuffers.indexCount,
                textures: [textureArray],
                samplerState: samplerState,
                vertexUniforms: &vertexUniforms,
                fragmentUniforms: &fragmentUniforms
            )
        }
    }
}
