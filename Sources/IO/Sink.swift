import Foundation

public protocol Sink {
    func write(buffer: UnsafeRawBufferPointer) throws -> Int
}

public extension Sink {
    @discardableResult
    func write(_ data: Data) throws -> Int {
        return try data.withUnsafeBytes {
            try self.write(buffer: $0)
        }
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
