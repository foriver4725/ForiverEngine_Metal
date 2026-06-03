import Foundation
import Metal

final class PlayerController {
    static let collisionSize = Vector3(0.5, 1.8, 0.5)
    static let cameraFovV: Float = 60.0 * degToRad
    static let gravityScale: Float = 1.2
    static let mass: Float = 60.0
    static let speedH: Float = 3.0
    static let dashSpeedH: Float = 6.0
    static let lookInputMultiplier: Float = 0.02
    static let lookInputLengthMax: Float = 50.0
    static let lookSensitivityH: Float = 180.0
    static let lookSensitivityV: Float = 180.0
    static let lookPitchMax: Float = 89.9 * degToRad
    static let minVelocityV: Float = -100.0
    static let jumpHeight: Float = 1.4
    static let eyeHeight: Float = 1.6

    static let findSpawnPointMaxAttempts = 1024

    static let groundedCheckOffset: Float = 0.01
    static let ceilingCheckOffset: Float = 0.01
    static let overlapCheckOffset: Float = 0.001

    static let reachDistance: Float = 5.0
    static let reachDetectStep: Float = 0.1

    static let mineCooldownSeconds: Float = 0.2
    static let placeCooldownSeconds: Float = 0.2

    struct Inputs {
        var move: Vector2
        var look: Vector2
        var dashPressed: Bool
        var jumpPressed: Bool
    }

    private var transform: CameraTransform
    private var velocityV: Float = 0

    private var yaw: Float = 0
    private var pitch: Float = 0

    init(
        windowSize: Lattice2,
        initChunkIndex: Lattice2,
        chunks: [[Chunk]]
    ) {
        var spawnWorldBlockPosition = Lattice3.zero
        var found = false

        for i in 0..<Self.findSpawnPointMaxAttempts {
            let x =
                initChunkIndex.x * Chunk.size
                + Chunk.size / 2
                + (i & 0x0f)

            let z =
                initChunkIndex.y * Chunk.size
                + Chunk.size / 2
                + ((i & 0xf0) >> 4)

            let y = PlayerControl.findFloorHeight(
                chunks: chunks,
                footWorldPosition: Vector3(
                    Float(x),
                    Float(Chunk.height - 1),
                    Float(z)
                ),
                collisionSize: Self.collisionSize
            )

            if y < 0 {
                continue
            }

            spawnWorldBlockPosition = Lattice3(x, y + 1, z)
            found = true
            break
        }

        if !found {
            print("Failed to find player spawn point")
        }

        let aspectRatio =
            Float(windowSize.x) / Float(windowSize.y)

        self.transform = CameraTransform.perspective(
            position:
                Vector3(spawnWorldBlockPosition)
                + Vector3.up * Self.eyeHeight,
            rotation: .identity,
            fov: Self.cameraFovV,
            aspectRatio: aspectRatio
        )

        self.velocityV = 0
    }

    func getRealGravity() -> Float {
        g * Self.gravityScale
    }

    func getFootPosition() -> Vector3 {
        PlayerControl.getFootPosition(
            transform.position,
            Self.eyeHeight
        )
    }

    func getFootBlockPosition() -> Lattice3 {
        PlayerControl.getBlockPosition(getFootPosition())
    }

    func findFloorHeight(_ chunks: [[Chunk]]) -> Int {
        PlayerControl.findFloorHeight(
            chunks: chunks,
            footWorldPosition:
                getFootPosition()
                + Vector3.up * Self.groundedCheckOffset,
            collisionSize: Self.collisionSize
        )
    }

    func findCeilHeight(_ chunks: [[Chunk]]) -> Int {
        PlayerControl.findCeilHeight(
            chunks: chunks,
            footWorldPosition:
                getFootPosition()
                + Vector3.up * -Self.ceilingCheckOffset,
            collisionSize: Self.collisionSize
        )
    }

    func isOverlappingWithTerrain(_ chunks: [[Chunk]]) -> Bool {
        PlayerControl.isOverlappingWithTerrain(
            chunks: chunks,
            footWorldPosition:
                getFootPosition()
                + Vector3.up * Self.overlapCheckOffset,
            collisionSize: Self.collisionSize
        )
    }

    func isOverlappingWithBlock(
        _ chunks: [[Chunk]],
        _ blockPosition: Lattice3
    ) -> Bool {
        PlayerControl.isOverlappingWithBlock(
            chunks: chunks,
            footWorldPosition:
                getFootPosition()
                + Vector3.up * Self.overlapCheckOffset,
            collisionSize: Self.collisionSize,
            targetWorldBlockPosition: blockPosition
        )
    }

    func calculateVPMatrix() -> Matrix4x4 {
        transform.calculateVPMatrix()
    }

