@usableFromInline
struct RingBufferImpl {
    let start: UnsafeMutableRawPointer
    let end: UnsafeMutableRawPointer
    var readPointer: UnsafeMutableRawPointer
    var writePointer: UnsafeMutableRawPointer
    var empty = true

    init(start: UnsafeMutableRawPointer, end: UnsafeMutableRawPointer) {
        self.start = start
        self.end = end
        self.readPointer = start
        self.writePointer = start
    }

    init(start: UnsafeMutableRawPointer, capacity: Int) {
        self.init(start: start, end: start + capacity)
    }

    init(buffer: UnsafeMutableRawBufferPointer) {
        guard let base = buffer.baseAddress, buffer.count > 0 else {
            preconditionFailure("Must not use an empty buffer to construct a ring buffer")
        }

        self.init(start: base, end: base + buffer.count)
    }

    init(capacity: Int) {
        self.init(buffer: .allocate(byteCount: capacity, alignment: 0))
    }

    init<T>(_ managedBuffer: ManagedBuffer<T, UInt8>) {
        let ptr = managedBuffer.withUnsafeMutablePointerToElements { $0 }
        self.init(start: ptr, capacity: managedBuffer.capacity)
    }

    @usableFromInline
    var availableToRead: Int {
        if readPointer < writePointer {
            return writePointer - readPointer
        } else if readPointer == writePointer && empty {
            return 0
        } else {
            return end - readPointer
        }
    }

    @usableFromInline
    var availableToWrite: Int {
        if writePointer < readPointer {
            return readPointer - writePointer
        } else if readPointer == writePointer && !empty {
            return 0
        } else {
            return end - writePointer
        }
    }

    @usableFromInline
    var capacity: Int {
        return end - start
    }

    @usableFromInline
    mutating func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        let ptr = UnsafeRawBufferPointer(start: UnsafeRawPointer(readPointer), count: availableToRead)

        var actualRead = 0
        let result = try closure(ptr, &actualRead)

        precondition(actualRead <= ptr.count, "Read more than available")
        readPointer += actualRead

        if readPointer == end {
            readPointer = start
        }

        if readPointer == writePointer {
            empty = true
        }

        return result
    }

    @usableFromInline
    mutating func write<T>(_ closure: (UnsafeMutableRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        let ptr = UnsafeMutableRawBufferPointer(start: writePointer, count: availableToWrite)
        var actualWritten = 0
        let result = try closure(ptr, &actualWritten)
        precondition(actualWritten <= ptr.count, "Written more than available")

        if actualWritten > 0 {
            empty = false

            writePointer += actualWritten

            if writePointer == end {
                writePointer = start
            }
        }

        return result
    }

    @usableFromInline
    mutating func read(buffer: UnsafeMutableRawBufferPointer) -> Int {
        guard var base = buffer.baseAddress, buffer.count > 0  else { return 0 }

        var toRead = buffer.count

        func readBlock() -> Int {
            return read { source, copied in
                guard let sourceAddress = source.baseAddress, source.count > 0 else {
                    return 0
                }

                copied = min(source.count, toRead)
                base.copyMemory(from: sourceAddress, byteCount: copied)
                return copied
            }
        }

        var r = readBlock()
        toRead -= r
        base += r

        r += readBlock()

        return r
    }
}

public struct RingBuffer: BufferedSource {
    @usableFromInline
    let buffer: ManagedBuffer<RingBufferImpl, UInt8>

    public init(capacity: Int) {
        buffer = ManagedBuffer.create(minimumCapacity: capacity, makingHeaderWith: RingBufferImpl.init)
    }

    @inlinable
    public var availableToRead: Int {
        return buffer.header.availableToRead
    }

    @inlinable
    public var availableToWrite: Int {
        return buffer.header.availableToWrite
    }

    @inlinable
    public func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        return try buffer.header.read(closure)
    }

    @inlinable
    public func read(buffer: UnsafeMutableRawBufferPointer) -> Int {
        return self.buffer.header.read(buffer: buffer)
    }

    @inlinable
    public func write<T>(_ closure: (UnsafeMutableRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        return try buffer.header.write(closure)
    }
}
