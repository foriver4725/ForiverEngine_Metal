import Metal
import MetalKit

enum TextureLoader {
    static func load(
        device: MTLDevice,
        name: String,
        //        bundle: Bundle = .main,
        isSRGB: Bool = false
    ) -> MTLTexture? {
        // NOTE: MTKTextureLoader fails in some PNG files, so load via RGBA8 bitmap (fallback method)
        //        let loader = MTKTextureLoader(device: device)
        //
        //        do {
        //            return try loader.newTexture(
        //                name: name,
        //                scaleFactor: 1.0,
        //                bundle: bundle,
        //                options: [
        //                    .SRGB: isSRGB
        //                ]
        //            )
        //        } catch {
        //            print("MTKTextureLoader name load failed: \(name), \(error)")
        //
        //            return loadViaRGBA8Bitmap(
        //                device: device,
        //                name: name,
        //                isSRGB: isSRGB
        //            )
        //        }

        return loadViaRGBA8Bitmap(
            device: device,
            name: name,
            isSRGB: isSRGB
        )
    }

    // Fallback of normal load
    static func loadViaRGBA8Bitmap(
        device: MTLDevice,
        name: String,
        isSRGB: Bool = false
    ) -> MTLTexture? {
        guard let nsImage = NSImage(named: name) else {
            print("NSImage load failed: \(name)")
            return nil
        }

        var rect = NSRect(origin: .zero, size: nsImage.size)

        guard
            let srcCGImage = nsImage.cgImage(
                forProposedRect: &rect,
                context: nil,
                hints: nil
            )
        else {
            print("CGImage convert failed: \(name)")
            return nil
        }

        let width = srcCGImage.width
        let height = srcCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixels = [UInt8](
            repeating: 0,
            count: height * bytesPerRow
        )

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        guard
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            print("CGContext create failed: \(name)")
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(
            srcCGImage,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: isSRGB ? .rgba8Unorm_srgb : .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )

        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }

        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: bytesPerRow
        )

        return texture
    }

    static func loadAsArray(
        device: MTLDevice,
        names: [String],
        //        bundle: Bundle = .main,
        isSRGB: Bool = false
    ) -> MTLTexture? {
        if names.isEmpty {
            print("Texture array load failed: empty names")
            return nil
        }

        let sourceTextures: [MTLTexture] = names.map { name in
            guard
                let texture = load(
                    device: device,
                    name: name,
                    //                    bundle: bundle,
                    isSRGB: isSRGB
                )
            else {
                fatalError("Failed to load texture: \(name)")
            }

            return texture
        }

        if sourceTextures.count != names.count {
            print("Texture array load failed: some textures failed to load")
            return nil
        }

        guard let first = sourceTextures.first else {
            return nil
        }

        for texture in sourceTextures {
            if texture.width != first.width {
                print("Texture array load failed: texture width mismatch")
                return nil
            }
            if texture.height != first.height {
                print("Texture array load failed: texture height mismatch")
                return nil
            }
            if texture.pixelFormat != first.pixelFormat {
                print(
                    "Texture array load failed: texture pixel format mismatch"
                )
                return nil
            }
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
