import Foundation
import Metal

final class ChunksManager {
    private enum ChunkGenerationState: UInt8 {
        case notYet = 0
        case creatingParallel
        case finishedParallel
        case finishedAll
    }

    private struct GeneratedChunkData {
        var chunk: Chunk
        var mesh: Mesh
    }

    private let lock = NSLock()

    private var generationStates: [[ChunkGenerationState]]
    private var chunks: [[Chunk]]
    private var meshes: [[Mesh]]
    private var meshBuffers: [[MeshBuffers?]]

    private var pendingGeneratedChunks: [Lattice2: GeneratedChunkData] = [:]

    private var drawMeshBuffers: [[MeshBuffers?]]
    private var renderMeshContext: RenderMeshContext
    private var drawRangeInfo: Chunk.DrawChunksIndexRangeInfo

    private var saveChunkIndices: Set<Lattice2> = []

    init(playerFirstExistingChunkIndex: Lattice2) {
        self.generationStates = Chunk.createChunksArray(
            defaultValue: .notYet
        )

        self.chunks = Chunk.createChunksArray(
            defaultValue: Chunk()
        )

        self.meshes = Chunk.createChunksArray(
            defaultValue: Mesh()
        )

        self.meshBuffers = Chunk.createChunksArray(
            defaultValue: nil as MeshBuffers?
        )

        self.drawMeshBuffers = Chunk.createDrawChunksArray(
            defaultValue: nil as MeshBuffers?
        )

        self.renderMeshContext = RenderMeshContext(
            meshBuffersList: []
        )

        self.drawRangeInfo = Chunk.createDrawChunksIndexRangeInfo(
            playerFirstExistingChunkIndex
        )

        self.saveChunkIndices.reserveCapacity(1024)
        self.pendingGeneratedChunks.reserveCapacity(1024)
    }

    func getChunks() -> [[Chunk]] {
        lock.lock()
        defer { lock.unlock() }

        return chunks
    }

    func getDrawRangeInfo() -> Chunk.DrawChunksIndexRangeInfo {
        lock.lock()
        defer { lock.unlock() }

        return drawRangeInfo
    }

