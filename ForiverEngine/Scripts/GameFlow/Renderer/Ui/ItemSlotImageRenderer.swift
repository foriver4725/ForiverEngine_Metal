import Metal
import MetalKit

final class ItemSlotImageRenderer {
    static let zOrder: UInt16 = 1

    enum ImageType {
        case normal
        case selected
    }

    private static let imageTypeToName: [ImageType: String] = [
        .normal: "item_frame",
        .selected: "item_frame_selected",
    ]

    private let base = ImageRendererBase()

    private var imageTypeToTexture: [ImageType: MTLTexture] = [:]

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2,
        position: Vector2,
        size: Vector2,
        initType: ImageType
    ) {
        imageTypeToTexture = [
            .normal: TextureLoader.load(
                device: renderContext.device,
                name: Self.imageTypeToName[.normal]!,
                isSRGB: false
            )!,
            .selected: TextureLoader.load(
                device: renderContext.device,
                name: Self.imageTypeToName[.selected]!,
                isSRGB: false
            )!,
        ]

        base.initialize(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize,
            imageName: Self.imageTypeToName[initType]!,
            position: position,
            size: size,
            zOrder: Self.zOrder,
            useDSV: false,
            useAlphaBlend: true,
            initDrawEnabled: true
        )
    }

    func changeImageType(
        renderContext: RenderContext,
        _ newType: ImageType
    ) {
        guard let texture = imageTypeToTexture[newType] else {
            fatalError("Invalid image type")
        }

        base.reUploadTexture(
            renderContext: renderContext,
            texture: texture
        )
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
}
