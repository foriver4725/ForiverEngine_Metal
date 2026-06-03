import Foundation

enum PlayerControl {
    static let worldEdgeMargin = Lattice2(2, 2)

    static let canMinePlaceBlockHeightRange =
        Lattice2(0, Chunk.height - 64)

    static func getBlockPosition(_ position: Float) -> Int {
        Int(round(position))
    }

    static func getBlockPosition(_ position: Vector3) -> Lattice3 {
        Lattice3(
            getBlockPosition(position.x),
            getBlockPosition(position.y),
            getBlockPosition(position.z)
        )
    }

    static func getFootPosition(
        _ worldPosition: Vector3,
        _ eyeHeight: Float
    ) -> Vector3 {
        worldPosition - Vector3.up * eyeHeight
    }

    static func getCollisionMinPosition(
        _ footWorldPosition: Vector3,
        _ collisionSize: Vector3
    ) -> Vector3 {
        Vector3(
            footWorldPosition.x - collisionSize.x * 0.5,
            footWorldPosition.y,
            footWorldPosition.z - collisionSize.z * 0.5
        )
    }

    static func isInsideWorldBounds(
        _ worldBlockPosition: Lattice3
    ) -> Bool {
        let allowedBegin = worldEdgeMargin
        let allowedEnd =
            Lattice2(
                Chunk.size * Chunk.count,
                Chunk.size * Chunk.count
            ) - worldEdgeMargin

        if !MathUtils.isInRange(
            worldBlockPosition.x,
            allowedBegin.x,
            allowedEnd.x
        ) {
            return false
        }

        if !MathUtils.isInRange(
            worldBlockPosition.z,
            allowedBegin.y,
            allowedEnd.y
        ) {
            return false
        }

        return true
    }

    struct CollisionBoundaryAsBlockInfoPerChunk {
        var isContained: Bool
        var localChunkIndex: Lattice2
        var rangeX: Lattice2
        var rangeY: Lattice2
        var rangeZ: Lattice2

        static func createUncontained(
            _ localChunkIndex: Lattice2
        ) -> CollisionBoundaryAsBlockInfoPerChunk {
            CollisionBoundaryAsBlockInfoPerChunk(
                isContained: false,
                localChunkIndex: localChunkIndex,
                rangeX: .zero,
                rangeY: .zero,
                rangeZ: .zero
            )
        }

        static func createContained(
            localChunkIndex: Lattice2,
            rangeX: Lattice2,
            rangeY: Lattice2,
            rangeZ: Lattice2
        ) -> CollisionBoundaryAsBlockInfoPerChunk {
            CollisionBoundaryAsBlockInfoPerChunk(
                isContained: true,
                localChunkIndex: localChunkIndex,
                rangeX: rangeX,
                rangeY: rangeY,
                rangeZ: rangeZ
            )
        }
    }

