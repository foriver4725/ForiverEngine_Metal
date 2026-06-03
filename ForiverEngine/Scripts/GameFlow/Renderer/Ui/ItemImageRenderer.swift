import Metal
import MetalKit

final class ItemImageRenderer {
    static let zOrder: UInt16 = 0

    private static let blockToName: [Block: String] = [
        .air: "air",
        .invalid: "invalid",
        .grass: "grass",
        .stone: "stone",
        .dirt: "dirt",
        .sand: "sand",
    ]

    private let base = ImageRendererBase()

    private var blockToTexture: [Block: MTLTexture] = [:]

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2,
        position: Vector2,
        size: Vector2,
        initType: Block
    ) {
        blockToTexture = Dictionary(
            uniqueKeysWithValues: Self.blockToName.map { block, name in
                (
                    block,
                    TextureLoader.loadAsArray(
                        device: renderContext.device,
                        names: [name],
                        isSRGB: false
                    )!
                )
            }
        )

        base.initialize(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize,
            imageName: Self.blockToName[initType]!,
            position: position,
            size: size,
            zOrder: Self.zOrder,
            initDrawEnabled: Self.isDrawableBlock(initType)
        )
    }

    func changeBlock(
        renderContext: RenderContext,
        _ newBlock: Block
    ) {
        guard let texture = blockToTexture[newBlock] else {
            fatalError("Invalid block")
        }

        base.reUploadTexture(
            renderContext: renderContext,
            texture: texture
        )

        base.setDrawEnabled(Self.isDrawableBlock(newBlock))
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext
    ) {
        base.draw(
            renderContext: renderContext,
            renderTargetContext: renderTargetContext
        )
    }

    private static func isDrawableBlock(_ block: Block) -> Bool {
        block != .invalid
    }
}
