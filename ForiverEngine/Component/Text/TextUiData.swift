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
        let width = dataSize.x
        let height = dataSize.y
        let bytesPerPixel = 4

        var pixels = [UInt8]()
        pixels.reserveCapacity(width * height * bytesPerPixel)

        for y in 0..<height {
            for x in 0..<width {
                let d = data[y][x]

                pixels.append(UInt8(d.color.r * 255))
                pixels.append(UInt8(d.color.g * 255))
                pixels.append(UInt8(d.color.b * 255))
                pixels.append(d.fontTextureIndex)
            }
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            fatalError("Failed to create text texture")
        }

        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: width * bytesPerPixel
        )

        return texture
    }
}
