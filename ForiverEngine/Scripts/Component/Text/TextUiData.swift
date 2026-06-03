import Metal
import simd

struct TextUiData {
    static let fontTextureTextLength = 16

    private(set) var data: [[Text.Data]]
    private(set) var dataSize: Lattice2

    static func createEmpty(dataSize: Lattice2) -> TextUiData {
        let row = Array(
            repeating: Text.Data.createDefault(),
            count: dataSize.x
        )

        return TextUiData(
            data: Array(repeating: row, count: dataSize.y),
            dataSize: dataSize
        )
    }

    func getDataSize() -> Lattice2 {
        dataSize
    }

    mutating func setText(
        positionIndex: Lattice2,
        text: Character,
        color: Color = Text.defaultColor
    ) {
        data[positionIndex.y][positionIndex.x] = Text.Data(
            color: color,
            fontTextureIndex: Text.convertToFontTextureIndex(text)
        )
    }

    mutating func setTexts(
        beginPositionIndex: Lattice2,
        texts: String,
        color: Color = Text.defaultColor
    ) {
        let characters = Array(texts)

        let textCount = characters.count

        let beginDataIndex =
            beginPositionIndex.y * dataSize.x
            + beginPositionIndex.x

        let endDataIndex = min(
            beginDataIndex + textCount,
            dataSize.x * dataSize.y
        )

        if beginDataIndex < 0 || beginDataIndex >= dataSize.x * dataSize.y {
            return
        }

        for i in beginDataIndex..<endDataIndex {
            let xi = i % dataSize.x
            let yi = i / dataSize.x
            let ti = i - beginDataIndex

            setText(
                positionIndex: Lattice2(xi, yi),
                text: characters[ti],
                color: color
            )
        }
    }

    mutating func clearRow(_ rowIndex: Int) {
        for x in 0..<dataSize.x {
            data[rowIndex][x] = Text.Data.createDefault()
        }
    }

    mutating func clearAll() {
        for y in 0..<dataSize.y {
            clearRow(y)
        }
    }

    func createTexture(device: MTLDevice) -> MTLTexture {
        let dataSizeTotal = dataSize.x * dataSize.y
        let bytesPerPixel = 4

        var pixels = [UInt8]()
        pixels.reserveCapacity(dataSizeTotal * bytesPerPixel)

        for i in 0..<dataSizeTotal {
            let xi = i % dataSize.x
            let yi = i / dataSize.x

            let singleData = data[yi][xi]

            pixels.append(UInt8(singleData.color.r * 0xff))
            pixels.append(UInt8(singleData.color.g * 0xff))
            pixels.append(UInt8(singleData.color.b * 0xff))
            pixels.append(singleData.fontTextureIndex)
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: dataSize.x,
            height: dataSize.y,
            mipmapped: false
        )

        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Failed to create text texture")
        }

        texture.replace(
            region: MTLRegionMake2D(0, 0, dataSize.x, dataSize.y),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: dataSize.x * bytesPerPixel
        )

        return texture
    }
}
