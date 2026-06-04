import Foundation

enum Block: UInt32 {
    case air = 0
    case invalid = 1
    case grass = 2
    case stone = 3
    case dirt = 4
    case sand = 5
}

func getBlockName(_ block: Block) -> String {
    switch block {
    case .air: return "Air"
    case .grass: return "Grass"
    case .stone: return "Stone"
    case .dirt: return "Dirt"
    case .sand: return "Sand"
    default: return "Invalid"
    }
}

final class Chunk {
    static let defaultCreationSeed: UInt32 = 0x2961_E3B1

    static let size = 16
    static let height = 256
    static let count = 1024
    static let drawDistance = 8
    static let drawCountMax = drawDistance * 2 + 1

    struct DrawChunksIndexRangeInfo {
        var rangeX: Lattice2
        var rangeZ: Lattice2
        var chunkCount: Int

        func getRangeMin() -> Lattice2 {
            Lattice2(rangeX.x, rangeZ.x)
        }

        func getRangeMax() -> Lattice2 {
            Lattice2(rangeX.y, rangeZ.y)
        }
    }

    private var data: [[[Block]]]

    init() {
        self.data = []
    }

    private init(data: [[[Block]]]) {
        self.data = data
    }

    static func createChunksArray<T>(
        defaultValue: @autoclosure () -> T
    ) -> [[T]] {
        Array(
            repeating: Array(
                repeating: defaultValue(),
                count: count
            ),
            count: count
        )
    }

    static func createDrawChunksArray<T>(
        defaultValue: @autoclosure () -> T
    ) -> [[T]] {
        Array(
            repeating: Array(
                repeating: defaultValue(),
                count: drawCountMax
            ),
            count: drawCountMax
        )
    }

    static func createDrawChunksIndexRangeInfo(
        _ cameraExistingChunkIndex: Lattice2
    ) -> DrawChunksIndexRangeInfo {
        let xMin = min(
            max(cameraExistingChunkIndex.x - drawDistance, 0),
            count - 1
        )
        let xMax = min(
            max(cameraExistingChunkIndex.x + drawDistance, 0),
            count - 1
        )
        let zMin = min(
            max(cameraExistingChunkIndex.y - drawDistance, 0),
            count - 1
        )
        let zMax = min(
            max(cameraExistingChunkIndex.y + drawDistance, 0),
            count - 1
        )

        let chunkCount = (xMax - xMin + 1) * (zMax - zMin + 1)

        return DrawChunksIndexRangeInfo(
            rangeX: Lattice2(xMin, xMax),
            rangeZ: Lattice2(zMin, zMax),
            chunkCount: chunkCount
        )
    }

    static func getIndex(_ worldBlockPosition: Lattice3) -> Lattice2 {
        Lattice2(
            worldBlockPosition.x / size,
            worldBlockPosition.z / size
        )
    }

    static func getLocalBlockPosition(
        _ worldBlockPosition: Lattice3
    ) -> Lattice3 {
        Lattice3(
            worldBlockPosition.x % size,
            worldBlockPosition.y,
            worldBlockPosition.z % size
        )
    }

    static func isValidIndex(_ chunkIndex: Lattice2) -> Bool {
        MathUtils.isInRange(chunkIndex.x, 0, count)
            && MathUtils.isInRange(chunkIndex.y, 0, count)
    }

    static func createVoid() -> Chunk {
        let zLine = Array(repeating: Block.air, count: size)
        let yPlane = Array(repeating: zLine, count: height)
        let data = Array(repeating: yPlane, count: size)

        return Chunk(data: data)
    }

    func serialize() -> Data {
        var buffer = Data()
        buffer.reserveCapacity(
            Self.size * Self.height * Self.size
                * MemoryLayout<UInt32>.size
        )

        for x in 0..<Self.size {
            for y in 0..<Self.height {
                for z in 0..<Self.size {
                    buffer.appendUInt32(data[x][y][z].rawValue)
                }
            }
        }

        return buffer
    }

    static func deserialize(_ buffer: Data) -> Chunk {
        let chunk = createVoid()
        var offset = 0

        for x in 0..<size {
            for y in 0..<height {
                for z in 0..<size {
                    guard let rawValue = buffer.readUInt32(offset: &offset),
                        let block = Block(rawValue: rawValue)
                    else {
                        chunk.data[x][y][z] = .invalid
                        continue
                    }

                    chunk.data[x][y][z] = block
                }
            }
        }

        return chunk
    }

    static func createFromNoise(
        chunkIndex: Lattice2,
        noiseScale: Vector2,
        heightBulk: Int,
        minDirtHeight: Int,
        minStoneHeight: Int,
        seed: UInt32 = defaultCreationSeed
    ) -> Chunk {
        let chunk = createVoid()

        let seedX = Float((seed & 0xFFFF_0000) >> 16)
        let seedZ = Float(seed & 0x0000_FFFF)

        for x in 0..<size {
            for z in 0..<size {
                let noise = Noise.simplex2D(
                    (Float(x + size * chunkIndex.x) + seedX) * noiseScale.x,
                    (Float(z + size * chunkIndex.y) + seedZ) * noiseScale.x
                )

                let heightNormed = (noise + 1.0) * 0.5

                let terrainHeight = min(
                    max(
                        heightBulk + Int(heightNormed * noiseScale.y),
                        0
                    ),
                    height - 1
                )

                for y in 0...terrainHeight {
                    if y >= minStoneHeight {
                        chunk.setBlock(Lattice3(x, y, z), .stone)
                    } else if y >= minDirtHeight {
                        if y == terrainHeight {
                            chunk.setBlock(Lattice3(x, y, z), .grass)
                        } else {
                            chunk.setBlock(Lattice3(x, y, z), .dirt)
                        }
                    } else {
                        chunk.setBlock(Lattice3(x, y, z), .sand)
                    }
                }
            }
        }

        return chunk
    }

