import Cocoa
import Metal
import MetalKit
import simd

final class Main: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderContext: RenderContext

    private let swapChainManager: SwapChainManager

    private var worldName: String

    private var playerExistingChunkIndex: TrackedValue<Lattice2>
    private var chunksManager: ChunksManager
    private var playerController: PlayerController

    private var terrainRenderer: TerrainRenderer
    private var postProcessRenderer: PostProcessRenderer
    private var textRenderer: TextRenderer
    private var pointerImageRenderer: PointerImageRenderer
    private var itemSlotManager: ItemSlotManager

    private var frameTimeStatsPreFrame = DebugFrameTimeStats(recordCount: 16)
    private var frameTimeStatsCPU = DebugFrameTimeStats(recordCount: 16)
    private var frameTimeStatsGPU = DebugFrameTimeStats(recordCount: 16)
    private var frameTimeStatsPostFrame = DebugFrameTimeStats(recordCount: 16)

    private var debugTextDisplayer = DebugTextDisplayer()
    private var isDebugFolded = true

    private var mineCooldownTimer = Timer(
        durationSeconds: PlayerController.mineCooldownSeconds
    )

    private var placeCooldownTimer = Timer(
        durationSeconds: PlayerController.placeCooldownSeconds
    )

    private var lastTime: Double = CACurrentMediaTime()

    init(metalView: MTKView) {
        let standardObjects =
            MetalUtils.createStandardObjects(metalView: metalView)

        self.device = standardObjects.device
        self.commandQueue = standardObjects.commandQueue

        self.renderContext = RenderContext(
            device: standardObjects.device,
            commandQueue: standardObjects.commandQueue
        )

        self.swapChainManager = SwapChainManager(metalView: metalView)

        let windowSize = Lattice2(
            Int(metalView.drawableSize.width),
            Int(metalView.drawableSize.height)
        )

        self.worldName = WorldDataSaveLoadManager.loadWorldName()

        var playerTransformBinary = Data()
        var terrainBinary = Data()

        if WorldDataSaveLoadManager.exists(worldName),
            let worldDataBinary = WorldDataSaveLoadManager.load(
                worldName: worldName
            ),
            let split = WorldDataSaveLoadManager.splitWorldDataBinaries(
                combinedBinary: worldDataBinary
            )
        {
            playerTransformBinary = split.playerTransformBinary
            terrainBinary = split.terrainBinary
        }

        let playerInitChunkIndex = Lattice2(
            Chunk.count / 2,
            Chunk.count / 2
        )

        self.playerExistingChunkIndex =
            TrackedValue(playerInitChunkIndex)

        self.chunksManager = ChunksManager(
            playerFirstExistingChunkIndex: playerExistingChunkIndex.getValue()
        )

        if !terrainBinary.isEmpty {
            chunksManager.deserializeAndUpdateChunks(
                terrainBinary,
                device: device
            )
        }

        chunksManager.updateDrawChunks(
            playerExistingChunkIndex: playerExistingChunkIndex.getValue(),
            parallelIfGenerate: false,
            deviceIfGenerate: device
        )

        self.playerController = PlayerController(
            windowSize: windowSize,
            initChunkIndex: playerExistingChunkIndex.getValue(),
            chunks: chunksManager.getChunks()
        )

        if !playerTransformBinary.isEmpty {
            playerController.deserializeTransformAndTeleport(
                playerTransformBinary
            )
        }

        self.terrainRenderer = TerrainRenderer(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        terrainRenderer.onPlayerCameraMatrixChanged(
            playerController.calculateVPMatrix()
        )

        self.postProcessRenderer = PostProcessRenderer(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        self.textRenderer = TextRenderer(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        self.pointerImageRenderer = PointerImageRenderer(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        self.itemSlotManager = ItemSlotManager(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        super.init()

        mineCooldownTimer.countToFinishImmediately()
        placeCooldownTimer.countToFinishImmediately()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 必要ならPostProcess/Text/Cameraのリサイズ処理をここに追加
    }

    func draw(in view: MTKView) {
        let timeBeforeFrame = CACurrentMediaTime()

        let deltaSeconds = Float(timeBeforeFrame - lastTime)
        lastTime = timeBeforeFrame

        let timeBeforeCPU = CACurrentMediaTime()
        frameTimeStatsPreFrame.record(timeBeforeCPU - timeBeforeFrame)

        // TODO: InputManagerを作ったらここを置き換え
        let playerInputs = PlayerController.Inputs(
            move: .zero,
            look: .zero,
            dashPressed: false,
            jumpPressed: false
        )

        playerController.onEveryFrame(
            chunks: chunksManager.getChunks(),
            inputs: playerInputs,
            deltaSeconds: deltaSeconds
        )

        terrainRenderer.onPlayerCameraMatrixChanged(
            playerController.calculateVPMatrix()
        )

        let looking = playerController.pickLookingBlock(
            chunks: chunksManager.getChunks()
        )

        if looking.faceNormal == .zero {
            terrainRenderer.setSelectingBlock(
                position: .zero,
                enabled: false
            )
        } else {
            terrainRenderer.setSelectingBlock(
                position: looking.blockPosition,
                enabled: true
            )

            mineCooldownTimer.onEveryFrame(deltaSeconds)
            placeCooldownTimer.onEveryFrame(deltaSeconds)

            // TODO: 左クリック/右クリック入力を接続
            // playerController.tryMineBlock(...)
            // playerController.tryPlaceBlock(...)
        }

        playerExistingChunkIndex.setValue(
            Chunk.getIndex(playerController.getFootBlockPosition())
        )

        if playerExistingChunkIndex.dropDirty() {
            chunksManager.updateDrawChunks(
                playerExistingChunkIndex: playerExistingChunkIndex.getValue(),
                parallelIfGenerate: true,
                deviceIfGenerate: device
            )
        }

        chunksManager.markChunkForSaving(
            playerExistingChunkIndex.getValue()
        )

        let frameBreakdown =
            DebugTextDisplayer.DebugFrameTimeStatsBreakdown(
                preFrame: frameTimeStatsPreFrame,
                cpu: frameTimeStatsCPU,
                gpu: frameTimeStatsGPU,
                postFrame: frameTimeStatsPostFrame
            )

        let lookingBlockInfo = DebugText.LookingBlockInfo(
            isLooking: looking.faceNormal != .zero,
            lookingBlockWorldPosition: looking.blockPosition,
            lookingBlockFaceNormal: looking.faceNormal
        )

        if isDebugFolded {
            debugTextDisplayer.updateDataAsFold(
                renderContext: renderContext,
                textRenderer: textRenderer
            )
        } else {
            debugTextDisplayer.updateDataAsUnfold(
                renderContext: renderContext,
                textRenderer: textRenderer,
                playerController: playerController,
                chunksManager: chunksManager,
                frameTimeStatsBreakdown: frameBreakdown,
                lookingBlockInfo: lookingBlockInfo
            )
        }

        let timeAfterCPU = CACurrentMediaTime()
        frameTimeStatsCPU.record(timeAfterCPU - timeBeforeCPU)

        guard
            let currentRenderTargetContext =
                swapChainManager.createCurrentRenderTargetContext()
        else {
            return
        }

        let postProcessRenderTargetContext =
            postProcessRenderer.createRenderTargetContext()

        let textRenderTargetContext =
            textRenderer.createRenderTargetContext()

        let terrainRenderMeshContext =
            chunksManager.packToRenderMeshContext()

        terrainRenderer.draw(
            renderContext: renderContext,
            renderTargetContext: postProcessRenderTargetContext,
            renderMeshContext: terrainRenderMeshContext
        )

        postProcessRenderer.draw(
            renderContext: renderContext,
            renderTargetContext: textRenderTargetContext
        )

        pointerImageRenderer.draw(
            renderContext: renderContext,
            renderTargetContext: textRenderTargetContext
        )

        itemSlotManager.draw(
            renderContext: renderContext,
            renderTargetContext: textRenderTargetContext
        )

        textRenderer.draw(
            renderContext: renderContext,
            renderTargetContext: currentRenderTargetContext
        )

        let timeAfterGPU = CACurrentMediaTime()
        frameTimeStatsGPU.record(timeAfterGPU - timeAfterCPU)

        let timeAfterFrame = CACurrentMediaTime()
        frameTimeStatsPostFrame.record(timeAfterFrame - timeAfterGPU)
    }

    func saveWorld() {
        let playerBinary = playerController.serializeTransform()
        let terrainBinary = chunksManager.serializeSaveChunks()

        let worldBinary =
            WorldDataSaveLoadManager.combineWorldDataBinaries(
                playerTransformBinary: playerBinary,
                terrainBinary: terrainBinary
            )

        _ = WorldDataSaveLoadManager.save(
            worldName: worldName,
            binary: worldBinary
        )
    }
}