    func onEveryFrame(
        chunks: [[Chunk]],
        inputs: Inputs,
        deltaSeconds: Float
    ) {
        do {
            var lookInput = inputs.look * Self.lookInputMultiplier

            if lookInput.lenSq
                > Self.lookInputLengthMax * Self.lookInputLengthMax
            {
                lookInput =
                    lookInput.normed * Self.lookInputLengthMax
            }

            yaw +=
                lookInput.x
                * Self.lookSensitivityH
                * degToRad
                * deltaSeconds

            pitch +=
                lookInput.y
                * Self.lookSensitivityV
                * degToRad
                * deltaSeconds

            pitch = min(
                max(pitch, -Self.lookPitchMax),
                Self.lookPitchMax
            )

            transform.rotation =
                Self.calculateRotationFromYawPitch(
                    yaw: yaw,
                    pitch: pitch
                )
        }

        do {
            let positionBeforeMove = transform.position

            do {
                let floorY = findFloorHeight(chunks)
                let ceilY = findCeilHeight(chunks)

                velocityV -= getRealGravity() * deltaSeconds
                velocityV = max(velocityV, Self.minVelocityV)

                if abs(velocityV) > 0.01 {
                    transform.position +=
                        Vector3.up * (velocityV * deltaSeconds)
                }

                let isGrounded =
                    floorY >= 0
                    ? getFootPosition().y
                        <= Float(floorY) + 0.5 + Self.groundedCheckOffset
                    : false

                let isCeiling =
                    ceilY <= Chunk.height - 1
                    ? getFootPosition().y + Self.collisionSize.y
                        >= Float(ceilY) - 0.5 - Self.ceilingCheckOffset
                    : false

                if isGrounded {
                    let minY = Float(floorY) + 0.5 + Self.eyeHeight

                    if transform.position.y < minY {
                        transform.position.y = minY
                    }

                    if velocityV < 0 {
                        velocityV = 0
                    }
                } else if isCeiling {
                    let maxY =
                        Float(ceilY)
                        - 0.5
                        - Self.collisionSize.y
                        + Self.eyeHeight

                    if transform.position.y > maxY {
                        transform.position.y = maxY
                    }

                    if velocityV > 0 {
                        velocityV = 0
                    }
                }

                if isGrounded && inputs.jumpPressed {
                    velocityV += sqrt(
                        2.0 * getRealGravity() * Self.jumpHeight
                    )
                }
            }

            do {
                let canDash = inputs.move.y > 0.5

                let speed =
                    canDash && inputs.dashPressed
                    ? Self.dashSpeedH
                    : Self.speedH

                var moveDirection =
                    transform.rotation
                    * Vector3(inputs.move.x, 0, inputs.move.y)

                moveDirection.y = 0
                moveDirection = moveDirection.normed

                do {
                    let positionBeforeMoveH = transform.position

                    transform.position +=
                        Vector3.right
                        * (moveDirection.x * speed * deltaSeconds)

                    if isOverlappingWithTerrain(chunks) {
                        transform.position = positionBeforeMoveH
                    }
                }

                do {
                    let positionBeforeMoveH = transform.position

                    transform.position +=
                        Vector3.forward
                        * (moveDirection.z * speed * deltaSeconds)

                    if isOverlappingWithTerrain(chunks) {
                        transform.position = positionBeforeMoveH
                    }
                }
            }

            if !PlayerControl.isInsideWorldBounds(
                getFootBlockPosition()
            ) {
                transform.position = positionBeforeMove
            }
        }
    }

    func pickLookingBlock(
        chunks: [[Chunk]]
    ) -> (blockPosition: Lattice3, faceNormal: Lattice3) {
        let rayOrigin = transform.position
        let rayDirection = transform.forward

        var d: Float = 0

        while d <= Self.reachDistance {
            let rayPosition = rayOrigin + rayDirection * d
            let rayBlockPosition =
                PlayerControl.getBlockPosition(rayPosition)

            if !PlayerControl.isInsideWorldBounds(rayBlockPosition)
                || !MathUtils.isInRange(
                    rayBlockPosition.y,
                    0,
                    Chunk.height
                )
            {
                d += Self.reachDetectStep
                continue
            }

            let chunkIndex = Chunk.getIndex(rayBlockPosition)

            if !Chunk.isValidIndex(chunkIndex) {
                d += Self.reachDetectStep
                continue
            }

            let targetingChunk = chunks[chunkIndex.x][chunkIndex.y]
            let rayLocalPosition =
                Chunk.getLocalBlockPosition(rayBlockPosition)

            let blockAtRay =
                targetingChunk.getBlock(rayLocalPosition)

            if blockAtRay != .air {
                let blockToRay =
                    (rayPosition - Vector3(rayBlockPosition)).normed

                let faceNormals: [Lattice3] = [
                    .right,
                    .left,
                    .up,
                    .down,
                    .forward,
                    .backward,
                ]

                var faceNormal = Lattice3.zero
                var maxDot = -Float.greatestFiniteMagnitude

                for normal in faceNormals {
                    let adjacentBlockPosition =
                        rayBlockPosition + normal

                    if !PlayerControl.isInsideWorldBounds(
                        adjacentBlockPosition
                    )
                        || !MathUtils.isInRange(
                            adjacentBlockPosition.y,
                            0,
                            Chunk.height
                        )
                    {
                        continue
                    }

                    let adjacentChunkIndex =
                        Chunk.getIndex(adjacentBlockPosition)

                    if Chunk.isValidIndex(adjacentChunkIndex) {
                        let adjacentChunk =
                            chunks[adjacentChunkIndex.x][adjacentChunkIndex.y]

                        let adjacentLocalPosition =
                            Chunk.getLocalBlockPosition(
                                adjacentBlockPosition
                            )

                        let adjacentBlock =
                            adjacentChunk.getBlock(
                                adjacentLocalPosition
                            )

                        if adjacentBlock != .air {
                            continue
                        }
                    }

                    let dot = Vector3.dot(
                        blockToRay,
                        Vector3(normal)
                    )

                    if dot > maxDot {
                        maxDot = dot
                        faceNormal = normal
                    }
                }

                if faceNormal == .zero {
                    return (.zero, .zero)
                }

                return (rayBlockPosition, faceNormal)
            }

            d += Self.reachDetectStep
        }

        return (.zero, .zero)
    }