    func getBlock(_ worldBlockPosition: Lattice3) -> Block {
        let chunkIndex = Chunk.getIndex(worldBlockPosition)
        let localBlockPosition = Chunk.getLocalBlockPosition(
            worldBlockPosition
        )

        return getBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition
        )
    }

    func getBlock(
        chunkIndex: Lattice2,
        localBlockPosition: Lattice3
    ) -> Block {
        lock.lock()
        defer { lock.unlock() }

        return chunks[chunkIndex.x][chunkIndex.y]
            .getBlock(localBlockPosition)
    }

    func updateBlock(
        worldBlockPosition: Lattice3,
        newBlock: Block,
        device: MTLDevice
    ) {
        let chunkIndex = Chunk.getIndex(worldBlockPosition)
        let localBlockPosition = Chunk.getLocalBlockPosition(
            worldBlockPosition
        )

        updateBlock(
            chunkIndex: chunkIndex,
            localBlockPosition: localBlockPosition,
            newBlock: newBlock,
            device: device
        )
    }

    func updateBlock(
        chunkIndex: Lattice2,
        localBlockPosition: Lattice3,
        newBlock: Block,
        device: MTLDevice
    ) {
        lock.lock()
        defer { lock.unlock() }

        chunks[chunkIndex.x][chunkIndex.y].setBlock(
            localBlockPosition,
            newBlock
        )

        meshes[chunkIndex.x][chunkIndex.y] =
            chunks[chunkIndex.x][chunkIndex.y]
            .createMesh(chunkIndex: chunkIndex)

        meshBuffers[chunkIndex.x][chunkIndex.y] =
            meshes[chunkIndex.x][chunkIndex.y]
            .createMetalBuffers(device: device)

        generationStates[chunkIndex.x][chunkIndex.y] = .finishedAll
        saveChunkIndices.insert(chunkIndex)
    }

    func updateDrawChunks(
        playerExistingChunkIndex: Lattice2,
        parallelIfGenerate: Bool,
        deviceIfGenerate: MTLDevice
    ) {
        lock.lock()
        drawRangeInfo = Chunk.createDrawChunksIndexRangeInfo(
            playerExistingChunkIndex
        )
        let currentDrawRangeInfo = drawRangeInfo
        lock.unlock()

        for xi in currentDrawRangeInfo.rangeX.x...currentDrawRangeInfo.rangeX.y
        {
            for zi in currentDrawRangeInfo.rangeZ
                .x...currentDrawRangeInfo.rangeZ.y
            {
                let chunkIndex = Lattice2(xi, zi)

                let shouldGenerate: Bool = lock.withLock {
                    !saveChunkIndices.contains(chunkIndex)
                }

                if shouldGenerate {
                    generateChunk(
                        chunkIndex: chunkIndex,
                        parallel: parallelIfGenerate,
                        device: deviceIfGenerate
                    )
                }

                copyToDrawData(chunkIndex)
            }
        }
    }

    func packToRenderMeshContext() -> RenderMeshContext {
        lock.lock()
        defer { lock.unlock() }

        var packed: [MeshBuffers] = []
        packed.reserveCapacity(
            Chunk.drawCountMax * Chunk.drawCountMax
        )

        for xi in drawRangeInfo.rangeX.x...drawRangeInfo.rangeX.y {
            for zi in drawRangeInfo.rangeZ.x...drawRangeInfo.rangeZ.y {
                let drawDataIndex = getDrawDataIndexNoLock(
                    Lattice2(xi, zi)
                )

                if let meshBuffer =
                    drawMeshBuffers[drawDataIndex.x][drawDataIndex.y]
                {
                    packed.append(meshBuffer)
                }
            }
        }

        renderMeshContext = RenderMeshContext(
            meshBuffersList: packed
        )

        return renderMeshContext
    }

    func markChunkForSaving(_ chunkIndex: Lattice2) {
        lock.lock()
        defer { lock.unlock() }

        saveChunkIndices.insert(chunkIndex)
    }

    func serializeSaveChunks() -> Data {
        lock.lock()
        defer { lock.unlock() }

        var buffer = Data()
        buffer.reserveCapacity(1024 * 1024)

        buffer.appendUInt64(UInt64(saveChunkIndices.count))

        for chunkIndex in saveChunkIndices {
            let x = UInt64(chunkIndex.x)
            let y = UInt64(chunkIndex.y)

            let chunk = chunks[chunkIndex.x][chunkIndex.y]
            let binary = chunk.serialize()

            buffer.appendUInt64(x)
            buffer.appendUInt64(y)
            buffer.appendUInt64(UInt64(binary.count))
            buffer.append(binary)
        }

        return buffer
    }

    func deserializeAndUpdateChunks(
        _ buffer: Data,
        device: MTLDevice
    ) {
        var offset = 0

        guard let chunkCount = buffer.readUInt64(offset: &offset) else {
            return
        }

        var loadedChunks: [Lattice2: Chunk] = [:]
        loadedChunks.reserveCapacity(1024)

        for _ in 0..<chunkCount {
            guard let x = buffer.readUInt64(offset: &offset) else {
                return
            }

            guard let y = buffer.readUInt64(offset: &offset) else {
                return
            }

            guard let binarySize = buffer.readUInt64(offset: &offset) else {
                return
            }

            guard
                let binary = buffer.readBytes(
                    offset: &offset,
                    count: Int(binarySize)
                )
            else {
                return
            }

            loadedChunks[Lattice2(Int(x), Int(y))] =
                Chunk.deserialize(binary)
        }

        lock.lock()
        saveChunkIndices.removeAll(keepingCapacity: true)
        lock.unlock()

        for (chunkIndex, chunk) in loadedChunks {
            updateChunk(
                chunkIndex: chunkIndex,
                newChunk: chunk,
                device: device,
                markForSaving: true
            )
        }
    }

    private func generateChunk(
        chunkIndex: Lattice2,
        parallel: Bool,
        device: MTLDevice
    ) {
        if parallel {
            tryStartGenerateChunkParallel(chunkIndex: chunkIndex)
            generateChunkNotParallel(
                chunkIndex: chunkIndex,
                device: device
            )
        } else {
            generateChunkSynchronously(
                chunkIndex: chunkIndex,
                device: device
            )
        }
    }

    private func tryStartGenerateChunkParallel(
        chunkIndex: Lattice2
    ) {
        let shouldStart: Bool = lock.withLock {
            if generationStates[chunkIndex.x][chunkIndex.y] != .notYet {
                return false
            }

            generationStates[chunkIndex.x][chunkIndex.y] = .creatingParallel
            return true
        }

        if !shouldStart {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let chunk = Chunk.createFromNoise(
                chunkIndex: chunkIndex,
                noiseScale: Vector2(0.015, 12.0),
                heightBulk: 16,
                minDirtHeight: 18,
                minStoneHeight: 24
            )

            let mesh = chunk.createMesh(chunkIndex: chunkIndex)

            self?.lock.lock()
            self?.pendingGeneratedChunks[chunkIndex] =
                GeneratedChunkData(
                    chunk: chunk,
                    mesh: mesh
                )
            self?.generationStates[chunkIndex.x][chunkIndex.y] =
                .finishedParallel
            self?.lock.unlock()
        }
    }

    private func generateChunkNotParallel(
        chunkIndex: Lattice2,
        device: MTLDevice
    ) {
        let generatedData: GeneratedChunkData? = lock.withLock {
            guard
                generationStates[chunkIndex.x][chunkIndex.y]
                    == .finishedParallel
            else {
                return nil
            }

            return pendingGeneratedChunks.removeValue(
                forKey: chunkIndex
            )
        }

        guard let generatedData else {
            return
        }

        let newMeshBuffer =
            generatedData.mesh.createMetalBuffers(device: device)

        lock.lock()
        chunks[chunkIndex.x][chunkIndex.y] = generatedData.chunk
        meshes[chunkIndex.x][chunkIndex.y] = generatedData.mesh
        meshBuffers[chunkIndex.x][chunkIndex.y] = newMeshBuffer

        generationStates[chunkIndex.x][chunkIndex.y] = .finishedAll
        lock.unlock()
    }

    private func generateChunkSynchronously(
        chunkIndex: Lattice2,
        device: MTLDevice
    ) {
        let shouldStart: Bool = lock.withLock {
            if generationStates[chunkIndex.x][chunkIndex.y] == .finishedAll {
                return false
            }

            generationStates[chunkIndex.x][chunkIndex.y] = .creatingParallel
            return true
        }

        if !shouldStart {
            return
        }

        let chunk = Chunk.createFromNoise(
            chunkIndex: chunkIndex,
            noiseScale: Vector2(0.015, 12.0),
            heightBulk: 16,
            minDirtHeight: 18,
            minStoneHeight: 24
        )

        let mesh = chunk.createMesh(chunkIndex: chunkIndex)
        let newMeshBuffer = mesh.createMetalBuffers(device: device)

        lock.lock()
        chunks[chunkIndex.x][chunkIndex.y] = chunk
        meshes[chunkIndex.x][chunkIndex.y] = mesh
        meshBuffers[chunkIndex.x][chunkIndex.y] = newMeshBuffer
        generationStates[chunkIndex.x][chunkIndex.y] = .finishedAll
        lock.unlock()
    }

    private func updateChunk(
        chunkIndex: Lattice2,
        newChunk: Chunk,
        device: MTLDevice,
        markForSaving: Bool
    ) {
        let newMesh = newChunk.createMesh(chunkIndex: chunkIndex)
        let newMeshBuffer = newMesh.createMetalBuffers(device: device)

        lock.lock()
        chunks[chunkIndex.x][chunkIndex.y] = newChunk
        meshes[chunkIndex.x][chunkIndex.y] = newMesh
        meshBuffers[chunkIndex.x][chunkIndex.y] = newMeshBuffer
        generationStates[chunkIndex.x][chunkIndex.y] = .finishedAll

        if markForSaving {
            saveChunkIndices.insert(chunkIndex)
        }

        lock.unlock()
    }

    private func copyToDrawData(_ chunkIndex: Lattice2) {
        lock.lock()
        defer { lock.unlock() }

        let drawDataIndex = getDrawDataIndexNoLock(chunkIndex)

        drawMeshBuffers[drawDataIndex.x][drawDataIndex.y] =
            meshBuffers[chunkIndex.x][chunkIndex.y]
    }

    private func getDrawDataIndexNoLock(_ chunkIndex: Lattice2) -> Lattice2 {
        chunkIndex - drawRangeInfo.getRangeMin()
    }
}