    func getBlock(_ position: Lattice3) -> Block {
        data[position.x][position.y][position.z]
    }

    func setBlock(_ position: Lattice3, _ block: Block) {
        data[position.x][position.y][position.z] = block
    }

    func getFloorHeight(
        positionXZ: Lattice2,
        maxY: Int = height - 1
    ) -> Int {
        for y in stride(from: maxY, through: 0, by: -1) {
            if getBlock(Lattice3(positionXZ.x, y, positionXZ.y)) != .air {
                return y
            }
        }

        return -1
    }

    func getCeilHeight(
        positionXZ: Lattice2,
        minY: Int = 0
    ) -> Int {
        for y in minY...(Self.height - 1) {
            if getBlock(Lattice3(positionXZ.x, y, positionXZ.y)) != .air {
                return y
            }
        }

        return Self.height
    }

    func createMesh(chunkIndex: Lattice2) -> Mesh {
        var mesh = Mesh()
        mesh.vertices.reserveCapacity(4096)
        mesh.indices.reserveCapacity(1024)

        let faceNormals: [Lattice3] = [
            .up,
            .down,
            .right,
            .left,
            .forward,
            .backward,
        ]

        for xi in 0..<Self.size {
            for yi in 0..<Self.height {
                for zi in 0..<Self.size {
                    let block = data[xi][yi][zi]

                    if block == .air {
                        continue
                    }

                    let localBlockPosition = Lattice3(xi, yi, zi)

                    let worldBlockPosition =
                        localBlockPosition
                        + Lattice3(
                            chunkIndex.x * Self.size,
                            0,
                            chunkIndex.y * Self.size
                        )

                    for faceNormal in faceNormals {
                        let checkPosition = localBlockPosition + faceNormal

                        if MathUtils.isInRange(checkPosition.x, 0, Self.size)
                            && MathUtils.isInRange(
                                checkPosition.y,
                                0,
                                Self.height
                            )
                            && MathUtils.isInRange(
                                checkPosition.z,
                                0,
                                Self.size
                            )
                            && data[checkPosition.x][checkPosition.y][
                                checkPosition.z
                            ] != .air
                        {
                            continue
                        }

                        appendFace(
                            to: &mesh,
                            worldBlockPosition: worldBlockPosition,
                            faceNormal: faceNormal,
                            block: block
                        )
                    }
                }
            }
        }

        if mesh.vertices.isEmpty {
            mesh = Mesh.createCube(
                centerWorldPosition: .zero,
                textureIndex: UInt32(Block.air.rawValue)
            )
        }

        return mesh
    }

    private func appendFace(
        to mesh: inout Mesh,
        worldBlockPosition: Lattice3,
        faceNormal: Lattice3,
        block: Block
    ) {
        let indexBegin = UInt32(mesh.vertices.count)

        mesh.indices.append(indexBegin + 0)
        mesh.indices.append(indexBegin + 1)
        mesh.indices.append(indexBegin + 2)
        mesh.indices.append(indexBegin + 2)
        mesh.indices.append(indexBegin + 1)
        mesh.indices.append(indexBegin + 3)

        let worldPosition = Vector3(worldBlockPosition)
        let normal = Vector3(faceNormal)
        let textureIndex = UInt32(block.rawValue)

        func v(
            _ offset: Vector3,
            _ uv: Vector2
        ) -> VertexData {
            VertexData(
                position: Vector4(worldPosition + offset),
                uv: uv,
                normal: normal,
                centerWorldPosition: worldPosition,
                textureIndex: textureIndex
            )
        }

        if faceNormal == .up {
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, -0.5), Vector2(0.00, 0.50))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, 0.5), Vector2(0.00, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(0.5, 0.5, -0.5), Vector2(0.25, 0.50))
            )
            mesh.vertices.append(v(Vector3(0.5, 0.5, 0.5), Vector2(0.25, 0.25)))
        } else if faceNormal == .down {
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, 0.5), Vector2(0.25, 0.50))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, -0.5), Vector2(0.25, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, 0.5), Vector2(0.50, 0.50))
            )
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, -0.5), Vector2(0.50, 0.25))
            )
        } else if faceNormal == .right {
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, -0.5), Vector2(0.25, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(0.5, 0.5, -0.5), Vector2(0.25, 0.00))
            )
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, 0.5), Vector2(0.50, 0.25))
            )
            mesh.vertices.append(v(Vector3(0.5, 0.5, 0.5), Vector2(0.50, 0.00)))
        } else if faceNormal == .left {
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, 0.5), Vector2(0.00, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, 0.5), Vector2(0.00, 0.00))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, -0.5), Vector2(0.25, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, -0.5), Vector2(0.25, 0.00))
            )
        } else if faceNormal == .forward {
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, 0.5), Vector2(0.75, 0.25))
            )
            mesh.vertices.append(v(Vector3(0.5, 0.5, 0.5), Vector2(0.75, 0.00)))
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, 0.5), Vector2(1.00, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, 0.5), Vector2(1.00, 0.00))
            )
        } else {
            mesh.vertices.append(
                v(Vector3(-0.5, -0.5, -0.5), Vector2(0.50, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(-0.5, 0.5, -0.5), Vector2(0.50, 0.00))
            )
            mesh.vertices.append(
                v(Vector3(0.5, -0.5, -0.5), Vector2(0.75, 0.25))
            )
            mesh.vertices.append(
                v(Vector3(0.5, 0.5, -0.5), Vector2(0.75, 0.00))
            )
        }
    }
}