    func tryMineBlock(
        chunksManager: ChunksManager,
        worldBlockPosition: Lattice3,
        device: MTLDevice
    ) -> Bool {
        if !PlayerControl.isInsideWorldBounds(worldBlockPosition) {
            return false
        }

        if !MathUtils.isInRange(
            worldBlockPosition.y,
            PlayerControl.canMinePlaceBlockHeightRange.x,
            PlayerControl.canMinePlaceBlockHeightRange.y
        ) {
            return false
        }

        let chunkIndex = Chunk.getIndex(worldBlockPosition)
        let localBlockPosition =
            Chunk.getLocalBlockPosition(worldBlockPosition)

        if chunksManager.getBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition
        ) == .air {
            return false
        }

        let playerExistingChunkIndex =
            Chunk.getIndex(getFootBlockPosition())

        chunksManager.updateBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition,
            newBlock: .air,
            device: device
        )

        chunksManager.updateDrawChunks(
            playerExistingChunkIndex: playerExistingChunkIndex,
            parallelIfGenerate: true,
            deviceIfGenerate: device
        )

        return true
    }

    func tryPlaceBlock(
        chunksManager: ChunksManager,
        worldBlockPosition: Lattice3,
        block: Block,
        device: MTLDevice
    ) -> Bool {
        if !PlayerControl.isInsideWorldBounds(worldBlockPosition) {
            return false
        }

        if !MathUtils.isInRange(
            worldBlockPosition.y,
            PlayerControl.canMinePlaceBlockHeightRange.x,
            PlayerControl.canMinePlaceBlockHeightRange.y
        ) {
            return false
        }

        let chunkIndex = Chunk.getIndex(worldBlockPosition)
        let localBlockPosition =
            Chunk.getLocalBlockPosition(worldBlockPosition)

        if chunksManager.getBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition
        ) != .air {
            return false
        }

        if isOverlappingWithBlock(
            chunksManager.getChunks(),
            worldBlockPosition
        ) {
            return false
        }

        let playerExistingChunkIndex =
            Chunk.getIndex(getFootBlockPosition())

        chunksManager.updateBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition,
            newBlock: block,
            device: device
        )

        chunksManager.updateDrawChunks(
            playerExistingChunkIndex: playerExistingChunkIndex,
            parallelIfGenerate: true,
            deviceIfGenerate: device
        )

        return true
    }

    func serializeTransform() -> Data {
        var buffer = Data()
        buffer.reserveCapacity(MemoryLayout<Float>.size * 5)

        buffer.appendFloat32(transform.position.x)
        buffer.appendFloat32(transform.position.y)
        buffer.appendFloat32(transform.position.z)
        buffer.appendFloat32(yaw)
        buffer.appendFloat32(pitch)

        return buffer
    }

    func deserializeTransformAndTeleport(_ buffer: Data) {
        if buffer.count != MemoryLayout<Float>.size * 5 {
            print("Failed to deserialize player transform")
            return
        }

        var offset = 0

        guard let x = buffer.readFloat32(offset: &offset),
            let y = buffer.readFloat32(offset: &offset),
            let z = buffer.readFloat32(offset: &offset),
            let yaw = buffer.readFloat32(offset: &offset),
            let pitch = buffer.readFloat32(offset: &offset)
        else {
            return
        }

        transform.position = Vector3(x, y, z)
        transform.rotation =
            Self.calculateRotationFromYawPitch(
                yaw: yaw,
                pitch: pitch
            )

        velocityV = 0
        self.yaw = yaw
        self.pitch = pitch
    }

    private static func calculateRotationFromYawPitch(
        yaw: Float,
        pitch: Float
    ) -> Quaternion {
        Quaternion.fromAxisAngle(
            axis: .up,
            angleRad: yaw
        )
            * Quaternion.fromAxisAngle(
                axis: .right,
                angleRad: pitch
            )
    }
}
