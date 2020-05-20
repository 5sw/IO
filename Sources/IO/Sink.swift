import Foundation

public protocol Sink {
    func write(buffer: UnsafeRawBufferPointer) throws -> Int
}

public extension Sink {
    @discardableResult
    func write<D: DataProtocol>(_ data: D) throws -> Int {
        var written = 0
        for region in data.regions {
            written += try region.withUnsafeBytes { (ptr) in
                try self.write(buffer: ptr)
            }
        }
        return written
    }
}

public protocol BufferedSink: Sink {
    func write<T>(_ closure: (UnsafeMutableRawBufferPointer, inout Int) throws -> T) throws -> T
}

extension BufferedSink {
    public func write(buffer: UnsafeRawBufferPointer) throws -> Int {
        guard let base = buffer.baseAddress, buffer.count > 0  else { return 0 }

        return try write { destination, copied in
            guard let destinationBase = destination.baseAddress, destination.count > 0 else {
                return 0
            }

            copied = min(destination.count, buffer.count)
            destinationBase.copyMemory(from: base, byteCount: copied)
            return copied
        }
    }
}
