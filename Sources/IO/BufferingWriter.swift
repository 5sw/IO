public class BufferingWriter<S: Sink>: BufferedSink {
    let sink: S

    @usableFromInline
    var ringBuffer: RingBuffer

    public init(sink: S, capacity: Int) {
        self.sink = sink
        self.ringBuffer = RingBuffer(capacity: capacity)
    }

    @usableFromInline
    func flushBuffer() throws {
        try ringBuffer.read { buffer, copied in
            guard buffer.count > 0 else { return }
            copied = try sink.write(buffer: buffer)
        }
    }

    @inlinable
    public func write<T>(_ closure: (UnsafeMutableRawBufferPointer, inout Int) throws -> T) throws -> T {
        let result = try ringBuffer.write(closure)
        try flushBuffer()
        return result
    }
}
