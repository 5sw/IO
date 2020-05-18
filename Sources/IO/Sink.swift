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
