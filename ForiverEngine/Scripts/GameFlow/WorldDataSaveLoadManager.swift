import Foundation

enum WorldDataSaveLoadManager {
    static let worldSaveDataDirectory =
        getAppDirectory()
        .appendingPathComponent("saves")
        .appendingPathComponent("world")

    static let worldSaveDataExtension = "world"

    static let worldNameFilePath =
        getAppDirectory()
        .appendingPathComponent("WorldName.txt")

    static let defaultWorldName = "NewWorld"

    private static func getAppDirectory() -> URL {
        Bundle.main.bundleURL.deletingLastPathComponent()
    }

    private static func getWorldSaveDataPath(_ worldName: String) -> URL {
        worldSaveDataDirectory
            .appendingPathComponent(worldName)
            .appendingPathExtension(worldSaveDataExtension)
    }

    static func exists(_ worldName: String) -> Bool {
        FileManager.default.fileExists(
            atPath: getWorldSaveDataPath(worldName).path
        )
    }

    static func save(
        worldName: String,
        binary: Data
    ) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: worldSaveDataDirectory,
                withIntermediateDirectories: true
            )

            try binary.write(
                to: getWorldSaveDataPath(worldName),
                options: .atomic
            )

            return true
        } catch {
            print("World save failed: \(error)")
            return false
        }
    }

    static func load(
        worldName: String
    ) -> Data? {
        do {
            return try Data(contentsOf: getWorldSaveDataPath(worldName))
        } catch {
            print("World load failed: \(error)")
            return nil
        }
    }

    static func loadWorldName() -> String {
        do {
            let text = try String(
                contentsOf: worldNameFilePath,
                encoding: .utf8
            )

            let worldName = text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return worldName.isEmpty ? defaultWorldName : worldName
        } catch {
            print("World name load failed: \(error)")
            return defaultWorldName
        }
    }

    static func combineWorldDataBinaries(
        playerTransformBinary: Data,
        terrainBinary: Data
    ) -> Data {
        var buffer = Data()

        buffer.appendUInt64(UInt64(playerTransformBinary.count))
        buffer.append(playerTransformBinary)

        buffer.appendUInt64(UInt64(terrainBinary.count))
        buffer.append(terrainBinary)

        return buffer
    }

    static func splitWorldDataBinaries(
        combinedBinary: Data
    ) -> (playerTransformBinary: Data, terrainBinary: Data)? {
        var offset = 0

        guard
            let playerTransformBinarySize =
                combinedBinary.readUInt64(offset: &offset)
        else {
            return nil
        }

        guard
            let playerTransformBinary =
                combinedBinary.readBytes(
                    offset: &offset,
                    count: Int(playerTransformBinarySize)
                )
        else {
            return nil
        }

        guard
            let terrainBinarySize =
                combinedBinary.readUInt64(offset: &offset)
        else {
            return nil
        }

        guard
            let terrainBinary =
                combinedBinary.readBytes(
                    offset: &offset,
                    count: Int(terrainBinarySize)
                )
        else {
            return nil
        }

        return (playerTransformBinary, terrainBinary)
    }
}
