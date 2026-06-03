import Metal
import MetalKit

final class ItemSlotManager {
    typealias SlotImageType = ItemSlotImageRenderer.ImageType

    static let slotCount = 6
    static let slotSize = 128
    static let itemSize = 96

    static let slotItems: [Block] = [
        .grass,
        .stone,
        .dirt,
        .sand,
        .invalid,
        .invalid,
    ]

    struct SelectInputs {
        var select1: Bool
        var select2: Bool
        var select3: Bool
        var select4: Bool
        var select5: Bool
        var select6: Bool

        var selectLeft: Bool
        var selectRight: Bool
    }

    private var slotImageRenderers: [ItemSlotImageRenderer]
    private var itemImageRenderers: [ItemImageRenderer]

    private var selectingIndex: Int = 0

    init(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2,
        initSelectingIndex: Int = 0
    ) {
        self.slotImageRenderers = Self.createSlotImageRenderers(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize
        )

        self.itemImageRenderers = Self.createItemImageRenderers(
            renderContext: renderContext,
            metalView: metalView,
            windowSize: windowSize
        )

        self.selectingIndex = initSelectingIndex

        changeSlotImage(
            renderContext: renderContext,
            index: initSelectingIndex,
            newType: .selected
        )
    }

    func updateSelectingSlotByInput(
        renderContext: RenderContext,
        inputs: SelectInputs
    ) {
        var newIndex = selectingIndex

        if inputs.select1 {
            newIndex = 0
        } else if inputs.select2 {
            newIndex = 1
        } else if inputs.select3 {
            newIndex = 2
        } else if inputs.select4 {
            newIndex = 3
        } else if inputs.select5 {
            newIndex = 4
        } else if inputs.select6 {
            newIndex = 5
        } else if inputs.selectLeft {
            newIndex = (selectingIndex - 1 + Self.slotCount) % Self.slotCount
        } else if inputs.selectRight {
            newIndex = (selectingIndex + 1) % Self.slotCount
        } else {
            return
        }

        updateSelectingSlot(
            renderContext: renderContext,
            newIndex: newIndex
        )
    }

    func updateSelectingSlot(
        renderContext: RenderContext,
        newIndex: Int
    ) {
        if selectingIndex == newIndex {
            return
        }

        let prevIndex = selectingIndex
        selectingIndex = newIndex

        changeSlotImage(
            renderContext: renderContext,
            index: prevIndex,
            newType: .normal
        )

        changeSlotImage(
            renderContext: renderContext,
            index: selectingIndex,
            newType: .selected
        )
    }

    func draw(
        renderContext: RenderContext,
        renderTargetContext: RenderTargetContext
    ) {
        for i in 0..<Self.slotCount {
            slotImageRenderers[i].draw(
                renderContext: renderContext,
                renderTargetContext: renderTargetContext
            )

            itemImageRenderers[i].draw(
                renderContext: renderContext,
                renderTargetContext: renderTargetContext
            )
        }
    }

    func getSelectingIndex() -> Int {
        selectingIndex
    }

    func getSelectingBlock() -> Block {
        Self.slotItems[selectingIndex]
    }

    private static func getSlotPosition(
        windowSize: Vector2,
        slotIndex: Int
    ) -> Vector2 {
        let marginBottom: Float = 20

        return Vector2(
            (windowSize.x - Float(slotSize * (slotCount - 1))) / 2
                + Float(slotIndex * slotSize),
            windowSize.y - marginBottom - Float(slotSize) / 2
        )
    }

    private static func createSlotImageRenderers(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) -> [ItemSlotImageRenderer] {
        var renderers: [ItemSlotImageRenderer] = []
        renderers.reserveCapacity(slotCount)

        for i in 0..<slotCount {
            renderers.append(
                ItemSlotImageRenderer(
                    renderContext: renderContext,
                    metalView: metalView,
                    windowSize: windowSize,
                    position: getSlotPosition(
                        windowSize: windowSize,
                        slotIndex: i
                    ),
                    size: Vector2(Float(slotSize), Float(slotSize)),
                    initType: .normal
                )
            )
        }

        return renderers
    }

    private static func createItemImageRenderers(
        renderContext: RenderContext,
        metalView: MTKView,
        windowSize: Vector2
    ) -> [ItemImageRenderer] {
        var renderers: [ItemImageRenderer] = []
        renderers.reserveCapacity(slotCount)

        for i in 0..<slotCount {
            renderers.append(
                ItemImageRenderer(
                    renderContext: renderContext,
                    metalView: metalView,
                    windowSize: windowSize,
                    position: getSlotPosition(
                        windowSize: windowSize,
                        slotIndex: i
                    ),
                    size: Vector2(Float(itemSize), Float(itemSize)),
                    initType: slotItems[i]
                )
            )
        }

        return renderers
    }

    private func changeSlotImage(
        renderContext: RenderContext,
        index: Int,
        newType: SlotImageType
    ) {
        slotImageRenderers[index].changeImageType(
            renderContext: renderContext,
            newType
        )
    }
}
