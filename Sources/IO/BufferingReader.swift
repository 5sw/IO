public class BufferingReader<S: Source>: BufferedSource {
    let source: S
    var ringBuffer: RingBuffer

    public init(source: S, capacity: Int) {
        self.source = source
        self.ringBuffer = RingBuffer(capacity: capacity)
    }

    public func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) throws -> T {
        try ringBuffer.write { buffer, written in
            guard buffer.count > 0 else { return }
            written = try source.read(buffer: buffer)
        }

        return try ringBuffer.read(closure)
    }
}