    static func calculateCollisionBoundaryAsBlock(
        worldPositionMin: Vector3,
        collisionSize: Vector3
    ) -> [CollisionBoundaryAsBlockInfoPerChunk] {
        typealias Info = CollisionBoundaryAsBlockInfoPerChunk

        if collisionSize.x >= 1.0 || collisionSize.z >= 1.0 {
            return [
                .createUncontained(Lattice2(0, 0)),
                .createUncontained(Lattice2(1, 0)),
                .createUncontained(Lattice2(0, 1)),
                .createUncontained(Lattice2(1, 1)),
            ]
        }

        let worldBlockPositionMin = getBlockPosition(worldPositionMin)
        let worldBlockPositionMax = getBlockPosition(
            worldPositionMin + collisionSize
        )

        let chunkIndexMin = Chunk.getIndex(worldBlockPositionMin)
        let chunkIndexMax = Chunk.getIndex(worldBlockPositionMax)

        if !MathUtils.isInRange(
            worldBlockPositionMin.x,
            0,
            Chunk.size * Chunk.count
        )
            || !MathUtils.isInRange(
                worldBlockPositionMin.y,
                0,
                Chunk.height
            )
            || !MathUtils.isInRange(
                worldBlockPositionMin.z,
                0,
                Chunk.size * Chunk.count
            )
        {
            return [
                .createUncontained(Lattice2(0, 0)),
                .createUncontained(Lattice2(1, 0)),
                .createUncontained(Lattice2(0, 1)),
                .createUncontained(Lattice2(1, 1)),
            ]
        }

        if !Chunk.isValidIndex(chunkIndexMin) {
            return [
                .createUncontained(Lattice2(0, 0)),
                .createUncontained(Lattice2(1, 0)),
                .createUncontained(Lattice2(0, 1)),
                .createUncontained(Lattice2(1, 1)),
            ]
        }

        let isValidChunkFlags = [
            true,
            MathUtils.isInRange(chunkIndexMax.x, 0, Chunk.count),
            MathUtils.isInRange(chunkIndexMax.y, 0, Chunk.count),
            Chunk.isValidIndex(chunkIndexMax),
        ]

        let isCrossingChunkX = chunkIndexMin.x < chunkIndexMax.x
        let isCrossingChunkZ = chunkIndexMin.y < chunkIndexMax.y
        let isCrossingChunkY = worldBlockPositionMax.y >= Chunk.height

        let localBlockPositionMin =
            Chunk.getLocalBlockPosition(worldBlockPositionMin)

        let localBlockPositionMax =
            Chunk.getLocalBlockPosition(worldBlockPositionMax)

        let localBlockPositionMinIn2x2Chunks = localBlockPositionMin

        let localBlockPositionMaxIn2x2Chunks =
            localBlockPositionMax
            + Lattice3(
                isCrossingChunkX ? Chunk.size : 0,
                0,
                isCrossingChunkZ ? Chunk.size : 0
            )

        var result: [Info] = []

        for i in 0..<4 {
            let localChunkIndex = Lattice2(
                (i & 0b01) != 0 ? 1 : 0,
                (i & 0b10) != 0 ? 1 : 0
            )

            if !isValidChunkFlags[i] {
                result.append(.createUncontained(localChunkIndex))
                continue
            }

            if (i == 1 && !isCrossingChunkX)
                || (i == 2 && !isCrossingChunkZ)
                || (i == 3 && !(isCrossingChunkX && isCrossingChunkZ))
            {
                result.append(.createUncontained(localChunkIndex))
                continue
            }

            let rangeX2x2 = Lattice2(
                localBlockPositionMinIn2x2Chunks.x,
                localBlockPositionMaxIn2x2Chunks.x
            )

            let rangeY2x2 = Lattice2(
                localBlockPositionMinIn2x2Chunks.y,
                localBlockPositionMaxIn2x2Chunks.y
            )

            let rangeZ2x2 = Lattice2(
                localBlockPositionMinIn2x2Chunks.z,
                localBlockPositionMaxIn2x2Chunks.z
            )

            let rangeY =
                isCrossingChunkY
                ? Lattice2(rangeY2x2.x, Chunk.height - 1)
                : Lattice2(rangeY2x2.x, rangeY2x2.y)

            let rangeX: Lattice2
            let rangeZ: Lattice2

            if i == 0 {
                rangeX = Lattice2(
                    rangeX2x2.x,
                    min(rangeX2x2.y, Chunk.size - 1)
                )
                rangeZ = Lattice2(
                    rangeZ2x2.x,
                    min(rangeZ2x2.y, Chunk.size - 1)
                )
            } else if i == 1 {
                rangeX = Lattice2(
                    max(rangeX2x2.x - Chunk.size, 0),
                    rangeX2x2.y - Chunk.size
                )
                rangeZ = Lattice2(
                    rangeZ2x2.x,
                    min(rangeZ2x2.y, Chunk.size - 1)
                )
            } else if i == 2 {
                rangeX = Lattice2(
                    rangeX2x2.x,
                    min(rangeX2x2.y, Chunk.size - 1)
                )
                rangeZ = Lattice2(
                    max(rangeZ2x2.x - Chunk.size, 0),
                    rangeZ2x2.y - Chunk.size
                )
            } else {
                rangeX = Lattice2(
                    max(rangeX2x2.x - Chunk.size, 0),
                    rangeX2x2.y - Chunk.size
                )
                rangeZ = Lattice2(
                    max(rangeZ2x2.x - Chunk.size, 0),
                    rangeZ2x2.y - Chunk.size
                )
            }

            result.append(
                .createContained(
                    localChunkIndex: localChunkIndex,
                    rangeX: rangeX,
                    rangeY: rangeY,
                    rangeZ: rangeZ
                )
            )
        }

        return result
    }

    static func findFloorHeight(
        chunks: [[Chunk]],
        footWorldPosition: Vector3,
        collisionSize: Vector3
    ) -> Int {

        let infos = calculateCollisionBoundaryAsBlock(
            worldPositionMin: getCollisionMinPosition(
                footWorldPosition,
                collisionSize
            ),
            collisionSize: collisionSize
        )

        func findFloorHeightForThisChunk(
            _ info: CollisionBoundaryAsBlockInfoPerChunk
        ) -> Int {

            if !info.isContained {
                return -1
            }

            let chunkIndex =
                Chunk.getIndex(
                    getBlockPosition(
                        getCollisionMinPosition(
                            footWorldPosition,
                            collisionSize
                        )
                    )
                )
                + info.localChunkIndex

            if !Chunk.isValidIndex(chunkIndex) {
                return -1
            }

            let chunk = chunks[chunkIndex.x][chunkIndex.y]

            var y = -1

            for x in info.rangeX.x...info.rangeX.y {
                for z in info.rangeZ.x...info.rangeZ.y {

                    let height = chunk.getFloorHeight(
                        positionXZ: Lattice2(x, z),
                        maxY: info.rangeY.x - 1
                    )

                    y = max(y, height)
                }
            }

            return y
        }

        var y = -1

        for info in infos {
            y = max(y, findFloorHeightForThisChunk(info))
        }

        return y
    }

