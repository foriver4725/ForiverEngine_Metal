import Metal
import MetalKit

enum TextureLoader {
    static func load(
        device: MTLDevice,
        name: String,
        bundle: Bundle = .main,
        isSRGB: Bool = false
    ) -> MTLTexture? {
        let loader = MTKTextureLoader(device: device)

        do {
            return try loader.newTexture(
                name: name,
                scaleFactor: 1.0,
                bundle: bundle,
                options: [
                    .SRGB: isSRGB
                ]
            )
        } catch {
            print("Failed to load texture: \(name), \(error)")
            return nil
        }
    }

    static func loadAsArray(
        device: MTLDevice,
        names: [String],
        bundle: Bundle = .main,
        isSRGB: Bool = false
    ) -> MTLTexture? {
        if names.isEmpty {
            return nil
        }

        let sourceTextures = names.compactMap {
            load(device: device, name: $0, bundle: bundle, isSRGB: isSRGB)
        }

        if sourceTextures.count != names.count {
            return nil
        }

        guard let first = sourceTextures.first else {
            return nil
        }

        for texture in sourceTextures {
            if texture.width != first.width { return nil }
            if texture.height != first.height { return nil }
            if texture.pixelFormat != first.pixelFormat { return nil }
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: first.pixelFormat,
            width: first.width,
            height: first.height,
            mipmapped: false
        )

        descriptor.textureType = .type2DArray
        descriptor.arrayLength = sourceTextures.count
        descriptor.usage = [.shaderRead]

        guard let textureArray = device.makeTexture(descriptor: descriptor)
        else {
            return nil
        }

        guard let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let blit = commandBuffer.makeBlitCommandEncoder()
        else {
            return nil
        }

        for (slice, texture) in sourceTextures.enumerated() {
            blit.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(
                    width: texture.width,
                    height: texture.height,
                    depth: 1
                ),
                to: textureArray,
                destinationSlice: slice,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
        }

        blit.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureArray
    }
}
