import Foundation

enum DebugText {
    struct FrameTimeBreakdown {
        var preFrame: Double
        var cpu: Double
        var gpu: Double
        var postFrame: Double
        var total: Double
    }

    struct LookingBlockInfo {
        var isLooking: Bool
        var lookingBlockWorldPosition: Lattice3
        var lookingBlockFaceNormal: Lattice3
    }

    static func frameTime(_ value: FrameTimeBreakdown) -> String {
        String(
            format:
                "Frame Time[ms] : Total=%.2f(PreFrame=%.2f,CPU=%.2f,GPU=%.2f,PostFrame=%.2f)",
            value.total,
            value.preFrame,
            value.cpu,
            value.gpu,
            value.postFrame
        )
    }

    static func position(_ playerController: PlayerController) -> String {
        let blockPosition = playerController.getFootBlockPosition()
        return "Position : \(blockPosition)"
    }

    static func lookingBlock(
        _ info: LookingBlockInfo,
        _ chunksManager: ChunksManager
    ) -> String {
        if info.isLooking {
            return
                "Looking Block : \(getBlockName(chunksManager.getBlock(info.lookingBlockWorldPosition)))(At=\(info.lookingBlockWorldPosition),Face=\(info.lookingBlockFaceNormal))"
        } else {
            return "Looking Block : None"
        }
    }

    static func chunkIndex(_ playerController: PlayerController) -> String {
        let blockPosition = playerController.getFootBlockPosition()
        let chunkIndex = Chunk.getIndex(blockPosition)

        if Chunk.isValidIndex(chunkIndex) {
            return "Chunk Index : \(chunkIndex)"
        } else {
            return "Chunk Index : Invalid"
        }
    }

    static func chunkLocalPosition(_ playerController: PlayerController)
        -> String
    {
        let blockPosition = playerController.getFootBlockPosition()
        let chunkIndex = Chunk.getIndex(blockPosition)
        let chunkLocalPosition = Chunk.getLocalBlockPosition(blockPosition)

        if Chunk.isValidIndex(chunkIndex) {
            return "Chunk Local Position : \(chunkLocalPosition)"
        } else {
            return "Chunk Local Position : Invalid"
        }
    }

    static func drawChunksRange(_ chunksManager: ChunksManager) -> String {
        let drawRangeInfo = chunksManager.getDrawRangeInfo()

        return
            "Drawing Chunks : \(drawRangeInfo.getRangeMin())-\(drawRangeInfo.getRangeMax())"
    }

    static func collisionRange(_ playerController: PlayerController) -> String {
        let position = playerController.getFootPosition()
        let minPosition = PlayerControl.getCollisionMinPosition(
            position,
            PlayerController.collisionSize
        )
        let maxPosition = minPosition + PlayerController.collisionSize

        return
            "Player Collision Range : \(PlayerControl.getBlockPosition(minPosition))-\(PlayerControl.getBlockPosition(maxPosition))"
    }

    static func floorCeilHeight(
        _ playerController: PlayerController,
        _ chunksManager: ChunksManager
    ) -> String {
        let chunks = chunksManager.getChunks()
        let floorHeight = playerController.findFloorHeight(chunks)
        let ceilHeight = playerController.findCeilHeight(chunks)

        let floorHeightText =
            floorHeight >= 0 ? String(floorHeight) : "None"

        let ceilHeightText =
            ceilHeight <= Chunk.height - 1 ? String(ceilHeight) : "None"

        return "Floor&Ceil Height : (\(floorHeightText),\(ceilHeightText))"
    }
}