    static func findCeilHeight(
        chunks: [[Chunk]],
        footWorldPosition: Vector3,
        collisionSize: Vector3
    ) -> Int {

        let infos = calculateCollisionBoundaryAsBlock(
            worldPositionMin: getCollisionMinPosition(
                footWorldPosition,
                collisionSize
            ),
            collisionSize: collisionSize
        )

        func findCeilHeightForThisChunk(
            _ info: CollisionBoundaryAsBlockInfoPerChunk
        ) -> Int {

            if !info.isContained {
                return Chunk.height
            }

            let chunkIndex =
                Chunk.getIndex(
                    getBlockPosition(
                        getCollisionMinPosition(
                            footWorldPosition,
                            collisionSize
                        )
                    )
                )
                + info.localChunkIndex

            if !Chunk.isValidIndex(chunkIndex) {
                return Chunk.height
            }

            let chunk = chunks[chunkIndex.x][chunkIndex.y]

            var y = Chunk.height

            for x in info.rangeX.x...info.rangeX.y {
                for z in info.rangeZ.x...info.rangeZ.y {

                    let height = chunk.getCeilHeight(
                        positionXZ: Lattice2(x, z),
                        minY: info.rangeY.y + 1
                    )

                    y = min(y, height)
                }
            }

            return y
        }

        var y = Chunk.height

        for info in infos {
            y = min(y, findCeilHeightForThisChunk(info))
        }

        return y
    }

    static func isOverlappingWithTerrain(
        chunks: [[Chunk]],
        footWorldPosition: Vector3,
        collisionSize: Vector3
    ) -> Bool {

        let infos = calculateCollisionBoundaryAsBlock(
            worldPositionMin: getCollisionMinPosition(
                footWorldPosition,
                collisionSize
            ),
            collisionSize: collisionSize
        )

        func isOverlappingForThisChunk(
            _ info: CollisionBoundaryAsBlockInfoPerChunk
        ) -> Bool {

            if !info.isContained {
                return false
            }

            let chunkIndex =
                Chunk.getIndex(
                    getBlockPosition(
                        getCollisionMinPosition(
                            footWorldPosition,
                            collisionSize
                        )
                    )
                )
                + info.localChunkIndex

            if !Chunk.isValidIndex(chunkIndex) {
                return false
            }

            let chunk = chunks[chunkIndex.x][chunkIndex.y]

            for x in info.rangeX.x...info.rangeX.y {
                for y in info.rangeY.x...info.rangeY.y {
                    for z in info.rangeZ.x...info.rangeZ.y {

                        if chunk.getBlock(
                            Lattice3(x, y, z)
                        ) != .air {
                            return true
                        }
                    }
                }
            }

            return false
        }

        for info in infos {
            if isOverlappingForThisChunk(info) {
                return true
            }
        }

        return false
    }

    static func isOverlappingWithBlock(
        chunks: [[Chunk]],
        footWorldPosition: Vector3,
        collisionSize: Vector3,
        targetWorldBlockPosition: Lattice3
    ) -> Bool {

        let collisionMinPosition =
            getCollisionMinPosition(
                footWorldPosition,
                collisionSize
            )

        let collisionMaxPosition =
            collisionMinPosition + collisionSize

        let collisionMinChunkIndex =
            Chunk.getIndex(
                getBlockPosition(collisionMinPosition)
            )

        let collisionMaxChunkIndex =
            Chunk.getIndex(
                getBlockPosition(collisionMaxPosition)
            )

        let targetChunkIndex =
            Chunk.getIndex(targetWorldBlockPosition)

        if !MathUtils.isInRange(
            targetChunkIndex.x,
            collisionMinChunkIndex.x,
            collisionMaxChunkIndex.x + 1
        ) {
            return false
        }

        if !MathUtils.isInRange(
            targetChunkIndex.y,
            collisionMinChunkIndex.y,
            collisionMaxChunkIndex.y + 1
        ) {
            return false
        }

        let overlapX =
            collisionMinPosition.x < Float(targetWorldBlockPosition.x) + 0.5
            && collisionMaxPosition.x > Float(targetWorldBlockPosition.x) - 0.5

        let overlapY =
            collisionMinPosition.y < Float(targetWorldBlockPosition.y) + 0.5
            && collisionMaxPosition.y > Float(targetWorldBlockPosition.y) - 0.5

        let overlapZ =
            collisionMinPosition.z < Float(targetWorldBlockPosition.z) + 0.5
            && collisionMaxPosition.z > Float(targetWorldBlockPosition.z) - 0.5

        return overlapX && overlapY && overlapZ
    }
}
