import MetalKit

final class Main: MainProtocol {
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

    init(_ view: MTKView) {
        let standardObjects =
            MetalUtils.createStandardObjects(metalView: view)

        self.device = standardObjects.device
        self.commandQueue = standardObjects.commandQueue

        self.renderContext = RenderContext(
            device: standardObjects.device,
            commandQueue: standardObjects.commandQueue
        )

        self.swapChainManager = SwapChainManager(metalView: view)

        let windowSize = Lattice2(
            Int(view.drawableSize.width),
            Int(view.drawableSize.height)
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
            metalView: view,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        terrainRenderer.onPlayerCameraMatrixChanged(
            playerController.calculateVPMatrix()
        )

        self.postProcessRenderer = PostProcessRenderer(
            renderContext: renderContext,
            metalView: view,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y)),
            clearColor: TerrainRenderer.skyColor,
            useDepth: true
        )

        self.textRenderer = TextRenderer(
            renderContext: renderContext,
            metalView: view,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y)),
            clearColor: TerrainRenderer.skyColor,
            useDepth: false
        )

        self.pointerImageRenderer = PointerImageRenderer(
            renderContext: renderContext,
            metalView: view,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        self.itemSlotManager = ItemSlotManager(
            renderContext: renderContext,
            metalView: view,
            windowSize: Vector2(Float(windowSize.x), Float(windowSize.y))
        )

        mineCooldownTimer.countToFinishImmediately()
        placeCooldownTimer.countToFinishImmediately()
    }

    func onEveryFrame(_ view: MTKView) -> Bool {
        let timeBeforeFrame = CACurrentMediaTime()

        let deltaSeconds = Float(timeBeforeFrame - lastTime)
        lastTime = timeBeforeFrame

        let timeBeforeCPU = CACurrentMediaTime()
        frameTimeStatsPreFrame.record((timeBeforeCPU - timeBeforeFrame) * 1000)

        if InputHelper.getKeyInfo(.escape).pressedNow {
            return false
        }

        // TODO: InputManagerを作ったらここを置き換え
        let playerInputs = PlayerController.Inputs(
            move: InputHelper.getAsAxis2D(
                upKey: .w,
                downKey: .s,
                leftKey: .a,
                rightKey: .d
            ),
            look: InputHelper.getMouseDelta(),
            dashPressed: InputHelper.getKeyInfo(.lShift).pressed,
            jumpPressed: InputHelper.getKeyInfo(.space).pressed,
        )

        playerController.onEveryFrame(
            chunks: chunksManager.getChunks(),
            inputs: playerInputs,
            deltaSeconds: deltaSeconds
        )

        terrainRenderer.onPlayerCameraMatrixChanged(
            playerController.calculateVPMatrix()
        )

        let itemSlotSelectInputs = ItemSlotManager.SelectInputs(
            select1: InputHelper.getKeyInfo(.n1).pressedNow,
            select2: InputHelper.getKeyInfo(.n2).pressedNow,
            select3: InputHelper.getKeyInfo(.n3).pressedNow,
            select4: InputHelper.getKeyInfo(.n4).pressedNow,
            select5: InputHelper.getKeyInfo(.n5).pressedNow,
            select6: InputHelper.getKeyInfo(.n6).pressedNow,

            selectLeft: InputHelper.getMouseWheelDelta() > 0.1,
            selectRight: InputHelper.getMouseWheelDelta() < -0.1,
        )
        itemSlotManager.updateSelectingSlotByInput(
            renderContext: renderContext,
            inputs: itemSlotSelectInputs
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

            if InputHelper.getKeyInfo(.mMouse).pressedNow {
                let lookingBlock = chunksManager.getBlock(looking.blockPosition)
                for i in 0..<ItemSlotManager.slotCount {
                    if ItemSlotManager.slotItems[i] == lookingBlock {
                        itemSlotManager.updateSelectingSlot(
                            renderContext: renderContext,
                            newIndex: i
                        )
                        break
                    }
                }
            }

            mineCooldownTimer.onEveryFrame(deltaSeconds)
            placeCooldownTimer.onEveryFrame(deltaSeconds)

            if mineCooldownTimer.isFinished()
                && InputHelper.getKeyInfo(.lMouse).pressed
            {
                mineCooldownTimer.reset()
                _ = playerController.tryMineBlock(
                    chunksManager: chunksManager,
                    worldBlockPosition: looking.blockPosition,
                    device: device
                )
            }

            if placeCooldownTimer.isFinished()
                && InputHelper.getKeyInfo(.rMouse).pressed
            {
                placeCooldownTimer.reset()

                let placeBlock = ItemSlotManager.slotItems[
                    itemSlotManager.getSelectingIndex()
                ]
                if placeBlock != .invalid {
                    _ = playerController.tryPlaceBlock(
                        chunksManager: chunksManager,
                        worldBlockPosition: looking.blockPosition
                            + looking.faceNormal,
                        block: placeBlock,
                        device: device
                    )
                }
            }

            if InputHelper.getKeyInfo(.lMouse).releasedNow {
                mineCooldownTimer.countToFinishImmediately()
            }
            if InputHelper.getKeyInfo(.rMouse).releasedNow {
                placeCooldownTimer.countToFinishImmediately()
            }
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

        if InputHelper.getKeyInfo(.f1).pressedNow {
            isDebugFolded = !isDebugFolded
        }

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

        // Reset the input flags.
        InputHelper.onEveryFrame()

        let timeAfterCPU = CACurrentMediaTime()
        frameTimeStatsCPU.record((timeAfterCPU - timeBeforeCPU) * 1000)

        guard
            // don't use depth because this is used only for text rendering (= post-processing)
            let currentRenderTargetContext =
                swapChainManager.createCurrentRenderTargetContext(
                    useDepth: false
                )
        else {
            return false
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

        // ここから先は、textRenderTargetContext に重ね描きするので clear しない
        textRenderTargetContext.renderPassDescriptor.colorAttachments[0]
            .loadAction = .load

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
        frameTimeStatsGPU.record((timeAfterGPU - timeAfterCPU) * 1000)

        let timeAfterFrame = CACurrentMediaTime()
        frameTimeStatsPostFrame.record((timeAfterFrame - timeAfterGPU) * 1000)

        return true
    }

    func onQuit() {
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
