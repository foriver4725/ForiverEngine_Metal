final class DebugTextDisplayer {
    static let textColor = Color.white

    struct DebugFrameTimeStatsBreakdown {
        let preFrame: DebugFrameTimeStats
        let cpu: DebugFrameTimeStats
        let gpu: DebugFrameTimeStats
        let postFrame: DebugFrameTimeStats
    }

    private struct RowData {
        var text: String
        var color: Color
    }

    private var rowDatas: [RowData] = []

    init() {
        rowDatas.reserveCapacity(64)
    }

    func updateDataAsFold(
        renderContext: RenderContext,
        textRenderer: TextRenderer
    ) {
        rowDatas.removeAll(keepingCapacity: true)
        rowDatas.append(
            RowData(
                text: "Press F1 to unfold debug info.",
                color: Self.textColor
            )
        )

        Self.applyDataToRenderer(rowDatas, textRenderer: textRenderer)
        textRenderer.updateDataAtGPU(renderContext: renderContext)
    }

    func updateDataAsUnfold(
        renderContext: RenderContext,
        textRenderer: TextRenderer,
        playerController: PlayerController,
        chunksManager: ChunksManager,
        frameTimeStatsBreakdown: DebugFrameTimeStatsBreakdown,
        lookingBlockInfo: DebugText.LookingBlockInfo
    ) {
        let frameTimePreFrame =
            frameTimeStatsBreakdown.preFrame.calculateMean()
        let frameTimeCPU =
            frameTimeStatsBreakdown.cpu.calculateMean()
        let frameTimeGPU =
            frameTimeStatsBreakdown.gpu.calculateMean()
        let frameTimePostFrame =
            frameTimeStatsBreakdown.postFrame.calculateMean()

        let frameTimeTotal =
            frameTimePreFrame
            + frameTimeCPU
            + frameTimeGPU
            + frameTimePostFrame

        let frameTimeBreakdown = DebugText.FrameTimeBreakdown(
            preFrame: frameTimePreFrame,
            cpu: frameTimeCPU,
            gpu: frameTimeGPU,
            postFrame: frameTimePostFrame,
            total: frameTimeTotal
        )

        rowDatas.removeAll(keepingCapacity: true)

        rowDatas.append(
            RowData(
                text: DebugText.frameTime(frameTimeBreakdown),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.position(playerController),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.lookingBlock(lookingBlockInfo, chunksManager),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.chunkIndex(playerController),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.chunkLocalPosition(playerController),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.drawChunksRange(chunksManager),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.collisionRange(playerController),
                color: Self.textColor
            )
        )

        rowDatas.append(
            RowData(
                text: DebugText.floorCeilHeight(
                    playerController,
                    chunksManager
                ),
                color: Self.textColor
            )
        )

        Self.applyDataToRenderer(rowDatas, textRenderer: textRenderer)
        textRenderer.updateDataAtGPU(renderContext: renderContext)
    }

    private static func applyDataToRenderer(
        _ rowDatas: [RowData],
        textRenderer: TextRenderer
    ) {
        textRenderer.data.clearAll()

        let indexOffset = Lattice2(1, 1)

        for i in rowDatas.indices {
            let rowData = rowDatas[i]
            let position = Lattice2(0, i) + indexOffset

            textRenderer.data.setTexts(
                beginPositionIndex: position,
                texts: rowData.text,
                color: rowData.color
            )
        }
    }
}
