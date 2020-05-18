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

    var availableToRead: Int {
        if readPointer < writePointer {
            return writePointer - readPointer
        } else if readPointer == writePointer && empty {
            return 0
        } else {
            return end - readPointer
        }
    }

    var availableToWrite: Int {
        if writePointer < readPointer {
            return readPointer - writePointer
        } else if readPointer == writePointer && !empty {
            return 0
        } else {
            return end - writePointer
        }
    }

    var capacity: Int {
        return end - start
    }

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
}

struct RingBuffer {
    private let buffer: ManagedBuffer<RingBufferImpl, UInt8>

    init(capacity: Int) {
        buffer = ManagedBuffer.create(minimumCapacity: capacity, makingHeaderWith: RingBufferImpl.init)
    }

    var availableToRead: Int {
        return buffer.header.availableToRead
    }

    var availableToWrite: Int {
        return buffer.header.availableToWrite
    }

    func read<T>(_ closure: (UnsafeRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        return try buffer.header.read(closure)
    }

    func write<T>(_ closure: (UnsafeMutableRawBufferPointer, inout Int) throws -> T) rethrows -> T {
        return try buffer.header.write(closure)
    }
}
