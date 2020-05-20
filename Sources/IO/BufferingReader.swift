public class BufferingReader<S: Source>: BufferedSource {
    let source: S

    @usableFromInline
    var ringBuffer: RingBuffer

    public init(source: S, capacity: Int) {
        self.source = source
        self.ringBuffer = RingBuffer(capacity: capacity)
    }

    @usableFromInline
    func fillBuffer() throws {
        try ringBuffer.write { buffer, written in
            guard buffer.count > 0 else { return }
            written = try source.read(buffer: buffer)
        }
    }

    @inlinable
    public func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) throws -> T {
        try fillBuffer()
        return try ringBuffer.read(closure)
    }

    @inlinable
    public func read(buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        try fillBuffer()
        return ringBuffer.read(buffer: buffer)
    }
}
