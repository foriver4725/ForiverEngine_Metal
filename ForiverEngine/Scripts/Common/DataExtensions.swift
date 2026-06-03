import Foundation

extension Data {
    func readUInt32(offset: inout Int) -> UInt32? {
        let size = MemoryLayout<UInt32>.size

        guard offset + size <= count else {
            return nil
        }

        var value: UInt32 = 0

        _ = Swift.withUnsafeMutableBytes(of: &value) { dst in
            copyBytes(
                to: dst,
                from: offset..<(offset + size)
            )
        }

        offset += size

        return UInt32(littleEndian: value)
    }

    func readUInt64(offset: inout Int) -> UInt64? {
        let size = MemoryLayout<UInt64>.size

        guard offset + size <= count else {
            return nil
        }

        let value = self[offset..<offset + size]
            .withUnsafeBytes {
                $0.load(as: UInt64.self)
            }

        offset += size
        return UInt64(littleEndian: value)
    }

    func readFloat32(offset: inout Int) -> Float? {
        let size = MemoryLayout<Float>.size

        guard offset + size <= count else {
            return nil
        }

        var value: Float = 0

        _ = Swift.withUnsafeMutableBytes(of: &value) { dst in
            copyBytes(
                to: dst,
                from: offset..<(offset + size)
            )
        }

        offset += size
        return value
    }

    func readBytes(
        offset: inout Int,
        count readCount: Int
    ) -> Data? {
        guard offset + readCount <= count else {
            return nil
        }

        let result = self[offset..<offset + readCount]
        offset += readCount

        return Data(result)
    }

    mutating func appendUInt32(_ value: UInt32) {
        var value = value.littleEndian

        Swift.withUnsafeBytes(of: &value) { bytes in
            append(contentsOf: bytes)
        }
    }

    mutating func appendUInt64(_ value: UInt64) {
        var value = value.littleEndian

        Swift.withUnsafeBytes(of: &value) { bytes in
            append(contentsOf: bytes)
        }
    }

    mutating func appendFloat32(_ value: Float) {
        var value = value

        Swift.withUnsafeBytes(of: &value) { bytes in
            append(contentsOf: bytes)
        }
    }
}
